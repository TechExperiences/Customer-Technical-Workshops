[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$SqlServerName,
    [Parameter(Mandatory)] [string]$AdministratorUpn,
    [string]$ResourceGroupName = 'rg-Unified'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$administrator = az ad user show --id $AdministratorUpn --query '{objectId:id,displayName:displayName}' -o json | ConvertFrom-Json
if (-not $administrator.objectId) { throw "Could not resolve Entra user $AdministratorUpn." }

az sql server ad-admin create --resource-group $ResourceGroupName --server $SqlServerName `
    --display-name $administrator.displayName --object-id $administrator.objectId
