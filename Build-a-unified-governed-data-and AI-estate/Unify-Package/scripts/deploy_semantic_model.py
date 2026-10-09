"""Deploy the unified Direct Lake Semantic Model and its bound Fabric report."""
from __future__ import annotations

import argparse
import base64
import json
import os
import time
import uuid
from pathlib import Path

import requests

FABRIC_API = "https://api.fabric.microsoft.com/v1"
# Stable lineage IDs let Fabric and the Data Agent continue referencing the same
# semantic-model tables after idempotent updateDefinition deployments.
LINEAGE_NAMESPACE = uuid.UUID("a7d99ee8-718c-5e3d-a52f-e966b51288a1")

# (table, [(column, dataType), ...]) - column lists come from the CSV headers and
# BusinessApplication JSON contracts already shipped in this package.  Every
# table is materialized as a Delta table by the Lakehouse ingestion notebook.
LAKEHOUSE_TABLES: dict[str, list[tuple[str, str]]] = {
    "DimDate": [("DateKey", "int64"), ("FullDate", "dateTime"), ("Year", "int64"), ("Quarter", "int64"),
                ("Month", "int64"), ("MonthName", "string"), ("Day", "int64")],
    "DimLocation": [("LocationID", "int64"), ("LocationName", "string"), ("City", "string"),
                     ("Country", "string"), ("LocationType", "string")],
    "DimMaterial": [("MaterialID", "int64"), ("MaterialName", "string"), ("MaterialType", "string"),
                     ("UnitOfMeasure", "string"), ("UnitCost", "double"), ("SupplierID", "int64")],
    "DimPlant": [("PlantID", "int64"), ("PlantName", "string"), ("Region", "string"), ("Country", "string")],
    "DimProduct": [("ProductID", "int64"), ("ProductName", "string"), ("Category", "string"),
                    ("Manufacturer", "string"), ("UnitPrice", "double"), ("LaunchDate", "dateTime")],
    "DimSupplier": [("SupplierID", "int64"), ("SupplierName", "string"), ("Country", "string"),
                     ("ContactEmail", "string"), ("QualityRating", "double"), ("OnboardedDate", "dateTime")],
    "FactInventory": [("InventoryID", "int64"), ("ProductID", "int64"), ("PlantID", "int64"),
                        ("CurrentInventory", "int64"), ("ReorderThreshold", "int64"), ("SafetyStock", "int64"),
                        ("InventoryStatus", "string"), ("SnapshotDate", "dateTime")],
    "FactInventorySnapshot": [("FactID", "int64"), ("DateKey", "int64"), ("ProductID", "int64"),
                                ("MaterialID", "int64"), ("PlantID", "int64"), ("QuantityOnHand", "int64"),
                                ("ReorderThreshold", "int64"), ("SafetyStock", "int64"), ("InventoryStatus", "string")],
    "FactProduction": [("FactID", "int64"), ("DateKey", "int64"), ("BatchID", "int64"), ("ProductID", "int64"),
                         ("PlantID", "int64"), ("MaterialID", "int64"), ("BatchSize", "int64"),
                         ("YieldPercentage", "double"), ("DurationDays", "int64"), ("Status", "string")],
    "FactQuality": [("FactID", "int64"), ("DateKey", "int64"), ("InspectionID", "int64"), ("BatchID", "int64"),
                     ("ProductID", "int64"), ("PlantID", "int64"), ("Result", "string"), ("DefectCount", "int64")],
    "FactSales": [("SalesID", "int64"), ("CustomerID", "int64"), ("ProductID", "int64"), ("PlantID", "int64"),
                   ("SalesDate", "dateTime"), ("UnitsSold", "int64"), ("TotalRevenue", "double"), ("Region", "string")],
    "FactShipment": [("FactID", "int64"), ("DateKey", "int64"), ("ShipmentID", "int64"), ("BatchID", "int64"),
                       ("ProductID", "int64"), ("PlantID", "int64"), ("DestinationLocationID", "int64"),
                       ("Quantity", "int64"), ("DeliveryDays", "int64"), ("Status", "string")],
    "FactSupplyChain": [("FactID", "int64"), ("DateKey", "int64"), ("PurchaseOrderID", "int64"),
                          ("SupplierID", "int64"), ("MaterialID", "int64"), ("PlantID", "int64"),
                          ("QuantityOrdered", "int64"), ("QuantityReceived", "int64"), ("UnitPrice", "double"),
                          ("LineTotal", "double"), ("LeadTimeDays", "int64")],
    "Supplier": [("SupplierID", "int64"), ("SupplierName", "string"), ("Country", "string"),
                  ("ContactEmail", "string"), ("QualityRating", "double"), ("OnboardedDate", "dateTime")],
    "Material": [("MaterialID", "int64"), ("MaterialName", "string"), ("MaterialType", "string"),
                  ("UnitOfMeasure", "string"), ("UnitCost", "double"), ("SupplierID", "int64")],
    "PurchaseOrder": [("PurchaseOrderID", "int64"), ("SupplierID", "int64"), ("PlantID", "int64"),
                        ("OrderDate", "dateTime"), ("ExpectedDeliveryDate", "dateTime"), ("Status", "string")],
    "ManufacturingBatch": [("BatchID", "int64"), ("ProductID", "int64"), ("PlantID", "int64"),
                             ("PrimaryMaterialID", "int64"), ("BatchSize", "int64"), ("StartDate", "dateTime"),
                             ("EndDate", "dateTime"), ("YieldPercentage", "double"), ("Status", "string")],
    "Inventory": [("InventoryID", "int64"), ("ProductID", "int64"), ("MaterialID", "int64"), ("PlantID", "int64"),
                   ("QuantityOnHand", "int64"), ("ReorderThreshold", "int64"), ("SafetyStock", "int64"),
                   ("LastUpdated", "dateTime")],
    "PurchaseOrderItem": [("PurchaseOrderItemID", "int64"), ("PurchaseOrderID", "int64"), ("MaterialID", "int64"),
                            ("QuantityOrdered", "int64"), ("QuantityReceived", "int64"), ("UnitPrice", "double"),
                            ("LineTotal", "double")],
    "QualityInspection": [("InspectionID", "int64"), ("BatchID", "int64"), ("InspectionDate", "dateTime"),
                            ("InspectorName", "string"), ("Result", "string"), ("DefectCount", "int64"),
                            ("Notes", "string")],
    "Shipment": [("ShipmentID", "int64"), ("BatchID", "int64"), ("ProductID", "int64"), ("PlantID", "int64"),
                  ("DestinationLocationID", "int64"), ("ShipDate", "dateTime"), ("DeliveryDate", "dateTime"),
                  ("Quantity", "int64"), ("Carrier", "string"), ("Status", "string")],
    "CustomerDetails": [("CustomerID", "int64"), ("CustomerName", "string"), ("Email", "string"),
                          ("Phone", "string"), ("Segment", "string"), ("AccountManager", "string"),
                          ("CreatedDate", "dateTime")],
    "CustomerAddress": [("AddressID", "int64"), ("CustomerID", "int64"), ("AddressLine1", "string"),
                          ("City", "string"), ("State", "string"), ("PostalCode", "string"),
                          ("Country", "string"), ("AddressType", "string")],
}

