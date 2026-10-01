# 2. Rapid Prototyping


Now that you have completed the envisioning **Whiteboard session** and identified key business opportunities, it is time to move from ideas to a working prototype. Explore how a intelligent solution can bring the envisioned scenario to life, validate its potential, and demonstrate how it could work in practice.

## Rapid Prototyping using GitHub Copilot

You will use GitHub Copilot to generate ARM or Bicep templates using the Future State Architecture arrived at from the previous Whiteboarding exercise.

- **ARM templates:** JSON-based Infrastructure-as-Code files used to define and deploy Azure resources.
- **Bicep templates:** Simplified, declarative Infrastructure-as-Code files used to define and deploy Azure resources with cleaner syntax.

### Sign in to GitHub Copilot Chat


1. Click on the **Visual Studio Code** from the VM desktop.

   ![](../Sandbox-Environment-Guides/Images/amp14.png)

1. Click on **Continue with GitHub** to sign in to GitHub Copilot.

   ![](../Sandbox-Environment-Guides/Images/amp18.png)

1. On the **Sign in to GitHub** tab, enter the provided **GitHub username** **(1)** in the input field, and click on **Sign in with your identity provider** to continue **(2)**.

    - **Username:** <inject key="GitHub User Name" enableCopy="true"/>

     ![](../Sandbox-Environment-Guides/Images/amp19.png)

1. Click on **Continue** on the **Single sign-on to CloudLabs Organizations** page to proceed.

   ![](../Sandbox-Environment-Guides/Images/amp20.png)

1. Click on **Accept**.

   ![](../Sandbox-Environment-Guides/Images/amp21.png)

1. Select **Continue** to **Authorize Visual Studio Code**.

   ![](../Sandbox-Environment-Guides/Images/amp22.png)

1. Select **Authorize Visual Studio Code**.

   ![](../Sandbox-Environment-Guides/Images/amp23.png)

1. Select **Open**.

   ![](../Sandbox-Environment-Guides/Images/amp24.png)

1. Once the Visual Studio code opens, choose any desired theme **(1)** and then click **Get Started (2)**.

   ![](../Sandbox-Environment-Guides/Images/b1.png)

   ![](../Sandbox-Environment-Guides/Images/amp26.png)

   >**Note:** If you get any error pop up, please **Close.**

    ![](../Sandbox-Environment-Guides/Images/b2.png)  

    - **Close** the pop up.  

     >**Note**: Please follow the steps sequentially as indicated by the numbered brackets (e.g., (1), (2), …) and execute them in the specified order.

1. Select **File (1)** and then **Open Folder (2)**.

   ![](../Sandbox-Environment-Guides/Images/amp27.png)

