---
name: "OpenSpec Authoring"
description: "Guidance for writing and reviewing OpenSpec-format specification documents."
user-invocable: false
---

# OpenSpec Authoring Skill

> Apply this skill when writing or reviewing any specification document in this repository. All specs must follow the OpenSpec format defined in `.github/instructions/openspec-format.md`.

---

## Quick Reference

This skill provides practical authoring guidance for writing OpenSpec documents. For the full format reference, see `.github/instructions/openspec-format.md`.

---

## Starting a New Spec

### Step 1: Choose the Right Spec Type

| Type | Use For | Location |
|------|---------|----------|
| `business` | Vision, requirements, user stories, actors | `spec/business/` |
| `technical` | Architecture, APIs, data model, infrastructure | `spec/technical/` |
| `validation` | Test strategy, acceptance criteria, SLAs | `spec/validation/` |
| `iteration` | Iteration plan, story specs | `spec/iterations/iteration-N/` |

### Step 2: Assign a Spec ID
- Business specs: `SPEC-001` through `SPEC-009`
- Technical specs: `SPEC-010` through `SPEC-019`
- Validation specs: `SPEC-020` through `SPEC-029`
- Iteration specs: `SPEC-IT-N-XXX` (where N is iteration number)

### Step 3: Copy the Template
Start from the blank template in `.github/instructions/openspec-format.md#full-openspec-template`.

---

## Writing Good User Stories

### The Formula
```
As a [specific actor],
I want [specific, actionable capability],
So that [measurable value or benefit].
```

### Actor Selection
- Always use an actor defined in `spec/business/actors.md` (or `spec/business/frame.md`)
- Never use "user" alone — which user? Be specific.
- If a new actor is needed, add them to the actors spec first.

### Capability Statement
- Use active verbs: "view", "create", "update", "delete", "search", "receive", "configure"
- Be specific enough that a developer knows what to build
- But not so specific that you're dictating implementation

**Too vague:**
> "I want the system to handle payments"

**Too prescriptive:**
> "I want a POST /api/v1/payments endpoint that accepts a Stripe payment intent ID and calls the Stripe API"

**Just right:**
> "I want to pay for my order using a saved credit card"

### Value Statement
- Should be a real user or business benefit
- Avoid circular value statements ("so that I can pay")
- Connect to a real outcome

**Circular (bad):**
> "So that I can use the payment feature"

**Real value (good):**
> "So that I can complete my purchase without needing to re-enter my card details"

---

## Writing Good Acceptance Criteria

### The Given-When-Then Structure

```
Given [a specific starting state or precondition]
When [a specific action is performed]
Then [a specific, observable outcome occurs]
And [additional outcomes if needed]
```

### Precision Checklist

Every Given-When-Then block must pass this checklist:
- [ ] The "Given" state can be set up programmatically (for automated testing)
- [ ] The "When" action is a single, specific action
- [ ] The "Then" outcome is observable and measurable (not "the system works correctly")
- [ ] The "And" clauses are truly additional, not alternatives

### AC Precision Examples

**Vague AC (bad):**
```
Given a registered user
When they log in
Then they should be authenticated
```

**Precise AC (good):**
```
Given a registered user with email "user@example.com" and a valid bcrypt-hashed password
When they submit a POST to /auth/login with {"email":"user@example.com","password":"correct-password"}
Then the system returns HTTP 200 with a response body containing:
  - "access_token": a non-empty JWT string
  - "refresh_token": a non-empty string
  - "token_type": "Bearer"
  - "expires_in": 900
And the access token is a valid JWT signed with RS256 with claims:
  - "sub": the user's ID
  - "email": "user@example.com"
```

### Required Scenarios Per Story

Every story should have ACs covering at minimum:

1. **Happy path** — The primary success scenario
2. **Validation error** — Invalid input is rejected with appropriate error
3. **Authorization** — Unauthorized access is denied (for protected operations)
4. **Not found** — Resource doesn't exist returns appropriate error
5. **Edge cases** — At least one boundary condition

