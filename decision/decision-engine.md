# WCD Engineering Decision Engine

## Purpose

The Decision Engine turns a Human's decision into organizational state change — Memory, `docs/roadmap.md`, and the next recommended Plan. It is a **recording and propagation layer, not an execution layer**: it never calls the GitHub API to merge, close, or reopen anything itself. A Human (mechanically, on GitHub) or GitHub's own automation performs the actual action; the Decision Engine's job starts *after* that action is known to have happened, turning the raw fact of a decision into durable, structured state.

This is the deeper mechanism behind `architecture/engineering-workflow.md`'s Stage 10 (Memory Update) — that stage said memory gets updated after a merge; this document defines exactly how, for every kind of decision a Human can make, not just "merged."

**Scope note (`adr/ADR-0006`):** the eight decision types below, and "never generated or self-applied by an AI agent," describe the Git/PR/Plan lifecycle specifically — not every judgment call an AI agent ever makes. `VISION.md`'s Decision component describes a separate, not-yet-implemented Operational Decision Layer that autonomously decides Continue/Retry/Rollback/Escalate/Wait/Cancel *during a Goal's execution* (e.g., mid-run of a Kubernetes health check) — a disjoint action space from the eight types here. See `adr/ADR-0006-operational-vs-git-lifecycle-decisions.md` for the boundary between the two.

## Decision types (Task 1)

Eight decision types. Every one of them is a Human judgment call recorded by the Decision Engine, never generated or self-applied by an AI agent (an AI agent can propose — see `architecture/engineering-workflow.md` Stage 5–6 review comments — but proposing is not deciding).

- **Approve**
- **Reject**
- **Merge**
- **Close**
- **Reopen**
- **Archive**
- **Escalate**
- **Defer**

## Decision detail (Task 2)

Each decision type below states its Trigger, Input, Output, and Next Action.

#### Approve

| | |
|---|---|
| Trigger | A reviewer (Human or OpenClaw at Gates 1–2; Human only at Gate 3, per `architecture/engineering-workflow.md`) explicitly approves a PR/Plan at its current gate. |
| Input | A PR/Plan sitting at a Review or Human Approval gate, with no open objection. |
| Output | That gate's status flips to passed. |
| Next Action | Knowledge Promotion records who approved, at which gate, and when. If this was the final gate (Human Approval), Roadmap Update marks the Plan ready for Merge — the Decision Engine does not merge it. |

#### Reject

| | |
|---|---|
| Trigger | A reviewer determines the PR/Plan does not meet the current gate's criteria. |
| Input | A PR/Plan at a Review or Human Approval gate, with a stated objection. |
| Output | The gate stays unpassed; the Plan returns to implementation, not forward. |
| Next Action | Knowledge Promotion records the rejection reason, specifically so the same objection isn't re-litigated identically on the next pass. Roadmap Update keeps the Plan at `In Progress` (or `Review` with changes requested) — never silently advanced. |

#### Merge

| | |
|---|---|
| Trigger | A Human clicks merge on an Approved PR, on GitHub (per `policies/ai-pull-request-policy.md` — Human-only, and mechanically performed on GitHub, never by the Decision Engine). |
| Input | The already-completed fact that an Approved PR was merged. |
| Output | The Decision Engine observes and records this — it does not perform the merge. |
| Next Action | Knowledge Promotion records the merged change and what it contained. Roadmap Update moves the Plan's row to `Merged`. |

#### Close

| | |
|---|---|
| Trigger | Either the normal path (merged and Validated, per `architecture/engineering-workflow.md` Stages 9–11) or an early-close decision by a Human (abandoned or superseded). |
| Input | A Plan ready to end, with a reason if it's closing early. |
| Output | The Plan's status becomes `Closed`. |
| Next Action | Knowledge Promotion records *why* it closed — merged-and-done is different knowledge from abandoned/superseded, and the two must stay distinguishable later. Roadmap Update moves it out of the active tables. |