# (fromTable, fromColumn, toTable, toColumn) - the "to" side is always the one/unique side.
RELATIONSHIPS: list[tuple[str, str, str, str]] = [
    ("FactInventory", "ProductID", "DimProduct", "ProductID"),
    ("FactInventory", "PlantID", "DimPlant", "PlantID"),
    ("FactInventorySnapshot", "DateKey", "DimDate", "DateKey"),
    ("FactInventorySnapshot", "ProductID", "DimProduct", "ProductID"),
    ("FactInventorySnapshot", "PlantID", "DimPlant", "PlantID"),
    ("FactProduction", "DateKey", "DimDate", "DateKey"),
    ("FactProduction", "ProductID", "DimProduct", "ProductID"),
    ("FactProduction", "PlantID", "DimPlant", "PlantID"),
    ("FactProduction", "MaterialID", "DimMaterial", "MaterialID"),
    ("FactQuality", "DateKey", "DimDate", "DateKey"),
    ("FactQuality", "ProductID", "DimProduct", "ProductID"),
    ("FactQuality", "PlantID", "DimPlant", "PlantID"),
    ("FactSales", "ProductID", "DimProduct", "ProductID"),
    ("FactSales", "PlantID", "DimPlant", "PlantID"),
    ("FactShipment", "DateKey", "DimDate", "DateKey"),
    ("FactShipment", "ProductID", "DimProduct", "ProductID"),
    ("FactShipment", "PlantID", "DimPlant", "PlantID"),
    ("FactShipment", "DestinationLocationID", "DimLocation", "LocationID"),
    ("FactSupplyChain", "DateKey", "DimDate", "DateKey"),
    ("FactSupplyChain", "SupplierID", "DimSupplier", "SupplierID"),
    ("FactSupplyChain", "MaterialID", "DimMaterial", "MaterialID"),
    ("FactSupplyChain", "PlantID", "DimPlant", "PlantID"),
    ("DimMaterial", "SupplierID", "DimSupplier", "SupplierID"),
    ("Material", "SupplierID", "Supplier", "SupplierID"),
    ("PurchaseOrder", "SupplierID", "Supplier", "SupplierID"),
    ("PurchaseOrder", "PlantID", "DimPlant", "PlantID"),
    ("PurchaseOrderItem", "PurchaseOrderID", "PurchaseOrder", "PurchaseOrderID"),
    ("PurchaseOrderItem", "MaterialID", "Material", "MaterialID"),
    ("ManufacturingBatch", "PrimaryMaterialID", "Material", "MaterialID"),
    ("ManufacturingBatch", "ProductID", "DimProduct", "ProductID"),
    ("ManufacturingBatch", "PlantID", "DimPlant", "PlantID"),
    ("Inventory", "MaterialID", "Material", "MaterialID"),
    ("Inventory", "ProductID", "DimProduct", "ProductID"),
    ("Inventory", "PlantID", "DimPlant", "PlantID"),
    ("QualityInspection", "BatchID", "ManufacturingBatch", "BatchID"),
    ("Shipment", "BatchID", "ManufacturingBatch", "BatchID"),
    ("Shipment", "ProductID", "DimProduct", "ProductID"),
    ("Shipment", "PlantID", "DimPlant", "PlantID"),
    ("Shipment", "DestinationLocationID", "DimLocation", "LocationID"),
    ("FactSales", "CustomerID", "CustomerDetails", "CustomerID"),
    ("CustomerAddress", "CustomerID", "CustomerDetails", "CustomerID"),
]