---

## Writing Non-Functional Requirements

### Performance NFRs
Always provide:
- The specific operation
- The measurement (p50, p95, p99 latency; throughput in rps)
- The test scenario (user count, data volume)
- The measurement method

**Example:**
```
The GET /products endpoint must respond within:
- p50 < 50ms
- p95 < 150ms  
- p99 < 300ms
Under sustained load of 500 concurrent users with 10,000 products in the database.
Measured using k6 load test from a client in the same AWS region.
```

### Security NFRs
Reference standards where possible:
- OWASP ASVS level 1, 2, or 3
- OWASP Top 10 specific items
- CWE identifiers for specific vulnerability classes
- NIST guidelines

**Example:**
```
Authentication must comply with OWASP ASVS Level 2, specifically:
- ASVS 2.1.1: All user-controllable inputs validated
- ASVS 2.1.12: Account lockout after 5 failed login attempts
- ASVS 2.10.4: Password storage using bcrypt with cost factor ≥ 12
```

### Availability NFRs
Use standard SLA terminology:
```
The API service must achieve:
- 99.9% monthly uptime (43.8 minutes downtime/month maximum)
- RTO (Recovery Time Objective): < 15 minutes for a service restart
- RPO (Recovery Point Objective): < 5 minutes (database backup frequency)
```

---

## Spec Review Checklist

When reviewing a spec document, check:

### Front Matter
- [ ] `spec_id` follows the convention (SPEC-NNN)
- [ ] `status` is accurate
- [ ] `type` is correct (business/technical/validation)
- [ ] `related_specs` links are accurate
- [ ] `related_stories` links are accurate

### Overview
- [ ] Purpose is clear in 1-2 sentences
- [ ] Scope is bounded (in AND out)
- [ ] Background provides necessary context without bloat

### Actors
- [ ] Only actors from the Frame document are referenced
- [ ] Each actor has clear goals and constraints
- [ ] No conflicting actor goals are left unresolved

### User Stories
- [ ] All stories follow As a/I want/So that format
- [ ] Story points are estimated
- [ ] Priority is assigned
- [ ] Agent role is assigned
- [ ] Dependencies are listed

### Acceptance Criteria
- [ ] At least 2 scenarios per story
- [ ] Happy path covered
- [ ] Error cases covered
- [ ] All scenarios are specific and testable
- [ ] No vague outcomes ("correctly", "properly", "successfully" without measurable definition)

### NFRs
- [ ] Performance targets are quantified (not "fast" but "p95 < 200ms")
- [ ] Security requirements reference standards
- [ ] Availability targets are in measurable SLA format

### Open Questions
- [ ] All open questions have owners
- [ ] All open questions have due dates
- [ ] No open questions exist in "approved" specs (resolve or remove before approving)

---

## Maintaining Spec Traceability

Every spec element should be traceable:

```
Actor Goal (frame.md)
    ↓
Business Requirement (requirements.md)
    ↓
User Story (user-stories.md / backlog.md)
    ↓
Acceptance Criterion (acceptance-criteria.md)
    ↓
Test Case (in code or validation spec)
    ↓
Implementation (in solutions/<project-name>/)
```

When reviewing specs during the Edit phase, verify this chain exists for every delivered story.

---

## Spec Lifecycle Management

### When to Update a Spec
- New information makes a section inaccurate → Update and bump version
- A change request is approved → Update with change record
- Implementation reveals spec was ambiguous → Update to remove ambiguity
- Post-release retrospective identifies improvements → Update and plan next iteration

### Version Bumping
- Patch (0.0.x): Typo fixes, clarifications that don't change meaning
- Minor (0.x.0): New sections, additional requirements, new stories added
- Major (x.0.0): Fundamental change to scope or approach

### Deprecating a Spec
When a spec is superseded:
1. Change status to `deprecated`
2. Add a note: "Superseded by SPEC-XXX — [reason]"
3. Update the successor spec to reference the deprecated spec for historical context
