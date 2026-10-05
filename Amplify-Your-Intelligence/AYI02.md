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

   > **&lt;TODO&gt;:** If the project folder name changes, update it in this step and screenshot.

1. From the **GitHub Copilot Chat**, select **Models (1)** and then select **Trust Workspace to enable models (2)**.

   ![](../Sandbox-Environment-Guides/Images/b6.png)

1. Select **Trust Folder and Continue**.

   ![](../Sandbox-Environment-Guides/Images/amp30.png)

1. Click **Auto (1)**, then click **Other Models (2)** to expand the list of available models.

   ![](../Amplify-Your-Intelligence/Images/14.png)

1. Select **Claude Fable 5.1 (1)**, then set the thinking effort to **High (2)** and the context to **1M (3)**.

   ![](../Amplify-Your-Intelligence/Images/15.png)

    >**Note:** If you're unable to select the **Models**, please wait for `2-3 minutes` then check and make sure you're signed in properly.

1. Click on **Default permission (1)** and then set it to **Allow all (2)**.

   ![](../Sandbox-Environment-Guides/Images/b8.png)

1. Select **Enable**.

   ![](../Sandbox-Environment-Guides/Images/amp33.png)

1. Select the approved **Caldova-Future-State-Architecture.png** image.

   ![](../Amplify-Your-Intelligence/Images/18.png)

1. From the **GitHub Copilot Chat**, click on **+ (1)** and then select the approved **Caldova-Future-State-Architecture.png (2)**.

   ![](../Sandbox-Environment-Guides/Images/b89.png)

### Fabric IQ

1. Along with the attached **Solution Architecture** (1), please paste the below prompt (2).

   ```
   You are my smart agent to read my attached architecture design for Caldova Pharmaceutical and its November NextGen Pharma product launch and create bicep/ARM template based on the identified Fabric resources.
 
   Please follow these below instructions for Fabric IQ section:
   0. Before deployment, detect the existing Python interpreter and verify pip is available. Install only the dependencies required by the generated scripts through the terminal, using the same interpreter for installation and execution. Reuse an existing virtual environment if available; creating one is optional. Verify the required imports before continuing. If installation fails, inspect the actual pip error and attempt a targeted fix instead of repeatedly retrying VS Code's Python Environments tool. Where supported, run long-running terminal commands in the background when independent work can continue. Check their output and successful completion before running dependent steps or reporting deployment complete.
   1. List down all the Azure resources required for the Fabric IQ section of the attached architecture diagram.
   2. Use existing Resource Group (rg-caldova-iq) and proceed further.
   3. Use existing Fabric Capacity (fabriccapacity<inject key="Deployment-ID" enableCopy="false"/>).
   4. Create a new Fabric Workspace (Caldova-Pharma) and attach capacity.
   5. Please provide Fabric admin access to the UPN <inject key="AzureAdUserEmail"></inject> to see the fabric workspace (Caldova-Pharma)
   6. Create Lakehouse and use GitHub Copilot to generate and store sample data into tables for the Fabric data sources shown in the architecture: Plant Capacity & Commitments, Batch Schedules & Changeovers, Equipment & Fill-Finish Availability, Product & Inventory Data, Demand Forecasts, Supplier & CMO Capacity, Quality & CMO Evaluation Records, Launch & Competitive Products, and RFP Status. Keep these as tables in the same Lakehouse; no external database connections are required.
      Keep shared IDs, dates and production units consistent across tables. Include required launch production, committed production, maximum plant capacity, equipment qualification windows, fill-finish availability and feasible internal schedule recovery.
      Generate data for the same November launch planning period across three plants, with a 7% network production shortfall (about 18,900 units), Plant 3 as the binding constraint, and insufficient internal recovery to fully close the gap. Document and validate the shortfall calculation using required launch production as the denominator. Include available capacity and qualification records for pre-qualified CMOs to support evaluating external manufacturing options.
   7. Create Fabric Ontology using above Lakehouse tables with proper entities and relationships to show the business model. Graph materialization is not required for this workshop.
   8. Create the Data Agent using the Lakehouse tables as its data source and prepare appropriate Agent Instructions. Instruct it to calculate committed production versus maximum capacity by plant, the network shortfall and feasible internal recovery, identify the constrained plant, and assess whether external CMO capacity is needed for the November launch. Show calculations, units and the planning period; do not hard-code answers. Perform one quick test for the November shortfall and internal recovery without creating a separate verification script.
   
   Note: After complete all above steps successfully, create MD(mark down) file with deployment instructions and post deployment configurations, and start deployment(create workspace, create lakehouse, table creation, sample data insertion, ontology creation, data agent creation)
   ```

   - Then **Send (3)**.

    ![](../Amplify-Your-Intelligence/Images/19.png)
   
