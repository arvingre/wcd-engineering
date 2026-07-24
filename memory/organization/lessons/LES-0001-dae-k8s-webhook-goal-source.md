# LES-0001: dae-k8s's outbound Webhook is a candidate Alert source for the WCD Goal Engine

- Scope: organization
- Status: Active
- Confidence: Medium
- Review After: 2026-10-01

## Observation

`DAELabs/dae-k8s` (K8sInsight, deployed as `lab/dae-k8s` GitOps wiring in `mac-platform-infra`) already ships a generic outbound Webhook notifier at `internal/notify/sink/webhook.go`. It fires on every detected `AnomalyEvent` (CrashLoopBackOff, OOMKilled, ImagePullBackOff, FailedScheduling, Evicted, StateOscillation, ...) and POSTs a JSON payload — `type`, `pod`, `namespace`, `message`, `evidence`, `timestamp`, `dedupKey`, `rootCause`, `suggestion` — that is structurally close to `VISION.md`'s `### 1. Goal` example Goal (`Fix CrashLoopBackOff - payment-service`, with `pod_running` / `no_restart` / `service_ready` verification criteria) and to its "Monitoring / Alerts — an alert fires, a Goal is generated automatically" Goal source.

This means the Goal Engine's first Alert source, when built, likely does not need a bespoke Kubernetes watcher — it can point `dae-k8s`'s existing webhook at a receiving endpoint instead of duplicating detection logic dae-k8s already has.

## Evidence

- `labs/DAELabs/dae-k8s/internal/notify/sink/webhook.go` — generic `Webhook` notifier and its payload shape.
- `labs/DAELabs/dae-k8s/internal/detector/types.go` — `AnomalyEvent` / `AnomalyType` enum the payload is built from.
- `VISION.md` → `## WCD Responsibilities` → `### 1. Goal` — the Goal source and example Goal this payload shape matches.

Single-source observation (one project, not yet cross-validated by a second independent case) — kept as a Lesson rather than a Pattern per `architecture/engineering-memory.md`'s rule against promoting from one case.

## Recommended Behavior

When PLAN-0006 Bootstrap designs the Goal Engine's Alert ingestion, evaluate wiring `dae-k8s`'s existing Webhook sink as the first Alert source before building a new detector or receiver. ADR-0006 (`feature/decision-layer-reconciliation`, merged via PR #15) has unblocked PLAN-0006 per its own Consequences section, but `docs/roadmap.md` still lists PLAN-0006 as Draft and ADR-0006's own `Status:` line still reads Proposed — neither has been synced to reflect the merge yet. Do not treat PLAN-0006 as open until that roadmap/ADR housekeeping and an actual Plan/branch exist.

## Promotion

- Promoted To: N/A
