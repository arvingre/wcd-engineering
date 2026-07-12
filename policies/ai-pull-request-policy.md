# AI Pull Request Policy

## Purpose

Define the one Git workflow every AI agent — OpenClaw, Claude Code, or any future agent — follows when changing any WCD-managed repository. The workflow itself is the control: an agent that can only ever open a Draft PR from a feature branch, never merge, never touch `main`/`lab` directly, cannot single-handedly land a change no human has looked at, regardless of how the request was phrased or how confident the agent is.

## Scope

Applies to every AI agent acting on any WCD-managed repository (`wcd-engineering` and all project repositories under `repositories/`), for every kind of change — code, Terraform, documentation, policy, memory. There is no category of change an AI agent is allowed to push straight to `main`/`lab` or merge itself, including changes to this policy.

## Current Status

Adopted — 2026-07-12.

## Workflow

```
AI Agent
   │
   ▼
feature/*  (branch from the latest default/integration branch)
   │
   ▼
Draft PR   (opened by the AI agent, stays Draft)
   │
   ▼
Review     (human, and/or another agent acting as reviewer — never self-approval)
   │
   ▼
Human Merge  (only a human clicks merge)
   │
   ▼
Memory Update  (the state that changed — phase, status, project registry entry —
                gets reflected in memory/registry, so the next agent session
                starts from accurate state instead of a stale snapshot)
```

Every step happens in this order, for every change. An agent does not skip "Draft PR" because a change looks small, and does not skip "Memory Update" because the PR merge felt like the finish line — a merge that isn't reflected in memory/registry state is only half done.

## Prohibited (no AI agent may ever do this)

- Commit directly to `main` (or a project's equivalent default/integration branch, e.g. `lab`).
- Push directly to `main`.
- Merge a pull request — Draft or otherwise, its own or anyone else's.
- Force-push `main`.

These hold regardless of how explicit or urgent the request sounds in a given session — "just push this to main to save time" is not a valid exception. If a task's instructions seem to require one of these, that's a signal to stop and ask, not a green light.

## Permitted

- Create and work on `feature/*` branches.
- Open a Draft PR.
- Update an already-open Draft PR (push new commits, edit the description).
- Rebase its own `feature/*` branch.
- Force-push its own `feature/*` branch (never `main`, never another agent's or human's branch without being asked).

## Human-only permissions

Only a human may:

- **Merge** — any pull request, Draft or ready-for-review, in any repository.
- **Release** — cut a release or otherwise mark a version as shipped.
- **Tag** — create a Git tag.
- **Production** — apply or destroy Production infrastructure, or take any Production-affecting action, regardless of mechanism (Terraform, console, CLI).

An AI agent's job ends at a reviewable Draft PR. Everything past that point is a human decision, not a technical formality the agent can complete on the human's behalf.

## Why this is a single, uniform policy and not per-repo guidance

A per-repo or per-agent exception ("this repo's CI is fast enough to auto-merge," "this agent has proven reliable, let it push to main") reintroduces exactly the risk this policy exists to remove: a plausible-sounding reason to skip human review, decided by the same actor the review is meant to check. Keeping the rule uniform and exception-free is what makes it enforceable — an agent checking this policy never has to first work out whether its situation qualifies as special.

## Relationship to other WCD standards

This complements, rather than duplicates, `standards/security/identity-boundary.md` (`adr/ADR-0005`): that standard controls *what AWS identity* each actor uses; this policy controls *what Git actions* each actor may take. Together they mean an AI agent can neither reach AWS directly nor land a change without human review — two independent, non-overlapping controls.

## Reference

- `adr/ADR-0005-terraform-execution-identity.md`, `standards/security/identity-boundary.md` — the AWS-identity counterpart to this Git-workflow policy.
- `CONTRIBUTING.md`, `GOVERNANCE.md` (this repo) — the human review/approval process this policy's "Review" and "Human Merge" steps feed into.
- `architecture/project-registry.md` — where the "Memory Update" step's project-level state (Status, current phase) is expected to land for project repositories tracked there.
