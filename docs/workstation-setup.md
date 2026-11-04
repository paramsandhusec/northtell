# Workstation setup

Reproducible local toolchain for Northtell. Versions are the ones the project is tested with.

## Platform
- macOS, Apple Silicon (darwin_arm64), 24 GB RAM

## Toolchain

| Tool | Version | Purpose | Install |
|------|---------|---------|---------|
| Azure CLI | 2.90.0 | Azure auth and resource management | `brew install azure-cli` |
| Terraform | 1.17.1 | Infrastructure as code | `brew install hashicorp/tap/terraform` |
| TFLint | 0.65.0 (terraform ruleset 0.15.0) | Terraform linting | `brew install --cask terraform-linters/tap/tflint` |
| Checkov | 3.3.30 | IaC security scanning | `pipx install checkov` |
| sigma-cli | 4.0.0 | Sigma rule conversion for Wazuh | `pipx install sigma-cli` |
| pre-commit | 4.7.0 | Runs gitleaks and `terraform fmt` before every commit | `pipx install pre-commit`, then `pre-commit install` in the repo |
| gitleaks | 8.30.1 | Secret scanning (pinned in `.pre-commit-config.yaml`) | Installed by pre-commit |
| PowerShell | 7.6.9 | Runs the kill-switch runbook tests (Pester) | `brew install powershell` |

## Verify
    az version; terraform version; tflint --version; checkov --version; sigma version; pre-commit --version; pwsh --version

## Notes
- After any billing or subscription change, re-authenticate the CLI (see INC-002 in [incidents](incidents.md)).
