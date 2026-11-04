# Northtell project charter

## Purpose
Northtell is a production-style, AI-assisted SIEM built on open-source tooling in Azure. It is designed, built, secured and operated end to end by one engineer, with security treated as part of the product rather than added afterwards.

## Problem statement
Small security teams drown in uncorrelated alerts. Northtell explores how rule-based correlation plus an AI layer can group related alerts into incidents, explain the links between them, and map them to MITRE ATT&CK, while keeping the AI layer itself secure.

## Objectives (v1)
| # | Objective | Evidence of done |
|---|-----------|------------------|
| O1 | Ingest Sysmon, pfSense, Azure activity, Entra ID, Exchange Online, Defender for Office 365 and Defender for Endpoint telemetry into Wazuh | Events from all seven sources visible and parsed |
| O2 | Detect a defined set of attacker techniques | Detections as code, each mapped to ATT&CK and validated by a simulated attack |
| O3 | AI layer groups correlated alerts into incidents, explains them and gives a verdict | Incident verdicts generated from real lab alerts, with accuracy measured against labeled attack runs |
| O4 | All infrastructure deployed as code with security scanning | Terraform with tflint and checkov in CI; no manual resources |
| O5 | Secure the platform itself | Threat model, hardened identity, budget kill switch, no secrets in repo |

## Scope
**In scope (v1)**
- Lab (ADR-0002): Wazuh, 2 Windows workstations, 1 domain controller, 1 pfSense firewall, 1 Kali attacker
- Wazuh as the SIEM with rule-based correlation
- Log sources: Sysmon, pfSense, Azure activity, Entra ID, Exchange Online, Defender for Office 365, Defender for Endpoint
- AI triage: enrichment, incident grouping, explanation, verdict
- MITRE ATT&CK mapping for every detection, with detections as code converted by sigma-cli and pySigma
- DevSecOps pipeline: protected main, signed commits, IaC scanning

**Out of scope (v1)**
- Northtell Console (Phase 4.5)
- Automated response actions
- Multi-tenant or customer-facing deployment
- Real personal or production data (lab data only)

## Constraints
- Budget: 100 CAD/month through November 2026 and 250 CAD/month from December 2026, enforced by Azure budget alerts and a kill switch at 90%
- One engineer, part-time
- Entra ID Free today; Entra ID P2 may come from the Microsoft 365 E5 developer sandbox (licensing decision pending)

## Open decisions
| Decision | Tracked in |
|----------|-----------|
| Where the lab VMs run (Azure, hybrid) | ADR-0002 (proposed) |
| Whether the AI layer may call an external model API, and which model | ADR-0003 (pending) |
| Licensing, tenant and subscription layout | ADR-0004 (pending) |
| Other open design decisions | [v1 design](02-v1-design.md), section 17 |

## Milestones
| Milestone | Target |
|-----------|--------|
| Phase 0: foundations (repo, identity, budget, docs) | Nov 2026 |
| First lab deployment | Dec 2026 |
| First demo: lab running, Wazuh ingesting, detections firing, phishing chain with a measured AI verdict | End of Jan 2027 |

## Success criteria
Northtell v1 is successful when a reviewer can clone the repo, read the docs, and see a simulated attack go from raw telemetry to an ATT&CK-mapped, AI-explained incident, with every design choice recorded in an ADR.
