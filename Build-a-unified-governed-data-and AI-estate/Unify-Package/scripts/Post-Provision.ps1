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
    if (-not $fabric.sqlDatabaseServerFqdn -or -not $fabric.sqlDatabaseName) {
        throw 'Fabric foundation provisioning did not return the Fabric SQL Database connection details.'
    }

    # Runs as the signed-in operator (the workspace creator, hence its Admin), so CREATE
    # TABLE succeeds regardless of what the Logic App's Contributor access maps to below.
    $env:AZURE_SQL_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://database.windows.net' -Purpose 'Fabric SQL Database schema'
    try {
        & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'prepare_fabric_sql_schema.py') `
            --server $fabric.sqlDatabaseServerFqdn --database $fabric.sqlDatabaseName
        if ($LASTEXITCODE -ne 0) { throw 'Fabric SQL Database BusinessApplication schema creation failed.' }
    } finally {
        Remove-Item Env:AZURE_SQL_ACCESS_TOKEN -ErrorAction SilentlyContinue
    }

    $logicAppPrincipalId = (az logic workflow show --resource-group $resourceGroup --name caldova-businessapp-ingest `
        --query identity.principalId -o tsv).Trim()
    if ($LASTEXITCODE -ne 0 -or -not $logicAppPrincipalId) {
        throw 'The managed identity for caldova-businessapp-ingest was not created.'
    }

    # Uses the Fabric Core role-assignments API with the identity's object ID directly,
    # avoiding the legacy Power BI membership API's separate Microsoft Graph app-ID lookup.
    & (Join-Path $PSScriptRoot 'Grant-LogicAppFabricAccess.ps1') `
        -WorkspaceId $fabric.workspaceId `
        -LogicAppPrincipalId $logicAppPrincipalId `
        -FabricAccessToken $env:AZURE_FABRIC_ACCESS_TOKEN

    & (Join-Path $PSScriptRoot 'Invoke-BusinessApplicationIngestion.ps1') `
        -StorageAccountName $storageAccount `
        -SqlServerFqdn $fabric.sqlDatabaseServerFqdn `
        -SqlDatabaseName $fabric.sqlDatabaseName `
        -ResourceGroupName $resourceGroup

    & (Join-Path $PSScriptRoot 'Copy-BlobDataToLakehouse.ps1') `
        -StorageAccountName $storageAccount `
        -WorkspaceId $fabric.workspaceId `
        -LakehouseId $fabric.lakehouseId `
        -SourceFolders @('Analytical', 'Operational')
    & (Join-Path $PSScriptRoot 'Remove-OperationalBlobs.ps1') -StorageAccountName $storageAccount

    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_lakehouse_notebook.py') `
        --workspace-id $fabric.workspaceId --lakehouse-id $fabric.lakehouseId
    if ($LASTEXITCODE -ne 0) { throw 'Lakehouse ingestion notebook deployment/run failed.' }

    $semanticArtifacts = & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_semantic_model.py') `
        --workspace-id $fabric.workspaceId --lakehouse-id $fabric.lakehouseId `
        --sql-server $fabric.sqlDatabaseServerFqdn --sql-database $fabric.sqlDatabaseName | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $semanticArtifacts.semanticModelId) { throw 'Semantic model/report deployment failed.' }

    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_data_agent.py') `
        --workspace-id $fabric.workspaceId --semantic-model-id $semanticArtifacts.semanticModelId
    if ($LASTEXITCODE -ne 0) { throw 'Data agent deployment failed.' }
} finally {
    Remove-Item Env:AZURE_FABRIC_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_STORAGE_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
