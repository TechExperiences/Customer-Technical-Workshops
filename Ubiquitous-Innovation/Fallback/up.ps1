[CmdletBinding()]
param(
    [string]$EnvFile = (Join-Path $PSScriptRoot '.env')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-Checked {
    param([Parameter(Mandatory)] [scriptblock]$Command, [Parameter(Mandatory)] [string]$FailureMessage)
    & $Command
    if ($LASTEXITCODE -ne 0) { throw $FailureMessage }
}

function Import-DotEnv {
    param([Parameter(Mandatory)] [string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Environment file was not found: $Path. Copy .env.example to .env and set its values."
    }
    $values = [ordered]@{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $trimmed = $line.Trim()
        if (-not $trimmed -or $trimmed.StartsWith('#')) { continue }
        if ($trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') { throw "Invalid .env entry: $line" }
        $name, $value = $Matches[1], $Matches[2].Trim()
        if ($value.Length -ge 2 -and (($value.StartsWith('"') -and $value.EndsWith('"')) -or ($value.StartsWith("'") -and $value.EndsWith("'")))) {
            $value = $value.Substring(1, $value.Length - 2)
        }
        $values[$name] = $value
    }
    return $values
}

function New-RandomSuffix {
    $alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789'.ToCharArray()
    $bytes = New-Object byte[] 5
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    return -join ($bytes | ForEach-Object { $alphabet[$_ % $alphabet.Length] })
}

function Test-ServicePrincipalAzureCliSession {
    param([Parameter(Mandatory)] [string]$ClientId, [Parameter(Mandatory)] [string]$TenantId)
    $accountJson = & az account show --only-show-errors --output json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $accountJson) { return $false }
    try {
        $account = $accountJson | ConvertFrom-Json
        return $account.user.type -eq 'servicePrincipal' -and $account.user.name -eq $ClientId -and $account.tenantId -eq $TenantId
    } catch { return $false }
}

function Get-TokenObjectId {
    param([Parameter(Mandatory)] [string]$AccessToken)
    $segments = $AccessToken.Split('.')
    if ($segments.Length -lt 2) { throw 'Azure access token is not a JWT.' }
    $payload = $segments[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
        1 { throw 'Azure access token payload is invalid.' }
    }
    $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
    if (-not $claims.oid) { throw 'Azure access token did not contain the service principal object ID.' }
    return [string]$claims.oid
}

if (-not (Get-Command az -ErrorAction Ignore)) { throw 'Azure CLI (az) is required.' }
if (-not (Get-Command python -ErrorAction Ignore)) { throw 'Python is required.' }

$configuration = Import-DotEnv -Path (Resolve-Path -LiteralPath $EnvFile)
foreach ($required in @('AZURE_SUBSCRIPTION_ID', 'AZURE_TENANT_ID', 'AZURE_CLIENT_ID', 'AZURE_CLIENT_SECRET', 'AZURE_LOCATION', 'AZURE_RESOURCE_GROUP', 'FABRIC_CAPACITY_ADMIN_UPN')) {
    $value = [string]$configuration[$required]
    if (-not $value -or $value -match '^<.*>$') { throw "Set a real value for $required in $EnvFile." }
    Set-Item -Path "Env:$required" -Value $value
}

$Location = $env:AZURE_LOCATION
$FoundryLocation = 'westus'
$ResourceGroupName = $env:AZURE_RESOURCE_GROUP
$SourceFabricResourceGroup = 'rg-Ubiquitous'
$PortalUserUpn = $env:FABRIC_CAPACITY_ADMIN_UPN
$BlobSourceFolder = Join-Path $PSScriptRoot 'BlobData'
$SharepointSourceFolder = Join-Path $PSScriptRoot 'Sharepoint'
if ($ResourceGroupName -ne 'rg-Ubiquitous-Innovation') { throw 'AZURE_RESOURCE_GROUP must be rg-Ubiquitous-Innovation for this creation-only workflow.' }
foreach ($sourceFolder in @($BlobSourceFolder, $SharepointSourceFolder)) {
    if (-not (Test-Path -LiteralPath $sourceFolder -PathType Container)) { throw "Source folder does not exist: $sourceFolder" }
    if (-not (Get-ChildItem -LiteralPath $sourceFolder -Recurse -File | Select-Object -First 1)) { throw "Source folder contains no files: $sourceFolder" }
}

if (Test-ServicePrincipalAzureCliSession -ClientId $env:AZURE_CLIENT_ID -TenantId $env:AZURE_TENANT_ID) {
    Write-Host 'Using the existing Azure CLI session for the configured service principal.' -ForegroundColor Cyan
} else {
    Write-Host 'Signing in to Azure CLI with the configured service principal...' -ForegroundColor Cyan
    & az login --service-principal --username $env:AZURE_CLIENT_ID --password $env:AZURE_CLIENT_SECRET --tenant $env:AZURE_TENANT_ID --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw 'Azure CLI service-principal sign-in did not complete.' }
}
Invoke-Checked { az account set --subscription $env:AZURE_SUBSCRIPTION_ID --only-show-errors } "Could not select subscription $($env:AZURE_SUBSCRIPTION_ID)."

$resourceGroupExists = (& az group exists --name $ResourceGroupName --only-show-errors).Trim()
if ($LASTEXITCODE -ne 0) { throw "Could not check whether resource group $ResourceGroupName exists." }
if ($resourceGroupExists -eq 'true') { throw "Resource group $ResourceGroupName already exists. This workflow is creation-only and will not reuse it." }

$managementAccessToken = (& az account get-access-token --resource https://management.azure.com/ --query accessToken -o tsv).Trim()
if ($LASTEXITCODE -ne 0 -or -not $managementAccessToken) { throw 'Could not acquire an Azure Resource Manager access token.' }
$automationPrincipalId = Get-TokenObjectId -AccessToken $managementAccessToken
$portalUserPrincipalId = (& az ad user show --id $PortalUserUpn --query id -o tsv).Trim()
if ($LASTEXITCODE -ne 0 -or -not $portalUserPrincipalId) {
    throw "Could not resolve FABRIC_CAPACITY_ADMIN_UPN $PortalUserUpn to an Entra user object ID. The service principal needs Microsoft Graph User.Read.All application permission with admin consent."
}

# Discover the published source agent before changing Azure state. The source RG
# is the only fixed reference; no workspace, agent ID, or MCP URL is configured.
$env:AZURE_FABRIC_ACCESS_TOKEN = (& az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv).Trim()
if (-not $env:AZURE_FABRIC_ACCESS_TOKEN) { throw 'Could not acquire a Fabric access token.' }
$sourceCapacityJson = & az resource list --resource-group $SourceFabricResourceGroup --resource-type Microsoft.Fabric/capacities --only-show-errors --output json
if ($LASTEXITCODE -ne 0 -or -not $sourceCapacityJson) { throw "Could not enumerate Fabric capacities in $SourceFabricResourceGroup." }
$sourceCapacities = @($sourceCapacityJson | ConvertFrom-Json)
if ($sourceCapacities.Count -ne 1 -or -not $sourceCapacities[0].name) {
    throw "Expected exactly one Fabric capacity in $SourceFabricResourceGroup; found $($sourceCapacities.Count)."
}
$sourceAgent = & python (Join-Path $PSScriptRoot 'scripts/discover_fabric_data_agent.py') --capacity-name $sourceCapacities[0].name | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $sourceAgent.mcpUrl) { throw 'Could not discover one published source Fabric Data Agent.' }
Write-Host 'Discovered the source Fabric Data Agent automatically.' -ForegroundColor Cyan

$suffix = ''
$StorageAccountName = ''
for ($attempt = 1; $attempt -le 12; $attempt++) {
    $candidateSuffix = New-RandomSuffix
    $candidateStorageAccountName = "adlsubiquitous$candidateSuffix"
    $nameAvailable = (& az storage account check-name --name $candidateStorageAccountName --query nameAvailable -o tsv --only-show-errors).Trim()
    if ($LASTEXITCODE -ne 0) { throw "Could not check availability of storage account name $candidateStorageAccountName." }
    if ($nameAvailable -eq 'true') {
        $suffix = $candidateSuffix
        $StorageAccountName = $candidateStorageAccountName
        break
    }
}
if (-not $suffix) { throw 'Could not generate an available ADLS Gen2 storage account name after 12 attempts.' }

$SearchServiceName = "searchubiquitous$suffix"
$CosmosAccountName = "cosmosubiquitous$suffix"
$FoundryAccountName = "foundryfallback$suffix"
$FoundryProjectName = 'ubiquitous-innovation-project'

Write-Host "Creating resource group $ResourceGroupName in $Location..." -ForegroundColor Cyan
Invoke-Checked { az group create --name $ResourceGroupName --location $Location --only-show-errors 1>$null } "Could not create resource group $ResourceGroupName."

Write-Host "Creating ADLS Gen2 account $StorageAccountName, Search $SearchServiceName, serverless Cosmos $CosmosAccountName, and Foundry project $FoundryProjectName..." -ForegroundColor Cyan
Invoke-Checked {
    az deployment group create --resource-group $ResourceGroupName --template-file (Join-Path $PSScriptRoot 'infra/main.bicep') `
        --parameters location=$Location storageAccountName=$StorageAccountName searchServiceName=$SearchServiceName cosmosAccountName=$CosmosAccountName `
        foundryAccountName=$FoundryAccountName foundryProjectName=$FoundryProjectName foundryLocation=$FoundryLocation `
        automationPrincipalId=$automationPrincipalId portalUserPrincipalId=$portalUserPrincipalId --only-show-errors 1>$null
} 'ADLS Gen2, Search, Cosmos DB, or Foundry Standard Agent Setup deployment failed.'

Invoke-Checked { python -m pip install --disable-pip-version-check -q -r (Join-Path $PSScriptRoot 'requirements.txt') } 'Could not install the Python dependencies.'
$env:AZURE_STORAGE_ACCESS_TOKEN = (& az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv).Trim()
if (-not $env:AZURE_STORAGE_ACCESS_TOKEN) { throw 'Could not acquire a Storage access token.' }

try {
    Write-Host "Uploading local data from $BlobSourceFolder to ADLS Gen2 container data..." -ForegroundColor Cyan
    Invoke-Checked {
        python (Join-Path $PSScriptRoot 'scripts/upload_to_adls.py') --storage-account-name $StorageAccountName --container data --source-folder $BlobSourceFolder
    } 'ADLS Gen2 data upload failed.'

    Write-Host "Uploading local data from $SharepointSourceFolder to ADLS Gen2 container sharepoint..." -ForegroundColor Cyan
    Invoke-Checked {
        python (Join-Path $PSScriptRoot 'scripts/upload_to_adls.py') --storage-account-name $StorageAccountName --container sharepoint --source-folder $SharepointSourceFolder
    } 'ADLS Gen2 SharePoint-source upload failed.'

    Write-Host 'Indexing the data and sharepoint containers in the Foundry knowledge base...' -ForegroundColor Cyan
    $knowledgeOutput = & python (Join-Path $PSScriptRoot 'scripts/create_knowledge_base.py') `
        --storage-account-name $StorageAccountName --foundry-account-name $FoundryAccountName --project-name $FoundryProjectName
    if ($LASTEXITCODE -ne 0) { throw 'Foundry knowledge-base creation failed.' }
    $vectorStoreId = [string]($knowledgeOutput | Select-Object -Last 1)
    if (-not $vectorStoreId) { throw 'Foundry knowledge-base creation did not return a vector store ID.' }

    Write-Host 'Creating the Foundry Supply Chain agent with Fabric analytics and document knowledge tools...' -ForegroundColor Cyan
    Invoke-Checked {
        python (Join-Path $PSScriptRoot 'scripts/deploy_foundry_agent.py') `
            --foundry-account-name $FoundryAccountName --project-name $FoundryProjectName --model-deployment-name gpt5mini `
            --vector-store-id $vectorStoreId --fabric-mcp-url $sourceAgent.mcpUrl
    } 'Foundry agent deployment failed.'

    Write-Host "Completed. Storage account: $StorageAccountName; containers: data, sharepoint; Search: $SearchServiceName; Cosmos: $CosmosAccountName; Foundry project: $FoundryProjectName; Foundry agent: supply-chain-bi-agent." -ForegroundColor Green
} finally {
    Remove-Item Env:AZURE_FABRIC_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_STORAGE_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
