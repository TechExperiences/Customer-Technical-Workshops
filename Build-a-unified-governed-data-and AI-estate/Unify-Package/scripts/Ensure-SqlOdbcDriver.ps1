[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$driver = @(Get-OdbcDriver -ErrorAction Stop | Where-Object { $_.Name -eq 'ODBC Driver 18 for SQL Server' })
if ($driver.Count) {
    Write-Host 'ODBC Driver 18 for SQL Server is already installed.' -ForegroundColor Green
    return
}

if (-not (Get-Command winget -ErrorAction Ignore)) {
    throw 'Microsoft ODBC Driver 18 for SQL Server is required, but winget is unavailable on this VM.'
}

Write-Host 'Installing Microsoft ODBC Driver 18 for SQL Server before Azure provisioning...' -ForegroundColor Cyan
& winget install --id Microsoft.msodbcsql.18 --exact --source winget --accept-package-agreements --accept-source-agreements
if ($LASTEXITCODE -ne 0) { throw 'ODBC Driver 18 installation failed.' }

$driver = @(Get-OdbcDriver -ErrorAction Stop | Where-Object { $_.Name -eq 'ODBC Driver 18 for SQL Server' })
if (-not $driver.Count) { throw 'ODBC Driver 18 installation completed but the driver is not registered with Windows.' }
Write-Host 'ODBC Driver 18 for SQL Server is installed and ready.' -ForegroundColor Green
