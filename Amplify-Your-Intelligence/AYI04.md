# Post deployment Guide - Work IQ

Work IQ provides Microsoft 365 organizational context through the existing tools. The imported **Microsoft IQ Agent** in Copilot Studio and its email flow combine this context with the Caldova Fabric Data Agent and four Foundry specialists. Reuse the setup completed in AYI02.

> **Note:** If AYI02 is complete, skip Steps 0–2 and review the existing connections in Step 3. Add only missing connections; do not import another solution or recreate working agents. The screenshots are retained from the original accelerator, with TODOs for Caldova replacements.

### Steps that need to be performed:

- **Import the solution:** Import the Power Platform solution ZIP supplied for the workshop into your Power Platform environment
- **Configure connections:** Sign in to and authorize the Work IQ, Microsoft Teams, Copilot Studio, Office 365 Outlook, Fabric Data Agent, and Foundry Agent connections.
- **Configure the email trigger** in the Power Automate flow — select the target inbox/folder to monitor and use **Caldova Request** as the subject filter.
- **Publish the agent** in Copilot Studio and enable the Microsoft Teams channel.

## Step 0: Create a Power Platform Environment with Dataverse enabled

>**Note:** If you have already completed this step during the **Rapid Prototyping – Work IQ** section, skip to **Step 3**. Otherwise, proceed with the steps below to create the Power Platform environment.

1. Right click on the [make.powerapps.com](https://make.powerapps.com) link then **Copy link** and then paste it on your VM browser tab.

1. On the **Welcome to Power Apps** page, click **Get started**.

   ![](../Sandbox-Environment-Guides/Images/a41.png)

1. Click on the **Settings (1)** from the top left and then select **Admin center**.

   ![](../Sandbox-Environment-Guides/Images/a42.png)

1. On the **Power Platform admin center**, click on **Manage (1)** then **Environments (2)** and then click **+ New (3)**.

   ![](../Sandbox-Environment-Guides/Images/a43.png)

1. On the **New environment** page, provide the following details to create a new environment.

    - **Type:** Choose **Developer (1)**
    - **Region:** Leave default
    - **Name:** Enter **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** **(2)**
    - Then Scroll down to **Change default settings**

      ![](../Sandbox-Environment-Guides/Images/b77.png)

1. Expand **Change default settings (1)** and then **Turn On (2)** setting **Add a Dataverse data  store?** and then click on **Next (3)**.

   ![](../Sandbox-Environment-Guides/Images/a45.png)

1. Then select **Save**.

   ![](../Sandbox-Environment-Guides/Images/b78.png)

1. Please wait until your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** environment is **Ready** before proceeding.

   ![](../Sandbox-Environment-Guides/Images/b80.png)


## Step 1: Import the Solution and configure the connections.

If the solution is not already imported, import the actual Power Platform solution ZIP into your environment. This is the workshop solution package, not a ZIP of your **Caldova-v1** deployment folder.

1. Navigate back to **Power Apps** portal. Refresh the portal.

1. Click on the **default Environment (1)** and then select your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)** Environment.

   ![](../Sandbox-Environment-Guides/Images/a50.png)

1. Make sure your in your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a51.png)

1. Go to **Solutions (1)** and then select **Import solution (2)**.

   ![](../Sandbox-Environment-Guides/Images/a52.png)

1. Click on **Browse** to select the solution file to import.

   ![](../Sandbox-Environment-Guides/Images/a53.png)

