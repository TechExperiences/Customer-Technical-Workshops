# Build a Unified, Governed data and AI estate Package

Now that you have deployed the generated template with GitHub Copilot, let’s explore a similar, pre-deployed solution. This provides a ready-to-use foundation to review, validate, and understand how the solution brings together data, analytics, AI, governance, and security to address Caldova’s business needs.

1. Navigate to the Azure portal. Click on **Resource group**.

   ![](../Sandbox-Environment-Guides/Images/amp52.png)

1. Select the pre deployed **rg-Buid-Unified** resource group.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u3.png)

1. You can see the already deployed resources.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u4.png)

## Step 1: Validate the Fabric Workspace

The **Caldova-Build-Unify-xxxxx** Fabric workspace has already been created and configured. In this step, we will validate that the workspace is available and accessible in **Microsoft Fabric**.


1. Click on the **App launcher (1)** and select **Microsoft fabric (2)** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Navigate to **Workspaces (1)**, there should be workspace created with the name starting with  **Caldova-Build-Unify-**. Select the workspace. 

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u6.png)

1. See the created Fabric items.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u5.png)


## Step 2: Validate the Required Delta Tables Loaded into the Lakehouse

The required analytical and operational data has already been loaded into the Caldova_Lakehouse as Delta tables. In this step, we will validate that the required tables have been created successfully and that the data ingested from Azure Blob Storage and Azure SQL Database is available in the lakehouse.

The validation ensures that the data is ready for downstream analytics, reporting, and AI workloads.

1. Open the **Caldova_Lakehouse** lakehouse from the workspace.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u7.png)

1. In the **Explorer** pane, expand **Tables (1) > dbo (2)**.

   - Verify that the required tables are available in the lakehouse **(3)**.

     ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u8.png)   

1. Select the **DimDate** table to open and review the table data which is ingested from Azure Blob storage.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u9.png)

1. Scroll down, you can verify the created tables in the same Lakehouse which is ingested from Azure SQL Database.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u10.png)

## Step 3: Validate Business Application Data Loaded into the Fabric SQL Database

The business application data has already been loaded into the Fabric SQL Database from files stored in the Azure Storage Account. In this step, we will validate that the data has been loaded successfully and is available in the Fabric SQL Database for downstream applications, reporting, analytics, and AI workloads.

The data movement was orchestrated using an Azure Logic App, which served as the integration layer between Azure Storage and Fabric SQL Database.

1. To verify the created tables in Fabric SQL Database, navigate back to the **Caldova-Build-Unify-xxxxx** workspace.

1. Open the **Caldova_SQLDatabase**.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u11.png)

1. In the **Explorer** pane, expand **Caldova_SQLDatabase (1)** > **dbo (2)** and then expand **Tables (3)**.

   - Verify that the business application tables have been loaded successfully **(4)**.

      - **CustomerAddress**
      - **CustomerDetails**

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u12.png)

1. Navigate to the **Azure Portal** and open the **rg-Build-Unify** resource group.

1. Under **Resources**, verify that the integration components created for the data-loading process are available:

   - **caldova-businessapp-ingest** – Logic App responsible for orchestrating the data ingestion.
   - **sql** – API connection used to connect to the Fabric SQL Database.
   - **caldova-integration-account** – Integration Account used as part of the integration workflow.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u13.png)   
  
## Step 4: Validate the Semantic Model, Power BI Report, and Data Agent

The **Direct Lake semantic model and Data Agent** have already been created using the data from the **Fabric Lakehouse and Fabric SQL Database**. In this step, we will validate the semantic model and its table relationships, create a **Power BI report** using the semantic model, and validate the **Data Agent** to ensure it can provide business insights through natural language queries.

1. Navigate back to Fabric Portal and open the **Caldova-Build-Unify-xxxxx** Workspace.

1. Open the created **Semantic model**.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u14.png) 

1. Review the configured table relationships to ensure the data model is correctly connected.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u15.png) 

1. Navigate back the **Caldova-Build-Unify-xxxxx** Workspace, click on **Caldova_Unified_Report**.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u16.png)

1. Review the generated report.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u17.png) 

### Building Data Agent using Sementic Model.

1. Navigate back to the **Caldova-Build-Unify-xxxxx** Workspace. Click the created Data Agent named **Caldova_Unified_DataAgent**.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u18.png) 

1. Open the **Data** section and verify that the tables are selected and available to the Data Agent.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u24.png) 

   - If the tables are not selected, select the tables.

1. Open the **Test Agent** option.

1. Copy the following prompt and paste it into the test chat: 

   ```
   What is our average supplier lead time by supplier, and which supplier has the best quality rating?
   ```

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u19.png)   

1. Review the response provided by the **Data Agent**

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u20.png) 

## Step 5: Validate Governance and Security Using OneLake Catalog

The Caldova Pharma Fabric workspace and data assets are already available in Microsoft Fabric. In this step, we will use OneLake Catalog to validate the available governance and security capabilities, including data discovery, access management, ownership, sensitivity, lineage, and compliance across the Fabric environment.

1. Click **OneLake Catalog **(1)** and navigate to catalog page.

   - Landing page of OneLake Catalog with show items and sub-items for all the workspaces **(2)**.

     ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u21.png) 

1. Click the **Govern** tab to view key insights about the content you've created in Microsoft Fabric.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u22.png) 

1. Click the **Secure** tab where all users will be managed under one space and add, remove, and manage access accross all the domains and workspaces.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u23.png) 

   > **Perform a wide range of operations:** including data discovery, governance, security, monitoring, and lineage tracking across the enterprise data landscape through the centralized OneLake Catalog.

### Congratulations! You have successfully completed the Workshop.




