# Build a Unified, Governed data and AI estate CAIP Customer Workshops
*Overview about Build a Unified, Governed data and AI estate*

![](../Sandbox-Environment-Guides/Images/unifiedHome.png)

## In this workshop

In this hands-on technical workshop, you'll design and build a unified, open and governed data and AI estate with Microsoft Fabric, OneLake, Azure Integration Services, Power BI and Fabric Data Agent. You'll start with a whiteboarding session to agree on business goals, current challenges and priorities. Then you'll build a future-state design that:

- connects operational and analytical data without copying it more than necessary
- brings application data into the platform
- manages discovery, governance and security in one place
- gives reports and AI one trusted source of business meaning

## Caldova Scenario

Caldova is a pharmaceutical manufacturer and distributor that is expanding its product portfolio and markets. Its data covers customers, products, inventory, supply chain, sales, finance and operations. It's spread across business applications, databases and files, on both on-premises servers and cloud storage. Custom integrations, manual data preparation and separate reporting datasets have led to data silos, duplicate copies, inconsistent definitions, poor visibility and governance, and difficulty analyzing across business areas.

What this costs the business:

- Leaders can't answer cross-functional questions, such as how a supply disruption affects revenue, without reconciling data by hand.
- Adding a new product line, market or acquisition takes weeks instead of days, which directly slows expansion.
- Teams bring different numbers for the same metric to meetings, which erodes trust in reporting.
- Inconsistent controls raise compliance and data-protection risk in a highly regulated industry. The risk grows as each new market adds its own pharmaceutical regulations.
- AI and advanced analytics projects stall or produce unreliable results, so Caldova can't get value from forecasting, inventory optimization or AI-assisted decisions as fast as its competitors.

## How the Workshop Helps

The workshop takes each of Caldova's challenges and builds the matching Microsoft capability:

- **One shared foundation:** OneLake becomes the common foundation for operational and analytical data. Azure SQL Database stays the operational source, and Azure Blob Storage stays the home for analytical and source data.
- **Connecting sources without moving data:** Azure SQL Database is mirrored into the Lakehouse with Fabric Mirroring, and Blob Storage is reached through OneLake shortcuts, so the data doesn't need a separate physical copy. Data Factory is used only where data must be loaded, scheduled or transformed.
- **Bringing operational and analytical data together:** Bronze, Silver and Gold layers are used where needed to load, check, standardize and enrich data across the customer, product, sales, finance and supply-chain areas.
- **Open and interoperable:** OneLake, open ways of reaching the data and reusable governed assets keep the platform open as tools and processing engines change. This avoids lock-in and new silos.
- **Application integration:** Azure Logic Apps reads, checks and transforms the JSON data that business applications write, then loads it into Fabric SQL Database. Service Bus or Event Grid can be added for event-driven processing.
- **Governance and security:** The OneLake catalog gives one place to discover, govern, secure and reuse Lakehouses, SQL databases, semantic models and other Fabric assets. Fabric permissions control access.
- **Consistent business meaning:** Power BI reports and a Fabric Data Agent use the same governed semantic model, so people and AI tools see the same definitions.

## Workshop Outcomes

By the end of the workshop, participants will have:

- A unified, open and governed data foundation built with Fabric
- Low-copy connections to operational and analytical data through OneLake
- A way to bring application data into Fabric SQL Database
- Central discovery and access control through the OneLake catalog
- One trusted semantic layer for reporting and AI-driven insights

## Accessing your Sandbox Environment

1. Once you're ready to dive in, your Virtual machine and Guide will be right at your fingertips within your web browser.

    >**Note**: If prompted, click on **Accept** to Proceed.

     ![](../Sandbox-Environment-Guides/Images/amp12.png)

1. On your Virtual machine, click on the **Azure Portal** icon.

   ![](../Sandbox-Environment-Guides/Images/amp13.png)

1. You'll see the **Sign into Microsoft Azure** tab. Here, enter your credentials:

   - **Email/Username:** <inject key="AzureAdUserEmail"></inject>

     ![](../Sandbox-Environment-Guides/Images/amp15.png)

1. Next, provide your password:
 
   - **Password:** <inject key="AzureAdUserPassword"></inject>

     ![](../Sandbox-Environment-Guides/Images/amp16.png)

1. If a pop-up appears **Stay signed in**, then select **Yes**.

   ![](../Sandbox-Environment-Guides/Images/amp17.png)

1. You will return to this portal in the upcoming steps. Keep the portal open and proceed with the next steps.


### Now, click on **`Next >>`** to continue with **`Envisioning Session Using Whiteboarding`**.
