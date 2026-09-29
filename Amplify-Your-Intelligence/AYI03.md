# Ground and Extend Agents with Shared Intelligence

Explore the Microsoft IQ Solution Accelerator through **Caldova Pharmaceutical's NextGen Pharma launch**. This walkthrough follows the first two modules of the demo script: ground an existing Supply Chain Intelligence Agent, then reuse the foundation for a CMO Evaluation Agent.

Use the prototype from [AYI02](AYI02.md) or the facilitator's prepared environment. The original accelerator walkthrough used retail data and resources. The activities below describe the Caldova adaptation; perform each hands-on step only after its required sources and configuration have been supplied and validated. If a dependency remains unresolved, review that part of the simulated demo with the facilitator and record it as not yet validated in the lab.

## Open the prepared environment

1. Open the Azure portal and select **Resource groups**.

   ![](../Sandbox-Environment-Guides/Images/amp52.png)

1. Open the facilitator-confirmed resource group. The existing accelerator guide uses **rg-miqsolution**.

   ![](../Sandbox-Environment-Guides/Images/amp53.png)

1. Review the deployed resources.

   ![](../Sandbox-Environment-Guides/Images/amp54.png)

> [!IMPORTANT]
> **&lt;TODO&gt; — Environment mapping and images:** Confirm the Caldova resource group, Fabric workspace, lakehouse, ontology, agents, knowledge sources, and document locations. The old guide references `Microsoft IQ - miqsolution{suffix}`, `miqsadata`, `RetailSupplyChainOntologyModel`, `RetailSC Ontology Agent`, and `ChatAgent`. Map these to the prepared Caldova resources and refresh the relevant screenshots, including `amp53.png` and `amp54.png`, if the environment changes. Renaming instructions alone does not convert the retail accelerator or its data.

## Module 1 — Ground the Supply Chain Intelligence Agent

### 1. Establish the starting point

In the story, Jordan's Supply Chain Intelligence Agent is already built in Microsoft Foundry and published to Microsoft 365 Copilot. It has enterprise GMP knowledge and Work IQ organizational context, but lacks the manufacturing and competitive information needed by Sam, the Operations Lead.

> [!IMPORTANT]
> **&lt;TODO&gt; — Starting state and reset:** Supply the prepared agent, its existing enterprise knowledge and Work IQ connections, its Microsoft 365 Copilot access, and a repeatable lab reset procedure. Identify how facilitators provide the before-grounding state without disrupting other participants. If the prototype already has all sources connected, use a recorded or simulated baseline rather than disconnecting shared resources ad hoc.

1. Open the prepared Supply Chain Intelligence Agent in Microsoft 365 Copilot.
1. Ask the two questions used in the story and save the responses for comparison:

   ```text
   What is our current capacity position — committed production versus maximum
   capacity by plant?
   ```

   ```text
   What is our competitor's announced launch timeline for their product, and how
   does it compare to our NextGen Pharma product launch schedule?
   ```

1. Discuss the missing evidence. In the simulated story, the agent cannot give a grounded plant-level capacity answer or identify a competitor launch date at this stage.

### 2. Inspect the manufacturing context in Fabric IQ

1. Open **Microsoft Fabric** from the app launcher.

   ![](../Sandbox-Environment-Guides/Images/amp55.png)

1. Open the facilitator-confirmed workspace, lakehouse, and manufacturing ontology.
1. Inspect the supplied data for capacity by plant, committed production, batch schedules, equipment qualification windows, fill-finish availability, and competitive products.
1. Review how the approved entity relationships represent that business context. Compare the records with the capacity calculation supplied for the lab.

> [!IMPORTANT]
> **&lt;TODO&gt; — Manufacturing data and ontology:** Provide the Caldova tables, entity types, relationships, source bindings, refresh procedure, and reconciliation of the 7% shortfall to approximately 18,900 units with Plant 3 as the constraint. The script does not supply a deployable schema and loadable lab data package. Add the tested Fabric navigation and Caldova screenshots once these assets exist. The old retail tables and screenshots retained below cannot validate the new scenario.

