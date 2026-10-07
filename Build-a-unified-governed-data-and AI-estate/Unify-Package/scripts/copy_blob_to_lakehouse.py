"""Copy the Blob raw zone into a Fabric Lakehouse Files/raw zone through OneLake."""
from __future__ import annotations

import argparse
import json
import subprocess
from datetime import datetime, timezone

from azure.core.credentials import AccessToken, TokenCredential
from azure.core.exceptions import ResourceExistsError
from azure.storage.blob import BlobServiceClient
from azure.storage.filedatalake import DataLakeServiceClient

STORAGE_RESOURCE = "https://storage.azure.com/"
CONTAINER_NAME = "data"


class AzureCliCredential(TokenCredential):
    """Small non-interactive credential that reuses the az/azd login from up.ps1."""

    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        response = subprocess.run(
            ["az", "account", "get-access-token", "--resource", STORAGE_RESOURCE, "-o", "json"],
            check=True,
            capture_output=True,
            text=True,
        )
        token = json.loads(response.stdout)
        expires = datetime.fromisoformat(token["expiresOn"].replace("Z", "+00:00"))
        if expires.tzinfo is None:
            expires = expires.replace(tzinfo=timezone.utc)
        return AccessToken(token["accessToken"], int(expires.timestamp()))


def ensure_directory(service: DataLakeServiceClient, workspace_id: str, path: str) -> None:
    """Create every OneLake path component; existing folders are intentionally reused."""
    file_system = service.get_file_system_client(workspace_id)
    current = ""
    for component in path.split("/"):
        current = f"{current}/{component}" if current else component
        try:
            file_system.get_directory_client(current).create_directory()
        except ResourceExistsError:
            pass


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage-account", required=True)
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    args = parser.parse_args()

    credential = AzureCliCredential()
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
        # Upload-SourceData writes the three source folders beneath data/.
        relative_path = blob.name.replace("\\", "/")
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
    print(f"Copied {copied} source files into the Lakehouse raw zone.")


if __name__ == "__main__":
    main()
