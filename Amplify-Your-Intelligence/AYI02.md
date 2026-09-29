# 2. Rapid Prototyping

Use the future-state architecture from whiteboarding to prepare a prototype for **Caldova Pharmaceutical's NextGen Pharma launch**. The business question is whether Caldova can close a **7% capacity gap across three plants** before the November launch, and which external manufacturing partners could help.

The demo story begins with an existing Supply Chain Intelligence Agent. This workshop retains the **GitHub Copilot prototyping exercise** from the original guide to prepare that foundation. The prompts below are workshop adaptations of the story; the script does not provide deployment templates, schemas, sample files, or tenant configuration.

## Before you begin

Use the facilitator's approved environment and source materials. If a prerequisite below is missing, record the gap and discuss the design; complete the dependent deployment or test after the collaborator TODO is resolved.

> [!IMPORTANT]
> **&lt;TODO&gt; — Deployment prerequisites:** Collaborators must provide the approved resource names, subscription/resource group, Fabric capacity and region, workspace, Foundry project, model deployments, access roles, and deployment procedures. The previous guide used F16 in West US 3, Foundry in Sweden Central, and specific model names; these are legacy lab choices, not requirements supplied by the Caldova script. Validate or replace them before running this exercise. Confirm the VM folder `C:\miq-project` and provided sign-in flow are still valid.

> [!IMPORTANT]
> **&lt;TODO&gt; — Caldova source package:** Provide the manufacturing and competitive-product data, table schemas and relationships, GMP SOPs, scheduling guidelines, Compressed Changeover Guidance, and Regulatory Change Control Procedures. Add the approved source locations and loading steps here. The script gives a 7% gap of approximately 18,900 units and identifies Plant 3 as the constraint, but does not supply a loadable lab dataset. Provide reconciled source records and document the calculation period and denominator before expecting those results. Do not invent missing records or policy text.

## Rapid prototyping using GitHub Copilot

Use GitHub Copilot to prepare ARM or Bicep templates for the Azure resources in the agreed architecture. Capture Fabric item setup, connections, and any other configuration as separate, reviewed steps where required by the validated lab procedure.

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

1. Select the model and permission settings specified by the facilitator for this workshop.

   > [!IMPORTANT]
   > **&lt;TODO&gt; — Copilot setup:** Confirm the available model and the permissions needed in the workshop tenant. The demo script does not specify GitHub Copilot settings. The previous guide's model selection and permission screenshots are retained in the reference section below and must be refreshed after validation.

1. Select the **Future-State-Architecture.png**.

   ![](../Sandbox-Environment-Guides/Images/b88.png)

1. From the **GitHub Copilot Chat**, click on **+ (1)** and then select the **Future-State-Architecture.png (2)**.

   ![](../Sandbox-Environment-Guides/Images/b89.png)

> [!IMPORTANT]
> **&lt;TODO&gt; — Architecture input and screenshots:** Replace the retail content in the VM's `Future-State-Architecture.png` with the approved Caldova architecture from whiteboarding, and refresh `b88.png` and `b89.png`. Keep the current images until replacements are ready. Verify that the attached architecture contains the four IQ components and the shared-agent flows before generating the prototype.

### Prepare the Fabric IQ foundation

1. With the approved Caldova architecture attached, send this workshop prompt:

   ```text
   Help me prepare a prototype for Caldova Pharmaceutical using the attached
   architecture and the facilitator-provided source package.

   The story concerns a 7% production-capacity gap across three plants before
   the November NextGen Pharma launch. The manufacturing context includes
   plant capacity, committed production, batch schedules, equipment qualification
   windows, fill-finish availability, and competitive products.

   1. Identify the resources and Fabric items shown in the architecture.
   2. Use only the supplied resource settings, schemas, records, and relationships.
   3. Prepare the Azure deployment templates and the separate Fabric configuration
      steps needed to load the approved data into a lakehouse and expose the
      manufacturing ontology for the agent workflow.
   4. Identify how the configured agent will access the ontology using the
      facilitator's validated integration procedure.
   5. Document how to verify the loaded data, entity relationships, and capacity
      calculation against the supplied source package.
   6. Mark missing settings, data, and unsupported deployment steps as TODOs.
      Do not invent plant figures, schemas, entity relationships, or API support.

   Present the plan and generated files for review before deployment.
   ```

