# WCD Engineering Memory

## Purpose

Engineering Memory is the durable organizational record used by OpenClaw and other authorized AI agents to continue work without rediscovering the same facts in every session. It records verified engineering reality: decisions, incidents, runbooks, lessons, patterns, project state, and the evidence that supports them.

Memory is not a transcript archive and not an unrestricted dump of model output. A record becomes organizational memory only when it is structured, traceable, current, and supported by an approved source such as a merged PR, adopted ADR, incident evidence, validated runbook, or explicit human decision.

This document defines the memory model for the whole WCD Engineering OS. Project repositories may keep project-specific memory, but they follow the same record types, lifecycle, provenance rules, and update rules defined here.

## Design principles

1. **Evidence before conclusion.** Every durable claim links to the source that established it.
2. **Current truth is explicit.** Superseded and stale records remain traceable but are never presented as current.
3. **Memory is structured.** Agents must not depend on long chat histories or growing unbounded Markdown files.
4. **Write after verification.** Proposed findings remain working context until an accepted event authorizes promotion into durable memory.
5. **Project isolation.** Project-specific facts stay scoped to their project unless deliberately promoted to organization-wide memory.
6. **No secrets.** Credentials, tokens, private keys, raw sensitive payloads, and Terraform state never enter Engineering Memory.
7. **Human authority remains final.** AI agents may draft and update records after verified events, but may not invent approvals or promote disputed conclusions.

## Memory layers

Engineering Memory is divided into four layers so agents load only the context needed for the current task.

| Layer | Purpose | Typical contents | Load behavior |
|---|---|---|---|
| Working Context | Temporary context for one active Plan or investigation | hypotheses, task notes, incomplete evidence | Loaded only for the active task; deleted or archived after closure |
| Project Memory | Durable facts about one project | project state, active constraints, project decisions, project incidents, runbooks | Loaded after reading `architecture/project-registry.md` and selecting the project |
| Organizational Memory | Reusable knowledge across projects | engineering standards, cross-project patterns, operating rules, shared lessons | Loaded by topic, not in full |
| Evidence Archive | Immutable or append-only source references | PRs, ADRs, incident records, CI reports, Terraform run references | Retrieved only when verification or audit is required |

The layers are related but not interchangeable. Working Context may contain unverified ideas. Project and Organizational Memory contain only promoted records. Evidence Archive is the proof layer, not the summary layer.

## Record types

Engineering Memory uses six durable record types.

### 1. Decision

A decision records a lasting engineering choice and its current status.

Required fields:

- `id`: stable identifier, for example `DEC-0001`
- `scope`: organization or project name
- `title`
- `status`: Proposed, Adopted, Superseded, Rejected
- `decision`
- `rationale`
- `constraints`
- `source`: ADR, approved PR, or explicit human decision
- `effective_at`
- `supersedes` / `superseded_by`, when applicable

An ADR remains the authoritative design artifact when one exists. A Decision memory record is the concise operational index that tells agents which ADR is current and what rule it establishes.

### 2. Incident

An incident records an observed failure, its evidence, impact, response, and verified outcome.

Required fields:

- `id`: for example `INC-2026-0001`
- `project`
- `started_at` and `resolved_at`
- `severity`
- `symptoms`
- `impact`
- `evidence_refs`
- `root_cause`: confirmed, suspected, or unknown
- `mitigation`
- `permanent_fix`
- `related_prs`
- `lessons`
- `status`: Open, Monitoring, Resolved, Closed

Raw logs and metric payloads remain in the evidence system. Memory stores the verified summary and references.

### 3. Runbook

A runbook records a validated operational procedure.

Required fields:

- `id`: for example `RUN-0001`
- `scope`
- `trigger`
- `preconditions`
- `steps`
- `verification`
- `rollback`
- `risk_level`
- `owner`
- `last_validated_at`
- `source`
- `status`: Draft, Validated, Deprecated

A runbook is not considered reusable until its verification method is explicit and it has been validated by a human or a successful controlled execution.

### 4. Lesson

