[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$resourceGroup = 'rg-Unified'

$storageAccount = az storage account list --resource-group $resourceGroup --query '[0].name' -o tsv
$sqlServer = az sql server list --resource-group $resourceGroup --query '[0].name' -o tsv
$capacityResourceId = az resource list --resource-group $resourceGroup --resource-type Microsoft.Fabric/capacities --query '[0].id' -o tsv
if (-not $storageAccount -or -not $sqlServer -or -not $capacityResourceId) {
    throw 'Expected Storage Account, Azure SQL Server, and Fabric Capacity were not found after provisioning.'
}

& (Join-Path $PSScriptRoot 'Upload-SourceData.ps1') -StorageAccountName $storageAccount
& (Join-Path $PSScriptRoot 'Configure-SqlEntraAdmin.ps1') -SqlServerName $sqlServer -AdministratorUpn $env:FABRIC_CAPACITY_ADMIN_UPN -ResourceGroupName $resourceGroup

& (Get-Command python -ErrorAction Stop).Source -m pip install --disable-pip-version-check -q -r (Join-Path $packageRoot 'requirements.txt')
& (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'load_operational_data.py') --server "$sqlServer.database.windows.net" --reset
& (Join-Path $PSScriptRoot 'Ensure-FabricLicense.ps1') -UserPrincipalName $env:FABRIC_CAPACITY_ADMIN_UPN -SkuPartNumber $env:FABRIC_LICENSE_SKU_PART_NUMBER
& (Join-Path $PSScriptRoot 'Deploy-FabricFoundation.ps1') -FabricCapacityResourceId $capacityResourceId
