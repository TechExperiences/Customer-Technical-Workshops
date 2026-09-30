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

$resourceGroup = 'rg-MWC'
$webAppName = "app-caldova-ordermgmt-$suffix"
$sqlServerName = "sql-caldova-$suffix"
$openAiAccountName = "openai-caldova-$suffix"
$databaseName = 'CaldovaOrderManagement'
$firewallRuleName = 'Allow-Azd-Migration-Client'
$clientIp = if ([string]::IsNullOrWhiteSpace($env:SQL_MIGRATION_CLIENT_IP)) { (Invoke-RestMethod -Uri 'https://api.ipify.org').Trim() } else { $env:SQL_MIGRATION_CLIENT_IP }
$deploymentRevision = (& git -C $projectRoot rev-parse --short HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($deploymentRevision)) { throw 'Unable to determine the Git revision being deployed.' }

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

Write-Host '[MIQ 2/6] Preparing the SQL migration connection...'
Write-Host "[MIQ 2/6] Opening temporary SQL firewall access for $clientIp..."
Invoke-AzChecked @('sql', 'server', 'firewall-rule', 'create', '--resource-group', $resourceGroup, '--server', $sqlServerName, '--name', $firewallRuleName, '--start-ip-address', $clientIp, '--end-ip-address', $clientIp, '--output', 'none')
Start-Sleep -Seconds 15

