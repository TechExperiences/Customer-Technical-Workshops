"""Create and load the OperationalData Azure SQL database from local CSV sources."""
from __future__ import annotations

import argparse
import csv
import json
import os
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


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--server", required=True, help="Azure SQL FQDN, e.g. server.database.windows.net")
    parser.add_argument("--database", default="OperationalData")
    parser.add_argument("--reset", action="store_true", help="Delete rows before loading; does not drop tables.")
    args = parser.parse_args()

    connection_string = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{args.server},1433;Database={args.database};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    if "ODBC Driver 18 for SQL Server" not in pyodbc.drivers():
        raise RuntimeError("ODBC Driver 18 for SQL Server is not registered. Run .\\up.ps1 again to install it.")
    with pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: azure_sql_token()}) as connection:
        cursor = connection.cursor()
        for batch in sql_batches((PACKAGE_ROOT / "sql" / "OperationalData.sql").read_text(encoding="utf-8")):
            try:
                cursor.execute(batch)
            except pyodbc.ProgrammingError as error:
                if "already an object named" not in str(error).lower():
                    raise
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