A lesson records a verified observation that should influence future work but is not yet a mandatory standard.

Required fields:

- `id`: for example `LES-0001`
- `scope`
- `observation`
- `evidence_refs`
- `recommended_behavior`
- `confidence`: Low, Medium, High
- `review_after`
- `status`: Active, Promoted, Retired

A repeated high-confidence Lesson may later be promoted into a Pattern, Standard, Runbook, or ADR.

### 5. Pattern

A pattern records a recurring problem or reusable solution seen across multiple verified cases.

Required fields:

- `id`: for example `PAT-0001`
- `scope`
- `name`
- `signal`
- `conditions`
- `known_causes`
- `recommended_response`
- `evidence_refs`: at least two independent cases unless a human explicitly approves an exception
- `confidence`
- `status`: Candidate, Validated, Deprecated

Patterns must not be created from one speculative incident. The distinction between a Lesson and a Pattern prevents premature generalization.

### 6. Project State

Project State is the compact current-state record for a registered project.

Required fields:

- `project`
- `current_phase`
- `active_plans`
- `open_risks`
- `current_constraints`
- `latest_release_or_baseline`
- `last_verified_at`
- `source_refs`

`architecture/project-registry.md` remains the system-wide entry point. Project State supplements it with operationally changing information and must never silently contradict the Registry.

## Storage layout

The default repository layout is:

```text
memory/
  organization/
    decisions/
    lessons/
    patterns/
    runbooks/
  projects/
    <project-name>/
      state.md
      decisions/
      incidents/
      lessons/
      patterns/
      runbooks/
  archive/
```

Each durable record is stored in its own file. Large append-only files are prohibited because they become expensive to load, difficult to review, and unsafe to update concurrently.

Recommended filenames:

```text
DEC-0001-short-title.md
INC-2026-0001-short-title.md
RUN-0001-short-title.md
LES-0001-short-title.md
PAT-0001-short-title.md
```

## Record lifecycle

All durable records follow this lifecycle:

```text
Observed
  -> Drafted
  -> Verified
  -> Active
  -> Superseded / Deprecated / Retired
  -> Archived
```

- **Observed**: evidence exists, but no memory record has been written.
- **Drafted**: an agent or human has created a structured candidate record.
- **Verified**: the record has been checked against its source evidence.
- **Active**: the record is safe for agents to use as current context.
- **Superseded / Deprecated / Retired**: the record remains traceable but is not current guidance.
- **Archived**: retained for audit and history; excluded from normal retrieval.

No agent may skip directly from Observed to Active.

## Promotion rules

A memory write must have a promotion trigger.

| Trigger | Memory action |
|---|---|
| PR merged | Update affected Project State; add or update Decision, Runbook, Lesson, or Pattern only when the merged change supports it |
| ADR adopted | Create or update the corresponding Decision record |
| Incident resolved | Create or finalize Incident; draft Lesson; promote Pattern only with sufficient repeated evidence |
| Human decision | Record the decision and its exact scope; link the conversation, issue, or PR where possible |
| Runbook successfully validated | Mark Runbook Validated and update `last_validated_at` |
| Standard changed | Supersede conflicting memory and update affected Project State records |

A PR opening, model recommendation, CI failure, or unconfirmed hypothesis is not enough to create Active durable memory.

## Update ownership

| Action | Owner |
|---|---|
| Draft a candidate record | OpenClaw, another assigned agent, or Human |
| Verify evidence and scope | OpenClaw reviewer and/or Human; never rely only on the authoring agent |
| Promote to Active | OpenClaw after a verified trigger, or Human directly |
| Supersede or retire | OpenClaw after an accepted source change, or Human |
| Archive | OpenClaw according to retention policy |
| Resolve conflicts | Human |

This follows the Engineering Workflow: after Merge, OpenClaw performs Memory Update before Roadmap Update and Close.

## Retrieval protocol

Agents must retrieve memory in this order:

