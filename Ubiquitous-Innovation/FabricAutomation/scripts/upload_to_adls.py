"""Upload a local folder to the data container of a newly created ADLS Gen2 account."""
from __future__ import annotations

import argparse
import os
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

from azure.core.credentials import AccessToken, TokenCredential
from azure.core.exceptions import HttpResponseError, ResourceExistsError, ResourceNotFoundError
from azure.storage.filedatalake import DataLakeServiceClient


class ProcessTokenCredential(TokenCredential):
    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
        if not token:
            raise RuntimeError("AZURE_STORAGE_ACCESS_TOKEN is not available. Run through up.ps1.")
        expires = datetime.now(timezone.utc) + timedelta(minutes=55)
        return AccessToken(token, int(expires.timestamp()))


def ensure_directory(file_system, path: str) -> None:
    current = ""
    for part in (component for component in path.split("/") if component):
        current = f"{current}/{part}" if current else part
        try:
            file_system.get_directory_client(current).create_directory()
        except ResourceExistsError:
            pass


def should_retry(error: Exception) -> bool:
    if isinstance(error, ResourceNotFoundError):
        return True
    if isinstance(error, HttpResponseError):
        return error.status_code in {403, 404}
    return False


def upload_when_ready(file_system, local_file: Path, destination_path: str) -> None:
    max_attempts = 60
    for attempt in range(1, max_attempts + 1):
        try:
            ensure_directory(file_system, destination_path.rpartition("/")[0])
            with local_file.open("rb") as contents:
                # The account and data container are created only for this run.
                # Overwrite is used solely to make a transient retry safe.
                file_system.get_file_client(destination_path).upload_data(contents, overwrite=True)
            return
        except Exception as error:
            if not should_retry(error) or attempt == max_attempts:
                raise RuntimeError(f"Could not upload {local_file.name}: {error}") from error
            print(f"ADLS data access is not ready for {local_file.name}; waiting 5 seconds (attempt {attempt}/{max_attempts})...")
            time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage-account-name", required=True)
    parser.add_argument("--source-folder", required=True)
    args = parser.parse_args()

    source = Path(args.source_folder).resolve()
    if not source.is_dir():
        raise RuntimeError(f"Source folder does not exist: {source}")
    files = sorted(path for path in source.rglob("*") if path.is_file())
    if not files:
        raise RuntimeError(f"Source folder contains no files: {source}")

    service = DataLakeServiceClient(
        account_url=f"https://{args.storage_account_name}.dfs.core.windows.net",
        credential=ProcessTokenCredential(),
    )
    file_system = service.get_file_system_client("data")
    uploaded = 0
    for local_file in files:
        relative_path = local_file.relative_to(source).as_posix()
        upload_when_ready(file_system, local_file, relative_path)
        uploaded += 1
        print(f"Uploaded {relative_path}")
    print(f"Uploaded {uploaded} file(s) to the ADLS Gen2 data container.")


if __name__ == "__main__":
    main()
