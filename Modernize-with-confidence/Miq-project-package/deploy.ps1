[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $SubscriptionId,

  [string] $ResourceGroupName = 'rg-caldova',

  [string] $SqlAdministratorLogin = 'sqladmincaldova',

  [securestring] $SqlAdministratorPassword,

  [string] $AppServicePlanSkuTier = 'Basic',
  [string] $AppServicePlanSkuName = 'B1',
  [string] $DatabaseSkuName = 'HS_Gen5_2',
  [string] $ChatModelVersion = '2025-08-07',
  [string] $EmbeddingModelVersion = '2'
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
$candidateLocations = @('westus2', 'westus', 'eastus', 'eastus2')
$appServiceCandidateLocations = @('westus2', 'westcentralus', 'westus', 'eastus', 'eastus2')
# App Service names are globally unique, unlike App Service plan names. A subscription
# GUID is globally unique and keeps this generated name stable across reruns.
$webAppName = "app-caldova-ordermgmt-$($SubscriptionId.Replace('-', ''))"

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
    [string[]] $CandidateLocations = $candidateLocations
  )

  foreach ($location in $CandidateLocations) {
    Write-Host "Trying $Name in $location..."
    try {
      & $Deploy $location
      Write-Host "$Name deployed in $location."
      return $location
    }
    catch {
      Write-Warning "$Name failed in ${location}: $($_.Exception.Message)"
      if ($Cleanup) {
        # A failed ARM deployment can leave an earlier, dependent resource behind.
        # Cleanup is limited to names preflight verified as absent before this run.
        try { & $Cleanup $location } catch { Write-Warning "Cleanup after $Name failed in ${location} also failed: $($_.Exception.Message)" }
      }
    }
  }
  throw "$Name could not be deployed in any candidate location: $($CandidateLocations -join ', ')."
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
$passwordText = [System.Net.NetworkCredential]::new('', $SqlAdministratorPassword).Password

# This prevents a failed retry cleanup from ever touching a resource that existed before
# this run. Use a different name, or deliberately remove/rename the existing resource,
# before rerunning this package.
$reservedNames = @($webAppName, 'plan-caldova-ordermgmt', 'sql-caldova-2401974', 'openai-caldova')
foreach ($reservedName in $reservedNames) {
  $found = & az resource list --resource-group $ResourceGroupName --query "[?name=='$reservedName'].id" --output tsv
  if ($LASTEXITCODE -ne 0) { throw "Unable to check existing resource name $reservedName." }
  if ($found) { throw "Resource '$reservedName' already exists in $ResourceGroupName. This script will not modify or delete an existing resource." }
}

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
  Invoke-AzChecked @('deployment', 'group', 'create', '--resource-group', $ResourceGroupName, '--name', "sql-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--template-file', (Join-Path $scriptRoot 'infra/components/sql.bicep'), '--parameters', "location=$location", "administratorLogin=$SqlAdministratorLogin", "administratorLoginPassword=$passwordText", "databaseSkuName=$DatabaseSkuName")
} -Cleanup {
  param($location)
  & az sql server delete --resource-group $ResourceGroupName --name 'sql-caldova-2401974' --yes 2>$null
}

$openAiLocation = Invoke-RegionalFallback -Name 'Azure OpenAI account and model deployments' -Deploy {
  param($location)
  Invoke-AzChecked @('deployment', 'group', 'create', '--resource-group', $ResourceGroupName, '--name', "openai-$location-$([guid]::NewGuid().ToString('N').Substring(0, 8))", '--template-file', (Join-Path $scriptRoot 'infra/components/openai.bicep'), '--parameters', "location=$location", "chatModelVersion=$ChatModelVersion", "embeddingModelVersion=$EmbeddingModelVersion")
} -Cleanup {
  param($location)
  & az cognitiveservices account delete --resource-group $ResourceGroupName --name 'openai-caldova' --yes 2>$null
}

Write-Host "Deployment complete. Resource group: $ResourceGroupName ($resourceGroupLocation)"
Write-Host "App Service: $appLocation | SQL: $sqlLocation | Azure OpenAI: $openAiLocation"
