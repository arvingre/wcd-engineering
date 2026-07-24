# DevOps AI Employee — Bootstrap Design Spec

| Field | Value |
|---|---|
| Codename | **DAE** (DevOps AI Employee) — Bootstrap / MVP slice |
| Backs Roadmap Plan | `PLAN-0006 Bootstrap` (currently Draft in `docs/roadmap.md`) |
| Document type | Architecture + design spec (feeds the Stage-2 Plan for PLAN-0006) |
| Document date | 2026-07-24 |
| Version | v1.0 (Initial Design) |
| Status | Draft — for Architecture Review (Gate 1) |
| Author role | OpenClaw (draft); Human confirms scope per `architecture/engineering-workflow.md` Stage 2 |

---

## 0. How to read this document

This is the concrete, buildable design that `VISION.md` has been missing. `VISION.md` states *what* the DevOps AI Employee should be (four owned components — Goal, Decision, Verification, Organization Memory — connected by a Continuous Loop). This document states *exactly what gets built first, in what order, with what data model and what boundaries*, so `PLAN-0006 Bootstrap` can move from a Draft row to an actual Feature Branch without re-litigating design mid-implementation.

It deliberately follows the same shape a good product design spec has: value → evaluation rubric → scope/YAGNI → keyed technical decisions with tradeoffs → architecture → data model → the one end-to-end workflow → NFRs → security → phased delivery with acceptance criteria → validation → risks → decision summary. Every major decision records what was **rejected** and why, so the design is auditable, not just asserted.

