# Microsoft IQ Solution Accelerator

Now that you have completed AYI02, explore the existing **Caldova November launch** deployment using the Microsoft IQ Solution Accelerator walkthrough below. Reuse the resources, published Fabric Data Agent and four Foundry agents you already configured. Confirm actual resource names in **Caldova-v1/DEPLOYMENT.md** and **FOUNDRY-DEPLOYMENT.md**; your deployment may use different names.

> **Note:** The retained screenshots show the original accelerator. Follow the Caldova names and prompts in the text. Screenshot replacements are marked below.

1. Navigate to the Azure portal. Click on **Resource group**.

   ![](../Sandbox-Environment-Guides/Images/amp52.png)

1. Select **rg-caldova-fabric-iq**, or the resource group recorded in your deployment guide.

   ![](../Sandbox-Environment-Guides/Images/amp53.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Review the existing Caldova resources. This walkthrough does not redeploy them.

   ![](../Sandbox-Environment-Guides/Images/amp54.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.


# Post deployment Guide - Fabric IQ and Microsoft Foundry

## Fabric IQ

1. Click on the **App launcher (1)** and select **Microsoft fabric** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Close the **Welcome to the Fabric view** pop up.

   ![](../Sandbox-Environment-Guides/Images/a35.png)

1. In the left navigation, select **Workspaces (1)** and then select the created workspace **Caldova Fabric IQ - NextGen Launch (2)**

   ![](../Sandbox-Environment-Guides/Images/amp56.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Review the workspace's item list. Items may be listed directly or organized into folders:

   - **Data agent:** `Caldova_Launch_Readiness_Agent`, published in AYI02.
   - **Lakehouse:** `caldova_supply_lakehouse`, containing the nine business data domains.
   - **Ontology:** `Caldova_NovemberLaunch_Ontology`, showing the entities and relationships.
   - **Reports and notebooks:** Review these if they were created by your deployment.

   Open the Lakehouse to inspect the data, or the Data Agent to ask questions.

   ![](../Sandbox-Environment-Guides/Images/amp57.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. If a **Supply Chain Dashboard** report was deployed, open it and review the November launch capacity and readiness summary.

   > **&lt;TODO&gt;:** Confirm the Power BI report in the Caldova architecture has been deployed and replace this screenshot. If the report is absent, record it as a pending dashboard task; workspace visibility does not verify report deployment.

   ![](../Sandbox-Environment-Guides/Images/amp65.png)

1. Navigate back to the workspace and open **caldova_supply_lakehouse**.

   ![](../Sandbox-Environment-Guides/Images/amp67.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Inside, you'll find two areas.

   - **Tables:** Review the nine domains: plant capacity and commitments; batch schedules and changeovers; equipment and fill-finish availability; product and inventory; demand forecasts; supplier and CMO capacity; quality and CMO evaluations; launch and competitive products; and RFP status. Open a table and confirm its columns and rows are visible.
   - **Files:** Review any source files generated during deployment. Foundry reference PDFs are stored separately in Azure Blob Storage.

     ![](../Sandbox-Environment-Guides/Images/amp68.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. For a visual review, open **Caldova_NovemberLaunch_Ontology** from the workspace.

   ![](../Sandbox-Environment-Guides/Images/amp66.png)

   - Review the nine entity types and their relationships for the Caldova story. The ontology is retained for visual exploration; the tested Data Agent route uses the Lakehouse. **Manage graph** eligibility and materialization are not prerequisites for this walkthrough.

   > **&lt;TODO&gt;:** Replace this screenshot with the Caldova ontology view; this optional ontology review can be removed if the updated experience no longer supports the workshop.

1. Navigate back to the workspace and open the existing **Caldova_Launch_Readiness_Agent**.

   ![](../Sandbox-Environment-Guides/Images/amp69.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Confirm its data source is **caldova_supply_lakehouse** and the required tables are selected. Reuse the working Lakehouse connection from AYI02.

   > **&lt;TODO&gt;:** Replace this screenshot with the Lakehouse selected as the Data Agent source.

   ![](../Sandbox-Environment-Guides/Images/amp70.png)

1. Click **Agent Instructions (1)**. Review the instructions and understand how they guide the agent **(2)**.

   ![](../Sandbox-Environment-Guides/Images/agenti1.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Close the **Agent Instructions (1)** and open the **Test data Agent (2)**.

    ![](../Sandbox-Environment-Guides/Images/a21.png)

1. In the query input area, ask questions using natural language, for example:

   ```
   List the three Caldova plants and their required and committed production for the November launch. Show the planning period and units.
   ```

1. Submit the query and review the response generated by the Data Agent.

    ![](../Sandbox-Environment-Guides/Images/a17.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Observe how the agent:
   - Interprets the question
   - Queries the selected Lakehouse tables
   - Provides insights in a readable format

1. Try multiple queries and refine your questions to explore additional insights.

   ```
   What is the current inventory for the products in the Caldova November launch? Break it down by product and plant.
   ```

    ![](../Sandbox-Environment-Guides/Images/a19.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ```
   Calculate Caldova's November production shortfall across the three plants. Show required production, committed production, the gap in units and the gap as a percentage of required production. Verify whether the data supports the stated 7% gap.
   ```

   ```
   Which plants have insufficient committed production for the November launch? Show the plant-level figures in a table.
   ```

   ```
   Which equipment, fill-finish or changeover constraints limit internal production recovery for the November launch?
   ```

   ```
   Which qualified external CMOs have available capacity for the November launch? Include quality evaluation and RFP status, and identify any missing records.
   ```

    ![](../Sandbox-Environment-Guides/Images/a37.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ```
   Based on the recorded plant commitments, demand forecasts and supplier capacity, which recovery options could reduce the November shortfall? Distinguish available capacity from confirmed commitments.
   ```

    ![](../Sandbox-Environment-Guides/Images/a36.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

     > **Note:**
     > - Clear and specific questions provide more accurate results.
     > - Responses may vary depending on how the question is framed.
     > - Use the Lakehouse records as the source of operational figures; show units, planning period and calculations, and do not assume the expected gap is already proven.

1. If you changed the Data Agent, select **Publish**. If the unchanged agent is already published from AYI02, continue to Microsoft Foundry.
   ![](../Sandbox-Environment-Guides/Images/a38.png)

1. Confirm **Publish** to make your changes available to connected agents.

   ![](../Sandbox-Environment-Guides/Images/a16.png)


## Microsoft Foundry

1. Navigate back to the Azure portal.

1. Select the existing **caldova-nextgen-launch** Foundry project, or the project recorded in **FOUNDRY-DEPLOYMENT.md**.

   ![](../Sandbox-Environment-Guides/Images/amp58.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Click on **Go to Foundry portal**.

   ![](../Sandbox-Environment-Guides/Images/amp59.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Click on **Build (1)**, then **Agents (2)**. Confirm the four agents are listed: **supplier-terms-agent**, **cmo-evaluation-agent**, **demand-sensing-agent** and **manufacturing-quality-agent**.

   ![](../Sandbox-Environment-Guides/Images/amp60.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Navigate to **Tools (1)** and review the existing **caldova-kb-mcp** connection used for document and approved public-source retrieval.

   ![](../Sandbox-Environment-Guides/Images/amp61.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Navigate to **Models / Deployments (1)**, you can see **gpt-5-mini** (chat) and **text-embedding-3-small** (embeddings) **(2)**.

   ![](../Sandbox-Environment-Guides/Images/amp62.png)

1. Navigate to **Knowledge (1)** and review **caldova-launch-kb**. Confirm the document source **caldova-documents-ks** is ready and contains the four Caldova PDFs. Review the existing public web source **caldova-public-gmp-web-ks**; no additional Web IQ connection is needed.

   ![](../Sandbox-Environment-Guides/Images/amp63.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Click on **Manage (1)** from the top navigation bar. Select **Connected resources (2)** to see the connected resources **(3)**.

   ![](../Sandbox-Environment-Guides/Images/amp64.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Navigate to **Agents (1)** and select **supplier-terms-agent (2)** first.

   ![](../Sandbox-Environment-Guides/Images/a27.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Make sure **gpt-5-mini** model selected.

   ![](../Sandbox-Environment-Guides/Images/a22.png)

1. Verify the existing knowledge-base MCP tool is attached. Keep the deployed specialist instructions and tools.

   ![](../Sandbox-Environment-Guides/Images/a23.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

    >**Note:** In case we are updating anything in the Agent, we need to click **Save**.

1. In the **Chat** playground, test Supplier Terms Agent using the prompts below. Check that company-specific answers use the Caldova documents and retain the returned source references.

   ```
   Summarize Caldova's supplier onboarding and qualification requirements for the November launch. Cite the supporting Caldova documents.
   ```

   ![](../Sandbox-Environment-Guides/Images/a24.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ![](../Sandbox-Environment-Guides/Images/a40.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Try some other prompts:

   ```
   What contract obligations and quality-agreement requirements apply to Caldova suppliers and CMOs? Use the Caldova reference PDFs and identify any missing information.
   ```

   ![](../Sandbox-Environment-Guides/Images/b83.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ```
   What do the Caldova supplier terms say about delivery delays, escalation and remediation? Cite the relevant document sections.
   ```

   ![](../Sandbox-Environment-Guides/Images/b84.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ```
   Explain the general purpose of a pharmaceutical quality agreement using the approved public FDA or EMA sources. Include the source URL and distinguish this guidance from Caldova-specific contract terms.
   ```

   ![](../Sandbox-Environment-Guides/Images/b85.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.


1. Review the existing Fabric Data Agent tool on **supplier-terms-agent**. If you already connected it in AYI02, keep that connection. Otherwise, add **Caldova_Launch_Readiness_Agent** using the steps below. Repeat only for another specialist whose Fabric tool is missing.

1. Scroll down to **Tools**, click on **Add** drop down **(1)** and then **Add tools (2)**. This tool retrieves operational data through the published Lakehouse-backed Fabric Data Agent.

   ![](../Sandbox-Environment-Guides/Images/a28.png)

1. Select **Fabric IQ(OneLake Catalog) (1)** and then **Add tool (2)**.

   ![](../Sandbox-Environment-Guides/Images/a32.png)

1. Select the published **Caldova_Launch_Readiness_Agent (1)** Data Agent and then **Add (2)**.

   ![](../Sandbox-Environment-Guides/Images/a30.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Review the existing specialist instructions. If source guidance is missing, add the following without replacing the agent's role or its existing instructions:

   ```
   Use the Caldova document knowledge base for supplier terms, qualification requirements and manufacturing or quality guidance.
   Use Caldova_Launch_Readiness_Agent for operational figures from the Lakehouse: plant commitments, batch schedules, equipment, inventory, forecasts, supplier/CMO capacity, quality evaluations, launch products and RFP status.
   Use the existing Web IQ knowledge source only for general GMP and quality-agreement guidance. Public sources do not establish facts about fictional Caldova suppliers or products.
   Combine the relevant tool results, retain returned source references and state missing evidence. Do not invent operational figures or treat available capacity as a confirmed commitment.
   ```

   ![](../Sandbox-Environment-Guides/Images/a31.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

1. Try the following prompts to test the Fabric Data Agent route from Supplier Terms Agent. Check that the tool is called and operational figures come from its response.

   ```
   Which Caldova suppliers or CMOs have available capacity for the November launch? Retrieve their capacity and RFP status through the Fabric Data Agent.
   ```

   ![](../Sandbox-Environment-Guides/Images/a34.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource, configuration or response described above.

   ```
   For a supplier or CMO returned in the previous answer, combine its recorded capacity and RFP status with the Caldova contract and qualification requirements. Explain the next steps and flag evidence that is missing.

   ```


   >**Note**: If it asks any follow-up or clarification questions without providing an answer, please respond to the question based on what is required and proceed.

1. Repeat the playground test for the other three existing agents:

   | Agent | Test prompt |
   |---|---|
   | `cmo-evaluation-agent` | Compare qualified CMO options for Caldova's November launch using recorded capacity, quality evaluation and RFP status. Cite the Caldova qualification documents and identify missing evidence. |
   | `demand-sensing-agent` | Calculate November required and committed production across the three plants, the shortfall in units and its percentage of required production. Show the planning period and plant-level breakdown. |
   | `manufacturing-quality-agent` | Explain equipment, fill-finish and changeover constraints for the November launch using Fabric data and Caldova manufacturing guidance. Separately explain GMP using an approved public source and include its URL. |

   > **&lt;TODO&gt;:** Add screenshots of the three specialist responses, including the public-source answer where applicable.

### Now, click on **`Next >>`** from the lower right corner to move on to **`Post deployment Guide - Work IQ`**.

You can also open [AYI04 – Work IQ](AYI04.md) to review the existing Copilot Studio orchestration and test it in Teams.
