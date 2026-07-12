# WCD Knowledge Promotion

## Purpose

Knowledge Promotion is the filter between a Decision (a raw, transient event — who decided what, when) and Memory (durable, curated organizational knowledge). This document is the mechanism referenced by `decision/decision-engine.md`'s `Decision → Knowledge Promotion → Roadmap Update` chain: it specifies exactly how that filtering works — which facts are **Stable Knowledge** allowed into Organizational Memory, and which are **Temporary Events** that must never enter it, no matter who is doing the promoting.

The core rule, stated once so it can be pointed back to everywhere else: **only Stable Knowledge enters Organizational Memory.** A Decision existing is not, by itself, a reason to write something into Memory.

## Promotion Rule

### Enters Memory (Stable Knowledge)

- Standing rules and policies — e.g. "AI agents never merge" (`policies/ai-pull-request-policy.md`).
- Architecture decisions with lasting impact — ADRs, and the reasoning behind them.
- Rejection reasons likely to recur — so the same objection isn't re-litigated identically next time.
- Defer conditions and their revisit triggers — while the Plan remains Deferred.
- Escalation *patterns* — a repeated theme across escalations is worth remembering; a single one-off usually isn't.
- Stable identity/ownership facts, once actually assigned (not `TBD` placeholders).
- Confirmed, validated project-level facts and their rationale — e.g. "EKS 1.35 chosen because 1.33's standard support ends in days," not just the bare version number.
- Cross-project structural decisions — identity boundaries, workflow definitions, this document's own promotion rule.

### Never enters Memory (Temporary Event)

- Raw event log — individual timestamps, who clicked what, in what UI, in what order.
- In-progress/ephemeral task state — a branch currently being worked, review comments not yet resolved, anything that will be stale within hours.
- **Raw mutable state, duplicated as-is** — the literal current output of `git log`/`git blame`, a current PR/issue list, current file contents, current CI results. Copying a live, changing snapshot into Memory just means Memory starts going stale the moment the source state moves on.

  This is **not** a rule against ever promoting anything that came from looking at current state — almost everything Knowledge Promotion handles starts that way. The distinction is between the raw state itself and what was concluded from it: **stable rationale, constraints, interpretations, and approved conclusions derived from current state may be promoted when they remain useful after the source state changes.** "PR #5 currently has 3 open review comments" is raw mutable state — excluded. "PR #5's review concluded X must always hold because Y" is a stable conclusion *derived from* reading that PR — includable, and it stays true and useful long after PR #5's comment count has changed or the PR itself has closed.