1. Once Copilot starts generating the response, monitor the process closely. Do not take any action; simply watch the progress.

1. If Copilot asks you to choose how to proceed with the existing workspace, select the recommended option similar to the one marked below.

   ![](../Amplify-Your-Intelligence/Images/20.png)

1. If Copilot asks how to handle the ontology data source for the Data Agent, select the recommended option: **Keep Lakehouse fallback + document UI step**

   - Then click **Submit** to continue.

   ![](../Amplify-Your-Intelligence/Images/21.png)
1. After some time, Copilot may ask you a few questions. Review each question carefully and select the appropriate response. 

1. Select **Yes**, if any question prompts you to respond related to `F16` deployment.

   ![](../Sandbox-Environment-Guides/Images/b13.png)

   > **&lt;TODO&gt;:** Replace this screenshot with the Caldova F16 deployment confirmation using Fable 5.1.

1. If prompted to provide the UPN for assigning **Fabric Administrator access**, enter **<inject key="AzureAdUserEmail"></inject> (1)** and then select **Submit (2)**. 

    ![](../Sandbox-Environment-Guides/Images/b14.png)

    > **&lt;TODO&gt;:** Replace this screenshot with the Caldova deployment and lab user access prompt using Fable 5.1.

1. Monitor the process to understand how it generates the response and handles or resolves errors.  

   >**Note:** In between, if it asks you to **Continue to iterate**, please click **Continue**.

1. Wait for the deployment to complete. This may take approximately `20–30` minutes. Once completed, you will see a Summary/Conclusion similar to the example below, although the details may vary **(1)** and select **Keep (2)** to keep the created files.

   ![](../Amplify-Your-Intelligence/Images/21.png)

    >**Note:** The **Summary/Conclusion** may look different for you. Once the deployment is completed, you will be able to view the results in the chat.

1. Once the deployment is complete, you can verify the deployed resources by navigating to the existing **rg-Caldova-iq** resource group.

1. Navigate to the Azure portal and click **Resource groups**. Open **rg-Caldova-iq** to verify the deployed resources.

   ![](../Amplify-Your-Intelligence/Images/23.png)


1. Select the **existing Resource Group used for the deployment**. Do not select the resource groups highlighted below.

   ![](../Amplify-Your-Intelligence/Images/24.png)

1. You should see the deployed Fabric capacity.

   ![](../Amplify-Your-Intelligence/Images/25.png)

1. Click on the **App launcher (1)** and select **Microsoft fabric** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Navigate to **Workspaces**, there should be workspace created with the name similar to **Caldova**.

   - If your unable to see. Please go back to the **GitHub Copilot Chat**.

     ![](../Sandbox-Environment-Guides/Images/b18.png)

      >**Note:** Not the one which starts with **Microsoft IQ**.

