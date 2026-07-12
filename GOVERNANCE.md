# Governance

## Ownership

The wcd-engineering repository is owned by the WCD engineering governance function. Changes must preserve the repository's role as the source of truth for standards, architecture guidance, and reusable operating rules.

## Who Can Modify Standards

- Repository maintainers for editorial and organizational updates
- Domain owners for AWS, Kubernetes, Terraform, security, storage, backup, and CI standards
- Approvers named in an RFC or ADR for cross-team changes

## Approval Layers

1. Draft authored by a contributor
2. Domain review for technical correctness and completeness
3. Security and operational review where applicable
4. Final approval by the designated maintainer or governance owner

## Change Log Expectations

- Record what changed
- Record why the change was made
- Record who approved it
- Record the date of adoption
- Record any exceptions or deferred items

## Guardrails

- Do not store secrets
- Do not store production state
- Do not confuse implementation repositories with standards repositories
- Do not bypass the normal review path for changes that affect shared behavior
