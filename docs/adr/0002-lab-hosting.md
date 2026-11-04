# ADR-0002: Lab hosting in Azure, scaled-down v1 lab, scheduled runtime

- **Status:** Proposed
- **Date:** 2026-10-31
- **Deciders:** Paramveer Sandhu

## Context
The target lab is 5 Windows workstations, 1 server, 2 pfSense firewalls, 1 attacker device and Wazuh. Running all of it in Azure 24/7 costs roughly 3× the available budget. Running it locally is not viable: pfSense is x86-only and the workstation is Apple Silicon with 24 GB RAM.

Constraints:
- Budget: 100 CAD/month through November 2026, 250 CAD/month from December 2026, with a kill switch at 90%.
- Wazuh all-in-one requires 4 vCPU and 8 GiB RAM for up to 25 agents.
- Wazuh's cloud modules pull Azure, Entra ID and Microsoft 365 logs from APIs and catch up from a checkpoint when Wazuh starts, within each API's retention.

## Decision
Host the lab in Azure (Canada Central) with a scaled-down v1 footprint. The whole lab, Wazuh included, runs 8 hours a day on a schedule.

| Component | Count | Size (to verify) | Runtime |
|-----------|-------|------------------|---------|
| Wazuh all-in-one and Northtell triage service | 1 | B4as_v2 (4 vCPU, 16 GiB) | 8 h a day |
| Windows workstations | 2 | B2s | 8 h a day |
| Domain controller | 1 | B2s | 8 h a day |
| pfSense | 1 | B1ms | 8 h a day |
| Kali attacker | 1 | B2s | 8 h a day |

Scheduled start and stop is automated (Azure Automation or Start/Stop VMs v2), defined in Terraform. The schedule is a private Terraform variable, not published in the repository. Azure auto-shutdown alone only stops VMs.

## Cost
From the Azure retail price list, Canada Central, 2026-11-03 (Linux unless noted, about 243 hours a month):

| Item | Size | CAD/month |
|------|------|-----------|
| Wazuh and triage service | B4as_v2, 4 vCPU, 16 GiB | 57 |
| 2 workstations | B2s, Windows | 37 |
| Domain controller | B2s, Windows | 19 |
| Kali | B2s | 16 |
| pfSense | B1ms; Marketplace software fee not priced | 8 |
| Disks, billed even while VMs are off | Wazuh 256 GB Standard SSD (30); lab on Standard HDD (34) | 64 |
| Static public IP on pfSense WAN | 1 | 5 |
| Total | | about 206, plus egress and peering |

The kill switch fires at 225 CAD, leaving about 19 CAD of headroom, so egress, peering and the pfSense fee are measured in the first month.

Correction to the first draft of this ADR: it estimated Wazuh at about US$61 a month running 24/7 on B4als_v2. That size costs about US$108 a month at that runtime. Running Wazuh around the clock on B4as_v2 would bring the total to about 320 CAD, over the cap, which is why Wazuh now follows the 8-hour schedule.

## Consequences
**Positive**
- Real Azure telemetry and a realistic network path through pfSense.
- Fits the December budget at about 206 CAD a month.
- The full lab stays a clear v2 goal.

**Negative**
- 2 workstations limit lateral-movement scenarios in v1.
- Little budget headroom; cost must be monitored weekly.
- Lab is unavailable outside the scheduled window unless started manually.
- Cloud alerts are detected when Wazuh next starts, not in real time.
- If licensing option A is chosen (v1 design, section 16), Wazuh stays in the pay-as-you-go subscription and the lab VMs move to the Visual Studio subscription, connected by VNet peering (v1 design, section 15). Recorded in ADR-0004.

## Alternatives considered
| Option | Rejected because |
|--------|------------------|
| Full 9-VM lab in Azure, 24/7 | ~3× budget |
| Hybrid (endpoints on the Mac) | pfSense is x86-only; 24 GB RAM is insufficient |
| Full lab in Azure, scheduled | Still exceeds budget at the planned runtime |
| Scaled-down lab with Wazuh 24/7 | About 320 CAD a month, over the cap |

## Follow-ups
- Measure real costs in the first month and update this ADR.
- Raise the Azure budget and alert thresholds to 250 CAD in December, through Terraform.
- Entra ID log export requires P1/P2 licensing; tracked separately.
