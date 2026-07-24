# WCD Project Registry

## Purpose

The single, unified entry point OpenClaw (and any other AI agent — Claude Code included) uses to know what projects exist before starting work. **Any AI agent must read this registry before beginning work on a project it hasn't already loaded context for in the current session.** It answers: what projects exist, where their code lives, what state they're in, what Terraform execution platform they use, which ADRs/standards govern them, and what not to touch without approval — without requiring the agent to re-discover any of that by exploring the filesystem or guessing.

**What this registry is not:**
- Not a place for business logic, application design, or implementation detail — that lives in each project's own repository.
- Not a secrets store — no credentials, tokens, or connection strings, ever.
- Not a Terraform state store — workspace *names* are recorded as pointers (so an agent knows where state lives), never state *content*.

**Design intent:** this file is meant to scale to 100+ projects without restructuring. Each project gets one self-contained `###` entry under `## Projects`, following the shape in `## Project Template`. Adding project #101 should look exactly like adding project #2 did — a new subsection, not a schema change.

## Current Engineering OS Plan

| Field | Value |
|---|---|
| Active Plan | PLAN-0003 — Engineering Roadmap |
| Status | In Progress |
| Plan Sync | Pending — Memory Update step not yet complete |
| Last Updated | 2026-07-13 |
| Next Plan | PLAN-0004 — do not start until PLAN-0003 Plan Sync is closed |

> Plan lifecycle gate: PR merged → **Memory Updated** → Roadmap Updated → Closed.
> PLAN-0003 PR is merged to main; Memory Update is the remaining step.

## Projects

### dae-k8s

| Field | Value |
|---|---|
| Project Name | dae-k8s (K8sInsight) |
| Description | Kubernetes anomaly-detection / root-cause-analysis tool. Business logic lives in its own upstream repository; this workspace holds only the GitOps wiring (`labs/mac-platform-infra/lab/dae-k8s/`) for a lab-scale deployment. Detects Pod-level anomalies (CrashLoopBackOff, OOMKilled, ImagePullBackOff, FailedScheduling, Evicted, etc.), infers a root cause, and can notify via a generic outbound Webhook, Lark, or Telegram sink (`internal/notify/`). |
| Repository | `https://github.com/DAELabs/dae-k8s` — this fork has no `main` branch, so Argo CD does not pull from GitHub; a private Gitea mirror (`gitea_admin/dae-k8s`) is the actual sync source (see `lab/dae-k8s/README.md` → "仓库来源"). Updates require a manual push to the Gitea mirror. |
| Owner | TBD — not yet assigned to a specific person/team |
| Status | Active |
| Default Branch | `main` (Gitea mirror only — GitHub fork has no `main`) |
| Integration Branch | N/A |
| Local Path | Source: `/Users/arvin/Documents/devops/labs/DAELabs/dae-k8s`; GitOps wiring: `/Users/arvin/Documents/devops/labs/mac-platform-infra/lab/dae-k8s` |
| HCP Terraform Workspace | N/A |
| Execution Platform | Kubernetes (OrbStack, lab scale), synced by Argo CD from the Gitea mirror |
| Related ADR | None yet |
| Standards | None yet |
| Dependencies | Candidate future integration, not started: the generic Webhook sink (`internal/notify/sink/webhook.go`) emits an `AnomalyEvent` payload (`type/pod/namespace/message/rootCause/suggestion/dedupKey`) structurally matching `VISION.md`'s `### 1. Goal` "Monitoring / Alerts" source and its example Goal. See `LES-0001` in `memory/organization/lessons/`. Scoped to PLAN-0006 Bootstrap (Draft) — do not build a receiver ahead of that Plan opening. |

**Metadata**

| Field | Value |
|---|---|
| Type | Application / Observability tool (lab deployment) |
| Visibility | Private (Gitea mirror); GitHub fork visibility TBD |
| Primary Language | Go (backend), TypeScript/React (frontend) |
| Infrastructure | Kubernetes (OrbStack) |
| Cloud Provider | N/A — local lab cluster |
| Repository URL | `https://github.com/DAELabs/dae-k8s` |
| Workspace | N/A |
| Maintainer | TBD |

### devops-terraform-jenkins-eks

