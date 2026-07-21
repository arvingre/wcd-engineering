# wcd-engineering

wcd-engineering is the engineering standards, architecture decisions, organizational knowledge, and AI agent rules repository for the WCD DevOps workspace.

Claude Code is our hands. OpenHands and OpenClaw are optional execution engines. WCD is the brain that owns Goals, Decisions, Organization Memory, and Continuous Work.

See [`VISION.md`](VISION.md) for the full engineering vision — why WCD exists, the four components it owns, the MVP, and the first production workflow.

It is not a business application repository. Source code, Terraform implementation details, and project-specific delivery artifacts belong in the `repositories/` tree.

## Purpose

- Define shared engineering standards for AWS, Kubernetes, Terraform, security, storage, backup, CI, and related platform practices
- Capture architecture decisions, RFCs, ADRs, playbooks, runbooks, policies, and reusable templates
- Hold durable instructions for human reviewers and AI agents that operate in this workspace

## Directory Structure

- `standards/` - organization-level standards and draft policies
- `architecture/` - platform overviews and reference maps, including `architecture/project-registry.md` — the entry point every AI agent (OpenClaw, Claude Code, or otherwise) reads before starting work on any project
- `module-catalog/` - module interface index and ownership notes
- `agents/` - role definitions and operating rules for AI agents
- `prompts/` - reusable review and analysis prompts
- `adr/` - architecture decision records
- `rfc/` - proposed changes and discussion artifacts
- `playbooks/` - step-by-step operational guidance
- `runbooks/` - operational execution guides
- `policies/` - governance and compliance rules
- `templates/` - reusable document templates

## Relationship To `repositories/`

```text
/Users/arvin/Documents/devops
├── wcd-engineering
│   └── standards, architecture, governance, prompts, agents
└── repositories
    ├── infrastructure
    │   └── project repositories and implementation code
    ├── platform
    ├── applications
    └── tools
```

`wcd-engineering` defines what good looks like.
`repositories/` contains the concrete implementation that follows or references those standards.

## Content Boundary

Should go in this repository:

- Shared standards and policies
- Architecture notes and decision records
- Review prompts and AI operating rules
- Ownership, approval, and governance guidance

Should not go in this repository:

- Application source code
- Terraform business logic or provider configuration
- Generated state files, secrets, or environment-specific credentials
- Production deployment artifacts that belong to a project repository

## How To Contribute

1. Propose the change in ADR or RFC form when the change affects shared behavior.
2. Update the relevant standard or governance document only after the change is reviewed and approved.
3. Add evidence, scope, and rollback or exception notes where applicable.
4. Keep examples generic and avoid copying secrets or production-only values.
5. Link to the implementation repository when the standard is backed by a working reference.