### 3. Extend the existing knowledge foundation

1. In the Azure portal, open the prepared Foundry project and select **Go to Foundry portal**.

   ![](../Sandbox-Environment-Guides/Images/amp59.png)

1. Open **Knowledge** and the existing shared knowledge base. The simulated script calls it **unified-knowledgebase**.
1. Review the existing enterprise source: GMP SOPs and scheduling guidelines, Compressed Changeover Guidance, and Regulatory Change Control Procedures.
1. Follow the facilitator's validated procedure to add the manufacturing context from **Fabric IQ**, including competitive-product data, and save the configuration.
1. Connect **Web IQ** using the validated procedure so competitor announcements and market information are available alongside enterprise knowledge.
1. Check that the existing **Work IQ** organizational context is available for escalation questions.
1. Republish the updated Supply Chain Intelligence Agent to Microsoft 365 Copilot using the prepared lab instructions.

> [!IMPORTANT]
> **&lt;TODO&gt; — Source connections and publishing:** Document the exact Fabric IQ, Web IQ, and Work IQ setup, authentication, permissions, and publishing steps supported in this tenant. The script shows Fabric IQ added through the shared knowledge base, whereas the old lab attached a Fabric Data Agent under the agent's Tools. Confirm the chosen lab implementation and explain any difference from the simulation. Add verified screenshots of the source connections and the Foundry publishing flow; the existing retail tool screenshots remain reference material only.

### 4. Compare grounded responses

Repeat the original two questions, then ask the GMP, escalation, and launch-readiness questions below. Open the supporting citations and compare the answer with the connected sources.

| Question | Expected behavior in the simulated story | Evidence to inspect in the workshop |
| --- | --- | --- |
| What is our competitor's announced launch timeline, and how does it compare to our NextGen Pharma launch? | The agent identifies Helios Biopharma's VEXA and cites its announced November 2026 launch, the same month as Caldova's launch. | Competitive-product records plus the dated external announcement. |
| What is our current capacity position — committed production versus maximum capacity by plant? | The agent reports a 7% network shortfall, approximately 18,900 units, with Plant 3 as the constraint. | Plant-level records, the calculation period, and the reconciled network calculation. |
| What do the GMP guidelines say about compressing changeover windows to accelerate production? | The response cites the manufacturing guidance and required Plant Operations Manager and QA sign-offs. | The supplied GMP/changeover document and its relevant passage. |
| Who should I escalate to if Plant 3 pushes back on the proposed schedule change? | The agent identifies Dana Reyes, VP of Manufacturing, then Morgan Ellis, COO, if unresolved. | The organizational structure and escalation information available through Work IQ. |
| Can we close the 7% capacity gap in time for the November NextGen Pharma product launch? | The agent concludes that internal capacity alone cannot close the gap and external manufacturing capacity is needed. | The manufacturing constraint and relevant policy evidence supporting the conclusion. |

These expectations describe the demo's results. Do not insert the target figures or names into agent instructions as a substitute for source data. If the lab response differs, inspect its evidence and record the source or configuration gap.

> [!IMPORTANT]
> **&lt;TODO&gt; — Reproducible validation sources:** Supply the competitor records and approved dated web sources, GMP document passages, organizational records for Dana Reyes and Morgan Ellis, and expected-result evidence. The narrative and screenshots illustrate these results but do not supply a deployable source package or directory configuration for the workshop. Add a validated response capture for each question after rehearsal.

### Module 1 checkpoint

Explain how each source changed the answer: Fabric IQ supplied manufacturing and competitive-product context; Web IQ supplied external announcements; Foundry IQ grounded enterprise knowledge; and Work IQ supplied organizational context. Record which parts were demonstrated and which were verified in the live sandbox.

## Module 2 — Reuse the foundation for CMO evaluation