1. Navigate to **C:\Files (1)**, select the workshop Power Platform solution ZIP **(2)** (using its renamed filename if applicable), and click **Open (3)**.

   ![](../Sandbox-Environment-Guides/Images/a54.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Once the Solution file is imported, click on **Next**.

   ![](../Sandbox-Environment-Guides/Images/a55.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Click on **Next** again.

   ![](../Sandbox-Environment-Guides/Images/a56.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Make sure you signed in / green check mark is showing up for all the services **(1)** and then **Import (2)**.

   ![](../Sandbox-Environment-Guides/Images/a57.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Wait for the Solution to import successfully.

   ![](../Sandbox-Environment-Guides/Images/a58.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. After importing has completed, click **Publish all customizations** in the top menu.

   ![](../Sandbox-Environment-Guides/Images/a59.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Wait for publishing to complete.

   ![](../Sandbox-Environment-Guides/Images/a60.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. When the import is complete, the solution will be available in the environment.

## Step 2: Configure the Email Trigger

Once connections are set, configure the Power Automate flow to monitor the correct inbox:

1. Navigate to **Solutions (1)** then select the imported **Microsoft IQ Accelerator (2)** solution, or its renamed Caldova equivalent.

   ![](../Sandbox-Environment-Guides/Images/a61.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Select the **When a new email arrives (V3)** trigger.

   ![](../Sandbox-Environment-Guides/Images/a62.png)

1. Click on **Edit**.

   ![](../Sandbox-Environment-Guides/Images/a63.png)

1. Click on **When a new email arrives (V3)** trigger.

   ![](../Sandbox-Environment-Guides/Images/a64.png)

1. Delete the **Inbox** folder.

   ![](../Sandbox-Environment-Guides/Images/a65.png)

1. Once it is deleted, click on the **folder (1)** icon and then select the **Inbox (2)** again. We deleted and selected the folder again because `Even though the Folder field shows 'Inbox,' this solution was imported from a different environment, so it may still be pointing at the wrong mailbox behind the scenes. Delete the value and re-select 'Inbox' from the picker to force it to re-link to your own mailbox.`

   ![](../Sandbox-Environment-Guides/Images/a66.png)

1. Expand the **Show advanced options** drop down.

   ![](../Sandbox-Environment-Guides/Images/a67.png)

1. Click the **X** next to that email address to remove it entirely, it is a stale leftover from wherever this solution was originally built/tested.

   ![](../Sandbox-Environment-Guides/Images/a68.png)

1. Set **Subject Filter** to **Caldova Request (1)** and then **Save (2)** the flow.

   ![](../Sandbox-Environment-Guides/Images/a69.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

## Step 3: Add the External Agents in Copilot Studio

Review the connected agents on the existing **Microsoft IQ Agent**. Keep the four Caldova Foundry specialists and the published **Caldova_Launch_Readiness_Agent** enabled. The Fabric agent uses **caldova_supply_lakehouse** as its working source; ontology graph materialization is not required. Use the following steps only to add a missing agent.

### 3.1 Add the Foundry Agents

If all four agents are already connected and enabled from AYI02, skip the connection-creation steps and review the instructions and tests below. Otherwise, connect the four agents already deployed in the **caldova-nextgen-launch** Foundry project. Start with **Supplier Terms Agent**, then repeat the connection steps for the other three using the same project connection.

1. Before connecting the agents, run the following prompt in **GitHub Copilot on the VM**, in your existing **Caldova-v1** folder. This checks the Activity protocol required by the [Copilot Studio Foundry connector](https://learn.microsoft.com/en-us/microsoft-copilot-studio/add-agent-foundry-agent).

   ```text
   Prepare the existing Caldova Foundry agents for connection from Copilot Studio: supplier-terms-agent, cmo-evaluation-agent, demand-sensing-agent and manufacturing-quality-agent. Use the project endpoint and resource IDs from FOUNDRY-DEPLOYMENT.md. Read each agent's stable endpoint configuration and enable the Activity protocol only if missing, following https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/configure-agent using the supported REST API or SDK. Preserve all existing protocols, authentication settings, active versions, instructions and tools. Do not recreate agents or redeploy resources. Read back the configuration to verify the update and report any failures. Output the project endpoint and the exact agent identifiers to enter in Copilot Studio's Agent Id field, and record them in FOUNDRY-DEPLOYMENT.md.
   ```

   > **Note:** The Foundry portal may still display only Responses and A2A endpoints after Activity is enabled. Use the configuration read-back and the Copilot Studio test below to verify the connection.

1. Right click on [Copilot Studio](https://copilotstudio.microsoft.com), then **Copy link** and then paste it on your VM browser tab to open the Copilot Studio.

1. Click on the default environment **(1)** and then select your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)**.

   ![](../Sandbox-Environment-Guides/Images/a70.png)

1. Make sure you are in **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a71.png)

1. Click on **Agents (1)** and then select the **Microsoft IQ Agent (2)**. It's the pre-configured agent included in the solution imported into Power Apps. If you renamed it, select its updated name. Reuse this agent and its existing Work IQ tools and email flow.

   ![](../Sandbox-Environment-Guides/Images/a72.png)

   > **&lt;TODO&gt;:** Update this screenshot if the imported agent has been renamed for Caldova.

1. On the **Welcome to Microsoft Copilot Studio** page, click on **Get Started**.

   ![](../Sandbox-Environment-Guides/Images/a73.png)

    >**Note:** If you get any error like the below **(1)**, go back the previous tab **(2)**. Refresh the browser and then open the agent again.

     ![](../Sandbox-Environment-Guides/Images/a103.png)

1. Click **Skip** to skip the **Welcome to Copilot Studio** pop up.

   ![](../Sandbox-Environment-Guides/Images/a74.png)

1. Navigate to **Agents (1)** and select **Microsoft IQ Agent (2)**, or its renamed equivalent.

   ![](../Sandbox-Environment-Guides/Images/b67.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the imported agent used for Caldova.

1. Make sure you are in **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a75.png)

1. Open the **Agents** tab. If it is hidden, use the **+6 (1)** / more-tabs menu and select **Agents (2)**.

   ![](../Sandbox-Environment-Guides/Images/a76.png)

1. Click on **+Add** to add Agent.

   ![](../Sandbox-Environment-Guides/Images/a77.png)

1. Click on **Connect to an External agent (1)** drop down and select **Microsoft Foundry (2)**.

   ![](../Sandbox-Environment-Guides/Images/a78.png)

1. In the connection dropdown, select an existing connection to the Caldova Foundry project, if available. Otherwise, click **Not connected (1)** and then **Create new connections (2)** and follow the connection-creation steps below.

   ![](../Sandbox-Environment-Guides/Images/a79.png)

1. For a new connection, navigate back to the **Microsoft Foundry Portal**, select the **caldova-nextgen-launch** project and click **Home**.

   -  If prompted **Save** the Agent.

      ![](../Sandbox-Environment-Guides/Images/b68.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova Foundry project.

1. Copy the **Project endpoint** into Notepad. Use the project endpoint, not the browser address or an individual agent endpoint. Confirm it matches the endpoint recorded by Copilot.

   ![](../Sandbox-Environment-Guides/Images/a80.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova project endpoint.

1. Navigate back to the **Copilot Studio**.

1. When creating a new connection, on the **Azure AI Foundry Agent Service** dialog,

   - **Authentication Type:** Select **Microsoft Entra ID User Login (1)**
   - **Azure AI Project Endpoint:** Paste the Project endpoint you copied in the previous step **(2)**
   - Then click **Create (3)**

     ![](../Sandbox-Environment-Guides/Images/a81.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova project connection.

1. If prompted, select the user account **<inject key="AzureAdUserEmail"></inject>**.

   ![](../Sandbox-Environment-Guides/Images/a82.png)

1. Make sure the connection is established **(1)** and then click **Next (2)**.

   ![](../Sandbox-Environment-Guides/Images/a83.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the established Caldova connection.

1. On the **Connect Microsoft Foundry agent** page, provide the following details:

   - **Name**: Enter **Supplier Terms Agent (1)**.
   - **Description**: `Answers questions about Caldova supplier terms, contract obligations and qualification requirements using the demo documents; uses public sources only for general GMP and quality-agreement information.` **(2)**
   - **Agent Id**: Enter the exact identifier reported by Copilot for **supplier-terms-agent (3)**. For the new Foundry agent, use its stable agent name, not the Copilot Studio display label. Verify it against your deployment output.
   - Then select **Add and configure (4)**

     ![](../Sandbox-Environment-Guides/Images/a84.png)

   > **&lt;TODO&gt;:** Replace the original agent details in this screenshot with Supplier Terms Agent and its actual Agent Id.

1. Click **Back**.

   ![](../Sandbox-Environment-Guides/Images/a85.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the connected Supplier Terms Agent.

1. Repeat **+ Add an agent → Connect to an external agent → Microsoft Foundry** for the other three agents. Select the **same Caldova project connection**, click **Next**, and use the details below. Verify each Agent Id against Copilot's output before adding it.

   | Name in Copilot Studio | Foundry agent name / Agent Id | Description |
   |---|---|---|
   | CMO Evaluation Agent | `cmo-evaluation-agent` | Evaluates external CMO options for the November launch using Caldova qualification documents, quality evaluations, available capacity and RFP status. Uses the Fabric Data Agent for operational figures. |
   | Demand Sensing Agent | `demand-sensing-agent` | Analyzes Caldova launch demand, competitive-product data and required versus committed production across the three plants. Uses the Fabric Data Agent to calculate the launch shortfall and its percentage. |
   | Manufacturing Quality Agent | `manufacturing-quality-agent` | Explains Caldova manufacturing-quality requirements and equipment, fill-finish and changeover constraints using demo guidance and the Fabric Data Agent. Uses public sources for general GMP information. |

   > **Note:** These connections reuse the agents and their existing Fabric Data Agent, document knowledge and Web IQ tools. No additional Foundry agents or Web IQ connections are needed here.

1. On the main agent's **Agents** tab, confirm all four Caldova Foundry agents are listed and **Enabled**.

   > **&lt;TODO&gt;:** Add a screenshot showing all four connected Caldova Foundry agents.

1. Open the main agent's **Overview → Instructions** and use the full [Caldova Copilot Studio Instructions](<Gap Analysis/Caldova-Copilot-Studio-Instructions.md>) saved during AYI02. If you already applied them, keep them. These instructions preserve the Work IQ and email behavior while routing to the four specialists and the Lakehouse-backed Fabric Data Agent.

   In the **--#TOOLS#--** section, on each line beginning **Use Supplier Terms Agent**, **Use CMO Evaluation Agent**, **Use Demand Sensing Agent** and **Use Manufacturing Quality Agent**, replace only the agent name with its actual connected-agent reference: place the cursor after **Use**, type **/** and select that agent, leaving the rest of the line intact. Keep the Fabric routing text and its enabled connection; Fabric agents cannot currently be referenced explicitly with **/**. See [connected-agent instructions](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents).

   Save the instructions before testing and publishing. Keep the existing main agent; no separate RFP tracking agent is needed for this walkthrough.

   > **&lt;TODO&gt;:** Add a screenshot of the Caldova instructions with the four connected Foundry references.

1. Open **Test your agent** and try each prompt below in a new test conversation. Check the activity map to confirm the intended Foundry agent was called, then review its answer and source references.

   | Agent | Test prompt |
   |---|---|
   | Supplier Terms Agent | `Use Supplier Terms Agent to summarize Caldova's supplier contract and qualification requirements for the November launch. Cite the demo documents used.` |
   | CMO Evaluation Agent | `Use CMO Evaluation Agent to compare the qualified CMO options for Caldova's November launch. Show available capacity, quality evaluation and RFP status from the Fabric Data Agent, and cite qualification documents. Identify any missing evidence.` |
   | Demand Sensing Agent | `Use Demand Sensing Agent to calculate Caldova's November required and committed production across the three plants, the shortfall in units and the shortfall as a percentage of required production. Show the planning period, formula and plant-level breakdown from the Fabric Data Agent.` |
   | Manufacturing Quality Agent | `Use Manufacturing Quality Agent to explain the equipment, fill-finish and changeover constraints affecting Caldova's November launch. Use operational data and cite the demo manufacturing-quality guidance. Separately explain GMP using an approved public FDA or EMA source and include its URL.` |

   > **Note:** A successful connection must return an answer through Copilot Studio, not just appear in the list. For an **endpoint does not support activity** error, rerun the preparation prompt. For **404 / Version not found**, confirm the project endpoint and Agent Id belong to the deployed agent in the new Foundry portal. If a Fabric tool returns **Workspace ID and artifact ID are required**, test that agent in the Foundry playground with your lab-user account and verify its existing Fabric tool connection before retrying; document and Web IQ answers alone do not verify the Fabric route.

   > **&lt;TODO&gt;:** Add screenshots of successful Caldova agent calls and responses in the Copilot Studio test panel.

### 3.2: Add the Fabric Data Agent

1. Confirm all four Foundry specialists appear in the connected-agent list **(1)**. If **Caldova_Launch_Readiness_Agent** is already connected and enabled, skip these addition steps. Otherwise click **+ Add an agent (2)**.

   ![](../Sandbox-Environment-Guides/Images/a86.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Click on **Connect to an External agent (1)** drop down and select **Microsoft Fabric (2)**.

   ![](../Sandbox-Environment-Guides/Images/a87.png)

1. Click on **Not connected (1)** drop down and then click **Create new connections (2)**.

   ![](../Sandbox-Environment-Guides/Images/a88.png)

1. Click on **Create**.

   ![](../Sandbox-Environment-Guides/Images/a89.png)

1. If prompted, select the user account **<inject key="AzureAdUserEmail"></inject>**.

   ![](../Sandbox-Environment-Guides/Images/a82.png)

1. Make sure the connection is established **(1)** and then click **Next (2)**.

   ![](../Sandbox-Environment-Guides/Images/a90.png)

1. On **Select agent to connect**, select the published **Caldova_Launch_Readiness_Agent (1)** from the Caldova workspace and click **Next (2)**. Select the Data Agent, not the ontology item.

   ![](../Sandbox-Environment-Guides/Images/a91.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. On the Data Agent page, use **Fabric Data Agent (1)** as the display name and describe it as retrieving Caldova November launch operational data from the Lakehouse. Select **Add and Configure (2)**. If you already configured a working connection with another display name, keep it.

   ![](../Sandbox-Environment-Guides/Images/a92.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Click **Back**.

   ![](../Sandbox-Environment-Guides/Images/a93.png)

1. Confirm the Fabric agent is listed and **Enabled**, alongside the four Foundry specialists. Test a plant-capacity question and check the activity map for the Fabric call.

   ![](../Sandbox-Environment-Guides/Images/a94.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

## Step 4: Verify Work IQ connections and MCP tools are connected and enabled

1. Click on **+6 (1)** and then open the **Tools (2)** tab.

   ![](../Sandbox-Environment-Guides/Images/a95.png)

1. Click the **Model Context Protocol (1)** filter chip.

1. Confirm that you can see these three tools **(2)**:

   | Tool name | Type | Available to | Trigger |
   |---|---|---|---|
   | Work IQ Copilot (Preview) | Model Context Protocol | Microsoft IQ Agent | By agent |
   | Work IQ Mail (Preview) | Model Context Protocol | Microsoft IQ Agent | By agent |
   | Work IQ User (Preview) | Model Context Protocol | Microsoft IQ Agent | By agent |

   ![](../Sandbox-Environment-Guides/Images/a96.png)

   - For each tool, confirm that:

     - The **Enabled** toggle is set to **On**.
     - The **Errors** column is empty.
     - The **Blocked** column is empty.

## Step 5: Publish the Agent

1. Save any changed instructions or connections, open **Overview (1)** and select **Publish (2)**. Publish the current changes before using the Teams channel; a previous published date alone does not confirm those changes are live.

   ![](../Sandbox-Environment-Guides/Images/a97.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Click on **Publish** to **Publish the agent.**

   ![](../Sandbox-Environment-Guides/Images/a98.png)

1. Wait for publishing to complete.

   ![](../Sandbox-Environment-Guides/Images/a99.png)

1. Once the Agent is published, click on **+6 (1)** and then select **Channels (2)**.

   ![](../Sandbox-Environment-Guides/Images/a100.png)

1. Select **Microsoft 365 and Microsoft Teams** to configure Teams as a channel.

   ![](../Sandbox-Environment-Guides/Images/a101.png)

1. On the **Microsoft 365 and Microsoft Teams** page, select **See agent in Teams**.

   ![](../Sandbox-Environment-Guides/Images/a102.png)

1. Select **Use the web app instead**.

   ![](../Sandbox-Environment-Guides/Images/a104.png)

1. Click on **Add** to add the agent.

   ![](../Sandbox-Environment-Guides/Images/a105.png)

1. Once the Agent added, click **Open** to open the agent in Teams.

   ![](../Sandbox-Environment-Guides/Images/a106.png)

1. Confirm the agent is visible in Teams. Send **start over** to begin a new conversation with the latest published version. Use Teams for this walkthrough; the Fabric connected-agent route is not currently supported when the main agent is deployed to Microsoft 365 Copilot. See [publishing](https://learn.microsoft.com/en-us/microsoft-copilot-studio/publication-fundamentals-publish-channels) and [connected-agent limitations](https://learn.microsoft.com/en-us/microsoft-copilot-studio/authoring-add-other-agents).

   ![](../Sandbox-Environment-Guides/Images/a107.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

## Testing Flow


### Step 1: Prepare Your Environment

1. **Open Microsoft Teams** with the agent chat visible.

   ![](../Sandbox-Environment-Guides/Images/a107.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. **Open your email client** (Outlook/Office 365) that's monitored by the flow

1. Right click on [make.powerautomate.com](https://make.powerautomate.com), then **Copy link** and then paste it on your VM browser tab to open **Power Automate**  to monitor the flow run history.

### Step 2: Send a Test Email

Send an email to trigger the agent. Use the below example scenarios that test both data retrieval (Fabric) and knowledge base search (Foundry):

#### Example: Caldova November Launch Readiness

1. Right click on [Outlook](https://outlook.com/) then **Copy link** and and then paste it on your VM browser tab to open **Outlook**.

1. If prompted, select **Sign in**.

1. Click on **Continue**.

   ![](../Sandbox-Environment-Guides/Images/a108.png)

1. Click on **New mail (1)** drop down and then **Mail (2)**.

   ![](../Sandbox-Environment-Guides/Images/a109.png)

1. Draft the below mail:

   - **TO:** Provide the email address as **<inject key="AzureAdUserEmail"></inject> (1)**

   - **Subject**: `Caldova Request - Urgent: Supplier Delivery Delay Concern` **(2)**

   - **Body (3)**:
      ```
      Hi Team,

      Please assess whether a supplier delivery delay could affect Caldova's
      NextGen Pharma November launch across our three plants.

      Can you provide:
      1. Current launch-product inventory, required and committed production,
         and the shortfall in units and as a percentage of required production
      2. Internal recovery constraints and qualified external CMO options,
         including recorded capacity, quality evaluation and RFP status
      3. Relevant supplier terms, qualification requirements and recommended
         next actions, with supporting sources

      Use the available Caldova records. Identify missing evidence rather than
      assuming that a delay or a supplier commitment has been confirmed.

      Thanks,
      [Your Name]
      ```

      - Click **Send (4)**

      ![](../Sandbox-Environment-Guides/Images/a110.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

### Step 3: Monitor the Flow

After sending the email:

1. Navigate back to **Power Automate** [make.powerautomate.com](https://make.powerautomate.com).

1. Click on the **default Environment (1)** and then select **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)** to switch the environment.

   ![](../Sandbox-Environment-Guides/Images/a111.png)

1. Navigate to **My flows (1)** and then click on **When a new email arrives (v3) (2)**.

   ![](../Sandbox-Environment-Guides/Images/a112.png)

1. Refresh the flow's run history and open the run triggered by your test email. If no run appears, check that the flow is enabled, the monitored mailbox is correct and the subject contains **Caldova Request**.

   ![](../Sandbox-Environment-Guides/Images/a113.png)

1. Wait for the run to finish and inspect the trigger and action outputs. A **Succeeded** flow run confirms flow execution; also review the Teams answer to verify the requested data and knowledge retrieval.

   ![](../Sandbox-Environment-Guides/Images/a114.png)

### Step 4: Review Response in Teams

1. Navigate back to **Teams** and review the message generated by the completed flow. If it is missing, inspect the Teams action output in the flow run.

   ![](../Sandbox-Environment-Guides/Images/b57.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Check that the response relates to the Caldova request and includes the retrieved launch figures, relevant supplier or CMO evidence, and any gaps in the available information.

   ![](../Sandbox-Environment-Guides/Images/a116.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.

1. Send a relevant follow-up question in the agent chat.

1. If a connection sign-in or consent card appears, complete sign-in and click **Allow** on the card.

   ![](../Sandbox-Environment-Guides/Images/agentprompt.png)

    > **Note:** Complete each requested connection using your lab-user account. A green **Connected** status confirms sign-in; test a question to verify the tool call.

1. After completing consent, send the original question again as a fresh chat message. Do not type **Allow** as the business question or repeatedly resubmit the same consent card.

    ![](../Sandbox-Environment-Guides/Images/Agentresponse.png)

   > **&lt;TODO&gt;:** Update this screenshot with the renamed Caldova solution or the configuration and response described above.


### Test the connected routes in Teams

Run a few focused questions before combining the sources:

| Route | Test prompt |
|---|---|
| Fabric Data Agent | List Caldova's three plants and their November required and committed production. Calculate the shortfall in units and as a percentage of required production. Show units and the planning period. |
| Supplier Terms Agent | Summarize Caldova's supplier contract obligations and qualification requirements for the November launch, citing the Caldova documents. |
| CMO Evaluation Agent | Compare the qualified CMO options for Caldova's November launch using recorded capacity, quality evaluations and RFP status. Identify missing evidence. |
| Demand Sensing Agent | Compare November demand with committed production across the three plants and explain which recorded constraints limit internal recovery. |
| Manufacturing Quality Agent / Web IQ | Explain the manufacturing-quality and changeover constraints in the Caldova guidance. Separately explain GMP using an approved public FDA or EMA source and include its URL. |
| Work IQ | Find emails or documents available to me about Caldova's November launch and summarize the latest relevant communications. State if none are found. |

For a failed call, run the same question in Copilot Studio **Test** and inspect its activity map to identify the failing agent or tool. If **Evaluation** reports an error while interactive Test succeeds, record the evaluation result separately; it does not establish that the Teams route passed. For an **invalid_payload** / missing **input** error, inspect the failing action's input mapping before changing resources or instructions.

> **&lt;TODO&gt;:** Replace the original response screenshots with the successful Caldova email-flow and Teams test results.

Once the email flow and the required connected routes return the expected answers, you have completed the workshop.
