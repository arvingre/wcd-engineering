# Project: devops-terraform-jenkins-eks

## Identity

| Field | Value |
|-------|-------|
| GitHub Repo | `Arvingrep/devops-terraform-jenkins-eks` |
| GitHub URL | `git@github.com:Arvingrep/devops-terraform-jenkins-eks.git` |
| Local Path | `/Users/arvin/Documents/devops/repositories/infrastructure/devops-terraform-jenkins-eks` |
| Type | Infrastructure / AWS IaC |

## Git

| Field | Value |
|-------|-------|
| Default integration branch | `lab` |
| Stable branch | `main` |
| Current working branch | `feature/eks-lab-foundation` |
| Working directory | Project root (Terraform workspaces per environment) |

## Terraform

| Field | Value |
|-------|-------|
| HCP Terraform Workspace | Not yet configured — pending |
| State backend | S3 (configured per environment in `environments/lab/` and `environments/prod/`) |
| Remote execution | Not yet enabled |

## Credentials

> **OpenClaw and Claude Code do not have AWS credentials by default.**
>
> AWS operations require credentials injected at runtime via:
> - `aws-vault` (recommended)
> - Environment variables (`AWS_PROFILE`, `AWS_ACCESS_KEY_ID`, etc.)
> - IAM Instance Profile (for CI runners)
>
> Never commit credentials. Never store credentials in wcd-engineering.

## Current Phase (as of 2026-07-12)

- Phase 0 (IaC Foundation): **Completed** — merged to `lab`
- Phase 4a (EKS Design): **Completed** — docs merged to `lab`
- Phase 4b-1 (EKS Minimal Lab Foundation): **In progress** — branch `feature/eks-lab-foundation`

## High-Risk Restrictions

- No automatic PR merge
- No automatic Production Terraform Apply or Destroy
- No Terraform state modification without explicit approval
- No IAM privilege expansion without approval
- No EBS / S3 / EKS deletion without approval

## Standards Reference

Relevant standards in wcd-engineering:
- `standards/terraform/`
- `standards/aws/`
- `standards/kubernetes/`
- `standards/storage/`
- `standards/security/`
- `architecture/aws-eks-platform.md`
- `architecture/project-registry.md`
