"""Index both Fallback ADLS containers in one Foundry File Search vector store."""
from __future__ import annotations

import argparse
import os
import time

from azure.ai.projects import AIProjectClient
from azure.core.credentials import AccessToken, TokenCredential
from azure.core.exceptions import HttpResponseError
from azure.identity import ClientSecretCredential
from azure.storage.filedatalake import DataLakeServiceClient


SUPPORTED_SUFFIXES = {
    ".c", ".cpp", ".cs", ".css", ".doc", ".docx", ".html", ".java", ".js",
    ".json", ".md", ".pdf", ".php", ".pptx", ".py", ".rb", ".sh", ".tex",
    ".ts", ".txt",
}


class ProcessStorageCredential(TokenCredential):
    def get_token(self, *scopes: str, **_: object) -> AccessToken:
        token = os.environ.get("AZURE_STORAGE_ACCESS_TOKEN")
        if not token:
            raise RuntimeError("AZURE_STORAGE_ACCESS_TOKEN is unavailable. Run through up.ps1.")
        # The PowerShell pipeline obtains a fresh token immediately before this script.
        return AccessToken(token, int(time.time()) + 3300)


def project_credential() -> ClientSecretCredential:
    required = ("AZURE_TENANT_ID", "AZURE_CLIENT_ID", "AZURE_CLIENT_SECRET")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError(f"Missing credential settings: {', '.join(missing)}")
    return ClientSecretCredential(
        tenant_id=os.environ["AZURE_TENANT_ID"],
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_secret=os.environ["AZURE_CLIENT_SECRET"],
    )


def create_vector_store_when_ready(openai_client):
    # Standard Agent Setup provisions its capability host asynchronously. Allow
    # up to 30 minutes for its role assignments and managed connections to settle.
    for attempt in range(1, 181):
        try:
            return openai_client.vector_stores.create(name="fallback-supply-chain-knowledge")
        except Exception as error:  # The capability host can take several minutes to become ready.
            if attempt == 180:
                raise RuntimeError(f"Could not create the Foundry vector store: {error}") from error
            print(f"Foundry knowledge storage is not ready; waiting 10 seconds (attempt {attempt}/180)...")
            time.sleep(10)
    raise RuntimeError("Vector store creation did not complete.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--storage-account-name", required=True)
    parser.add_argument("--foundry-account-name", required=True)
    parser.add_argument("--project-name", required=True)
    args = parser.parse_args()

    project_endpoint = (
        f"https://{args.foundry_account_name}.services.ai.azure.com/"
        f"api/projects/{args.project_name}"
    )
    project = AIProjectClient(endpoint=project_endpoint, credential=project_credential(), allow_preview=True)
    service = DataLakeServiceClient(
        account_url=f"https://{args.storage_account_name}.dfs.core.windows.net",
        credential=ProcessStorageCredential(),
    )
    try:
        openai = project.get_openai_client()
        vector_store = create_vector_store_when_ready(openai)
        indexed = 0
        for container in ("data", "sharepoint"):
            file_system = service.get_file_system_client(container)
            paths = sorted(path for path in file_system.get_paths(recursive=True) if not path.is_directory)
            if not paths:
                raise RuntimeError(f"The {container} container has no files to index.")
            for path in paths:
                suffix = "." + path.name.rsplit(".", 1)[-1].casefold() if "." in path.name else ""
                if suffix not in SUPPORTED_SUFFIXES:
                    raise RuntimeError(
                        f"{container}/{path.name} is not supported by Foundry File Search. "
                        "Use a supported document or text format."
                    )
                contents = file_system.get_file_client(path.name).download_file().readall()
                upload_name = f"{container}__{path.name.replace('/', '__')}"
                openai.vector_stores.files.upload_and_poll(
                    vector_store_id=vector_store.id,
                    file=(upload_name, contents),
                    attributes={"source_container": container, "source_path": path.name},
                )
                indexed += 1
                print(f"Indexed {container}/{path.name}")
        print(f"Created vector store {vector_store.id} from {indexed} file(s) in data and sharepoint.")
        print(vector_store.id)
    except HttpResponseError as error:
        raise RuntimeError(f"Foundry knowledge-base indexing failed: {error}") from error
    finally:
        project.close()


if __name__ == "__main__":
    main()
