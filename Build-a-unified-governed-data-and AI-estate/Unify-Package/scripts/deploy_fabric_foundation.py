"""Create or reuse the Fabric workspace, Lakehouse, and Fabric SQL Database through Fabric REST APIs."""
from __future__ import annotations

import argparse
import json
import os
import time

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
TOKEN_ENVIRONMENTS = {
    "https://api.fabric.microsoft.com": "AZURE_FABRIC_ACCESS_TOKEN",
}


def token(resource: str) -> str:
    environment_name = TOKEN_ENVIRONMENTS[resource]
    access_token = os.environ.get(environment_name)
    if not access_token:
        raise RuntimeError(
            f"{environment_name} is missing. Run this script through .\\up.ps1 so PowerShell can acquire the token."
        )
    return access_token


class Api:
    def __init__(self, root: str, access_token: str):
        self.root = root.rstrip("/")
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})

    def request(self, method: str, path: str, body: dict | None = None) -> dict:
        response = self.session.request(method, f"{self.root}{path}", json=body, timeout=60)
        response.raise_for_status()
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


def first(items: list[dict], display_name: str) -> dict | None:
    return next((item for item in items if item.get("displayName") == display_name), None)


def wait_for_workspace_item(fabric: Api, workspace_id: str, display_name: str) -> dict:
    """Return an item only after Fabric has materialized its final item ID.

    Several Fabric create endpoints complete asynchronously.  Their initial response
    is an operation object, not the workspace item, so it cannot be used as an ID.
    """
    for _ in range(24):
        items = fabric.request("GET", f"/workspaces/{workspace_id}/items").get("value", [])
        item = first(items, display_name)
        if item and item.get("id"):
            return item
        time.sleep(5)
    raise TimeoutError(
        f"Fabric item {display_name!r} did not appear in workspace {workspace_id} with an ID after two minutes."
    )


def fabric_capacity_id(fabric: Api, azure_capacity_resource_id: str) -> str:
    """Resolve the Fabric capacity GUID from the Fabric API, not ARM metadata.

    Azure Resource Manager owns the Azure resource and does not consistently expose
    Fabric's internal GUID in properties.  The workspace API requires the Fabric API
    capacity ID, which is returned by GET /capacities.
    """
    capacity_name = azure_capacity_resource_id.rstrip("/").rsplit("/", 1)[-1]
    last_state = "not yet visible in Fabric"
    for _ in range(24):  # Capacity registration can take a short time after ARM succeeds.
        capacities = fabric.request("GET", "/capacities").get("value", [])
        matches = [
            capacity for capacity in capacities
            if capacity.get("displayName", "").casefold() == capacity_name.casefold()
        ]
        if len(matches) > 1:
            raise RuntimeError(f"More than one Fabric capacity matches Azure resource name {capacity_name!r}.")
        if matches:
            capacity = matches[0]
            last_state = str(capacity.get("state", "Unknown"))
            if last_state.casefold() == "active" and capacity.get("id"):
                return capacity["id"]
        time.sleep(5)
    raise RuntimeError(
        f"Fabric capacity {capacity_name!r} was not available and Active after two minutes "
        f"(last state: {last_state}). Verify the capacity is active and the signed-in user has Capacity.Read.All access."
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capacity-resource-id", required=True)
    parser.add_argument("--workspace", default="Caldova-Build-Unify")
    parser.add_argument("--lakehouse", default="Caldova_Lakehouse")
    parser.add_argument("--sql-database", default="Caldova_SQLDatabase")
    args = parser.parse_args()

    fabric = Api(FABRIC_API, token("https://api.fabric.microsoft.com"))
    workspaces = fabric.request("GET", "/workspaces").get("value", [])
    workspace = first(workspaces, args.workspace)
    if workspace is None:
        workspace = fabric.request("POST", "/workspaces", {
            "displayName": args.workspace,
            "capacityId": fabric_capacity_id(fabric, args.capacity_resource_id),
        })
    workspace_id = workspace["id"]

    items = fabric.request("GET", f"/workspaces/{workspace_id}/items").get("value", [])
    lakehouse = first(items, args.lakehouse)
    if lakehouse is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/items", {"displayName": args.lakehouse, "type": "Lakehouse"})
        lakehouse = wait_for_workspace_item(fabric, workspace_id, args.lakehouse)

    sql_database = first(items, args.sql_database)
    if sql_database is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/sqlDatabases", {"displayName": args.sql_database})
        sql_database = wait_for_workspace_item(fabric, workspace_id, args.sql_database)

    print(json.dumps({
        "workspaceId": workspace_id,
        "lakehouseId": lakehouse["id"],
        "sqlDatabaseId": sql_database["id"],
    }, indent=2))


if __name__ == "__main__":
    main()
