[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$StorageAccountName,
    [Parameter(Mandatory)] [string]$WorkspaceId,
    [Parameter(Mandatory)] [string]$LakehouseId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$python = Get-Command python -ErrorAction Stop
& $python.Source (Join-Path $PSScriptRoot 'copy_blob_to_lakehouse.py') `
    --storage-account $StorageAccountName `
    --workspace-id $WorkspaceId `
    --lakehouse-id $LakehouseId
if ($LASTEXITCODE -ne 0) { throw 'Copying Blob source files to OneLake failed.' }
