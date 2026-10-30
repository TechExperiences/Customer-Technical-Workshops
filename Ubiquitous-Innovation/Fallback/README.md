# Fallback Foundry provisioning

`up.ps1` is a creation-only, service-principal pipeline. It creates no Fabric capacity, workspace, Lakehouse, semantic model, or Fabric Data Agent.

It creates a new `rg-Ubiquitous-Innovation` environment with:

1. ADLS Gen2 storage in West US 2, including one `data` container.
2. Azure AI Search and serverless Azure Cosmos DB for Foundry Standard Agent Setup in West US 2.
3. A Foundry hub/project in West US, `gpt-5.1` version `2025-11-13`, and one `Ubiquitous-Supply-Chain-BI-Agent`.
4. A document knowledge base sourced only from the ADLS `data` container.
5. A Foundry Remote Tool connection using Microsoft Entra user delegation and a Fabric MCP tool, both discovered automatically from the single published `Ubiquitous_Innovation_DataAgent` created by the prior FabricAutomation run in `rg-Ubiquitous`.

Run FabricAutomation first, then copy `.env.example` to `.env`, set the credentials, and run:

```powershell
.\up.ps1
```

No Fabric workspace, Data Agent ID, or MCP endpoint belongs in `.env`. The pipeline fails rather than selecting an arbitrary source if `rg-Ubiquitous` does not contain exactly one matching capacity, workspace, and Data Agent.

The VM needs Azure CLI (`az`), Azure Developer CLI (`azd`), and Python. The pipeline signs `az` and, when necessary, `azd` in with the configured service principal. The generated Foundry connection uses `user-entra-token` so a caller's own Entra context is forwarded to Fabric; the caller must have Fabric access and the required delegated Fabric Data Agent permission when invoking the agent.

`FABRIC_CAPACITY_ADMIN_UPN` receives `Foundry User` on the new Foundry project and the Cosmos DB Built-in Data Reader data-plane role on the new Cosmos account. This permits that user to inspect Foundry-managed thread and memory records in Cosmos Data Explorer but not change or delete them.

The pipeline checks that the Fallback resource group does not already exist and never reuses it.
