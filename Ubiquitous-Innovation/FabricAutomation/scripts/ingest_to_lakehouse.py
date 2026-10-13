"""Convert local CSV files to Delta tables in a newly created Fabric Lakehouse."""
from __future__ import annotations

import argparse
import os
import re
import time
from pathlib import Path

import pyarrow as pa
import pyarrow.csv as csv
from deltalake import write_deltalake


def table_name_for(local_file: Path) -> str:
    name = re.sub(r"[^A-Za-z0-9_]", "_", local_file.stem).strip("_")
    if not name:
        raise RuntimeError(f"Cannot derive a table name from {local_file.name!r}.")
    if name[0].isdigit():
        name = f"table_{name}"
    return name


def is_onelake_not_ready(error: Exception) -> bool:
    message = str(error).casefold()
    return any(marker in message for marker in ("pathnotfound", "path not found", "not found", "status code: 404", "error 404", "(404)"))


def write_table_when_onelake_ready(uri: str, table, storage_options: dict[str, str], table_name: str) -> None:
    """Wait for the new Lakehouse Tables endpoint to become available in OneLake."""
    max_attempts = 36
    for attempt in range(1, max_attempts + 1):
        try:
            # This workflow targets a brand-new Lakehouse and never reuses a table.
            # Delta writes create the transaction log and Parquet data under
            # Tables/dbo/<table_name>; schema-enabled Lakehouses recognize tables
            # inside a schema.
            write_deltalake(uri, table, mode="error", storage_options=storage_options)
            return
        except Exception as error:
            if not is_onelake_not_ready(error) or attempt == max_attempts:
                raise RuntimeError(f"Could not create Delta table {table_name}: {error}") from error
            print(f"OneLake Tables path is not ready for {table_name}; waiting 5 seconds (attempt {attempt}/{max_attempts})...")
            time.sleep(5)


def latest_plant_dimension(plant_table: pa.Table) -> pa.Table:
    """Return one current dimension row per PlantID from Plant observations."""
    plants: dict[str, dict] = {}
    for row in plant_table.to_pylist():
        plant_id = str(row["PlantID"])
        existing = plants.get(plant_id)
        if existing is None or str(row["PlantObservationDate"]) > str(existing["PlantObservationDate"]):
            plants[plant_id] = row
    return pa.Table.from_pylist([
        {
            "PlantID": row["PlantID"],
            "PlantName": row["PlantName"],
            "Location": row["Location"],
            "Country": row["Country"],
            "PlantObservationDate": row["PlantObservationDate"],
        }
        for _, row in sorted(plants.items())
    ])


def lakehouse_table_uri(workspace_id: str, lakehouse_id: str, table_name: str) -> str:
    return f"abfss://{workspace_id}@onelake.dfs.fabric.microsoft.com/{lakehouse_id}/Tables/dbo/{table_name}"


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    parser.add_argument("--source-folder", required=True)
    args = parser.parse_args()

    access_token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
    if not access_token:
        raise RuntimeError("AZURE_STORAGE_ACCESS_TOKEN is not available. Run through up.ps1.")

    source = Path(args.source_folder).resolve()
    if not source.is_dir():
        raise RuntimeError(f"Source folder does not exist: {source}")
    files = sorted(path for path in source.rglob("*") if path.is_file())
    if not files:
        raise RuntimeError(f"Source folder contains no files: {source}")
    non_csv_files = [path.relative_to(source).as_posix() for path in files if path.suffix.casefold() != ".csv"]
    if non_csv_files:
        raise RuntimeError(f"Only CSV files can be converted to Lakehouse tables: {', '.join(non_csv_files)}")

    table_names: set[str] = set()
    tables: list[tuple[Path, str]] = []
    for local_file in files:
        table_name = table_name_for(local_file)
        if table_name.casefold() in table_names:
            raise RuntimeError(f"Multiple CSV files resolve to the same table name: {table_name}")
        table_names.add(table_name.casefold())
        tables.append((local_file, table_name))

    storage_options = {
        "AZURE_STORAGE_ACCOUNT_NAME": "onelake",
        "AZURE_STORAGE_TOKEN": access_token,
    }
    created = 0
    plant_table: pa.Table | None = None
    for local_file, table_name in tables:
        arrow_table = csv.read_csv(local_file)
        table_uri = lakehouse_table_uri(args.workspace_id, args.lakehouse_id, table_name)
        write_table_when_onelake_ready(table_uri, arrow_table, storage_options, table_name)
        if table_name == "Plant":
            plant_table = arrow_table
        created += 1
        print(f"Created table {table_name} from {local_file.relative_to(source).as_posix()}")

    if plant_table is None:
        raise RuntimeError("Plant.csv is required to derive the DimPlant Lakehouse dimension.")
    dim_plant = latest_plant_dimension(plant_table)
    write_table_when_onelake_ready(
        lakehouse_table_uri(args.workspace_id, args.lakehouse_id, "DimPlant"),
        dim_plant,
        storage_options,
        "DimPlant",
    )
    created += 1
    print("Created table DimPlant from the latest Plant observation per PlantID")
    print(f"Created {created} Delta table(s) in the Lakehouse Tables area.")


if __name__ == "__main__":
    main()
