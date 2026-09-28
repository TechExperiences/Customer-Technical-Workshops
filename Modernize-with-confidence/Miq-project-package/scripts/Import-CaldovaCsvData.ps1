[CmdletBinding()]
param(
  [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection] $Connection,
  [Parameter(Mandatory)][string] $DataPath,
  [Parameter(Mandatory)][string] $SchemaPath
)

. (Join-Path $PSScriptRoot 'Sql-Helpers.ps1')

Invoke-CaldovaSqlNonQuery -Connection $Connection -Sql (Get-Content -LiteralPath $SchemaPath -Raw) | Out-Null

$tables = @(
  @{ Table = 'Warehouses'; File = 'Warehouses.csv'; Skip = @() },
  @{ Table = 'ProductCategories'; File = 'ProductCategories.csv'; Skip = @() },
  @{ Table = 'ProductCatalog'; File = 'ProductCatalog.csv'; Skip = @() },
  @{ Table = 'ProductDescriptions'; File = 'ProductDescriptions.csv'; Skip = @() },
  @{ Table = 'Customers'; File = 'Customers.csv'; Skip = @() },
  @{ Table = 'CustomerAddresses'; File = 'CustomerAddresses.csv'; Skip = @() },
  @{ Table = 'Inventory'; File = 'Inventory.csv'; Skip = @('QuantityAvailable') },
  @{ Table = 'Orders'; File = 'Orders.csv'; Skip = @() },
  @{ Table = 'OrderLines'; File = 'OrderLines.csv'; Skip = @() },
  @{ Table = 'Shipments'; File = 'Shipments.csv'; Skip = @() },
  @{ Table = 'SemanticSearchLog'; File = 'SemanticSearchLog.csv'; Skip = @() }
)

$integerColumns = @('AddressID','CategoryID','ParentCategoryID','ProductID','ProductDescriptionID','CustomerID','InventoryID','WarehouseID','QuantityOnHand','QuantityReserved','QuantityAvailable','ReorderLevel','ReorderQuantity','OrderID','ShippingAddressID','BillingAddressID','OrderLineID','LineNumber','Quantity','ShipmentID','SemanticSearchLogID','TopProductID','ResultCount')
$decimalColumns = @('CreditLimit','UnitPrice','Weight','SubTotal','TaxAmount','ShippingAmount','TotalAmount','DiscountPercent','LineTotal','TopScore')
$booleanColumns = @('IsActive','IsPrimary')
$dateColumns = @('CreatedDate','ModifiedDate','LastRestockDate','OrderDate','RequiredDate','ShippedDate','EstimatedDeliveryDate','DeliveredDate','SearchDate')

function Get-ColumnType {
  param([string] $Name)
  if ($integerColumns -contains $Name) { return [int] }
  if ($decimalColumns -contains $Name) { return [decimal] }
  if ($booleanColumns -contains $Name) { return [bool] }
  if ($dateColumns -contains $Name) { return [datetime] }
  return [string]
}

function Convert-CsvValue {
  param([string] $Value, [type] $Type)
  if ([string]::IsNullOrWhiteSpace($Value)) { return [DBNull]::Value }
  if ($Type -eq [bool]) { return [bool]::Parse($Value) }
  if ($Type -eq [int]) { return [int]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture) }
  if ($Type -eq [decimal]) { return [decimal]::Parse($Value, [Globalization.NumberStyles]::Any, [Globalization.CultureInfo]::InvariantCulture) }
  if ($Type -eq [datetime]) { return [datetime]::Parse($Value, [Globalization.CultureInfo]::InvariantCulture) }
  return $Value
}

foreach ($definition in $tables) {
  $existingCount = [int](Invoke-CaldovaSqlScalar -Connection $Connection -Sql "SELECT COUNT_BIG(*) FROM dbo.[$($definition.Table)];")
  if ($existingCount -gt 0) {
    Write-Host "Skipping $($definition.Table): $existingCount existing rows."
    continue
  }

  $filePath = Join-Path $DataPath $definition.File
  if (-not (Test-Path -LiteralPath $filePath -PathType Leaf)) { throw "Required source file is missing: $filePath" }
  $rows = @(Import-Csv -LiteralPath $filePath)
  if ($rows.Count -eq 0) { throw "Source file has no rows: $filePath" }

  $columns = @($rows[0].PSObject.Properties.Name | Where-Object { $definition.Skip -notcontains $_ })
  $dataTable = [System.Data.DataTable]::new($definition.Table)
  foreach ($column in $columns) { [void]$dataTable.Columns.Add($column, (Get-ColumnType $column)) }
  foreach ($row in $rows) {
    $newRow = $dataTable.NewRow()
    foreach ($column in $columns) { $newRow[$column] = Convert-CsvValue -Value $row.$column -Type (Get-ColumnType $column) }
    [void]$dataTable.Rows.Add($newRow)
  }

  $bulkCopy = [System.Data.SqlClient.SqlBulkCopy]::new($Connection)
  $bulkCopy.DestinationTableName = "dbo.[$($definition.Table)]"
  $bulkCopy.BatchSize = 500
  $bulkCopy.BulkCopyTimeout = 600
  foreach ($column in $columns) { [void]$bulkCopy.ColumnMappings.Add($column, $column) }
  try { $bulkCopy.WriteToServer($dataTable) }
  finally { $bulkCopy.Dispose() }
  Write-Host "Imported $($dataTable.Rows.Count) rows into dbo.$($definition.Table)."
}

$verification = Invoke-CaldovaSqlScalar -Connection $Connection -Sql "SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID('dbo') AND name <> 'ProductDescriptionEmbeddings';"
Write-Host "Initial relational migration complete. Tables available before embeddings: $verification."
