[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'scripts/Invoke-AzdDeployment.ps1')
