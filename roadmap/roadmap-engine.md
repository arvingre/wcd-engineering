# WCD Roadmap Engine

## Purpose

The Roadmap Engine turns Human Decisions and Knowledge Promotion's output into organizational state — where every Plan currently stands — and recommends what to work on next. It is the piece that closes the loop `architecture/engineering-loop.md` left open at "Wait Human Decision": this document is what happens between a Human deciding something and the Loop's next run picking up the consequences.

Like `decision/decision-engine.md`, the Roadmap Engine is a **state-tracking layer, not an execution layer.** It never calls the GitHub API, never opens a branch or PR, and never assigns work to an agent. Its only output is a recommendation and an updated Roadmap state; a Human decides whether to act on either.

## Roadmap State vs. Decision State — not the same concept

**A Decision State is an event. A Roadmap State is a standing condition.**

`decision/decision-engine.md` defines eight Decision types — Approve, Reject, Merge, Close, Reopen, Archive, Escalate, Defer — each one a momentary act a Human performs. A Decision happens once, at a point in time, and then it's over.

A Roadmap State is what a Plan sits in *between* Decisions — it persists until the next Decision changes it. The same Decision can even produce different Roadmap States depending on context (see `Reject` in `## Transition Rules` below, which lands at either `Closed` or `Blocked`). Conflating the two — treating "the Decision was Defer" and "the Roadmap State is Deferred" as interchangeable facts — loses exactly the information the state machine needs: *why* a Plan is in a given state, not just that it is.

## Roadmap State model (Task 1)

| State | Meaning |
|---|---|
| **Draft** | Plan written, no branch/PR opened yet. |
| **In Progress** | Implementation branch active. |
| **Review** | Draft PR open, in Architecture Review or Implementation Review. |
| **Approved** | Passed Human Approval, not yet merged. |
| **Blocked** | Cannot proceed — either an unresolved external dependency, or an Escalation awaiting a specific decision-maker. Not terminal (see `## Transition Rules`). |
| **Deferred** | Valid, but a Human decided not to proceed right now. Not terminal — resumes when its revisit condition is met. |
| **Completed** | Merged to `main` (or a project's integration branch) and Validated per `architecture/engineering-workflow.md` Stage 9. |
| **Closed** | Ended — either normally (after Completed) or early (abandoned/superseded). |
| **Archived** | Permanently moved out of active consideration. Reopening requires a fresh, explicit justification, not routine. |

**Terminology note:** `docs/roadmap.md` currently uses `Merged` for what this document calls `Completed` — same underlying state, different name in the two documents. This document doesn't rename `docs/roadmap.md`'s existing vocabulary (out of scope here — see `## Roadmap Vocabulary Update`); the two terms should be read as synonyms until a future Plan reconciles them.

## Roadmap Inputs (Task 2)

| Input | What the Roadmap Engine reads from it |
|---|---|
| **Human Decision** | The Decision itself (type, target, reason) — the direct trigger for most state transitions. |
| **Knowledge Promotion Result** | Whatever `knowledge/knowledge-promotion.md` promoted from that Decision — durable rationale that should travel with the Roadmap entry, not just the bare state change. |
| **Current Roadmap** | `docs/roadmap.md`'s existing state for the Plan in question — a transition is always relative to where the Plan already is. |
| **Project Registry** | `architecture/project-registry.md` — which project a Plan belongs to, and that project's own Status, for cross-checking (e.g. don't recommend new work on an `Archived` project). |
| **Dependency State** | The `depends_on`/`blocked_by`/`unblocks`/`supersedes` graph — see `## Dependency Handling`. |
| **GitHub Merge State** | Whether a PR is actually merged on GitHub — the Roadmap Engine confirms this rather than assuming a Merge Decision implies it (the Decision records that a Human merged it; this input verifies the merge is real). |

## Transition Rules (Task 3)