| Field | Value |
|---|---|
| Project Name | devops-terraform-jenkins-eks |
| Description | WCD's AWS Infrastructure-as-Code baseline — versioned Terraform modules (network, EKS, Jenkins, IAM, security, ECR, observability, DNS) deployed independently to `lab`/`staging`/`prod`. Originated as a Terraform+Jenkins+EKS tutorial project, being restructured into a long-term, repeatable, auditable template. |
| Repository | `https://github.com/Arvingrep/devops-terraform-jenkins-eks` |
| Owner | TBD — not yet assigned to a specific person/team; confirm before treating any approval as authoritative |
| Status | Active |
| Default Branch | `main` |
| Integration Branch | `lab` |
| Local Path | `/Users/arvin/Documents/devops/repositories/infrastructure/devops-terraform-jenkins-eks` |
| HCP Terraform Workspace | `operationarvin/infra-aws/devops-terraform-jenkins-eks` — exists and is VCS-connected (`execution-mode=local`, `auto-apply=false`), but **no code currently points at it** (no `cloud {}`/backend block in `environments/lab/versions.tf`). A push to this repo does not trigger a remote run today. |
| Execution Platform | Undecided (Proposed) — ADR-0002 in this project's own `docs/decisions/` weighs HCP Terraform Cloud against self-managed S3+DynamoDB; leaning HCP Terraform Cloud but not finalized. |
| Related ADR | This project: `docs/decisions/ADR-0001-environment-layout.md` (Adopted), `ADR-0002-terraform-state.md` (Proposed), `ADR-0003-github-oidc.md` (Proposed), `ADR-0004-lab-prod-strategy.md` (Adopted). Org-wide: `adr/ADR-0005-terraform-execution-identity.md` (this repo, Proposed) — defines the identity boundary this project's ADR-0002/ADR-0003 must conform to. |
| Standards | `standards/aws/eks.md`, `standards/terraform/module-standard.md`, `standards/terraform/environment-layout.md`, `standards/security/iam.md`, `standards/security/identity-boundary.md`, `architecture/aws-eks-platform.md` — all currently placeholder/draft in this repo, pointing back to this project as the reference implementation. |
| Dependencies | `modules/network` was a hard prerequisite for `modules/eks` (discovered mid-Phase-4b-1: the network module was still an unimplemented stub, so it became its own prerequisite PR rather than being folded into the EKS module PR). ADR-0002's backend decision blocks Phase 1 bootstrap work. Phase 4a's four design docs (`docs/eks-capacity-plan.md`, `docs/eks-node-group-design.md`, `docs/eks-scheduling-standard.md`, `docs/eks-storage-design.md`) were a hard gate on Phase 4b's `modules/eks` implementation. |

**Metadata**

| Field | Value |
|---|---|
| Type | Infrastructure / AWS IaC |
| Visibility | Public |
| Primary Language | HCL (Terraform), Bash |
| Infrastructure | VPC/networking, EKS, Jenkins (EC2, being replaced by `modules/jenkins`) |
| Cloud Provider | AWS |
| Repository URL | `https://github.com/Arvingrep/devops-terraform-jenkins-eks` |
| Workspace | `operationarvin/infra-aws/devops-terraform-jenkins-eks` (HCP Terraform Cloud) |
| Maintainer | TBD |

### wcd-engineering

| Field | Value |
|---|---|
| Repository | `https://github.com/arvingre/wcd-engineering` |
| Purpose | Engineering standards, architecture decisions, organizational knowledge, and AI agent operating rules for the WCD DevOps workspace. Defines what good looks like; project repositories implement it. Not a business application repository — no Terraform business logic, no state, no secrets. |
| Owner | TBD — not yet assigned to a specific person/team |
| Default Branch | `main` |
| Local Path | `/Users/arvin/Documents/devops/wcd-engineering` |
| Current Version | Unversioned — no release/tag scheme yet; treat `main` HEAD as current |
| Related ADR | `adr/ADR-0005-terraform-execution-identity.md` (Proposed) — the only ADR in this repo so far |

**Metadata**

| Field | Value |
|---|---|
| Type | Standards / Documentation / Governance |
| Visibility | Public |
| Primary Language | Markdown |
| Infrastructure | N/A |
| Cloud Provider | N/A |
| Repository URL | `https://github.com/arvingre/wcd-engineering` |
| Workspace | N/A — this repository has no Terraform of its own |
| Maintainer | TBD |

## Project Template

Copy this block under `## Projects` for each new project. Every field is required; use `TBD` rather than omitting a field or guessing a value.

```markdown
### <project-name>

| Field | Value |
|---|---|
| Project Name | |
| Description | |
| Repository | |
| Owner | |
| Status | Planning \| Active \| Maintenance \| Archived |
| Default Branch | |
| Integration Branch | |
| Local Path | |
| HCP Terraform Workspace | (or "N/A" if this project has no Terraform) |
| Execution Platform | |
| Related ADR | |
| Standards | |
| Dependencies | |

**Metadata**

| Field | Value |
|---|---|
| Type | |
| Visibility | Public \| Private \| Internal |
| Primary Language | |
| Infrastructure | |
| Cloud Provider | |
| Repository URL | |
| Workspace | |
| Maintainer | |
```

### Status definitions

- **Planning** — design/ADR phase; no implementation code has landed yet, or only scaffolding exists.
- **Active** — actively developed; PRs land regularly; the project is the current focus of real work.
- **Maintenance** — stable; only receives fixes and small updates, not new feature work.
- **Archived** — no longer maintained; kept for reference/history only. Do not propose new work here without first confirming it should be un-archived.

Every project entry in `## Projects` must have exactly one `Status` value from this list — no free-text status.
