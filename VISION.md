# WCD Engineering Vision

Before writing more code, reset the project direction.

The goal of WCD is **not** to build another AI chat application.
The goal is **not** to build another generic Agent framework.
The goal is **not** to compete with Claude Code, OpenHands, OpenClaw, AutoGen, or LangGraph.

We reuse them whenever possible.

## What problem are we solving?

Today's AI products are mostly task executors:

```
Human
  │
  ▼
Prompt
  │
  ▼
AI
  │
  ▼
Task Finished
  │
  ▼
End
```

Our target is different. We want AI to become a long-running engineering employee:

```
Human
  │
  ▼
Goal
  │
  ▼
AI
  │
  ▼
Planning
  │
  ▼
Execution
  │
  ▼
Verification
  │
  ▼
Memory
  │
  ▼
Continue Working
  │
  ▼
Finish
```

The AI should work continuously instead of waiting for the next prompt.

## Philosophy: Employee, not Agent

Do not build an Agent. Build an Employee.

An Employee has:

- Goals
- Responsibilities
- Memory
- Decision making
- Continuous work
- Learning from previous work

An Agent usually finishes one task. An Employee owns a job.

## Do not reinvent execution

Execution already exists — Claude Code, OpenHands, OpenClaw, GitHub Actions, Kubernetes Jobs, Terraform, `kubectl`. These are execution engines. WCD orchestrates them instead of replacing them.

## WCD Responsibilities

WCD owns exactly **four components** — Goal, Decision, Verification, Organization Memory. **Continuous Loop is the mechanism that connects them, not a fifth peer component.**

(This corrects an earlier draft of this Vision that listed Continuous Loop as one of the four owned things and left Verification out entirely. Verification turned out to be too weak a link — "what does verification mean, and what happens when it fails" — to leave undefined, so it was promoted to a first-class component; Loop was demoted to the mechanism that sequences the other four.)

### 1. Goal

What should be done? Every Goal must carry its own verification criteria — that's what Verification checks against later.

Sources:

- Human — submitted directly.
- Monitoring / Alerts — an alert fires, a Goal is generated automatically.
- Scheduler — a recurring Goal (e.g. Daily Kubernetes Health Check) fires on a cadence.
- Memory-driven — Organization Memory surfaces a preventive Goal from a recurring pattern.

**Learning loop:**

```
Alert / Schedule / Human
        │
        ▼
   Goal Engine
        │
        ▼
Decision → Execution → Verification
        │
        ▼
  Organization Memory
        │
        ▼
   (writes back to) Goal Engine's own rules
```

What gets learned, concretely:

- **Alert → Goal mapping** — which Goal template actually resolved which class of Alert; reinforce what works, retire what doesn't.
- **Priority rules** — recurring patterns (e.g. "a 2am PVC failure always escalates to a human") get promoted to a standing priority rule.
- **False-alarm filtering** — an Alert class that has self-healed within 5 minutes the last 10 times gets a observe-before-Goal delay instead of an immediate Goal.
- **Goal dependency discovery** — if Goal B always runs after Goal A, that becomes an explicit dependency.

MVP sequencing for this learning loop — do not build automatic learning on day one:

1. Manual rules (hardcoded Alert → Goal mapping).
2. Memory starts recording every Goal's outcome, no learning yet.
3. A recurring Goal (`Weekly: Review Memory and Update Rules`) has an LLM analyze accumulated Memory and propose rule updates for a human to review.

### 2. Decision

What should happen next — Continue? Retry? Rollback? Escalate? Wait for approval? Never blindly retry; every decision must be explainable.

**This is a different layer from `decision/decision-engine.md`'s Decision Engine.** That document governs Git/PR lifecycle decisions for evolving the wcd-engineering and project repositories themselves (Approve/Reject/Merge/Close/Reopen/Archive/Escalate/Defer) and is deliberately, permanently human-only — see `policies/ai-pull-request-policy.md`. The Decision component described here governs the Employee's own runtime judgment *while it is executing a Goal* (e.g., mid-way through a Daily Kubernetes Health Check run, deciding whether to retry a flaky check). **These two Decision layers must not be conflated, and the operational layer described below has not been implemented or reconciled against the already-merged Git-lifecycle Decision Engine yet** — that reconciliation is a prerequisite for PLAN-0006 Bootstrap, not an afterthought.