| Decision | Trigger | Precondition | Current State | Next State | Required Evidence |
|---|---|---|---|---|---|
| **Approve** | A reviewer (Human, and only Human at the final gate) approves the PR at its current gate. | No open objection at that gate. | Review | Approved | The Approve Decision record — who approved, at which gate. |
| **Merge** | A Human merges the Approved PR on GitHub (the Roadmap Engine observes this, never performs it). | GitHub Merge State confirms the PR is actually merged. | Approved | Completed | The Merge Decision record **and** confirmed GitHub Merge State — either alone is insufficient. |
| **Close** | A Close decision, normal (post-Completed, Validated) or early (abandoned/superseded). | Completed (normal path), or any earlier state with a stated early-close reason. | Completed, or any pre-Completed state | Closed | The Close Decision record, with reason if early. |
| **Reject** | A reviewer determines the PR/Plan cannot proceed as currently scoped. | A stated rejection reason. | Review or Approved | **Closed** if the reason means the current approach/scope is invalid (needs a fresh Plan, not a fix) — **Blocked** if the reason is an external, resolvable dependency or precondition. | The Reject Decision record with its reason — the reason is what determines which of the two next states applies, not the Reject decision alone. |
| **Defer** | A Human (or OpenClaw, subject to Human confirmation) decides the Plan is valid but shouldn't proceed now. | A stated reason and, where known, a revisit condition. | Draft, In Progress, Review, or Approved | Deferred | The Defer Decision record with reason and revisit condition. |
| **Escalate** | A reviewer, or a pattern `architecture/engineering-loop.md`'s Risk output surfaces, determines the Plan can't be resolved at the normal review level. | The Plan is stuck at a gate. | Review or Approved | Blocked | The Escalate Decision record with reason. |
| **Archive** | A Human decides a `Closed` Plan should move permanently out of active consideration. | The Plan is Closed. | Closed | Archived | The Archive Decision record with reason. |
| **Reopen** | A Human decides a `Closed` or `Archived` Plan needs to become active again. | A stated reason. | Closed or Archived | In Progress | The Reopen Decision record with reason. (Always routes through In Progress, even from Review-stage closes — reopening re-validates before resuming review, rather than assuming the old review state is still valid.) |

**`Blocked` is not a dead end.** Two different Decisions land there (`Reject` and `Escalate`) for two different reasons — the Required Evidence column is what distinguishes them, since the state alone doesn't say why a Plan is Blocked. Once the blocking condition clears (tracked via `## Dependency Handling`), the Plan resumes via a fresh ordinary Decision (typically `Approve`, or simply resuming implementation) — this document doesn't need a ninth Decision type for "unblock"; it's the same Transition Rules above, applied again once the precondition that was missing is satisfied.

## Next Active Plan Selection (Task 4)

In this order:

1. **Approved and not yet Completed** — finishing something already past review outranks starting anything new. This keeps work-in-progress low and matches `docs/roadmap.md`'s existing Scheduling rule ("finish active work before opening a new Plan").
2. **Dependencies satisfied** — among what's left, exclude anything whose `depends_on` graph isn't fully resolved.
3. **No Blocker** — exclude anything currently `Blocked`, or `blocked_by` something unresolved.
4. **Highest priority** — among the remaining candidates, prefer the Human-assigned highest priority.
5. **Smallest, most executable scope** — the tiebreaker among equal-priority candidates: prefer whichever is quickest to actually finish, to keep the loop moving.

**The Roadmap Engine's only output here is a `Recommended Next Plan`.** It is explicitly forbidden from:

- Automatically starting a Plan.
- Automatically creating a branch.
- Automatically creating a PR.
- Automatically assigning Claude Code (or any agent).

Every recommendation waits for an explicit Human Decision before `architecture/engineering-workflow.md` Stage 3 (Feature Branch) work begins — the same "nothing advances without a human decision" principle every other document in this Engineering OS already holds to.

## Dependency Handling (Task 5)

Four relationship types:

| Relationship | Meaning | Example |
|---|---|---|
| **depends_on** | A general prerequisite — this Plan can't be considered *complete* until the other one is, but isn't necessarily actively stuck right now. | `PLAN-0009 depends_on PR #10 and PR #11` |
| **blocked_by** | An *active*, immediate blocking relationship — this Plan literally cannot merge or proceed until the other one resolves. Typically used for stacked PRs. | `PR #4 blocked_by PR #3` |
| **unblocks** | The inverse of `blocked_by`, stated from the other direction, so the blocking Plan's own record shows everything it's holding up, not just the blocked Plan's record showing what's holding it back. | `PR #3 unblocks PR #4` |
| **supersedes** | Replacement, not sequencing — this Plan makes another one obsolete. The superseded Plan should be Closed (its Close Decision's reason references the superseding Plan). | A revised Plan `supersedes` an earlier, abandoned attempt at the same goal. |

`depends_on` and `blocked_by` are related but distinct: every `blocked_by` relationship implies a `depends_on` relationship, but not every `depends_on` is an active blocker yet (a Plan can depend on something that hasn't been reached as a hard blocker in the current lifecycle stage). Next Active Plan Selection (Task 4, step 2–3) checks both.

## Closed Loop (Task 6)

```
Registry
  │
  ▼
Engineering Loop
  │
  ▼
GitHub / HCP Terraform / CI
  │
  ▼
Notification
  │
  ▼
Human
  │
  ▼
Decision Engine
  │
  ▼
Knowledge Promotion
  │
  ▼
Roadmap Engine
  │
  ▼
Recommended Next Plan
  │
  ▼
Human Decision
  │
  ▼
Engineering Loop
```

This is the full cycle every other document in this Engineering OS is one piece of:

- **Registry → Engineering Loop → GitHub/HCP Terraform/CI**: `architecture/engineering-loop.md` Steps 1, 4–7 — OpenClaw reads state, inspects everything read-only.
- **CI → Notification → Human**: `architecture/engineering-loop.md` Step 8's Engineering Report is what gets surfaced to a Human as a Notification — the Loop generates it, a Human is the one who has to see it for anything to happen next.
- **Human → Decision Engine**: a Human makes one of the eight Decisions; `decision/decision-engine.md` records it.
- **Decision Engine → Knowledge Promotion**: `knowledge/knowledge-promotion.md` filters the raw Decision for what's durable.
- **Knowledge Promotion → Roadmap Engine**: this document consumes both the raw Decision (Roadmap Inputs, above) and what got promoted, and produces the new Roadmap State via `## Transition Rules`.
- **Roadmap Engine → Recommended Next Plan → Human Decision**: `## Next Active Plan Selection`'s output, which — like every other recommendation in this system — waits for a Human before anything happens.
- **Human Decision → Engineering Loop**: the cycle restarts; the Loop's next run (`architecture/engineering-loop.md`'s Manual/Daily/Weekly/Release cadence) picks up from the new state.

No step in this loop is optional, and no step is automatic past a Human decision point — that property is what makes it a *closed* loop rather than a one-way pipeline that eventually needs a human to manually intervene and restart it.

## Roadmap Vocabulary Update (Task 7)

`docs/roadmap.md`'s current `## Plan status vocabulary` section has `Draft`, `In Progress`, `Review`, `Approved`, `Merged`, `Closed` — missing `Blocked`, `Deferred`, and `Archived`, all three of which this document's state model needs. Adding only those three definitions to that section (reusing the same wording as `## Roadmap State model` above); no existing Plan row, status, or historical fact in `docs/roadmap.md` is rewritten.

## Reference

- `architecture/engineering-loop.md` — where this document's Roadmap Inputs are read from (Steps 1–2) and where "Recommend Next Plan" / "Wait Human Decision" (Steps 9–10) named what this document now specifies in full.
- `decision/decision-engine.md` — the eight Decision types this document's Transition Rules consume, and why the Roadmap Engine, like the Decision Engine, never touches GitHub directly.
- `knowledge/knowledge-promotion.md` — the `Decision → Knowledge Promotion → Roadmap Update` chain this document is the "Roadmap" half of.
- `architecture/engineering-workflow.md` — the eleven-stage Plan lifecycle whose Stages 5–9 (Review through Validation) this document's Roadmap States track.
- `architecture/project-registry.md` — the source of a Plan's project context, and the `Archived` project-status definition this document's `Archived` Roadmap State mirrors at the Plan level.
- `docs/roadmap.md` — the Roadmap this engine updates; see `## Roadmap Vocabulary Update` above for the one change this Plan makes there.
