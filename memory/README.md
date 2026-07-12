# WCD Engineering Memory

This directory stores durable, structured organizational knowledge for the WCD Engineering OS. Its governing architecture is `architecture/engineering-memory.md`.

Memory records are summaries and indexes backed by authoritative evidence. GitHub, project repositories, adopted ADRs, CI reports, incident systems, and approved human decisions remain the source of truth.

## What belongs here

- verified engineering Decisions
- resolved or actively managed Incidents
- validated Runbooks
- evidence-backed Lessons
- recurring validated Patterns
- compact current Project State records

## What does not belong here

- Terraform state files
- secrets, tokens, credentials, passwords, or private keys
- full source-code copies
- raw CI logs or unrestricted production logs
- temporary task output or speculative hypotheses
- copied private chat transcripts
- unreviewed model output

## Directory contract

```text
memory/
  organization/
    decisions/
    lessons/
    patterns/
    runbooks/
  projects/
    <project-name>/
      state.md
      decisions/
      incidents/
      lessons/
      patterns/
      runbooks/
  archive/
```

Each durable record is stored in its own file and follows the record types, lifecycle, provenance, promotion, retrieval, staleness, and security rules in `architecture/engineering-memory.md`.

Subdirectories are introduced when a real record is created; empty placeholder trees are not required.

## Write policy

All AI-authored memory changes use a feature branch and Draft PR. No AI agent writes directly to `main`, merges its own memory changes, invents an approval, or promotes an unverified claim into Active memory.
