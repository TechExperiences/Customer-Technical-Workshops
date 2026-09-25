# Caldova Azure fallback deployment

This package creates the resources shown in the supplied image:

- `app-caldova-ordermgmt-<deployment-suffix>` — App Service
- `plan-caldova-ordermgmt` — App Service plan
- `sql-caldova-<deployment-suffix>` and `CaldovaOrderManagement` — Azure SQL logical server and Hyperscale database
- `openai-caldova-<deployment-suffix>` — Azure OpenAI account with `gpt-5-mini` and `text-embedding-ada-002` deployments

## Regional fallback behavior

`deploy.ps1` creates `rg-caldova` and deploys SQL/Azure OpenAI using this fallback order: **West US 2**, **West US**, **East US**, then **East US 2**. The App Service plan and web app use **West US 2** first, **West Central US** second, then follow the remaining fallback order.

The resource group's location cannot be changed after creation. Each remaining dependency group then applies the same ordered fallback independently. Azure requires these resources to be in the same region as their parent/dependency, so they move together:

- App Service plan + web app
- SQL logical server + database
- Azure OpenAI account + both model deployments

This means a resource group can remain in West US 2 while, for example, Azure OpenAI is placed in East US after capacity or model availability failures.

If a regional attempt partially creates a new dependency pair and fails, the script removes those generated resources before moving to the next candidate region.

At first deployment, the script generates one random eight-character suffix for globally named resources and saves it in the ignored `.deployment-state.json` file. Retrying the deployment reuses the same names. Delete this state file only when intentionally starting a new set of globally named resources.

## Prerequisites

1. Azure CLI installed and authenticated: `az login`
2. Permission to create resource groups and the listed resource providers.
3. An Azure OpenAI quota/model offer for `gpt-5-mini` and `text-embedding-ada-002` in a candidate region.

## Deploy

Create your local `.env` file from `.env.example`, set at least `AZURE_SUBSCRIPTION_ID` and `SQL_ADMINISTRATOR_PASSWORD`, then run this single command from the package root:

```powershell
.\up.ps1
```

`up.ps1` loads the root `.env` into the current process before starting `azd up --no-prompt`. This is necessary because azd validates the subscription before project hooks run. The azd hook loads the same `.env` and supplies the SQL password without prompting. `.env` and `.azure` are ignored by Git.

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

The starter configuration enables public network access for SQL and Azure OpenAI so the infrastructure can be reached during initial setup. Restrict both with private endpoints/firewall rules before production use. The script does not store the SQL password in a file.
