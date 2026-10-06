[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$FabricCapacityResourceId,
    [string]$WorkspaceName = 'Caldova-unify',
    [string]$LakehouseName = 'Caldova_Lakehouse',
    [string]$FabricSqlDatabaseName = 'Caldova_SQLDatabase'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
$python = Get-Command python -ErrorAction Stop

& $python.Source (Join-Path $PSScriptRoot 'deploy_fabric_foundation.py') `
    --capacity-resource-id $FabricCapacityResourceId `
    --workspace $WorkspaceName `
    --lakehouse $LakehouseName `
    --sql-database $FabricSqlDatabaseName
