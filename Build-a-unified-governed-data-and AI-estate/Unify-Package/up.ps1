[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/Ensure-SqlOdbcDriver.ps1')
& (Join-Path $PSScriptRoot 'scripts/Invoke-AzdDeployment.ps1')
