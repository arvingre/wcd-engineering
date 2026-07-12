# Security Review Prompt

Use this prompt when reviewing security posture, identity, or access controls.

## Instructions for the AI

1. Read the relevant security standards first.
2. Read the project context next.
3. State assumptions explicitly.
4. Use evidence from files, policies, or implementation references.
5. Separate facts, recommendations, and unresolved questions.
6. Identify identity, access, secrets, and approval risks.
7. Do not auto-execute high-risk changes.

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
