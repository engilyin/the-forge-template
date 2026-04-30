# Interactive SDLC Flow — FORGE Template

> This document defines the complete Software Development Lifecycle flow used in the FORGE template.
> Each stage describes what happens, who is involved, what artifacts are produced, and when human checkpoints occur.

---

## SDLC Overview

```
Discovery
    │
    ▼
Specification
    │
    ▼
Backlog Creation
    │
    ▼
Backlog Grooming
    │
    ▼
Iteration Planning
    │
    ▼
Development (Generate)
    │
    ▼
Review / QA (Edit)
    │
    ▼
Release
    │
    ▼
[Next Iteration or Project Close]
```

Human checkpoints (🔵) occur after each stage. The user reviews artifacts and decides whether to proceed, iterate, or escalate.

---

## Stage 1: Discovery

### Goal
Understand what needs to be built and for whom. Establish the context that all subsequent work depends on.

### Agent Roles Involved
- **Business Analyst** (lead)
- **Solution Architect** (support)
- **Project Manager** (support)

### Activities
1. User interviews (Copilot asks structured questions)
2. Domain analysis — understanding the business context
3. Stakeholder identification
4. High-level feature brainstorming
5. Greenfield vs. brownfield assessment
6. Technology preference gathering

### For Greenfield Projects
Run: `.github/prompts/project/greenfield-init.prompt.md`

Copilot will ask:
- What is the name and domain of this project?
- What problem does it solve? For whom?
- What are the most important goals for the first release?
- What technology stack do you prefer? (defaults: Java/Spring Boot, React, Expo RN, AWS)
- What is the team size and structure?
- Are there any hard constraints (timeline, budget, compliance)?

### For Brownfield Projects
Run: `.github/prompts/project/brownfield-analysis.prompt.md`

Copilot will:
- Scan `solutions/` directory for all project repositories
- Identify technology stack, frameworks, patterns in use
- Map existing architecture components
- Identify test coverage baseline
- Highlight technical debt and improvement areas
- Generate a brownfield discovery report

### Artifacts Produced
- Discovery notes (in `spec/business/discovery-notes.md`)
- Stakeholder map
- Initial epic list
- For brownfield: architecture analysis report

### 🔵 Human Checkpoint: Discovery Review
**Question to user:** "I've completed the discovery phase. Here's what I've understood about your project. Does this accurately capture what you're building? Are there any corrections or additions before I proceed to specification?"

**Decision:** Approve → proceed to Specification | Reject → re-run Discovery with corrections

---

## Stage 2: Specification

### Goal
Produce detailed, structured specifications that AI agents can use to generate precise, correct code. This covers business requirements, user stories, technical architecture, and acceptance criteria.

### Agent Roles Involved
- **Business Analyst** (business specs)
- **Solution Architect** (technical specs)
- **Tech Lead** (technical validation)

### Activities
1. Run FORGE Frame phase → `spec/business/frame.md`
2. Run FORGE Obstruct phase → `spec/business/obstruct-report.md`
3. Run FORGE Reconstruct phase → finalized specs in `spec/business/` and `spec/technical/`
4. All specifications written in OpenSpec format (see `.github/instructions/openspec-format.md`)

### Key Specification Artifacts

**Business Specs (`spec/business/`):**
- `frame.md` — Project frame (vision, scope, constraints)
- `actors.md` — User roles and their goals
- `user-stories.md` — Full backlog of user stories
- `obstruct-report.md` — Risks, gaps, assumptions
- `non-functional-requirements.md` — Performance, security, scalability requirements

**Technical Specs (`spec/technical/`):**
- `architecture.md` — System architecture overview and ADRs
- `api-contracts.md` — REST/event API interface definitions
- `data-model.md` — Entity definitions, relationships, storage strategy
- `infrastructure.md` — Cloud infrastructure design (AWS services, Terraform layout)
- `security.md` — Authentication, authorization, data protection requirements
- `deployment.md` — CI/CD pipeline design, deployment strategy (blue/green, canary)

**Validation Specs (`spec/validation/`):**
- `acceptance-criteria.md` — Per-story acceptance criteria
- `test-strategy.md` — Testing approach by layer
- `performance-targets.md` — SLA definitions

### 🔵 Human Checkpoint: Specification Review
**Question to user:** "The specifications are complete. I've produced [X] user stories across [Y] epics. Key technical decisions include: [summary]. Do you want to review any section before I proceed to backlog creation? Are there any changes needed?"

