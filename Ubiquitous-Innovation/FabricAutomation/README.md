# Fabric workspace, Lakehouse, and local data ingestion

Create `.env` from `.env.example`, replace the placeholders, then run:

```powershell
.\up.ps1
```

The script uses the configured service principal for non-interactive Azure CLI sign-in. If Azure CLI is already signed in as that exact application in the configured tenant, it reuses the existing session; otherwise it signs in silently.

The `Fabric Data` folder beside `up.ps1` is read locally. Each CSV is written once as a Delta table in the new Lakehouse `Tables` area; the CSV files are not uploaded to `Files`. Table names use the CSV filenames (for example, `Inventory.csv` becomes `Inventory`).

The `BlobData` folder beside `up.ps1` is uploaded recursively to the `data` container in a new ADLS Gen2 storage account. Both source paths are resolved from the project directory, so the project can be copied to a VM without hardcoded user paths.

The workflow is creation-only and stops if `rg-Ubiquitous` already exists. It creates only:

1. `rg-Ubiquitous`
2. One F16 Fabric capacity with a random five-character alphanumeric suffix
3. One paired `Ubiquitous-Innovation-<suffix>` Fabric workspace
4. One schema-enabled Lakehouse
5. One ADLS Gen2 storage account named `adlsubiquitous<suffix>` and its `data` container

The service principal creates the workspace and Lakehouse. `FABRIC_CAPACITY_ADMIN_UPN` is added as a capacity administrator and workspace `Admin`, so that user can see and open the new workspace normally in the Fabric portal.

Prerequisites: Azure CLI, Python, Azure RBAC that permits the service principal to create the resource group, Fabric capacity, storage account, and storage role assignment (for example, Owner or Contributor plus User Access Administrator). The Fabric tenant must permit service principals to use Fabric APIs. Microsoft Graph **Application** permission `User.Read.All` with tenant admin consent is required only to resolve `FABRIC_CAPACITY_ADMIN_UPN` before adding that user to the new workspace; the project does not check or assign licenses. The pipeline grants the service principal `Storage Blob Data Contributor` only on its newly created storage account so it can upload the `BlobData` files.
