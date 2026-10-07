"""Create and load the OperationalData Azure SQL database from local CSV sources."""
from __future__ import annotations

import argparse
import csv
import json
import os
import re
import struct
import subprocess
from pathlib import Path

import pyodbc

PACKAGE_ROOT = Path(__file__).resolve().parents[1]
LOAD_ORDER = [
    "Supplier", "Material", "PurchaseOrder", "ManufacturingBatch", "Inventory",
    "PurchaseOrderItem", "QualityInspection", "Shipment",
]
SQL_COPT_SS_ACCESS_TOKEN = 1256


def azure_sql_token() -> bytes:
    token_from_environment = os.environ.get("AZURE_SQL_ACCESS_TOKEN")
    if not token_from_environment:
        result = subprocess.run(
            ["az", "account", "get-access-token", "--resource", "https://database.windows.net", "-o", "json"],
            check=True, capture_output=True, text=True,
        )
        token_from_environment = json.loads(result.stdout)["accessToken"]

    # SQL_COPT_SS_ACCESS_TOKEN expects a 4-byte little-endian byte length followed
    # by the UTF-16-LE token, not the token bytes alone.
    encoded_token = token_from_environment.encode("utf-16-le")
    return struct.pack("<I", len(encoded_token)) + encoded_token


def sql_batches(sql: str) -> list[str]:
    return [batch.strip() for batch in sql.split("\nGO\n") if batch.strip()]


def ensure_sql_authentication_user(cursor: pyodbc.Cursor, username: str, password: str) -> None:
    """Ensure the Query Editor can sign in with the requested SQL username."""
    if not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]{0,127}", username):
        raise ValueError("SQL authentication username must start with a letter and contain only letters, numbers, or underscores.")

    cursor.execute("SELECT 1 FROM sys.database_principals WHERE name = ?", username)
    if cursor.fetchone() is None:
        try:
            # New servers have this SQL server login already, so map it to the database.
            cursor.execute(f"CREATE USER [{username}] FOR LOGIN [{username}]")
        except pyodbc.Error:
            # Existing servers cannot rename their immutable server administrator.
            # Create a contained database user so the exact requested username still works.
            escaped_password = password.replace("'", "''")
            cursor.execute(f"CREATE USER [{username}] WITH PASSWORD = N'{escaped_password}', DEFAULT_SCHEMA = [dbo]")
    cursor.execute(
        """
        SELECT 1
        FROM sys.database_role_members membership
        JOIN sys.database_principals role_principal ON role_principal.principal_id = membership.role_principal_id
        JOIN sys.database_principals member_principal ON member_principal.principal_id = membership.member_principal_id
        WHERE role_principal.name = 'db_owner' AND member_principal.name = ?
        """,
        username,
    )
    if cursor.fetchone() is None:
        cursor.execute(f"ALTER ROLE db_owner ADD MEMBER [{username}]")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--server", required=True, help="Azure SQL FQDN, e.g. server.database.windows.net")
    parser.add_argument("--database", default="OperationalData")
    parser.add_argument("--reset", action="store_true", help="Delete rows before loading; does not drop tables.")
    parser.add_argument("--sql-auth-login", default=os.environ.get("SQL_ADMINISTRATOR_LOGIN", "squnify"))
    parser.add_argument("--sql-auth-password", default=os.environ.get("SQL_ADMINISTRATOR_PASSWORD"))
    args = parser.parse_args()

    connection_string = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{args.server},1433;Database={args.database};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    if "ODBC Driver 18 for SQL Server" not in pyodbc.drivers():
        raise RuntimeError("ODBC Driver 18 for SQL Server is not registered. Run .\\up.ps1 again to install it.")
    if not args.sql_auth_password:
        raise RuntimeError("SQL_ADMINISTRATOR_PASSWORD is required to create the SQL authentication user.")
    with pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: azure_sql_token()}) as connection:
        cursor = connection.cursor()
        for batch in sql_batches((PACKAGE_ROOT / "sql" / "OperationalData.sql").read_text(encoding="utf-8")):
            try:
                cursor.execute(batch)
            except pyodbc.ProgrammingError as error:
                if "already an object named" not in str(error).lower():
                    raise
        ensure_sql_authentication_user(cursor, args.sql_auth_login, args.sql_auth_password)
        if args.reset:
            for table in reversed(LOAD_ORDER):
                cursor.execute(f"DELETE FROM dbo.[{table}]")

        for table in LOAD_ORDER:
            file_path = PACKAGE_ROOT / "Operational" / f"{table}.csv"
            with file_path.open(newline="", encoding="utf-8-sig") as source:
                reader = csv.DictReader(source)
                columns = reader.fieldnames or []
                rows = [tuple(None if value == "" else value for value in row.values()) for row in reader]
            if rows:
                markers = ", ".join("?" for _ in columns)
                statement = f"INSERT INTO dbo.[{table}] ({', '.join(f'[{c}]' for c in columns)}) VALUES ({markers})"
                cursor.fast_executemany = True
                cursor.executemany(statement, rows)
            cursor.execute(f"SELECT COUNT(*) FROM dbo.[{table}]")
            print(f"{table}: {cursor.fetchone()[0]} rows")
        connection.commit()


if __name__ == "__main__":
    main()