Trigger points — the Decision layer is consulted at four moments:

1. Before a Goal starts — produce an execution plan.
2. After every execution step — continue / adjust / stop?
3. After a Verification result — PASS continues, WARN is triaged, FAIL routes back to Decision.
4. On an exception — timeout, insufficient permission, resource not found.

Possible decisions: `Continue`, `Retry` (informed by Memory, never blind), `Rollback`, `Escalate`, `Wait`, `Cancel`.

**Three-layer structure:**

```
Layer 1: Policy (hard rules, cannot be bypassed)
  → "delete in production" → must Escalate
  → "3 consecutive failures" → must Escalate, no more Retry

Layer 2: Memory (check history)
  → "has this been seen before? how was it resolved?"
  → found → reuse the successful approach
  → not found → fall through to Layer 3

Layer 3: LLM reasoning
  → judge from current context
  → must output an explainable reason, not just a verdict
```

Policy is not hand-written up front — it is **governed by the LLM itself, over time**:

1. Every LLM decision is recorded to Memory along with its reason.
2. A recurring Goal (`Weekly Policy Review`) has an LLM analyze the Decision history in Memory and distill it into rules.
3. Those rules are written to `policies/` (YAML/Markdown), version-controlled, human-reviewable and human-overridable.
4. Future Decisions check the Policy file first; a hit executes directly, a miss falls through to Memory then LLM reasoning, which then feeds back into the next Policy Review.

**Escalate path:**

```
Decision Engine → Escalate → OpenClaw Gateway → Telegram / Slack
```

WCD does not own the notification channel itself — that's delegated to OpenClaw Gateway, consistent with "do not reinvent execution."

### 3. Verification

A Goal that hasn't been verified doesn't count as done.

Every Goal carries its own verification criteria as part of the Goal itself:

```yaml
goal:
  name: "Fix CrashLoopBackOff - payment-service"
  verification:
    - type: pod_running
      target: payment-service
      namespace: production
    - type: no_restart
      window: 5m
    - type: service_ready
      target: payment-service
```

- Human-submitted Goals → the human defines the criteria.
- Alert-triggered Goals → criteria are derived automatically from the Alert type.
- Memory → supplies criteria that have proven effective for similar Goals historically.

Verification does not execute checks itself — it delegates to the same execution engines everything else does (`kubectl`, AWS CLI, GitHub API), waits for a stability window appropriate to what changed, then judges the result:

```
Execution completes
      │
      ▼
Wait for stability window (per Goal type)
  Kubernetes  → 5m
  Terraform   → 10m
  GitHub PR   → wait for CI
  ArgoCD sync → 3m
  AWS resource → 8m
      │
      ▼
Run verification checks (delegated to kubectl / AWS CLI / GitHub API)
      │
      ▼
Compare against Memory's historical "health snapshot"
      │
      ▼
PASS → record new snapshot to Memory → next Goal
WARN → Decision Engine: continue observing, or Escalate
FAIL → Decision Engine: Retry / Rollback / Escalate
```

Stability windows live in `policies/verification.yaml`; the LLM periodically reviews Memory to check whether the configured windows are still appropriate and proposes updates, the same way Policy gets refined.

### 4. Organization Memory

The system's long-term learning substrate — it writes back to every other component. Not generic RAG, not a vector database.

Every completed Goal writes one durable experience record:

```yaml
incident:
  id: "INC-2026-0722-001"
  trigger: "CrashLoopBackOff alert - payment-service"
  goal: "Investigate and fix payment-service"

  investigation:
    root_cause: "OOMKilled - memory limit too low (256Mi)"
    evidence: ["kubectl logs", "kubectl describe pod"]

  decision_made: "Increase memory limit to 512Mi"
  execution: "kubectl patch + ArgoCD sync"

  verification:
    result: PASS
    stability_window: 5m
    health_snapshot: { pods: running, restarts: 0 }

  lessons_learned:
    - "payment-service OOM triggered by high traffic at 14:00-15:00"
    - "512Mi is sufficient, 1Gi is safe ceiling"

  tags: [kubernetes, oom, payment-service, memory]
```

