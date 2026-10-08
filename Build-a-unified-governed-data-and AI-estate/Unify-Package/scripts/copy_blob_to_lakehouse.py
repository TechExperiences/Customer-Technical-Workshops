"""Copy the Blob raw zone into a Fabric Lakehouse Files/raw zone through OneLake."""
from __future__ import annotations

import argparse
import os
from datetime import datetime, timedelta, timezone

from azure.core.credentials import AccessToken, TokenCredential
from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobServiceClient
from azure.storage.filedatalake import DataLakeServiceClient

CONTAINER_NAME = "data"


class ProcessTokenCredential(TokenCredential):
    """Uses the short-lived Storage token that Post-Provision obtains via az."""

    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        access_token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
        if not access_token:
            raise RuntimeError(
                "AZURE_STORAGE_ACCESS_TOKEN is missing. Run this script through .\\up.ps1 so PowerShell can acquire the token."
            )
        expires = datetime.now(timezone.utc) + timedelta(minutes=55)
        return AccessToken(access_token, int(expires.timestamp()))


def ensure_directory(service: DataLakeServiceClient, workspace_id: str, path: str) -> None:
    """Create every OneLake path component under the Lakehouse artifact; existing folders are reused.

    The first path segment is the Lakehouse's own artifact ID, which already exists as
    the implicit root - OneLake's policy rejects directory operations directly on that
    root ("folder '' under 'Lakehouse' artifact"), so creation starts one level down
    (e.g. "<lakehouseId>/Files", not the bare lakehouse ID alone).
    """
    file_system = service.get_file_system_client(workspace_id)
    components = path.split("/")
    current = components[0]
    for component in components[1:]:
        current = f"{current}/{component}"
        try:
            file_system.get_directory_client(current).create_directory()
        except ResourceExistsError:
            pass


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    parser.add_argument("--source-folders", nargs="+", required=True)
    args = parser.parse_args()

    credential = ProcessTokenCredential()
    blob_service = BlobServiceClient(
        account_url=f"https://{args.storage_account}.blob.core.windows.net",
        credential=credential,
    )
    source = blob_service.get_container_client(CONTAINER_NAME)
    one_lake = DataLakeServiceClient(
        account_url="https://onelake.dfs.fabric.microsoft.com",
        credential=credential,
    )
    destination = one_lake.get_file_system_client(args.workspace_id)

    copied = 0
    for blob in source.list_blobs():
        relative_path = blob.name.replace("\\", "/")
        source_folder = relative_path.split("/", 1)[0]
        if source_folder not in args.source_folders:
            continue
        target_directory = f"{args.lakehouse_id}/Files/raw"
        if "/" in relative_path:
            target_directory = f"{target_directory}/{relative_path.rsplit('/', 1)[0]}"
        ensure_directory(one_lake, args.workspace_id, target_directory)
        target_file = f"{target_directory}/{relative_path.rsplit('/', 1)[-1]}"
        payload = source.download_blob(blob.name).readall()
        destination.get_file_client(target_file).upload_data(payload, overwrite=True)
        copied += 1
        print(f"Copied {relative_path} -> Files/raw/{relative_path}")

    if copied == 0:
        raise RuntimeError("No blobs were found in the data container; source upload did not complete.")
    print(f"Copied {copied} {', '.join(args.source_folders)} source files into the Lakehouse raw zone.")


if __name__ == "__main__":
    main()
