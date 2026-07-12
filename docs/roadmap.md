# WCD Engineering Roadmap

## Vision

`docs/roadmap.md` is the single task-scheduling center for the whole WCD Engineering OS. Every future Plan, ADR, and PR is organized around this roadmap — an agent (OpenClaw, Claude Code, or any other) deciding what to work on next starts here, not by independently inventing priorities. This file doesn't belong to any one project; it sits above `architecture/project-registry.md` (which tracks project *state*) and coordinates the *engineering-OS-building* work itself: standards, policies, memory, bootstrap, agent roles — the things every project repository depends on but that live in this repository.

## Plan status vocabulary

Every Plan uses exactly one of these statuses — no free-text status:

- **Draft** — Plan written, no branch/PR opened yet.
- **In Progress** — an agent is actively working the Plan (branch created, commits landing).
- **Review** — Draft PR open, awaiting human (and/or peer-agent) review.
- **Approved** — reviewed and accepted, awaiting merge.
- **Merged** — PR merged to `main`.
- **Closed** — Plan ended without merging (superseded, abandoned, or folded into another Plan) — a valid, non-failure outcome, not silently dropped.

## Plan lifecycle

```
Plan
  │
  ▼
Draft PR
  │
  ▼
Review
  │
  ▼
Approved
  │
  ▼
Merged
  │
  ▼
Memory Updated
  │
  ▼
Closed
```

"Merged" is not the finish line — a Plan whose merge isn't reflected in `memory/`/`architecture/project-registry.md` afterward is only half done (see `policies/ai-pull-request-policy.md`, which this lifecycle's PR-related steps implement).

## Current Phase

Bootstrapping the Engineering OS itself: identity/workflow boundaries and the project registry are in place; the roadmap that ties future work together is this Plan. Next up is making the runtime pieces (memory, bootstrap, agent roles) match the same level of rigor, then the content-heavy standards/playbooks/templates work that depends on all of the above being solid first.

## Completed Plans

| Plan | Title | Status | Related PR |
|---|---|---|---|
| PLAN-0001 | Identity Boundary | Merged | [#1](https://github.com/arvingre/wcd-engineering/pull/1) |
| PLAN-0002 | Project Registry | Merged | [#2](https://github.com/arvingre/wcd-engineering/pull/2) |

## In Progress

| Plan | Title | Status | Related PR |
|---|---|---|---|
| PLAN-0003 | Engineering Roadmap | In Progress | (this Plan — Draft PR opens with this file) |
| PLAN-0004 | AI Pull Request Policy | Review | [#3](https://github.com/arvingre/wcd-engineering/pull/3) (open) |

## Next Plans

Reserved, not yet started — numbers and titles fixed so future work references them consistently, content not designed yet:

| Plan | Title | Status |
|---|---|---|
| PLAN-0005 | Engineering Memory | Draft |
| PLAN-0006 | Bootstrap | Draft |

## Future Plans

Reserved, further out — depend on PLAN-0005/PLAN-0006 landing first:

| Plan | Title | Status |
|---|---|---|
| PLAN-0007 | Agent Roles | Draft |
| PLAN-0008 | Engineering Standards | Draft |
| PLAN-0009 | Playbooks | Draft |
| PLAN-0010 | Templates | Draft |

## Design intent

- **Scales to hundreds of Plans without restructuring** — each Plan is one row in one of the tables above, referenced by a stable `PLAN-XXXX` number; moving a Plan between sections (e.g. Next → In Progress) is a row move, not a schema change.
- **Not project-specific** — this roadmap tracks work on the Engineering OS itself (standards, policies, memory, bootstrap, agent roles, this roadmap). Project-level work (e.g. `devops-terraform-jenkins-eks`'s own migration-plan phases) is tracked in that project's own repository and reflected only as a `Status`/`Related ADR` pointer in `architecture/project-registry.md`, not duplicated here.
- **An agent can determine its next step from this file alone**: read `## In Progress` first (finish what's started before opening something new), then `## Next Plans` in order. A Plan is not started out of numeric order without a stated reason.

## Reference

- `policies/ai-pull-request-policy.md` — the Git mechanics behind the "Draft PR → Review → Approved → Merged" steps above.
- `standards/security/identity-boundary.md`, `adr/ADR-0005-terraform-execution-identity.md` — the AWS-identity boundary PLAN-0001 established.
- `architecture/project-registry.md` — where project-level (not Engineering-OS-level) state lives; PLAN-0002 established it.
