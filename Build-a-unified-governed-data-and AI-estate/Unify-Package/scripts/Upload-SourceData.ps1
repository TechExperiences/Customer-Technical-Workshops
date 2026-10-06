[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$StorageAccountName,
    [string]$ContainerName = 'data'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Test-SourceData.ps1') -PackageRoot $packageRoot

foreach ($folder in @('Analytical', 'BusinessApplication', 'Operational')) {
    $source = Join-Path $packageRoot $folder
    az storage blob upload-batch --account-name $StorageAccountName --auth-mode login `
        --destination $ContainerName --destination-path $folder --source $source --overwrite true
}
