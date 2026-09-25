# Caldova Azure fallback deployment

This package creates the resources shown in the supplied image:

- `app-caldova-ordermgmt` — App Service
- `plan-caldova-ordermgmt` — App Service plan
- `sql-caldova-2401974` and `CaldovaOrderManagement` — Azure SQL logical server and Hyperscale database
- `openai-caldova` — Azure OpenAI account with `gpt-5-mini` and `text-embedding-ada-002` deployments

## Regional fallback behavior

`deploy.ps1` tries, in order: **West US 2**, **West US**, **East US**, then **East US 2**. It creates `rg-fallback-caldova-mwc` in the first successful location.

The resource group's location cannot be changed after creation. Each remaining dependency group then applies the same ordered fallback independently. Azure requires these resources to be in the same region as their parent/dependency, so they move together:

- App Service plan + web app
- SQL logical server + database
- Azure OpenAI account + both model deployments

This means a resource group can remain in West US 2 while, for example, Azure OpenAI is placed in East US after capacity or model availability failures.

Before deploying the three dependency groups, the script verifies that their named resources do not already exist in the resource group. If a regional attempt partially creates a new pair and fails, it removes only those newly-created resources before moving to the next candidate region.

## Prerequisites

1. Azure CLI installed and authenticated: `az login`
2. Permission to create resource groups and the listed resource providers.
3. An Azure OpenAI quota/model offer for `gpt-5-mini` and `text-embedding-ada-002` in a candidate region.

## Deploy

The recommended option is a single command from this folder:

```powershell
azd up
```

`azd up` prompts for Azure authentication, environment, and subscription as necessary. Its provisioning hook invokes `az login` only if Azure CLI has no current session, then prompts securely for the SQL administrator password and deploys the full fallback workflow. No separate `az login`, `azd provision`, or script command is required.

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
