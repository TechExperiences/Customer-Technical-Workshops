# Work IQ, CMO RFP Tracking, and Governance

Continue Caldova's story after the Supply Chain Intelligence Agent identifies the need for external capacity and the CMO Evaluation Agent assesses potential manufacturing partners. Alex, the Procurement Manager, now uses a lightweight **CMO RFP Tracking Agent** built in Copilot Studio. The final part follows the IT Compliance Lead as the agent portfolio grows.

In this story, **Work IQ** supplies organizational and collaboration context. The Copilot Studio agent consumes shared intelligence to support procurement; Work IQ itself is not the email-triggered flow described in the previous retail lab.

The activities below adapt the demo story into a workshop. Collaborator TODOs identify the setup and evidence the script does not supply. Complete each dependent hands-on activity only after those prerequisites are available. Otherwise, review the corresponding simulated-demo sequence with the facilitator and record it as demonstration-only.

## Before you begin

Confirm the shared knowledge foundation and CMO evaluation work from [AYI03](AYI03.md). Identify the available Copilot Studio environment and Microsoft 365 Copilot/Teams access. Record any remaining source or publishing gaps.

> [!IMPORTANT]
> **&lt;TODO&gt; — Copilot Studio environment and solution package:** Confirm the environment, access requirements, connections, and agent creation procedure for Caldova. The previous guide created `Amplify Environment<inject key="Deployment-ID" enableCopy="false"/>` with Dataverse and imported `C:\Files\MicrosoftIQAccelerator.zip`. The script does not provide or validate a Caldova version of that package. If the lab retains it, supply the updated solution and verified import steps; otherwise, document the tested creation path. Avoid importing the old retail workflow as though it already implements the CMO scenario.

## Complete Module 2 — Build the CMO RFP Tracking Agent

### 1. Create the procurement agent