1. **Optional: Fix workspace access.** If the newly created Caldova workspace is not visible in the Fabric portal, send the following prompt in the **same GitHub Copilot conversation**. If the workspace is already accessible, skip this step and the next access-fix completion step.

   ```
   I cannot see the Caldova workspace created by the previous deployment in the Fabric portal.

   Using deployment-output.json and the existing deployment identity:
   1. Verify that the workspace exists through the Fabric API and report its workspace ID and tenant ID.
   2. Resolve the lab user <inject key="AzureAdUserEmail"></inject> to the correct user object ID in that tenant.
   3. Grant this user Admin access to the existing workspace, preserving existing access.
   4. Verify the user's workspace role assignment and confirm the workspace is attached to the deployed F16 capacity.
   5. Provide the direct workspace URL and report the actual API verification results.

   Reuse the existing resources. Do not recreate the workspace, reload data, or rerun the full deployment. This request is for workspace access, not a tenant-wide Fabric Administrator role.
   ```

    ![](../Amplify-Your-Intelligence/Images/26.png)   

1. Wait for the process to complete.


1. Now please go back to the Fabric portal, refresh the portal and navigate to the **Workspaces**. Now you should be able to see a Workspace which starts with something similar to `Caldova`.

   ![](../Amplify-Your-Intelligence/Images/27.png)

1. Open the **Caldova** workspace.

1. Make sure that all the workspace items mentioned in the prompt are created. 

   ![](../Amplify-Your-Intelligence/Images/28.png)

1. Please open each item and verify that it has been created correctly. If anything is missing, go back to the **GitHub Copilot Chat** and provide a follow-up prompt to address the missing item.  

1. In this case, when I opened the workspace. There are no tables created in the Lakehouse.

   ![](../Amplify-Your-Intelligence/Images/29.png)

1. Navigate back to the **GitHub Copilot Chat** to send the follow up prompt.

   ```
   Issues identified with the workspace items, please fix this issue.

   No table has been created in the Lakehouse, and no sample data has been loaded.
   The Ontology was created, but no entities or relationships have been added.
   The Ontology has not been configured as the Data Source for the Data Agent.
   ```
    ![](../Amplify-Your-Intelligence/Images/30.png)

1. Wait for the process to complete and click **Keep** to keep the file.

1. Navigate back to the Fabric workspace, refresh the Lakehouse, and verify that the tables have been created and the sample data has been loaded successfully.

   ![](../Amplify-Your-Intelligence/Images/31.png)

1. Open the **Ontology** item and verify that the entities and relationships have been created successfully.

   ![](../Amplify-Your-Intelligence/Images/32.png)

1. Open the **Data Agent** from the workspace. If the **Ontology** can be added as the Data Source and the Data Agent queries work, keep it. Otherwise, use the existing **Lakehouse** as the Data Source in the next step.

1. If adding the ontology fails or the Data Agent queries do not work with it, use the existing **Caldova Lakehouse** as the Data Source. You can ask **GitHub Copilot Chat** to update the existing Data Agent, or follow the steps below.

   - Navigate back to the **Fabric workspace** and open the **Data Agent**. Remove the failing **Ontology** Data Source and add the existing **Lakehouse**; select all nine Caldova story tables. Keep the ontology item in the workspace.

   - Click on the **elipses (1)** and then **Remove (2)**.

     ![](../Amplify-Your-Intelligence/Images/33.png)

   - Click **Yes, remove**. 

   - Select **Add data (1)** drop down and then **Data source (2)**.

     ![](../Amplify-Your-Intelligence/Images/34.png)   

   - Select the existing **Caldova Lakehouse (1)** and then **Add (2)**. Select all nine story tables and include their join keys and calculation guidance in the Data Agent instructions.

     ![](../Amplify-Your-Intelligence/Images/36.png)        

1. Confirm the working Data Source is added: keep the **Ontology** if it works; otherwise, confirm the **Caldova Lakehouse** and all nine story tables are selected.

   ![](../Amplify-Your-Intelligence/Images/37.png)

