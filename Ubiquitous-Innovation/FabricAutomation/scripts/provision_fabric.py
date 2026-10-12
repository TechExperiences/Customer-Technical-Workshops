"""Create one new Fabric workspace and one Lakehouse on a newly created capacity."""
from __future__ import annotations

import argparse
import json
import os
import time

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"


class FabricApi:
    def __init__(self, token: str) -> None:
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token}", "Content-Type": "application/json"})

    def request(self, method: str, path: str, body: dict | None = None) -> dict:
        response = self.session.request(method, f"{FABRIC_API}{path}", json=body, timeout=60)
        if not response.ok:
            raise RuntimeError(f"{method} {path} failed ({response.status_code}): {response.text}")
        if response.status_code == 202 and response.headers.get("x-ms-operation-id"):
            return self.wait_operation(response.headers["x-ms-operation-id"])
        return response.json() if response.content else {}

    def wait_operation(self, operation_id: str) -> dict:
        for _ in range(120):
            operation = self.request("GET", f"/operations/{operation_id}")
            if operation.get("status") == "Succeeded":
                return operation
            if operation.get("status") in {"Failed", "Cancelled"}:
                raise RuntimeError(json.dumps(operation, indent=2))
            time.sleep(5)
        raise TimeoutError(f"Fabric operation {operation_id} did not complete within ten minutes.")

    def list_all(self, path: str) -> list[dict]:
        values: list[dict] = []
        next_path = path
        while next_path:
            response = self.request("GET", next_path)
            values.extend(response.get("value", []))
            continuation = response.get("continuationToken")
            next_path = f"{path}?continuationToken={continuation}" if continuation else ""
        return values


def fabric_capacity_id(api: FabricApi, capacity_resource_id: str) -> str:
    capacity_name = capacity_resource_id.rstrip("/").rsplit("/", 1)[-1]
    for _ in range(36):
        matches = [
            capacity for capacity in api.list_all("/capacities")
            if capacity.get("displayName", "").casefold() == capacity_name.casefold()
        ]
        if len(matches) == 1 and matches[0].get("state", "").casefold() == "active" and matches[0].get("id"):
            return matches[0]["id"]
        if len(matches) > 1:
            raise RuntimeError(f"Multiple Fabric capacities have the unexpected name {capacity_name!r}.")
        time.sleep(5)
    raise TimeoutError(f"New capacity {capacity_name!r} did not become active within three minutes.")


def wait_for_capacity_assignment(api: FabricApi, workspace_id: str) -> None:
    for _ in range(36):
        workspace = api.request("GET", f"/workspaces/{workspace_id}")
        progress = workspace.get("capacityAssignmentProgress")
        if progress == "Completed":
            return
        if progress == "Failed":
            raise RuntimeError(f"Workspace capacity assignment failed: {json.dumps(workspace, indent=2)}")
        time.sleep(5)
    raise TimeoutError("New workspace capacity assignment did not complete within three minutes.")


def wait_for_lakehouse(api: FabricApi, workspace_id: str, lakehouse_name: str) -> dict:
    for _ in range(36):
        items = api.list_all(f"/workspaces/{workspace_id}/items")
        lakehouse = next((item for item in items if item.get("displayName") == lakehouse_name and item.get("type") == "Lakehouse"), None)
        if lakehouse and lakehouse.get("id"):
            return lakehouse
        time.sleep(5)
    raise TimeoutError("New Lakehouse did not materialize within three minutes.")


def ensure_workspace_admin(api: FabricApi, workspace_id: str, principal_id: str) -> None:
    """Grant Admin only when the supplied user is not already a workspace Admin."""
    assignments = api.list_all(f"/workspaces/{workspace_id}/roleAssignments")
    matching_assignments = [
        assignment for assignment in assignments
        if assignment.get("principal", {}).get("id", "").casefold() == principal_id.casefold()
    ]
    if any(assignment.get("role") == "Admin" for assignment in matching_assignments):
        return
    if matching_assignments:
        existing_roles = ", ".join(sorted({str(assignment.get("role")) for assignment in matching_assignments}))
        raise RuntimeError(
            f"Workspace administrator {principal_id} already has workspace role(s) {existing_roles}, "
            "not Admin. The creation-only workflow will not replace an existing role assignment."
        )
    api.request("POST", f"/workspaces/{workspace_id}/roleAssignments", {
        "principal": {"id": principal_id, "type": "User"},
        "role": "Admin",
    })


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capacity-resource-id", required=True)
    parser.add_argument("--workspace-name", required=True)
    parser.add_argument("--lakehouse-name", required=True)
    parser.add_argument("--workspace-admin-principal-id", required=True)
    args = parser.parse_args()

    access_token = os.environ.get("AZURE_FABRIC_ACCESS_TOKEN")
    if not access_token:
        raise RuntimeError("AZURE_FABRIC_ACCESS_TOKEN is not available. Run through up.ps1.")
    api = FabricApi(access_token)
    capacity_id = fabric_capacity_id(api, args.capacity_resource_id)

    # This endpoint creates the workspace already assigned to the just-created capacity.
    # It intentionally does not search for, reuse, or reassign any workspace.
    workspace = api.request("POST", "/workspaces", {"displayName": args.workspace_name, "capacityId": capacity_id})
    workspace_id = workspace.get("id")
    if not workspace_id:
        raise RuntimeError(f"Workspace creation returned no workspace ID: {json.dumps(workspace, indent=2)}")
    wait_for_capacity_assignment(api, workspace_id)
    ensure_workspace_admin(api, workspace_id, args.workspace_admin_principal_id)

    # This endpoint creates a new, schema-enabled Lakehouse only. It intentionally
    # performs no existing-item lookup or update.
    api.request("POST", f"/workspaces/{workspace_id}/lakehouses", {
        "displayName": args.lakehouse_name,
        "creationPayload": {"enableSchemas": True},
    })
    lakehouse = wait_for_lakehouse(api, workspace_id, args.lakehouse_name)
    print(json.dumps({"workspaceId": workspace_id, "lakehouseId": lakehouse["id"]}))


if __name__ == "__main__":
    main()
