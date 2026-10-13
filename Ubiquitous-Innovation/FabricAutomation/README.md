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

The service principal is the capacity administrator and creates the workspace and Lakehouse.

Prerequisites: Azure CLI, Python, Azure RBAC that permits the service principal to create the resource group and Fabric capacity, and a Fabric tenant setting that permits service principals to use Fabric APIs.