Two-layer storage: **PostgreSQL** (structured, queryable) + **Git** (human-readable — `decisions/`, `policies/`). The objective: never investigate the same problem twice.

## Continuous Loop (mechanism, not a component)

The Employee never stops after one Goal.

```
Goal Queue (priority-ordered)
        │
        ▼
Take next Goal
        │
        ▼
Decision Engine → build execution plan
        │
        ▼
Execution (delegated to Claude Code / OpenHands / OpenClaw)
        │
        ▼
Wait for stability window
        │
        ▼
Verification → PASS / WARN / FAIL
        │
FAIL / WARN → back to Decision Engine
PASS
        │
        ▼
Memory Update
        │
        ▼
Decision Engine → Goal done, or continue
        │
        ▼
back to Goal Queue
```

**Queue-empty behavior** — the Employee has three states, never a fourth "stopped" state:

- Queue has a Goal → executes normally.
- Queue empty → enters listening mode, waiting for an Alert or a scheduled trigger.
- A scheduled trigger fires → auto-injects a Goal (e.g. Daily Health Check).

**Concurrency** — limited parallelism with conflict detection, not full serialization and not unbounded parallelism:

```yaml
conflict_rules:
  - scope: namespace
    max_concurrent: 1
  - scope: terraform_workspace
    max_concurrent: 1
  - scope: global_destructive
    max_concurrent: 1
```

**Trigger mechanism** — a Kubernetes CronJob heartbeat (every minute) checks the Goal Queue (PostgreSQL); a Goal present starts a Kubernetes Job to execute it, an empty queue checks for due scheduled Goals and otherwise sleeps until the next heartbeat. All CronJob/Job definitions are GitOps-managed and synced by ArgoCD. **This scheduler does not exist yet** — `architecture/engineering-loop.md`'s Engineering Loop is a different thing: it's OpenClaw's own cadence for inspecting *this meta-repo's* PR/Roadmap state, not a trigger for the Employee's operational Goal Queue described here.

## MVP

Forget AI Company OS. Forget multiple departments. Forget CEO Agent. Forget complex hierarchies.

Build **one** Employee.

**Name:** DevOps AI Employee

**Responsibilities, and nothing else:**

- Kubernetes
- GitHub
- Terraform
- Jenkins
- ArgoCD
- AWS

## First Workflow

Implement only **one** production workflow: Daily Kubernetes Health Check.

1. Check cluster status.
2. Detect failures.
3. Investigate automatically.
4. Generate an RCA.
5. If safe, generate a Fix PR.
6. Update Organization Memory.
7. Wait for the next scheduled run.

Repeat daily. Do not add more workflows until this one is reliable.

## Success Criteria

The project succeeds when a human can submit one Goal and leave. The AI should Plan, Execute, Verify, Document, Commit, Create PR, and Update Memory, then return either `Completed` or `Escalated` — without requiring continuous human interaction.

## Engineering Rule

Build one AI Employee that reliably completes one real engineering job every day before attempting to build an AI organization.

**As of this writing, none of the ten Completed/Merged FOUNDATION components in `docs/roadmap.md` are this first workflow — they govern how this repository evolves, not how the Employee operates against Kubernetes.** PLAN-0006 Bootstrap, the actual first step toward the workflow above, is still Draft. This Vision's own Engineering Rule is the standard the roadmap should be held to before adding a PLAN-0011 or beyond.

## Reference

- `docs/roadmap.md`, `architecture/project-registry.md` — current Plan status and what to work on next.
- `decision/decision-engine.md` — the Git/PR lifecycle Decision layer this Vision's Decision component is distinct from (see `## WCD Responsibilities` → `### 2. Decision`).
- `policies/ai-pull-request-policy.md` — the human-only Git workflow every AI agent, including one executing this Vision's own Goals, must follow.
- `architecture/engineering-loop.md` — OpenClaw's meta-repo inspection cadence, distinct from this Vision's Continuous Loop trigger mechanism (see `## Continuous Loop`).