**Grounding facts this design builds on (already true in the repo, not assumed):**
- `dae-k8s` (K8sInsight) is a live project — a Go/React Kubernetes anomaly detector with a generic outbound Webhook sink (`internal/notify/sink/webhook.go`) emitting an `AnomalyEvent` payload. See `architecture/project-registry.md#dae-k8s`.
- `LES-0001` established that this webhook payload structurally matches `VISION.md`'s Goal source, so the first Alert→Goal source can reuse it rather than build a bespoke watcher.
- `ADR-0006` reconciled the Operational Decision Layer (this design's runtime Decision) against the Git-lifecycle Decision Engine (`decision/decision-engine.md`) and, per its Consequences, unblocks PLAN-0006 — **subject to the housekeeping in §4**.
- Merge, approval, and production remain Human-only for every AI agent (`policies/ai-pull-request-policy.md`). This design never violates that; the Employee *proposes*, a Human *decides*.

---

## 1. Positioning

### 1.1 One-line value

> **One DevOps AI Employee that runs one real Kubernetes job every day — detect → investigate → RCA → propose a Fix PR → verify → remember — and returns `Completed` or `Escalated` without a human babysitting the happy path.**

### 1.2 What Bootstrap proves

`VISION.md`'s Engineering Rule: *"Build one AI Employee that reliably completes one real engineering job every day before attempting to build an AI organization."* Bootstrap is the first time the four owned components run as a **connected loop against a real cluster**, instead of only governing how this meta-repo evolves. Every FOUNDATION Plan merged so far (PLAN-0001…, Decision Engine, Roadmap Engine, Knowledge Promotion) governs the repository's own evolution; **none of them is the Employee doing a job.** Bootstrap is.

### 1.3 The gap this closes

| | Before Bootstrap | After Bootstrap |
|---|---|---|
| Goal | Described in prose in `VISION.md` | A row in a `goals` queue, with attached verification criteria |
| Decision | Two layers defined on paper (`decision/decision-engine.md`, ADR-0006) | The **operational** layer actually runs at 4 trigger points during a Goal |
| Verification | A YAML example in `VISION.md` | A real stability-window check against a Memory health snapshot |
| Memory | Templates in `memory/templates/` | An incident record written to PG **and** Git per completed Goal |
| Loop | A diagram in `VISION.md` | A K8s CronJob heartbeat that actually dequeues and runs Goals |

---

## 2. Evaluation rubric

Every keyed decision in §5 is scored on five axes drawn from `VISION.md`'s own philosophy, not a generic checklist. (This replaces k8s-style commercial axes — WCD is an internal engineering OS, not a product being sold.)

| Axis | Meaning | Why it's an axis here |
|---|---|---|
| **Reuse** | Does it reuse an existing execution engine instead of reinventing one? | Vision's central rule: *"Do not reinvent execution."* |
| **Reliability / blast radius** | Failure modes, recoverability, worst-case damage | An Employee acting on a real cluster must fail safe |
| **Explainability** | Can every action/decision state a reason? | Vision: *"Never blindly retry; every decision must be explainable."* |
| **Verifiability** | Can the outcome be checked, not assumed? | Vision: *"A Goal that hasn't been verified doesn't count as done."* |
| **Operability** | Deploy/run/observe friction in the lab, then beyond | It has to actually run daily, unattended |

---

## 3. Scope

### 3.1 Bootstrap MUST deliver (v1)

- [ ] A `goals` queue in PostgreSQL, priority-ordered, with per-Goal verification criteria.
- [ ] A **Continuous Loop trigger**: a Kubernetes CronJob heartbeat (1/min) that dequeues a ready Goal and starts a Kubernetes Job to run it; empty queue → check scheduled Goals → sleep. GitOps-managed, ArgoCD-synced.
- [ ] The **Operational Decision layer** (Policy → Memory → LLM) consulted at the four trigger points from `VISION.md` §2.
- [ ] **Execution** delegated to Claude Code (headless) — the Employee's "hands" (`README.md`). No bespoke executor.
- [ ] **One workflow, end to end**: *Daily Kubernetes Health Check* (§9).
- [ ] **Verification** with a stability window, delegated to `kubectl`, compared against a Memory health snapshot → PASS / WARN / FAIL.
- [ ] **Memory**: one incident record per completed Goal, written to both PostgreSQL (structured) and Git (`decisions/`, human-readable).
- [ ] **Escalate** path: Decision → OpenClaw Gateway → Telegram/Slack (WCD does not own the channel).
- [ ] A minimal, hardcoded **Policy** (Layer 1): destructive action → Escalate; 3 consecutive failures → Escalate, no more Retry.

### 3.2 Explicitly NOT in Bootstrap (YAGNI boundary)

- ❌ **No second Employee, no departments, no CEO agent, no hierarchy** — `VISION.md` MVP says build *one* Employee.
- ❌ **No Terraform / AWS / Jenkins execution.** MVP responsibility is **Kubernetes only** (lab cluster). OpenClaw has no AWS/HCP credentials by default (`memory/projects/wcd-engineering/project-state.md`); Bootstrap does not change that.
- ❌ **No auto-apply, no auto-merge, ever.** The Employee generates a Fix PR; a Human merges (`policies/ai-pull-request-policy.md`). This is a permanent red line, not a phase.
- ❌ **No automatic learning on day one.** Memory *records* outcomes; it does not yet *change rules*. Rule distillation is Phase 3 (deferred) — `VISION.md` §1's explicit MVP sequencing.
- ❌ **No bespoke Kubernetes watcher for alerts.** Reuse `dae-k8s`'s existing webhook (LES-0001) as the first Alert source (Phase 2).
- ❌ **No new notification channel.** Reuse OpenClaw Gateway.
- ❌ **No vector database / generic RAG.** Memory is PostgreSQL + Git, per `VISION.md` §4.

---

## 4. Phase 0 — prerequisite housekeeping (blocks opening PLAN-0006)

`LES-0001` is explicit: *"Do not treat PLAN-0006 as open until that roadmap/ADR housekeeping and an actual Plan/branch exist."* Before any implementation branch:

1. **Sync ADR-0006 status** — flip its `Status:` from `Proposed` to the merged reality (it merged via PR #15). Without this, the operational-vs-git-lifecycle Decision boundary this design depends on reads as un-adopted.
2. **Flip PLAN-0006 in `docs/roadmap.md`** from `Draft` to `In Progress` **only when** its Feature Branch actually opens — not before (roadmap must never show a status that isn't yet true, per `architecture/engineering-workflow.md` Stage 10).
3. **Add `Escalated` to the roadmap status vocabulary.** `docs/roadmap.md` already carries `Deferred` and `Archived` (added by a later reconciliation PR), so Phase 3's `Deferred` parking is already valid — the only word still missing is `Escalated`, which `decision/decision-engine.md`'s Decision State Machine can produce. This is a small consistency fix, **not** a hard blocker for opening PLAN-0006 (that blocker is item 1, the ADR-0006 status sync). Note: `decision/decision-engine.md`'s own vocabulary note still lists `Deferred`/`Archived` as missing too — that note is now stale and can be trimmed in the same pass.

Phase 0 is documentation-only and follows the normal eleven-stage workflow itself.

---

## 5. Keyed technical decisions

Each decision: rubric read, then the rejected alternatives and why.

### 5.1 Orchestrator language: Go

| Axis | Read |
|---|---|
| Reuse | ✓ `dae-k8s` is Go; `client-go`, K8s `Job`/`CronJob`, and `kubectl` interop are first-class |
| Reliability | ✓ Single static binary, easy to run as a K8s Job image |
| Explainability | ✓ Structured `slog`/`zap` JSON logs with a decision reason field |
| Verifiability | — neutral |
| Operability | ✓ One image, no runtime deps beyond PG + kubeconfig |

**Rejected:** Python (heavier container, dependency drift for a long-running in-cluster job) — acceptable later for LLM glue, not the core loop.

### 5.2 State store: PostgreSQL — and nothing else

Goal Queue, operational Decisions, Verifications, Incidents, and concurrency locks all live in one PostgreSQL instance. This mirrors the same restraint the k8s-risk-platform design praised: use one durable component many ways instead of adding stateful infrastructure.

| Axis | Read |
|---|---|
| Reuse | ✓ `VISION.md` §4 already mandates PostgreSQL for structured Memory |
| Reliability | ✓ Transactional enqueue/dequeue; `pg_advisory_lock` for concurrency and leader election |
| Explainability | ✓ Every Decision/Verification is a queryable row, not an in-memory event |
| Operability | ✓ One backing service in the lab |

**Rejected:** Redis / NATS / Kafka for the queue (new stateful component for a workload that peaks at a handful of Goals/day), a vector DB for Memory (`VISION.md` §4 explicitly says *"Not generic RAG, not a vector database"*).

### 5.3 Continuous Loop trigger: Kubernetes CronJob heartbeat

A `CronJob` fires every minute, checks the `goals` queue, and starts a `Job` per ready Goal; an empty queue checks for due scheduled Goals, else sleeps to the next heartbeat. Exactly `VISION.md`'s described mechanism. GitOps-defined, ArgoCD-synced.

| Axis | Read |
|---|---|
| Reuse | ✓ Native K8s scheduling; no custom controller/operator to write or run |
| Reliability | ✓ Job restart/backoff is the platform's, not ours; a crashed run is just a failed Job |
| Operability | ✓ Fully declarative, visible via `kubectl get cronjob,job` and ArgoCD |

**Rejected:** a long-running custom controller / Operator (more code, more failure surface, more to secure) for Bootstrap. Revisit only if per-minute latency becomes a real constraint (NFR §12 says it isn't at lab scale).

### 5.4 Execution engine: Claude Code (headless)

The Employee's investigation/RCA/Fix-PR generation is delegated to Claude Code running non-interactively inside the Job. `README.md`: *"Claude Code is our hands."*

| Axis | Read |
|---|---|
| Reuse | ✓ Do-not-reinvent: Claude Code already drives `kubectl`, git, and PR creation |
| Explainability | ✓ Its transcript is the evidence trail for the incident record |
| Verifiability | ✓ It produces a PR (reviewable artifact), never a silent mutation |

**Rejected:** OpenHands / a hand-rolled tool loop as the *primary* Bootstrap executor (`VISION.md` lists them as *optional* engines) — kept behind the same execution interface so a later Plan can swap without touching Goal/Decision/Verification/Memory.

### 5.5 First Goal sources: a schedule + the dae-k8s webhook

Two sources for Bootstrap, in order:
1. **Scheduler** — a recurring Goal `Daily: Kubernetes Health Check` (Phase 1).
2. **Monitoring/Alerts** — a tiny HTTP receiver that maps `dae-k8s`'s `AnomalyEvent` webhook to a Goal (Phase 2, per `LES-0001`).

| Axis | Read |
|---|---|
| Reuse | ✓ Phase 2 needs **zero** detection code — `dae-k8s` already detects and POSTs |
| Reliability | ✓ Its payload carries `dedupKey`, so idempotent Goal creation is cheap |
| Operability | ✓ The receiver is one small Deployment + Service |

**Rejected:** building a bespoke Kubernetes event watcher (duplicates detection `dae-k8s` already ships — LES-0001's core finding). Human-submitted Goals are supported by the same queue but not a Bootstrap deliverable to *drive*.

### 5.6 Fix application: PR only, Human merges

The Employee may **generate** a Fix (a PR to the project repo, or a push to the `dae-k8s` Gitea mirror as a change proposal), never apply it to a shared/production branch. `policies/ai-pull-request-policy.md`: AI works through `feature/*` + Draft PR; merge is Human-only.

**Rejected:** auto-remediation / `kubectl apply` by the Employee (violates the red line and the identity boundary). WARN/FAIL and destructive cases route to Escalate, not to action.

### 5.7 Memory: two-layer (PostgreSQL + Git)

Structured, queryable incident rows in PostgreSQL; human-readable records committed under `decisions/` (and policy updates under `policies/`) in Git. Exactly `VISION.md` §4's two-layer store. Objective: *"never investigate the same problem twice."*

**Rejected:** single-store-only (PG-only loses human reviewability; Git-only loses queryability). Both, on purpose.

### 5.8 Escalation & notification: OpenClaw Gateway

`Decision → Escalate → OpenClaw Gateway → Telegram / Slack`. WCD does not own the channel (`VISION.md` §2). Bootstrap emits an escalation event to OpenClaw; the channel wiring is OpenClaw's.

**Rejected:** a WCD-owned notifier (reinvents delivery OpenClaw already does).

---

## 6. Architecture

### 6.1 High-level

```
                 ┌───────────────────────────────────────────┐
   Sources ──▶   │                Goal Engine                 │
  (schedule,     │   goals queue (PostgreSQL, priority)       │
   dae-k8s       └──────────────────┬────────────────────────┘
   webhook,                         │ heartbeat dequeue (CronJob 1/min)
   human)                           ▼
                 ┌───────────────────────────────────────────┐
                 │  Runner Job (K8s Job, one per Goal)         │
                 │  ┌─────────────┐  ┌──────────────────────┐ │
                 │  │  Decision   │  │  Execution           │ │
                 │  │  Policy →   │─▶│  Claude Code headless│ │
                 │  │  Memory →   │  │  (kubectl / git / PR)│ │
                 │  │  LLM        │  └───────────┬──────────┘ │
                 │  └─────┬───────┘              │            │
                 │        │        ┌─────────────▼──────────┐ │
                 │        │        │  Verification          │ │
                 │        │        │  stability window +    │ │
                 │        │        │  kubectl + snapshot cmp│ │
                 │        │        └─────────────┬──────────┘ │
                 │   Escalate                    │ PASS/WARN/FAIL
                 └────────┼──────────────────────┼────────────┘
                          │                       ▼
                          │            ┌────────────────────┐
                          │            │ Organization Memory │
                          │            │ PostgreSQL + Git    │
                          │            └────────────────────┘
                          ▼
                 OpenClaw Gateway ──▶ Telegram / Slack
```

### 6.2 Component ↔ Vision mapping

| Vision component | Bootstrap realization | Backing store |
|---|---|---|
| Goal | `goals` queue + scheduled/alert sources | PostgreSQL |
| Decision (operational) | Policy→Memory→LLM at 4 trigger points | PostgreSQL (`decisions`) + Git `policies/` |
| Verification | stability window + `kubectl` + snapshot compare | PostgreSQL (`verifications`) |
| Organization Memory | incident record per Goal | PostgreSQL (`incidents`) + Git `decisions/` |
| Continuous Loop | CronJob heartbeat → Job per Goal | Kubernetes (GitOps/ArgoCD) |

### 6.3 The two Decision layers must not be conflated

Per `ADR-0006` and `decision/decision-engine.md`:
- **Git-lifecycle Decision Engine** (`decision/decision-engine.md`) — eight Human-only decision types (Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer) about **Plans/PRs in this repo**. Permanently human-only.
- **Operational Decision layer** (this design) — the Employee's runtime judgment *while executing a Goal* (Continue/Retry/Rollback/Escalate/Wait/Cancel). Autonomous within Policy, but Escalate always hands back to a Human.

Bootstrap implements only the operational layer. It never generates or self-applies a Git-lifecycle decision.

---

## 7. Data flow

### 7.1 Scheduled — Daily Kubernetes Health Check

1. Heartbeat CronJob sees a due scheduled Goal → enqueues `Daily: Kubernetes Health Check` (verification criteria attached) → starts a Runner Job.
2. Decision (before-start trigger) builds an execution plan: Policy check → Memory check ("what did yesterday's snapshot look like?") → LLM plan.
3. Execution (Claude Code): `kubectl get nodes/pods/events`, detect anomalies.
4. On anomaly: investigate (`kubectl logs`, `describe`) → generate RCA.
5. If safe **and** Policy allows: generate a Fix PR. If destructive/uncertain: Escalate.
6. Verification: wait the K8s stability window (5m) → re-check → compare to Memory health snapshot → PASS/WARN/FAIL.
7. Memory: write the incident record (PG + Git), update the health snapshot. Return `Completed` or `Escalated`.

### 7.2 Reactive — dae-k8s anomaly (Phase 2)

1. `dae-k8s` detects e.g. `CrashLoopBackOff` → POSTs its `AnomalyEvent` webhook.
2. DAE receiver maps payload → Goal (using `dedupKey` for idempotency) → enqueue.
3. Same loop as §7.1 steps 2–7.

---

## 8. Data model

### 8.1 PostgreSQL (structured)

```sql
-- The Goal Queue
CREATE TABLE goals (
  id             UUID PRIMARY KEY,
  source         TEXT NOT NULL,          -- schedule | alert | human | memory
  source_ref     TEXT,                   -- dedupKey / schedule name / alert id
  name           TEXT NOT NULL,
  priority       INT  NOT NULL DEFAULT 100,
  status         TEXT NOT NULL,          -- queued | running | waiting | done | escalated | cancelled
  spec           JSONB NOT NULL,         -- { responsibilities, verification: [...] }
  conflict_scope TEXT,                   -- namespace:<ns> | tf_workspace:<w> | global_destructive
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- one active Goal per (source, source_ref) → idempotent alert ingestion
CREATE UNIQUE INDEX goals_active_source_uniq
  ON goals (source, source_ref)
  WHERE status IN ('queued','running','waiting');

-- One execution attempt of a Goal
CREATE TABLE goal_runs (
  id          UUID PRIMARY KEY,
  goal_id     UUID NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  attempt     INT  NOT NULL,
  plan        JSONB,                     -- the Decision-built execution plan
  outcome     TEXT,                      -- completed | escalated | failed
  started_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  finished_at TIMESTAMPTZ
);

-- Every operational Decision, with its mandatory reason
CREATE TABLE decisions (
  id            UUID PRIMARY KEY,
  goal_run_id   UUID NOT NULL REFERENCES goal_runs(id) ON DELETE CASCADE,
  trigger_point TEXT NOT NULL,           -- before_goal | after_step | after_verify | on_exception
  layer         TEXT NOT NULL,           -- policy | memory | llm
  verdict       TEXT NOT NULL,           -- continue | retry | rollback | escalate | wait | cancel
  reason        TEXT NOT NULL,           -- NEVER empty; no blind retry (Vision §2)
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Verification results
CREATE TABLE verifications (
  id              UUID PRIMARY KEY,
  goal_run_id     UUID NOT NULL REFERENCES goal_runs(id) ON DELETE CASCADE,
  criteria        JSONB NOT NULL,
  stability_window TEXT NOT NULL,        -- e.g. 5m
  result          TEXT NOT NULL,         -- pass | warn | fail
  health_snapshot JSONB,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Organization Memory: one durable incident per completed Goal
CREATE TABLE incidents (
  id             UUID PRIMARY KEY,
  goal_id        UUID REFERENCES goals(id) ON DELETE SET NULL,
  trigger        TEXT NOT NULL,
  root_cause     TEXT,
  evidence       JSONB,                  -- ["kubectl logs", "kubectl describe pod", ...]
  decision_made  TEXT,
  execution      TEXT,
  verify_result  TEXT,                   -- pass | warn | fail
  lessons        JSONB,                  -- ["512Mi sufficient", ...]
  tags           TEXT[],
  git_ref        TEXT,                   -- path/commit of the human-readable record
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX ON incidents USING GIN (tags);

-- Health baseline the next run compares against
CREATE TABLE health_snapshots (
  scope       TEXT PRIMARY KEY,          -- cluster / namespace:<ns>
  snapshot    JSONB NOT NULL,            -- { pods: running, restarts: 0, ... }
  taken_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

Concurrency uses `pg_advisory_lock(hash(conflict_scope))` — no table needed.

### 8.2 Git (human-readable)

- `decisions/INC-YYYY-MMDD-NNN.md` — the human-readable twin of each `incidents` row, using `memory/templates/incident.md`. `incidents.git_ref` points to it.
- `policies/decision.yaml`, `policies/verification.yaml` — Layer-1 hard rules and stability windows. Version-controlled, human-overridable (Phase 1 hardcodes minimal rules; Phase 3 proposes updates here).

---

## 9. The one workflow — Daily Kubernetes Health Check

Exactly `VISION.md`'s First Workflow, made concrete. **Do not add a second workflow until this one is reliable** (Vision's engineering rule).

```yaml
goal:
  name: "Daily: Kubernetes Health Check"
  source: schedule
  conflict_scope: "cluster"
  verification:
    - type: all_nodes_ready
    - type: no_pods_in: [CrashLoopBackOff, ImagePullBackOff, Pending]
    - type: no_restart_spike     # vs yesterday's health_snapshot
      window: 5m
steps:
  1_check:      "kubectl get nodes, pods -A, events -A"
  2_detect:     "diff against health_snapshots[cluster]"
  3_investigate:"on anomaly: kubectl logs/describe → evidence"
  4_rca:        "LLM: root_cause + suggestion"
  5_fix:        "if safe & policy-allowed: open Fix PR; else Escalate"
  6_verify:     "wait 5m → re-check criteria → PASS/WARN/FAIL"
  7_memory:     "write incidents row + decisions/INC-*.md; update snapshot"
outcome: Completed | Escalated
```

---

## 10. Decision & Policy

Three layers, consulted at four trigger points (before Goal / after step / after Verification / on exception):

```
Layer 1  Policy   (hard rules, cannot be bypassed)
           destructive action        → Escalate
           3 consecutive failures    → Escalate (no more Retry)
Layer 2  Memory   (has this been seen? how was it resolved?)  → reuse
Layer 3  LLM      (reason from context; MUST output an explainable reason)
```

- Bootstrap **hardcodes** only the Layer-1 rules above in `policies/decision.yaml`. No automatic Policy distillation (that is Phase 3).
- Every `decisions` row carries a non-empty `reason` — enforced, because "never blindly retry" is a Bootstrap acceptance criterion, not an aspiration.

---

## 11. Verification

```
Execution completes → wait stability window (K8s: 5m)
  → run checks (delegated to kubectl)
  → compare to health_snapshots[scope]
  → PASS  → record snapshot → Memory → next Goal
    WARN  → Decision: observe or Escalate
    FAIL  → Decision: Retry / Rollback(via Human) / Escalate
```

- Stability windows live in `policies/verification.yaml` (K8s 5m for Bootstrap; other engines' windows are recorded but unused until their workflow exists).
- **A Goal never reaches `done` without a `verifications.result = pass` row.** This is the single hardest gate in the design.

---

## 12. Non-functional requirements

| Category | Metric | Target (lab) |
|---|---|---|
| Latency | Queued Goal → Runner Job started | ≤ 1 heartbeat (60s) |
| Autonomy | Happy-path Daily Health Check | 0 human interactions |
| Explainability | `decisions` rows with empty `reason` | 0 |
| Verifiability | Goals `done` without a PASS verification | 0 |
| Blast radius | Auto-applied changes to a shared/prod branch | 0 (PR-only) |
| Idempotency | Duplicate active Goal for same `(source, source_ref)` | 0 (unique index + advisory lock) |
| Recoverability | Crashed Runner Job | Job backoff; Goal returns to `queued` |
| Escalation | Escalate event reaching OpenClaw | delivered or itself Escalated |

---

## 13. Security & guardrails

- **AI proposes, Human decides** — no AI merge/approve/apply, ever (`policies/ai-pull-request-policy.md`).
- **Kubernetes only, lab only** for Bootstrap. No AWS/HCP Terraform credentials (OpenClaw has none by default — `project-state.md`).
- **Least-privilege kubeconfig**: the Runner Job's ServiceAccount is `get/list/watch` + the narrowest write needed to open a PR-backed change — never cluster-admin. Aligns with `standards/security/identity-boundary.md` (no shared credentials, no `AdministratorAccess`, no `0.0.0.0/0`).
- **No secrets in Git.** PG creds and any tokens via K8s `Secret`; the receiver validates the `dae-k8s` webhook with a shared token from a Secret.
- **Security Review** applies at Gate 2 (`architecture/engineering-workflow.md` §6) since the receiver is network-exposed and the Job holds a kubeconfig.

---

## 14. Deployment (lab)

- Runs **in-cluster** on the OrbStack lab cluster, GitOps-defined and ArgoCD-synced (same substrate as `dae-k8s`).
- Objects: `CronJob` (heartbeat), `Job` (per-Goal runner image), `Deployment`+`Service` (dae-k8s webhook receiver, Phase 2), `PostgreSQL` (queue+memory), `Secret`s (db creds, webhook token, kubeconfig), ArgoCD `Application`.
- Manifests live in the project's own GitOps wiring under `labs/mac-platform-infra/lab/`, **not** in this standards repo (`README.md` content boundary: no deployment artifacts here).

---

## 15. Phased delivery plan

> This section is what turns into `PLAN-0006 Bootstrap`. Each slice is independently testable per `architecture/engineering-workflow.md` Stage 3.

**Phase 0 — Housekeeping (docs-only, §4).** Sync ADR-0006 + roadmap vocabulary. *Acceptance:* PLAN-0006 can be opened without a stale-status contradiction.

**Phase 1 — Bootstrap MVP (the buildable core).**
1. PG schema + migrations (`goals`, `goal_runs`, `decisions`, `verifications`, `incidents`, `health_snapshots`).
2. Goal Queue enqueue/dequeue + advisory-lock concurrency.
3. CronJob heartbeat + Runner Job image (GitOps/ArgoCD).
4. Execution adapter over Claude Code (headless) behind a swappable interface.
5. Operational Decision (Policy→Memory→LLM) at the 4 trigger points; minimal hardcoded Policy.
6. Daily Kubernetes Health Check workflow (§9), happy path.
7. Verification (5m window, kubectl, snapshot compare).
8. Memory writer (PG row + Git `decisions/INC-*.md`).
9. Escalate → OpenClaw Gateway.

*Phase-1 acceptance (Vision Success Criteria):* a scheduled Daily Health Check Goal runs Plan→Execute→Verify→Document→(Fix PR)→Memory unattended and returns `Completed` or `Escalated`.

**Phase 2 — Reactive source (LES-0001).** dae-k8s webhook receiver → Goal mapping (idempotent via `dedupKey`). *Acceptance:* a real `dae-k8s` `CrashLoopBackOff` produces a Goal and, where safe, a Fix PR.

**Phase 3 — Learning loop (DEFERRED, not Bootstrap).** A recurring `Weekly: Review Memory and Update Rules` Goal has an LLM propose `policies/*.yaml` updates **for Human review** — never self-applied. Held `Deferred` in the roadmap until Phase 1 is reliable (`VISION.md` §1 sequencing).

---

## 16. Validation checklist

Confirmed at `architecture/engineering-workflow.md` Stage 9 against the merged result:

- [ ] Heartbeat starts a Runner Job for a ready Goal within one minute.
- [ ] Daily Health Check runs detect→RCA→(optional Fix PR)→verify→memory with no human interaction on the happy path.
- [ ] No Goal reaches `done` without a `verifications.result = pass`.
- [ ] Every `decisions` row has a non-empty `reason`.
- [ ] A destructive/uncertain case Escalates via OpenClaw and applies nothing.
- [ ] Every completed Goal has an incident record in **both** PG and Git.
- [ ] (Phase 2) A dae-k8s webhook anomaly yields exactly one active Goal per `dedupKey`.

---

## 17. Risks & mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| LLM proposes an unsafe Fix | Cluster harm | PR-only + Policy destructive→Escalate; Human merge gate |
| Heartbeat double-runs a Goal | Duplicate action | Unique active-Goal index + `pg_advisory_lock(conflict_scope)` |
| Verification false PASS | "Fixed" but still broken | Stability window + snapshot compare, not a point check |
| dae-k8s webhook storms | Goal queue flood | `dedupKey` idempotency + priority + per-scope concurrency=1 |
| PLAN-0006 opened before Phase 0 | Stale roadmap/ADR contradiction | §4 gates it explicitly |
| Scope creep to AWS/Terraform | MVP never ships | §3.2 YAGNI boundary; Kubernetes-only |
| Learning loop built too early | Unreviewable rule drift | Phase 3 Deferred; Memory records before it changes rules |

---

## 18. Decision summary

| Item | Choice | Status |
|---|---|---|
| Orchestrator language | Go | ✅ |
| State store | PostgreSQL (queue + decisions + memory + locks) | ✅ |
| Loop trigger | K8s CronJob heartbeat (1/min) + Job per Goal | ✅ |
| Execution engine | Claude Code headless (swappable interface) | ✅ |
| First Goal sources | Schedule (P1) + dae-k8s webhook (P2) | ✅ |
| Fix application | PR only; Human merges | ✅ (red line) |
| Memory | PostgreSQL + Git two-layer | ✅ |
| Escalation | OpenClaw Gateway → Telegram/Slack | ✅ |
| Decision (operational) | Policy → Memory → LLM, 4 trigger points | ✅ |
| Learning / policy distillation | Deferred to Phase 3 | ⏸️ |
| MVP responsibility surface | Kubernetes only, lab only | ✅ |

---

## 19. Next steps

1. ⬜ Human reviews this design (Architecture Review, Gate 1).
2. ⬜ Complete Phase 0 housekeeping (§4) — ADR-0006 + roadmap vocabulary sync.
3. ⬜ Open `PLAN-0006 Bootstrap` as a Stage-2 Plan (objective/scope/tasks/constraints/deliverables) referencing this design; reserve nothing new — PLAN-0006 already exists in `docs/roadmap.md`.
4. ⬜ Feature branch `feature/plan-0006-bootstrap` off `main`; implement Phase 1 slices as Draft PR(s).
5. ⬜ Validation (§16) → Memory Update → Close, per the eleven-stage workflow.

---

## 20. References

- `VISION.md` — the four owned components, MVP, First Workflow, Success Criteria this design realizes.
- `decision/decision-engine.md`, `adr/ADR-0006-operational-vs-git-lifecycle-decisions.md` — the Git-lifecycle vs operational Decision boundary (§6.3).
- `architecture/engineering-workflow.md` — the eleven-stage lifecycle and gates this Plan moves through.
- `architecture/project-registry.md#dae-k8s`, `memory/organization/lessons/LES-0001-dae-k8s-webhook-goal-source.md` — the reused first Alert source.
- `policies/ai-pull-request-policy.md` — the Human-only merge/approval boundary this design never crosses.
- `standards/security/identity-boundary.md` — the identity rules the Runner Job's ServiceAccount and the receiver obey.
- `docs/roadmap.md` — where `PLAN-0006 Bootstrap` is scheduled.

---

*End of design spec.*