The capacity decision leads to the next business question: **Which Contract Manufacturing Organizations can help close the gap fast?** Jordan creates a CMO Evaluation Agent that uses the same shared foundation, then adds the pre-qualified CMO supplier database.

### 1. Reuse the existing knowledge and connections

1. In Microsoft Foundry, create or open the prepared **CMO Evaluation Agent**. The script shows `cmo-evaluation-agent`.
1. Configure it to use the existing shared knowledge base and manufacturing ontology, following the validated lab procedure.
1. Confirm its access to the enterprise GMP documents, Work IQ organizational context, and Web IQ external context.
1. Record the reused sources and connections. Verify access under the configured identity before proceeding.

> [!IMPORTANT]
> **&lt;TODO&gt; — CMO agent configuration:** Provide the tested creation steps, model deployment, agent instructions, identity, and source/connection bindings for the CMO Evaluation Agent. The script describes reuse but does not supply a deployable agent definition. Document how permissions are verified for the new agent rather than assuming that attaching a shared source grants the correct access automatically.

### 2. Extend the ontology with CMO supplier data

1. Inspect the facilitator-provided pre-qualified CMO supplier database. In the story, this data comes from **Oracle**.
1. Follow the validated ingestion procedure to load it into the Fabric Lakehouse.
1. Open the existing manufacturing ontology. The script shows **Operations Intelligence**, followed by **Add Entity Type** and **CMO_Evaluation**.
1. Review the new entity's supplied properties, relationships, and data bindings.
1. As a workshop validation step, rerun a capacity question in the original Supply Chain Intelligence Agent after the extension to check that the existing workflow still works.

> [!IMPORTANT]
> **&lt;TODO&gt; — Oracle ingestion and CMO_Evaluation:** Provide the source connection, access requirements, loading procedure, supplier records, schema, entity properties, relationships, and refresh configuration. The script names Oracle and `CMO_Evaluation` but does not provide those implementation details. If an approved sample extract is used instead of Oracle, label that as a workshop adaptation and document it here. Add screenshots for ingestion, the new entity, and the shared-source validation.

### 3. Validate and publish the CMO Evaluation Agent

1. In the Foundry playground, ask the capacity and GMP changeover questions from Module 1. Check that the agent retrieves the shared manufacturing data and enterprise guidance.
1. Publish the configured agent to Microsoft 365 Copilot using the validated lab procedure.
1. As Sam, ask the following question, adapted from the script:

   ```text
   Review prior touchpoints across emails, Teams, SharePoint, and OneDrive.
   Score each pre-qualified CMO on responsiveness, quality, and speed.
   Recommend which CMOs can fast-track to 3–6 months under GMP validation
   for our NextGen Pharma product launch, and assess whether they can
   close our capacity gap. Cite the evidence for your recommendation.
   ```

1. Inspect the cited supplier records and collaboration history. Discuss which evidence supports the recommendation and which uncertainties remain. The script's response screenshot lists **Meridian, Astoria, and Cobalt** as fast-track eligible, identifies **Meridian Biologics** as the best overall choice, and says each of the three can close the approximately 18,900-unit gap. Treat these as simulated results to substantiate with the approved lab data.
1. Record the intelligence reused by the second agent and the additional source introduced by the CMO extension.

> [!IMPORTANT]
> **&lt;TODO&gt; — CMO evaluation evidence:** Supply the pre-qualified CMO list, collaboration history, evaluation rubric, capacity and timing evidence, and the GMP validation material needed to assess the 3–6 month question. The response screenshot references `GUID-PROC-009` for qualification, `GUID-QA-018` for the fast-track standard, and `GUID-PROC-012` for weighted scoring. Supply those source documents and the underlying supplier records; the screenshot alone does not provide their complete rules, scoring weights, or a reproducible lab dataset. Do not invent scores or treat the requested timeline as a guaranteed outcome.

