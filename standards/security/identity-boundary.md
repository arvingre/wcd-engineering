# Identity Boundary Standard

## Purpose

Define which identity each actor in the WCD engineering pipeline uses to reach AWS — if any — and enforce that no two distinct actors ever share a credential or IAM role. The goal is that a bug, prompt-injection, or compromise scoped to one actor cannot silently reach further into AWS than that actor is supposed to be able to.

## Scope

Applies to every actor that can influence Terraform-managed AWS infrastructure across WCD project repositories: OpenClaw, Claude Code, GitHub Actions, HCP Terraform, and AWS itself as the resulting infrastructure. See `adr/ADR-0005-terraform-execution-identity.md` for the decision record and open questions.

## Current Status

Proposed — 2026-07-12 (ADR-0005). This PR is still Draft; status moves to Adopted on merge, not before.

## Identity map

| Actor | Responsibility | Default AWS credential | Identity mechanism |
|---|---|---|---|
| OpenClaw | Planning, memory, review | None | N/A — never authenticates to AWS directly |
| Claude Code | Implementation (writing Terraform, opening PRs) | None | N/A — never authenticates to AWS directly |
| GitHub Actions | CI only, unless explicitly approved otherwise | None by default | GitHub OIDC → federated AWS IAM role, only for the specific, explicitly-approved case that needs it |
| HCP Terraform | Terraform Plan / Apply / State | Yes — the only actor expected to hold apply-level AWS permissions | HCP Terraform OIDC → federated AWS IAM role |
| AWS | The resulting infrastructure | N/A | N/A — terminal system, not an actor with its own identity to manage |

## Rules

1. **OpenClaw and Claude Code hold no AWS credentials by default.** Neither is expected to call the AWS API directly under normal operation. A specific, human-authorized session using local AWS CLI credentials for read-only inspection is a deliberate, scoped exception — not the default posture — and must never reuse a standing IAM user/role shared with any automated pipeline identity.
2. **GitHub Actions is CI only, unless explicitly approved otherwise.** Its default job is running `fmt`/`validate`/lint/security-scan checks with no AWS credentials at all (`-backend=false`, no AWS calls). It never plans, applies, or touches Terraform state — that is HCP Terraform's responsibility, not GitHub Actions', and the two are not interchangeable. If a specific workflow is explicitly approved to need AWS access for some CI purpose, it authenticates via **GitHub OIDC**, never long-lived `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`. (This generalizes, as an org-wide standard, a decision already tracked per-project — see `devops-terraform-jenkins-eks` ADR-0003.)
3. **HCP Terraform is responsible for Terraform Plan, Apply, and State — exclusively.** No other actor in this pipeline plans or applies Terraform. It authenticates via **HCP Terraform OIDC** (dynamic provider credentials), not a static AWS access key pasted into workspace variables.
4. **GitHub OIDC and HCP Terraform OIDC are distinct identities and must never be collapsed into one.** Each gets its own AWS IAM role, trust policy, and permission boundary, matching the non-overlapping responsibilities above: GitHub Actions' role (when one exists at all) is scoped to a specific CI need, never to plan/apply/state; HCP Terraform's role is scoped to plan/apply/state. Neither role is ever `AdministratorAccess`, and neither role's trust policy accepts both OIDC providers.
5. **AWS is the terminal system**, not an actor with its own identity to manage under this standard — every rule above exists to control what is allowed to reach it, not the reverse.

## Why this boundary exists

- If OpenClaw or Claude Code held standing AWS credentials, a planning mistake or prompt-injection could reach real infrastructure without ever passing through the review/CI/HCP-Terraform-plan gate that's supposed to sit in front of every change. Keeping them credential-less makes "an AI agent ran apply on its own" structurally impossible, not merely policy-forbidden.
- If GitHub Actions and HCP Terraform shared one IAM role, a CI-side compromise (a malicious PR from a fork, a supply-chain issue in a third-party Action) would inherit apply-level AWS permissions meant only for the plan/apply pipeline — not for arbitrary jobs that just run `fmt`/`lint`.

## Reference

- `adr/ADR-0005-terraform-execution-identity.md` — the decision record and open questions. Status here tracks that ADR's status.
- Reference implementation: `devops-terraform-jenkins-eks` — `docs/decisions/ADR-0002-terraform-state.md` (state backend, including the HCP Terraform Cloud option) and `docs/decisions/ADR-0003-github-oidc.md` (GitHub → AWS via OIDC). This standard generalizes what those per-project ADRs already established into an org-wide rule that other project repos are expected to follow too.
