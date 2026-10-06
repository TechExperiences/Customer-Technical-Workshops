# Modernize with Confidence Package

Now that you have deployed the generated template with GitHub Copilot, let’s explore a similar, pre-deployed solution. This will provide a ready-to-use foundation that can help you rapidly prototype, customize, and validate intelligent solutions for your business scenarios.

1. Navigate to the Azure portal. Click on **Resource group**.

   ![](../Sandbox-Environment-Guides/Images/amp52.png)

1. Select the pre deployed **rg-MWC** resource group.

   ![](../Modernize-with-confidence/Images/m2.png)

## Migration From On-Prem SQL to Azure SQL DB Hyperscale

Migrate the pharmaceutical manufacturing database from on-premises SQL Server to Azure SQL Database Hyperscale to provide scalable, highly available, and cloud-based data management. The migration preserves critical manufacturing, product, inventory, production, and operational data while enabling improved performance, scalability, and integration with modern Azure analytics and AI services.

### Validation - Azure SQL DB Hyperscale

1. You can see all the resources and click on *Azure SQL Database Hyperscale* named **CaldovaOrderManagement**.

   ![](../Modernize-with-confidence/Images/m3.png)

1. Navigate to **Query editor (1)** to connect SQL Database.

   - To authorize user click on **Connect as odl_user_<inject key="Deployment-ID" enableCopy="false"/> (2)**

     ![](../Modernize-with-confidence/Images/m4.png)

1. Expand **Schema(dbo) (1)** -> **Tables (2)** -> and Click any table **(3)** to see data **(4)**.

   ![](../Modernize-with-confidence/Images/m5.png)

## Migration From On-Prem Web Application to Azure App Service 

Migrate the pharmaceutical manufacturing web application (Order Management) from on-premises infrastructure to Azure App Service to provide a scalable, secure, and highly available cloud-hosted platform. The migration enables improved application performance, simplified infrastructure management, and seamless integration with Azure services and the modernized Azure SQL Database backend.

### Validation - Azure App Service

Navigate back to Azure portal to validate the migrated web application and search for `rg-MWC` Resource Group. you can see App service resources along with SQL Database.

1. Navigate back to **rg-MWC** RG. Select the App Service named Click on **app-caldova-ordermgmt-xxxx**.

   ![](../Modernize-with-confidence/Images/m6.png)

1. You can see all app related information and click on **default domain**.

   ![](../Modernize-with-confidence/Images/m7.png)

1. It will open application in new tab and you can see migrated application.

   ![](../Modernize-with-confidence/Images/m8.png)

1. In migrated application you can see `Traditional Sql Search` section got added.

1. Click on **Traditional Sql Search** section.

   ![](../Modernize-with-confidence/Images/m9.png)   

1. Paste the below prompt in search area **(1)** and click on **Search (2)** button.   

   ```
   medicine used to reduce fever.
   ```

   ![](../Modernize-with-confidence/Images/m10.png)     

1. `You can observe it will return no results.`

   The migrated application currently uses traditional SQL search to find products based on exact text matches. Traditional SQL search typically relies on conditions such as LIKE, where the user's search terms need to closely match the words stored in the product description.

   For example, if a product description contains: `"Paracetamol is used to relieve mild pain."` and the user searches for: `"medicine used to reduce fever"`.

   - A traditional SQL `LIKE` search may not return the product because the exact phrase `"medicine used to reduce fever"` does not appear in the product description.

   - This creates a limitation for users because they often search using natural language, synonyms, or different words that express the same meaning.

1. To overcome this limitation, we will enhance the migrated application with **vector/semantic search** using Azure SQL Database Hyperscale and Azure OpenAI embeddings.

   - `Vector search` converts product descriptions and user search queries into numerical **embeddings** that represent their meaning. The application can then compare the similarity between the user's query and product descriptions instead of relying only on exact keyword matches.

     >**Note:** Will do Semantic search validation once next deployment(Vector embedding) is done.

1. In the next Section, we will:

   - Generate embeddings for the existing product descriptions using **Azure OpenAI**.
   - Store the generated embeddings in **Azure SQL Database Hyperscale** using the native `VECTOR` data type.
   - Generate an embedding for the user's natural-language search query.
   - Compare the query embedding with product-description embeddings using vector similarity.
   - Add a **Semantic/Vector Search** page to the migrated web application.
   - Display matching products along with their similarity/probability scores.
   - Add a visualization to demonstrate product search trends based on the vector-search results.

This allows us to demonstrate how the migrated application can move from **keyword-based search** to **meaning-based search** using Azure AI capabilities.

## Implementation of Vector/Semantic Search in Azure SQL Database Hyperscale

Implement vector search in Azure SQL Database Hyperscale using Azure OpenAI embeddings and the native VECTOR data type to enable natural-language product searches. Query and product embeddings are compared using vector similarity to identify relevant products beyond exact keyword matching, improving search accuracy and product discovery.

### Validation - Traditional SQL Search Vs Vector Semantic Search

1. Click on **Semantic Search (1)** section. Paste the same prompt in search area **(2)** and click on **search (3)** button. 

   ``` 
   medicine used to reduce fever
   ```

   ![](../Modernize-with-confidence/Images/m11.png) 

1. The semantic/vector search can identify products based on the meaning and semantic similarity of the query and product descriptions, even when the exact keywords are not present.

   ![](../Modernize-with-confidence/Images/m12.png) 


### Congratulations! You have successfully completed the Workshop.  