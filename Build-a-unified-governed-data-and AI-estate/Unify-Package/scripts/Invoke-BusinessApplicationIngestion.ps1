[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$StorageAccountName,
    [Parameter(Mandatory)] [string]$SqlServerFqdn,
    [Parameter(Mandatory)] [string]$SqlDatabaseName,
    [string]$ResourceGroupName = 'rg-Build-Unify',
    [string]$LogicAppName = 'caldova-businessapp-ingest'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Fabric SQL Database reports its server FQDN as "host,port"; the SQL connector wants the host only.
$sqlServerHost = ($SqlServerFqdn -split ',')[0]

$subscriptionId = (az account show --query id -o tsv).Trim()
if ($LASTEXITCODE -ne 0 -or -not $subscriptionId) { throw 'Could not resolve the current Azure subscription ID.' }
$workflowUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.Logic/workflows/$LogicAppName"

# Everything below stays on the ARM control plane (management.azure.com), the same
# plane every other step in this pipeline already uses reliably. The alternative -
# POSTing to the Logic App's public SAS callback URL on *.logic.azure.com - goes
# through a separate, shared multi-tenant data-plane gateway that returned
# 502/NoResponse against a Logic App redeployed moments earlier in this same run.
# Baking inputs into workflow parameters lets the trigger run with no request body,
# so the ARM "run trigger" action (which does not accept a body) can replace it.
$workflow = az rest --method get --uri "$workflowUri`?api-version=2019-05-01" --only-show-errors | ConvertFrom-Json
if ($LASTEXITCODE -ne 0 -or -not $workflow) { throw "Could not read the $LogicAppName workflow definition." }

# Read the blobs here, with the same "az storage blob ... --auth-mode login" pattern
# Upload-SourceData.ps1 and Remove-OperationalBlobs.ps1 already use successfully, and
# embed the content directly into the INSERT query text below. This keeps the Logic
# App itself doing only what it has reliably done so far: running a SQL statement.
$customerDetailsFile = New-TemporaryFile
$customerAddressFile = New-TemporaryFile
try {
    az storage blob download --account-name $StorageAccountName --container-name data `
        --name 'BusinessApplication/CustomerDetails.json' --file $customerDetailsFile --auth-mode login --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not download BusinessApplication/CustomerDetails.json.' }
    az storage blob download --account-name $StorageAccountName --container-name data `
        --name 'BusinessApplication/CustomerAddress.json' --file $customerAddressFile --auth-mode login --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not download BusinessApplication/CustomerAddress.json.' }
    $customerDetailsJson = Get-Content -LiteralPath $customerDetailsFile -Raw
    $customerAddressJson = Get-Content -LiteralPath $customerAddressFile -Raw
} finally {
    Remove-Item -LiteralPath $customerDetailsFile, $customerAddressFile -ErrorAction SilentlyContinue
}

# The SQL connector's formalParameters/@json binding does not reliably parameterize a query
# containing an OPENJSON ... WITH (...) clause - it left @json unresolved and misparsed the
# WITH keyword ("Must declare the scalar variable '@json'. Incorrect syntax near 'with'.").
# Building the full statement here, with the JSON embedded as an N'...' string literal
# (single quotes doubled per T-SQL escaping rules), sidesteps that connector limitation.
function New-OpenJsonInsertQuery {
    param([string]$InsertSelectWithClause, [string]$Json)
    $escapedJson = $Json.Replace("'", "''")
    return $InsertSelectWithClause.Replace('__JSON__', $escapedJson)
}

$customerDetailsQuery = New-OpenJsonInsertQuery -Json $customerDetailsJson -InsertSelectWithClause @'
INSERT INTO dbo.CustomerDetails (CustomerID, CustomerName, Email, Phone, Segment, AccountManager, CreatedDate)
SELECT CustomerID, CustomerName, Email, Phone, Segment, AccountManager, CreatedDate
FROM OPENJSON(N'__JSON__')
WITH (
  CustomerID INT '$.CustomerID',
  CustomerName NVARCHAR(200) '$.CustomerName',
  Email NVARCHAR(320) '$.Email',
  Phone NVARCHAR(50) '$.Phone',
  Segment NVARCHAR(100) '$.Segment',
  AccountManager NVARCHAR(200) '$.AccountManager',
  CreatedDate DATE '$.CreatedDate'
);
'@

$customerAddressQuery = New-OpenJsonInsertQuery -Json $customerAddressJson -InsertSelectWithClause @'
INSERT INTO dbo.CustomerAddress (AddressID, CustomerID, AddressLine1, City, State, PostalCode, Country, AddressType)
SELECT AddressID, CustomerID, AddressLine1, City, State, PostalCode, Country, AddressType
FROM OPENJSON(N'__JSON__')
WITH (
  AddressID INT '$.AddressID',
  CustomerID INT '$.CustomerID',
  AddressLine1 NVARCHAR(200) '$.AddressLine1',
  City NVARCHAR(100) '$.City',
  State NVARCHAR(100) '$.State',
  PostalCode NVARCHAR(20) '$.PostalCode',
  Country NVARCHAR(100) '$.Country',
  AddressType NVARCHAR(50) '$.AddressType'
);
'@

$workflow.properties.definition.parameters.sqlServer.defaultValue = $sqlServerHost
$workflow.properties.definition.parameters.sqlDatabase.defaultValue = $SqlDatabaseName
$workflow.properties.definition.parameters.customerDetailsQuery.defaultValue = $customerDetailsQuery
$workflow.properties.definition.parameters.customerAddressQuery.defaultValue = $customerAddressQuery

$workflowBodyFile = New-TemporaryFile
try {
    $workflow | ConvertTo-Json -Depth 50 -Compress | Set-Content -LiteralPath $workflowBodyFile -Encoding utf8NoBOM
    az rest --method put --uri "$workflowUri`?api-version=2019-05-01" --body "@$workflowBodyFile" --only-show-errors | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Could not set this run's inputs on the $LogicAppName workflow." }
} finally {
    Remove-Item -LiteralPath $workflowBodyFile -ErrorAction SilentlyContinue
}

$invokedAt = [DateTimeOffset]::UtcNow
az rest --method post --uri "$workflowUri/triggers/manual/run?api-version=2019-05-01" --only-show-errors | Out-Null
if ($LASTEXITCODE -ne 0) { throw "Could not start a run of the $LogicAppName workflow." }

# A bare & in an unquoted argument makes cmd.exe (which az.cmd delegates to on
# Windows) split the command line, so this URI deliberately avoids any query
# parameter beyond api-version to keep it a single, whitespace-free token.
$runName = $null
for ($attempt = 1; $attempt -le 24; $attempt++) {
    Start-Sleep -Seconds 5
    $runs = (az rest --method get --uri "$workflowUri/runs`?api-version=2019-05-01" --only-show-errors | ConvertFrom-Json).value
    $match = @($runs | Where-Object { [DateTimeOffset]::Parse($_.properties.startTime) -ge $invokedAt } | Sort-Object { $_.properties.startTime } -Descending | Select-Object -First 1)
    if ($match) { $runName = $match[0].name; break }
}
if (-not $runName) { throw "The $LogicAppName workflow did not report a new run after being triggered." }

for ($attempt = 1; $attempt -le 60; $attempt++) {
    $run = az rest --method get --uri "$workflowUri/runs/$runName`?api-version=2019-05-01" --only-show-errors | ConvertFrom-Json
    $status = $run.properties.status
    if ($status -eq 'Succeeded') {
        Write-Host "BusinessApplication ingestion via $LogicAppName completed (run $runName)." -ForegroundColor Green
        return
    }
    if ($status -in @('Failed', 'Cancelled', 'Faulted', 'TimedOut', 'Aborted')) {
        # The run-level error is a generic "no dependent actions succeeded" message, and
        # even the action-list entry's 'error' property is often null for ApiConnection
        # actions - the real connector error only shows up on the per-action detail
        # endpoint or in the body behind its outputsLink. Fetch both so the thrown
        # message contains the actual SQL connector failure instead of "null".
        $actions = (az rest --method get --uri "$workflowUri/runs/$runName/actions`?api-version=2019-05-01" --only-show-errors | ConvertFrom-Json).value
        $failedActions = @($actions | Where-Object { $_.properties.status -eq 'Failed' })
        $report = @($failedActions | ForEach-Object {
            $detail = az rest --method get --uri "$workflowUri/runs/$runName/actions/$($_.name)`?api-version=2019-05-01" --only-show-errors | ConvertFrom-Json
            $errorDetail = $null
            if (($detail.properties | Get-Member -Name 'error' -ErrorAction SilentlyContinue)) { $errorDetail = $detail.properties.error }
            $outputsBody = $null
            if (($detail.properties | Get-Member -Name 'outputsLink' -ErrorAction SilentlyContinue) -and $detail.properties.outputsLink.uri) {
                try {
                    $outputsBody = Invoke-RestMethod -Uri $detail.properties.outputsLink.uri -Method Get
                } catch {
                    $outputsBody = "Could not fetch outputsLink: $($_.Exception.Message)"
                }
            }
            [PSCustomObject]@{ name = $_.name; error = $errorDetail; outputs = $outputsBody }
        })
        throw "BusinessApplication ingestion run $runName ended with status $status. Failed action(s): $($report | ConvertTo-Json -Compress -Depth 20)"
    }
    Start-Sleep -Seconds 10
}
throw "BusinessApplication ingestion run $runName did not reach a terminal status in time."

