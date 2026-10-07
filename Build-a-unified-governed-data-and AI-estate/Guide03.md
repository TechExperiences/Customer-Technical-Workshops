# Build a Unified, Governed data and AI estate Package

Now that you have deployed the generated template with GitHub Copilot, let’s explore a similar, pre-deployed solution. This will provide a ready-to-use foundation that can help you rapidly prototype, customize, and validate intelligent solutions for your business scenarios.

1. Navigate to the Azure portal. Click on **Resource group**.

   ![](../Sandbox-Environment-Guides/Images/amp52.png)

1. Select the pre deployed **rg-Buid-Unified** resource group.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u1.png)

1. You can see the already deployed resources.

   ![](../Build-a-unified-governed-data-and%20AI-estate/Images/u2.png)

## Step 1: Validate the Fabric Workspace

1. Click on the **App launcher (1)** and select **Microsoft fabric (2)** icon.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Navigate to **Workspaces**, there should be workspace created with the name similar to **Caldova-Pharma**. 

   ![](../Sandbox-Environment-Guides/Images/workspace-created.png)


## Step 2: Validate the Required Delta Tables Loaded into the Lakehouse

1. Select the created **Caldova-Pharma** Workspace.

1. Open the **Caldova_Lakehouse** lakehouse from the workspace.

1. In the **Explorer** pane, expand **Tables**.

1. Verify that the required tables are available in the lakehouse.

1. Select the **DimDate** table to open and review the table data which is ingested from Azure Blob storage.

   ![](/Sandbox-Environment-Guides/Images/LH-AnalyticalData.png) 

1. You can verify the created tables in the same Lakehouse which is ingested from Azure SQL Database.

   ![](/Sandbox-Environment-Guides/Images/LH-Operational.png) 

## Step 3: Validate Business Application Data Loaded into the Fabric SQL Database



