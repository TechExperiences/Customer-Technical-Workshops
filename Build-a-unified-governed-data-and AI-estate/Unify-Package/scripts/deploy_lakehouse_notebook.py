"""Deploy the Unified_Ingestion_Notebook into the Fabric workspace and run it.

Materializes the Lakehouse Delta tables that the semantic model binds to, since
Fabric item creation doesn't automatically run Spark pipelines against raw files.
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import time
from pathlib import Path

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
PACKAGE_ROOT = Path(__file__).resolve().parents[1]


def token() -> str:
    access_token = os.environ.get("AZURE_FABRIC_ACCESS_TOKEN")
    if not access_token:
        raise RuntimeError("AZURE_FABRIC_ACCESS_TOKEN is missing. Run this script through .\\up.ps1.")
    return access_token


class Api:
    def __init__(self, access_token: str):
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})

    def request(self, method: str, path: str, body: dict | None = None) -> dict:
        response = self.session.request(method, f"{FABRIC_API}{path}", json=body, timeout=60)
        if not response.ok:
            raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text}")
        if response.status_code == 202:
            operation = response.headers.get("x-ms-operation-id")
            if operation:
                return self.wait(operation)
        return response.json() if response.content else {}

    def wait(self, operation_id: str) -> dict:
        for _ in range(120):
            operation = self.request("GET", f"/operations/{operation_id}")
            if operation.get("status") == "Succeeded":
                return operation
            if operation.get("status") in {"Failed", "Cancelled"}:
                raise RuntimeError(json.dumps(operation, indent=2))
            time.sleep(5)
        raise TimeoutError(f"Fabric operation {operation_id} did not complete in time")

    def list_all(self, path: str) -> list[dict]:
        # Fabric list endpoints paginate via continuationToken; a single unpaginated
        # GET can silently miss an existing item once a workspace spans multiple pages.
        results: list[dict] = []
        next_path = path
        while next_path:
            response = self.request("GET", next_path)
            results.extend(response.get("value", []))
            token = response.get("continuationToken")
            if not token:
                break
            separator = "&" if "?" in path else "?"
            next_path = f"{path}{separator}continuationToken={token}"
        return results


def first(items: list[dict], display_name: str) -> dict | None:
    return next((item for item in items if item.get("displayName") == display_name), None)


def encode(text: str) -> str:
    return base64.b64encode(text.encode("utf-8")).decode("utf-8")


def platform_part(display_name: str) -> str:
    return encode(json.dumps({
        "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
        "metadata": {"type": "Notebook", "displayName": display_name},
        "config": {"version": "2.0", "logicalId": "00000000-0000-0000-0000-000000000000"},
    }))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    parser.add_argument("--lakehouse-name", default="Caldova_Lakehouse")
    parser.add_argument("--notebook-name", default="Unified_Ingestion_Notebook")
    args = parser.parse_args()

    fabric = Api(token())
    source = (PACKAGE_ROOT / "notebooks" / "Unified_Ingestion_Notebook.py").read_text(encoding="utf-8")
    source = (source
        .replace("__LAKEHOUSE_ID__", args.lakehouse_id)
        .replace("__LAKEHOUSE_NAME__", args.lakehouse_name)
        .replace("__WORKSPACE_ID__", args.workspace_id))

    definition = {
        "format": "fabricGitSource",
        "parts": [
            {"path": "notebook-content.py", "payload": encode(source), "payloadType": "InlineBase64"},
            {"path": ".platform", "payload": platform_part(args.notebook_name), "payloadType": "InlineBase64"},
        ],
    }

    items = fabric.list_all(f"/workspaces/{args.workspace_id}/items")
    notebook = first(items, args.notebook_name)
    if notebook is None:
        notebook = fabric.request("POST", f"/workspaces/{args.workspace_id}/notebooks", {
            "displayName": args.notebook_name,
            "definition": definition,
        })
        items = fabric.list_all(f"/workspaces/{args.workspace_id}/items")
        notebook = first(items, args.notebook_name)
    else:
        fabric.request("POST", f"/workspaces/{args.workspace_id}/items/{notebook['id']}/updateDefinition", {
            "definition": definition,
        })

    # The "run on demand item job" endpoint returns 202 with an empty body and the
    # job instance ID only in the Location header - unlike other Fabric LRO endpoints,
    # which return it via x-ms-operation-id. Bypass the generic request() helper (it
    # only knows the x-ms-operation-id convention) and parse the ID out directly, the
    # same way Microsoft's own microsoft-iq-solution-accelerator does it.
    response = fabric.session.request(
        "POST",
        f"{FABRIC_API}/workspaces/{args.workspace_id}/items/{notebook['id']}/jobs/instances?jobType=RunNotebook",
        json={},
        timeout=60,
    )
    if not response.ok:
        raise RuntimeError(f"Notebook run request failed: {response.status_code}: {response.text}")
    location = response.headers.get("Location") or response.headers.get("location")
    if not location:
        raise RuntimeError(f"Notebook run did not return a Location header: {response.status_code} {response.text}")
    job_instance_id = location.split("?")[0].rstrip("/").rsplit("/", 1)[-1]

    for _ in range(120):
        status = fabric.request(
            "GET", f"/workspaces/{args.workspace_id}/items/{notebook['id']}/jobs/instances/{job_instance_id}"
        )
        state = status.get("status")
        if state == "Completed":
            print(f"Notebook {args.notebook_name} run completed.")
            return
        if state in {"Failed", "Cancelled", "Deduped"}:
            raise RuntimeError(f"Notebook run ended with status {state}: {json.dumps(status, indent=2)}")
        time.sleep(15)
    raise TimeoutError(f"Notebook {args.notebook_name} run did not complete in time.")


if __name__ == "__main__":
    main()
