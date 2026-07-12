# WCD Engineering Roadmap

## Vision

`docs/roadmap.md` is the single task-scheduling center for the whole WCD Engineering OS. Every future Plan, ADR, and PR is organized around this roadmap. Agents read this file before proposing new work.

## Plan status vocabulary

- **Draft** — reserved or written, no branch/PR opened.
- **In Progress** — implementation branch active.
- **Review** — Draft PR open.
- **Approved** — reviewed and awaiting merge.
- **Merged** — PR merged to `main`; post-merge state sync may still be required.
- **Blocked** — cannot proceed: an unresolved external dependency, or an Escalation awaiting a specific decision-maker. Not terminal — resumes once the blocking condition clears. See `roadmap/roadmap-engine.md`.
- **Deferred** — valid, but a Human decided not to proceed right now. Not terminal — resumes when its revisit condition is met. See `roadmap/roadmap-engine.md`.
- **Closed** — ended without merge, with reason recorded.
- **Archived** — permanently moved out of active consideration after being Closed. Reopening requires a fresh, explicit justification, not routine. See `roadmap/roadmap-engine.md`.

## Plan lifecycle

```text
Plan -> Draft PR -> Review -> Approved -> Merged -> Memory Updated -> Closed
```

Merged is not the finish line. Roadmap and durable memory must reflect the merged reality before the work is operationally complete.

## Current Phase

The Engineering OS foundation is established: identity boundary, project registry, AI PR policy, roadmap, engineering workflow, engineering loop, and engineering memory are merged. The next implementation target is PLAN-0006 Bootstrap, followed by PLAN-0007 Agent Roles.

## Completed Plans

| Plan | Title | Status | Related PR |
|---|---|---|---|
| PLAN-0001 | Identity Boundary | Merged | [#1](https://github.com/arvingre/wcd-engineering/pull/1) |
| PLAN-0002 | Project Registry | Merged | [#2](https://github.com/arvingre/wcd-engineering/pull/2) |
| PLAN-0003 | Engineering Roadmap | Merged | [#4](https://github.com/arvingre/wcd-engineering/pull/4) |
| PLAN-0004 | AI Pull Request Policy | Merged | [#3](https://github.com/arvingre/wcd-engineering/pull/3) |
| PLAN-0005 | Engineering Memory | Merged | [#7](https://github.com/arvingre/wcd-engineering/pull/7) |
| FOUNDATION-WORKFLOW | Engineering Workflow | Merged | [#5](https://github.com/arvingre/wcd-engineering/pull/5) |
| FOUNDATION-LOOP | Engineering Loop | Merged | [#6](https://github.com/arvingre/wcd-engineering/pull/6) |

## In Progress

No implementation Plan is currently active. This state-sync PR completes the post-merge Roadmap and Memory Update required after PRs #3-#7.

## Next Plans

| Plan | Title | Status |
|---|---|---|
| PLAN-0006 | Bootstrap | Draft |
| PLAN-0007 | Agent Roles | Draft |

## Future Plans

| Plan | Title | Status |
|---|---|---|
| PLAN-0008 | Engineering Standards | Draft |
| PLAN-0009 | Playbooks | Draft |
| PLAN-0010 | Templates | Draft |

## Scheduling rule

Finish active work before opening a new Plan. When no Plan is active, select the first item in `Next Plans` unless a human records a reason to change priority.

## Reference

- `architecture/project-registry.md`
- `architecture/engineering-workflow.md`
- `architecture/engineering-loop.md`
- `architecture/engineering-memory.md`
- `policies/ai-pull-request-policy.md`
