"""Upload a local folder into one named container of the new ADLS Gen2 account."""
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
    """Use the short-lived Storage token issued by the service-principal login."""

    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
        if not token:
            raise RuntimeError("AZURE_STORAGE_ACCESS_TOKEN is unavailable. Run through up.ps1.")
        expires = datetime.now(timezone.utc) + timedelta(minutes=55)
        return AccessToken(token, int(expires.timestamp()))


def ensure_directory(file_system, path: str) -> None:
    current = ""
    for component in (part for part in path.split("/") if part):
        current = f"{current}/{component}" if current else component
        try:
            file_system.get_directory_client(current).create_directory()
        except ResourceExistsError:
            pass


def retryable(error: Exception) -> bool:
    return isinstance(error, ResourceNotFoundError) or (
        isinstance(error, HttpResponseError) and error.status_code in {403, 404}
    )


def upload(file_system, local_file: Path, destination_path: str) -> None:
    for attempt in range(1, 61):
        try:
            ensure_directory(file_system, destination_path.rpartition("/")[0])
            with local_file.open("rb") as contents:
                file_system.get_file_client(destination_path).upload_data(contents, overwrite=True)
            return
        except Exception as error:
            if not retryable(error) or attempt == 60:
                raise RuntimeError(f"Could not upload {local_file.name}: {error}") from error
            print(f"Storage access is not ready for {local_file.name}; waiting 5 seconds (attempt {attempt}/60)...")
            time.sleep(5)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage-account-name", required=True)
    parser.add_argument("--container", required=True, choices=("data", "sharepoint"))
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
    file_system = service.get_file_system_client(args.container)
    for local_file in files:
        relative_path = local_file.relative_to(source).as_posix()
        upload(file_system, local_file, relative_path)
        print(f"Uploaded {relative_path} to {args.container}")
    print(f"Uploaded {len(files)} file(s) to the ADLS Gen2 {args.container} container.")


if __name__ == "__main__":
    main()
