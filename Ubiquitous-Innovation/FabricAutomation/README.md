# Fabric, Lakehouse, storage, and Foundry provisioning

Create `.env` from `.env.example`, replace the placeholders, then run:

```powershell
.\up.ps1
```

The script uses the configured service principal for non-interactive Azure CLI sign-in. If Azure CLI is already signed in as that exact application in the configured tenant, it reuses the existing session; otherwise it signs in silently.

The `Fabric Data` folder beside `up.ps1` is read locally. Each CSV is written once as a Delta table in the new Lakehouse `Tables` area; the CSV files are not uploaded to `Files`. Table names use the CSV filenames (for example, `Inventory.csv` becomes `Inventory`). The pipeline also derives `dbo.DimPlant` from the latest observation for each `PlantID`, so the semantic model can use `Plant` as a unique dimension.

The `BlobData` folder beside `up.ps1` is uploaded recursively to the `data` container in a new ADLS Gen2 storage account. Both source paths are resolved from the project directory, so the project can be copied to a VM without hardcoded user paths.

The workflow is creation-only and stops if `rg-Ubiquitous` already exists. It creates only:

1. `rg-Ubiquitous`
2. One F16 Fabric capacity with a random five-character alphanumeric suffix
3. One paired `Ubiquitous-Innovation-<suffix>` Fabric workspace
4. One schema-enabled Lakehouse
5. One ADLS Gen2 storage account named `adlsubiquitous<suffix>` and its `data` container
6. One Direct Lake semantic model: `Ubiquitous_Innovation_SemanticModel`
7. One published Data Agent: `Ubiquitous_Innovation_DataAgent`
8. One Azure AI Foundry account and project in West US
9. One low-capacity `gpt-5-mini` (`2025-08-07`) Global Standard deployment: `gpt5mini`
10. One Foundry prompt agent: `supply-chain-bi-agent`, with the instruction `You are my Supply chain agent.` Its endpoint enables the Responses and Activity protocols with Entra and Bot Service RBAC authorization schemes.

The service principal creates the workspace and Lakehouse. `FABRIC_CAPACITY_ADMIN_UPN` is added as a capacity administrator and workspace `Admin`, so that user can see and open the new workspace normally in the Fabric portal.

The semantic model contains the six Lakehouse `dbo` tables and their Product/Plant relationships. It is refreshed after creation so the published Data Agent can query it. No report is created.

Prerequisites: Azure CLI, Python, Azure RBAC that permits the service principal to create the resource group, Fabric capacity, storage account, Foundry account/project/model deployment, and role assignments (for example, Owner or Contributor plus User Access Administrator). The subscription must have quota for `gpt-5-mini` Global Standard in West US. The Fabric tenant must permit service principals to use Fabric APIs. For the Direct Lake refresh, allow the application to call Power BI APIs and grant the Power BI Service **Application** permission `Dataset.ReadWrite.All` with tenant admin consent. Microsoft Graph **Application** permission `User.Read.All` with tenant admin consent is required only to resolve `FABRIC_CAPACITY_ADMIN_UPN` before adding that user to the new workspace; the project does not check or assign licenses. The pipeline grants `Storage Blob Data Contributor` only to the service principal on its newly created storage account, and grants `Foundry User` only on the new Foundry project to both the service principal and `FABRIC_CAPACITY_ADMIN_UPN`.
