[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$UserPrincipalName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-GraphRest {
    param(
        [Parameter(Mandatory)] [ValidateSet('GET', 'POST')] [string]$Method,
        [Parameter(Mandatory)] [string]$Url,
        [string]$Body
    )

    $arguments = @('rest', '--method', $Method, '--url', $Url, '--resource', 'https://graph.microsoft.com', '--headers', 'Content-Type=application/json')
    if ($Body) { $arguments += @('--body', $Body) }
    $response = & az @arguments
    if ($LASTEXITCODE -ne 0) { throw "Microsoft Graph request failed: $Method $Url" }
    return $response | ConvertFrom-Json
}

$encodedUpn = [System.Uri]::EscapeDataString($UserPrincipalName)
$licenseDetails = Invoke-GraphRest -Method GET -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/licenseDetails?`$select=skuId,skuPartNumber"
$fabricLicenses = @($licenseDetails.value | Where-Object { $_.skuPartNumber -match 'FABRIC|POWER_BI' })
$nonFreeLicense = @($fabricLicenses | Where-Object { $_.skuPartNumber -notmatch 'FREE' } | Select-Object -First 1)
if ($nonFreeLicense) {
    Write-Host "Using existing Fabric/Power BI license $($nonFreeLicense.skuPartNumber) assigned to $UserPrincipalName." -ForegroundColor Green
    return
}

$existingFreeLicense = @($fabricLicenses | Where-Object { $_.skuPartNumber -match 'FREE' } | Select-Object -First 1)
if ($existingFreeLicense) {
    Write-Host "Using existing free Fabric/Power BI license $($existingFreeLicense.skuPartNumber) assigned to $UserPrincipalName." -ForegroundColor Green
    return
}

# Graph can assign only a SKU the tenant already exposes. It cannot start a trial,
# purchase a license, or bypass tenant licensing policy.
$subscribedSkus = Invoke-GraphRest -Method GET -Url 'https://graph.microsoft.com/v1.0/subscribedSkus?$select=skuId,skuPartNumber,prepaidUnits,consumedUnits'
$freeSku = @($subscribedSkus.value | Where-Object {
    $_.skuPartNumber -in @('FABRIC_FREE', 'POWER_BI_STANDARD') -or
    $_.skuPartNumber -match '(FABRIC|POWER_BI).*FREE'
} | Where-Object { ([int]$_.prepaidUnits.enabled - [int]$_.consumedUnits) -gt 0 } | Select-Object -First 1)
if (-not $freeSku) {
    throw 'No existing Fabric/Power BI license is assigned and this tenant exposes no assignable free Fabric/Power BI SKU. Enable an eligible free SKU in the tenant, or assign an appropriate Fabric/Power BI license, then rerun.'
}

$body = @{ addLicenses = @(@{ skuId = $freeSku.skuId }); removeLicenses = @() } | ConvertTo-Json -Compress
[void](Invoke-GraphRest -Method POST -Url "https://graph.microsoft.com/v1.0/users/$encodedUpn/assignLicense" -Body $body)
Write-Host "Assigned free Fabric/Power BI license $($freeSku.skuPartNumber) to $UserPrincipalName." -ForegroundColor Green
