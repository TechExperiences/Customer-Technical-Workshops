# Fabric workspace, Lakehouse, and local data ingestion

Create `.env` from `.env.example`, replace the placeholders, then run:

```powershell
.\up.ps1
```

The script uses the configured service principal for non-interactive Azure CLI sign-in. If Azure CLI is already signed in as that exact application in the configured tenant, it reuses the existing session; otherwise it signs in silently.

The only local input is `Fabric Data` beside `up.ps1`. Every file is uploaded recursively once to the `Files/` area of the new Lakehouse, retaining subfolders. The source path is resolved from the project directory, so it works when the project is copied to a VM.

The workflow is creation-only and stops if `rg-Ubiquitous` already exists. It creates only:

1. `rg-Ubiquitous`
2. One F16 Fabric capacity with a random five-character alphanumeric suffix
3. One paired `Ubiquitous-Innovation-<suffix>` Fabric workspace
4. One schema-enabled Lakehouse

The service principal creates the workspace and Lakehouse. `FABRIC_CAPACITY_ADMIN_UPN` is added as a capacity administrator and workspace `Admin`, so that user can see and open the new workspace normally in the Fabric portal.

Prerequisites: Azure CLI, Python, Azure RBAC that permits the service principal to create the resource group and Fabric capacity, a Fabric tenant setting that permits service principals to use Fabric APIs, and Microsoft Graph **Application** permission `User.Read.All` with tenant admin consent. The permission is used only to resolve `FABRIC_CAPACITY_ADMIN_UPN` to its Entra object ID before adding that user to the new workspace; the project does not check or assign licenses.