# Relationships that must stay inactive to avoid an ambiguous filter path between two
# tables reachable more than one way (Fabric rejects the model outright otherwise).
# DimMaterial -> DimSupplier is "this material's reference supplier"; the fact-level
# FactSupplyChain -> DimSupplier edge is the actual transaction supplier and stays active.
# Same pattern for the Operational tables: PurchaseOrderItem reaches Supplier both via
# PurchaseOrder.SupplierID (the actual order's supplier) and via Material.SupplierID
# (the material's reference supplier) - the latter is deactivated for the same reason.
# Shipment also reaches DimProduct/DimPlant both directly and via ManufacturingBatch
# (which also has its own DimProduct/DimPlant edges); ManufacturingBatch's edges stay
# active because they're QualityInspection's only path to those dimensions, so
# Shipment's redundant direct edges are deactivated instead.
INACTIVE_RELATIONSHIPS: set[tuple[str, str, str, str]] = {
    ("DimMaterial", "SupplierID", "DimSupplier", "SupplierID"),
    ("Material", "SupplierID", "Supplier", "SupplierID"),
    ("Shipment", "ProductID", "DimProduct", "ProductID"),
    ("Shipment", "PlantID", "DimPlant", "PlantID"),
}


def token(env_name: str) -> str:
    access_token = os.environ.get(env_name)
    if not access_token:
        raise RuntimeError(f"{env_name} is missing. Run this script through .\\up.ps1.")
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