**Decision:** Approve → proceed to Backlog | Request changes → update specific spec sections | Reject → re-run Reconstruct

---

## Stage 3: Backlog Creation

### Goal
Break down the specifications into a prioritized, estimated backlog of user stories that development agents can execute.

### Agent Roles Involved
- **Business Analyst** (story writing)
- **Scrum Master** (story format and quality)
- **Tech Lead** (technical story breakdown)

### Activities
1. Break epics into user stories following format:
   ```
   As a [actor], I want [capability] so that [business value].
   ```
2. Attach acceptance criteria to each story
3. Flag dependencies between stories
4. Assign stories to epics
5. Initial T-shirt size estimation (S/M/L/XL)
6. Mark must-have vs. nice-to-have

Run: `.github/prompts/backlog/story-breakdown.prompt.md`

### Artifacts Produced
- `spec/business/backlog.md` — Full prioritized backlog
- Story count and initial size estimates
- Dependency graph (in backlog file)

### 🔵 Human Checkpoint: Backlog Review
**Question to user:** "The backlog contains [N] stories across [M] epics. [X] are marked as must-have for the first release. Does the backlog reflect your priorities? Are any stories missing or should any be removed?"

**Decision:** Approve → proceed to Grooming | Adjust priorities/stories → update backlog

---

## Stage 4: Backlog Grooming

### Goal
Refine stories to be "Ready" for development — well-defined, correctly sized, unambiguous, and unblocked.

### Agent Roles Involved
- **Scrum Master** (lead)
- **Tech Lead** (technical estimation)
- **Business Analyst** (acceptance criteria clarity)

### Activities
1. Review each story for clarity and completeness
2. Story point estimation (Fibonacci: 1, 2, 3, 5, 8, 13)
3. Identify and resolve ambiguous acceptance criteria
4. Split stories that are too large (>8 points)
5. Mark stories as "Ready" when Definition of Ready is met

### Definition of Ready
A story is **Ready** when:
- [ ] It has a clear title and description
- [ ] Acceptance criteria are specific and testable
- [ ] Story points are estimated
- [ ] All dependencies are identified
- [ ] No blockers exist
- [ ] The implementing agent role is assigned

Run: `.github/prompts/backlog/backlog-grooming.prompt.md`

### Artifacts Produced
- Updated `spec/business/backlog.md` with story points and Ready flags
- Sprint velocity estimate
- Blockers list with owners

### 🔵 Human Checkpoint: Grooming Review
**Question to user:** "Grooming complete. [N] stories are Ready, totaling [X] story points. Estimated velocity is [Y] points/iteration. Are you satisfied with the story definitions? Shall I proceed to iteration planning?"

**Decision:** Approve → proceed to Iteration Planning | More grooming needed → continue grooming session

---

## Stage 5: Iteration Planning

### Goal
Select stories for the current iteration, define the iteration goal, and prepare the development agents for execution.

### Agent Roles Involved
- **Scrum Master** (planning ceremony)
- **Project Manager** (capacity planning)
- **Tech Lead** (technical ordering)

### Activities
1. Define iteration goal (1 sentence: "By end of this iteration we will have...")
2. Select stories from Ready backlog based on velocity
3. Identify story dependencies and ordering
4. Assign stories to agent roles
5. Create iteration folder: `spec/iterations/iteration-N/`
6. Write iteration plan document

Run: `.github/prompts/backlog/iteration-planning.prompt.md`

### Iteration Folder Structure
```
spec/iterations/
  iteration-1/
    plan.md           ← Iteration goal, selected stories, agent assignments
    stories/
      STORY-001.md    ← Full story spec for each story
      STORY-002.md
    status.md         ← Updated during execution
    report.md         ← Completed after Edit phase
```

### 🔵 Human Checkpoint: Iteration Plan Review
**Question to user:** "Iteration [N] is planned with [X] stories ([Y] points). Goal: [iteration goal]. Stories are assigned to [agent list]. Shall I proceed to development execution? If running in Dark Factory mode, I'll use parallel git worktrees."

**Decision:** Approve → proceed to Development | Adjust scope → modify story selection

---

## Stage 6: Development (Generate Phase)

### Goal
Implement all stories in the iteration. Produce working, tested, documented code.

### Agent Roles Involved
- **Java Backend Developer** — Spring Boot/WebFlux/Cloud services
- **React Frontend Developer** — UI components, state management, API integration
- **Mobile Developer** — Expo React Native screens and features
- **DevOps Engineer** — AWS infrastructure, Terraform stacks, and Jenkins CI/CD

