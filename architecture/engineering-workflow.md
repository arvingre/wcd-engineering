# WCD Engineering Workflow

## Purpose

This is the default workflow for the entire WCD Engineering OS — the one lifecycle every engineering task moves through, from first idea to closed record, regardless of which repository it touches or which AI agent (or human) does the work. `docs/roadmap.md` schedules *what* gets worked on; this document defines *how* every one of those Plans actually moves from start to finish. Both humans and AI agents follow it — there is no separate, faster path for either.

This generalizes and gives full shape to the PR mechanics already established in `policies/ai-pull-request-policy.md` (PLAN-0004) — that policy is the Git-level slice of Stages 3–8 below; this document is the whole lifecycle around it, including what happens before a branch exists and after a PR merges.

## Lifecycle

```
Idea
  │
  ▼
Plan
  │
  ▼
Feature Branch
  │
  ▼
Draft PR
  │
  ▼
Architecture Review  ─── Gate 1
  │
  ▼
Implementation Review ─── Gate 2 (includes Security Review where applicable)
  │
  ▼
Approval             ─── Gate 3
  │
  ▼
Merge                ─── Human only
  │
  ▼
Memory Update
  │
  ▼
Roadmap Update
  │
  ▼
Close
```

A stage that has not passed its gate does not advance to the next stage — see `## Review Gates`. A Plan can also move straight to **Close** from any earlier stage if it's abandoned or superseded (see `docs/roadmap.md`'s `Closed` status) — that is a valid outcome, not a violation of the lifecycle, as long as Roadmap Update still records it.

### Stage detail

Each stage below states its Input, Output, Owner (who is responsible for that stage happening), Allowed actions, and Forbidden actions.

#### 1. Idea

| | |
|---|---|
| Input | An observed gap, request, or need — a Roadmap gap, a user request, a finding from a prior Review. |
| Output | A rough problem statement — not yet a formal Plan. |
| Owner | Human or OpenClaw |
| Allowed | Discuss, write informal notes, propose. |
| Forbidden | Opening a branch, writing implementation code/infra, or treating an Idea as authorization to proceed — an Idea is not a Plan. |

#### 2. Plan

| | |
|---|---|
| Input | An Idea. |
| Output | A structured Plan: objective, scope, tasks, constraints, deliverables — the same shape every `PLAN-XXXX` in `docs/roadmap.md` follows. |
| Owner | OpenClaw drafts; Human confirms scope before it moves forward. |
| Allowed | Define objective/scope/tasks/constraints, assign or reserve a `PLAN-XXXX` number in `docs/roadmap.md`. |
| Forbidden | Any implementation, opening a branch or PR — a Plan is a document, not code. |

#### 3. Feature Branch

| | |
|---|---|
| Input | A confirmed Plan. |
| Output | A `feature/*` branch, created from the latest default/integration branch, with implementation work committed. |
| Owner | Claude Code (or whichever agent/human is assigned the implementation) |
| Allowed | Create the branch, commit, push, rebase, and force-push *that same branch*. |
| Forbidden | Committing or pushing to `main`/`lab` directly, touching any other branch without being asked. |

#### 4. Draft PR

| | |
|---|---|
| Input | A feature branch with committed changes. |
| Output | An open, **Draft** pull request with a description covering summary, scope, and what was validated. |
| Owner | Whoever did the implementation (Claude Code, or Human). |
| Allowed | Open the Draft PR, push further commits to it, edit its description. |
| Forbidden | Marking it ready-for-review or merging it — it stays Draft through every review gate below until Approval. |

#### 5. Architecture Review — Gate 1

| | |
|---|---|
| Input | An open Draft PR. |
| Output | Architecture accepted or sent back with requested changes. |
| Owner | Human and/or OpenClaw acting as reviewer — never the same actor that authored the PR. |
| Allowed | Comment, request changes, check the PR against existing standards/ADRs/roadmap scope, approve this gate. |
| Forbidden | Advancing to Implementation Review without this gate passing; self-review by the PR's own author. |
| Checks | Does the design fit existing standards and ADRs? Does it stay within the Plan's stated scope (no undisclosed scope creep)? Does it avoid collapsing roles/identities that `standards/security/identity-boundary.md` keeps separate? |

#### 6. Implementation Review — Gate 2 (includes Security Review)