def first(items: list[dict], display_name: str, item_type: str) -> dict | None:
    """Find the expected Fabric item, never merely an arbitrary name match.

    Workspace item display names are not a reliable identifier: a notebook, report,
    or an item from a partially failed deployment can have the same display name as
    the semantic model we are looking for.  Returning an item only when both fields
    match prevents a report from being bound to the wrong artifact ID.
    """
    return next(
        (
            item for item in items
            if item.get("displayName") == display_name and item.get("type") == item_type
        ),
        None,
    )


def wait_for_item(fabric: Api, workspace_id: str, display_name: str, item_type: str) -> dict:
    """Wait for a created Fabric item to become visible as its expected type."""
    for _ in range(24):
        item = first(fabric.list_all(f"/workspaces/{workspace_id}/items"), display_name, item_type)
        if item and item.get("id"):
            return item
        time.sleep(5)
    raise TimeoutError(
        f"Fabric {item_type} {display_name!r} did not appear in workspace {workspace_id} after two minutes."
    )


def refresh_semantic_model(workspace_id: str, semantic_model_id: str) -> None:
    """Trigger a Direct Lake refresh (framing) and wait for it to complete.

    Direct Lake tables created or updated through the REST API (as opposed to the
    Fabric portal) are left in an unprocessed state until something explicitly
    refreshes the model - Microsoft's own Direct Lake documentation states this
    directly, and querying an unprocessed table returns an error. Without this
    step every fresh deployment's tables show as unprocessed (a warning icon in
    the portal's model view) and the Data Agent cannot answer any question.
    """
    session = requests.Session()
    session.headers.update({
        "Authorization": f"Bearer {token('AZURE_POWERBI_ACCESS_TOKEN')}",
        "Content-Type": "application/json",
    })
    base = f"https://api.powerbi.com/v1.0/myorg/groups/{workspace_id}/datasets/{semantic_model_id}"
    response = session.post(f"{base}/refreshes", json={"type": "full"}, timeout=60)
    if not response.ok:
        raise RuntimeError(f"POST {base}/refreshes -> {response.status_code}: {response.text}")
    for _ in range(24):
        time.sleep(5)
        response = session.get(f"{base}/refreshes", timeout=60)
        response.raise_for_status()
        refreshes = response.json().get("value", [])
        latest = refreshes[0] if refreshes else None
        if latest and latest.get("status") == "Completed":
            return
        if latest and latest.get("status") == "Failed":
            raise RuntimeError(f"Semantic model refresh failed: {json.dumps(latest, indent=2)}")
    raise TimeoutError(f"Semantic model {semantic_model_id} refresh did not complete in two minutes.")


def encode(text: str) -> str:
    return base64.b64encode(text.encode("utf-8")).decode("utf-8")


def lineage_id(*parts: str) -> str:
    return str(uuid.uuid5(LINEAGE_NAMESPACE, "/".join(parts)))


