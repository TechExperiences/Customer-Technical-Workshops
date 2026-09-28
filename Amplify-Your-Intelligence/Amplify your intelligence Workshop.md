# Microsoft Technical Workshop: Amplify Your Intelligence with Microsoft IQ

## Overview

**Workshop Purpose:** This workshop helps technical teams envision and prototype a shared intelligence foundation for AI agents. Using Caldova Pharmaceutical's accelerated product launch as the scenario, you will explore how Microsoft IQ brings together manufacturing data, enterprise knowledge, external market information, and organizational context to support grounded decisions.

![](../Sandbox-Environment-Guides/Images/AmplifyImg.png)

### The Caldova launch challenge

Caldova's leadership has approved an accelerated launch of its **NextGen Pharma product in November 2026**. A competitor is targeting the same launch window, and Caldova faces a **7% production-capacity gap across three plants**. The business needs to determine whether internal manufacturing can close the gap while meeting Good Manufacturing Practices (GMP) requirements, and which external manufacturing partners could help if it cannot.

You will work through this scenario from four perspectives:

- **Jordan, the engineer:** Connects the intelligence sources and enables agents to reuse a shared foundation.
- **Sam, the Operations Lead:** Uses the Supply Chain Intelligence Agent to assess capacity, review GMP guidance, and identify the right escalation path.
- **Alex, the Procurement Manager:** Uses a lightweight CMO RFP Tracking Agent to track requests for proposals across shortlisted Contract Manufacturing Organizations (CMOs).
- **The IT Compliance Lead:** Reviews agent ownership, access, data protection, and audit evidence as adoption grows.

### The shared intelligence foundation

| Component | Role in the Caldova scenario |
| --- | --- |
| **Fabric IQ** | Provides business context for plant capacity, batch schedules, equipment qualification windows, fill-finish availability, competitive products, and CMO supplier data. |
| **Foundry IQ** | Grounds agents in shared enterprise knowledge, including GMP SOPs, compressed changeover guidance, and regulatory change control procedures. |
| **Web IQ** | Adds external context from competitor announcements, press releases, and market information with supporting sources. |
| **Work IQ** | Adds organizational context and relevant collaboration history from Microsoft 365 to support escalation and supplier evaluation. |

Microsoft Foundry and Copilot Studio provide the agent-building experiences, with Microsoft 365 Copilot and Teams as user-facing channels in the story. Microsoft Agent 365, Microsoft Entra, and Microsoft Purview support the governance part of the scenario.

### Workshop journey and learning outcomes

Begin with business and technical whiteboarding, translate the agreed architecture into a prototype, and explore the solution accelerator. Use the following outcomes to guide the workshop:

1. **Ground an existing agent:** Explain how the Supply Chain Intelligence Agent combines manufacturing data, GMP knowledge, market information, and organizational context to answer the launch-capacity question with supporting evidence.
1. **Reuse intelligence for new agents:** Design how a CMO Evaluation Agent and a CMO RFP Tracking Agent can build on the same foundation, extending it with supplier data instead of rebuilding the core integrations for each use case.
1. **Validate governance:** Define checks for identity-scoped answers, restricted-content exclusion, agent ownership, and audit evidence across the agent portfolio.

The Caldova story comes from a simulated demonstration. Its business figures are scenario inputs; use the data, connections, and capabilities available in your sandbox to validate hands-on results. Record any missing prerequisites during whiteboarding.

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

