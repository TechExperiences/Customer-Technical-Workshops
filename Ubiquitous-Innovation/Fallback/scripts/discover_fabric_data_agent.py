"""Discover the single published Fabric Data Agent created by FabricAutomation.

The source resource group identifies the Fabric capacity. The workspace and
Data Agent are Fabric artifacts, so their IDs are discovered through Fabric's
API and never supplied in .env.
"""
from __future__ import annotations

import argparse
import json
import os

import requests


FABRIC_API = "https://api.fabric.microsoft.com/v1"
DATA_AGENT_NAME = "Ubiquitous_Innovation_DataAgent"
WORKSPACE_PREFIX = "Ubiquitous-Innovation-"


class FabricApi:
    def __init__(self, access_token: str) -> None:
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {access_token}"})

    def list_all(self, path: str) -> list[dict]:
        items: list[dict] = []
        next_path = path
        while next_path:
            response = self.session.get(f"{FABRIC_API}{next_path}", timeout=60)
            if not response.ok:
                raise RuntimeError(f"GET {path} failed ({response.status_code}): {response.text}")
            body = response.json()
            items.extend(body.get("value", []))
            continuation = body.get("continuationToken")
            separator = "&" if "?" in path else "?"
            next_path = f"{path}{separator}continuationToken={continuation}" if continuation else ""
        return items


def exactly_one(values: list[dict], description: str) -> dict:
    if len(values) != 1:
        raise RuntimeError(
            f"Expected exactly one {description}, found {len(values)}. "
            "The Fallback pipeline will not guess or reuse an arbitrary Fabric artifact."
        )
    return values[0]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capacity-name", required=True)
    args = parser.parse_args()

    access_token = os.environ.get("AZURE_FABRIC_ACCESS_TOKEN")
    if not access_token:
        raise RuntimeError("AZURE_FABRIC_ACCESS_TOKEN is unavailable. Run through up.ps1.")
    api = FabricApi(access_token)

    capacity = exactly_one(
        [
            item
            for item in api.list_all("/capacities")
            if item.get("displayName", "").casefold() == args.capacity_name.casefold()
            and item.get("state", "").casefold() == "active"
            and item.get("id")
        ],
        f"active Fabric capacity named {args.capacity_name!r}",
    )
    capacity_id = capacity["id"]
    workspace = exactly_one(
        [
            item
            for item in api.list_all("/workspaces")
            if item.get("capacityId") == capacity_id
            and item.get("displayName", "").startswith(WORKSPACE_PREFIX)
            and item.get("id")
        ],
        f"Fabric workspace assigned to capacity {args.capacity_name!r}",
    )
    workspace_id = workspace["id"]
    data_agent = exactly_one(
        [
            item
            for item in api.list_all(f"/workspaces/{workspace_id}/items")
            if item.get("type") == "DataAgent"
            and item.get("displayName") == DATA_AGENT_NAME
            and item.get("id")
        ],
        f"Data Agent named {DATA_AGENT_NAME!r} in workspace {workspace.get('displayName')!r}",
    )
    data_agent_id = data_agent["id"]
    print(
        json.dumps(
            {
                "workspaceId": workspace_id,
                "dataAgentId": data_agent_id,
                "mcpUrl": f"{FABRIC_API}/mcp/workspaces/{workspace_id}/dataagents/{data_agent_id}/agent",
            }
        )
    )


if __name__ == "__main__":
    main()
