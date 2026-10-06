# Caldova unified estate: resource and data map

## Azure foundation

| Order | Resource | Proposed name | Region | Purpose |
|---:|---|---|---|---|
| 1 | Resource group | `rg-Unified` | West US 2 | Single lifecycle boundary for all Azure resources. |
| 2 | Storage account | `stcaldova<unique-suffix>` | West US 3 | Landing zone for the three local source domains. |
| 3 | Blob container | `data` | Inherits storage account | Holds source data without modification. |
| 4 | Azure SQL logical server | `sql-operational-<unique-suffix>` | West US 2 | Hosts the operational source database. |
| 5 | Azure SQL database | `OperationalData` | West US 2 | Holds the eight operational tables before Fabric mirroring. |
| 6 | Fabric capacity | `fabriccapacity<unique-suffix>` | West US 2 | F16 capacity, per approved requirement. |
| 7 | Fabric license | `FABRIC_FREE` by default | Tenant level | Checked and assigned to the capacity administrator before workspace creation. |
| 8 | Fabric workspace | `Caldova-unify` | Assigned to West US 2 capacity | Governs Fabric items and access. |
| 8 | Fabric Lakehouse | `Caldova_Lakehouse` | Workspace capacity | Delta storage for the unified analytical estate. |
| 9 | Fabric SQL database | `Caldova_SQLDatabase` | Workspace capacity | Customer-master target if the Logic App pattern is retained. |
| 10 | Semantic model | `Caldova_Unified_SemanticModel` | Workspace capacity | Governed reporting layer. |
| 11 | Data Agent | `Caldova_Unified_DataAgent` | Workspace capacity | Natural-language interface to the semantic model. |

## Storage landing layout

```text
data/
  Analytical/                 <- 13 CSV files from ./Analytical
  BusinessApplication/        <- CustomerDetails.json, CustomerAddress.json
  Operational/                <- 8 CSV files from ./Operational
```

## Domain mapping

| Local source | Landing zone | Initial target | Fabric consumption |
|---|---|---|---|
| `Analytical/*.csv` | `data/Analytical/` | Lakehouse `dbo` Delta tables | Direct Lake |
| `BusinessApplication/*.json` | `data/BusinessApplication/` | Fabric SQL Database customer tables | Direct Lake |
| `Operational/*.csv` | `data/Operational/` | Azure SQL `OperationalData.dbo` tables | Fabric Mirroring, then Lakehouse shortcut |

## Verified data inventory

| Domain | Tables/files | Rows |
|---|---|---:|
| Analytical | 13 CSV files | 978 |
| Business Application | 2 JSON files | 50 |
| Operational | 8 CSV files | 328 |

All operational referential checks pass, including joins to the supplied analytical product, plant, and location dimensions.

## Provisioning prerequisite

The Azure identity used for deployment must have **Contributor** (or equivalent resource-create permission) at the target subscription or `rg-Unified` scope. It also needs capacity-creation permission for `Microsoft.Fabric/capacities` and a Fabric tenant/capacity entitlement for F16.
