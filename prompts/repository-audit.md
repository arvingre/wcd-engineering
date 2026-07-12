# Repository Audit Prompt

Use this prompt for a repository review or audit.

## Instructions for the AI

1. Read the relevant standards first.
2. Read the project context and repository layout next.
3. State assumptions explicitly.
4. Gather evidence from file paths, commands, or document references.
5. Separate facts, recommendations, and items that still need confirmation.
6. Identify risks and note any missing information.
7. Do not execute high-risk operations automatically.

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