| | |
|---|---|
| Input | A PR that passed Architecture Review. |
| Output | Implementation accepted or sent back with requested changes. |
| Owner | Human and/or OpenClaw acting as reviewer. |
| Allowed | Comment, request changes, approve this gate. |
| Forbidden | Advancing to Approval without this gate passing. |
| Checks | Correctness, clarity, adherence to the Plan's constraints. **Security Review is a mandatory sub-check within this gate** — not a separate lifecycle stage — triggered whenever the change touches AWS identity/credentials, IAM, network exposure, or secrets; it verifies the change doesn't violate `standards/security/identity-boundary.md` (no shared credentials, no `AdministratorAccess`, no `0.0.0.0/0` defaults) before Implementation Review can pass. |

#### 7. Approval — Gate 3

| | |
|---|---|
| Input | A PR that passed both Architecture Review and Implementation Review (and Security Review, where it applied). |
| Output | An explicit Approved status on the PR. |
| Owner | Human. |
| Allowed | Approve. |
| Forbidden | Self-approval; approving a PR that hasn't passed Gates 1–2; an AI agent approving its own or another agent's PR — approval, like merge, is a human action. |

#### 8. Merge — Human only

| | |
|---|---|
| Input | An Approved PR. |
| Output | The change lands on `main` (or the project's integration branch, e.g. `lab`). |
| Owner | **Human, exclusively.** No AI agent merges anything, ever — see `policies/ai-pull-request-policy.md`. |
| Allowed | Human clicks merge. |
| Forbidden | Any AI agent merging, or a human merging a PR that hasn't cleared Gate 3. |

#### 9. Memory Update

| | |
|---|---|
| Input | A merged change. |
| Output | Updated memory reflecting the new reality — project status, phase, standing decisions. |
| Owner | OpenClaw. |
| Allowed | Update memory records to match what actually merged. |
| Forbidden | Skipping this stage because the merge "feels done" — a merge not reflected in memory is stale information for the next agent session; recording a status that isn't yet true (e.g. writing "Merged" before it is). |

#### 10. Roadmap Update

| | |
|---|---|
| Input | A merged, memory-updated change. |
| Output | `docs/roadmap.md`'s entry for this Plan moved to its new status (e.g. `Review` → `Merged`) and, if applicable, into the right table. |
| Owner | OpenClaw. |
| Allowed | Update the Plan's status and table placement. |
| Forbidden | Renumbering an existing `PLAN-XXXX` — numbers are stable identifiers, not reordered for tidiness. |

#### 11. Close

| | |
|---|---|
| Input | A Roadmap-updated Plan (normal path), or a Human decision to abandon/supersede a Plan at any earlier stage (early-close path). |
| Output | The Plan's status set to `Closed` in `docs/roadmap.md`, with a one-line reason if it closed early. |
| Owner | OpenClaw records it; Human can direct an early close from any stage. |
| Allowed | Mark Closed, with reason if early. |
| Forbidden | Leaving a Plan in limbo — every Plan reaches `Closed` eventually, even ones that never merged. |

## Roles

| Role | Fundamental responsibility | AWS identity |
|---|---|---|
| **Human** | Final authority. The only role that can perform Approval and Merge (and, per `policies/ai-pull-request-policy.md`, Release/Tag/Production). Can force an early Close from any stage. | Own credentials, not a pipeline identity — out of scope for `standards/security/identity-boundary.md`. |
| **OpenClaw** | Planning, memory, review. Drafts Plans, reviews alongside or instead of a human at Gates 1–2, updates Memory and Roadmap after merge. | None by default. |
| **Claude Code** | Implementation. Turns an approved Plan into a Feature Branch and Draft PR, responds to review feedback at Gates 1–2. | None by default. |
| **GitHub** | System of record for branches, PRs, reviews, and merge gating. Runs CI (`fmt`/`validate`/lint/security-scan, and only ever more than that for a specific, explicitly-approved workflow) via GitHub Actions, and mechanically enforces that Merge cannot happen without the required review state. | GitHub OIDC, CI only, only if explicitly approved for a given workflow. |
| **HCP Terraform** | For Plans whose implementation touches Terraform-managed infrastructure in a project repository: Terraform Plan, Apply, and State, exclusively. **Conditional, not universal** — a Plan that doesn't touch Terraform (including every Plan in this repository, which has none) never invokes this role. | HCP Terraform OIDC. |

Same non-overlap rule as `standards/security/identity-boundary.md`: GitHub's role never extends to Terraform plan/apply/state, and HCP Terraform's role never extends to arbitrary CI tasks.

### Stage → role quick reference

| Stage | Responsible role(s) |
|---|---|
| Idea | Human or OpenClaw |
| Plan | OpenClaw (drafts), Human (confirms) |
| Feature Branch | Claude Code |
| Draft PR | Claude Code |
| Architecture Review | Human and/or OpenClaw |
| Implementation Review (+ Security Review) | Human and/or OpenClaw |
| Approval | Human |
| Merge | Human, exclusively |
| Memory Update | OpenClaw |
| Roadmap Update | OpenClaw |
| Close | OpenClaw records; Human can force early |

GitHub and HCP Terraform aren't "assigned" a stage the way the four actor roles above are — GitHub is the substrate Stages 3–8 execute on, and HCP Terraform activates only where a given Plan's implementation actually calls for it.

## Review Gates

Four gates, in order. **A Plan that has not passed a gate cannot enter the next stage — no exceptions for urgency, confidence, or a small-looking change.**

1. **Architecture Review** (Stage 5) — does the design fit, stay in scope, and respect existing identity/role boundaries?
2. **Implementation Review** (Stage 6) — is the implementation correct and within the Plan's constraints?
3. **Security Review** — not a separate stage; a mandatory sub-check inside Implementation Review, required whenever the change touches AWS identity, IAM, network exposure, or secrets.
4. **Approval Gate** (Stage 7) — final human sign-off, only after Gates 1–2 (and 3, where applicable) have passed.

## Artifacts and traceability

Every Plan produces some subset of six artifact types, each linking back to the one before it, so any artifact can be traced back to the Idea that started it:

| Artifact | Produced at | Always produced? |
|---|---|---|
| **Plan** | Stage 2 | Always |
| **PR** | Stage 4 | Always |
| **ADR** | Stage 5, when Architecture Review determines the Plan makes a decision with lasting impact (per `CONTRIBUTING.md`'s own definition of when to use one) | Conditional |
| **Review** | Stages 5–7 (review comments/records on the PR) | Always |
| **Memory** | Stage 9 | Always |
| **Roadmap** | Stages 2 and 10 (reserved at Plan time, updated at Roadmap Update) | Always |

**Worked example, from this repository's own history:** `PLAN-0001` (Plan) → `PR #1` (PR) → `ADR-0005` (ADR, because it was a lasting identity-boundary decision) → review comments on `PR #1` (Review) → this session's memory update (Memory) → `docs/roadmap.md`'s `PLAN-0001` row, status `Merged` (Roadmap). Each link is a direct reference (a PR number, an ADR filename, a `PLAN-XXXX` number) — not a paraphrase — so tracing from the Roadmap entry back to the original Idea never requires reconstructing history from memory.

## Design intent (validation)

- **Works for every project, not just this repository.** Nothing above is `wcd-engineering`-specific — a project repository (e.g. `devops-terraform-jenkins-eks`) follows the same eleven stages, the same four gates, the same roles; only the Feature Branch's base (`lab` there, `main` here) and whether HCP Terraform activates differ per project.
- **Supports multiple AI agents.** Roles are defined by function (Planning/Memory/Review vs. Implementation vs. CI vs. Terraform execution), not by naming one specific agent — a new agent slots into an existing role instead of requiring a new one.
- **Does not depend on Terraform.** HCP Terraform is explicitly conditional (see Roles) — this document itself, and any documentation-only Plan like PLAN-0001–0004, never invokes it.
- **Extensible.** New stages, gates, roles, or artifact types can be added by extending the tables above without breaking existing `PLAN-XXXX` records — this document describes the process, not any specific Plan's content, so it doesn't need to change every time a new Plan is added to `docs/roadmap.md`.

## Reference

- `docs/roadmap.md` — schedules *what* Plans exist and their status; this document defines *how* each one moves through its lifecycle.
- `policies/ai-pull-request-policy.md` — the Git-mechanics detail behind Stages 3–8 (branch/PR rules, what's prohibited/permitted for AI agents, human-only actions).
- `standards/security/identity-boundary.md`, `adr/ADR-0005-terraform-execution-identity.md` — the identity rules Architecture Review and the Security Review sub-check enforce.
- `architecture/project-registry.md` — where a project's own phase/status (as opposed to this repository's Plan status) is tracked.