1. Review the generated plan with the facilitator. Resolve its TODOs using the approved lab materials, then follow the validated deployment procedure.

1. In the Azure portal and Fabric workspace, check that the expected resources and items exist. Review the loaded tables and relationships against the source package.

1. If the facilitator's integration uses a Fabric Data Agent, confirm its configured data source and instructions before testing it. The previous lab used a retail data agent; its names and bindings do not establish a Caldova configuration.

   > [!IMPORTANT]
   > **&lt;TODO&gt; — Ontology and agent integration:** Provide the manufacturing ontology's entity types, keys, relationships, item names, and tested agent access procedure. Resolve whether the lab follows the script's Fabric IQ knowledge-source flow or uses the previous accelerator's Fabric Data Agent tool connection. Document the chosen implementation explicitly; the two flows should not be treated as interchangeable without validation.

1. Use this question to check the structured-data path once it is configured:

   ```text
   What is our current capacity position — committed production versus maximum
   capacity by plant?
   ```

1. Compare the answer with the loaded records. Record the source, time period, and calculation used. The story's shortfall is an expected result only when the approved sample data supports it.

### Prepare Foundry IQ and the existing supply chain agent

The story's starting point is a **Supply Chain Intelligence Agent** built in Microsoft Foundry, grounded in enterprise GMP knowledge and Work IQ organizational context, and already published to Microsoft 365 Copilot. Fabric IQ and Web IQ are added later in the grounding walkthrough.

1. Return to GitHub Copilot and send this workshop prompt:

   ```text
   Prepare the Foundry portion of the Caldova prototype using the approved
   architecture, source package, and lab configuration.

   1. Use the facilitator-provided resource group, region, project, model
      deployments, identities, and connection settings.
   2. Prepare a shared enterprise knowledge base using the supplied GMP SOPs,
      scheduling guidelines, Compressed Changeover Guidance, and Regulatory
      Change Control Procedures.
   3. Prepare the Supply Chain Intelligence Agent to use that knowledge base.
      Follow the approved Work IQ setup for organizational context.
   4. Document the starting state before manufacturing and public-web grounding
      are connected, and the later steps for adding Fabric IQ and Web IQ.
   5. Reuse the existing knowledge foundation when adding the CMO Evaluation
      Agent later. Do not build a separate knowledge base for each agent.
   6. Include validation prompts and record unresolved configuration as TODOs.
      Do not create GMP policy content or claim a connection works without testing.

   Present the generated files and configuration steps for facilitator review.
   ```

1. Review the output and follow the approved deployment procedure. In Microsoft Foundry, inspect the project, agent, shared knowledge base, sources, and configured connections.

1. Check the enterprise knowledge path with the question from the story:

   ```text
   What do the GMP guidelines say about compressing changeover windows to
   accelerate production?
   ```

1. Open the cited source and verify that the answer reflects the supplied guidance. The story includes Plant Operations Manager and QA sign-offs; the workshop needs the corresponding document to substantiate that response.

> [!IMPORTANT]
> **&lt;TODO&gt; — Knowledge setup and publishing:** Supply the approved GMP files, ingestion/indexing procedure, exact knowledge-base and source names, agent instructions, identity configuration, and Foundry-to-Microsoft 365 Copilot publishing steps. The script uses `unified-knowledgebase`; the previous lab uses `{suffix}-kb` and `ChatAgent`. Provide an explicit mapping to the actual deployed resources instead of only changing their names in this guide.

### Prepare Web IQ and Work IQ

In the story, **Web IQ** provides current competitor announcements and market information, while **Work IQ** supplies organizational context and later helps evaluate prior CMO interactions across Microsoft 365.

