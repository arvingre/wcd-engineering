# EKS Capacity Review Prompt

Use this prompt when reviewing EKS capacity or scaling assumptions.

## Instructions for the AI

1. Read the EKS standard first.
2. Read the implementation repository context next.
3. State assumptions explicitly.
4. Use evidence from node group design, capacity plans, scheduling guidance, or cluster docs.
5. Separate facts, recommendations, and open questions.
6. Identify capacity, scheduling, cost, and resilience risks.
7. Do not automatically change infrastructure.

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