#### Reopen

| | |
|---|---|
| Trigger | A Human decides a `Closed` or `Archived` Plan needs to become active again — the need resurfaced, or an earlier close/archive turns out to have been premature. |
| Input | A `Closed` or `Archived` Plan, plus a stated reason for reopening. |
| Output | The Plan's status returns to an active state — `In Progress` if implementation already exists to resume, `Review` if it closed mid-review — decided by whoever reopens it. |
| Next Action | Knowledge Promotion records that it was reopened and why — a Plan reopened more than once is itself a signal worth surfacing later (see `architecture/engineering-loop.md`'s Risk output). Roadmap Update moves it back into an active table. |

#### Archive

| | |
|---|---|
| Trigger | A Human decides a `Closed` Plan should move permanently out of active consideration — distinct from Close, which still shows in ordinary history and reopens routinely. |
| Input | A `Closed` Plan. |
| Output | The Plan's status becomes `Archived` — kept for historical record only, mirroring `architecture/project-registry.md`'s own `Archived` project-status definition ("no longer maintained, kept for reference only; do not propose new work here without first confirming it should be un-archived"). |
| Next Action | Knowledge Promotion records the archive decision and reason. Roadmap Update removes it from every active table, leaving only a historical reference. Reopening an `Archived` Plan is possible but requires its own fresh, explicit Reopen decision — never treated as routine the way reopening a merely-`Closed` Plan is. |

#### Escalate

| | |
|---|---|
| Trigger | A reviewer — or a pattern the Decision Engine's own knowledge surfaces, such as a Plan flagged as a Risk by `architecture/engineering-loop.md` for sitting too long — determines the Plan/PR can't be resolved at the normal review level (conflicting feedback, a call that exceeds a reviewer's authority). |
| Input | A stuck or contested Plan/PR. |
| Output | The Plan is flagged `Escalated` — it does not advance through its normal gate until a specific, named decision-maker resolves it. |
| Next Action | Knowledge Promotion records the escalation and why. Roadmap Update surfaces it prominently — in the next Engineering Report's Risk section, not left quietly sitting at `In Progress`/`Review`. |

#### Defer

| | |
|---|---|
| Trigger | A Human (or OpenClaw, subject to Human confirmation) decides a Plan is valid but shouldn't proceed right now — not rejected, not closed, just not now. |
| Input | A Plan at any pre-Merge stage, plus a stated reason and, where known, a condition for revisiting it. |
| Output | The Plan's status becomes `Deferred` — paused, neither advancing nor closed. |
| Next Action | Knowledge Promotion records the defer reason and revisit condition. Roadmap Update moves it out of `In Progress`/`Next Plans` into a holding area, so `architecture/engineering-loop.md`'s "Recommend Next Plan" step stops re-suggesting it every run until the revisit condition is met. |

## Decision → Knowledge Promotion → Roadmap Update (Task 3)

```
Decision
  │
  ▼
Knowledge Promotion
  │
  ▼
Roadmap Update
```

**A Decision never writes directly to Memory.** Knowledge Promotion sits between them on purpose: not every detail of a raw decision (who clicked what, at what timestamp, in what UI) is worth keeping as durable memory — most of it is transient event log. Knowledge Promotion is the judgment step that decides what from a Decision is actually worth promoting into Memory as a standing fact (a rejection reason that will recur, a defer condition that must be checked later, an escalation pattern worth watching) versus what can be left as an ephemeral record on the PR/decision itself. This mirrors the same discipline Claude Code's own memory system applies — save rules and stable decisions, not transient state — applied here at the organizational level instead of a single session's.

Only *after* Knowledge Promotion decides what's durable does Roadmap Update happen — the Roadmap reflects promoted knowledge, not raw decisions. This is why the chain is Decision → Knowledge Promotion → Roadmap Update, and not Decision → Roadmap Update directly: skipping the promotion step would mean the Roadmap accumulates noise instead of curated state.

**Relationship to `architecture/engineering-workflow.md` Stage 10 (Memory Update):** that stage described "Memory Update" as a single step that also covers Roadmap status. This document specifies the same territory in more depth for the Decision artifact specifically — Knowledge Promotion *is* the mechanism by which Stage 10's "Memory" half gets populated, and its output then drives the "Roadmap" half. The two documents describe one mechanism at two levels of detail, not two different mechanisms.

## Decision State Machine (Task 4)

This composes with, rather than replaces, the eleven-stage lifecycle in `architecture/engineering-workflow.md` — that lifecycle is the intended path; this state machine adds the branches decisions can create (`Deferred`, `Escalated`, `Archived`, and the reversal `Reopen`) on top of it.

```
Draft ──▶ In Progress ──▶ Review ──▶ Approved ──▶ Merged ──▶ Closed ──▶ Archived
              ▲              │           │                     │           │
              │         Reject/Defer   Reject                Reopen ◀──────┘
              │              │           │                     │
              └──────────────┴───────────┴─────────────────────┘
                                    (Escalate: freezes the current
                                     state until a named decision-
                                     maker resolves it, then resumes
                                     from where it was)
```

| Current State | Decision | Next State |
|---|---|---|
| Review | Approve (non-final gate) | Review (next gate) |
| Review | Approve (final gate — Human Approval) | Approved |
| Review | Reject | In Progress |
| Review | Defer | Deferred |
| Review | Escalate | Escalated (resumes at Review once resolved) |
| Approved | Merge | Merged |
| Approved | Reject | In Progress (rare — approval revoked before merge actually happens) |
| Merged | Close | Closed |
| Draft / In Progress / Review / Approved | Close | Closed (early close — see `architecture/engineering-workflow.md` Stage 11) |
| Closed | Reopen | In Progress or Review |
| Closed | Archive | Archived |
| Archived | Reopen | In Progress (requires a fresh, explicit justification — not routine) |
| Deferred | (revisit condition met) | Review or In Progress, whichever it left |
| Escalated | (named decision-maker resolves it) | Review or Approved, whichever it left |

**Note on `docs/roadmap.md`'s status vocabulary:** the Roadmap's current status list is `Draft`/`In Progress`/`Review`/`Approved`/`Merged`/`Closed`. This state machine adds `Deferred`, `Escalated`, and `Archived` as states a Decision can produce. That's a real gap between what this document needs and what `docs/roadmap.md` currently documents — flagged here rather than silently worked around; reconciling the Roadmap's own vocabulary with this is left as follow-up work, not expanded in this PR (out of scope — see Constraints).

## Design intent (validation)

- **Decisions drive Memory, Roadmap, and Next Plan — never GitHub directly.** Every decision type's Next Action above ends in Knowledge Promotion and Roadmap Update, never in "the Decision Engine performs a GitHub action." The actual GitHub-side action (merge, close, reopen) always already happened, performed by a Human, before the Decision Engine's Next Action runs.
- Each decision type's Output is a **state change**, not a **side effect on GitHub** — this document defines what happens to organizational knowledge, not what buttons get clicked.

## Reference

- `architecture/engineering-workflow.md` — the eleven-stage lifecycle this state machine's "happy path" follows, and where Stage 10 (Memory Update) is specified in less depth than this document goes into.
- `architecture/engineering-loop.md` — where Escalate/Defer flags are expected to surface as Risk, and what reads Roadmap state to Recommend Next Plan.
- `docs/roadmap.md` — the status vocabulary this document extends (see the note above).
- `architecture/project-registry.md` — the `Archived` project-status definition this document's `Archive` decision mirrors at the Plan level.
- `policies/ai-pull-request-policy.md` — why Merge is always a Human-performed GitHub action the Decision Engine only ever observes.