### Development Modes

#### Interactive Mode
Stories are worked one at a time. After each story, the user reviews the output before the next story begins.

#### Dark Factory Mode
Stories are implemented sequentially per session (one story = one fresh context). Worktrees isolate each story branch. See `.github/instructions/dark-factory.md`.

- Level 4 (human-orchestrated): `.github/prompts/dark-factory/orchestrator-playbook.md`
- Level 5 (automated): `.github/prompts/dark-factory/auto-iterate.prompt.md`

### Per-Story Development Workflow
1. Agent reads story spec from `spec/iterations/iteration-N/stories/STORY-XXX.md`
2. Agent creates branch: `feature/STORY-XXX-short-description`
3. Agent implements code in the relevant project under `solutions/`
4. Agent writes unit tests
5. Agent runs local test suite
6. Agent commits with conventional commit message
7. Agent creates PR (or marks ready for review in Dark Factory mode)
8. Agent updates `spec/iterations/iteration-N/status.md`

### Artifacts Produced
- Source code in `solutions/<project-name>/` (feature branches)
- Unit tests alongside implementation code
- Updated CI/CD pipeline if required
- Terraform changes if infrastructure modified

### 🔵 Human Checkpoint: Story-Level Review (Interactive Mode Only)
Between each story in interactive mode, Copilot presents:
- What was implemented
- Test results
- Any deviations from the spec and why
- Next story to be worked

**Decision:** Approve story → continue | Request changes → edit phase for this story | Reject → re-implement

---

## Stage 7: Review / QA (Edit Phase)

### Goal
Validate all iteration deliverables against acceptance criteria, perform code review, and produce a release candidate.

### Agent Roles Involved
- **QA Engineer** (test execution, acceptance validation)
- **Tech Lead** (code review)
- **Solution Architect** (architecture review)

### Activities
1. Code review for each PR/story
2. Integration test execution
3. Acceptance criteria validation (story-by-story)
4. Security review (SAST, dependency scan)
5. Performance check for critical paths
6. Documentation review
7. Go/No-Go decision support

Run: `.github/prompts/forge/05-edit.prompt.md`

### Artifacts Produced
- Code review comments/resolutions
- QA test report in `spec/iterations/iteration-N/report.md`
- Updated `spec/validation/` with test results
- Release notes draft

### 🔵 Human Checkpoint: Iteration Assessment
Run: `.github/prompts/dark-factory/assess-iteration.prompt.md`

**Question to user:** "Iteration [N] is complete. [X/Y] stories passed acceptance criteria. [Z] issues found. Overall status: [GREEN/AMBER/RED]. Do you approve this iteration for release? Or should we fix [specific issues] before release?"

**Decision:** 
- Approve for release → proceed to Release stage
- Fix and re-review → targeted Edit phase
- Rollback → discard iteration, re-plan

---

## Stage 8: Release

### Goal
Deploy the validated release candidate to production (or staging) and update all documentation.

### Agent Roles Involved
- **DevOps Engineer** (deployment execution)
- **Tech Lead** (release approval)
- **Project Manager** (stakeholder communication)

### Activities
1. Merge all iteration PRs to main branch
2. Create release tag (semantic versioning)
3. Trigger CI/CD pipeline (Jenkins)
4. Deploy to the target runtime platform (for example ECS/Fargate, Kubernetes, or another approved runtime) starting with staging when applicable
5. Post-deployment smoke tests
6. Update CHANGELOG.md
7. Notify stakeholders

### Artifacts Produced
- Deployed release
- Release tag and GitHub release notes
- Updated CHANGELOG.md
- Post-deployment test results
- Stakeholder communication

### 🔵 Human Checkpoint: Release Confirmation
**Question to user:** "Release [version] has been deployed to [environment]. Smoke tests: [PASS/FAIL]. Are you satisfied with the release? Shall I begin planning the next iteration?"

**Decision:** 
- Satisfied → close iteration, plan next
- Issues found → hotfix process
- Project complete → run project close activities

---

## Agile Loop Summary

```
Discovery ──► Specification ──► Backlog
                                  │
                            ◄─────┘ (adjust backlog as needed)
                                  │
                            Grooming ──► Iteration Planning
                                               │
                                         Development ──► Review/QA
                                               │              │
                                          [next iter] ◄──── Release?
                                                              │
                                                          Release ──► [next iter]
```

Dark Factory automation applies within the **Development** stage, with human checkpoints before and after each iteration.
