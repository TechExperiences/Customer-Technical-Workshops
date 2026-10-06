[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot)
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Add-Finding {
    param([string]$Severity, [string]$Rule, [string]$Detail)
    [PSCustomObject]@{ Severity = $Severity; Rule = $Rule; Detail = $Detail }
}

function Get-CsvRows {
    param([string]$FileName)
    @(Import-Csv -LiteralPath (Join-Path $PackageRoot "Analytical/$FileName"))
}

$findings = [System.Collections.Generic.List[object]]::new()
$manifestPath = Join-Path $PackageRoot 'config/source-manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Source manifest not found: $manifestPath" }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

foreach ($table in $manifest.sources.analytical.tables) {
    $file = Join-Path $PackageRoot "Analytical/$table.csv"
    if (-not (Test-Path -LiteralPath $file)) {
        $findings.Add((Add-Finding Error 'RequiredSourceFile' "Missing Analytical/$table.csv"))
        continue
    }
    $rows = @(Import-Csv -LiteralPath $file)
    if ($rows.Count -eq 0) { $findings.Add((Add-Finding Error 'NonEmptySource' "Analytical/$table.csv has no rows")) }
}

foreach ($table in $manifest.sources.operational.tables) {
    $file = Join-Path $PackageRoot "Operational/$table.csv"
    if (-not (Test-Path -LiteralPath $file)) {
        $findings.Add((Add-Finding Error 'RequiredSourceFile' "Missing Operational/$table.csv"))
        continue
    }
    $rows = @(Import-Csv -LiteralPath $file)
    if ($rows.Count -eq 0) { $findings.Add((Add-Finding Error 'NonEmptySource' "Operational/$table.csv has no rows")) }
}

foreach ($table in $manifest.sources.businessApplication.tables) {
    $file = Join-Path $PackageRoot "BusinessApplication/$table.json"
    if (-not (Test-Path -LiteralPath $file)) {
        $findings.Add((Add-Finding Error 'RequiredSourceFile' "Missing BusinessApplication/$table.json"))
        continue
    }
    try {
        $rows = @(Get-Content -LiteralPath $file -Raw | ConvertFrom-Json)
        if ($rows.Count -eq 0) { $findings.Add((Add-Finding Error 'NonEmptySource' "BusinessApplication/$table.json has no records")) }
    } catch { $findings.Add((Add-Finding Error 'ValidJson' "BusinessApplication/$table.json: $($_.Exception.Message)")) }
}

$keyRules = @(
    @{ File = 'DimDate.csv'; Column = 'DateKey' }, @{ File = 'DimLocation.csv'; Column = 'LocationID' },
    @{ File = 'DimMaterial.csv'; Column = 'MaterialID' }, @{ File = 'DimPlant.csv'; Column = 'PlantID' },
    @{ File = 'DimProduct.csv'; Column = 'ProductID' }, @{ File = 'DimSupplier.csv'; Column = 'SupplierID' },
    @{ File = 'FactInventory.csv'; Column = 'InventoryID' }, @{ File = 'FactInventorySnapshot.csv'; Column = 'FactID' },
    @{ File = 'FactProduction.csv'; Column = 'FactID' }, @{ File = 'FactQuality.csv'; Column = 'FactID' },
    @{ File = 'FactSales.csv'; Column = 'SalesID' }, @{ File = 'FactShipment.csv'; Column = 'FactID' },
    @{ File = 'FactSupplyChain.csv'; Column = 'FactID' }
)
foreach ($rule in $keyRules) {
    $rows = Get-CsvRows $rule.File
    $values = @($rows | ForEach-Object { $_.($rule.Column) })
    $blanks = @($values | Where-Object { [string]::IsNullOrWhiteSpace($_) }).Count
    $duplicates = @($values | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Group-Object | Where-Object Count -gt 1).Count
    if ($blanks) { $findings.Add((Add-Finding Error 'PrimaryKeyNotNull' "$($rule.File).$($rule.Column) has $blanks empty values")) }
    if ($duplicates) { $findings.Add((Add-Finding Error 'PrimaryKeyUnique' "$($rule.File).$($rule.Column) has $duplicates duplicated values")) }
}

$dimDate = @((Get-CsvRows 'DimDate.csv').DateKey | ForEach-Object { [string]$_ })
foreach ($fact in @('FactQuality.csv', 'FactShipment.csv')) {
    $orphanDates = @((Get-CsvRows $fact).DateKey | ForEach-Object { [string]$_ } | Where-Object { $_ -notin $dimDate } | Sort-Object -Unique)
    if ($orphanDates.Count) {
        $severity = if ($manifest.qualityPolicy.onMissingDateDimensionMember -eq 'extend_dimension') { 'Warning' } else { 'Error' }
        $findings.Add((Add-Finding $severity 'MissingDateDimensionMember' "$fact references date keys not in DimDate: $($orphanDates -join ', ')"))
    }
}

$customers = @(Get-Content -LiteralPath (Join-Path $PackageRoot 'BusinessApplication/CustomerDetails.json') -Raw | ConvertFrom-Json)
$customerIds = @($customers.CustomerID | ForEach-Object { [string]$_ })
$salesCustomerIds = @((Get-CsvRows 'FactSales.csv').CustomerID | ForEach-Object { [string]$_ } | Sort-Object -Unique)
$orphanCustomers = @($salesCustomerIds | Where-Object { $_ -notin $customerIds })
if ($orphanCustomers.Count) { $findings.Add((Add-Finding Error 'CustomerJoin' "FactSales has customer IDs missing from CustomerDetails: $($orphanCustomers -join ', ')")) }

$findings | Format-Table -AutoSize
$errors = @($findings | Where-Object Severity -eq 'Error')
if ($errors.Count) { throw "Source validation failed with $($errors.Count) error(s)." }
Write-Host "Source validation passed with $(@($findings | Where-Object Severity -eq 'Warning').Count) warning(s)." -ForegroundColor Green
