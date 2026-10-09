"""Deploy a Fabric Data Agent sourced from the unified Semantic Model and publish it."""
from __future__ import annotations

import argparse
import base64
import json
import os
import time
import uuid

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
LINEAGE_NAMESPACE = uuid.UUID("a7d99ee8-718c-5e3d-a52f-e966b51288a1")

# Every table in the semantic model (deploy_semantic_model.py's LAKEHOUSE_TABLES).
# The Data Agent's datasource.json "elements" array must use the semantic
# model's actual table lineage IDs.  Random IDs display table names in Fabric
# but are treated as deleted table references at query time.
SEMANTIC_MODEL_TABLES = [
    "DimDate", "DimLocation", "DimMaterial", "DimPlant", "DimProduct", "DimSupplier",
    "FactInventory", "FactInventorySnapshot", "FactProduction", "FactQuality", "FactSales",
    "FactShipment", "FactSupplyChain",
    "Supplier", "Material", "PurchaseOrder", "ManufacturingBatch", "Inventory",
    "PurchaseOrderItem", "QualityInspection", "Shipment",
    "CustomerDetails", "CustomerAddress",
]

AI_INSTRUCTIONS = """You are the Caldova Unified Data Estate analytics agent. Answer questions about \
sales, products, plants, suppliers, materials, manufacturing, inventory, shipments, purchase orders, \
quality inspections, and customers using only the Caldova_Unified_SemanticModel semantic model.

Behavior rules:
- Use the semantic model as the source of truth for tables, columns, and relationships.
- Do not invent values, IDs, or relationships that are not present in the model.
- Prefer the most direct relationship path available between entities.
- Return human-readable names alongside keys when both are available (e.g. ProductName with ProductID).
- For aggregations, use DAX aggregation functions (SUM, AVERAGE, COUNTROWS) to ensure accuracy.
- If a user term is ambiguous, ask one short clarification question.
- If no rows are found, state which filter was applied and suggest an alternative.
"""


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


def encode(obj: dict) -> str:
    return base64.b64encode(json.dumps(obj).encode("utf-8")).decode("utf-8")


def semantic_table_lineage_id(table_name: str) -> str:
    return str(uuid.uuid5(LINEAGE_NAMESPACE, f"table/{table_name}"))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--semantic-model-id", required=True)
    parser.add_argument("--semantic-model-name", default="Caldova_Unified_SemanticModel")
    parser.add_argument("--agent-name", default="Caldova_Unified_DataAgent")
    args = parser.parse_args()

    fabric = Api(token())
    data_source_folder = f"semantic_model-{args.semantic_model_name}"
    datasource = {
        "$schema": "1.0.0",
        "artifactId": args.semantic_model_id,
        "workspaceId": args.workspace_id,
        "displayName": args.semantic_model_name,
        "type": "semantic_model",
        "userDescription": "Unified Caldova Analytical, Operational, and Customer data spanning the Lakehouse and Fabric SQL Database.",
        "elements": [
            {
                "id": semantic_table_lineage_id(table),
                "is_selected": True,
                "display_name": table,
                "type": "semantic_model.table",
            }
            for table in SEMANTIC_MODEL_TABLES
        ],
    }
    stage_config = {"$schema": "1.0.0", "aiInstructions": AI_INSTRUCTIONS}
    publish_info = {"$schema": "1.0.0", "description": "Published by Post-Provision.ps1"}

    definition = {
        "parts": [
            {"path": "Files/Config/data_agent.json", "payload": encode({"$schema": "2.1.0"}), "payloadType": "InlineBase64"},
            {"path": f"Files/Config/draft/{data_source_folder}/datasource.json", "payload": encode(datasource), "payloadType": "InlineBase64"},
            {"path": "Files/Config/draft/stage_config.json", "payload": encode(stage_config), "payloadType": "InlineBase64"},
            {"path": f"Files/Config/published/{data_source_folder}/datasource.json", "payload": encode(datasource), "payloadType": "InlineBase64"},
            {"path": "Files/Config/published/stage_config.json", "payload": encode(stage_config), "payloadType": "InlineBase64"},
            {"path": "Files/Config/publish_info.json", "payload": encode(publish_info), "payloadType": "InlineBase64"},
        ],
    }

    items = fabric.list_all(f"/workspaces/{args.workspace_id}/items")
    agent = first(items, args.agent_name)
    if agent is None:
        fabric.request("POST", f"/workspaces/{args.workspace_id}/dataAgents", {
            "displayName": args.agent_name,
            "definition": definition,
        })
        items = fabric.list_all(f"/workspaces/{args.workspace_id}/items")
        agent = first(items, args.agent_name)
    else:
        fabric.request("POST", f"/workspaces/{args.workspace_id}/items/{agent['id']}/updateDefinition", {
            "definition": definition,
        })

    fabric.request("POST", f"/workspaces/{args.workspace_id}/dataAgents/{agent['id']}/staging/publish", {
        "publishedDescription": "Published by Post-Provision.ps1",
    })
    print(json.dumps({"dataAgentId": agent["id"]}, indent=2))


if __name__ == "__main__":
    main()