def build_model_bim(workspace_id: str, lakehouse_id: str) -> dict:
    tables = []
    for name, columns in LAKEHOUSE_TABLES.items():
        tables.append({
            "name": name,
            "lineageTag": lineage_id("table", name),
            "columns": [
                {
                    "name": column,
                    "dataType": data_type,
                    "sourceColumn": column,
                    "lineageTag": lineage_id("table", name, "column", column),
                }
                for column, data_type in columns
            ],
            "partitions": [{
                "name": name,
                "mode": "directLake",
                "source": {"type": "entity", "entityName": name.lower(), "schemaName": "dbo", "expressionSource": "LakehouseQuery"},
            }],
        })
    relationships = [
        {
            "name": lineage_id("relationship", from_table, from_column, to_table, to_column),
            "fromTable": from_table, "fromColumn": from_column,
            "toTable": to_table, "toColumn": to_column,
            **({"isActive": False} if (from_table, from_column, to_table, to_column) in INACTIVE_RELATIONSHIPS else {}),
        }
        for from_table, from_column, to_table, to_column in RELATIONSHIPS
    ]

    return {
        "name": "model",
        "compatibilityLevel": 1604,
        "model": {
            "culture": "en-US",
            "defaultPowerBIDataSourceVersion": "powerBI_V3",
            "sourceQueryCulture": "en-US",
            "dataAccessOptions": {"legacyRedirects": True, "returnErrorValuesAsNull": True},
            "expressions": [
                {
                    # Direct Lake on OneLake binds all governed tables, including the
                    # BusinessApplication replica.  The authoritative customer records
                    # remain in Fabric SQL as well, loaded by the Logic App.
                    "name": "LakehouseQuery",
                    "kind": "m",
                    "lineageTag": lineage_id("expression", "LakehouseQuery"),
                    "expression": [
                        "let",
                        f"    Source = AzureStorage.DataLake(\"https://onelake.dfs.fabric.microsoft.com/{workspace_id}/{lakehouse_id}\", [HierarchicalNavigation=true])",
                        "in",
                        "    Source",
                    ],
                    "annotations": [{"name": "PBI_IncludeFutureArtifacts", "value": "False"}],
                },
            ],
            "tables": tables,
            "relationships": relationships,
            "annotations": [{"name": "PBI_QueryOrder", "value": json.dumps(list(LAKEHOUSE_TABLES))}],
        },
    }


def platform_part(display_name: str, item_type: str) -> str:
    return encode(json.dumps({
        "$schema": "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
        "metadata": {"type": item_type, "displayName": display_name},
        "config": {"version": "2.0", "logicalId": "00000000-0000-0000-0000-000000000000"},
    }))


def deploy_semantic_model(fabric: Api, workspace_id: str, display_name: str,
                            lakehouse_id: str) -> str:
    model_bim = build_model_bim(workspace_id, lakehouse_id)
    definition = {
        "parts": [
            {"path": "model.bim", "payload": encode(json.dumps(model_bim)), "payloadType": "InlineBase64"},
            {"path": "definition.pbism", "payload": encode(json.dumps({"version": "4.0"})), "payloadType": "InlineBase64"},
            {"path": ".platform", "payload": platform_part(display_name, "SemanticModel"), "payloadType": "InlineBase64"},
        ],
    }

    items = fabric.list_all(f"/workspaces/{workspace_id}/items")
    existing = first(items, display_name, "SemanticModel")
    if existing is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/semanticModels", {
            "displayName": display_name,
            "definition": definition,
        })
        existing = wait_for_item(fabric, workspace_id, display_name, "SemanticModel")
    else:
        fabric.request("POST", f"/workspaces/{workspace_id}/items/{existing['id']}/updateDefinition", {
            "definition": definition,
        })
    return existing["id"]


def _visual_field(table: str, column: str, aggregation: int | None = None) -> tuple[dict, str, str]:
    """Return a semantic-query expression plus the stable Power BI query reference."""
    column_expression = {
        "Column": {
            "Expression": {"SourceRef": {"Source": table}},
            "Property": column,
        }
    }
    if aggregation is None:
        return column_expression, f"{table}.{column}", column
    aggregation_expression = {
        "Aggregation": {"Expression": column_expression, "Function": aggregation}
    }
    aggregation_names = {0: "Sum", 1: "Average", 2: "Count", 5: "DistinctCount"}
    return aggregation_expression, f"{aggregation_names[aggregation]}({table}.{column})", f"{aggregation_names[aggregation]} of {column}"


