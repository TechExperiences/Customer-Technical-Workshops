[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$ParametersFile,
    [Parameter(Mandatory)] [string]$SqlAdministratorPassword,
    [Parameter(Mandatory)] [string]$SqlEntraAdministratorUpn
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$parameters = Get-Content -LiteralPath $ParametersFile -Raw | ConvertFrom-Json
$values = $parameters.parameters
$resourceGroup = $values.resourceGroupName.value
$storageAccount = $values.storageAccountName.value
$sqlServer = $values.sqlServerName.value
$sqlDatabase = $values.sqlDatabaseName.value
$capacity = $values.fabricCapacityName.value

Write-Host 'Phase 1/5: Provisioning Azure foundation and Fabric capacity.' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'Deploy-Foundation.ps1') -ParametersFile $ParametersFile -SqlAdministratorPassword $SqlAdministratorPassword

Write-Host 'Phase 2/5: Uploading validated source folders to Blob Storage.' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'Upload-SourceData.ps1') -StorageAccountName $storageAccount

Write-Host 'Phase 3/5: Configuring SQL Entra administrator and loading OperationalData.' -ForegroundColor Cyan
& (Join-Path $PSScriptRoot 'Configure-SqlEntraAdmin.ps1') -SqlServerName $sqlServer -AdministratorUpn $SqlEntraAdministratorUpn -ResourceGroupName $resourceGroup
& (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'load_operational_data.py') `
    --server "$sqlServer.database.windows.net" --database $sqlDatabase --reset

Write-Host 'Phase 4/5: Creating Fabric workspace, Lakehouse, and Fabric SQL Database.' -ForegroundColor Cyan
$capacityResourceId = az resource show --resource-group $resourceGroup --resource-type Microsoft.Fabric/capacities `
    --name $capacity --query id -o tsv
if (-not $capacityResourceId) { throw "Fabric capacity $capacity was not found in $resourceGroup." }
if (-not $env:FABRIC_LICENSE_SKU_PART_NUMBER) { $env:FABRIC_LICENSE_SKU_PART_NUMBER = 'FABRIC_FREE' }
& (Join-Path $PSScriptRoot 'Ensure-FabricLicense.ps1') -UserPrincipalName $SqlEntraAdministratorUpn -SkuPartNumber $env:FABRIC_LICENSE_SKU_PART_NUMBER
& (Join-Path $PSScriptRoot 'Deploy-FabricFoundation.ps1') -FabricCapacityResourceId $capacityResourceId

Write-Host 'Phase 5/5: Azure and Fabric foundation deployment completed.' -ForegroundColor Green
Write-Host 'Next: deploy the notebook to the Lakehouse, configure mirroring, and publish the semantic model/Data Agent.' -ForegroundColor Yellow
