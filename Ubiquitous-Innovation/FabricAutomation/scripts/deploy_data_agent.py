"""Create and publish a Fabric Data Agent bound to the Ubiquitous semantic model."""
from __future__ import annotations

import argparse
import base64
import json
import os
import time
import uuid

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
LINEAGE_NAMESPACE = uuid.UUID("c51ee716-a8e0-5ab9-a34d-1dc5a09898d6")
SEMANTIC_MODEL_TABLES = [
    "EquipmentQualification", "Inventory", "Plant", "PlantCapacity", "Product", "ProductionPlan",
]

AI_INSTRUCTIONS = """You are the Ubiquitous Innovation manufacturing analytics agent.
Answer only from the connected Ubiquitous_Innovation_SemanticModel.

Use the model's Product, Plant, Inventory, PlantCapacity, ProductionPlan, and
EquipmentQualification tables and their relationships. Do not invent values,
IDs, relationships, or data that are not present in the model. For quantities
and capacity questions, calculate accurate aggregations. When appropriate,
return product and plant names alongside their IDs. Ask one concise clarification
question if the requested metric, plant, product, or date range is ambiguous.
"""


def token() -> str:
    value = os.environ.get("AZURE_FABRIC_ACCESS_TOKEN")
    if not value:
        raise RuntimeError("AZURE_FABRIC_ACCESS_TOKEN is missing. Run this script through .\\up.ps1.")
    return value


class FabricApi:
    def __init__(self, access_token: str) -> None:
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})

    def request(self, method: str, path: str, body: dict | None = None) -> dict:
        response = self.session.request(method, f"{FABRIC_API}{path}", json=body, timeout=60)
        if not response.ok:
            raise RuntimeError(f"{method} {path} -> {response.status_code}: {response.text}")
        if response.status_code == 202 and response.headers.get("x-ms-operation-id"):
            return self.wait(response.headers["x-ms-operation-id"])
        return response.json() if response.content else {}

    def wait(self, operation_id: str) -> dict:
        for _ in range(120):
            operation = self.request("GET", f"/operations/{operation_id}")
            if operation.get("status") == "Succeeded":
                return operation
            if operation.get("status") in {"Failed", "Cancelled"}:
                raise RuntimeError(json.dumps(operation, indent=2))
            time.sleep(5)
        raise TimeoutError("Fabric operation did not complete within ten minutes.")

    def list_all(self, path: str) -> list[dict]:
        items: list[dict] = []
        next_path = path
        while next_path:
            response = self.request("GET", next_path)
            items.extend(response.get("value", []))
            continuation = response.get("continuationToken")
            next_path = f"{path}?continuationToken={continuation}" if continuation else ""
        return items


def encode(value: object) -> str:
    return base64.b64encode(json.dumps(value, separators=(",", ":")).encode("utf-8")).decode("utf-8")


def table_lineage_id(table_name: str) -> str:
    return str(uuid.uuid5(LINEAGE_NAMESPACE, f"table/{table_name}"))


def find_data_agent(items: list[dict], display_name: str) -> dict | None:
    return next(
        (item for item in items if item.get("displayName") == display_name and item.get("type") == "DataAgent"),
        None,
    )


def wait_for_data_agent(fabric: FabricApi, workspace_id: str, display_name: str) -> dict:
    for _ in range(24):
        item = find_data_agent(fabric.list_all(f"/workspaces/{workspace_id}/items"), display_name)
        if item and item.get("id"):
            return item
        time.sleep(5)
    raise TimeoutError(f"Data Agent {display_name!r} did not appear within two minutes.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--semantic-model-id", required=True)
    parser.add_argument("--semantic-model-name", default="Ubiquitous_Innovation_SemanticModel")
    parser.add_argument("--agent-name", default="Ubiquitous_Innovation_DataAgent")
    args = parser.parse_args()

    data_source_folder = f"semantic_model-{args.semantic_model_name}"
    datasource = {
        "$schema": "1.0.0",
        "artifactId": args.semantic_model_id,
        "workspaceId": args.workspace_id,
        "displayName": args.semantic_model_name,
        "type": "semantic_model",
        "userDescription": "Manufacturing, product, plant, inventory, capacity, production-plan, and equipment-qualification analytics.",
        "elements": [
            {
                "id": table_lineage_id(table_name),
                "is_selected": True,
                "display_name": table_name,
                "type": "semantic_model.table",
            }
            for table_name in SEMANTIC_MODEL_TABLES
        ],
    }
    definition = {
        "parts": [
            {"path": "Files/Config/data_agent.json", "payload": encode({"$schema": "2.1.0"}), "payloadType": "InlineBase64"},
            {"path": f"Files/Config/draft/{data_source_folder}/datasource.json", "payload": encode(datasource), "payloadType": "InlineBase64"},
            {"path": "Files/Config/draft/stage_config.json", "payload": encode({"$schema": "1.0.0", "aiInstructions": AI_INSTRUCTIONS}), "payloadType": "InlineBase64"},
            {"path": f"Files/Config/published/{data_source_folder}/datasource.json", "payload": encode(datasource), "payloadType": "InlineBase64"},
            {"path": "Files/Config/published/stage_config.json", "payload": encode({"$schema": "1.0.0", "aiInstructions": AI_INSTRUCTIONS}), "payloadType": "InlineBase64"},
            {"path": "Files/Config/publish_info.json", "payload": encode({"$schema": "1.0.0", "description": "Published by up.ps1"}), "payloadType": "InlineBase64"},
        ],
    }

    fabric = FabricApi(token())
    agent = find_data_agent(fabric.list_all(f"/workspaces/{args.workspace_id}/items"), args.agent_name)
    if agent:
        fabric.request("POST", f"/workspaces/{args.workspace_id}/items/{agent['id']}/updateDefinition", {"definition": definition})
    else:
        fabric.request("POST", f"/workspaces/{args.workspace_id}/dataAgents", {"displayName": args.agent_name, "definition": definition})
        agent = wait_for_data_agent(fabric, args.workspace_id, args.agent_name)

    fabric.request("POST", f"/workspaces/{args.workspace_id}/dataAgents/{agent['id']}/staging/publish", {
        "publishedDescription": "Published by up.ps1",
    })
    print(json.dumps({"dataAgentId": agent["id"]}))


if __name__ == "__main__":
    main()
