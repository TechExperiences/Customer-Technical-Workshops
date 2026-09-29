[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
. (Join-Path $PSScriptRoot 'Import-DotEnv.ps1')
. (Join-Path $PSScriptRoot 'Sql-Helpers.ps1')
Import-DotEnv -Path (Join-Path $projectRoot '.env')

$statePath = Join-Path $projectRoot '.deployment-state.json'
if (-not (Test-Path -LiteralPath $statePath -PathType Leaf)) { throw 'Deployment state is missing. The preprovision stage did not complete.' }
$suffix = (Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json).deploymentSuffix
if ([string]::IsNullOrWhiteSpace($suffix)) { throw 'Deployment state does not contain a deployment suffix.' }

$resourceGroup = 'rg-caldova'
$webAppName = "app-caldova-ordermgmt-$suffix"
$sqlServerName = "sql-caldova-$suffix"
$openAiAccountName = "openai-caldova-$suffix"
$databaseName = 'CaldovaOrderManagement'
$firewallRuleName = 'Allow-Azd-Migration-Client'
$clientIp = if ([string]::IsNullOrWhiteSpace($env:SQL_MIGRATION_CLIENT_IP)) { (Invoke-RestMethod -Uri 'https://api.ipify.org').Trim() } else { $env:SQL_MIGRATION_CLIENT_IP }

function Invoke-AzChecked {
  param([string[]] $Arguments)
  & az @Arguments
  if ($LASTEXITCODE -ne 0) { throw "Azure CLI command failed: az $($Arguments -join ' ')" }
}

function Wait-CaldovaEmbeddingDeployment {
  param(
    [Parameter(Mandatory)][string] $AccountName,
    [Parameter(Mandatory)][string] $ApiKey,
    [string] $DeploymentName = 'text-embedding-ada-002',
    [int] $MaxAttempts = 80,
    [int] $DelaySeconds = 15
  )

  # ARM can report the OpenAI deployment complete a little before the data-plane
  # endpoint accepts embedding requests. Probe the actual endpoint so phase 3
  # begins only when the model that generates the 12th table is usable.
  $endpoint = "https://$AccountName.openai.azure.com/openai/deployments/$DeploymentName/embeddings?api-version=2023-05-15"
  $body = @{ input = @('Caldova deployment readiness check') } | ConvertTo-Json -Compress
  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    try {
      $response = Invoke-RestMethod -Uri $endpoint -Method Post -Headers @{ 'api-key' = $ApiKey } -ContentType 'application/json' -Body $body
      if ($null -ne $response.data -and $response.data.Count -gt 0) {
        Write-Host "Embedding deployment '$DeploymentName' is ready."
        return
      }
      throw 'The embedding endpoint returned no vectors.'
    }
    catch {
      if ($attempt -eq $MaxAttempts) {
        throw "Embedding deployment '$DeploymentName' did not become available after $($MaxAttempts * $DelaySeconds / 60) minutes. Last error: $($_.Exception.Message)"
      }
      Write-Host "Waiting for embedding deployment '$DeploymentName' to become available ($attempt/$MaxAttempts)..."
      Start-Sleep -Seconds $DelaySeconds
    }
  }
}

Write-Host "Phase 1/3 complete: infrastructure is provisioned."
Write-Host "Opening temporary SQL firewall access for $clientIp..."
Invoke-AzChecked @('sql', 'server', 'firewall-rule', 'create', '--resource-group', $resourceGroup, '--server', $sqlServerName, '--name', $firewallRuleName, '--start-ip-address', $clientIp, '--end-ip-address', $clientIp, '--output', 'none')
Start-Sleep -Seconds 15

