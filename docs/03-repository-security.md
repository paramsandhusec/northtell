# Repository security

Controls enforced on `paramsandhusec/northtell`, each verified with `gh api`. A control is added here only once it is on.

| Control | Setting | What it stops |
|---|---|---|
| Branch ruleset on `main` | Pull request required, signed commits, squash merges only, linear history, no deletions, no force-pushes, no bypass list | Direct pushes to `main`, unsigned or spoofed commits, rewriting or deleting history |
| Secret scanning with push protection | On | Pushing a known provider credential (cloud keys, tokens) to the public repo |
| Dependabot alerts and security updates | On | Running dependencies with known vulnerabilities unnoticed |
| Default `GITHUB_TOKEN` permission | Read-only | A workflow step writing to the repo with more access than it needs |
| GitHub Actions approving pull requests | Not allowed | An automated identity approving its own change |
| Allowed actions | GitHub-created actions plus an explicit allow-list: `hashicorp/setup-terraform`, `terraform-linters/setup-tflint`, `bridgecrewio/checkov-action`, `gitleaks/gitleaks-action`, `azure/login`, `rhysd/actionlint` | A compromised or look-alike third-party action running in the pipeline |
| Actions pinned to a full commit SHA | Required | A moved or hijacked version tag swapping the code an action runs |
| Squash commit message | Pull request title and description | Losing the `Co-Authored-By` trailer that marks AI-assisted changes on `main` |
| Required status checks on `main` | `secrets` (gitleaks), `workflows` (actionlint) and `terraform` (fmt, validate, TFLint, tests, Checkov) must pass, reported only by GitHub Actions; branches must be up to date | Merging code, including AI-written code, that leaks a secret, breaks a workflow or fails infrastructure checks |
| Dependabot version updates | Weekly for GitHub Actions | Pinned actions drifting behind security fixes |
| Pre-commit hooks (local) | gitleaks and `terraform fmt` before every commit | A secret reaching a commit at all, before push protection or CI see it |

## How to verify

```bash
gh api repos/paramsandhusec/northtell/rulesets --jq '.[].name'
gh api repos/paramsandhusec/northtell --jq '.security_and_analysis'
gh api repos/paramsandhusec/northtell/actions/permissions --jq '{allowed_actions, sha_pinning_required}'
gh api repos/paramsandhusec/northtell/actions/permissions/selected-actions --jq '.patterns_allowed'
gh api repos/paramsandhusec/northtell/actions/permissions/workflow
gh api repos/paramsandhusec/northtell --jq '{squash_merge_commit_title, squash_merge_commit_message}'
gh api repos/paramsandhusec/northtell/rulesets/26004604 --jq '.rules[] | select(.type=="required_status_checks") | .parameters.required_status_checks[].context'
```