1. Navigate to **Test data agent (1)**, send the following prompts in Data agent input box **(2)**:

   ```
   For the November NextGen Pharma launch, show required production, committed production and maximum capacity by plant. Calculate the network shortfall in units and as a percentage of required production. Which plant is the main constraint, how much can feasible internal recovery close, and what gap remains? Show the calculation, planning period and units from the data.
   ```

   ![](../Amplify-Your-Intelligence/Images/38.png)   

   ```
   Which pre-qualified CMOs have available capacity to help close the remaining November NextGen Pharma launch gap? List their available capacity, qualification status and current RFP status. Compare capacity with the remaining gap using the same planning period and units. If a required value is missing, state that rather than assuming it.
   ```

   ![](../Amplify-Your-Intelligence/Images/39.png)    

1. Click on **Publish**.

   ![](../Sandbox-Environment-Guides/Images/b65.png)  

   > **&lt;TODO&gt;:** Replace this screenshot with publication of the Caldova data agent and current test results.

1. Click on **Publish** again to publish the data agent.

   ![](../Sandbox-Environment-Guides/Images/b66.png)  

   > **&lt;TODO&gt;:** Replace this screenshot with the Caldova data agent publication dialog.

### Foundry IQ    

1. Navigate back to the **GitHub Copilot Chat** to deploy the **Foundry resources**.

1. Navigate back to the **GitHub Copilot Chat** 

1. Copy the prompt below into the chat and send.

   ```
   Read the attached Caldova Pharmaceutical architecture for the November NextGen Pharma launch, generate the required Bicep/ARM templates, and deploy the Foundry IQ section.

   0. Where supported, run long-running terminal commands in the background when independent work can continue. Check their output and successful completion before running dependent steps or reporting deployment complete.

   1. List the Foundry-related resources required by the diagram.

   2. Deploy them in the existing rg-caldova-iq Resource Group, using Sweden Central.

   3. Create model deployments for gpt-5-mini and text-embedding-3-small.

   4. Generate four short, text-based PDFs: Supplier Terms; CMO Qualification & Evaluation; GMP & Manufacturing Changeover Guidance; and Manufacturing Quality Guidance. Label them fictional demo content. Use company, product, plant and CMO names/IDs from the existing Caldova data, with illustrative terms/processes consistent with the launch story. Keep changing capacity, demand and RFP figures in Fabric; do not present demo policies as regulatory requirements.

      Reuse the deployment storage account, or create one in the same Resource Group if absent. Upload to a caldova-documents Blob container without replacing unrelated documents. Create a shared Azure AI Search-backed knowledge base for the PDFs using the original Blob ingestion pattern. Verify readable text and successful upload/indexing.

      Configure Web IQ as Foundry's native Web Search tool directly in agent Tools, not as URL knowledge sources or through the knowledge-base MCP connection. Restrict search to these URLs using supported URL/site configuration, with Bing Custom Search where required:
      - https://www.fda.gov/drugs/pharmaceutical-quality-resources/facts-about-current-good-manufacturing-practice-cgmp
      - https://www.fda.gov/regulatory-information/search-fda-guidance-documents/contract-manufacturing-arrangements-drugs-quality-agreements-guidance-industry
      - https://www.ema.europa.eu/en/scientific-guidelines/ich-q10-pharmaceutical-quality-system

      Return source citations. Use public sources only for general GMP, quality agreements and quality/change management. Ground Caldova's 7% gap, plant/CMO capacity, qualification status, launch dates, demand and competitor facts in Fabric, and fictional terms/processes in the PDFs. Public guidance must not add scenario constraints or imply Caldova plant/CMO approval or compliance.

   5. Create four agents sharing the model deployments and PDF knowledge base, with focused instructions:
      - Supplier Terms Agent: supplier terms, contract obligations and qualification documents.
      - CMO Evaluation Agent: CMO qualification, capacity, evaluation records and RFP status.
      - Demand Sensing Agent: demand forecasts, required versus committed production and launch/competitive products.
      - Manufacturing Quality Agent: quality, equipment availability, fill-finish/changeover constraints and GMP guidance.

      Attach Web Search to Supplier Terms, CMO Evaluation and Manufacturing Quality agents only.

      Include instructions to use the existing Lakehouse-backed Caldova Fabric Data Agent for operational data once manually connected. Do not attach or test it during deployment; I will connect it through Tools → Fabric IQ (OneLake Catalog). Do not recreate Fabric resources or require ontology graph materialization. Use relevant document/web sources without hard-coding answers or inventing operational figures when Fabric is not connected.

   6. Run one quick PDF-grounded test per agent and one public-web test per web-enabled agent. Verify document/allowed-source citations and Web Search invocation. Example web question: "What is GMP and why does it matter in drug manufacturing?"

      Do not attempt Fabric connections or queries. Record actual results, failures and the manual Fabric connection step in the deployment MD. Report deployment outcome and agent names/IDs. Do not create a separate verification script or wait for manual UI verification.

   Note: Create a deployment MD with deployment instructions and post-deployment configuration, including how to manually connect the existing Fabric Data Agent to each Foundry agent.
   ```

   > **&lt;TODO&gt;:** Update the following Foundry screenshots and agent-selection labels to show the four Caldova agents and their shared Fabric, knowledge-base and Web IQ connections.

