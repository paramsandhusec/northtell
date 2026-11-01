# Northtell — Project charter

## Purpose
Northtell is a production-style, AI-assisted SIEM built on open-source tooling in Azure. It is designed, built, secured and operated end to end by one engineer, with security treated as part of the product rather than added afterwards.

## Problem statement
Small security teams drown in uncorrelated alerts. Northtell explores how rule-based correlation plus an AI layer can group related alerts into incidents, explain the links between them, and map them to MITRE ATT&CK — while keeping the AI layer itself secure.

## Objectives (v1)
| # | Objective | Evidence of done |
|---|-----------|------------------|
| O1 | Ingest Azure, Entra ID, firewall and Sysmon telemetry into Wazuh | Events from all four sources visible and parsed |
| O2 | Detect a defined set of attacker techniques | Detections as code, each mapped to ATT&CK and validated by a simulated attack |
| O3 | AI layer groups correlated alerts into incidents and explains them | Incident summaries generated from real lab alerts |
| O4 | All infrastructure deployed as code with security scanning | Terraform with tflint and checkov in CI; no manual resources |
| O5 | Secure the platform itself | Threat model, hardened identity, budget kill switch, no secrets in repo |

## Scope
**In scope (v1)**
- Lab: 5 workstations, 1 server, 2 pfSense firewalls, 1 attacker device
- Wazuh as the SIEM with rule-based correlation
- Log sources: Azure activity, Entra ID, pfSense, Sysmon
- AI triage: enrichment, incident grouping, explanation
- MITRE ATT&CK mapping for every detection
- DevSecOps pipeline: protected main, signed commits, IaC scanning

**Out of scope (v1)**
- Northtell Console (Phase 4.5)
- Automated response actions
- Multi-tenant or customer-facing deployment
- Real personal or production data — lab data only

## Constraints
- Budget: 100 CAD/month (may rise to 150), enforced by Azure budget alerts and a kill switch at 90%
- One engineer, part-time
- Entra ID Free today; 5 Entra ID P2 licenses planned

## Open decisions
| Decision | Tracked in |
|----------|-----------|
| Where the lab VMs run (Azure, hybrid) | ADR (pending) |
| Whether the AI layer may call an external model API | ADR (pending) |
| Which AI model to use | ADR (pending) |

## Milestones
| Milestone | Target |
|-----------|--------|
| Phase 0 — foundations (repo, identity, budget, docs) | Nov 2026 |
| First demoable version: lab running, Wazuh ingesting, first detections firing | End of Jan 2027 |

## Success criteria
Northtell v1 is successful when a reviewer can clone the repo, read the docs, and see a simulated attack go from raw telemetry to an ATT&CK-mapped, AI-explained incident — with every design choice recorded in an ADR.
