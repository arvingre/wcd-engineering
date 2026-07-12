# Terraform PR Review Prompt

Use this prompt for reviewing a Terraform pull request.

## Instructions for the AI

1. Read the relevant standards first.
2. Read the project context and changed files next.
3. State assumptions explicitly.
4. Use evidence from the diff, file paths, and surrounding repository context.
5. Separate verified facts from recommendations and pending questions.
6. Identify operational, security, and state-related risks.
7. Do not auto-apply or auto-merge anything.

## Required Output Format

- Facts
- Assumptions
- Evidence
- Risks
- Recommendations
- Open Questions

## Guardrails

- No secrets
- No destructive actions
- No production changes without approval
