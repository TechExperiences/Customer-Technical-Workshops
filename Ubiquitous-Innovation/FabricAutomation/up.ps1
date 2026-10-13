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
        if ($trimmed -notmatch '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            throw "Invalid .env entry: $line"
        }
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

if (-not (Get-Command az -ErrorAction Ignore)) { throw 'Azure CLI (az) is required.' }
if (-not (Get-Command azd -ErrorAction Ignore)) { throw 'Azure Developer CLI (azd) is required.' }
if (-not (Get-Command python -ErrorAction Ignore)) { throw 'Python is required.' }
$configuration = Import-DotEnv -Path (Resolve-Path -LiteralPath $EnvFile)
foreach ($required in @('AZURE_ENV_NAME', 'AZURE_SUBSCRIPTION_ID', 'AZURE_TENANT_ID', 'AZURE_LOCATION', 'AZURE_RESOURCE_GROUP', 'FABRIC_CAPACITY_ADMIN_UPN')) {
    $value = [string]$configuration[$required]
    if (-not $value -or $value -match '^<.*>$') { throw "Set a real value for $required in $EnvFile." }
}
foreach ($setting in $configuration.GetEnumerator()) { Set-Item -Path "Env:$($setting.Key)" -Value $setting.Value }

$Location = $env:AZURE_LOCATION
$ResourceGroupName = $env:AZURE_RESOURCE_GROUP
$CapacityAdministratorUpn = $env:FABRIC_CAPACITY_ADMIN_UPN
$LakehouseName = if ($env:LAKEHOUSE_NAME) { $env:LAKEHOUSE_NAME } else { 'Ubiquitous_Lakehouse' }
$SourceFolder = Join-Path $PSScriptRoot 'Fabric Data'
$SharePointSourceFolder = Join-Path $PSScriptRoot 'Sharepoint_doc'
$EnableSharePointUpload = $env:ENABLE_SHAREPOINT_GRAPH_UPLOAD -eq 'true'
$ProvisionSharePointWrite = $env:PROVISION_SHAREPOINT_SITE_WRITE -eq 'true'
if ($ResourceGroupName -ne 'rg-Ubiquitous') { throw 'AZURE_RESOURCE_GROUP must be rg-Ubiquitous for this creation-only workflow.' }
if (-not (Test-Path -LiteralPath $SourceFolder -PathType Container)) {
    throw "Source folder does not exist: $SourceFolder"
}
if (-not (Get-ChildItem -LiteralPath $SourceFolder -Recurse -File | Select-Object -First 1)) {
    throw "Source folder contains no files: $SourceFolder"
}
if ($EnableSharePointUpload) {
    if (-not (Test-Path -LiteralPath $SharePointSourceFolder -PathType Container) -or -not (Get-ChildItem -LiteralPath $SharePointSourceFolder -Recurse -File | Select-Object -First 1)) {
        throw "SharePoint source folder is missing or empty: $SharePointSourceFolder"
    }
    foreach ($setting in @('SHAREPOINT_TENANT_ID', 'SHAREPOINT_CLIENT_ID', 'SHAREPOINT_CLIENT_SECRET', 'SHAREPOINT_SITE_URL', 'SHAREPOINT_LIBRARY_NAME', 'SHAREPOINT_DESTINATION_FOLDER')) {
        $value = [string](Get-Item "Env:$setting" -ErrorAction SilentlyContinue).Value
        if (-not $value -or $value -match '^<.*>$') { throw "Set a real value for $setting in .env before enabling SharePoint upload." }
    }
}

& az account show --only-show-errors 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'No active Azure CLI session was found. Starting Azure sign-in...' -ForegroundColor Cyan
    & az login --tenant $env:AZURE_TENANT_ID --only-show-errors
    if ($LASTEXITCODE -ne 0) { throw 'Azure CLI sign-in did not complete.' }
}
Invoke-Checked { az account set --subscription $env:AZURE_SUBSCRIPTION_ID --only-show-errors } "Could not select subscription $($env:AZURE_SUBSCRIPTION_ID)."