1. Open [Copilot Studio](https://copilotstudio.microsoft.com) in the VM browser and select the facilitator-confirmed environment.
1. Open **Agents**, then create or open the prepared **CMO RFP Tracking Agent** using the validated lab instructions.
1. Review the intended business task: report the status of requests for proposals across the shortlisted pre-qualified CMOs.
1. Connect the agent to the same intelligence foundation used by the Foundry agents, following the prepared configuration.

> [!IMPORTANT]
> **&lt;TODO&gt; — Shared intelligence connection:** Supply the exact Copilot Studio connection method, agent/tool identifiers, descriptions, authentication settings, and access scope. The script shows reuse and an **Add to agent** action but does not provide the configuration behind that action. Confirm whether the old accelerator's external-agent connections and Work IQ tools apply. Do not use an agent's display name as its identifier unless the validated connector procedure explicitly requires it.

### 2. Ground the agent in RFP records

1. Inspect the facilitator-provided shortlist and RFP status records.
1. Identify how the agent obtains that information and how Work IQ collaboration context contributes to the response.
1. Review the agent's instructions. The following is a workshop draft to adapt after the actual connections are configured:

   ```text
   Help Caldova Procurement track RFP status for the shortlisted CMOs supporting
   the NextGen Pharma launch. Use the configured shared intelligence and
   approved RFP records. Report the status supported by those records and cite
   the evidence. Use available collaboration context where relevant.

   If a supplier, request, or status cannot be verified, state what information
   is missing. Do not infer that an RFP was sent from the fact that a CMO was
   shortlisted. This exercise asks for a status report, not for sending RFPs.
   ```

> [!IMPORTANT]
> **&lt;TODO&gt; — RFP source and expected results:** Supply the actual RFP records, supplier shortlist, status definitions, source location, and retrieval procedure. The script says requests are already out to the top three fast-track CMOs and the rest are on hold or not yet engaged, but does not supply reusable RFP source data or an end-to-end retrieval configuration. Its response screenshot names Meridian, Astoria, and Cobalt as active RFPs, Helix and Vanta as gated, and Northwind as excluded. Reconcile the narrative and screenshot status wording in the approved lab records. Confirm the use of RFP versus RFQ terminology: the narrative mentions RFQs, while the agent and status question are named RFP. Use the approved workshop terminology consistently once clarified.

### 3. Publish and test

1. Publish the configured agent to **Teams and Microsoft 365 Copilot** using the facilitator's validated steps.
1. Open the agent in Microsoft 365 Copilot and ask:

   ```text
   What is the RFP status across the shortlisted CMOs for our NextGen Pharma
   product launch? Cite the records supporting each status.
   ```

1. Compare the response with the supplied records. The simulated story shows requests already sent to the top three fast-track CMOs, with the remaining CMOs on hold or not yet engaged.
1. Confirm that the response uses the shared foundation and relevant evidence. Record missing or conflicting data instead of forcing the response to match the narrative.

> [!IMPORTANT]
> **&lt;TODO&gt; — Publishing and screenshots:** Verify the publishing, channel configuration, user access, and installation steps for this tenant. Replace the old Microsoft IQ Agent screenshots with the CMO RFP Tracking Agent configuration and its verified response once available. Keep the existing images in the reference section until the replacements are ready.

### Procurement checkpoint

Explain how Alex's agent reuses the intelligence foundation and identify the RFP evidence it needs. The earlier retail email-triggered Power Automate test is not part of this story's core sequence and has been removed from the active walkthrough.

> [!IMPORTANT]
> **&lt;TODO&gt; — Optional email extension:** If collaborators retain email-triggered orchestration as a separate workshop extension, provide a Caldova-specific business purpose, updated solution/flow, sample message, configured mailbox and connections, and verified result. The demo script does not describe this workflow. Do not present the previous camping-supplier email test as a Caldova story step.

## Module 3 — Trust intelligence that drives scale

Six weeks into the accelerated launch, the script introduces a broader agent portfolio and asks: **Can Caldova prove every agent is operating within policy before leadership relies on it for critical decisions?** The IT Compliance Lead examines agent inventory, policy violations, identity-scoped responses, restricted-content handling, and identity controls.

> [!IMPORTANT]
> **&lt;TODO&gt; — Governance lab prerequisites:** Supply the prepared tenant, admin/test access, required services, agent registrations, policies, labeled documents, and test identities needed below. The script demonstrates configured controls; it does not provide their deployment instructions. Document the tested setup and exact navigation before treating this section as an executable security lab. Where unavailable, use the simulated demonstration and mark the live validation as pending.

### 1. Inspect the agent portfolio in Agent 365

1. In the prepared Microsoft 365 Admin Center, follow the script's **AI Agents** entry to Agent 365.
1. Inspect the registry and **Map** views. Discuss agent ownership, status, identity, and platform grouping.
1. Examine the Supply Chain Intelligence Agent and CMO Evaluation Agent. The script also shows demand sensing and manufacturing quality in its later fleet, and discusses Copilot Studio, Microsoft 365 Agent Toolkit, Foundry, and shadow agents in the portfolio view.
1. Record what is actually present in the lab and which entries are supplied for demonstration only.

> [!IMPORTANT]
> **&lt;TODO&gt; — Agent inventory and fleet continuity:** Provide the registrations, owners, platform assignments, and screenshots used in this exercise. The script's later four-agent fleet names supply chain intelligence, CMO evaluation, demand sensing, and manufacturing quality; it does not explain how the earlier CMO RFP Tracking Agent is represented in that count. Confirm the intended workshop inventory rather than inventing an additional deployment or silently changing the fleet count. Building demand sensing or manufacturing quality agents is not specified by the script.

### 2. Review the Foundry policy alert

1. In the prepared Foundry environment, open the **Operate** view and inspect the demonstrated out-of-compliance alert.
1. Follow the alert to **Compliance** and the **Policies** tab.
1. Review the guardrail compliance policy, the evaluated assets, and the recorded violation. The simulated story shows **four assets evaluated and one in violation**.
1. Record the policy and affected asset shown by the lab. Review the displayed cost and token-usage information as part of the operational context.

> [!IMPORTANT]
> **&lt;TODO&gt; — Reproducible policy alert:** Supply the policy definition, prepared test asset, alert-generation procedure, and expected evidence. The script does not supply a deployable guardrail policy configuration or a remediation procedure. Add those instructions and screenshots after rehearsal; do not deliberately alter workshop policies or introduce a violation based only on this narrative.

### 3. Compare identity-scoped capacity answers

1. Use the two facilitator-provided test identities representing the **Plant 3 Operations Manager** and the **VP of Manufacturing**.
1. Ask the same Supply Chain Intelligence Agent the same question under each identity:

   ```text
   What is our current capacity position — committed production versus maximum
   capacity by plant?
   ```

1. Compare the answers with the configured access assignments. In the story, the Plant 3 manager sees Plant 3 information, while the VP sees all three plants.
1. Check the supporting access evidence. The workshop should test the configured permissions, rather than rely on an agent instruction asking it to hide certain plants.

> [!IMPORTANT]
> **&lt;TODO&gt; — User access and identity propagation:** Provide the two test identities, source-level access configuration, assignments, and the tested end-to-end identity flow for this agent. The script attributes the scoped responses to Entra-based permissions but does not specify how the lab implements them. Supply expected allowed/denied evidence and screenshots before claiming the exercise proves access isolation.

### 4. Check restricted-content exclusion and audit evidence

1. Inspect the prepared restricted launch-planning document in the Caldova R&D SharePoint site. The story describes regulated manufacturing production plans and supplier agreements.
1. As the IT Compliance Lead, ask the Supply Chain Intelligence Agent:

   ```text
   Prepare an executive briefing on supplier readiness and manufacturing
   constraints, including any relevant launch-planning documents.
   ```

1. Inspect the response. In the simulation, Purview blocks the restricted content from being used; the briefing includes a note about its exclusion and does not reproduce the protected content.
1. Follow the related DLP rule match in **Purview Activity Explorer**, including its association with the agent identity.
1. Review the corresponding at-risk alert in **Agent 365** and match it to the demonstrated event.

> [!IMPORTANT]
> **&lt;TODO&gt; — Purview policy and restricted source:** Provide the approved test document/site, sensitivity label configuration, DLP policy and scope, retrieval connection, and role/access setup. The script describes the restricted content and resulting block but does not supply a deployable policy. Confirm which configured control enforces the exclusion and verify the content is absent from the answer; a label or an agent statement alone is not sufficient evidence.

> [!IMPORTANT]
> **&lt;TODO&gt; — Audit and alert correlation:** Supply the tested event-generation steps, Activity Explorer filters, agent identity mapping, expected log fields, and Agent 365 alert evidence. Document any observed event/alert delay during rehearsal instead of assigning an unsupported timing guarantee. Add screenshots that connect the prompt, exclusion, DLP event, and agent alert.

### 5. Inspect agent identity and network controls

1. Open the Supply Chain Intelligence Agent's details in Foundry. The script's **Identity and Access** card shows an **Entra Agent identity** and an **Entra Agent Blueprint**.
1. In the prepared Microsoft Entra Admin Center, open **Agents** and inspect the corresponding identity, owner, object ID, and applicable Conditional Access policies.
1. Review the facilitator-provided configuration evidence for the private endpoints, managed identities, and network isolation described in the story.
1. Record which controls have been verified and which are represented only by the simulated demonstration.

> [!IMPORTANT]
> **&lt;TODO&gt; — Identity and network implementation:** Provide the agent identity/blueprint setup, owner assignments, applicable Conditional Access policies, resource-specific managed identities, private endpoint and network configuration, and validation steps. The script does not define the topology or prove a configured lab's security boundary. Add the relevant screenshots and evidence before claiming that the workshop's data remains within that boundary.

## Workshop review

Review the three story outcomes with the facilitator:

| Outcome | Evidence to review |
| --- | --- |
| Ground an existing agent | Before-and-after capacity and competitor responses, cited GMP guidance, and the organizational escalation answer. |
| Reuse shared intelligence | The CMO Evaluation Agent's shared sources, the `CMO_Evaluation` extension, and RFP status grounded in procurement records. |
| Govern the agent portfolio | Ownership and identity records, role-scoped answers, the restricted-content exclusion, and the related policy/audit evidence. |

For each outcome, distinguish what was validated hands-on from what was reviewed in the simulated story. Record unresolved collaborator TODOs before declaring the corresponding lab capability complete.

The script illustrates faster decisions, reuse, and governed scale. It does not establish measured workshop timings, guaranteed cost savings, or regulatory certification for the lab.

## Existing screenshots awaiting collaborator review

> [!IMPORTANT]
> **&lt;TODO&gt; — Screenshot refresh:** The images below are retained from the previous lab so collaborators can replace them after the Caldova configuration is validated. They may show retail names, sample data, older setup choices, or the email-triggered workflow. They are reference material, not evidence of the Caldova results or instructions to execute the old workflow. Keep the current image files until replacements are available, then update the relevant Markdown references and remove obsolete reference entries. New Web IQ, CMO, and governance steps also need verified screenshots where applicable.

<details>
<summary>Previous lab screenshots retained for collaborators</summary>

**Earlier lab section: Step 0: Create a Power Platform Environment with Dataverse enabled**

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

**Earlier lab section: 3.1 Add the Foundry Chat Agent**

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

![](../Sandbox-Environment-Guides/Images/a80.png)

![](../Sandbox-Environment-Guides/Images/a81.png)

![](../Sandbox-Environment-Guides/Images/a82.png)

![](../Sandbox-Environment-Guides/Images/a83.png)

![](../Sandbox-Environment-Guides/Images/a84.png)

![](../Sandbox-Environment-Guides/Images/a85.png)

**Earlier lab section: 3.2: Add the Fabric Data Agent**

![](../Sandbox-Environment-Guides/Images/a86.png)

![](../Sandbox-Environment-Guides/Images/a87.png)

![](../Sandbox-Environment-Guides/Images/a88.png)

![](../Sandbox-Environment-Guides/Images/a89.png)

![](../Sandbox-Environment-Guides/Images/a82.png)

![](../Sandbox-Environment-Guides/Images/a90.png)

![](../Sandbox-Environment-Guides/Images/a91.png)

![](../Sandbox-Environment-Guides/Images/a92.png)

![](../Sandbox-Environment-Guides/Images/a93.png)

![](../Sandbox-Environment-Guides/Images/a94.png)

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

![](../Sandbox-Environment-Guides/Images/a116.png)

![](../Sandbox-Environment-Guides/Images/agentprompt.png)

![](../Sandbox-Environment-Guides/Images/Agentresponse.png)

</details>

### This completes the workshop walkthrough. Review any remaining prerequisites and validation items with the facilitator.
