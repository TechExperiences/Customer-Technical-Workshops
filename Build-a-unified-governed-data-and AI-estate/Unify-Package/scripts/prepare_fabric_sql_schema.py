"""Create the BusinessApplication tables in the Fabric SQL Database (Caldova_SQLDatabase).

Runs with the deploying operator's own Entra token, who is the Fabric workspace Admin
as its creator, so CREATE TABLE succeeds regardless of the narrower SQL role that the
caldova-businessapp-ingest Logic App's Contributor workspace access maps to.
"""
from __future__ import annotations

import argparse
import json
import os
import struct
import subprocess
import time
from pathlib import Path

import pyodbc

PACKAGE_ROOT = Path(__file__).resolve().parents[1]
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
    parser.add_argument("--server", required=True, help="Fabric SQL Database server FQDN, e.g. xxxx.database.fabric.microsoft.com")
    parser.add_argument("--database", required=True)
    args = parser.parse_args()

    # Fabric SQL Database serverFqdn is reported as "host,port"; pyodbc wants them split.
    server_host, _, server_port = args.server.partition(",")
    connection_string = (
        "Driver={ODBC Driver 18 for SQL Server};"
        f"Server=tcp:{server_host},{server_port or '1433'};Database={args.database};"
        "Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    )
    if "ODBC Driver 18 for SQL Server" not in pyodbc.drivers():
        raise RuntimeError("ODBC Driver 18 for SQL Server is not registered. Run .\\up.ps1 again to install it.")

    # A Fabric SQL Database created moments earlier can take a short time to accept
    # TDS connections, so a first-try run retries instead of failing immediately.
    max_attempts = 8
    delay_seconds = 15
    for attempt in range(1, max_attempts + 1):
        try:
            connection = pyodbc.connect(connection_string, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: azure_sql_token()})
            break
        except pyodbc.Error as error:
            if attempt == max_attempts:
                raise
            print(f"Connection attempt {attempt} of {max_attempts} failed ({error}); retrying in {delay_seconds}s while the database comes online...")
            time.sleep(delay_seconds)
            delay_seconds = min(delay_seconds * 2, 120)

    with connection:
        cursor = connection.cursor()
        for batch in sql_batches((PACKAGE_ROOT / "sql" / "BusinessApplicationData.sql").read_text(encoding="utf-8")):
            cursor.execute(batch)
        connection.commit()
    print(f"BusinessApplication schema is ready in {args.database} on {server_host}.")


if __name__ == "__main__":
    main()
