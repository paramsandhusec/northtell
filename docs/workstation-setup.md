### INC-001: Azure subscription disabled before first deployment
- **Date:** 2026-10-29
- **Symptom:** Portal showed "Azure subscription 1" as Disabled; no resources could be created.
- **Root cause:** free trial expired 
- **Resolution:** upgraded to Pay-As-You-Go via portal banner
- **Prevention:** Monthly budget `guardrail-manual` (100 CAD) with alerts at 50%, 80%, 100% actual and 100% forecasted, verified via the Budgets REST API.

### INC-002: Azure CLI reported stale subscription state
- **Date:** 2026-10-29
- **Symptom:** Portal showed Active; `az account show` reported Disabled, and `az consumption budget list` returned nothing.
- **Root cause:** Azure CLI caches subscription metadata at `az login`; the login predated reactivation.
- **Resolution:** `az account clear && az login`
- **Prevention:** Re-authenticate the CLI after any billing or subscription state change. Verify through the API (`az rest`), not only the portal.
