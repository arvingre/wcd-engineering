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
Architecture Review   ─── Gate 1
  │
  ▼
Implementation Review ─── Gate 2 (includes Security Review where applicable)
  │
  ▼
Human Approval         ─── Gate 3
  │
  ▼
Merge                  ─── Human only
  │
  ▼
Validation
  │
  ▼
Memory Update
  │
  ▼
Close
```

A stage that has not met its Exit Criteria does not advance to the next stage — see `## Review Gates`. A Plan can also move straight to **Close** from any earlier stage if it's abandoned or superseded (see `docs/roadmap.md`'s `Closed` status) — that is a valid outcome, not a violation of the lifecycle, as long as Memory Update still records it.

### Stage detail

Each stage below states its Purpose, Owner, Input, Output, and Exit Criteria (the condition that must hold before the next stage can start).

#### 1. Idea

| | |
|---|---|
| Purpose | Capture an observed gap, request, or need before any formal commitment is made. |
| Owner | Human or OpenClaw |
| Input | A Roadmap gap, a user request, or a finding from a prior Review or Validation. |
| Output | A rough problem statement — not yet a formal Plan. |
| Exit Criteria | The idea is specific enough to write a Plan against. No branch, code, or infrastructure change exists yet — an Idea is not authorization to proceed. |

#### 2. Plan

| | |
|---|---|
| Purpose | Turn an Idea into a structured, scoped commitment everyone can review before any implementation starts. |
| Owner | OpenClaw drafts; Human confirms scope. |
| Input | An Idea. |
| Output | A structured Plan — objective, scope, tasks, constraints, deliverables — with a reserved `PLAN-XXXX` number in `docs/roadmap.md`. |
| Exit Criteria | Scope, constraints, and deliverables are explicit enough that Feature Branch work can start without re-litigating what's in or out of scope. No implementation exists yet — a Plan is a document, not code. |

#### 3. Feature Branch

| | |
|---|---|
| Purpose | Give the Plan an isolated place to be implemented without touching any shared branch. |
| Owner | Claude Code (or whichever agent/human is assigned the implementation). |
| Input | A confirmed Plan. |
| Output | A `feature/*` branch, created from the latest default/integration branch, with implementation work committed. |
| Exit Criteria | The branch contains a complete, self-consistent implementation of the Plan's scope — not a partial state — ready to open as a PR. Nothing has been committed or pushed to `main`/`lab` directly. |

#### 4. Draft PR

| | |
|---|---|
| Purpose | Make the work visible and reviewable without implying it's ready to merge. |
| Owner | Whoever did the implementation. |
| Input | A feature branch with committed changes. |
| Output | An open **Draft** pull request with a description covering summary, scope, and what was validated so far. |
| Exit Criteria | The PR description gives a reviewer everything needed to start Architecture Review without first asking clarifying questions. It stays Draft — not marked ready-for-review or merged — through every stage below until Human Approval. |

#### 5. Architecture Review — Gate 1

| | |
|---|---|
| Purpose | Confirm the design fits existing standards/ADRs, stays within the Plan's stated scope, and doesn't collapse identity or role boundaries — before investing further review effort in implementation detail. |
| Owner | Human and/or OpenClaw acting as reviewer — never the same actor that authored the PR. |
| Input | An open Draft PR. |
| Output | Architecture accepted, or sent back with requested changes. |
| Exit Criteria | No open architecture-level objection remains. Self-review by the PR's own author does not satisfy this. |

#### 6. Implementation Review — Gate 2 (includes Security Review)

| | |
|---|---|
| Purpose | Confirm the implementation is correct, clear, and within the Plan's constraints. **Security Review is a mandatory sub-check within this gate** — not a separate lifecycle stage — triggered whenever the change touches AWS identity/credentials, IAM, network exposure, or secrets, verifying the change doesn't violate `standards/security/identity-boundary.md` (no shared credentials, no `AdministratorAccess`, no `0.0.0.0/0` defaults). |
| Owner | Human and/or OpenClaw acting as reviewer. |
| Input | A PR that passed Architecture Review. |
| Output | Implementation accepted, or sent back with requested changes. |
| Exit Criteria | No open implementation or security objection remains. |

