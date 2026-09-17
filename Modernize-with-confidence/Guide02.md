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


### Congratulations! You have successfully completed the `Rapid Prototyping using GitHub Copilot` session
