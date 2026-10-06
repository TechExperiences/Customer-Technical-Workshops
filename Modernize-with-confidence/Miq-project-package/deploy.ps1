[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $SubscriptionId,

  [string] $ResourceGroupName = 'rg-MWC',

  [string] $SqlAdministratorLogin = 'sqladmincaldova',

  [securestring] $SqlAdministratorPassword,

  [Parameter(Mandatory)]
  [string] $SqlEntraAdministratorLogin,

  [Parameter(Mandatory)]
  [string] $SqlEntraAdministratorObjectId,

  [string] $AppServicePlanSkuTier = 'Basic',
  [string] $AppServicePlanSkuName = 'B1',
  [string] $DatabaseSkuName = 'HS_Gen5_2',
  [string] $ChatModelVersion = '2025-08-07',
  [string] $EmbeddingModelVersion = '2',
  [int] $EmbeddingModelCapacity = 10
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$candidateLocations = @('westus2', 'westus', 'eastus', 'eastus2')
$appServiceCandidateLocations = @('westus2', 'westcentralus', 'westus', 'eastus', 'eastus2')
$openAiCandidateLocations = @('westus')
$deploymentStatePath = Join-Path $scriptRoot '.deployment-state.json'

# App Service, SQL logical-server, and Azure OpenAI account names must be globally
# unique. Generate a fresh suffix for every run so an earlier failed or soft-deleted
# resource can never block a subsequent deployment. The state file communicates this
# run's names to postprovision; it is not reused on a later run.
$deploymentSuffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
@{ deploymentSuffix = $deploymentSuffix } | ConvertTo-Json | Set-Content -LiteralPath $deploymentStatePath -Encoding utf8

$webAppName = "app-caldova-ordermgmt-$deploymentSuffix"
$sqlServerName = "sql-caldova-$deploymentSuffix"
$openAiAccountName = "openai-caldova-$deploymentSuffix"

function Invoke-AzChecked {
  param([string[]] $Arguments)
  & az @Arguments
  if ($LASTEXITCODE -ne 0) {
    $safeArguments = $Arguments | ForEach-Object {
      if ($_ -like 'administratorLoginPassword=*') { 'administratorLoginPassword=***' } else { $_ }
    }
    throw "Azure CLI command failed: az $($safeArguments -join ' ')"
  }
}

function Invoke-RegionalFallback {
  param(
    [Parameter(Mandatory)][string] $Name,
    [Parameter(Mandatory)][scriptblock] $Deploy,
    [scriptblock] $Cleanup,
    [string[]] $CandidateLocations = $candidateLocations,
    [int] $MaxAttemptsPerLocation = 1,
    [int] $RetryDelaySeconds = 30
  )

  foreach ($location in $CandidateLocations) {
    for ($attempt = 1; $attempt -le $MaxAttemptsPerLocation; $attempt++) {
      Write-Host "Trying $Name in $location..."
      try {
        & $Deploy $location
        Write-Host "$Name deployed in $location."
        return $location
      }
      catch {
        $failureMessage = $_.Exception.Message
        $isTransientConflict = $failureMessage -match 'RequestConflict|Another operation is being performed|OperationInProgress'
        if ($isTransientConflict -and $attempt -lt $MaxAttemptsPerLocation) {
          Write-Warning "$Name has an in-progress Azure operation in ${location}; retrying in $RetryDelaySeconds seconds ($attempt/$MaxAttemptsPerLocation)."
          Start-Sleep -Seconds $RetryDelaySeconds
          continue
        }

        Write-Warning "$Name failed in ${location}: $failureMessage"
        break
      }
    }
    if ($Cleanup) {
      # A failed ARM deployment can leave an earlier, dependent resource behind.
      try { & $Cleanup $location } catch { Write-Warning "Cleanup after $Name failed in ${location} also failed: $($_.Exception.Message)" }
    }
  }
  throw "$Name could not be deployed in any candidate location: $($CandidateLocations -join ', ')."
}

function Assert-SqlAdministratorPassword {
  param([securestring] $Password, [string] $Login)
  $plainText = [System.Net.NetworkCredential]::new('', $Password).Password
  $categories = @(
    $plainText -cmatch '[A-Z]'
    $plainText -cmatch '[a-z]'
    $plainText -match '\d'
    $plainText -match '[^A-Za-z0-9]'
  ) | Where-Object { $_ }
  if ($plainText.Length -lt 8 -or $categories.Count -lt 3 -or $plainText.IndexOf($Login, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
    throw 'SQL_ADMINISTRATOR_PASSWORD must be at least 8 characters, contain at least three character categories (uppercase, lowercase, number, special), and not contain SQL_ADMINISTRATOR_LOGIN.'
  }
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw 'Azure CLI is required. Install it and run az login before executing this script.'
}

# azd and Azure CLI can have separate cached sign-in sessions. The azd hook uses
# this script, so sign in to Azure CLI only when an existing session is unavailable.
& az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
  $servicePrincipalVariables = @('AZURE_CLIENT_ID', 'AZURE_TENANT_ID', 'AZURE_CLIENT_SECRET')
  $hasServicePrincipal = ($servicePrincipalVariables | Where-Object {
    [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($_, 'Process'))
  }).Count -eq 0
  if ($hasServicePrincipal) {
    & az login --service-principal --username $env:AZURE_CLIENT_ID --password $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID --output none
  }
  else {
    Write-Host 'No Azure CLI session was found. Opening Azure sign-in...'
    & az login --output none
  }
  if ($LASTEXITCODE -ne 0) { throw 'Azure CLI sign-in failed or was cancelled.' }
}

Invoke-AzChecked @('account', 'set', '--subscription', $SubscriptionId)

# Resource group location is immutable. The selected location remains its location even
# when a later independent component must fall back to another supported region.
$existingRg = & az group exists --name $ResourceGroupName
if ($LASTEXITCODE -ne 0) { throw 'Unable to check whether the resource group already exists.' }

if ($existingRg -eq 'true') {
  $resourceGroupLocation = (& az group show --name $ResourceGroupName --query location --output tsv).Trim()
  if ($LASTEXITCODE -ne 0) { throw "Unable to read existing resource group $ResourceGroupName." }
  Write-Host "Using existing resource group $ResourceGroupName in $resourceGroupLocation."
}
else {
  $resourceGroupLocation = Invoke-RegionalFallback -Name 'resource group' -Deploy {
    param($location)
    Invoke-AzChecked @('deployment', 'sub', 'create', '--name', "rg-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--location', $location, '--template-file', (Join-Path $scriptRoot 'infra/main.bicep'), '--parameters', "resourceGroupName=$ResourceGroupName", "resourceGroupLocation=$location")
  }
}

if (-not $SqlAdministratorPassword) {
  $SqlAdministratorPassword = Read-Host 'Enter the SQL administrator password' -AsSecureString
}
Assert-SqlAdministratorPassword -Password $SqlAdministratorPassword -Login $SqlAdministratorLogin
$passwordText = [System.Net.NetworkCredential]::new('', $SqlAdministratorPassword).Password

# These dependency groups must be co-located: web app + plan, database + server,
# and OpenAI model deployments + their OpenAI account. Each group retries independently.
$appLocation = Invoke-RegionalFallback -Name 'App Service plan and web app' -CandidateLocations $appServiceCandidateLocations -Deploy {
  param($location)
  Invoke-AzChecked @('deployment', 'group', 'create', '--resource-group', $ResourceGroupName, '--name', "app-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--template-file', (Join-Path $scriptRoot 'infra/components/app-service.bicep'), '--parameters', "location=$location", "webAppName=$webAppName", "appServicePlanSkuTier=$AppServicePlanSkuTier", "appServicePlanSkuName=$AppServicePlanSkuName")
} -Cleanup {
  param($location)
  & az webapp delete --resource-group $ResourceGroupName --name $webAppName 2>$null
  & az appservice plan delete --resource-group $ResourceGroupName --name 'plan-caldova-ordermgmt' --yes 2>$null
}

$sqlLocation = Invoke-RegionalFallback -Name 'SQL server and database' -Deploy {
  param($location)
  Invoke-AzChecked @('deployment', 'group', 'create', '--resource-group', $ResourceGroupName, '--name', "sql-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--template-file', (Join-Path $scriptRoot 'infra/components/sql.bicep'), '--parameters', "location=$location", "sqlServerName=$sqlServerName", "administratorLogin=$SqlAdministratorLogin", "administratorLoginPassword=$passwordText", "entraAdministratorLogin=$SqlEntraAdministratorLogin", "entraAdministratorObjectId=$SqlEntraAdministratorObjectId", "databaseSkuName=$DatabaseSkuName")
} -Cleanup {
  param($location)
  & az sql server delete --resource-group $ResourceGroupName --name $sqlServerName --yes 2>$null
}

$openAiLocation = Invoke-RegionalFallback -Name 'Azure OpenAI account and model deployments' -CandidateLocations $openAiCandidateLocations -MaxAttemptsPerLocation 12 -RetryDelaySeconds 30 -Deploy {
  param($location)
  Invoke-AzChecked @('deployment', 'group', 'create', '--resource-group', $ResourceGroupName, '--name', "openai-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--template-file', (Join-Path $scriptRoot 'infra/components/openai.bicep'), '--parameters', "location=$location", "openAiAccountName=$openAiAccountName", "chatModelVersion=$ChatModelVersion", "embeddingModelVersion=$EmbeddingModelVersion", "embeddingModelCapacity=$EmbeddingModelCapacity")
} -Cleanup {
  param($location)
  & az cognitiveservices account delete --resource-group $ResourceGroupName --name $openAiAccountName --yes 2>$null
}

Write-Host "Deployment complete. Resource group: $ResourceGroupName ($resourceGroupLocation)"
Write-Host "App Service: $appLocation | SQL: $sqlLocation | Azure OpenAI: $openAiLocation"
