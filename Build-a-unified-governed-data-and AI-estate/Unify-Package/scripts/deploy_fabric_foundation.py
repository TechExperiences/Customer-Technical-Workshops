"""Create or reuse the Fabric workspace, Lakehouse, and Fabric SQL Database through Fabric REST APIs."""
from __future__ import annotations

import argparse
import json
import subprocess
import time

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
ARM_API = "https://management.azure.com"


def token(resource: str) -> str:
    response = subprocess.run(
        ["az", "account", "get-access-token", "--resource", resource, "-o", "json"],
        check=True, capture_output=True, text=True,
    )
    return json.loads(response.stdout)["accessToken"]


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


def capacity_guid(resource_id: str) -> str:
    arm = Api(ARM_API, token("https://management.azure.com/"))
    resource = arm.request("GET", f"{resource_id}?api-version=2023-11-01")
    guid = resource.get("properties", {}).get("guid")
    if not guid:
        raise RuntimeError("Fabric capacity GUID was not returned by ARM. Verify capacity provisioning completed.")
    return guid


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
        workspace = fabric.request("POST", "/workspaces", {"displayName": args.workspace, "capacityId": capacity_guid(args.capacity_resource_id)})
    workspace_id = workspace["id"]

    items = fabric.request("GET", f"/workspaces/{workspace_id}/items").get("value", [])
    lakehouse = first(items, args.lakehouse)
    if lakehouse is None:
        lakehouse = fabric.request("POST", f"/workspaces/{workspace_id}/items", {"displayName": args.lakehouse, "type": "Lakehouse"})

    sql_database = first(items, args.sql_database)
    if sql_database is None:
        sql_database = fabric.request("POST", f"/workspaces/{workspace_id}/sqlDatabases", {"displayName": args.sql_database})

    print(json.dumps({
        "workspaceId": workspace_id,
        "lakehouseId": lakehouse["id"],
        "sqlDatabaseId": sql_database["id"],
    }, indent=2))


if __name__ == "__main__":
    main()
