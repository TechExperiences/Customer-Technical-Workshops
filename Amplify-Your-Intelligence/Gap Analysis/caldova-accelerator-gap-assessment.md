# Caldova workshop: gaps beyond the Microsoft IQ accelerator

30 September 2026. This assessment incorporates the public accelerator. See the [decision table](README.md) for proposed High/Low priorities. Items below describe gaps against the full script; Low-priority details may be simplified only with the corresponding narrative adjustment.

**Keep the existing accelerator foundation.** The work is mainly scenario data, knowledge, instructions, additional agents/workflows, and demonstrated governance. Adding Web IQ alone does not deliver the full Caldova story.

## Evidence and boundaries

- Story authority: **Amplify Your Intelligence Demo Script (1).docx**, a simulated experience. Its screens establish desired story outcomes, not verified lab capabilities.
- Implementation reference: [public accelerator at commit 09a1224](https://github.com/microsoft/microsoft-iq-solution-accelerator/tree/09a1224156b39a0aeb73a50698ee39593a5bcbd6). Reviewed documentation, Fabric schemas, Foundry setup, Bicep, and the exported Copilot Studio solution contents.
- Workshop reference: local `main` at `5430300`. Its AYI02 also describes adding a Fabric tool to the Foundry agent. The VM may contain a different package from the latest public export; inspect its installed version and instructions before applying package-specific changes.
- AYI01 is already on remote `dev` in [commit 0371751](https://github.com/TechExperiences/Customer-Technical-Workshops/commit/03717515e771045f7aa70ade5c0627f843540cc0); the remote branch was verified at that commit. AYI02–04 remain unchanged by this gap-analysis update.

This is source/code analysis, not tenant or end-to-end validation. Recommendations below are implementation proposals, not additional Caldova business facts.

## Foundation to preserve

The [architecture](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/docs/TechnicalArchitecture.md) deliberately uses Copilot Studio as the central orchestrator. The [integration](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/docs/copilot/README.md) combines Fabric data, Foundry document retrieval, and Work IQ, with email-triggered Power Automate and Teams interaction.

Reuse the [Fabric lakehouse, semantic model, ontology, data agent and dashboards](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/docs/fabric/README.md), and the [Foundry PDF ingestion, Blob Storage, Search, knowledge base and MCP connection](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/docs/foundry/README.md).

There is no story-driven need to recreate resource groups or change resource names, regions, or capacity sizes. Preserve functioning setup, import, authentication, and publishing steps. If tool names change, update their prompt references consistently: the public [deployment guide](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/docs/copilot/DeploymentGuide.md) explicitly links external-agent names to its instructions.

## Gaps and minimum changes

| Area | Baseline | Missing for the story | Minimum adaptation |
| --- | --- | --- | --- |
| **Manufacturing capacity** | Retail products, warehouses, inventory, suppliers, orders and forecasts. | Plant production capacity, committed production, batch schedules, equipment qualification and fill-finish availability. | Extend the existing data/model/ontology with coherent manufacturing records and calculation definitions. They must support the 7% / approximately 18,900-unit shortfall and Plant 3 constraint for the relevant launch period. |
| **GMP knowledge** | Generic supplier, quality, inventory and delivery PDFs plus retrieval infrastructure. | Caldova GMP SOPs, scheduling, compressed-changeover and regulatory-change guidance; later, CMO qualification and scoring policies. | Load approved scenario documents through the existing pipeline. The Word script is not the deployable policy corpus. Missing documents or rules remain TODOs. |
| **Competitive intelligence** | Retail product data; no Web IQ integration in the inspected export. | Competitive-product records and dated external evidence for the Helios/VEXA launch comparison. | Add competitive records to Fabric and implement a tested web-grounding path. Obtain approved URLs or clearly labelled simulated evidence; do not assume public search will reproduce the simulated companies and announcements. |
| **Instructions and citations** | Retail-oriented tool routing; packaged instructions suppress sources and references. | Manufacturing questions, web grounding, combined reasoning and cited answers. | Adapt scope/routing and preserve source attribution through the final response. Keep expected business results out of system instructions. |
| **Organizational context** | Work IQ tools and Microsoft 365 connections; exported tools use invoker mode. | Scenario organization/escalation records and accessible emails, chats and documents; later, CMO interactions. | Prepare and verify the Microsoft 365 evidence used to identify plant/QA approvers, Dana Reyes and Morgan Ellis, and to assess CMO history. Connections alone do not provide that content. |
| **CMO evaluation and reuse** | Reusable Fabric and Foundry resources, one central orchestrator and one document agent. | CMO Evaluation Agent, Oracle pre-qualified CMO data, `CMO_Evaluation` ontology extension, evidence-backed scoring and capacity contribution. | Add the agent and source extension using existing resources. Obtain approved records and evaluation rules. An Oracle extract can be an agreed lab adaptation; it must not be presented as a live Oracle integration. Verify existing agents after extending the ontology. |
| **RFP tracking** | Supplier-email urgency triage, Teams notification and Work IQ mail capabilities. | Alex's separate RFP Tracking Agent and reliable status for shortlisted CMOs. | Add the agent and a status source, such as prepared correspondence or an existing tracking artifact. A new database is not inherently required. The script queries requests already sent; automatic dispatch is not required for that scene. |
| **Scoped access and DLP** | Entra authentication, managed identities and Azure resource RBAC. | Plant 3-only versus network-wide responses; restricted SharePoint content excluded by policy, with audit evidence. | Configure the actual data/document permissions and policy path. Test with two user identities and a labelled document. Resource RBAC alone does not prove these outcomes. |
| **Fleet governance and isolation** | Foundry resources and ordinary operational diagnostics. | Agent 365 inventory/alerts, agent identity and blueprint, demonstrated guardrail monitoring, and private connectivity. | Treat these as an explicit governance workstream. Validate tenant access, supported integrations and policy evidence. The supplied Foundry/Search template enables public networking. |
| **Freshness and repeatability** | Sample data, indexing and retail test cases. | Current scenario inputs, the same-agent before/after grounding sequence, consistent dates and reproducible outcomes. | Define refresh/as-of behavior, adapt test inputs, and validate in the VM. Preserve old screenshots with precise TODOs until replacements reflect a working lab. |

## Important code findings

1. **Warehouse capacity is not manufacturing capacity.** The [inventory schema](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/src/fabric/notebooks/schema/model_inventory.ipynb) defines `MaxCapacity` as maximum storage capacity. The dashboard measures warehouse utilization. Relabelling these would not support the production-shortfall story. Adapt dashboard measures only if using that dashboard to demonstrate the new scenario.
2. **The exported prompt conflicts with cited answers.** In the [solution ZIP](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/src/copilot/sln/MicrosoftIQAccelerator_1_0_0_3.zip), `botcomponents/crfaa_MicrosoftIQAgent.gpt.default/data` prohibits sources/references. Its built-in web browsing is disabled, and the export contains no Web IQ tool. Adding an icon will not implement grounding.
3. **Foundry is initially a document specialist.** [agent_api.py](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/infra/scripts/foundry/agent_api.py#L38) generates instructions saying database queries are unavailable. If retaining the workshop's additional Fabric tool on this agent, align its instructions. The script also prohibits direct document links despite the README's link-based citation description; verify actual displayed attribution.
4. **The flow is supplier-alert triage.** In the ZIP, `Workflows/WhenanewemailarrivesV3-41394E75-795B-F111-BEC7-7CED8D3D5C39.json` classifies urgent supplier messages and conditionally posts to Teams. Adapt its prompt if retaining email as the launch-capacity entry point. Regression-test its JSON response contract: the general agent prompt prohibits non-text responses.
5. **Private networking is not established by this deployment.** [deploy_ai_foundry.bicep](https://github.com/microsoft/microsoft-iq-solution-accelerator/blob/09a1224156b39a0aeb73a50698ee39593a5bcbd6/infra/deploy_ai_foundry.bicep#L153) enables public network access for Foundry and Search. This describes the template, not the user's deployed tenant.

## Architecture decisions

**Recommend retaining Copilot Studio orchestration as the workshop adaptation.** The Word script places the Supply Chain Intelligence and CMO Evaluation agents in Foundry and publishes them to Microsoft 365 Copilot. Retaining the current orchestrator is compatible with demonstrating the business reasoning, once required sources and tools work. Record this implementation difference in facilitator notes. If direct Foundry publishing is itself a required learning outcome, that path needs its own implementation and test.

Likewise, separate Fabric/Foundry tools can provide shared grounding without recreating the simulated screen's single `unified-knowledgebase` layout. If that exact UI is required, validate its connectors separately. Reusing resources does not automatically prove inherited data permissions or policies for each agent.

For the senior's diagram, retain the three platform columns; make manufacturing and competitive data explicit; expand Supplier Terms to include GMP/CMO knowledge; show Web IQ's external evidence path; add the CMO Evaluation and RFP Tracking agents using the shared foundation; change the entry event to launch-capacity planning; and add a governance band marked for implementation/validation. The accompanying image is a logical proposal, not a verified deployment diagram.

## Before updating AYI02

1. Inventory the working VM package, agents, instructions, tools and resource IDs. Do not upgrade the lab merely to match latest public `main`.
2. Agree the orchestration/publishing adaptation and which simulated screens must become hands-on exercises.
3. Obtain the scenario data and knowledge pack: manufacturing records and definitions, GMP documents, competitive evidence, organization context, CMO records/rules/interactions and RFP status evidence. Do not fabricate policies, scoring weights or results.
4. Preserve original deployment/navigation steps. Change scenario prompts, sources, routing/citations and only the connections that the new story requires.
5. Assign CMO reuse, RFP tracking and governance to the appropriate later exercises. All are needed for the full story; all do not need to be built inside AYI02.

## Verification needed

- Same agent: missing-data response before connection, grounded answer after connection.
- Capacity: consistent plant records, period, units and denominator supporting the shortfall and need for external manufacturing.
- Policy/escalation: source-backed GMP approval rules and organizational escalation.
- Competition: identifiable product record plus dated attributable announcement; explicit labelling of simulated material.
- CMO: evidence-backed scores and capacity contribution; support for the 3–6-month qualification claim; meaningful comparison against the scenario's as-of date and launch deadline.
- RFP: status reconciles with correspondence/tracking records, with no invented sent requests.
- Governance: actual scoped responses, content exclusion and audit/registry/policy evidence on the tested path.

The later four-agent fleet includes demand sensing and manufacturing quality, which are not built in the earlier scenes. Decide whether to pre-provision representative agents or retain that scene as a labelled simulation, without inventing additional functional exercises.

## Shareable team summary

We can retain the Microsoft IQ accelerator and most workshop deployment steps. The senior's diagram follows its intended Copilot Studio orchestration. Web IQ covers one missing part of the Caldova story, but we also need manufacturing data and measures, GMP documents, Microsoft 365 scenario context, citation/routing changes, CMO evaluation and RFP status capabilities, and the demonstrated governance controls. The immediate dependency for AYI02 is the scenario data and knowledge pack. Let's agree these assets and capabilities before replacing working instructions or screenshots.