1. Identify the connections required by the approved architecture. Record which are already configured and which still need setup.
1. Identify the sources needed for the competitor question, the Dana Reyes/Morgan Ellis escalation path, and the later CMO collaboration-history question.
1. Keep the starting state documented so that the next walkthrough can compare responses before and after the missing grounding sources are connected.

> [!IMPORTANT]
> **&lt;TODO&gt; — Web IQ:** Provide tenant availability, access requirements, the tested connection procedure, and approved competitor source material. The story names Helios Biopharma's VEXA and an announced November 2026 launch, but does not provide a reproducible set of web URLs or a live-lab setup. Confirm whether this part will use the simulated demo or a verified lab connection; do not substitute a different service silently.

> [!IMPORTANT]
> **&lt;TODO&gt; — Work IQ:** Provide the supported connection method, permissions, organizational records, and relevant Microsoft 365 collaboration material. The old guide lists Work IQ Copilot, Mail, and User preview tools; confirm the tools needed for this scenario rather than assuming those connections implement every story interaction. Work IQ is the contextual intelligence layer in the story, not the name of the old email-triggered orchestration flow.

### Validate the prototype handoff

Record the following before continuing:

- The environment, resources, and actual names used for the manufacturing ontology, shared knowledge base, and Supply Chain Intelligence Agent.
- Which source connections are active, and the starting state used for the before-and-after grounding exercise.
- Evidence that the loaded manufacturing data and cited GMP documents match the approved source package.
- The steps already completed and any remaining collaborator TODOs. A generated template or a success message alone does not confirm the full scenario works.

The **CMO Evaluation Agent**, Oracle supplier-data extension, and shared-foundation tests are covered in [the next walkthrough](AYI03.md). Alex's Copilot Studio RFP tracking exercise and the governance walkthrough are covered in [AYI04](AYI04.md), so the old email-triggered setup is no longer repeated here.

## Existing screenshots awaiting collaborator review

> [!IMPORTANT]
> **&lt;TODO&gt; — Screenshot refresh:** The images below are retained from the previous lab so collaborators can replace them after the Caldova configuration is validated. They may show retail names, sample data, older setup choices, or the email-triggered workflow. They are reference material, not evidence of the Caldova results or instructions to execute the old workflow. Keep the current image files until replacements are available, then update the relevant Markdown references and remove obsolete reference entries. New Web IQ, CMO, and governance steps also need verified screenshots where applicable.

<details>
<summary>Previous lab screenshots retained for collaborators</summary>

**Earlier lab section: Sign in to GitHub Copilot Chat**

![](../Sandbox-Environment-Guides/Images/b7.png)

![](../Sandbox-Environment-Guides/Images/b8.png)

![](../Sandbox-Environment-Guides/Images/amp33.png)

**Earlier lab section: Fabric IQ**

![](../Sandbox-Environment-Guides/Images/b12.png)

![](../Sandbox-Environment-Guides/Images/Prompt-followup.png)

![](../Sandbox-Environment-Guides/Images/b13.png)

![](../Sandbox-Environment-Guides/Images/b14.png)

![](../Sandbox-Environment-Guides/Images/b15.png)

![](../Sandbox-Environment-Guides/Images/b16.png)

![](../Sandbox-Environment-Guides/Images/b55.png)

![](../Sandbox-Environment-Guides/Images/b17.png)

![](../Sandbox-Environment-Guides/Images/amp55.png)

![](../Sandbox-Environment-Guides/Images/b18.png)

![](../Sandbox-Environment-Guides/Images/b19.png)

![](../Sandbox-Environment-Guides/Images/b20.png)

![](../Sandbox-Environment-Guides/Images/b21.png)

![](../Sandbox-Environment-Guides/Images/b22.png)

![](../Sandbox-Environment-Guides/Images/b23.png)

![](../Sandbox-Environment-Guides/Images/b25.png)

![](../Sandbox-Environment-Guides/Images/b24.png)

![](../Sandbox-Environment-Guides/Images/b26.png)

![](../Sandbox-Environment-Guides/Images/b27.png)

