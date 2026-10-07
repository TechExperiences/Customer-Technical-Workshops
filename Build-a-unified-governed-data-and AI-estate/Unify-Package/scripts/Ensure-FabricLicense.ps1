[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$UserPrincipalName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GraphRest {
    param([Parameter(Mandatory)] [ValidateSet('GET', 'POST')] [string]$Method, [Parameter(Mandatory)] [string]$Url, [string]$Body)
    $arguments = @('rest', '--method', $Method, '--url', $Url, '--resource', 'https://graph.microsoft.com', '--headers', 'Content-Type=application/json')
    if ($Body) { $arguments += @('--body', $Body) }
    $response = & az @arguments
    if ($LASTEXITCODE -ne 0) { throw "Microsoft Graph request failed: $Method $Url" }
    return $response | ConvertFrom-Json
}

$encodedUpn = [System.Uri]::EscapeDataString($UserPrincipalName)
$licenseDetails = Invoke-GraphRest -Method GET -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/licenseDetails?`$select=skuId,skuPartNumber"
$assignedFabricLicense = @($licenseDetails.value | Where-Object { $_.skuPartNumber -match 'FABRIC|POWER_BI' } | Select-Object -First 1)
if ($assignedFabricLicense) {
    Write-Host "Existing Fabric/Power BI entitlement $($assignedFabricLicense.skuPartNumber) is already assigned to $UserPrincipalName." -ForegroundColor Green
    return
}

$subscribedSkus = Invoke-GraphRest -Method GET -Url 'https://graph.microsoft.com/v1.0/subscribedSkus?$select=skuId,skuPartNumber,prepaidUnits,consumedUnits'
$freeOrTrialSkus = @($subscribedSkus.value | Where-Object {
    $_.skuPartNumber -in @('FABRIC_FREE', 'POWER_BI_STANDARD') -or
    $_.skuPartNumber -match '(FABRIC|POWER_BI).*(FREE|TRIAL)'
} | Where-Object { ([int]$_.prepaidUnits.enabled - [int]$_.consumedUnits) -gt 0 })
$sku = @($freeOrTrialSkus | Select-Object -First 1)
if (-not $sku) {
    throw 'No assignable free or trial Fabric/Power BI license is exposed by this tenant. Microsoft Graph cannot create or enroll a tenant into a new 60-day trial; it can only assign licenses that the tenant already exposes. Enable the Fabric/Power BI trial or free license once in the Microsoft 365/Fabric admin experience, then rerun .\up.ps1.'
}

$body = @{ addLicenses = @(@{ skuId = $sku.skuId }); removeLicenses = @() } | ConvertTo-Json -Compress
[void](Invoke-GraphRest -Method POST -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/assignLicense" -Body $body)
Write-Host "Assigned free or trial Fabric/Power BI license $($sku.skuPartNumber) to $UserPrincipalName." -ForegroundColor Green
