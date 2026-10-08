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
        if not response.ok:
            # Surface Fabric's own errorCode/message instead of a bare "403 Forbidden",
            # since that detail is what actually explains an item-creation rejection.
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
        # GET can silently miss items (an existing Lakehouse, for example) once a
        # workspace holds enough items to span more than one page.
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


def wait_for_workspace_item(fabric: Api, workspace_id: str, display_name: str) -> dict:
    """Return an item only after Fabric has materialized its final item ID.

    Several Fabric create endpoints complete asynchronously.  Their initial response
    is an operation object, not the workspace item, so it cannot be used as an ID.
    """
    for _ in range(24):
        items = fabric.list_all(f"/workspaces/{workspace_id}/items")
        item = first(items, display_name)
        if item and item.get("id"):
            return item
        time.sleep(5)
    raise TimeoutError(
        f"Fabric item {display_name!r} did not appear in workspace {workspace_id} with an ID after two minutes."
    )


def wait_for_capacity_assignment(fabric: Api, workspace_id: str) -> None:
    """Block until the workspace's capacity binding is actually usable.

    Item creation on a non-PowerBI type requires the workspace's capacity assignment
    to have finished. Get Workspace reports this directly via capacityAssignmentProgress
    (Completed/InProgress/Failed), so this polls that documented field instead of
    guessing with blind retries on whatever error an unready workspace happens to return.
    """
    for _ in range(24):
        workspace = fabric.request("GET", f"/workspaces/{workspace_id}")
        progress = workspace.get("capacityAssignmentProgress")
        if progress == "Completed":
            return
        if progress == "Failed":
            raise RuntimeError(f"Workspace {workspace_id} capacity assignment failed: {json.dumps(workspace, indent=2)}")
        time.sleep(5)
    raise TimeoutError(f"Workspace {workspace_id} capacity assignment did not complete within two minutes.")


def get_or_none(fabric: Api, path: str) -> dict | None:
    """GET a Fabric resource, returning None on a 404 instead of raising.

    Used to detect items left behind by an earlier failed run: they still show up
    in the generic workspace items list by display name, but their own item-type
    detail endpoint has no record of them and never will - no amount of retrying
    that GET will make it appear. The caller discards the stale reference and
    recreates the item instead. A pinned item ID queried under the wrong workspace
    (e.g. the pinned workspace itself vanished and a different one had to be used)
    surfaces as 401 Unauthorized rather than 404, so both are treated as "not found".
    """
    try:
        return fabric.request("GET", path)
    except RuntimeError as error:
        if "404" in str(error) or "401" in str(error):
            return None
        raise


def fabric_capacity_id(fabric: Api, azure_capacity_resource_id: str) -> str:
    """Resolve the Fabric capacity GUID from the Fabric API, not ARM metadata.

    Azure Resource Manager owns the Azure resource and does not consistently expose
    Fabric's internal GUID in properties.  The workspace API requires the Fabric API
    capacity ID, which is returned by GET /capacities.
    """
    capacity_name = azure_capacity_resource_id.rstrip("/").rsplit("/", 1)[-1]
    last_state = "not yet visible in Fabric"
    for _ in range(24):  # Capacity registration can take a short time after ARM succeeds.
        capacities = fabric.list_all("/capacities")
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

    # Always resolved by display name, every run - no ID is ever persisted/trusted
    # across runs. This matches the pattern in Microsoft's own microsoft-iq-solution-
    # accelerator (infra/scripts/fabric/step_workspace_setup.py): a pinned ID is only
    # a correctness risk in a sandbox tenant that can delete workspaces or drop their
    # capacity binding between runs, whereas a fresh by-name lookup self-heals for
    # free (a deleted workspace simply isn't found, and a fresh one is created).
    capacity_id = fabric_capacity_id(fabric, args.capacity_resource_id)
    workspaces = fabric.list_all("/workspaces")
    workspace = next(
        (w for w in workspaces if w.get("displayName") == args.workspace and w.get("capacityId") == capacity_id),
        None,
    )
    if workspace is None:
        # Also consider a same-named workspace that has lost its capacity binding
        # (observed directly in this sandbox), rather than creating a duplicate
        # workspace next to one that just needs reassigning.
        workspace = next((w for w in workspaces if w.get("displayName") == args.workspace), None)
    if workspace is None:
        workspace = fabric.request("POST", "/workspaces", {
            "displayName": args.workspace,
            "capacityId": capacity_id,
        })
    workspace_id = workspace["id"]

    # Idempotent: reassigning to the same capacity is a safe no-op when already bound,
    # and self-heals the workspace when the assignment has silently dropped (also
    # observed directly in this sandbox).
    fabric.request("POST", f"/workspaces/{workspace_id}/assignToCapacity", {"capacityId": capacity_id})
    wait_for_capacity_assignment(fabric, workspace_id)

    items = fabric.list_all(f"/workspaces/{workspace_id}/items")
    lakehouse = first(items, args.lakehouse)
    if lakehouse is not None:
        lakehouse_details = get_or_none(fabric, f"/workspaces/{workspace_id}/lakehouses/{lakehouse['id']}")
        # A Lakehouse created without creationPayload.enableSchemas is permanently flat -
        # schemas cannot be enabled in place - so the notebook's "CREATE SCHEMA dbo" and
        # every dbo.<table> write fail immediately. Treat a schema-less Lakehouse the same
        # as an orphaned one: discard and recreate with schemas enabled from the start.
        if lakehouse_details is None or not lakehouse_details.get("properties", {}).get("defaultSchema"):
            # The generic Items API DELETE returns 400 OperationNotSupportedForItem for a
            # Lakehouse; its own dedicated endpoint is required.
            fabric.request("DELETE", f"/workspaces/{workspace_id}/lakehouses/{lakehouse['id']}")
            lakehouse = None
    if lakehouse is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/lakehouses", {
            "displayName": args.lakehouse,
            "creationPayload": {"enableSchemas": True},
        })
        lakehouse = wait_for_workspace_item(fabric, workspace_id, args.lakehouse)

    sql_database = first(items, args.sql_database)
    sql_database_details = None
    if sql_database is not None:
        sql_database_details = get_or_none(fabric, f"/workspaces/{workspace_id}/sqlDatabases/{sql_database['id']}")
        if sql_database_details is None:
            # Same orphaned-leftover situation as the Lakehouse check above - and the same
            # dedicated-endpoint requirement for DELETE.
            fabric.request("DELETE", f"/workspaces/{workspace_id}/sqlDatabases/{sql_database['id']}")
            sql_database = None
    if sql_database is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/sqlDatabases", {"displayName": args.sql_database})
        sql_database = wait_for_workspace_item(fabric, workspace_id, args.sql_database)
        sql_database_details = fabric.request("GET", f"/workspaces/{workspace_id}/sqlDatabases/{sql_database['id']}")

    # The item list's entry has no "properties"; the dedicated detail fetch above
    # (either reused or freshly created) carries the TDS connection details for
    # the BusinessApplication ingestion Logic App.
    sql_database_properties = sql_database_details.get("properties", {})

    print(json.dumps({
        "workspaceId": workspace_id,
        "lakehouseId": lakehouse["id"],
        "sqlDatabaseId": sql_database["id"],
        "sqlDatabaseServerFqdn": sql_database_properties.get("serverFqdn"),
        "sqlDatabaseName": sql_database_properties.get("databaseName"),
    }, indent=2))


if __name__ == "__main__":
    main()
