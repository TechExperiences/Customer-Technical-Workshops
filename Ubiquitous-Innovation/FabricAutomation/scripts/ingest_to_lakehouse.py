"""Upload a local folder once into the Files area of a newly created Lakehouse."""
from __future__ import annotations

import argparse
import os
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from azure.core.credentials import AccessToken, TokenCredential
from azure.core.exceptions import ResourceExistsError, ResourceNotFoundError
from azure.storage.filedatalake import DataLakeServiceClient


class ProcessTokenCredential(TokenCredential):
    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
        if not token:
            raise RuntimeError("AZURE_STORAGE_ACCESS_TOKEN is not available. Run through up.ps1.")
        expires = datetime.now(timezone.utc) + timedelta(minutes=55)
        return AccessToken(token, int(expires.timestamp()))


def ensure_directory(file_system, path: str) -> None:
    parts = path.split("/")
    current = parts[0]
    for part in parts[1:]:
        current = f"{current}/{part}"
        try:
            file_system.get_directory_client(current).create_directory()
        except ResourceExistsError:
            pass


def upload_when_onelake_ready(file_system, local_file: Path, destination_path: str) -> None:
    """Wait for Fabric to finish exposing the new Lakehouse through OneLake.

    Fabric item creation and the underlying OneLake Files path are eventually
    consistent. A new Lakehouse can be returned by the Fabric REST API before its
    storage path accepts writes, in which case OneLake returns PathNotFound.
    """
    max_attempts = 36
    for attempt in range(1, max_attempts + 1):
        try:
            ensure_directory(file_system, destination_path.rsplit("/", 1)[0])
            with local_file.open("rb") as contents:
                # This workflow writes only to a newly created Lakehouse. Overwrite
                # makes a retry safe if OneLake created a partial target before a
                # transient PathNotFound response.
                file_system.get_file_client(destination_path).upload_data(contents, overwrite=True)
            return
        except ResourceNotFoundError:
            if attempt == max_attempts:
                raise RuntimeError(
                    f"OneLake did not make the destination available for {local_file.name} after three minutes: "
                    f"{destination_path}"
                ) from None
            print(f"OneLake path is not ready for {local_file.name}; waiting 5 seconds (attempt {attempt}/{max_attempts})...")
            time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    parser.add_argument("--source-folder", required=True)
    args = parser.parse_args()

    source = Path(args.source_folder).resolve()
    if not source.is_dir():
        raise RuntimeError(f"Source folder does not exist: {source}")
    files = [path for path in source.rglob("*") if path.is_file()]
    if not files:
        raise RuntimeError(f"Source folder contains no files: {source}")

    service = DataLakeServiceClient("https://onelake.dfs.fabric.microsoft.com", credential=ProcessTokenCredential())
    file_system = service.get_file_system_client(args.workspace_id)
    uploaded = 0
    for local_file in files:
        relative_path = local_file.relative_to(source).as_posix()
        destination_path = f"{args.lakehouse_id}/Files/{relative_path}"
        upload_when_onelake_ready(file_system, local_file, destination_path)
        uploaded += 1
        print(f"Uploaded {relative_path}")
    print(f"Uploaded {uploaded} file(s) to the Lakehouse Files area.")


if __name__ == "__main__":
    main()
