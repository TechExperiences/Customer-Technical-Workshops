[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$resourceGroup = if ($env:AZURE_RESOURCE_GROUP) { $env:AZURE_RESOURCE_GROUP } else { 'rg-Build-Unify' }

function Get-AzureAccessToken {
    param(
        [Parameter(Mandatory)] [string]$Resource,
        [Parameter(Mandatory)] [string]$Purpose
    )

    $accessToken = (& az account get-access-token --resource $Resource --query accessToken -o tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $accessToken) { throw "Could not acquire an Entra access token for $Purpose." }
    return $accessToken
}

$storageAccount = az storage account list --resource-group $resourceGroup --query '[0].name' -o tsv
$sqlServer = $env:SQL_SERVER_NAME
$capacityResourceId = az resource list --resource-group $resourceGroup --resource-type Microsoft.Fabric/capacities --query '[0].id' -o tsv
if (-not $storageAccount -or -not $sqlServer -or -not $capacityResourceId) {
    throw 'Expected Storage Account, Azure SQL Server, and Fabric Capacity were not found after provisioning.'
}

& az sql server show --resource-group $resourceGroup --name $sqlServer --only-show-errors 1>$null
if ($LASTEXITCODE -ne 0) { throw "The SQL Server created for this run was not found: $sqlServer" }

& (Join-Path $PSScriptRoot 'Upload-SourceData.ps1') -StorageAccountName $storageAccount
& (Join-Path $PSScriptRoot 'Configure-SqlEntraAdmin.ps1') -SqlServerName $sqlServer -AdministratorUpn $env:FABRIC_CAPACITY_ADMIN_UPN -ResourceGroupName $resourceGroup

& (Get-Command python -ErrorAction Stop).Source -m pip install --disable-pip-version-check -q -r (Join-Path $packageRoot 'requirements.txt')
$env:AZURE_SQL_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://database.windows.net' -Purpose 'Azure SQL'
try {
    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'load_operational_data.py') --server "$sqlServer.database.windows.net" --reset
    if ($LASTEXITCODE -ne 0) { throw 'Operational data load failed. Fabric licensing and workspace creation were not attempted.' }
} finally {
    Remove-Item Env:AZURE_SQL_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
& (Join-Path $PSScriptRoot 'Ensure-FabricLicense.ps1') -UserPrincipalName $env:FABRIC_CAPACITY_ADMIN_UPN

# Python inherits these process-only tokens.  It never needs to locate az.exe, and
# none of the token values are written to .env, azd settings, or source control.
$env:AZURE_FABRIC_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://api.fabric.microsoft.com' -Purpose 'Microsoft Fabric'
$env:AZURE_STORAGE_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://storage.azure.com/' -Purpose 'Azure Blob Storage and OneLake'
try {
    $fabric = & (Join-Path $PSScriptRoot 'Deploy-FabricFoundation.ps1') -FabricCapacityResourceId $capacityResourceId
    if (-not $fabric.workspaceId -or -not $fabric.lakehouseId) {
        throw 'Fabric foundation provisioning did not return a workspace or Lakehouse ID.'
    }
    $logicAppPrincipalId = (az logic workflow show --resource-group $resourceGroup --name caldova-businessapp-ingest `
        --query identity.principalId -o tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $logicAppPrincipalId) {
        throw 'The managed identity for caldova-businessapp-ingest was not created.'
    }
    $logicAppApplicationId = (az ad sp show --id $logicAppPrincipalId --query appId -o tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $logicAppApplicationId) {
        throw 'Could not resolve the Logic App managed identity application ID in Microsoft Entra.'
    }
    $env:AZURE_POWERBI_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://analysis.windows.net/powerbi/api' -Purpose 'Fabric workspace access assignment'
    try {
        & (Join-Path $PSScriptRoot 'Grant-LogicAppFabricAccess.ps1') `
            -WorkspaceId $fabric.workspaceId `
            -LogicAppApplicationId $logicAppApplicationId `
            -PowerBiAccessToken $env:AZURE_POWERBI_ACCESS_TOKEN
    } finally {
        Remove-Item Env:AZURE_POWERBI_ACCESS_TOKEN -ErrorAction SilentlyContinue
    }
    & (Join-Path $PSScriptRoot 'Copy-BlobDataToLakehouse.ps1') `
        -StorageAccountName $storageAccount `
        -WorkspaceId $fabric.workspaceId `
        -LakehouseId $fabric.lakehouseId `
        -SourceFolders @('Analytical', 'Operational')
    & (Join-Path $PSScriptRoot 'Remove-OperationalBlobs.ps1') -StorageAccountName $storageAccount
} finally {
    Remove-Item Env:AZURE_FABRIC_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_STORAGE_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