1. Wait for the deployment to complete and the **Keep** the file.

   ![](../Sandbox-Environment-Guides/Images/b38.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova Foundry deployment results and Keep action.

1. Navigate back to the Resource group. Select the **Foundry Project**.

   ![](../Sandbox-Environment-Guides/Images/b39.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova resource group and Foundry project.

1. Click On **Go to Foundry portal**.

   ![](../Sandbox-Environment-Guides/Images/b40.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show Go to Foundry portal for the Caldova project.

1. Click on **Build**.

   ![](../Sandbox-Environment-Guides/Images/b41.png)  

1. Navigate to **Models (1)** and make sure 2  models are deployed **(2)**,

   ![](../Sandbox-Environment-Guides/Images/b42.png)  

1. Navigate to **Agents** and confirm these four agents appear: **supplier-terms-agent**, **cmo-evaluation-agent**, **demand-sensing-agent**, and **manufacturing-quality-agent**. Open **supplier-terms-agent** first.

   ![](../Sandbox-Environment-Guides/Images/b43.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show the four Caldova agents and selection of supplier-terms-agent.

1. Make sure the model is set to **gpt-5-mini**. Check whether the published **Caldova_Launch_Readiness_Agent** is already connected under **Tools**; if it is, keep that connection. Otherwise, add it below.

   ![](../Sandbox-Environment-Guides/Images/b44.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova agent's model and Fabric Data Agent tool.

   - In **Instructions**, retain the supplier-terms guidance and ensure it tells the agent to use **Caldova_Launch_Readiness_Agent** for capacity, qualification status and RFP data, and document knowledge for fictional supplier terms. Do not hard-code answers.

     ![](../Sandbox-Environment-Guides/Images/b45.png)  

     > **&lt;TODO&gt;:** Replace this screenshot with the Caldova agent instructions; the old model-switch workaround is no longer part of this step.

   - To add the missing connection, scroll to **Tools**, select **Add**, then **Browse all tools** (or **Add tools**).

     ![](../Sandbox-Environment-Guides/Images/b46.png)  

     > **&lt;TODO&gt;:** Update this screenshot to show the current Add tools menu.

   - Select **Fabric IQ (OneLake Catalog)**, then **Add tool**.

     ![](../Sandbox-Environment-Guides/Images/a32.png)      

     > **&lt;TODO&gt;:** Update this screenshot to show the current Fabric IQ tool selection.

   - In the catalog, filter **Type** to **Data agent**, select the published **Caldova_Launch_Readiness_Agent** from your Caldova workspace, and click **Add**. Complete any sign-in with the same lab account used in Fabric, then **Save** the Foundry agent.

     ![](../Sandbox-Environment-Guides/Images/b47.png)          

     > **&lt;TODO&gt;:** Replace this screenshot with selection of the published Caldova Data Agent instead of the old retail ontology.

1. Scroll down to **Knowledge** and verify that the shared knowledge source for the Caldova demo PDFs is attached. Also confirm the configured public-Web IQ source/tool is present in **Knowledge** or **Tools**, as appropriate for the deployed integration.

   ![](../Sandbox-Environment-Guides/Images/b48.png)  

   > **&lt;TODO&gt;:** Update this screenshot to show the Caldova document knowledge and configured public-web grounding.

1. Test **supplier-terms-agent** with questions about its documents and Fabric data. Confirm document answers include citations and data answers use **Caldova_Launch_Readiness_Agent**. After testing it, repeat the relevant tool, knowledge and response checks for **cmo-evaluation-agent**, **demand-sensing-agent**, and **manufacturing-quality-agent**, keeping each agent's focused instructions.

1. For getting the prompts, you can go back to **GitHub Copilot Chat**, and send the below query:

   > **&lt;TODO&gt;:** Remove this generic prompt-generation step; use the Caldova agent tests below.

   ```
   Can you please provide some of the prompts to test the foundry agent.
   ```

   ![](../Sandbox-Environment-Guides/Images/b49.png) 

1. Once the prompts are generated, you can go back to the Foundry Agent **Chat** section and paste the prompts to see the results.

   > **&lt;TODO&gt;:** Remove this old testing step and replace its screenshots with the Caldova agent tests below.

   ![](../Sandbox-Environment-Guides/Images/b51.png)  

   ![](../Sandbox-Environment-Guides/Images/b52.png)  

   ![](../Sandbox-Environment-Guides/Images/b53.png)     

1. With **supplier-terms-agent** open, use its **Chat/Playground** to run these prompts separately. The published **Caldova_Launch_Readiness_Agent** was connected in step 10; keep that connection and the shared document knowledge.

   ```
   From the Caldova demo documents, summarize the supplier terms and CMO qualification/evaluation process relevant to supporting the November NextGen Pharma launch. Cite the documents and distinguish fictional workshop terms from public guidance. State any missing information.
   ```

   ```
   Use Caldova_Launch_Readiness_Agent to list the pre-qualified CMOs, their available capacity and current RFP status for the November NextGen Pharma launch. Show the planning period and units from the data. Do not assume missing values or replace data with document examples.
   ```

   Confirm document citations in the first answer and a Fabric Data Agent tool call in the second, using the response activity/trace where available.

   > **&lt;TODO&gt;:** Add screenshots of the Supplier Terms Agent's document and Fabric answers.

1. In **supplier-terms-agent**, run this Web IQ prompt:

   ```
   Use the connected public-web source to explain the purpose of a quality agreement between a drug owner and a contract manufacturer, based on the FDA Contract Manufacturing Arrangements for Drugs guidance. Cite the public URL. Keep this general explanation separate from Caldova's fictional supplier terms and do not infer that any Caldova CMO is approved.
   ```

   Confirm the answer cites the FDA public source.

   > **&lt;TODO&gt;:** Add a screenshot of the Supplier Terms Agent's cited Web IQ answer.

1. Open **cmo-evaluation-agent**. For its capacity, qualification and RFP questions, confirm **Caldova_Launch_Readiness_Agent** is connected under **Tools**. If missing, repeat the connection in step 10 as done for **supplier-terms-agent**, retaining this agent's CMO evaluation instructions. Check its shared document knowledge as in step 11, save, and run:

   ```
   Use Caldova_Launch_Readiness_Agent to calculate the remaining November NextGen Pharma production gap after feasible internal recovery. Compare it with available capacity from pre-qualified CMOs for the same period and units, including qualification/evaluation records and RFP status. Use the Caldova CMO demo documents to explain the evaluation process with citations. Distinguish available capacity from capacity already committed, and state missing evidence before recommending an option.
   ```

   Confirm the numbers come from a Fabric tool response and process explanations cite the demo documents.

   > **&lt;TODO&gt;:** Add a screenshot of the CMO Evaluation Agent's grounded comparison.

1. In **cmo-evaluation-agent**, run this Web IQ prompt:

   ```
   Using the connected public-web source and the FDA quality-agreements guidance, summarize the general quality responsibilities an owner and contract manufacturer should document when establishing a manufacturing arrangement. Cite the public URL. Do not change Caldova's CMO qualification status, capacity or RFP results.
   ```

   Confirm the answer cites the FDA public source.

   > **&lt;TODO&gt;:** Add a screenshot of the CMO Evaluation Agent's cited Web IQ answer.

1. Open **demand-sensing-agent**. It requires **Caldova_Launch_Readiness_Agent** for forecast and launch data. If the tool is missing, repeat step 10, retaining its demand-sensing instructions, then save. Run:

   ```
   Use Caldova_Launch_Readiness_Agent to compare required and committed production for the November NextGen Pharma launch across the three plants. Calculate the shortfall in units and as a percentage of required production, showing the formula and planning period. Identify the main constrained plant and summarize relevant launch/competitive-product records from the data. If market impact cannot be calculated from the available fields, state what is missing rather than inventing it.
   ```

   Confirm a Fabric tool call and data-derived calculations.

   > **&lt;TODO&gt;:** Add a screenshot of the Demand Sensing Agent's calculated launch shortfall.

1. Open **manufacturing-quality-agent**. Confirm **Caldova_Launch_Readiness_Agent** is connected for equipment, production and quality records. If missing, repeat step 10, retaining its manufacturing-quality instructions. Check the shared Caldova manufacturing/quality document knowledge as in step 11, save, and run:

   ```
   Use Caldova_Launch_Readiness_Agent to identify the plant and equipment constraints affecting November NextGen Pharma production and feasible internal recovery, considering batch schedules/changeovers, equipment fill-finish availability and available quality records. Use the Caldova demo guidance to explain any documented changeover review or sign-off steps, with citations. Separate data-supported recovery from assumptions and state missing information; do not invent downtime, approval status or additional capacity.
   ```

   Confirm a Fabric tool call and document citations for any process/sign-off explanation.

   > **&lt;TODO&gt;:** Add a screenshot of the Manufacturing Quality Agent's grounded constraint and recovery answer.

1. In **manufacturing-quality-agent**, run these Web IQ prompts separately:

   ```
   Use the connected public-web source to explain what GMP is and why it matters in drug manufacturing, based on the FDA CGMP overview. Cite the public URL and do not claim that Caldova's plants or CMOs are compliant.
   ```

   ```
   Use the connected public-web source to summarize the purpose of change management in a pharmaceutical quality system, based on EMA's ICH Q10 guidance. Cite the public URL. Keep the explanation separate from Caldova's fictional changeover process and do not introduce new launch constraints.
   ```

   Confirm the answers cite the corresponding FDA/EMA public sources.

   > **&lt;TODO&gt;:** Add screenshots of the Manufacturing Quality Agent's cited FDA and EMA answers.

## Work IQ

The third component of the accelerator is Work IQ (the Copilot Studio email-triggered agent that orchestrates Fabric IQ and Foundry IQ from a single conversational ingress)

### Steps that need to be performed:

- **Import the solution:** Import the Power Platform zip solution file inside the solution file folder into your Power Platform environment
- **Configure connections:** Sign in to and authorize the Work IQ, Microsoft Teams, Copilot Studio, Office 365 Outlook, Fabric Data Agent, and Foundry Agent connections. 
- **Configure the email trigger** in the Power Automate flow — select the target inbox/folder to monitor and (optionally) add a subject filter such as **Caldova Request**.
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

   > **&lt;TODO&gt;:** Update this screenshot to show browsing for the actual workshop solution ZIP.

1. Navigate to **C:\Files (1)**, then select the supplied workshop solution ZIP (**MicrosoftIQAccelerator (2)** in the current screenshot, or its renamed filename) and then **Open (3)**.

   ![](../Sandbox-Environment-Guides/Images/a54.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the actual solution ZIP filename and folder path.

1. Once the Solution file is imported, click on **Next**.

   ![](../Sandbox-Environment-Guides/Images/a55.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the solution details for the actual workshop ZIP.

1. Click on **Next** again.

   ![](../Sandbox-Environment-Guides/Images/a56.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the next import screen for the actual workshop ZIP.

1. Make sure you are signed in and a green check mark is showing up for all the services **(1)** and then click on **Import (2)**.

   ![](../Sandbox-Environment-Guides/Images/a57.png)

1. Wait for the Solution to import successfully, it may take `2-3 minutes`.

   ![](../Sandbox-Environment-Guides/Images/a58.png)

   > **&lt;TODO&gt;:** Update this screenshot to show import completion with the renamed solution.

1. After importing has completed, click **Publish all customizations** in the top menu.    

   ![](../Sandbox-Environment-Guides/Images/a59.png)

   > **&lt;TODO&gt;:** Update this screenshot to show Publish all customizations with the renamed solution.

1. Wait for publishing to complete. 

   ![](../Sandbox-Environment-Guides/Images/a60.png)

   > **&lt;TODO&gt;:** Update this screenshot to show publication completion with the renamed solution.

1. When the import is complete, the solution will be available in the environment.

### Step 2: Configure the Email Trigger

Once connections are set, configure the Power Automate flow to monitor the correct inbox:

1. Navigate to **Solutions (1)** then select the imported workshop solution (**Microsoft IQ Accelerator (2)** in the current screenshot, or its renamed solution name).

   ![](../Sandbox-Environment-Guides/Images/a61.png)

   > **&lt;TODO&gt;:** Update this screenshot to show the renamed imported workshop solution.

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

1. Optionally add a `Subject Filter` to limit which emails trigger the flow. You can provide **Caldova Request** **(1)** and then **Save (2)** the flow.

   ![](../Sandbox-Environment-Guides/Images/a69.png)

   > **&lt;TODO&gt;:** Update this screenshot to show Caldova Request in the Subject Filter.

### Step 3: Add the External Agents in Copilot Studio   

After import, add the Fabric and Foundry agents again in Copilot Studio. Use Fabric for operational data questions and the four Foundry specialists for Caldova supplier terms, CMO evaluation, demand sensing and manufacturing quality. If they do not appear yet, finish deploying Fabric and Foundry first, then return to Copilot Studio and refresh the agent list.

### 3.1 Add the Foundry Agents

Connect the four agents already deployed in the **caldova-nextgen-launch** Foundry project. Start with **Supplier Terms Agent**, then repeat the connection steps for the other three using the same project connection.

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

     ![](../Sandbox-Environment-Guides/Images/b69.png)

   > **&lt;TODO&gt;:** Replace the Retail Agent details in this screenshot with Supplier Terms Agent and its actual Agent Id.

1. Click **Back**.

   ![](../Sandbox-Environment-Guides/Images/b70.png)

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

1. Open the main agent's **Overview → Instructions**. Replace only obsolete references to the previous **Retail Agent / Foundry Chat Agent** with the routing guidance below. Keep the existing Work IQ, Fabric and email-flow instructions. Use **/** in the instruction editor to select each connected agent by its actual name.

   ```text
   For Caldova November launch questions, use Supplier Terms Agent for supplier terms and contract or qualification requirements; CMO Evaluation Agent for comparing qualified external CMOs, available capacity and RFP status; Demand Sensing Agent for demand forecasts and the required-versus-committed production gap; and Manufacturing Quality Agent for equipment, fill-finish, changeover and quality constraints. For questions spanning these areas, combine the relevant agents' findings. Show the units, planning period and calculations for operational figures, retain source links, and distinguish Caldova demo evidence from general public guidance. If a required source or tool fails, state what could not be verified instead of inventing an answer.
   ```

   > **&lt;TODO&gt;:** Add a screenshot of the updated Caldova routing instructions.

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


   



