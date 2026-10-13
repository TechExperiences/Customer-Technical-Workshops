# Fabric workspace and Lakehouse creation

Create `.env` from `.env.example`, replace the placeholders with your Azure subscription ID, tenant ID, and capacity-administrator UPN, then run from PowerShell:

```powershell
.\up.ps1
```

If Azure CLI has no active session, the script starts `az login` automatically.

The script imports `.env`, saves non-secret configuration into the named Azure Developer CLI environment (`AZURE_ENV_NAME`), then uses those loaded values for the deployment. Azure authentication is performed through Azure CLI/Azure Developer CLI sign-in.

Before resource creation, the script checks `FABRIC_CAPACITY_ADMIN_UPN` for an assigned Fabric/Power BI license. It uses an existing non-free entitlement when available, otherwise an existing free entitlement. If neither exists, it attempts to assign only a free tenant-exposed SKU. It never assigns a paid SKU, buys a license, or creates a trial.

The only source data folder is `Fabric Data` beside `up.ps1`. Its files are copied once to the new Lakehouse's `Files/` area, retaining subfolders. The path is resolved from the script location, so the project can be moved to a VM; it is not configurable through `.env` or command-line parameters.

After Lakehouse creation, OneLake can take time to expose its `Files` path. The ingestion step retries `PathNotFound` responses for up to three minutes; all local files are discovered recursively, so no file list is required.

The script is deliberately creation-only. It stops if `rg-Ubiquitous` already exists and never searches for, reuses, updates, reassigns, or deletes Fabric workspaces, Lakehouses, or capacities.

Each run generates a random five-character alphanumeric suffix. For example, the capacity can be `fabricubiquitousx4p7k` and the paired workspace `Ubiquitous-Innovation-x4p7k`.

Only these resources are created:

1. `rg-Ubiquitous`
2. One F16 Fabric capacity
3. One Fabric workspace assigned to that capacity at creation
4. One schema-enabled Lakehouse

`FABRIC_CAPACITY_ADMIN_UPN` is added to the new capacity as its capacity administrator and to the new workspace as Fabric `Admin`. Before adding the workspace role, the script checks its existing role assignments and skips the add when that user is already an Admin. It does not replace a different existing workspace role.

## Optional direct SharePoint upload with a service principal

When `ENABLE_SHAREPOINT_GRAPH_UPLOAD=true`, the pipeline uploads every file under `Sharepoint_doc` directly to the configured SharePoint library/folder through the existing service principal. It does not use OneDrive, VM managed identity, browser sign-in, a user password, or TAP.

The service principal requires Microsoft Graph **Application** permission `Sites.Selected`, admin consent, and explicit `write` access to the configured SharePoint site. Set `PROVISION_SHAREPOINT_SITE_WRITE=true` only if the signed-in Azure CLI user has SharePoint/Graph administrator authority; the pipeline then attempts the site-level write grant. Set the service principal client ID, tenant ID, secret, site URL, library, and destination folder in `.env`. The client secret is intentionally excluded from azd environment persistence, but it remains a sensitive local value and must never be committed.

Prerequisites: Azure CLI, Python, Azure permission to create a resource group and Fabric capacity, Fabric capacity/workspace creation permission, and a tenant configuration that permits the signed-in identity to use Fabric APIs. This project does not create or assign licenses, does not modify Entra permissions, and creates no other Azure or Fabric resources.
