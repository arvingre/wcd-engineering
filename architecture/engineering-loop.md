# WCD Engineering Loop

## Purpose

The Engineering Loop is the recurring cycle that keeps the WCD Engineering OS oriented: read current state across every project, produce a report, recommend what to do next, and stop — never act on that recommendation itself. **OpenClaw runs this Loop by default.** It is read-only inspection plus a report; nothing in it merges a PR, applies Terraform, or starts implementation on its own.

## Who runs this (Task 5)

**OpenClaw runs the Engineering Loop.** This is one of OpenClaw's default, standing responsibilities (see `architecture/engineering-workflow.md`'s Roles: "Planning, memory, review").

**Claude Code does not run the Loop.** Claude Code's role is Implementation only — it is invoked to work a specific, already-approved Plan (`architecture/engineering-workflow.md` Stage 3, "Feature Branch"), not to decide what to work on next. The Loop's "Recommend Next Plan" output (Step 9 below) is what eventually hands Claude Code a Plan to implement — Claude Code is downstream of the Loop, never a participant in it.

## Loop steps (Task 1)

```
Read Project Registry
  │
  ▼
Read Roadmap
  │
  ▼
Read Active Plans
  │
  ▼
Inspect GitHub
  │
  ▼
Inspect Open PRs
  │
  ▼
Inspect HCP Terraform
  │
  ▼
Inspect CI
  │
  ▼
Generate Engineering Report
  │
  ▼
Recommend Next Plan
  │
  ▼
Wait Human Decision
```