1. Read `architecture/project-registry.md`.
2. Identify the project and task scope.
3. Read that project's `state.md`.
4. Retrieve only relevant active Decisions, Runbooks, Lessons, and Patterns by topic or identifier.
5. Open source evidence only when validating a claim, reviewing a conflict, or making a high-risk decision.
6. Ignore Draft, Superseded, Deprecated, Retired, and Archived records unless the task explicitly requires history.

Agents must cite memory record IDs in Plans, PR descriptions, reviews, RCA reports, and recommendations whenever a record materially affects the result.

## Conflict and staleness handling

When two records conflict:

1. Prefer the record with the authoritative source type: adopted ADR or explicit human decision over a Lesson or Pattern.
2. Prefer Active over non-active statuses.
3. Prefer the more recent effective source only when it explicitly supersedes the older record.
4. Do not infer supersession from date alone.
5. If authority remains unclear, stop advancement and request a human decision.

Every Project State record must include `last_verified_at`. Records with time-sensitive operational facts must include `review_after`. Passing that date does not automatically invalidate a record, but it marks the record stale and prevents an agent from treating it as sufficient evidence for a high-risk action.

## Memory update procedure

After an approved change merges, OpenClaw performs the following read/write loop:

1. Read the merged PR, final review state, linked Plan, affected ADRs, and changed files.
2. Determine which existing memory records are affected.
3. Draft the minimum necessary updates.
4. Verify every changed claim against merged or approved evidence.
5. Update or create records on a `feature/memory-*` branch.
6. Open a Draft PR when the update is substantial, disputed, cross-project, or changes a Decision, Pattern, Runbook, or organizational rule.
7. For a purely mechanical Project State refresh, follow the repository's approved automation policy once one exists; until then, use a Draft PR.
8. After human merge, update `docs/roadmap.md` and close the Plan.

Memory updates do not bypass the AI Pull Request Policy. AI agents never commit directly to `main` and never merge their own memory changes.

## Learning loop

Engineering Memory supports learning but does not automatically rewrite organizational rules.

```text
Incident / Review / Delivery result
  -> Lesson candidate
  -> repeated evidence
  -> Pattern candidate
  -> validation
  -> Runbook / Standard / ADR proposal
  -> human approval
  -> active organizational rule
```

This is the boundary between Memory Engineering and Learning Engineering: memory preserves verified experience; learning proposes controlled changes to the system based on that experience.

## Security and privacy

The following content is prohibited:

- credentials, tokens, private keys, recovery codes, or secret values
- Terraform state or raw provider credentials
- raw customer personal data when a redacted reference is sufficient
- unrestricted production logs containing sensitive payloads
- copied private chat transcripts as durable memory
- model hidden reasoning or chain-of-thought

Store references, redacted evidence, and verified summaries instead. Access to private project memory follows the project's repository and identity controls.

## Minimum viable implementation

PLAN-0005 is complete when the following foundation exists:

1. This architecture document is approved.
2. The `memory/` directory structure is introduced through a separate implementation Plan or follow-up commit.
3. A record template exists for each of the six record types.
4. At least one real merged change is processed through the Memory Update procedure.
5. OpenClaw can retrieve Project State plus topic-specific records without loading the entire memory tree.
6. No memory write path bypasses Draft PR and human merge controls.

## Non-goals

This foundation does not yet implement:

- a vector database or semantic search service
- automatic embedding of every repository file or chat message
- autonomous online training or model fine-tuning
- automatic promotion of Lessons into Patterns or Standards
- a centralized enterprise audit database
- cross-company sharing of private organizational memory

Those may be introduced only when the file-based model proves insufficient and a new Plan defines migration, access control, cost, and audit requirements.

## References

- `architecture/project-registry.md` — identifies projects and their authoritative repositories.
- `architecture/engineering-workflow.md` — defines Memory Update as a required post-merge stage.
- `architecture/engineering-loop.md` — consumes prior findings and emits Memory Updates.
- `docs/roadmap.md` — schedules PLAN-0005 and later implementation Plans.
- `policies/ai-pull-request-policy.md` — governs every AI-authored memory change.
- `standards/security/identity-boundary.md` — defines identity and credential boundaries that memory must not collapse.