& azd auth login --check-status 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host 'No active Azure Developer CLI session was found. Starting Azure Developer CLI sign-in...' -ForegroundColor Cyan
    Invoke-Checked { azd auth login --tenant-id $env:AZURE_TENANT_ID } 'Azure Developer CLI sign-in did not complete.'
}
& azd env select $env:AZURE_ENV_NAME 1>$null 2>$null
if ($LASTEXITCODE -ne 0) {
    Invoke-Checked {
        azd env new $env:AZURE_ENV_NAME --subscription $env:AZURE_SUBSCRIPTION_ID --location $Location --no-prompt
    } "Could not create Azure Developer CLI environment $($env:AZURE_ENV_NAME)."
}
foreach ($setting in $configuration.GetEnumerator() | Where-Object { $_.Key -ne 'SHAREPOINT_CLIENT_SECRET' }) {
    Invoke-Checked { azd env set $setting.Key $setting.Value --environment $env:AZURE_ENV_NAME } "Could not save $($setting.Key) to the Azure Developer CLI environment."
}
# Read the effective values back from azd so all subsequent provisioning uses the
# selected Azure Developer CLI environment, not merely the original .env process values.
foreach ($setting in $configuration.GetEnumerator() | Where-Object { $_.Key -ne 'SHAREPOINT_CLIENT_SECRET' }) {
    $effectiveValue = (& azd env get-value $setting.Key --environment $env:AZURE_ENV_NAME).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $effectiveValue) {
        throw "Could not read $($setting.Key) from the Azure Developer CLI environment."
    }
    Set-Item -Path "Env:$($setting.Key)" -Value $effectiveValue
}
$Location = $env:AZURE_LOCATION
$ResourceGroupName = $env:AZURE_RESOURCE_GROUP
$CapacityAdministratorUpn = $env:FABRIC_CAPACITY_ADMIN_UPN
$LakehouseName = if ($env:LAKEHOUSE_NAME) { $env:LAKEHOUSE_NAME } else { 'Ubiquitous_Lakehouse' }
$SourceFolder = Join-Path $PSScriptRoot 'Fabric Data'
$SharePointSourceFolder = Join-Path $PSScriptRoot 'Sharepoint_doc'
$EnableSharePointUpload = $env:ENABLE_SHAREPOINT_GRAPH_UPLOAD -eq 'true'
$ProvisionSharePointWrite = $env:PROVISION_SHAREPOINT_SITE_WRITE -eq 'true'
Write-Host "Saved .env values to Azure Developer CLI environment $($env:AZURE_ENV_NAME)." -ForegroundColor Cyan

# Complete the user entitlement check before creating the resource group or the F16
# capacity, so a licensing failure cannot leave billable deployment resources behind.
& (Join-Path $PSScriptRoot 'scripts/Ensure-FabricLicense.ps1') -UserPrincipalName $CapacityAdministratorUpn

if ($EnableSharePointUpload -and $ProvisionSharePointWrite) {
    & (Join-Path $PSScriptRoot 'scripts/Grant-ServicePrincipalSharePointWrite.ps1') `
        -ClientId $env:SHAREPOINT_CLIENT_ID -SharePointSiteUrl $env:SHAREPOINT_SITE_URL
}

# This deployment intentionally never reuses an existing resource group.  A second
# invocation must use a clean subscription or a different requested group name.
$resourceGroupExists = (& az group exists --name $ResourceGroupName --only-show-errors).Trim()
if ($LASTEXITCODE -ne 0) { throw "Could not check whether resource group $ResourceGroupName exists." }
if ($resourceGroupExists -eq 'true') {
    throw "Resource group $ResourceGroupName already exists. This workflow is creation-only and will not reuse it."
}

$suffix = New-RandomSuffix
$capacityName = "fabricubiquitous$suffix"
$workspaceName = "Ubiquitous-Innovation-$suffix"

Write-Host "Creating resource group $ResourceGroupName in $Location..." -ForegroundColor Cyan
Invoke-Checked { az group create --name $ResourceGroupName --location $Location --only-show-errors 1>$null } "Could not create resource group $ResourceGroupName."

Write-Host "Creating F16 Fabric capacity $capacityName..." -ForegroundColor Cyan
Invoke-Checked {
    az deployment group create --resource-group $ResourceGroupName --template-file (Join-Path $PSScriptRoot 'infra/main.bicep') `
        --parameters capacityName=$capacityName location=$Location capacityAdministratorUpn=$CapacityAdministratorUpn --only-show-errors 1>$null
} 'Fabric capacity deployment failed.'