![](../Sandbox-Environment-Guides/Images/b60.png)

![](../Sandbox-Environment-Guides/Images/b61.png)

![](../Sandbox-Environment-Guides/Images/b76.png)

![](../Sandbox-Environment-Guides/Images/graph.png)

![](../Sandbox-Environment-Guides/Images/b28.png)

![](../Sandbox-Environment-Guides/Images/b30.png)

![](../Sandbox-Environment-Guides/Images/b31.png)

![](../Sandbox-Environment-Guides/Images/b32.png)

![](../Sandbox-Environment-Guides/Images/b58.png)

![](../Sandbox-Environment-Guides/Images/b59.png)

![](../Sandbox-Environment-Guides/Images/b65.png)

![](../Sandbox-Environment-Guides/Images/b66.png)

**Earlier lab section: Foundry IQ**

![](../Sandbox-Environment-Guides/Images/b38.png)

![](../Sandbox-Environment-Guides/Images/b39.png)

![](../Sandbox-Environment-Guides/Images/b40.png)

![](../Sandbox-Environment-Guides/Images/b41.png)

![](../Sandbox-Environment-Guides/Images/b42.png)

![](../Sandbox-Environment-Guides/Images/b43.png)

![](../Sandbox-Environment-Guides/Images/b44.png)

![](../Sandbox-Environment-Guides/Images/b45.png)

![](../Sandbox-Environment-Guides/Images/b46.png)

![](../Sandbox-Environment-Guides/Images/a32.png)

![](../Sandbox-Environment-Guides/Images/b47.png)

![](../Sandbox-Environment-Guides/Images/b48.png)

![](../Sandbox-Environment-Guides/Images/b49.png)

![](../Sandbox-Environment-Guides/Images/b51.png)

![](../Sandbox-Environment-Guides/Images/b52.png)

![](../Sandbox-Environment-Guides/Images/b53.png)

**Earlier lab section: Step 0: Create a Power Platoform Environment with Dataverse enabled**

![](../Sandbox-Environment-Guides/Images/a41.png)

![](../Sandbox-Environment-Guides/Images/a42.png)

![](../Sandbox-Environment-Guides/Images/a43.png)

![](../Sandbox-Environment-Guides/Images/b77.png)

![](../Sandbox-Environment-Guides/Images/a45.png)

![](../Sandbox-Environment-Guides/Images/b78.png)

![](../Sandbox-Environment-Guides/Images/b80.png)

**Earlier lab section: Step 1: Import the Solution and configure the connections.**

![](../Sandbox-Environment-Guides/Images/a50.png)

![](../Sandbox-Environment-Guides/Images/a51.png)

![](../Sandbox-Environment-Guides/Images/a52.png)

![](../Sandbox-Environment-Guides/Images/a53.png)

![](../Sandbox-Environment-Guides/Images/a54.png)

![](../Sandbox-Environment-Guides/Images/a55.png)

![](../Sandbox-Environment-Guides/Images/a56.png)

![](../Sandbox-Environment-Guides/Images/a57.png)

![](../Sandbox-Environment-Guides/Images/a58.png)

![](../Sandbox-Environment-Guides/Images/a59.png)

![](../Sandbox-Environment-Guides/Images/a60.png)

**Earlier lab section: Step 2: Configure the Email Trigger**

![](../Sandbox-Environment-Guides/Images/a61.png)

![](../Sandbox-Environment-Guides/Images/a62.png)

![](../Sandbox-Environment-Guides/Images/a63.png)

![](../Sandbox-Environment-Guides/Images/a64.png)

![](../Sandbox-Environment-Guides/Images/a65.png)

![](../Sandbox-Environment-Guides/Images/a66.png)

![](../Sandbox-Environment-Guides/Images/a67.png)

![](../Sandbox-Environment-Guides/Images/a68.png)

![](../Sandbox-Environment-Guides/Images/a69.png)

**Earlier lab section: 3.1 Add the Foundry Agent**

![](../Sandbox-Environment-Guides/Images/a70.png)

