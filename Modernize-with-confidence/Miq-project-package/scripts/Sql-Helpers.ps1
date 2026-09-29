function New-CaldovaSqlConnection {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $ServerName,
    [Parameter(Mandatory)][string] $DatabaseName
  )

  $token = (& az account get-access-token --resource https://database.windows.net --query accessToken --output tsv).Trim()
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($token)) {
    throw 'Unable to acquire an Azure SQL access token from the current Azure identity.'
  }

  $connection = [System.Data.SqlClient.SqlConnection]::new("Server=tcp:$ServerName.database.windows.net,1433;Initial Catalog=$DatabaseName;Encrypt=True;TrustServerCertificate=False;Connection Timeout=60;")
  $connection.AccessToken = $token
  $connection.add_InfoMessage({ param($sender, $event) Write-Host "[MIQ SQL] $($event.Message)" })
  $connection.Open()
  return $connection
}

function Invoke-CaldovaSqlNonQuery {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection] $Connection,
    [Parameter(Mandatory)][string] $Sql,
    [int] $CommandTimeout = 600
  )

  $command = $Connection.CreateCommand()
  $command.CommandText = $Sql
  $command.CommandTimeout = $CommandTimeout
  try { return $command.ExecuteNonQuery() }
  finally { $command.Dispose() }
}

function Invoke-CaldovaSqlScalar {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][System.Data.SqlClient.SqlConnection] $Connection,
    [Parameter(Mandatory)][string] $Sql,
    [int] $CommandTimeout = 600
  )

  $command = $Connection.CreateCommand()
  $command.CommandText = $Sql
  $command.CommandTimeout = $CommandTimeout
  try { return $command.ExecuteScalar() }
  finally { $command.Dispose() }
}