def _report_visual(
    name: str,
    visual_type: str,
    x: int,
    y: int,
    width: int,
    height: int,
    projections: dict[str, list[tuple[str, str, int | None]]],
    title: str,
    tab_order: int,
) -> dict:
    """Build one legacy report.json visual container for Fabric's report API.

    Fabric still accepts this report.json format for REST-created reports.  Keeping
    it lets this project update an existing report in place while supplying real
    visual definitions rather than an empty report canvas.
    """
    query_select: list[dict] = []
    config_projections: dict[str, list[dict]] = {}
    transform_ordering: dict[str, list[int]] = {}
    transform_active: dict[str, list[dict]] = {}
    source_tables: list[str] = []

    for role, fields in projections.items():
        config_projections[role] = []
        transform_ordering[role] = []
        transform_active[role] = []
        for table, column, aggregation in fields:
            if table not in source_tables:
                source_tables.append(table)
            expression, query_ref, restatement = _visual_field(table, column, aggregation)
            projection_index = len(query_select)
            query_select.append({**expression, "Name": query_ref})
            config_projections[role].append({"queryRef": query_ref})
            transform_ordering[role].append(projection_index)
            transform_active[role].append({"queryRef": query_ref})

    visual_config = {
        "name": name,
        "layouts": [{
            "id": 0,
            "position": {"x": x, "y": y, "z": tab_order, "width": width, "height": height, "tabOrder": tab_order},
        }],
        "singleVisual": {
            "visualType": visual_type,
            "projections": config_projections,
            "vcObjects": {"title": [{"properties": {"text": {"expr": {"Literal": {"Value": json.dumps(f"'{title}'")}}}}}]},
        },
    }
    query = {
        "Commands": [{"SemanticQueryDataShapeCommand": {
            "Query": {
                "Version": 2,
                "From": [{"Name": table, "Entity": table, "Type": 0} for table in source_tables],
                "Select": query_select,
            },
            "Binding": {
                "DataReduction": {"DataVolume": 3, "Primary": {"Window": {"Count": 500}}},
                "Primary": {"Groupings": [{"Projections": list(range(len(query_select)))}]},
                "Version": 1,
            },
            "ExecutionMetricsKind": 1,
        }}],
    }
    query_metadata = []
    for role_fields in projections.values():
        for table, column, aggregation in role_fields:
            _, query_ref, restatement = _visual_field(table, column, aggregation)
            query_metadata.append({"Name": query_ref, "Restatement": restatement})
    data_transforms = {
        "objects": {},
        "projectionOrdering": transform_ordering,
        "projectionActive": transform_active,
        "queryMetadata": {"Select": query_metadata},
    }
    return {
        "x": x,
        "y": y,
        "z": tab_order,
        "width": width,
        "height": height,
        "config": json.dumps(visual_config),
        "query": json.dumps(query),
        "dataTransforms": json.dumps(data_transforms),
        "filters": "[]",
    }