![](../Sandbox-Environment-Guides/Images/a71.png)

![](../Sandbox-Environment-Guides/Images/a72.png)

![](../Sandbox-Environment-Guides/Images/a73.png)

![](../Sandbox-Environment-Guides/Images/a103.png)

![](../Sandbox-Environment-Guides/Images/a74.png)

![](../Sandbox-Environment-Guides/Images/b67.png)

![](../Sandbox-Environment-Guides/Images/a75.png)

![](../Sandbox-Environment-Guides/Images/a76.png)

![](../Sandbox-Environment-Guides/Images/a77.png)

![](../Sandbox-Environment-Guides/Images/a78.png)

![](../Sandbox-Environment-Guides/Images/a79.png)

![](../Sandbox-Environment-Guides/Images/b68.png)

![](../Sandbox-Environment-Guides/Images/a80.png)

![](../Sandbox-Environment-Guides/Images/a81.png)

![](../Sandbox-Environment-Guides/Images/a82.png)

![](../Sandbox-Environment-Guides/Images/a83.png)

![](../Sandbox-Environment-Guides/Images/b69.png)

![](../Sandbox-Environment-Guides/Images/b70.png)

**Earlier lab section: 3.2: Add the Fabric Data Agent**

![](../Sandbox-Environment-Guides/Images/b71.png)

![](../Sandbox-Environment-Guides/Images/a87.png)

![](../Sandbox-Environment-Guides/Images/a88.png)

![](../Sandbox-Environment-Guides/Images/a89.png)

![](../Sandbox-Environment-Guides/Images/a82.png)

![](../Sandbox-Environment-Guides/Images/a90.png)

![](../Sandbox-Environment-Guides/Images/b72.png)

![](../Sandbox-Environment-Guides/Images/b73.png)

![](../Sandbox-Environment-Guides/Images/b74.png)

![](../Sandbox-Environment-Guides/Images/b75.png)

**Earlier lab section: Step 4: Verify Work IQ connections and MCP tools are connected and enabled**

![](../Sandbox-Environment-Guides/Images/a95.png)

![](../Sandbox-Environment-Guides/Images/a96.png)

**Earlier lab section: Step 5: Publish the Agent**

![](../Sandbox-Environment-Guides/Images/a97.png)

![](../Sandbox-Environment-Guides/Images/a98.png)

![](../Sandbox-Environment-Guides/Images/a99.png)

![](../Sandbox-Environment-Guides/Images/a100.png)

![](../Sandbox-Environment-Guides/Images/a101.png)

![](../Sandbox-Environment-Guides/Images/a102.png)

![](../Sandbox-Environment-Guides/Images/a104.png)

![](../Sandbox-Environment-Guides/Images/a105.png)

![](../Sandbox-Environment-Guides/Images/a106.png)

![](../Sandbox-Environment-Guides/Images/a107.png)

**Earlier lab section: Step 1: Prepare Your Environment**

![](../Sandbox-Environment-Guides/Images/a107.png)

**Earlier lab section: Example: Supply Chain Disruption**

![](../Sandbox-Environment-Guides/Images/a108.png)

![](../Sandbox-Environment-Guides/Images/a109.png)

![](../Sandbox-Environment-Guides/Images/a110.png)

**Earlier lab section: Step 3: Monitor the Flow**

![](../Sandbox-Environment-Guides/Images/a111.png)

![](../Sandbox-Environment-Guides/Images/a112.png)

![](../Sandbox-Environment-Guides/Images/a113.png)

![](../Sandbox-Environment-Guides/Images/a114.png)

**Earlier lab section: Step 4: Review Response in Teams**

![](../Sandbox-Environment-Guides/Images/b57.png)

![](../Sandbox-Environment-Guides/Images/Agent2.png)

![](../Sandbox-Environment-Guides/Images/agentprompt.png)

![](../Sandbox-Environment-Guides/Images/agent1.png)

</details>

### Now, click on **`Next >>`** to continue with **`Ground and Extend Agents with Shared Intelligence`**.
