# WCD Engineering Memory

This directory stores long-term stable knowledge for the WCD Engineering OS.

## What belongs here

- Engineering standards and principles (distilled, not raw)
- Architecture decisions (ADRs)
- Project state summaries (phase, branch, path)
- Organization-level rules and approval boundaries
- Bootstrap and recovery references

## What does NOT belong here

- Terraform state files
- Secrets, tokens, credentials, or passwords
- Full project source code or complete Terraform modules
- CI logs or build artifacts
- Temporary task output or draft documents
- Unreviewed incident data

## Source of truth

GitHub and the project repositories remain the source of truth for:
- Current code
- Active Pull Requests
- CI results
- Branch state
- Terraform module implementation

Memory records here are pointers and summaries — always verify against live sources before acting.

## Directory structure

```
memory/
├── engineering/    # Standards, principles, cross-project engineering rules
├── projects/       # Per-project state: paths, branches, phase, restrictions
├── decisions/      # Architecture Decision Records (distilled)
├── organizations/  # Org-level rules, team structure, approval chains
└── bootstrap/      # Machine recovery and environment setup references
```
