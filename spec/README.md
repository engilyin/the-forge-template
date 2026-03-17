# Specification Folder — Structure & Guide

This folder contains all project specifications in **OpenSpec format**. Specifications are the source of truth for what gets built — all code in `solution/` must trace back to a spec here.

---

## Folder Structure

```
spec/
├── business/           ← Business requirements, user stories, backlog
├── technical/          ← Architecture, APIs, data model, infrastructure  
├── validation/         ← Test strategy, acceptance criteria, QA reports
├── iterations/         ← Per-iteration plans, story specs, and reports
│   └── iteration-N/
│       ├── plan.md         ← Iteration goal, selected stories, config
│       ├── stories/        ← Individual story specs
│       │   └── STORY-XXX.md
│       ├── status.md       ← Live execution status (updated during Dark Factory)
│       └── report.md       ← Post-iteration assessment report
└── README.md           ← This file
```

---

## Business Specs (`spec/business/`)

| File | Spec ID | Description | FORGE Phase |
|------|---------|-------------|-------------|
| `frame.md` | SPEC-001 | Project frame: vision, scope, actors, epics | Frame |
| `actors.md` | SPEC-002 | Actor definitions and goals | Frame |
| `discovery-notes.md` | SPEC-002b | Raw discovery session notes | Frame |
| `obstruct-report.md` | SPEC-004 | Risks, gaps, assumptions, blockers | Obstruct |
| `requirements.md` | SPEC-005 | Finalized functional requirements | Reconstruct |
| `user-stories.md` | SPEC-006 | Full user story set | Reconstruct |
| `backlog.md` | SPEC-007 | Groomed, prioritized backlog | Backlog Grooming |
| `non-functional-requirements.md` | SPEC-008 | Performance, security, reliability NFRs | Reconstruct |

---

## Technical Specs (`spec/technical/`)

| File | Spec ID | Description | FORGE Phase |
|------|---------|-------------|-------------|
| `architecture.md` | SPEC-010 | System architecture + ADRs | Reconstruct |
| `api-contracts.md` | SPEC-011 | API endpoint definitions | Reconstruct |
| `data-model.md` | SPEC-012 | Entity definitions and relationships | Reconstruct |
| `infrastructure.md` | SPEC-013 | AWS/IaC design | Reconstruct |
| `security.md` | SPEC-014 | Security architecture and requirements | Reconstruct |
| `deployment.md` | SPEC-015 | CI/CD and deployment strategy | Reconstruct |
| `technical-spikes.md` | SPEC-016 | Technical investigations needed | Obstruct |
| `openapi.yaml` | — | Generated OpenAPI spec (from code) | Generate |

---

## Validation Specs (`spec/validation/`)

| File | Spec ID | Description | FORGE Phase |
|------|---------|-------------|-------------|
| `acceptance-criteria.md` | SPEC-020 | Per-story Given/When/Then criteria | Reconstruct |
| `test-strategy.md` | SPEC-021 | Test approach by layer | Reconstruct |
| `performance-targets.md` | SPEC-022 | SLA definitions and load test targets | Reconstruct |

---

## OpenSpec Format Quick Reference

All specification files use YAML front matter + structured markdown sections:

```yaml
---
spec_id: SPEC-NNN
title: "[Descriptive Title]"
version: "0.1.0"
status: draft | review | approved | implemented | deprecated
type: business | technical | validation
created: YYYY-MM-DD
updated: YYYY-MM-DD
authors:
  - [Agent Role or Human Name]
---
```

**Required Sections** (varies by type):
- `## Overview` — Purpose, scope, background
- `## Actors` (business specs) — Who interacts with the system
- `## User Stories` (business specs) — As a/I want/So that format
- `## Acceptance Criteria` — Given/When/Then scenarios
- `## Non-Functional Requirements` — Performance, security, reliability
- `## Constraints` — Hard limits
- `## Open Questions` — Unresolved items with owners

For the full format reference: `.github/instructions/openspec-format.md`
For authoring guidance: `.github/skills/openspec-authoring.md`

---

## Spec Status Lifecycle

```
draft ──► review ──► approved ──► implemented ──► deprecated
```

- **draft:** Being authored. Not yet ready for review.
- **review:** Ready for stakeholder review. May still change.
- **approved:** Locked for implementation. Changes require formal change request.
- **implemented:** All stories derived from this spec are delivered.
- **deprecated:** Superseded or descoped. Do not use for new work.

---

## Traceability Chain

Every deliverable in `solution/` must trace back through this chain:

```
spec/business/frame.md (actor goals)
    ↓
spec/business/requirements.md (functional requirements)
    ↓
spec/business/backlog.md (user stories)
    ↓
spec/validation/acceptance-criteria.md (acceptance criteria)
    ↓
spec/iterations/iteration-N/stories/STORY-XXX.md (iteration story spec)
    ↓
solution/ (implementation code + tests)
```

If code exists in `solution/` with no corresponding spec entry, it was built without a spec — this is a process violation and should be addressed in the next iteration.

---

## Creating New Spec Documents

1. Copy the template from `.github/instructions/openspec-format.md`
2. Assign the next available `spec_id` in the appropriate range
3. Set status to `draft`
4. Fill in all required sections
5. Change status to `review` when ready for stakeholder review
6. Get approval from the relevant agent roles
7. Change status to `approved` before work begins

---

## Searching Specs

To find all specs related to a topic:
```bash
grep -r "authentication" spec/ -l
grep -r "STORY-001" spec/ -l
grep -r "spec_id: SPEC-01" spec/ 
```
