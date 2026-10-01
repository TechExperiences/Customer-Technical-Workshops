# Caldova workshop gap decisions

We can retain the accelerator and most deployment steps. Use this table to agree which story outcomes we must implement and which details we can simplify before editing AYI02.

High = removing the change would undermine a core story outcome. Low = a small, explicit narrative adjustment can simplify or omit it. These are proposed priorities for discussion, not approved removals or estimates of implementation effort.

The final column asks: **Can we simplify or omit this change without losing the core story?** Low-priority recommendations preserve the named business capabilities where indicated.

| Main gap | What exists | Keep add or update | Why | Where in the story | Can simplify or omit? |
| --- | --- | --- | --- | --- | --- |
| Manufacturing capacity | Retail inventory and warehouse capacity. | Keep Fabric; add plant production, schedules and constraints. | Explain the 7% gap and need for external capacity. | M1: “7% network shortfall”; “Plant 3 the binding constraint”. | No — High |
| GMP knowledge | Supplier and operations PDFs; document retrieval. | Keep retrieval; add GMP, changeover and regulatory guidance. | Ground manufacturing options and required approvals. | M1: “Compressed Changeover Guidance”; plant manager and QA sign-offs. | No — High |
| Competitive evidence | Retail product data; no configured Web IQ path in export. | Add competitive records and tested web grounding. | Support the competing launch timeline with evidence. | M1: “Helios Biopharma’s VEXA”; announced November 2026 launch. | No — High |
| Cited grounded answers | Tool routing; exported prompt suppresses references. | Update scope and citations; test the same agent before and after grounding. | Demonstrate that connected evidence improves answers. | M1: agent initially lacks data; later gives a “cited, trustworthy decision”. | No — High |
| Work IQ context | Microsoft 365 connections and tools. | Keep tools; add organization and CMO interaction evidence. | Ground escalation and partner history in actual sources. | M1: Dana Reyes then Morgan Ellis. M2: prior email, Teams and document touchpoints. | No — High |
| CMO evaluation and reuse | Shared Fabric and Foundry foundation; generic agents. | Add CMO records and scoring evidence; demonstrate a new agent reusing the foundation. | Find external capacity and demonstrate reuse. | M2: “same Foundry IQ knowledge base”; score “responsiveness, quality, and speed”. | No — High |
| Scoped access and DLP | Entra authentication and resource RBAC. | Add plant-scoped access, protected content and audit tests. | Preserve the core trust and governance outcome. | M3: Plant 3 manager versus VP; “Purview blocks it”; logged DLP event. | No — High |
| Live Oracle ingestion | Fabric data loading. | Keep loading; use an approved CMO extract for the lab if agreed. | Source brand can change while pre-qualified CMO data remains. | M2: “from an Oracle database into the Fabric Lakehouse”. Label an extract as an adaptation. | Yes — Low |
| Exact agent count and separate RFP agent | Central orchestrator and document/data specialists. | Keep one clear new-agent reuse example; merge RFP status if retained; omit extra fleet agents. | Preserve evaluation and reuse without building every named agent. | M2: Alex’s RFP tracker. M3: four-agent fleet adds demand sensing and manufacturing quality. | Yes — Low |
| Exact hosting and knowledge layout | Copilot Studio orchestrates separate Fabric and Foundry tools. | Keep this routing; omit exact Foundry publishing and single-KB screens if agreed. | Business answers and shared reuse can remain unchanged. | M1–2: Foundry agents, “unified-knowledgebase”, publishing to Microsoft 365 Copilot. | Yes — Low |
| Full fleet admin demonstration | Foundry resources and ordinary diagnostics. | Keep access/DLP evidence; shorten registry, map, blueprint and alert walkthroughs. | A smaller governance demo can preserve the trust lesson. | M3: Agent 365 registry/map, guardrail violation, Entra Agent Blueprint. | Yes — Low |
| Private network build | Managed identities; template enables public networking. | Keep identities; defer private endpoints in the lab and remove isolation claims. | The perimeter detail can be a future-state discussion. | M3: “Private endpoints, managed identities, network isolation”. | Yes — Low |
| Continuous live refresh | Sample-data loading and indexing. | Use dated snapshots and a controlled refresh; remove real-time claims. | Repeatable lab evidence can support the same decision. | Overview: “refreshed in real time”. M1: “live manufacturing” and real-time web. | Yes — Low |

## Story references

Story source: Amplify Your Intelligence Demo Script (1).docx. M1 = Section 3, Ground Agents in the business context that compounds. M2 = Section 4, Accelerate Agent Deployment with Shared Intelligence. M3 = Section 5, Trust intelligence that drives scale (Security Deep Dive). Scene phrases in the table are searchable anchors; pagination varies by renderer.

## Discussion decisions

For each row, record **implement**, **simplify**, or **remove the scene**, and note the required story wording. For High rows, removal changes the core story and needs an explicit team decision. Preserve the capacity, policy, market, Work IQ, reuse and trust outcomes when simplifying Low rows.

The exact agent count is not a requirement: retain at least one clear new-agent reuse example. If RFP status remains in the workshop, it still needs real status evidence. If a Microsoft IQ pillar or the entire security module is removed, that is a larger story change.

## Files

- [Editable Word decision table](Caldova-Gap-Decisions.docx)
- [Detailed accelerator gap assessment](caldova-accelerator-gap-assessment.md)
- [Architecture recommendations](caldova-architecture-review.md)
- [Architecture image and notes](caldova-minimal-architecture-notes.md)

## Baseline

Reviewed [public accelerator commit 09a1224](https://github.com/microsoft/microsoft-iq-solution-accelerator/tree/09a1224156b39a0aeb73a50698ee39593a5bcbd6). Check the installed VM package before applying package-specific prompt changes. This assessment is based on source review; deployment validation remains part of the workshop work. The original Word story is referenced by filename and section and is not included in this folder.
