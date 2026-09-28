## 1. Envisioning Session Using Whiteboarding

### Whiteboarding

Whiteboarding helps technical teams align on business goals, current challenges, future-state architecture, and solution priorities. In this session, you will design a shared Microsoft IQ intelligence foundation for Caldova Pharmaceutical's accelerated NextGen Pharma product launch.

### Business scenario

Caldova is targeting a **November 2026 launch** while a competitor is pursuing the same launch window. Sam, the Operations Lead, needs to answer the VP of Manufacturing's question: **Can we close a 7% production-capacity gap across three plants in time for launch?**

In the story, Jordan has already built a Supply Chain Intelligence Agent with enterprise GMP knowledge and organizational context. The agent initially lacks the manufacturing and competitive data needed to answer the capacity and launch-timing questions. Your architecture should show how adding that context improves the existing agent and creates a foundation for additional agents.

Use these scenario details when discussing the target outcome:

- The network shortfall is approximately **18,900 units**, with **Plant 3** as the binding constraint.
- Internal capacity alone cannot fully close the gap, so the team needs to evaluate **Contract Manufacturing Organizations (CMOs)**.
- Proposed changes to manufacturing changeover windows must follow GMP guidance, including Plant Operations Manager and QA sign-offs.
- The escalation path in the story includes **Dana Reyes, VP of Manufacturing**, followed by **Morgan Ellis, COO**, if the issue remains unresolved.

These are inputs from the simulated story. During prototyping, verify the supporting data and documents before expecting an agent to reproduce these results.

### Goals for the future-state solution

Design a solution that can:

- Compare committed production with maximum capacity by plant and explain the network shortfall.
- Compare Caldova's launch schedule with cited competitor announcements and current market information.
- Retrieve GMP scheduling, compressed changeover, and regulatory change control guidance with citations.
- Identify the appropriate stakeholders and escalation path using organizational context.
- Evaluate pre-qualified CMOs using supplier data and relevant collaboration history, then track RFP progress.
- Reuse a shared intelligence foundation across agents while respecting access controls and protecting restricted information.

### How to copy the Whiteboard using an existing template URL

> [!IMPORTANT]
> **&lt;TODO&gt; — Whiteboard template:** Collaborators should review the linked template and update its case study, business notes, and current-state and future-state architecture sections for Caldova Pharmaceutical. The current reference screenshot still contains Zava Retail content. Keep the existing link until the revised template is available, then verify or update it here. In the meantime, use the Caldova scenario and activities below to guide the session.

1. Open a new browser tab in the Edge browser.

1. Right click on the following Whiteboard template link -  ["Whiteboard Template"](https://sandboxailabs1002-my.sharepoint.com/:wb:/g/personal/amplify_user_sandboxailabs1002_onmicrosoft_com/IQCgG6cKI3xwSon2DSEbtOmxAUc7nM9jphqv7ozbt4RC8aU?e=5Vyzra), then select **Copy link** and then paste it on the browser tab.

1. If prompted, sign in with your ODL user credentials.

1. Once you login, you will get a pop-up message to create the new Whiteboard. Read the message and click **Got it**.

   ![](../Sandbox-Environment-Guides/Images/amp71.png)

1. Use the **Zoom out** option to view the Whiteboard template clearly.

   ![](../Sandbox-Environment-Guides/Images/cd35.png)

   > [!IMPORTANT]
   > **&lt;TODO&gt; — Whiteboard image:** Replace `cd35.png` with a screenshot of the updated Caldova template once it is ready. The replacement should show the pharmaceutical launch challenge, all four IQ components including Web IQ, and the shared-agent architecture. The existing image is retained for now.

1. Please follow along as the **Facilitator** guides you through the **Business** and **Technical** Envisioning session. During the session, you will identify key business challenges, define priorities, assess the current environment, and design a Future-state solution architecture.

### Activities

1. Review the **Business Envisioning Notes** using Caldova's launch challenge. Capture the decisions Sam, Jordan, Alex, and the IT Compliance Lead need to support.

1. In the **Technical Envisioning** section, capture the **Top 5 Pain Points** from the story:
   - Fragmented visibility across plant capacity, supplier networks, and external market information.
   - Slow decisions caused by manual analysis and coordination across teams.
   - Repeated integration and retrieval work when each new agent starts from scratch.
   - Stale internal and external information that reduces confidence in recommendations.
   - Limited visibility into agent ownership, access, data protection, and compliance.

1. Define the **Top Priorities** and corresponding **Success Criteria**. Use the following checks to make the intended outcomes concrete:

   | Priority | Success criteria to validate |
   | --- | --- |
   | Ground the capacity decision | The agent compares committed production and maximum capacity by plant, explains the gap, and cites the supporting data. With the story's sample data, it identifies Plant 3 as the constraint and the need for external capacity. |
   | Combine operational and business context | Answers draw on the relevant GMP documents, dated competitor sources, and organizational context, with evidence for each conclusion. |
   | Reuse the intelligence foundation | The CMO Evaluation Agent reuses the shared knowledge and manufacturing context. CMO supplier data extends the existing ontology rather than requiring a separate foundation. |
   | Support procurement | The CMO RFP Tracking Agent reports the status of requests for shortlisted suppliers using the shared context and available RFP records. |
   | Govern access and protect data | The same capacity question respects Plant 3 manager versus VP access. Restricted launch-planning content is excluded where policy requires it, with agent ownership and audit evidence available for review. |

1. Complete **Technical Discovery** by documenting the current-state architecture and the sources needed for the scenario:
   - **Manufacturing and business data:** Plant capacity, committed production, batch schedules, equipment qualification windows, fill-finish availability, and competitive products.
   - **Enterprise knowledge:** GMP SOPs, compressed changeover guidance, and regulatory change control procedures.
   - **Organizational and collaboration context:** Reporting relationships, escalation responsibilities, and relevant emails, Teams conversations, SharePoint documents, and OneDrive files.
   - **External information:** Competitor press releases, launch announcements, and market information.
   - **CMO supplier data:** The pre-qualified supplier database, represented as an Oracle source in the story, and the data needed to evaluate and track suppliers.
   - **Governance prerequisites:** User and agent identities, permissions, sensitivity labels, data protection policies, network requirements, and audit visibility.
   - Record which sources and capabilities are available in the sandbox, which require configuration, and which remain demonstration-only.

1. Design the **Future State Architecture** to show:
   - **Fabric IQ** providing the manufacturing ontology and its extension with the `CMO_Evaluation` entity.
   - **Foundry IQ** providing shared enterprise knowledge and grounding, with **Web IQ** for external information and **Work IQ** for organizational and collaboration context.
   - The **Supply Chain Intelligence Agent** and **CMO Evaluation Agent** in Microsoft Foundry reusing the shared foundation.
   - The **CMO RFP Tracking Agent** in Copilot Studio supporting Alex's procurement workflow using that shared intelligence.
   - Microsoft 365 Copilot and Teams as the user-facing channels in the story.
   - Microsoft Agent 365, Microsoft Entra, and Microsoft Purview supporting agent oversight, identity and access, and data protection. Mark where each control must be configured and tested.

1. Review the completed envisioning outputs with the facilitator. Confirm that each business question maps to the required sources, an agent workflow, and a success criterion. Record missing data, environment prerequisites, and assumptions to resolve during prototyping.

## This completes the Envisioning Session using Microsoft Whiteboarding.

### Now, click on **`Next >>`** from the lower right corner to move on to **`Rapid Prototyping`**.
