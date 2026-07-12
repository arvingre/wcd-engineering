# Contributing

## Change Types

- **ADR**: use for architecture decisions with lasting impact
- **RFC**: use for proposed changes that need discussion before adoption
- **Standard update**: use for edits to existing engineering standards

## Flow

1. Capture the problem statement and scope.
2. Document the proposed change in ADR or RFC form if the change affects shared behavior.
3. Identify affected standards, repositories, and teams.
4. Review for security, operational risk, and implementation fit.
5. Approve before updating the standard or related guidance.

## Pull Request Requirements

- Clear summary of what changed and why
- Evidence or references for the change
- Explicit assumptions and open questions
- Review notes for security and operational impact
- No secrets, state files, or environment-specific credentials

## Standard Change Approval

- Small editorial fixes may be approved by the repository maintainer
- Behavior-changing updates require peer review
- Security, storage, backup, and platform changes require the appropriate domain reviewer
- Changes that affect production practices require documented approval before adoption
