# ADR-0002: Lab hosting — Azure, scaled-down v1 lab, scheduled runtime

- **Status:** Proposed
- **Date:** 2026-10-31
- **Deciders:** Paramveer Sandhu

## Context
The target lab is 5 Windows workstations, 1 server, 2 pfSense firewalls, 1 attacker device and Wazuh. Running all of it in Azure 24/7 costs roughly 3× the available budget. Running it locally is not viable: pfSense is x86-only and the workstation is Apple Silicon with 24 GB RAM.

Constraints:
- Budget: 100 CAD/month through November 2026, 250 CAD/month from December 2026, with a kill switch at 90%.
- Wazuh all-in-one requires 4 vCPU and 8 GiB RAM for up to 25 agents.
- Wazuh must stay on to collect Azure and Entra ID logs continuously.

## Decision
Host the lab in Azure (Canada Central) with a scaled-down v1 footprint. Lab VMs run on a schedule; Wazuh runs continuously.

| Component | Count | Size (to verify) | Runtime |
|-----------|-------|------------------|---------|
| Wazuh all-in-one | 1 | B4als_v2 (4 vCPU, 8 GiB) | 24/7 |
| Windows workstations | 2 | B2s | Scheduled |
| Domain controller | 1 | B2s | Scheduled |
| pfSense | 1 | B1ms or B2s | Scheduled |
| Kali attacker | 1 | B2s | Scheduled |

Scheduled start and stop is automated (Azure Automation or Start/Stop VMs v2), defined in Terraform. The schedule is a private Terraform variable, not published in the repository. Azure auto-shutdown alone only stops VMs.

## Cost estimate (to verify in the Azure Pricing Calculator)
| Item | Basis | Estimate (USD/month) |
|------|-------|----------------------|
| Wazuh | ~0.084/hr × 730 h | ~61 |
| 5 lab VMs | ~0.046/hr Linux rate × scheduled hours | ~56 + Windows licensing for 3 VMs |
| Managed disks, public IPs, egress | 6 VMs | to verify |

Windows licensing, disk and pfSense marketplace costs are unverified. The estimate is close to the 250 CAD cap and must be confirmed before deployment.

## Consequences
**Positive**
- Real Azure telemetry and a realistic network path through pfSense.
- Fits the December budget if the estimate holds.
- The full lab stays a clear v2 goal.

**Negative**
- 2 workstations limit lateral-movement scenarios in v1.
- Little budget headroom; cost must be monitored weekly.
- Lab is unavailable outside the scheduled window unless started manually.

## Alternatives considered
| Option | Rejected because |
|--------|------------------|
| Full 9-VM lab in Azure, 24/7 | ~3× budget |
| Hybrid (endpoints on the Mac) | pfSense is x86-only; 24 GB RAM is insufficient |
| Full lab in Azure, scheduled | Still exceeds budget at the planned runtime |

## Follow-ups
- Verify costs in the Azure Pricing Calculator and update this ADR.
- Raise the Azure budget and alert thresholds to 250 CAD in December, through Terraform.
- Entra ID log export requires P1/P2 licensing; tracked separately.
