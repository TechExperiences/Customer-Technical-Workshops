# 2. Rapid Prototyping


Now that you have completed the envisioning **Whiteboard session** and identified key business opportunities, it is time to move from ideas to a working prototype. Explore how a intelligent solution can bring the envisioned scenario to life, validate its potential, and demonstrate how it could work in practice.

## Rapid Prototyping using GitHub Copilot

You will use GitHub Copilot to generate ARM or Bicep templates using the Future State Architecture arrived at from the previous Whiteboarding exercise.

- **ARM templates:** JSON-based Infrastructure-as-Code files used to define and deploy Azure resources.
- **Bicep templates:** Simplified, declarative Infrastructure-as-Code files used to define and deploy Azure resources with cleaner syntax.

### Step1: Verify Resources in the Azure Resource Group

1. Navigate to the [Azure portal](https://portal.azure.com/). Search for **Resource groups**. and Click on **rg-unified** Resource Group.

   ![](../Sandbox-Environment-Guides/Images/RG.png)

1.  Confirm that the resource group contains the following resources:
   - **Fabric Capacity**
   - **SQL Database** 
   - **SQL Server** 
   - **Storage Account**

   ![](../Sandbox-Environment-Guides/Images/rg-resource.png)

1. Verify that the resources are available in their respective Azure regions and that the migration environment has been provisioned successfully.


## Sign in to GitHub Copilot Chat

### Step 1: Creation Of Fabric Workspace

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

1. Navigate to **`C:\`** path **(1)**, then select the **Unifydata** folder **(2)** and then **Select folder (3)**.

   ![](../Sandbox-Environment-Guides/Images/unifyvscode.png)

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


1. Please copy the below prompt and paste it in the copilot chat win

   ```
   You are my Smart Agent supporting Caldova Pharma. I am planning to build a unified solution to improve business operations and decision-making.
 
   Please follow the instructions below to build Fabric Workspace:
   
   Instructions:
   
   Use existing Resource Group (rg-unified) and proceed further.
   
   Use existing storage account(storage2410878) and container inside this.
   
   Use existing Fabric Capacity (fabriccapacity2410878).
   
   Create a new Fabric Workspace (Caldova-Pharma) and attach capacity.
   
   Please provide Fabric admin access to the UPN (odl_user_2410878@sandboxailabs1002.onmicrosoft.com) to see the fabric workspace (Caldova-Pharma)

   ```

   - Then **Send (3)**.

    ![](../Sandbox-Environment-Guides/Images/unify_prompt.png)
   
1. Once Copilot starts generating the response, monitor the process closely. Do not take any action; simply watch the progress.

1. If Copilot Asks to aunthenticate like below, please click on provided link and provide the code which was given by copilot 

   ![](../Sandbox-Environment-Guides/Images/Login.png)

1. Click on Yes, completed and then click on **Submit** button
    
    ![](../Sandbox-Environment-Guides/Images/Login2.png)

1. After some time, Copilot may ask you a few questions. Review each question carefully and select the appropriate response. 

1. Monitor the process to understand how it generates the response and handles or resolves errors.  

   >**Note:** In between, if it asks you to **Continue to iterate**, please click **Continue**.
   
   >Wait for the deployment to complete.

1. Once the deployment is complete, you can verify the deployed resources by navigating to the resource group.

1. Navigate back to the Azure portal and Click on the **App launcher (1)** and select **Microsoft fabric** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Navigate to **Workspaces**, there should be workspace created with the name similar to **Caldova-Pharma**. 

   ![](../Sandbox-Environment-Guides/Images/workspace-created.png)


### Step 2: Loading Of Required Delta Tables Into Lakehouse 

1. Navigate back to Github Copilot 

1. Copy the below prompt and paste it in the chat window 

   ``` 
   Great. You have created Fabric Workspace (Caldova-Pharma). Now follow below instructions to create Lakehouse and delta table for Analytical data.
 
   Instructions:  
   
   Use above Resource Group, Azure Blob storage account, Fabric capacity, and Fabric Workspace.
   
   Create New Lakehouse (Caldova-Lakehouse) in the above Fabric workspace.  
   
   After Lakehouse is created, ingest data from Azure Blob and follow the steps below.
   
   Connect storage account(storage2410878) and Container (data)  
   
          a. Extract/Read analytical data from the Analytical folder exist under above container. 

          b. Load data (csv files) into the above created (Caldova-Lakehouse) using Shortcut technique.
   
   After completing above steps, please validate Lakehouse and all delta tables are created successfully.
   
   Great. Now you have created Fabric Lakehouse in the Workspace (Caldova-Pharma) and ingested data from Azure Blob  storage. Now follow the instructions below to ingest operational data from Azure SQL Database.
   
   Instructions:  
   
   Use the above Resource Group, Azure Blob storage account, Fabric capacity, Fabric Workspace, and Lakehouse  (Caldova-Lakehouse).  
   
   Connect to Azure SQL Server (sql-operational-2410878.database.windows.net) and its Database (OperationalData)  
   
   Use UPN: odl_user_2410878@sandboxailabs1002.onmicrosoft.com to connect above SQL Server and Database to read/  ingest Operational data into Lakehouse  
   
   Create Fabric Mirrored Database and connect to Azure SQL Server for Operational Data.
   
   Ingest data and create delta tables in the above created Lakehouse using shortcut pointing to Mirrored database.
   
   After completing the above steps, please validate Lakehouse. All delta tables are created successfully and data moved from Azure SQL Database.  
   ```

1. Monitor the process to understand how it generates the response and handles or resolves errors.  

   >**Note:** In between, if it asks you to **Continue to iterate**, please click **Continue**.
   
   >Wait for the deployment to complete.

1. Once the deployment is complete, you can verify the craeted Lakehouse in fabric workspace.

1. Navigate to the **Microsoft Fabric** portal and Open the **Caldova_Lakehouse** lakehouse from the workspace.

1. In the **Explorer** pane, expand **Tables**.

1. Verify that the required tables are available in the lakehouse.

1. Select the **DimDate** table to open and review the table data. 

   ![](../Sandbox-Environment-Guides/Images/LH-Analyticaldata.png)

1. Navigate back to Github Copilot 

1. Copy the below prompt and paste it in the chat window 

   ```
   Great. Now you have created Fabric Lakehouse in the Workspace (Caldova-Pharma) and ingested data from Azure Blob storage. Now follow the instructions below to ingest operational data from Azure SQL Database.
 
   Instructions:  
   
   Use the above Resource Group, Azure Blob storage account, Fabric capacity, Fabric Workspace, and Lakehouse (Caldova-Lakehouse).  
   
   Connect to Azure SQL Server (sql-operational-2410878.database.windows.net)    and its Database (OperationalData)  
   
   Use UPN: odl_user_2410878@sandboxailabs1002.onmicrosoft.com to connect  above SQL Server and Database to read/ingest Operational data into    Lakehouse  
   
   Create Fabric Mirrored Database and connect to Azure SQL Server for  Operational Data.
   
   Ingest data and create delta tables in the above created Lakehouse using   shortcut pointing to Mirrored database.
   
   After completing the above steps, please validate Lakehouse. All delta  tables are created successfully and data moved from Azure SQL Database.  

   ```




### Congratulations! You have successfully completed the `Rapid Prototyping using GitHub Copilot` session and validated the Microsoft IQ solution across` Fabric IQ, Foundry IQ`, and `Work IQ`.