1. **Read Project Registry** — `architecture/project-registry.md`: what projects exist, their Status, Owner, Local Path, Repository, and Related ADR/Standards. This is the loop's starting point for *which* repositories and workspaces to inspect in every later step — nothing below is hardcoded to one project.
2. **Read Roadmap** — `docs/roadmap.md`: Current Phase, and every `PLAN-XXXX`'s status across Completed/In Progress/Next/Future.
3. **Read Active Plans** — the Plans currently at `In Progress`/`Review`/`Approved` (not yet `Merged`/`Closed`): read their actual PR content and description, not just the Roadmap's one-line status, to catch drift between what the Roadmap says and what's really happening.
4. **Inspect GitHub** — for each repository from the Project Registry: current default/integration branch state, recent commits, whether anything moved since the last Loop run. Read-only.
5. **Inspect Open PRs** — for each repository: list open Draft PRs (from any AI agent or human), their `architecture/engineering-workflow.md` gate status (Architecture Review / Implementation Review / Approval), age, and whether they're stalled. Read-only — never comments, approves, or merges.
6. **Inspect HCP Terraform** — for each project with an `HCP Terraform Workspace` field in the Project Registry: workspace run history and whether state exists, via whatever read access is actually available (HCP Terraform's own UI/API reviewed by a human, or a scoped read-only token if one is explicitly provisioned — OpenClaw has no AWS or HCP Terraform credentials by default, per `standards/security/identity-boundary.md`, and this step never assumes otherwise). **Never triggers, plans, or applies a run** — inspection only.
7. **Inspect CI** — for each open PR: actual check results (`fmt`/`validate`/lint/security-scan, or a project's equivalent), not just the PR's Draft/non-Draft label.
8. **Generate Engineering Report** — synthesize Steps 1–7 into one structured status snapshot across every project: what's on track, what's blocked, what's stale, what's risky. See `## Loop Outputs`.
9. **Recommend Next Plan** — using the Report plus the Roadmap's `Next Plans` table, propose either a specific `PLAN-XXXX` to start, or — if the Report surfaced a blocker (a stalled PR, a failing gate, a stale Active Plan) — recommend resolving that first instead of starting new work.
10. **Wait Human Decision** — the Loop stops here. It does not open a branch, does not assign the recommended Plan to Claude Code, and does not do anything else on its own — the same "nothing advances without a human decision" principle as every gate in `architecture/engineering-workflow.md`.

## Loop Frequency (Task 2)

| Frequency | When | Depth |
|---|---|---|
| **Manual** | On demand — a human asks for a status check, or before starting new work. | Full loop (all 10 steps), same as any other run. |
| **Daily** | A lightweight standing cadence. | Steps 1–2 (Registry + Roadmap) plus a quick pass of Steps 4–5 (GitHub + open PRs) — enough to catch a stalled PR or drifted branch early, without the heavier HCP Terraform/CI inspection every time. |
| **Weekly** | A standing cadence for a fuller picture. | All 10 steps, including HCP Terraform and CI inspection — a complete Engineering Report. |
| **Release** | Around a Production-affecting change. | All 10 steps, with extra attention in the Report to Approval/Merge state and any Plan touching Production (`architecture/engineering-workflow.md`'s Merge stage, Human-only). |

All four are supported modes, not a single fixed schedule this document mandates — which cadence(s) actually run is an operational choice made where OpenClaw's own scheduling lives, not decided here.

## Loop Inputs (Task 3)

| Input | Consumed at | Read-only? |
|---|---|---|
| Project Registry | Step 1 | Yes |
| Roadmap | Step 2 | Yes |
| ADR | Steps 3, 8 — informs whether an Active Plan's direction still matches an adopted decision | Yes |
| Plans | Step 3 | Yes |
| GitHub | Steps 4–5 | Yes |
| Terraform (via HCP Terraform) | Step 6 | Yes — inspection only, see Step 6 above; never Plan/Apply |
| Memory | Steps 3, 8 — prior Loop findings and standing decisions inform the current pass | Yes (also an **output** — see below; the Loop reads prior Memory and writes updated Memory, a feedback loop across runs) |

## Loop Outputs (Task 4)

| Output | What it is |
|---|---|
| **Engineering Report** | The Step 8 synthesis — one structured snapshot of state across every project in the Registry. |
| **Risk** | Anything the Report surfaces that needs attention before it becomes a problem: a stalled PR, a failing CI check, a Plan stuck In Progress past a reasonable window, drift between Roadmap status and actual PR state, an approaching version-support deadline. Called out explicitly in the Report, not buried in a general summary. |
| **Recommendation** | The Loop's proposed action(s) from Step 9 — which could be "start a specific Plan" or "resolve this blocker before starting anything new." |
| **Next Plan** | The specific `PLAN-XXXX` recommended, when the Recommendation is to start new work — pulled from the Roadmap's `Next Plans` table, cross-checked against current Active Plans and Risks so it isn't recommended in isolation from what's already in flight. |
| **Memory Update** | The Loop's own closing action: record what this run found and recommended, so the next Loop run — and any Claude Code Implementation session that picks up the recommended Plan — starts from current state instead of rediscovering it. |

## Design intent (validation)

- **Multiple Repositories** — every step is driven by iterating the Project Registry (Step 1), not by naming one repository; adding a new project to the Registry is enough for the Loop to start covering it, no change to this document required.
- **Multiple AI** — Step 5 inspects open PRs regardless of which agent (Claude Code, or any future agent) opened them; the Loop itself only ever runs as OpenClaw (see `## Who runs this`), but what it inspects is agent-agnostic.
- **Multiple Projects** — same mechanism as Multiple Repositories: driven by the Registry, one project per entry, no fixed count.
- **Multiple Workspaces** — Step 6 iterates each project's own `HCP Terraform Workspace` field from the Registry rather than assuming a single workspace; a project with no Terraform (like `wcd-engineering` itself) is simply skipped at this step, not a special case the Loop needs to hardcode around.

## Reference

- `docs/roadmap.md` — read at Step 2; updated (as part of a Plan's own lifecycle, not by the Loop itself) via `architecture/engineering-workflow.md` Stage 10.
- `architecture/project-registry.md` — read at Step 1; the source of truth for which repositories/workspaces every later step covers.
- `architecture/engineering-workflow.md` — the per-Plan lifecycle the Loop's "Recommend Next Plan" output feeds into; also where the Human-only Merge/Approval rules this Loop respects (never acting on its own recommendation) are defined.
- `standards/security/identity-boundary.md` — why Step 6 (Inspect HCP Terraform) is read-only-by-construction: OpenClaw has no AWS or HCP Terraform credentials by default.
