"""Index both Fallback ADLS containers in one Foundry File Search vector store."""
from __future__ import annotations

import argparse
import os
import time
from typing import Any

from azure.ai.projects import AIProjectClient
from azure.core.credentials import AccessToken, TokenCredential
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
            status_code = getattr(error, "status_code", None)
            if status_code not in {403, 404, 409, 429, 500, 502, 503, 504} or attempt == 180:
                raise RuntimeError(f"Could not create the Foundry vector store: {error}") from error
            print(f"Foundry knowledge storage is not ready; waiting 10 seconds (attempt {attempt}/180)...")
            time.sleep(10)
    raise RuntimeError("Vector store creation did not complete.")


def upload_name_for(container: str, source_path: str) -> str:
    """Return a portable unique name for a source file in the vector store."""
    return f"{container}__{source_path.replace('/', '__')}"


def collect_documents(service: DataLakeServiceClient) -> list[tuple[str, Any, str, str]]:
    """Validate and order every source document before creating a vector store."""
    documents: list[tuple[str, Any, str, str]] = []
    upload_names: set[str] = set()
    for container in ("data", "sharepoint"):
        file_system = service.get_file_system_client(container)
        paths = sorted(
            (path for path in file_system.get_paths(recursive=True) if not path.is_directory),
            key=lambda path: path.name.casefold(),
        )
        if not paths:
            raise RuntimeError(f"The {container} container has no files to index.")
        for path in paths:
            suffix = "." + path.name.rsplit(".", 1)[-1].casefold() if "." in path.name else ""
            if suffix not in SUPPORTED_SUFFIXES:
                raise RuntimeError(
                    f"{container}/{path.name} is not supported by Foundry File Search. "
                    "Use a supported document or text format."
                )
            upload_name = upload_name_for(container, path.name)
            if upload_name.casefold() in upload_names:
                raise RuntimeError(
                    f"Multiple source files resolve to the same Foundry upload name: {upload_name}"
                )
            upload_names.add(upload_name.casefold())
            documents.append((container, file_system, path.name, upload_name))
    return documents


def delete_vector_store_after_failure(openai_client, vector_store_id: str) -> None:
    """Best-effort cleanup prevents an incomplete knowledge base from accumulating."""
    try:
        openai_client.vector_stores.delete(vector_store_id)
        print(f"Removed incomplete vector store {vector_store_id}.")
    except Exception as cleanup_error:
        print(
            f"Warning: could not remove incomplete vector store {vector_store_id}: {cleanup_error}"
        )


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
        # Complete all read-only enumeration and validation before a new remote
        # vector store is created. A local/source-data defect cannot then leave
        # an empty vector store behind.
        documents = collect_documents(service)
        vector_store = create_vector_store_when_ready(openai)
        for container, file_system, source_path, upload_name in documents:
            contents = file_system.get_file_client(source_path).download_file().readall()
            openai.vector_stores.files.upload_and_poll(
                vector_store_id=vector_store.id,
                file=(upload_name, contents),
                attributes={"source_container": container, "source_path": source_path},
            )
            print(f"Indexed {container}/{source_path}")
        print(f"Created vector store {vector_store.id} from {len(documents)} file(s) in data and sharepoint.")
        print(vector_store.id)
    except Exception as error:
        if "vector_store" in locals():
            delete_vector_store_after_failure(openai, vector_store.id)
        if isinstance(error, RuntimeError):
            raise
        raise RuntimeError(f"Foundry knowledge-base indexing failed: {error}") from error
    finally:
        project.close()


if __name__ == "__main__":
    main()
