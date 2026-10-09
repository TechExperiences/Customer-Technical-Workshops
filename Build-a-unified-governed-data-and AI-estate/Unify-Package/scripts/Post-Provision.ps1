[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$resourceGroup = if ($env:AZURE_RESOURCE_GROUP) { $env:AZURE_RESOURCE_GROUP } else { 'rg-Build-Unify' }

# UNIFY-SP-SUPPORT: this package was written for an interactive user. When the deployment is signed in
# as a service principal (unattended lab VM), three things differ and are handled below:
#   1. the operational data load connects with the signed-in identity's token, so that identity must be the
#      Azure SQL Entra admin while loading (the lab user is made admin right afterwards);
#   2. the Fabric/Power BI licence step is for the lab user only and is not needed by the service principal,
#      so a failure there is a warning instead of stopping the deployment;
#   3. the workspace creator is the service principal - the lab user is added to the workspace by the caller.
$signedInAccount = az account show --query user -o json | ConvertFrom-Json
$runningAsServicePrincipal = ($signedInAccount.type -eq 'servicePrincipal')

function Get-TokenObjectId {
    param([Parameter(Mandatory)] [string]$AccessToken)
    # The "oid" claim is the object id that Azure SQL compares with the Entra admin SID.
    $payload = $AccessToken.Split('.')[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) { 2 { $payload += '==' } 3 { $payload += '=' } }
    return ([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json).oid
}

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
if ($runningAsServicePrincipal) {
    $operatorObjectId = Get-TokenObjectId -AccessToken (Get-AzureAccessToken -Resource 'https://database.windows.net' -Purpose 'Azure SQL')
    az sql server ad-admin create --resource-group $resourceGroup --server $sqlServer `
        --display-name $signedInAccount.name --object-id $operatorObjectId
    if ($LASTEXITCODE -ne 0) { throw 'Could not make the deploying service principal the Azure SQL Entra administrator.' }
    Write-Host 'Waiting for the Entra administrator change to take effect...' -ForegroundColor Yellow
    Start-Sleep -Seconds 90
} else {
    & (Join-Path $PSScriptRoot 'Configure-SqlEntraAdmin.ps1') -SqlServerName $sqlServer -AdministratorUpn $env:FABRIC_CAPACITY_ADMIN_UPN -ResourceGroupName $resourceGroup
}

& (Get-Command python -ErrorAction Stop).Source -m pip install --disable-pip-version-check -q -r (Join-Path $packageRoot 'requirements.txt')
$env:AZURE_SQL_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://database.windows.net' -Purpose 'Azure SQL'
try {
    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'load_operational_data.py') --server "$sqlServer.database.windows.net" --reset
    if ($LASTEXITCODE -ne 0) { throw 'Operational data load failed. Fabric licensing and workspace creation were not attempted.' }
} finally {
    Remove-Item Env:AZURE_SQL_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
if ($runningAsServicePrincipal) {
    & (Join-Path $PSScriptRoot 'Configure-SqlEntraAdmin.ps1') -SqlServerName $sqlServer -AdministratorUpn $env:FABRIC_CAPACITY_ADMIN_UPN -ResourceGroupName $resourceGroup
}
try {
    & (Join-Path $PSScriptRoot 'Ensure-FabricLicense.ps1') -UserPrincipalName $env:FABRIC_CAPACITY_ADMIN_UPN
} catch {
    if (-not $runningAsServicePrincipal) { throw }
    Write-Warning "Fabric/Power BI licence check for $($env:FABRIC_CAPACITY_ADMIN_UPN) did not complete: $($_.Exception.Message) Continuing - the service principal does not need a licence, but the lab user does before using the Fabric portal."
}

# Python inherits these process-only tokens.  It never needs to locate az.exe, and
# none of the token values are written to .env, azd settings, or source control.
$env:AZURE_FABRIC_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://api.fabric.microsoft.com' -Purpose 'Microsoft Fabric'
$env:AZURE_STORAGE_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://storage.azure.com/' -Purpose 'Azure Blob Storage and OneLake'
$env:AZURE_POWERBI_ACCESS_TOKEN = Get-AzureAccessToken -Resource 'https://analysis.windows.net/powerbi/api' -Purpose 'Power BI semantic model refresh'
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
        -SourceFolders @('Analytical', 'Operational', 'BusinessApplication')
    & (Join-Path $PSScriptRoot 'Remove-OperationalBlobs.ps1') -StorageAccountName $storageAccount

    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_lakehouse_notebook.py') `
        --workspace-id $fabric.workspaceId --lakehouse-id $fabric.lakehouseId
    if ($LASTEXITCODE -ne 0) { throw 'Lakehouse ingestion notebook deployment/run failed.' }

    $semanticArtifacts = & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_semantic_model.py') `
        --workspace-id $fabric.workspaceId --lakehouse-id $fabric.lakehouseId | ConvertFrom-Json
    if ($LASTEXITCODE -ne 0 -or -not $semanticArtifacts.semanticModelId) { throw 'Semantic model/report deployment failed.' }

    & (Get-Command python -ErrorAction Stop).Source (Join-Path $PSScriptRoot 'deploy_data_agent.py') `
        --workspace-id $fabric.workspaceId --semantic-model-id $semanticArtifacts.semanticModelId
    if ($LASTEXITCODE -ne 0) { throw 'Data agent deployment failed.' }
} finally {
    Remove-Item Env:AZURE_FABRIC_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_STORAGE_ACCESS_TOKEN -ErrorAction SilentlyContinue
    Remove-Item Env:AZURE_POWERBI_ACCESS_TOKEN -ErrorAction SilentlyContinue
}