def build_report_json() -> dict:
    """Create the Caldova executive overview using the unified Direct Lake model."""
    report_namespace = uuid.UUID("524eb324-ee4a-5a71-a01e-63e287510219")

    def visual(
        key: str, visual_type: str, x: int, y: int, width: int, height: int,
        projections: dict[str, list[tuple[str, str, int | None]]], title: str, tab_order: int,
    ) -> dict:
        return _report_visual(
            uuid.uuid5(report_namespace, key).hex,
            visual_type, x, y, width, height, projections, title, tab_order,
        )

    visuals = [
        visual("total-revenue", "card", 20, 20, 285, 100,
               {"Values": [("FactSales", "TotalRevenue", 0)]}, "Total Revenue", 0),
        visual("units-sold", "card", 325, 20, 285, 100,
               {"Values": [("FactSales", "UnitsSold", 0)]}, "Units Sold", 1),
        visual("inventory-on-hand", "card", 630, 20, 285, 100,
               {"Values": [("Inventory", "QuantityOnHand", 0)]}, "Quantity on Hand", 2),
        visual("supplier-quality", "card", 935, 20, 325, 100,
               {"Values": [("DimSupplier", "QualityRating", 1)]}, "Average Supplier Quality", 3),
        visual("revenue-trend", "lineChart", 20, 145, 600, 265,
               {"Category": [("DimDate", "FullDate", None)], "Y": [("FactSales", "TotalRevenue", 0)]},
               "Revenue Trend", 4),
        visual("revenue-by-product", "clusteredBarChart", 640, 145, 620, 265,
               {"Category": [("DimProduct", "ProductName", None)], "Y": [("FactSales", "TotalRevenue", 0)]},
               "Revenue by Product", 5),
        visual("inventory-by-plant", "clusteredColumnChart", 20, 435, 600, 265,
               {"Category": [("DimPlant", "PlantName", None)], "Y": [("Inventory", "QuantityOnHand", 0)]},
               "Inventory by Plant", 6),
        visual("supplier-quality-table", "tableEx", 640, 435, 620, 265,
               {"Values": [("DimSupplier", "SupplierName", None), ("DimSupplier", "QualityRating", 1)]},
               "Supplier Quality", 7),
    ]
    return {
        "config": json.dumps({"version": "5.43", "themeCollection": {}}),
        "layoutOptimization": 0,
        "sections": [{
            "name": "ReportSection1",
            "displayName": "Overview",
            "filters": "[]",
            "ordinal": 0,
            "visualContainers": visuals,
            "width": 1280,
            "height": 720,
        }],
        "resourcePackages": [],
    }


def deploy_report(fabric: Api, workspace_id: str, display_name: str, semantic_model_id: str) -> str:
    """Create or update the business-ready report bound to the semantic model."""
    # Fabric REST API uses the v2 report-definition schema.  Its documented
    # byConnection form needs only semanticmodelid=<item GUID>.  The prior v1
    # shape was incomplete (it omitted pbiModelVirtualServerName and name), which
    # caused Fabric to reject definition.pbir before it could create the report.
    pbir = {
        "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
        "version": "4.0",
        "datasetReference": {
            "byConnection": {
                "connectionString": f"semanticmodelid={semantic_model_id}",
            }
        },
    }
    report_json = build_report_json()
    definition = {
        "parts": [
            {"path": "definition.pbir", "payload": encode(json.dumps(pbir)), "payloadType": "InlineBase64"},
            {"path": "report.json", "payload": encode(json.dumps(report_json)), "payloadType": "InlineBase64"},
            {"path": ".platform", "payload": platform_part(display_name, "Report"), "payloadType": "InlineBase64"},
        ],
    }

    items = fabric.list_all(f"/workspaces/{workspace_id}/items")
    existing = first(items, display_name, "Report")
    if existing is None:
        fabric.request("POST", f"/workspaces/{workspace_id}/reports", {
            "displayName": display_name,
            "definition": definition,
        })
        existing = wait_for_item(fabric, workspace_id, display_name, "Report")
    else:
        fabric.request("POST", f"/workspaces/{workspace_id}/items/{existing['id']}/updateDefinition", {
            "definition": definition,
        })
    return existing["id"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--lakehouse-id", required=True)
    parser.add_argument("--semantic-model-name", default="Caldova_Unified_SemanticModel")
    parser.add_argument("--report-name", default="Caldova_Unified_Report")
    args = parser.parse_args()

    fabric = Api(token("AZURE_FABRIC_ACCESS_TOKEN"))

    semantic_model_id = deploy_semantic_model(
        fabric, args.workspace_id, args.semantic_model_name,
        args.lakehouse_id,
    )
    refresh_semantic_model(args.workspace_id, semantic_model_id)
    report_id = deploy_report(fabric, args.workspace_id, args.report_name, semantic_model_id)

    print(json.dumps({"semanticModelId": semantic_model_id, "reportId": report_id}, indent=2))


if __name__ == "__main__":
    main()