try {
  $connection = New-CaldovaSqlConnection -ServerName $sqlServerName -DatabaseName $databaseName
  try {
    Write-Host 'Phase 2/3: creating schema and importing the 11 simulated on-prem CSV exports.'
    & (Join-Path $PSScriptRoot 'Import-CaldovaCsvData.ps1') -Connection $connection -DataPath (Join-Path $projectRoot 'data') -SchemaPath (Join-Path $projectRoot 'infra\sql\InitialSchema.sql')

    $openAiKey = (& az cognitiveservices account keys list --resource-group $resourceGroup --name $openAiAccountName --query key1 --output tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($openAiKey)) { throw 'Unable to retrieve the Azure OpenAI key required for embedding generation.' }
    Write-Host 'Waiting for text-embedding-ada-002 before generating the 12th table...'
    Wait-CaldovaEmbeddingDeployment -AccountName $openAiAccountName -ApiKey $openAiKey
    $embeddingScriptPath = Join-Path $projectRoot 'infra\sql\Embedding_Script.sql'
    $runtimeScriptPath = Join-Path $projectRoot 'infra\sql\.embedding-runtime.sql'
    try {
      $embeddingScript = Get-Content -LiteralPath $embeddingScriptPath -Raw
      $embeddingScript = $embeddingScript.Replace('__AZURE_OPENAI_ENDPOINT__', "https://$openAiAccountName.openai.azure.com")
      $embeddingScript = $embeddingScript.Replace('__AZURE_OPENAI_API_KEY__', $openAiKey)
      $embeddingScript = $embeddingScript.Replace('__AZURE_OPENAI_EMBEDDING_DEPLOYMENT__', 'text-embedding-ada-002')
      $embeddingScript = $embeddingScript.Replace('__AZURE_OPENAI_EMBEDDING_API_VERSION__', '2023-05-15')
      Set-Content -LiteralPath $runtimeScriptPath -Value $embeddingScript -Encoding utf8 -NoNewline
      Write-Host 'Phase 3/3: generating the 12th table from Azure OpenAI embeddings.'
      Invoke-CaldovaSqlNonQuery -Connection $connection -Sql $embeddingScript -CommandTimeout 1800 | Out-Null
    }
    finally {
      if (Test-Path -LiteralPath $runtimeScriptPath) { Remove-Item -LiteralPath $runtimeScriptPath -Force }
    }

    $embeddingCount = [int](Invoke-CaldovaSqlScalar -Connection $connection -Sql 'SELECT COUNT(*) FROM dbo.ProductDescriptionEmbeddings;')
    if ($embeddingCount -le 0) { throw 'Embedding generation completed without creating any embeddings.' }
    Write-Host "Pipeline verification succeeded: 11 source tables imported and $embeddingCount generated embeddings stored in dbo.ProductDescriptionEmbeddings."
  }
  finally {
    $connection.Dispose()
  }

  $openAiScope = (& az cognitiveservices account show --resource-group $resourceGroup --name $openAiAccountName --query id --output tsv).Trim()
  $appPrincipalId = (& az webapp identity show --resource-group $resourceGroup --name $webAppName --query principalId --output tsv).Trim()
  if ($openAiScope -and $appPrincipalId) {
    & az role assignment create --assignee-object-id $appPrincipalId --assignee-principal-type ServicePrincipal --role 'Cognitive Services OpenAI User' --scope $openAiScope --output none 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Unable to assign Cognitive Services OpenAI User to the web app identity. Assign it manually if the deployment identity lacks role-assignment permission.' }
  }
  if ([string]::IsNullOrWhiteSpace($appPrincipalId)) { throw 'Web app managed identity was not created.' }
  $appSid = $appPrincipalId.Replace('-', '')
  $appConnection = New-CaldovaSqlConnection -ServerName $sqlServerName -DatabaseName $databaseName
  try {
    $grantSql = "IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$webAppName') CREATE USER [$webAppName] WITH SID = 0x$appSid, TYPE = E; IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id JOIN sys.database_principals u ON u.principal_id=m.member_principal_id WHERE r.name=N'db_datareader' AND u.name=N'$webAppName') ALTER ROLE db_datareader ADD MEMBER [$webAppName]; IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id JOIN sys.database_principals u ON u.principal_id=m.member_principal_id WHERE r.name=N'db_datawriter' AND u.name=N'$webAppName') ALTER ROLE db_datawriter ADD MEMBER [$webAppName];"
    Invoke-CaldovaSqlNonQuery -Connection $appConnection -Sql $grantSql | Out-Null
  }
  finally { $appConnection.Dispose() }
  $outboundIps = ((& az webapp show --resource-group $resourceGroup --name $webAppName --query outboundIpAddresses --output tsv).Trim() -split ',') | Where-Object { $_ }
  for ($index = 0; $index -lt $outboundIps.Count; $index++) {
    $ip = $outboundIps[$index].Trim()
    Invoke-AzChecked @('sql', 'server', 'firewall-rule', 'create', '--resource-group', $resourceGroup, '--server', $sqlServerName, '--name', "Allow-App-Service-$index", '--start-ip-address', $ip, '--end-ip-address', $ip, '--output', 'none')
  }
  Invoke-AzChecked @('webapp', 'config', 'appsettings', 'set', '--resource-group', $resourceGroup, '--name', $webAppName, '--settings', "AZURE_OPENAI_ENDPOINT=https://$openAiAccountName.openai.azure.com", "SQL_SERVER_NAME=$sqlServerName", 'ASPNETCORE_ENVIRONMENT=Production', '--output', 'none')
  & (Join-Path $PSScriptRoot 'Publish-WebApp.ps1') -ResourceGroup $resourceGroup -WebAppName $webAppName
}
finally {
  Write-Host 'Removing temporary SQL migration firewall access...'
  & az sql server firewall-rule delete --resource-group $resourceGroup --server $sqlServerName --name $firewallRuleName --yes 2>$null
}