> [!IMPORTANT]
> **&lt;TODO&gt; — Product naming in source screenshots:** The script's narrative uses NextGen Pharma, while the CMO prompt screenshot uses ZAVA IL2 and the response refers to a V2 launch. This walkthrough follows the narrative's NextGen Pharma name. Confirm the intended product identifiers in the supplied data and replace inconsistent screenshots before delivery; do not silently treat the names as interchangeable records.

### Module 2 checkpoint

The story illustrates how adding a supplier source can extend a foundation used by multiple agents. For this workshop, retain evidence of source reuse, cited recommendations, access checks, and the original agent's behavior after the extension. The demo's claims about deployment speed and reduced effort are narrative outcomes, not measured lab results.

## Existing screenshots awaiting collaborator review

> [!IMPORTANT]
> **&lt;TODO&gt; — Screenshot refresh:** The images below are retained from the previous lab so collaborators can replace them after the Caldova configuration is validated. They may show retail names, sample data, older setup choices, or the email-triggered workflow. They are reference material, not evidence of the Caldova results or instructions to execute the old workflow. Keep the current image files until replacements are available, then update the relevant Markdown references and remove obsolete reference entries. New Web IQ, CMO, and governance steps also need verified screenshots where applicable.

<details>
<summary>Previous lab screenshots retained for collaborators</summary>

**Earlier lab section: Fabric IQ**

![](../Sandbox-Environment-Guides/Images/a35.png)

![](../Sandbox-Environment-Guides/Images/amp56.png)

![](../Sandbox-Environment-Guides/Images/amp57.png)

![](../Sandbox-Environment-Guides/Images/amp65.png)

![](../Sandbox-Environment-Guides/Images/amp67.png)

![](../Sandbox-Environment-Guides/Images/amp68.png)

![](../Sandbox-Environment-Guides/Images/amp66.png)

![](../Sandbox-Environment-Guides/Images/amp69.png)

![](../Sandbox-Environment-Guides/Images/amp70.png)

![](../Sandbox-Environment-Guides/Images/agenti1.png)

![](../Sandbox-Environment-Guides/Images/a21.png)

![](../Sandbox-Environment-Guides/Images/a17.png)

![](../Sandbox-Environment-Guides/Images/a19.png)

![](../Sandbox-Environment-Guides/Images/a37.png)

![](../Sandbox-Environment-Guides/Images/a36.png)

![](../Sandbox-Environment-Guides/Images/a38.png)

![](../Sandbox-Environment-Guides/Images/a16.png)

**Earlier lab section: Microsoft Foundry**

![](../Sandbox-Environment-Guides/Images/amp58.png)

![](../Sandbox-Environment-Guides/Images/amp60.png)

![](../Sandbox-Environment-Guides/Images/amp61.png)

![](../Sandbox-Environment-Guides/Images/amp62.png)

![](../Sandbox-Environment-Guides/Images/amp63.png)

![](../Sandbox-Environment-Guides/Images/amp64.png)

![](../Sandbox-Environment-Guides/Images/a27.png)

![](../Sandbox-Environment-Guides/Images/a22.png)

![](../Sandbox-Environment-Guides/Images/a23.png)

![](../Sandbox-Environment-Guides/Images/a24.png)

![](../Sandbox-Environment-Guides/Images/a40.png)

![](../Sandbox-Environment-Guides/Images/b83.png)

![](../Sandbox-Environment-Guides/Images/b84.png)

![](../Sandbox-Environment-Guides/Images/b85.png)

![](../Sandbox-Environment-Guides/Images/a28.png)

![](../Sandbox-Environment-Guides/Images/a32.png)

![](../Sandbox-Environment-Guides/Images/a30.png)

![](../Sandbox-Environment-Guides/Images/a31.png)

![](../Sandbox-Environment-Guides/Images/a34.png)

</details>

### Now, click on **`Next >>`** to continue with **`Work IQ, CMO RFP Tracking, and Governance`**.
