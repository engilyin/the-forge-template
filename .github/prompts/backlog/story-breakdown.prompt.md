---
mode: agent
description: "Break down requirements from spec/business/ into well-formed user stories with acceptance criteria, actor assignments, and priority."
tools:
  - read_file
  - create_file
  - insert_edit_into_file
  - semantic_search
  - file_search
---

# Backlog: Story Breakdown

You are acting as a **Business Analyst** supported by a **Scrum Master** and **Tech Lead**. Your goal is to decompose the epics and requirements from the specification documents into a well-structured, prioritized backlog of user stories.

## Your Objective

Produce `spec/business/backlog.md` containing a complete set of user stories that:
- Cover all must-have requirements in `spec/business/requirements.md`
- Are written in standard user story format with clear acceptance criteria
- Are properly prioritized and sized
- Are assigned to agent roles
- Include dependencies between stories

## Prerequisites
Read these files before starting:
- `spec/business/frame.md` — epics list and actor definitions
- `spec/business/requirements.md` — functional requirements
- `spec/business/non-functional-requirements.md` — NFRs (for technical stories)
- `spec/technical/api-contracts.md` — API definitions (to inform backend stories)
- `spec/technical/data-model.md` — data model (to inform backend stories)

If `spec/business/requirements.md` doesn't exist, check `spec/business/frame.md` for the initial epic list.

## Step-by-Step Process

### Step 1: Extract and Organize Epics
List all epics from the Frame document. Confirm with the user:
> "I've identified [N] epics: [list]. Are there any additional epics or should any be adjusted before I break them into stories?"

### Step 2: Story Decomposition Rules

Apply these rules when breaking epics into stories:

**Story Format (mandatory):**
```
As a [actor from spec/business/frame.md],
I want [specific capability],
So that [business value or user benefit].
```

**Story Size Rules:**
- Each story should be completable in 1-5 days by one agent
- Maximum size: 8 story points (split larger stories)
- Minimum size: 1 story point (combine smaller items if <1 hour each)
- Infrastructure/DevOps stories are typically 2-5 points
- UI stories for a single screen are typically 2-3 points
- API endpoint implementation is typically 2-3 points per endpoint group

**Story Types to Include:**
1. **Feature stories** — Functional capabilities for users
2. **Technical stories** — Infrastructure setup, CI/CD, database migrations
3. **Security stories** — Auth/authz implementation, security hardening
4. **NFR stories** — Performance optimization, observability setup
5. **Spike stories** — Research/investigation tasks (from Obstruct report)

**Story Splitting Patterns (use when a story is too big):**
- Split by user role (admin flow vs. user flow)
- Split by operation type (create vs. read vs. update vs. delete)
- Split by happy path vs. error paths
- Split by platform (web vs. mobile)
- Split by integration (standalone functionality vs. integration with external system)

### Step 3: Write Stories Systematically

For each epic, produce 3-8 stories. Cover:
1. The core happy-path functionality
2. Error and edge case handling
3. Security requirements for that area
4. NFRs relevant to that area (if significant enough to be a story)

### Step 4: Write Acceptance Criteria

For every story, write 2-5 Given/When/Then scenarios:

**Must include:**
- The primary success scenario (happy path)
- At least one failure/error scenario
- Boundary conditions (if applicable)
- Security scenario (if story involves data access or modification)

**Format:**
```
**Scenario N: [Scenario Name]**
- **Given** [precondition]
- **When** [action]
- **Then** [expected outcome]
- **And** [additional outcome]
```

### Step 5: Assign Agent Roles

Assign each story to the appropriate agent role:

| Story Characteristic | Assigned Agent |
|---------------------|----------------|
| REST API, business logic, database | `java-backend-developer` |
| Web UI components, pages, state | `react-frontend-developer` |
| Mobile screens and navigation | `mobile-developer` |
| AWS infrastructure, Terraform, K8s, CI/CD | `devops-engineer` |
| Test plans, QA automation, quality gates | `qa-engineer` |
| System design, ADRs, cross-cutting concerns | `tech-lead` |

### Step 6: Identify Dependencies

For each story, identify:
- Stories that must be completed BEFORE this story (blockers)
- Stories that this story ENABLES (dependents)

Common dependency patterns:
- Backend API must exist before Frontend can consume it
- Database schema must be created before API can use it
- Auth system must exist before any protected endpoints
- Infrastructure must be set up before application can deploy

### Step 7: Assign Priorities

Use MoSCoW prioritization:
- **M — Must-have:** Required for any release. Without this, the system has no value.
- **S — Should-have:** Important but the system works without it. Target for first release.
- **C — Could-have:** Nice to have. Include if time permits.
- **W — Won't-have (this iteration):** Acknowledged but explicitly deferred.

### Step 8: Produce the Backlog Document

Create `spec/business/backlog.md`:

```markdown
---
spec_id: SPEC-003
title: "[Project Name] — Product Backlog"
version: "0.1.0"
status: draft
type: business
created: [today]
---

## Backlog Summary

- Total Stories: [N]
- Must-have: [M] stories ([X] estimated points)
- Should-have: [P] stories ([Y] estimated points)
- Could-have: [Q] stories ([Z] estimated points)

## Epic Summary

| Epic | Stories | Must-Have Points | Total Points |
|------|---------|-----------------|-------------|

## Stories by Epic

### EPIC-N: [Epic Title]

#### [STORY-ID]: [Story Title]

**As a** [actor],
**I want** [capability],
**So that** [value].

| Field | Value |
|-------|-------|
| Story Points | [estimate or TBD] |
| Priority | must-have / should-have / could-have |
| Assigned Agent | [agent role] |
| Type | feature / technical / security / spike |
| Dependencies | [STORY-IDs or none] |
| Status | new |

**Acceptance Criteria:**

**Scenario 1: [Name]**
- Given [precondition]
- When [action]
- Then [outcome]

[Additional scenarios...]

---
[Repeat for each story]
```

### Step 9: Review with User

Present a summary:
> "Backlog created with [N] stories across [M] epics.
> 
> **Must-have stories:** [X] ([Y] story points)
> **Should-have stories:** [A] ([B] story points)
> **Could-have stories:** [C] ([D] story points)
>
> Notable dependency chains:
> [List 2-3 key dependency sequences]
>
> Does this backlog reflect your priorities? Are any important stories missing?"

## Important Rules
- **Every actor in stories must appear in `spec/business/frame.md`** — Don't invent new actors
- **Stories must be independent** — If two stories are heavily coupled, they should be one story
- **Acceptance criteria must be testable** — If you can't write a test for it, rewrite the criterion
- **Don't over-engineer stories** — A story is not a spec document. Keep it concise.
- **Technical stories are still stories** — Infrastructure setup, CI/CD config, etc. are valid backlog items

## Output
When complete:
- `spec/business/backlog.md` — Full prioritized backlog
- → Next: `.github/prompts/backlog/backlog-grooming.prompt.md`