try {
  $connection = New-CaldovaSqlConnection -ServerName $sqlServerName -DatabaseName $databaseName
  try {
    Write-Host '[MIQ 3/6] Creating schema and importing the 11 simulated on-prem CSV exports...'
    & (Join-Path $PSScriptRoot 'Import-CaldovaCsvData.ps1') -Connection $connection -DataPath (Join-Path $projectRoot 'data') -SchemaPath (Join-Path $projectRoot 'infra\sql\InitialSchema.sql')

    $openAiKey = (& az cognitiveservices account keys list --resource-group $resourceGroup --name $openAiAccountName --query key1 --output tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($openAiKey)) { throw 'Unable to retrieve the Azure OpenAI key required for embedding generation.' }
    Write-Host '[MIQ 4/6] Waiting for text-embedding-ada-002 before generating the 12th table...'
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
      Write-Host '[MIQ 4/6] Generating the 12th table from Azure OpenAI embeddings (progress is reported every 10 records)...'
      Invoke-CaldovaSqlNonQuery -Connection $connection -Sql $embeddingScript -CommandTimeout 1800 | Out-Null
    }
    finally {
      if (Test-Path -LiteralPath $runtimeScriptPath) { Remove-Item -LiteralPath $runtimeScriptPath -Force }
    }

    $embeddingCount = [int](Invoke-CaldovaSqlScalar -Connection $connection -Sql 'SELECT COUNT(*) FROM dbo.ProductDescriptionEmbeddings;')
    $expectedEmbeddingCount = [int](Invoke-CaldovaSqlScalar -Connection $connection -Sql "SELECT COUNT(*) FROM dbo.ProductDescriptions pd JOIN dbo.ProductCatalog p ON p.ProductID=pd.ProductID WHERE pd.LanguageCode='en-US' AND p.IsActive=1;")
    if ($embeddingCount -ne $expectedEmbeddingCount) { throw "Embedding generation is incomplete: expected $expectedEmbeddingCount embeddings but found $embeddingCount." }
    Write-Host "Pipeline verification succeeded: 11 source tables imported and $embeddingCount generated embeddings stored in dbo.ProductDescriptionEmbeddings."
  }
  finally {
    $connection.Dispose()
  }

  Write-Host '[MIQ 5/6] Configuring App Service identity, SQL access, OpenAI access, and network rules...'
  $openAiScope = (& az cognitiveservices account show --resource-group $resourceGroup --name $openAiAccountName --query id --output tsv).Trim()
  $appPrincipalId = (& az webapp identity show --resource-group $resourceGroup --name $webAppName --query principalId --output tsv).Trim()
  if ([string]::IsNullOrWhiteSpace($appPrincipalId)) { throw 'Web app managed identity was not created.' }
  # principalId is the Entra service-principal object ID used for Azure RBAC. Azure
  # SQL external users instead store a SID derived from the identity's application/client ID.
  $appClientId = (& az ad sp show --id $appPrincipalId --query appId --output tsv).Trim()
  $clientIdLookupExitCode = $LASTEXITCODE
  if ($openAiScope -and $appPrincipalId) {
    & az role assignment create --assignee-object-id $appPrincipalId --assignee-principal-type ServicePrincipal --role 'Cognitive Services OpenAI User' --scope $openAiScope --output none 2>$null
    if ($LASTEXITCODE -ne 0) { throw 'Unable to assign Cognitive Services OpenAI User to the web app identity. The deployment identity needs User Access Administrator or Owner at the Azure OpenAI scope.' }
  }
  if ($clientIdLookupExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($appClientId)) { throw 'Unable to resolve the generated App Service managed identity client ID required for Azure SQL access.' }
  $appSqlSid = '0x' + [System.BitConverter]::ToString(([guid]$appClientId).ToByteArray()).Replace('-', '')
  $appConnection = New-CaldovaSqlConnection -ServerName $sqlServerName -DatabaseName $databaseName
  try {
    # Recreate a stale user if a previous run used the same name with a different SID.
    $grantSql = "DECLARE @Sid varbinary(16) = CONVERT(varbinary(16), '$appSqlSid', 1); IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$webAppName' AND sid <> @Sid) DROP USER [$webAppName]; IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = N'$webAppName') BEGIN DECLARE @CreateUserSql nvarchar(max) = N'CREATE USER [$webAppName] WITH SID = ' + CONVERT(nvarchar(34), @Sid, 1) + N', TYPE = E'; EXEC sys.sp_executesql @CreateUserSql; END; IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id JOIN sys.database_principals u ON u.principal_id=m.member_principal_id WHERE r.name=N'db_datareader' AND u.name=N'$webAppName') ALTER ROLE db_datareader ADD MEMBER [$webAppName]; IF NOT EXISTS (SELECT 1 FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id JOIN sys.database_principals u ON u.principal_id=m.member_principal_id WHERE r.name=N'db_datawriter' AND u.name=N'$webAppName') ALTER ROLE db_datawriter ADD MEMBER [$webAppName]; IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name=N'$webAppName' AND type='E' AND sid=@Sid) THROW 51000, 'Managed identity database user SID verification failed.', 1; IF (SELECT COUNT(DISTINCT r.name) FROM sys.database_role_members m JOIN sys.database_principals r ON r.principal_id=m.role_principal_id JOIN sys.database_principals u ON u.principal_id=m.member_principal_id WHERE u.name=N'$webAppName' AND r.name IN (N'db_datareader',N'db_datawriter')) <> 2 THROW 51001, 'Managed identity database role verification failed.', 1;"
    Invoke-CaldovaSqlNonQuery -Connection $appConnection -Sql $grantSql | Out-Null
  }
  finally { $appConnection.Dispose() }
  # No VNet is used for this accelerator. Allow both active and potential outbound
  # App Service addresses so a platform scale/rebalance does not break SQL access.
  $activeOutboundIps = ((& az webapp show --resource-group $resourceGroup --name $webAppName --query outboundIpAddresses --output tsv).Trim() -split ',') | Where-Object { $_ }
  $possibleOutboundIps = ((& az webapp show --resource-group $resourceGroup --name $webAppName --query possibleOutboundIpAddresses --output tsv).Trim() -split ',') | Where-Object { $_ }
  $outboundIps = @($activeOutboundIps + $possibleOutboundIps | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Sort-Object -Unique)
  for ($index = 0; $index -lt $outboundIps.Count; $index++) {
    $ip = $outboundIps[$index].Trim()
    Invoke-AzChecked @('sql', 'server', 'firewall-rule', 'create', '--resource-group', $resourceGroup, '--server', $sqlServerName, '--name', "Allow-App-Service-$index", '--start-ip-address', $ip, '--end-ip-address', $ip, '--output', 'none')
  }
  Invoke-AzChecked @('webapp', 'config', 'appsettings', 'set', '--resource-group', $resourceGroup, '--name', $webAppName, '--settings', "AZURE_OPENAI_ENDPOINT=https://$openAiAccountName.openai.azure.com", "SQL_SERVER_NAME=$sqlServerName", "CALDOVA_DEPLOYMENT_REVISION=$deploymentRevision", 'ASPNETCORE_ENVIRONMENT=Production', '--output', 'none')
  Invoke-AzChecked @('webapp', 'log', 'config', '--resource-group', $resourceGroup, '--name', $webAppName, '--application-logging', 'filesystem', '--level', 'information', '--detailed-error-messages', 'true', '--failed-request-tracing', 'true', '--web-server-logging', 'filesystem')
  Write-Host '[MIQ 6/6] Building and deploying the Caldova web UI...'
  & (Join-Path $PSScriptRoot 'Publish-WebApp.ps1') -ResourceGroup $resourceGroup -WebAppName $webAppName
  Write-Host '[MIQ 6/6] Deployment complete. The App Service URL is shown above.'
}
finally {
  Write-Host 'Removing temporary SQL migration firewall access...'
  & az sql server firewall-rule delete --resource-group $resourceGroup --server $sqlServerName --name $firewallRuleName --yes 2>$null
}
