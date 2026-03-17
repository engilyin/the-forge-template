# OpenSpec Format Guide

> OpenSpec is a structured, AI-readable specification format designed for use with AI-assisted development workflows.
> All specifications in this repository use the OpenSpec format.
> Reference: [openspec.dev](https://openspec.dev)

---

## What Is OpenSpec?

OpenSpec is a convention for writing software specifications in a format that is:

1. **Human-readable** — Clear enough for developers, product managers, and stakeholders to understand without translation
2. **AI-parseable** — Structured enough for AI agents to extract precise requirements without ambiguity
3. **Traceable** — Every requirement can be linked to a user story, to code, and to a test
4. **Version-controllable** — Plain markdown that lives in git alongside the code it specifies

OpenSpec is not a proprietary tool — it is a formatting convention. It uses YAML front matter for metadata and structured markdown sections for content.

---

## OpenSpec Document Structure

Every OpenSpec document consists of:

1. **YAML Front Matter** — Metadata block at the top of the file
2. **Overview Section** — Human-readable summary of what this spec covers
3. **Actors Section** — Who interacts with the system described in this spec
4. **User Stories Section** — The "As a... I want... So that..." requirements
5. **Acceptance Criteria Section** — Specific, testable conditions that define "done"
6. **Non-Functional Requirements Section** — Performance, security, reliability, scalability
7. **Constraints Section** — Hard limits and non-negotiables
8. **Open Questions Section** — Unresolved items that need answers before implementation

---

## YAML Front Matter Reference

```yaml
---
spec_id: SPEC-001
title: "User Authentication System"
version: "1.0.0"
status: draft | review | approved | implemented | deprecated
type: business | technical | validation | iteration
created: 2024-01-15
updated: 2024-01-20
authors:
  - Business Analyst Agent
  - Solution Architect Agent
reviewers:
  - Tech Lead Agent
  - Security Engineer
related_specs:
  - SPEC-002
  - SPEC-003
related_stories:
  - STORY-001
  - STORY-002
tags:
  - authentication
  - security
  - backend
---
```

### Field Definitions

| Field | Required | Description |
|-------|----------|-------------|
| `spec_id` | Yes | Unique identifier. Format: `SPEC-NNN` |
| `title` | Yes | Short, descriptive title |
| `version` | Yes | Semantic version of this spec document |
| `status` | Yes | Current lifecycle status |
| `type` | Yes | Category of specification |
| `created` | Yes | Date first created (ISO 8601) |
| `updated` | Yes | Date last modified (ISO 8601) |
| `authors` | Yes | Who wrote this spec |
| `reviewers` | No | Who reviewed/approved this spec |
| `related_specs` | No | IDs of related/dependent specs |
| `related_stories` | No | IDs of user stories covered by this spec |
| `tags` | No | Searchable keywords |

---

## Section: Overview

```markdown
## Overview

### Purpose
[1-3 sentences: what does this specification define and why does it exist?]

### Scope
[What is included in this spec? What is explicitly excluded?]

### Background
[Any context needed to understand the spec — business drivers, technical constraints, prior decisions]

### Dependencies
[Other systems, services, or specs this spec depends upon]
```

---

## Section: Actors

```markdown
## Actors

### [Actor Name]
- **Type:** Human | System | External Service
- **Description:** [Brief description of who/what this actor is]
- **Primary Goals:** [What does this actor want to achieve?]
- **Permissions:** [What can this actor do in the system?]
- **Constraints:** [Any limits on this actor's behavior]

### Example

### Registered User
- **Type:** Human
- **Description:** A user who has created an account in the system
- **Primary Goals:** Access personalized features, manage their profile, complete purchases
- **Permissions:** Read own profile, create orders, view order history, manage addresses
- **Constraints:** Cannot access other users' data; cannot modify system configuration
```

---

## Section: User Stories

```markdown
## User Stories

### [STORY-ID]: [Story Title]

**As a** [actor],
**I want** [capability or feature],
**So that** [business value or user benefit].

**Story Points:** [1 | 2 | 3 | 5 | 8 | 13]
**Priority:** [must-have | should-have | nice-to-have]
**Dependencies:** [STORY-IDs this story depends on, or "none"]
**Assigned Agent:** [agent role name]

#### Preconditions
- [Condition that must be true before this story can be executed]

#### Postconditions
- [State of the system after this story is successfully completed]

#### Notes
- [Any additional context, design hints, or constraints]
```

### User Story Example

```markdown
### STORY-001: User Login with Email and Password

**As a** registered user,
**I want** to log in with my email address and password,
**So that** I can access my account and personalized features.

**Story Points:** 3
**Priority:** must-have
**Dependencies:** none
**Assigned Agent:** java-backend-developer

#### Preconditions
- User has a registered account
- User's email is verified

#### Postconditions
- User receives a JWT access token (15 min expiry) and refresh token (7 day expiry)
- Login event is logged in audit trail
- Failed login attempts are tracked (lockout after 5 attempts)

#### Notes
- Passwords must be stored as bcrypt hashes (cost factor ≥ 12)
- JWT must include: user ID, email, roles, issued-at, expiry
- Refresh token rotation must be implemented
```

---

## Section: Acceptance Criteria

```markdown
## Acceptance Criteria

### [STORY-ID]: [Story Title]

**Given** [initial context / precondition],
**When** [action taken],
**Then** [expected outcome].

Use one Given-When-Then block per test scenario.

#### Example

### STORY-001: User Login with Email and Password

**Scenario 1: Successful Login**
- **Given** a registered user with email "user@example.com" and a valid password
- **When** the user submits the login form with correct credentials
- **Then** the system returns HTTP 200 with a JSON body containing `access_token` and `refresh_token`
- **And** the access token is a valid JWT signed with RS256
- **And** the access token expires in 900 seconds
- **And** a LOGIN_SUCCESS event is written to the audit log

**Scenario 2: Invalid Password**
- **Given** a registered user with email "user@example.com"
- **When** the user submits the login form with an incorrect password
- **Then** the system returns HTTP 401 with error code `INVALID_CREDENTIALS`
- **And** a LOGIN_FAILURE event is written to the audit log
- **And** the failed attempt counter is incremented

**Scenario 3: Account Lockout**
- **Given** a registered user who has had 4 previous failed login attempts
- **When** the user submits the login form with an incorrect password
- **Then** the system returns HTTP 423 with error code `ACCOUNT_LOCKED`
- **And** a ACCOUNT_LOCKED event is written to the audit log
- **And** a lockout notification email is sent to the user
```

---

## Section: Non-Functional Requirements

```markdown
## Non-Functional Requirements

### Performance
| Requirement | Target | Measurement Method |
|------------|--------|-------------------|
| [requirement] | [specific measurable target] | [how to measure] |

### Security
| Requirement | Standard / Reference |
|------------|---------------------|
| [requirement] | [OWASP / CWE / internal standard] |

### Reliability
| Requirement | Target |
|------------|--------|
| Availability | [e.g., 99.9% monthly uptime] |
| RTO (Recovery Time Objective) | [e.g., < 1 hour] |
| RPO (Recovery Point Objective) | [e.g., < 5 minutes] |

### Scalability
- [Describe expected load and growth projections]
- [Horizontal vs. vertical scaling strategy]
- [State or stateless design requirement]

### Observability
- [Logging requirements (format, level, retention)]
- [Metrics requirements (what to measure, alerting thresholds)]
- [Tracing requirements (distributed tracing, correlation IDs)]

### Example NFRs

### Performance
| Requirement | Target | Measurement Method |
|------------|--------|-------------------|
| Login API p95 latency | < 200ms | Load test with 1000 concurrent users |
| Login API throughput | > 500 rps | Load test with JMeter |

### Security
| Requirement | Standard / Reference |
|------------|---------------------|
| Passwords stored as bcrypt hash | OWASP Password Storage Cheat Sheet |
| JWT signed with RS256 | RFC 7519 |
| No secrets in source code | OWASP ASVS 2.10 |
| Input validation on all endpoints | OWASP ASVS 5.1 |
```

---

## Section: Constraints

```markdown
## Constraints

### Technical Constraints
- [Hard technical limits: language, framework, platform requirements]

### Business Constraints
- [Timeline, budget, regulatory, compliance requirements]

### Operational Constraints
- [Deployment environment restrictions, on-call requirements, SLA obligations]
```

---

## Section: Open Questions

```markdown
## Open Questions

Track unresolved questions that need answers before or during implementation.

| ID | Question | Owner | Due Date | Status |
|----|---------|-------|----------|--------|
| OQ-001 | [question] | [who must answer] | [date] | open / answered |

When a question is answered, update status to "answered" and add the answer:

**OQ-001 Answer:** [the answer, including who provided it and when]
```

---

## Full OpenSpec Template

Use this as the starting point for any new spec document:

```markdown
---
spec_id: SPEC-XXX
title: ""
version: "0.1.0"
status: draft
type: business
created: YYYY-MM-DD
updated: YYYY-MM-DD
authors:
  - Business Analyst Agent
reviewers: []
related_specs: []
related_stories: []
tags: []
---

## Overview

### Purpose

### Scope

### Background

### Dependencies

---

## Actors

---

## User Stories

---

## Acceptance Criteria

---

## Non-Functional Requirements

### Performance

### Security

### Reliability

### Scalability

---

## Constraints

---

## Open Questions
```

---

## Spec Status Lifecycle

```
draft ──► review ──► approved ──► implemented
  ▲           │                        │
  └───────────┘ (revisions)            ▼
                                  deprecated
```

- **draft** — Being written, not yet ready for review
- **review** — Under review by stakeholders/tech lead
- **approved** — Approved and locked for implementation
- **implemented** — All stories in this spec are delivered
- **deprecated** — Superseded by a newer spec or descoped

---

## Spec Folder Organization

```
spec/
  business/
    frame.md                    ← SPEC-001: Project frame document
    actors.md                   ← SPEC-002: Actor definitions
    user-stories.md             ← SPEC-003: Full user story backlog
    obstruct-report.md          ← SPEC-004: Risks, gaps, assumptions
    non-functional-requirements.md ← SPEC-005: NFRs

  technical/
    architecture.md             ← SPEC-010: System architecture
    api-contracts.md            ← SPEC-011: API interface definitions
    data-model.md               ← SPEC-012: Data entities and relationships
    infrastructure.md           ← SPEC-013: Cloud/IaC design
    security.md                 ← SPEC-014: Security requirements and design
    deployment.md               ← SPEC-015: Deployment strategy

  validation/
    acceptance-criteria.md      ← SPEC-020: Per-story acceptance criteria
    test-strategy.md            ← SPEC-021: Test approach by layer
    performance-targets.md      ← SPEC-022: SLA and performance targets

  iterations/
    iteration-1/
      plan.md                   ← Iteration plan
      stories/
        STORY-001.md            ← Individual story spec
      status.md                 ← Live execution status
      report.md                 ← Post-iteration report
```
