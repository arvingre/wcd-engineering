# ADR-0006: Operational Decision Layer vs. Git-Lifecycle Decision Engine

**Status:** Adopted — 2026-07-22, merged via PR #15 (`feature/decision-layer-reconciliation`). Proposed and adopted the same day; per this ADR's own rule, status moved to Adopted on merge.

## Context

`VISION.md` (merged via PR #14) defines a **Decision** component as one of the four things WCD owns: a three-layer structure (Policy file → Memory → LLM reasoning) that autonomously decides `Continue` / `Retry` / `Rollback` / `Escalate` / `Wait` / `Cancel` while the Employee is executing a Goal — a Human is only pulled in via the `Escalate` path (Decision Engine → OpenClaw Gateway → Telegram/Slack).

`decision/decision-engine.md` (already Completed, PR #10) also calls itself "the Decision Engine," defining eight decision types — Approve, Reject, Merge, Close, Reopen, Archive, Escalate, Defer — and states plainly that "every one of them is a Human judgment call... never generated or self-applied by an AI agent."

Read side by side, these look like a direct contradiction: one says the Employee decides for itself, the other says an AI agent never decides. VISION.md itself flagged this explicitly as an open reconciliation and named it a prerequisite for PLAN-0006 Bootstrap, not an afterthought. Per a direct 2026-07-22 human decision, wherever VISION.md and an existing document genuinely conflict on the same action space, VISION.md governs — this ADR is the first application of that tie-breaker rule.

## Decision

1. **These are two distinct Decision layers over two disjoint action spaces — not one document contradicting the other.**

   - **Git-Lifecycle Decision Engine** (`decision/decision-engine.md`, unchanged by this ADR) — decides Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer for Plans and PRs, in `wcd-engineering` and every project repository. Always a Human judgment call, no exceptions, per `policies/ai-pull-request-policy.md`.
   - **Operational Decision Layer** (VISION.md's `### 2. Decision`, not yet implemented — that's PLAN-0006's job) — decides Continue/Retry/Rollback/Escalate/Wait/Cancel *during a Goal's execution* (e.g., mid-way through a Daily Kubernetes Health Check run: retry a flaky check, roll back a bad patch). Three-layer Policy → Memory → LLM reasoning, autonomous except at Escalate.

   None of the Git-Lifecycle Decision Engine's eight types maps onto an operational action like "retry this health check" — the two documents were never actually describing the same decision space, they just both used the word "Decision Engine."

2. **The one place these layers touch is Escalate**, and even there they don't merge: an Operational Escalate produces a Human-facing notification (OpenClaw Gateway → Telegram/Slack). It never bypasses the Git-Lifecycle Decision Engine — if the Employee's operational work produces a code or doc change (e.g., a Fix PR from the Daily Health Check workflow), that change still goes through the ordinary feature-branch → Draft PR → Human Merge path, untouched by this ADR.

3. **Applying the tie-breaker rule:** on close reading there is no actual conflict once scoped precisely (point 1) — so this ADR does not amend, weaken, or reopen the already-Completed `decision/decision-engine.md`. Had a genuine overlap been found, VISION.md's design would have governed and `decision-engine.md` would have needed a superseding change; that didn't turn out to be necessary here.

4. `decision/decision-engine.md` gets a short cross-reference added (see accompanying diff) pointing to this ADR and to VISION.md, so a future reader doesn't misread its "never generated or self-applied by an AI agent" language as a blanket claim covering all AI decision-making everywhere, rather than specifically Git/PR/Plan lifecycle actions.

5. **This ADR does not implement the Operational Decision Layer.** It only settles the boundary. Building it — Policy file schema, where Memory physically lives, the LLM-reasoning prompt/loop, stability windows — is PLAN-0006 Bootstrap's job, which this ADR unblocks.

## Consequences

- PLAN-0006 Bootstrap can proceed without re-litigating whether its Decision layer contradicts the merged Decision Engine.
- Any future component that appears to let AI decide something autonomously must first show which layer it belongs to: Git-lifecycle (human-only, no exceptions, ever) or Operational (Policy → Memory → LLM, human only at Escalate). A component that claims to autonomously decide a Git/PR action is not covered by this ADR and remains prohibited outright by `policies/ai-pull-request-policy.md`.
- If a future case can't be cleanly assigned to one layer, that's a signal this ADR's boundary needs revisiting via a superseding ADR — not a reason to quietly blend the two.

## Open questions

- The Operational Decision Layer's actual implementation (Policy file format and location, where "Memory" physically lives — this ADR assumes VISION.md's PostgreSQL + Git two-layer design without standing any of it up) is deferred entirely to PLAN-0006.
- Whether an Operational Escalate should also leave a lightweight record on the Git-lifecycle side (e.g., a GitHub Issue) for visibility, or stay purely on the Telegram/Slack channel, is unresolved — left to PLAN-0006 to decide.

## References

- `VISION.md` — `## WCD Responsibilities` → `### 2. Decision`, the source of the Operational Decision Layer design.
- `decision/decision-engine.md` — the Git-lifecycle Decision Engine this ADR distinguishes from, unchanged.
- `policies/ai-pull-request-policy.md` — the human-only Git workflow that stays in force regardless of Operational-layer autonomy.
- `docs/roadmap.md` — PLAN-0006 Bootstrap, unblocked by this ADR.
