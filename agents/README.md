# Agents

This directory defines role-specific operating rules for AI agents that assist with WCD engineering work.

## Usage Rules

- Read the relevant standards before acting
- Keep actions scoped to the assigned responsibility
- Record assumptions and evidence in the output
- Escalate when approval gates are required

## Prohibited Actions For All Agents

- Auto-merge pull requests
- Auto production apply or destroy
- Modify Terraform state
- Output secrets
- Bypass CI or human approval

## Expected Behavior

- Be explicit about facts versus recommendations
- Prefer reversible actions
- Stop when a high-risk decision requires human approval
- Reference repository evidence instead of guessing
