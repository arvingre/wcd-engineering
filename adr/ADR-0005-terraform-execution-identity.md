# ADR-0005: Terraform Execution Identity

**Status:** Proposed — 2026-07-12. This PR is still Draft; status moves to Adopted on merge, not before.

## Context

WCD's engineering pipeline involves five distinct actors that could, in principle, touch AWS: OpenClaw (planning/memory/review orchestrator), Claude Code (implementation), GitHub Actions (CI), HCP Terraform (plan/apply/state), and AWS itself as the target. Without an explicit boundary, an implementation shortcut — exporting AWS keys into a CI environment for convenience, giving an agent workstation a standing IAM role "just in case" — can quietly collapse several of these into one shared identity, which defeats the point of having distinct actors with distinct responsibilities in the first place.

This generalizes, as an org-wide standard, the per-project decisions already made in `devops-terraform-jenkins-eks`: ADR-0002 (Terraform state backend, including the HCP Terraform Cloud workspace option) and ADR-0003 (GitHub → AWS via OIDC, not static keys).

## Decision

1. **OpenClaw** — responsible for planning, memory, and review. No AWS credentials by default.
2. **Claude Code** — responsible for implementation (writing Terraform, opening PRs). No AWS credentials by default.
3. **GitHub Actions** — responsible for CI **only, unless explicitly approved otherwise**. By default this means credential-free `fmt`/`validate`/lint/security-scan checks — no Terraform plan, no apply, no state access, ever, under the default posture. If a specific workflow is explicitly approved to need AWS access for some CI purpose, it authenticates via **GitHub OIDC** federated to a scoped IAM role — scoped to that CI purpose, not to plan/apply/state.
4. **HCP Terraform** — responsible for Terraform Plan, Apply, and State, **exclusively**. No other actor in this pipeline plans or applies Terraform. Authenticates to AWS via **HCP Terraform OIDC** (dynamic provider credentials) federated to a scoped IAM role. This is the only actor in the pipeline expected to hold AWS permissions broad enough to actually change infrastructure.
5. **AWS** — the resulting infrastructure state. Not an actor with its own credentials to manage under this ADR; every rule above exists to control what's allowed to reach it.
6. **GitHub OIDC and HCP Terraform OIDC are explicitly two different identities.** They must never share a single AWS IAM role — no common "Administrator Role", no trust policy that accepts both OIDC providers on one role. Each gets its own role, matching the non-overlapping responsibilities in points 3 and 4: GitHub Actions' role is never scoped to plan/apply/state, and HCP Terraform's role is never scoped to arbitrary CI tasks.

See `standards/security/identity-boundary.md` for the full standing rule set this ADR establishes — this ADR is the decision record; that document is the enforceable standard.

## Consequences

- Every project repo's own OIDC/backend ADR (e.g. `devops-terraform-jenkins-eks` ADR-0002/ADR-0003) should treat this ADR as the org-wide baseline it implements, not an independent, competing decision.
- **This ADR creates no AWS resources.** It establishes the boundary; the actual IAM roles, trust policies, and permission boundaries are implemented per project (e.g. `devops-terraform-jenkins-eks`'s `bootstrap/github-oidc/`) and reviewed against this standard.
- Any future proposal to grant OpenClaw or Claude Code standing AWS credentials, or to let GitHub Actions and HCP Terraform share a role, is a deviation from this ADR and requires its own superseding ADR — not a quiet exception.

## Open questions

- Exact IAM role names and permission boundaries per actor are left to each project's own bootstrap work. `devops-terraform-jenkins-eks` ADR-0003 already names `WCDTerraformLabRole`/`WCDTerraformProdPlanRole`/`WCDTerraformProdApplyRole` as a starting point for the HCP-Terraform-side identity in that repo — this ADR does not itself create or name any AWS resource.
- Whether any GitHub Actions workflow actually ends up needing an AWS role at all is still open per-project (default is no — CI-only, credential-free `fmt`/`validate`/lint/security-scan). `devops-terraform-jenkins-eks` ADR-0003 flags this as unresolved for that repo specifically; it's inherited here as an open question at the org level too. Whatever the answer, Terraform plan/apply/state stays exclusively on the HCP Terraform side — that part is decided, not open.
- Whether Jenkins (where it still exists, e.g. `devops-terraform-jenkins-eks`'s `part1-jenkins-from-terraform`) fits this same OIDC model or needs a different mechanism (e.g. an EC2 instance profile) is out of scope for this ADR and tracked separately per-project.

## References

- `devops-terraform-jenkins-eks`: `docs/decisions/ADR-0002-terraform-state.md`, `docs/decisions/ADR-0003-github-oidc.md`
- `standards/security/identity-boundary.md` (this repo)
