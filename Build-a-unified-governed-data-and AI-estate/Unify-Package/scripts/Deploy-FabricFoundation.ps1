[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$FabricCapacityResourceId,
    [string]$WorkspaceName,
    [string]$LakehouseName = 'Caldova_Lakehouse',
    [string]$FabricSqlDatabaseName = 'Caldova_SQLDatabase'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$python = Get-Command python -ErrorAction Stop

if (-not $WorkspaceName) {
    # Fabric workspace display names are reserved tenant-wide, not just among workspaces
    # the current caller can see - confirmed directly against this sandbox tenant: POST
    # /workspaces returned 409 WorkspaceNameAlreadyExists for "Caldova-Build-Unify" while
    # GET /workspaces (which only lists workspaces the caller has a role on) didn't show
    # any such workspace at all. A bare constant name can collide with another session's
    # (or an orphaned, now-invisible) workspace in this shared sandbox. Reuse the same
    # uniqueString(subscription().id, resourceGroupName) suffix main.bicep already uses
    # for the storage account/capacity names - stable across re-runs of this same
    # subscription+resource group, but unique across other sandbox sessions.
    $capacitySuffix = ($FabricCapacityResourceId -split '/fabriccapacity')[-1]
    $WorkspaceName = "Caldova-Build-Unify-$capacitySuffix"
}

$result = & $python.Source (Join-Path $PSScriptRoot 'deploy_fabric_foundation.py') `
    --capacity-resource-id $FabricCapacityResourceId `
    --workspace $WorkspaceName `
    --lakehouse $LakehouseName `
    --sql-database $FabricSqlDatabaseName
if ($LASTEXITCODE -ne 0) { throw 'Fabric workspace, Lakehouse, or Fabric SQL database provisioning failed.' }

# The Python command emits one JSON object so subsequent pipeline steps can use the
# immutable workspace and Lakehouse IDs rather than looking up a display name again.
return (($result -join [Environment]::NewLine) | ConvertFrom-Json)