#### 7. Human Approval — Gate 3

| | |
|---|---|
| Purpose | A final, explicit human sign-off — distinct from either review above — before anything is allowed to merge. |
| Owner | Human, exclusively. |
| Input | A PR that passed Architecture Review and Implementation Review (including Security Review, where it applied). |
| Output | An explicit Approved status on the PR. |
| Exit Criteria | A human who is not the PR's own author has explicitly approved it. No AI agent approves its own or another agent's PR — approval, like merge, is a human action. |

#### 8. Merge — Human only

| | |
|---|---|
| Purpose | Land the change on the shared branch. |
| Owner | Human, exclusively — no AI agent merges anything, ever (`policies/ai-pull-request-policy.md`). |
| Input | An Approved PR. |
| Output | The change lands on `main` (or the project's integration branch, e.g. `lab`). |
| Exit Criteria | The merge commit exists on the target branch. A PR that hasn't cleared Gate 3 is never merged, regardless of who requests it. |

#### 9. Validation

| | |
|---|---|
| Purpose | Confirm the merged change actually does what the Plan intended — not just that it merged cleanly. This is the same check every Plan's own Validation checklist already asks for (e.g. "Registry 可以扩展到 100+ 项目"); this stage is where that checklist gets confirmed against the real, merged result instead of staying an aspiration inside the Plan document. |
| Owner | Whoever can actually check the outcome — GitHub/CI for machine-checkable Plans (tests, a `terraform plan` diff, link/structure checks), Human or OpenClaw for Plans validated by inspection (most documentation Plans). |
| Input | The merged change, and the Plan's own Validation checklist. |
| Output | Confirmation that every Validation criterion is met, or a finding that one isn't. |
| Exit Criteria | Every criterion in the Plan's Validation checklist is confirmed true. A failed criterion blocks Memory Update — it is not silently marked done. |

#### 10. Memory Update

| | |
|---|---|
| Purpose | Make sure the next agent session (or Loop run — see `architecture/engineering-loop.md`) starts from what's actually true instead of rediscovering it. |
| Owner | OpenClaw. |
| Input | A validated, merged change. |
| Output | Updated memory reflecting the new reality — project status, phase, standing decisions — **and** the Plan's `docs/roadmap.md` status/table placement updated to match (e.g. `Review` → `Merged`). Roadmap status is a form of Engineering-OS memory, so it's recorded as part of this stage rather than a separate one. |
| Exit Criteria | Memory and `docs/roadmap.md` both reflect the validated, merged state — not before, and never a status that isn't yet true. |

#### 11. Close

| | |
|---|---|
| Purpose | Give every Plan a definite, recorded end — whether it merged or not. |
| Owner | OpenClaw records it; Human can direct an early close from any earlier stage. |
| Input | A Memory-Updated Plan (normal path), or a Human decision to abandon/supersede a Plan at any earlier stage (early-close path). |
| Output | The Plan's status set to `Closed` in `docs/roadmap.md`, with a one-line reason if it closed early. |
| Exit Criteria | The Plan has a final status. No Plan is left indefinitely `In Progress`/`Review` with nothing tracking it. |

## Roles

| Role | Fundamental responsibility | AWS identity |
|---|---|---|
| **Human** | Final authority. The only role that can perform Human Approval and Merge (and, per `policies/ai-pull-request-policy.md`, Release/Tag/Production). Can force an early Close from any stage. | Own credentials, not a pipeline identity — out of scope for `standards/security/identity-boundary.md`. |
| **OpenClaw** | Planning, memory, review. Drafts Plans, reviews alongside or instead of a human at Gates 1–2, confirms Validation for inspection-based Plans, updates Memory (including Roadmap status) after merge. | None by default. |
| **Claude Code** | Implementation. Turns an approved Plan into a Feature Branch and Draft PR, responds to review feedback at Gates 1–2. | None by default. |
| **GitHub** | System of record for branches, PRs, reviews, and merge gating. Runs CI (`fmt`/`validate`/lint/security-scan, and only ever more than that for a specific, explicitly-approved workflow) via GitHub Actions — including machine-checkable Validation — and mechanically enforces that Merge cannot happen without the required review state. | GitHub OIDC, CI only, only if explicitly approved for a given workflow. |
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
| Human Approval | Human |
| Merge | Human, exclusively |
| Validation | GitHub (automated) or Human/OpenClaw (inspection) |
| Memory Update | OpenClaw |
| Close | OpenClaw records; Human can force early |

GitHub and HCP Terraform aren't "assigned" a stage the way the four actor roles above are — GitHub is the substrate Stages 3–9 execute on, and HCP Terraform activates only where a given Plan's implementation actually calls for it.

## Review Gates

Four gates, in order. **A Plan that has not passed a gate cannot enter the next stage — no exceptions for urgency, confidence, or a small-looking change.**

1. **Architecture Review** (Stage 5) — does the design fit, stay in scope, and respect existing identity/role boundaries?
2. **Implementation Review** (Stage 6) — is the implementation correct and within the Plan's constraints?
3. **Security Review** — not a separate stage; a mandatory sub-check inside Implementation Review, required whenever the change touches AWS identity, IAM, network exposure, or secrets.
4. **Human Approval Gate** (Stage 7) — final human sign-off, only after Gates 1–2 (and 3, where applicable) have passed.

## Artifacts and traceability

Every Plan produces some subset of six artifact types, each linking back to the one before it, so any artifact can be traced back to the Idea that started it:

| Artifact | Produced at | Always produced? |
|---|---|---|
| **Plan** | Stage 2 | Always |
| **PR** | Stage 4 | Always |
| **ADR** | Stage 5, when Architecture Review determines the Plan makes a decision with lasting impact (per `CONTRIBUTING.md`'s own definition of when to use one) | Conditional |
| **Review** | Stages 5–7 (review comments/records on the PR) | Always |
| **Memory** | Stage 10 | Always |
| **Roadmap** | Stages 2 (reserved) and 10 (updated as part of Memory Update) | Always |

**Worked example, from this repository's own history:** `PLAN-0001` (Plan) → `PR #1` (PR) → `ADR-0005` (ADR, because it was a lasting identity-boundary decision) → review comments on `PR #1` (Review) → this session's memory update (Memory) → `docs/roadmap.md`'s `PLAN-0001` row, status `Merged` (Roadmap, recorded as part of that same Memory Update stage). Each link is a direct reference (a PR number, an ADR filename, a `PLAN-XXXX` number) — not a paraphrase — so tracing from the Roadmap entry back to the original Idea never requires reconstructing history from memory.

## Design intent (validation)

- **Works for every project, not just this repository.** Nothing above is `wcd-engineering`-specific — a project repository (e.g. `devops-terraform-jenkins-eks`) follows the same eleven stages, the same four gates, the same roles; only the Feature Branch's base (`lab` there, `main` here), whether HCP Terraform activates, and what "Validation" checks (a smoke test there, document inspection here) differ per project.
- **Supports multiple AI agents.** Roles are defined by function (Planning/Memory/Review vs. Implementation vs. CI vs. Terraform execution), not by naming one specific agent — a new agent slots into an existing role instead of requiring a new one.
- **Does not depend on Terraform.** HCP Terraform is explicitly conditional (see Roles) — this document itself, and any documentation-only Plan, never invokes it.
- **Extensible.** New stages, gates, roles, or artifact types can be added by extending the tables above without breaking existing `PLAN-XXXX` records — this document describes the process, not any specific Plan's content, so it doesn't need to change every time a new Plan is added to `docs/roadmap.md`.

## Reference

- `docs/roadmap.md` — schedules *what* Plans exist and their status; this document defines *how* each one moves through its lifecycle.
- `policies/ai-pull-request-policy.md` — the Git-mechanics detail behind Stages 3–8 (branch/PR rules, what's prohibited/permitted for AI agents, human-only actions).
- `standards/security/identity-boundary.md`, `adr/ADR-0005-terraform-execution-identity.md` — the identity rules Architecture Review and the Security Review sub-check enforce.
- `architecture/project-registry.md` — where a project's own phase/status (as opposed to this repository's Plan status) is tracked.
- `architecture/engineering-loop.md` — what reads the Memory/Roadmap state this workflow's Stage 10 produces.