1. Navigate to **`C:\`** path **(1)**, then select the **miq-project** folder **(2)** and then **Select folder (3)**.

   ![](../Sandbox-Environment-Guides/Images/b56.png)

1. From the **GitHub Copilot Chat**, select **Models (1)** and then select **Trust Workspace to enable models (2)**.

   ![](../Sandbox-Environment-Guides/Images/b6.png)

1. Select **Trust Folder and Continue**.

   ![](../Sandbox-Environment-Guides/Images/amp30.png)

1. Click **Auto (1)** and then set the model to **Claude Sonnet 5 (2)**.

   ![](../Sandbox-Environment-Guides/Images/b7.png)

    >**Note:** If you're unable to select the **Models**, please wait for `2-3 minutes` then check and make sure you're signed in properly.

1. Click on **Default permission (1)** and then set it to **Allow all (2)**.

   ![](../Sandbox-Environment-Guides/Images/b8.png)

1. Select **Enable**.

   ![](../Sandbox-Environment-Guides/Images/amp33.png)

1. Select the **Future-State-Architecture.png**.

   ![](../Sandbox-Environment-Guides/Images/b88.png)

1. From the **GitHub Copilot Chat**, click on **+ (1)** and then select the **Future-State-Architecture.png (2)**.

   ![](../Sandbox-Environment-Guides/Images/b89.png)

### Fabric IQ

1. Along with the attached **Solution Architecture** (1), please paste the below prompt (2).

   ```
   You are my smart agent to read my attached architecture design for Zava Retail and create bicep/ARM template based on the identified resources.
 
   Please follow these below instructions for Fabric IQ section:
   1. List down all the Azure resources from the attached architecture diagram.
   2. Create a new resource group.
   3. Create a new Fabric Capacity using **SKU F16** for the **West US 3** region.
   4. Create a new Fabric Workspace attaching with above newly created capacity. 
   5. Create Lakehouse and store sample data into tables(Tables should be as per architecture design)
   6. Create Fabric Ontology using above Lakehouse tables with proper relationship and generate Ontology Graph View
   7. Create Data Agent using above Ontology as a data source and prepare proper Agent Instruction based on these Ontology Entities.
   
   Note: After complete all above steps successfully, create MD(mark down) file with deployment instructions and post deployment configurations, and start deployment(create workspace, create lakehouse, table creation, sample data insertion, ontology creation, data agent creation)
   ```

   - Then **Send (3)**.

    ![](../Sandbox-Environment-Guides/Images/b12.png)
   
1. Once Copilot starts generating the response, monitor the process closely. Do not take any action; simply watch the progress.

1. If Copilot Asks below question to create new Resource Group, please select the option similar to the one marked below.

   ![](../Sandbox-Environment-Guides/Images/Prompt-followup.png)

1. After some time, Copilot may ask you a few questions. Review each question carefully and select the appropriate response. 

1. Select **Yes**, if any question prompts you to respond related to `F16` deployment.

   ![](../Sandbox-Environment-Guides/Images/b13.png)

1. If prompted to provide the UPN for assigning **Fabric Administrator access**, enter **<inject key="AzureAdUserEmail"></inject> (1)** and then select **Submit (2)**. 

    ![](../Sandbox-Environment-Guides/Images/b14.png)

1. Monitor the process to understand how it generates the response and handles or resolves errors.  

   >**Note:** In between, if it asks you to **Continue to iterate**, please click **Continue**.

1. Wait for the deployment to complete. This may take approximately `20–30` minutes. Once completed, you will see a Summary/Conclusion similar to the example below, although the details may vary **(1)** and select **Keep (2)** to keep the created files.

   ![](../Sandbox-Environment-Guides/Images/b15.png)

    >**Note:** The **Summary/Conclusion** may look different for you. Once the deployment is completed, you will be able to view the results in the chat.

1. Once the deployment is complete, you can verify the deployed resources by navigating to the newly created resource group.

1. Navigate to the Azure portal. Click on **Resource group**.

   ![](../Sandbox-Environment-Guides/Images/b16.png)

1. Select the newly created Resource Group, excluding the **resource groups** highlighted below.

   ![](../Sandbox-Environment-Guides/Images/b55.png)

1. You should see the deployed Fabric capacity.

   ![](../Sandbox-Environment-Guides/Images/b17.png)

1. Click on the **App launcher (1)** and select **Microsoft fabric** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Navigate to **Workspaces**, there should be workspace created with the name similar to **Zava Retail**. 

   - If your unable to see. Please go back to the **GitHub Copilot Chat**.

     ![](../Sandbox-Environment-Guides/Images/b18.png)

      >**Note:** Not the one which starts with **Microsoft IQ**.

1. From the **GitHub Copilot Chat**, send the the below prompt to make the UPN **<inject key="AzureAdUserEmail"></inject>** as Fabric admin **(1)** and then **Send (2)**.

   ```
   Please provide Fabric admin access to the UPN <inject key="AzureAdUserEmail"></inject> to see the fabric workspace
   ```

    ![](../Sandbox-Environment-Guides/Images/b19.png)   

1. Wait for the process to complete and then **Keep** the file.

   ![](../Sandbox-Environment-Guides/Images/b20.png)

1. Now please go back to the Fabric portal, refresh the portal and navigate to the **Workspaces**. Now you should be able to see a Workspace which starts with something similar to `Zava Retail`.

   ![](../Sandbox-Environment-Guides/Images/b21.png)

1. Open the **Zava Retail** workspace.

1. Make sure that all the workspace items mentioned in the prompt are created. 

   ![](../Sandbox-Environment-Guides/Images/b22.png)

1. Please open each item and verify that it has been created correctly. If anything is missing, go back to the **GitHub Copilot Chat** and provide a follow-up prompt to address the missing item.  

1. In this case, when I opened the workspace. There are no tables created in the Lakehouse.

   ![](../Sandbox-Environment-Guides/Images/b23.png)

1. Navigate back to the **GitHub Copilot Chat** to send the follow up prompt.

   ```
   Issues identified with the workspace items, please fix this issue.

   No table has been created in the Lakehouse, and no sample data has been loaded.
   The Ontology was created, but no entities or relationships have been added.
   The Ontology has not been configured as the Data Source for the Data Agent.
   ```

    ![](../Sandbox-Environment-Guides/Images/b25.png)

1. Wait for the process to complete and click **Keep** to keep the file.

   ![](../Sandbox-Environment-Guides/Images/b24.png)

1. Navigate back to the Fabric workspace, refresh the Lakehouse, and verify that the tables have been created and the sample data has been loaded successfully.

   ![](../Sandbox-Environment-Guides/Images/b26.png)

1. Open the **Ontology** item and verify that the entities and relationships have been created successfully.

   ![](../Sandbox-Environment-Guides/Images/b27.png)

1. Select **Product** Entity **(1)** and then click on **View Entity Type details (2)**.   

   ![](../Sandbox-Environment-Guides/Images/b60.png)

1. Click on **Overview**.

   ![](../Sandbox-Environment-Guides/Images/b61.png)

1. Set the `Time range` to **Last 30 minutes (1)**,

   - `Time granularity`: **1 hr (2)**
   - `Aggregation`: **Sum (3)**
   - Then **Apply (4)**

     ![](../Sandbox-Environment-Guides/Images/b76.png) 

1. Wait until you see the **Relationship graph**.

   ![](../Sandbox-Environment-Guides/Images/graph.png)

1. Close the **Ontology** page.

1. Open the **Data Agent** from the workspace and verify that the **Ontology** is configured as the Data Source.

1. If not please go back to **GitHub Copilot Chat** and explain the issue and ask to fix.

   - Navigate back to the **Fabric workspace** and open the **Data Agent**. If the error persists, remove the existing Data Source and manually add the **Ontology** as the Data Source.

   - Click on the **elipses (1)** and then **Remove (2)**.

     ![](../Sandbox-Environment-Guides/Images/b28.png)

   - Click **Yes, remove**. 

   - Select **Add data (1)** drop down and then **Data source (2)**.

     ![](../Sandbox-Environment-Guides/Images/b30.png)   

   - Select the **Ontology (1)** and then **Add (2)**.

     ![](../Sandbox-Environment-Guides/Images/b31.png)        

1. Make sure Ontology is added.

   ![](../Sandbox-Environment-Guides/Images/b32.png)

1. Navigate to **Test data agent (1)**, send the following prompts in Data agent input box **(2)**:

   ```
   Which products are below their reorder level?
   ```

   ![](../Sandbox-Environment-Guides/Images/b58.png)   

   ```
   List all suppliers and their lead times.
   ```

   ![](../Sandbox-Environment-Guides/Images/b59.png)    

1. Click on **Publish**.

   ![](../Sandbox-Environment-Guides/Images/b65.png)  

1. Click on **Publish** again to publish the data agent.

   ![](../Sandbox-Environment-Guides/Images/b66.png)  

### Foundry IQ    

1. Navigate back to the **GitHub Copilot Chat** to deploy the **Foundry resources**.

1. Navigate back to the **GitHub Copilot Chat** 

1. Copy the prompt below into the chat and send.

   ```
   You are my smart agent to read my attached architecture design for Zava Retail and create bicep/ARM template based on the identified resources.

   Please follow these below instructions for Foundry IQ section in the same Resource group.
   1. List down all the Azure Foundry related resources from the architecture diagram.
   2. Create Foundry resources in Azure(Please use same Resource Group created for the above Fabric Resources) and use Sweden Central region. 
   3. In Foundry Project, create two models(1. gpt-5-mini, 2. text-embedding-3-small)
   4. In Foundry Project, create knowledge base and having one knowledge source which should point to the Azure resource > Resource group (rg-miqsolution)-> Container -> All files(PDFs) using Azure AI Search Service.
   5. Create Foundry Agent("Retail-Agent") and use "Fabric Data Agent" using tool calling and use above knowledge base as attaching knowledge.
   6. Once "Retail-Agent" get created, please validate(prompt should work and return valid results) and provide confirmation.

   Note: After complete all above steps successfully, create MD(mark down) file with deployment instructions and post deployment configurations, and start deployment.
   ```

1. Wait for the deployment to complete and the **Keep** the file.

   ![](../Sandbox-Environment-Guides/Images/b38.png)  

1. Navigate back to the Resource group. Select the **Foundry Project**.

   ![](../Sandbox-Environment-Guides/Images/b39.png)  

1. Click On **Go to Foundry portal**.

   ![](../Sandbox-Environment-Guides/Images/b40.png)  

1. Click on **Build**.

   ![](../Sandbox-Environment-Guides/Images/b41.png)  

1. Navigate to **Models (1)** and make sure 2  models are deployed **(2)**,

   ![](../Sandbox-Environment-Guides/Images/b42.png)  

1. Navigate to **Agents (1)** and click on the **Retail-Agent (2)**.

   ![](../Sandbox-Environment-Guides/Images/b43.png)  

1. Make sure the model is set to **gpt-5-mini (1)**. If you get any error in the **Tools (2)** section as below:

   ![](../Sandbox-Environment-Guides/Images/b44.png)  

   - From the **Model** drop down, switch to **gpt-5** model.

     ![](../Sandbox-Environment-Guides/Images/b45.png)  

   - Then again select the **gpt-5-mini** model.

   - Scroll down to **Tools**. Click on **Add (1)** drop down and then select **Add tools (2)**.

     ![](../Sandbox-Environment-Guides/Images/b46.png)  

   - Select **Fabric IQ(OneLake Catalog) (1)** and then **Add tool (2)**.

     ![](../Sandbox-Environment-Guides/Images/a32.png)      

   - Select the **Zava Retail** Ontology **(1)** and then **Add (2)**. 

     ![](../Sandbox-Environment-Guides/Images/b47.png)          

1. Scroll down to **Knowledge**, verify that the Knowledge source has been added.

   ![](../Sandbox-Environment-Guides/Images/b48.png)  

1. Lets test the Agent by providing some prompts related to documents and agent.

1. For getting the prompts, you can go back to **GitHub Copilot Chat**, and send the below query:

   ```
   Can you please provide some of the prompts to test the foundry agent.
   ```

   ![](../Sandbox-Environment-Guides/Images/b49.png) 

1. Once the prompts are generated, you can go back to the Foundry Agent **Chat** section and paste the prompts to see the results.

   ![](../Sandbox-Environment-Guides/Images/b51.png)  

   ![](../Sandbox-Environment-Guides/Images/b52.png)  

   ![](../Sandbox-Environment-Guides/Images/b53.png)     

## Work IQ

The third component of the accelerator is Work IQ (the Copilot Studio email-triggered agent that orchestrates Fabric IQ and Foundry IQ from a single conversational ingress)

### Steps that need to be performed:

- **Import the solution:** Import the Power Platform zip solution file inside the solution file folder into your Power Platform environment
- **Configure connections:** Sign in to and authorize the Work IQ, Microsoft Teams, Copilot Studio, Office 365 Outlook, Fabric Data Agent, and Foundry Agent connections. 
- **Configure the email trigger** in the Power Automate flow — select the target inbox/folder to monitor and (optionally) add a subject filter such an IQ Request.
- **Publish the agent** in Copilot Studio and enable the Microsoft Teams channel.

### Step 0: Create a Power Platoform Environment with Dataverse enabled

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


### Step 1: Import the Solution and configure the connections.

In this step, you will import the Power Platform zip solution file into your Power Platform environment.

1. Navigate back to **Power Apps** portal.

1. Click on the **default Environment (1)** and then select your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)** Environment.

   ![](../Sandbox-Environment-Guides/Images/a50.png)

1. Make sure you are in your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a51.png)

1. Go to **Solutions (1)** and then select **Import solution (2)**.

   ![](../Sandbox-Environment-Guides/Images/a52.png)

1. Click on **Browse** to select the solution file to import.

   ![](../Sandbox-Environment-Guides/Images/a53.png)

1. Navigate to **C:\Files (1)**, then select **MicrosoftIQAccelerator (2)** zip file and then **Open (3)**.

   ![](../Sandbox-Environment-Guides/Images/a54.png)

1. Once the Solution file is imported, click on **Next**.

   ![](../Sandbox-Environment-Guides/Images/a55.png)

1. Click on **Next** again.

   ![](../Sandbox-Environment-Guides/Images/a56.png)

1. Make sure you are signed in and a green check mark is showing up for all the services **(1)** and then click on **Import (2)**.

   ![](../Sandbox-Environment-Guides/Images/a57.png)

1. Wait for the Solution to import successfully, it may take `2-3 minutes`.

   ![](../Sandbox-Environment-Guides/Images/a58.png)

1. After importing has completed, click **Publish all customizations** in the top menu.    

   ![](../Sandbox-Environment-Guides/Images/a59.png)

1. Wait for publishing to complete. 

   ![](../Sandbox-Environment-Guides/Images/a60.png)

1. When the import is complete, the solution will be available in the environment.

### Step 2: Configure the Email Trigger

Once connections are set, configure the Power Automate flow to monitor the correct inbox:

1. Navigate to **Solutions (1)** then select the imported **Microsoft IQ Accelerator (2)** solution.

   ![](../Sandbox-Environment-Guides/Images/a61.png)

1. Select the **When a new email arrives (V3)** trigger.

   ![](../Sandbox-Environment-Guides/Images/a62.png)

1. Click on **Edit**.

   ![](../Sandbox-Environment-Guides/Images/a63.png)

1. Click on **When a new email arrives (V3)** trigger.

   ![](../Sandbox-Environment-Guides/Images/a64.png)

1. Remove the **Inbox** folder by clicking on the backspace.

   ![](../Sandbox-Environment-Guides/Images/a65.png)

1. Once it is deleted, click on the **folder (1)** icon and then select the **Inbox (2)** again. We deleted and selected the folder again because `Even though the Folder field shows 'Inbox,' this solution was imported from a different environment, so it may still be pointing at the wrong mailbox behind the scenes. Delete the value and re-select 'Inbox' from the picker to force it to re-link to your own mailbox.`

   ![](../Sandbox-Environment-Guides/Images/a66.png)

1. Expand the **Show advanced options** drop down.

   ![](../Sandbox-Environment-Guides/Images/a67.png)

1. Click the **X** next to that email address to remove it entirely, it is a stale leftover from wherever this solution was originally built/tested. 

   ![](../Sandbox-Environment-Guides/Images/a68.png)

1. Optionally add a `Subject Filter` to limit which emails trigger the flow. You can provide **IQ Request** **(1)** and then **Save (2)** the flow.   

   ![](../Sandbox-Environment-Guides/Images/a69.png)

### Step 3: Add the External Agents in Copilot Studio   

After import, add the Fabric and Foundry agents again in Copilot Studio. Use Fabric for data questions and Foundry for document questions. If they do not appear yet, finish deploying Fabric and Foundry first, then return to Copilot Studio and refresh the agent list.

### 3.1 Add the Foundry Agent
 
1. Right click on [Copilot Studio](https://copilotstudio.microsoft.com), then **Copy link** and then paste it on your VM browser tab to open the Copilot Studio.

1. Click on the default environment **(1)** and then select your **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)**.

   ![](../Sandbox-Environment-Guides/Images/a70.png)

1. Make sure you are in **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a71.png)

1. Click on **Agents (1)** and then select the **Microsoft IQ Agent (2)**. It's a pre-configured component that came bundled inside the solution package we imported in the Power apps.

   ![](../Sandbox-Environment-Guides/Images/a72.png)

1. On the **Welocome to Microsoft Copilot Studio** page, click on **Get Started**.

   ![](../Sandbox-Environment-Guides/Images/a73.png)

    >**Note:** If you get any error like the below **(1)**, go back the previous tab **(2)**. Refresh the browser and then open the agent again.

     ![](../Sandbox-Environment-Guides/Images/a103.png)    

1. Click **Skip** to skip the **Welcome to Copilot Studio** pop up.

   ![](../Sandbox-Environment-Guides/Images/a74.png)

1. Navigate to **Agents (1)** and the select **Microsoft IQ Agent (2)**.   

   ![](../Sandbox-Environment-Guides/Images/b67.png)

1. Make sure you are in **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>** Environment.

   ![](../Sandbox-Environment-Guides/Images/a75.png)

1. Click on **+6 (1)** and then select **Agents (2)**.

   ![](../Sandbox-Environment-Guides/Images/a76.png)

1. Click on **+Add** to add Agent.

   ![](../Sandbox-Environment-Guides/Images/a77.png)

1. Click on **Connect to an External agent (1)** drop down and select **Microsoft Foundry (2)**.

   ![](../Sandbox-Environment-Guides/Images/a78.png)

1. Click on **Not connected (1)** drop down and then click **Create new connections (2)**.

   ![](../Sandbox-Environment-Guides/Images/a79.png)

1. Before proceeding to the next step, navigate back to the **Microsoft Foundry Portal.** Click on **Home**.

   -  If prompted **Save** the Agent.

      ![](../Sandbox-Environment-Guides/Images/b68.png)   

1. Copy and paste the **Project endpoint** in a notepad.

   ![](../Sandbox-Environment-Guides/Images/a80.png)

1. Navigate back to the **Copilot Studio**.   

1. On the **Azure AI Foundry Agent Service**,

   - **Authentication Type:** Select **Microsoft Entra ID User Login (1)**
   - **Azure AI Project Endpoint:** Paste the Project endpoint you copied in the previous step **(2)** 
   - Then click **Create (3)**

     ![](../Sandbox-Environment-Guides/Images/a81.png)

1. If prompted, select the user account **<inject key="AzureAdUserEmail"></inject>**.

   ![](../Sandbox-Environment-Guides/Images/a82.png)

1. Make sure the connection is established **(1)** and then click **Next (2)**.

   ![](../Sandbox-Environment-Guides/Images/a83.png)

1. On the **Connect Microsoft Foundry agent** page, provide the following details:

   - **Name**: Enter **Retail Agent (1)**
   - **Description**: `You are a data analyst assistant for Microsoft IQ with access to documents and reference materials.` **(2)**
   - **Agent Id**: Enter **Retail Agent (3)**
     - This is the same name as the agent in Foundry.
   - Then select **Add and configure (4)**  

     ![](../Sandbox-Environment-Guides/Images/b69.png)

1. Click **Back**.

   ![](../Sandbox-Environment-Guides/Images/b70.png)

### 3.2: Add the Fabric Data Agent   

1. Confirm the Foundry agent appears in the connected-agent list **(1)** and then click **+ Add an agent (2)**.

   ![](../Sandbox-Environment-Guides/Images/b71.png)

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

1. On the **Select agent to connect** page, select the Ontology model **(1)** and then **Next (2)**.

   ![](../Sandbox-Environment-Guides/Images/b72.png)

1. On the Ontology Agent page, provide the name as **SupplyChainDataAgent (1)** and then **Add and Configure (2)**.

   ![](../Sandbox-Environment-Guides/Images/b73.png)

1. Click **Back**.

   ![](../Sandbox-Environment-Guides/Images/b74.png)

1. Make sure the Fabric agent now shows up in the list of connected agents.

   ![](../Sandbox-Environment-Guides/Images/b75.png)

### Step 4: Verify Work IQ connections and MCP tools are connected and enabled
 
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

1. Click on the **Overview (1)** tab and then **Publish (2)**.

   ![](../Sandbox-Environment-Guides/Images/a97.png)

1. Click on **Publish** to **Publish the agent.**

   ![](../Sandbox-Environment-Guides/Images/a98.png)
 
1. Wait for publishing to complete (1-2 minutes).

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

1. Make sure you can see the agent.

   ![](../Sandbox-Environment-Guides/Images/a107.png)

## Testing Flow   


### Step 1: Prepare Your Environment

1. **Open Microsoft Teams** with the agent chat visible.

   ![](../Sandbox-Environment-Guides/Images/a107.png)

1. **Open your email client** (Outlook/Office 365) that's monitored by the flow 

1. Right click on [make.powerautomate.com](https://make.powerautomate.com), then **Copy link** and then paste it on your VM browser tab to open **Power Automate**  to monitor the flow run history.

### Step 2: Send a Test Email

Send an email to trigger the agent. Use the below example scenarios that test both data retrieval (Fabric) and knowledge base search (Foundry):

#### Example: Supply Chain Disruption

1. Right click on [Outlook](https://outlook.com/) then **Copy link** and then paste it on your VM browser tab to open **Outlook**.

1. If prompted, select **Sign in**.

1. Click on **Continue**.

   ![](../Sandbox-Environment-Guides/Images/a108.png)

1. Click on **New mail (1)** drop down and then **Mail (2)**.

   ![](../Sandbox-Environment-Guides/Images/a109.png)

1. Draft the below mail:

   - **TO:** Provide the email address as **<inject key="AzureAdUserEmail"></inject> (1)**

   - **Subject**: `IQ Request - Urgent: Supplier Delivery Delay Concern` **(2)**

   - **Body (3)**:
      ```
      Hi Team,

      I just received notification that our primary camping tent supplier, 
      Mountain Peak Manufacturing, is experiencing production delays due to 
      material shortages. This could impact our inventory levels significantly.

      Can you provide:
      1. Current inventory levels for all tent products from this supplier
      2. Our alternative supplier options based on our supplier qualification policy
      3. Recommended actions to mitigate supply chain risk

      This is urgent as we're heading into peak season.

      Thanks,
      [Your Name]
      ```

      - Click **Send (4)**

      ![](../Sandbox-Environment-Guides/Images/a110.png)

### Step 3: Monitor the Flow

After sending the email:

1. Navigate back to **Power Automate** [make.powerautomate.com](https://make.powerautomate.com).

1. Click on the **default Environment (1)** and then select **Amplify Environment<inject key="Deployment-ID" enableCopy="false"/> (2)** to switch the environment.

   ![](../Sandbox-Environment-Guides/Images/a111.png)

1. Navigate to **My flows (1)** and then click on **When a new email arrives (v3) (2)**.

   ![](../Sandbox-Environment-Guides/Images/a112.png)

1. Within 1-2 minutes, a new flow run should appear in Power Automate's run history (if monitoring). Click on it.

   ![](../Sandbox-Environment-Guides/Images/a113.png)

1. Typical execution time: 30 seconds to 2 minutes. Status should progress from **Running** to **Succeeded**

   ![](../Sandbox-Environment-Guides/Images/a114.png)

### Step 4: Review Response in Teams

1. Within 1-3 minutes of sending the email, you should receive a message from the agent in Teams. Navigate back to **Teams**.

   ![](../Sandbox-Environment-Guides/Images/b57.png)

1. The response should look similar to this. Including details regarding the triggered mail.

   ![](../Sandbox-Environment-Guides/Images/Agent2.png)

1. Copy any follow-up Question and paste it in chat window

1. It will ask for **Allow**, Please click on **Allow**

   ![](../Sandbox-Environment-Guides/Images/agentprompt.png)

    >Note: click on **Allow** for every Connect pop up.

1. Type **Allow** in chat window, then you will get response from agent

    ![](../Sandbox-Environment-Guides/Images/agent1.png)


### Congratulations! You have successfully completed the `Rapid Prototyping using GitHub Copilot` session and validated the Microsoft IQ solution across` Fabric IQ, Foundry IQ`, and `Work IQ`.


   