- Raw CI/build logs.
- **Secrets, credentials, tokens — never, under any circumstance**, regardless of stability.
- Terraform state *content* — only workspace *names* are ever recorded anywhere in this Engineering OS (`architecture/project-registry.md` already establishes this; Knowledge Promotion inherits the same boundary, it doesn't relax it).
- One-off chatter with no decisional content.

**Enforcement, not just guidance:** the Evaluate step of the Promotion Pipeline (below) checks every candidate against both lists. A candidate matching anything in "Never enters Memory" is rejected regardless of who's promoting it or how confident they are it's important — the exclusion list isn't a suggestion a busy promotion pass can skip.

## Promotion Pipeline

```
Decision
  │
  ▼
Evaluate
  │
  ▼
Stable?
  │
  ├── No ──▶ Discarded
  │
  └── Yes
        │
        ▼
      Memory
        │
        ▼
      Index
        │
        ▼
      Done
```

*(The **No → Discarded** branch isn't in the diagram this Plan specified but is necessary for the pipeline to be complete — added here explicitly rather than left implicit.)*

1. **Decision** — input: a Decision from `decision/decision-engine.md` (Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer), or any other candidate fact a Review or Plan surfaces that looks like it might be Stable Knowledge.
2. **Evaluate** — check the candidate against the Promotion Rule's two lists above.
3. **Stable?** — the yes/no checkpoint. Not a judgment call made loosely — it's answered by the Evaluate step's result against the Rule, not by how important the candidate *feels*.
4. **No → Discarded** — **Discarded means, precisely and only, "not promoted to Memory." It never means the source record is deleted or rewritten.** The Decision, Review, or PR the candidate came from still exists on GitHub exactly as it always did (`decision/decision-engine.md`'s Knowledge Promotion step already established this) — Discarded describes what Knowledge Promotion did with it (declined to duplicate it into Memory), not anything that happened to the original evidence. See `## Auditability` below for how this differs from Pruning, the other way a fact can end up outside active Memory.
5. **Yes → Memory** — the promoted fact is written into Memory as a durable record.
6. **Index** — the new Memory entry is linked from an index so it's discoverable later, not just written and forgotten. (Same discipline Claude Code's own memory system already applies: every memory file gets one line in `MEMORY.md` pointing to it — Knowledge Promotion applies the same indexing requirement at the organizational level.)
7. **Done.**

## Keeping Memory from growing without bound (validation)

Selective promotion (most candidates fail Evaluate and are Discarded) bounds growth relative to raw activity, but that alone isn't enough — more decisions keep happening over time even after filtering, so an append-only Memory would still grow forever. Two more rules close that gap:

1. **Memory entries are living records, updated in place — not an append-only log.** When a promoted fact changes (a project's Status moves from `Active` to `Archived`, a Defer condition is resolved), the existing Memory entry is *updated* to reflect the new reality, not left in place with a second, newer entry appended alongside it. Duplicate near-identical entries are a sign Knowledge Promotion is being done wrong, not an acceptable steady state.
2. **Promoted facts that are no longer stable get pruned, not just left to accumulate.** See `## Auditability` immediately below for exactly what Pruning does and does not do — it is not deletion.

Together: Promotion Rule keeps *Temporary Events* out entirely; update-in-place plus pruning keeps *Stable Knowledge* itself from silently becoming its own kind of clutter once it's no longer actually stable — without either of those two mechanisms ever destroying the evidence a promoted fact was based on.

## Auditability

**Pruning means removing an item from active organizational memory. It does not mean deleting or rewriting the source evidence that item was based on — those are two different actions, and Knowledge Promotion only ever performs the first.** A promoted Defer condition, once resolved, no longer needs to sit in *active* Memory — only the final stable outcome (why the Plan eventually proceeded or didn't) does. An Escalation's promoted record survives past the escalation resolving only if it revealed a *pattern* worth remembering (per the Promotion Rule above); the one-off event itself does not need to stay in active Memory. In every case, what gets pruned is the *active-Memory copy* — never the underlying history it was drawn from.

**Historical evidence always remains available, independent of what's currently in active Memory, in:**

- GitHub PR and review history — the actual review comments, approvals, and discussion.
- ADR history — every ADR ever written, including superseded ones (ADRs aren't deleted when a later one replaces them, per standard ADR practice — the old one stays, marked superseded).
- Decision records — the artifacts `decision/decision-engine.md`'s eight decision types produce.
- Git history — `git log`/`git blame` on every file this Engineering OS has ever contained.
- Evidence archive — a durable store for anything promoted-then-pruned that shouldn't simply vanish from view even once it's out of active Memory. (Not yet built as of this document; named here as the intended home for pruned-but-still-referenceable knowledge, tracked as follow-up scope rather than something this Plan builds.)

**Two more rules keep this connected, not just theoretically true:**

- **Superseded knowledge links to its replacement.** When an active Memory entry is updated because the fact it recorded changed, the old understanding isn't silently overwritten with no trace — the new entry (or the evidence-archive record of the old one) carries a reference back to what it replaced and why, so "why did we used to think X" is answerable later, not lost.
- **Memory cleanup must not destroy organizational audit history.** Whatever process runs update-in-place or pruning operates only on *active Memory* — it never touches GitHub PR/review history, ADR history, Decision records, or Git history, which are independent systems of record this Engineering OS doesn't own the deletion of.

This is also the precise difference between **Discarded** (step 4 in `## Promotion Pipeline`) and **Pruned** (this section): Discarded happens at Evaluate time, before anything was ever promoted — there is no active-Memory copy to remove, only the original Decision/Review/PR record, untouched. Pruned happens to something that *was* promoted and later stopped being useful in its active form — its active-Memory copy is removed, but (per the rules above) its trail remains findable through the historical evidence list above.

## Reference

- `decision/decision-engine.md` — where the `Decision → Knowledge Promotion → Roadmap Update` chain this document specifies in depth was first introduced.
- `architecture/engineering-workflow.md` — Stage 10 (Memory Update), the lifecycle stage this pipeline's output feeds into.
- `architecture/engineering-loop.md` — reads promoted Memory (Step 1/3) as part of its own inspection pass.
- `architecture/project-registry.md` — the source of the `Archived` status definition and the Terraform-state-content exclusion this document's Promotion Rule inherits rather than redefines.
