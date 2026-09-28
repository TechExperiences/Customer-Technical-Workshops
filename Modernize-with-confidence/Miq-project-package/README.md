# Caldova Azure fallback deployment

This package provisions the Caldova modernization demo and runs the full local-CSV migration pipeline through `azd up`.

## What `azd up` does

1. Creates `rg-caldova`, the App Service plan/web app, Azure SQL Hyperscale database, Azure OpenAI account, and its chat/embedding model deployments.
2. Sets the supplied Microsoft Entra administrator on Azure SQL.
3. Creates a temporary firewall rule for the current deployment client, then imports the 11 simulated on-prem CSV exports from `data/`.
4. Verifies the relational schema and source-table counts.
5. Waits until the `text-embedding-ada-002` data-plane endpoint accepts an embedding request, then runs `infra/sql/Embedding_Script.sql`, which creates `dbo.ProductDescriptionEmbeddings` and generates native `VECTOR(1536)` embeddings.
6. Verifies generated embeddings, grants the web app identity Azure OpenAI access when permitted, then removes the temporary SQL firewall rule.

`data/ProductDescriptionEmbeddings.csv` is deliberately excluded from initial import. The 12th table is generated from the imported product, category, and description data so the demo clearly shows the AI modernization phase.

The local CSVs are a **simulated on-premises export**. The package does not connect to an on-premises VM and does not store any source-system credentials.

## Resources

- `app-caldova-ordermgmt-<deployment-suffix>` — App Service
- `plan-caldova-ordermgmt` — App Service plan
- `sql-caldova-<deployment-suffix>` and `CaldovaOrderManagement` — Azure SQL logical server and Hyperscale database
- `openai-caldova-<deployment-suffix>` — Azure OpenAI account with `gpt-5-mini` and `text-embedding-ada-002` deployments in West US

## Regional fallback behavior

`deploy.ps1` creates `rg-caldova` and deploys SQL using this fallback order: **West US 2**, **West US**, **East US**, then **East US 2**. The App Service plan and web app use **West US 2** first, **West Central US** second, then follow the remaining fallback order. Azure OpenAI and both model deployments are intentionally deployed in **West US only**.

The resource group's location cannot be changed after creation. Each remaining dependency group then applies its configured location policy independently. Azure requires resources in each group to be in the same region as their parent/dependency, so they move together:

- App Service plan + web app
- SQL logical server + database
- Azure OpenAI account + both model deployments

This means a resource group can remain in West US 2 while SQL or App Service independently use another supported fallback region. Azure OpenAI has no fallback by design; a West US OpenAI failure stops the deployment rather than placing models in another region.

If a regional attempt partially creates a new dependency pair and fails, the script removes those generated resources before moving to the next candidate region.

At first deployment, the script generates one random eight-character suffix for globally named resources and saves it in the ignored `.deployment-state.json` file. Retrying the deployment reuses the same names. Delete this state file only when intentionally starting a new set of globally named resources.

## Prerequisites

1. Azure CLI, Azure Developer CLI, and PowerShell 7.
2. The azd identity must be the Microsoft Entra SQL administrator configured in `.env`, or otherwise be authorized to connect as an Azure SQL Entra administrator.
3. Permission to create resource groups/resources, list Azure OpenAI keys, and create role assignments if app OpenAI RBAC is required.
4. An Azure OpenAI quota/model offer for `gpt-5-mini` and `text-embedding-ada-002` in West US.

Azure OpenAI model deployments are created serially because the Azure OpenAI control plane permits only one deployment operation at a time per account. If Azure reports a transient in-progress operation, the deployment retries West US for up to six minutes before failing.
5. A local `.env` copied from `.env.example`; it must contain the subscription ID, SQL admin password, and Entra SQL administrator values. Do not commit it.

## Deploy

Create your local `.env` file from `.env.example`, set the required values, then run from the package root:

```powershell
.\up.ps1
```

`up.ps1` loads the root `.env`, creates or selects the local azd environment named by `AZURE_ENV_NAME`, saves the subscription ID into that environment, and starts `azd up --no-prompt`. This removes the one-time manual `azd env new` and `azd env set` setup. The azd hooks then load the same `.env`, run all three migration phases, and do not prompt for the SQL password. `.env` and `.azure` are ignored by Git.

Azure still requires an authenticated identity. With a personal account, the first `az login` is interactive by design. Use a service principal or managed identity if the login must also be fully unattended.

For a fully unattended sign-in, set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_CLIENT_SECRET` in the local `.env`. `up.ps1` uses them for both azd and Azure CLI sign-in. Keep this local `.env` protected; it is ignored by Git.

For direct Azure CLI execution instead, the script remains available and prompts securely for the SQL administrator password if it is not supplied:

```powershell
.\deploy.ps1 -SubscriptionId '<your-subscription-id>'
```

The `gpt-5-mini` model version defaults to `2025-08-07`; change `-ChatModelVersion` if your subscription offers another version. The configured application API-version values are intentionally application settings, not Azure deployment-model versions:

```text
AZURE_OPENAI_CHAT_DEPLOYMENT=gpt-5-mini
AZURE_OPENAI_EMBEDDING_DEPLOYMENT=text-embedding-ada-002
AZURE_OPENAI_CHAT_API_VERSION=2024-08-01-preview
AZURE_OPENAI_EMBEDDING_API_VERSION=2023-05-15
```

## Security note

The starter configuration enables public network access for SQL and Azure OpenAI so the migration can run from the deployment client. The pipeline automatically removes its temporary SQL firewall rule afterward. Use Private Link/VNet integration for production app-to-SQL connectivity. The script does not commit the SQL password or Azure OpenAI key.