$capacityResourceId = (& az resource show --resource-group $ResourceGroupName --resource-type Microsoft.Fabric/capacities --name $capacityName --query id -o tsv).Trim()
if ($LASTEXITCODE -ne 0 -or -not $capacityResourceId) { throw 'The newly created Fabric capacity could not be resolved.' }
$workspaceAdminPrincipalId = (& az ad user show --id $CapacityAdministratorUpn --query id -o tsv).Trim()
if ($LASTEXITCODE -ne 0 -or -not $workspaceAdminPrincipalId) {
    throw "Could not resolve Fabric capacity administrator UPN $CapacityAdministratorUpn to an Entra user object ID."
}

Invoke-Checked { python -m pip install --disable-pip-version-check -q -r (Join-Path $PSScriptRoot 'requirements.txt') } 'Could not install the Python dependencies.'
$env:AZURE_FABRIC_ACCESS_TOKEN = (& az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv).Trim()
$env:AZURE_STORAGE_ACCESS_TOKEN = (& az account get-access-token --resource https://storage.azure.com/ --query accessToken -o tsv).Trim()
if (-not $env:AZURE_FABRIC_ACCESS_TOKEN -or -not $env:AZURE_STORAGE_ACCESS_TOKEN) { throw 'Could not acquire Fabric or Storage access tokens.' }

try {
    Write-Host "Creating workspace $workspaceName and Lakehouse $LakehouseName..." -ForegroundColor Cyan
    $fabric = & python (Join-Path $PSScriptRoot 'scripts/provision_fabric.py') `
        --capacity-resource-id $capacityResourceId --workspace-name $workspaceName --lakehouse-name $LakehouseName `
        --workspace-admin-principal-id $workspaceAdminPrincipalId | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $fabric.workspaceId -or -not $fabric.lakehouseId) {
        throw 'Workspace or Lakehouse creation did not return IDs.'
    }

    Write-Host "Uploading local data from $SourceFolder to the new Lakehouse..." -ForegroundColor Cyan
    Invoke-Checked {
        python (Join-Path $PSScriptRoot 'scripts/ingest_to_lakehouse.py') `
            --workspace-id $fabric.workspaceId --lakehouse-id $fabric.lakehouseId --source-folder $SourceFolder
    } 'Lakehouse ingestion failed.'

    if ($EnableSharePointUpload) {
        Write-Host "Uploading SharePoint documents from $SharePointSourceFolder through the service principal..." -ForegroundColor Cyan
        Invoke-Checked {
            python (Join-Path $PSScriptRoot 'scripts/upload_sharepoint_documents.py') `
                --source-folder $SharePointSourceFolder `
                --tenant-id $env:SHAREPOINT_TENANT_ID `
                --client-id $env:SHAREPOINT_CLIENT_ID `
                --site-url $env:SHAREPOINT_SITE_URL `
                --library-name $env:SHAREPOINT_LIBRARY_NAME `
                --destination-folder $env:SHAREPOINT_DESTINATION_FOLDER
        } 'SharePoint document upload failed.'
    }

    Write-Host "Completed. Workspace: $workspaceName; Lakehouse: $LakehouseName" -ForegroundColor Green
} finally {
    Remove-Item Env:AZURE_FABRIC_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_STORAGE_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
