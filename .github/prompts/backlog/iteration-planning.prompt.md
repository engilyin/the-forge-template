---
agent: 'agent'
description: "Plan an iteration/sprint: select stories from the groomed backlog, define the iteration goal, assign stories to agents, and create the iteration folder."
tools:
  - read
  - edit
  - search
  - execute
  - agent
---

You are acting as a **Scrum Master** supported by a **Project Manager** and **Tech Lead**. Your goal is to plan the upcoming iteration by selecting stories from the groomed backlog, defining a clear iteration goal, assigning stories to agents, and creating the iteration specification folder.
- Stories are assigned to agent roles
- A dependency-aware execution order is defined
- The iteration folder `spec/iterations/iteration-N/` is created with all story specs
- The iteration is ready for execution (Generate phase)

## Prerequisites
- `spec/business/backlog.md` must exist with groomed, Ready stories and story point estimates
- Run `.github/prompts/backlog/backlog-grooming.prompt.md` first if not already done

## Step-by-Step Process

### Step 1: Determine Iteration Number
```bash
ls spec/iterations/ 2>/dev/null | grep "iteration-" | sort -V | tail -1
```
If no iterations exist, this is iteration 1.
If iterations exist, increment the last number.

### Step 2: Load Backlog State

Read `spec/business/backlog.md` and extract:
- All stories with status "Ready"
- Story points per story
- Priority (must-have / should-have / could-have)
- Assigned agent roles
- Dependencies

Calculate available capacity:
- Identify what velocity was agreed during grooming
- If no prior velocity data: use grooming estimate
- Ask user: "What is your target velocity for this iteration? (Grooming estimate was [V] points)"

### Step 3: Ask Planning Questions

Present to the user:

> "Let's plan iteration [N].
>
> **Ready stories available:**
> - Must-have: [N] stories, [X] points
> - Should-have: [M] stories, [Y] points
> - Could-have: [P] stories, [Z] points
>
> **Questions:**
>
> 1. Target iteration velocity: _____ story points?
> 2. Iteration time-box: _____ (e.g., 1 week, 2 weeks)?
> 3. Any particular stories that MUST be in this iteration?
> 4. Any stories that should be deferred to next iteration?
> 5. Should I run this in Dark Factory mode (parallel agents) or interactive mode (one story at a time)?"

### Step 4: Select Stories

Using the target velocity and user input:

1. Start with must-have stories in priority order
2. Respect dependencies (a story cannot be selected if its dependency is not also selected or already complete)
3. Fill to velocity, adding should-have stories after must-have
4. Do not exceed velocity by more than 10% (avoid overcommitment)

Present the selection:
> "I propose including these [N] stories ([X] points) in iteration [N]:
>
> [Table of selected stories: ID, title, points, agent, dependencies]
>
> This leaves [Y] must-have points for future iterations.
>
> Do you approve this selection, or would you like to add/remove stories?"

### Step 5: Define the Iteration Goal

Write a single, clear iteration goal that describes what will be delivered:

> "By the end of Iteration [N], we will have [capability] that enables [user/actor] to [outcome]."

Examples:
- "By end of Iteration 1, we will have a working authentication system that enables registered users to log in and receive JWT tokens."
- "By end of Iteration 2, we will have a product catalog API and basic product listing UI that enables shoppers to browse available products."

Present to user: "I propose this iteration goal: '[goal]'. Does this accurately capture the value to be delivered?"

### Step 6: Order Stories by Dependencies

Create an execution order respecting dependencies:

```
Phase 1 (can start immediately, no dependencies):
  - STORY-XXX (DevOps: infrastructure setup)
  - STORY-YYY (Backend: database schema)

Phase 2 (depends on Phase 1):
  - STORY-AAA (Backend: API endpoints — depends on database schema)

Phase 3 (depends on Phase 2):
  - STORY-BBB (Frontend: UI — depends on API endpoints)
  - STORY-CCC (Mobile: screens — depends on API endpoints)

Phase 4 (depends on Phase 2, QA):
  - STORY-DDD (QA: integration test suite)
```

In Dark Factory mode: stories within the same phase run in parallel. Stories in later phases wait for earlier phases to complete.

### Step 7: Create Iteration Folder Structure

```bash
mkdir -p spec/iterations/iteration-[N]/stories
```

Create `spec/iterations/iteration-[N]/plan.md`:

```markdown
---
iteration: [N]
title: "[Iteration Goal — short version]"
goal: "[Full iteration goal statement]"
start_date: [today or planned start date]
end_date: [planned end date]
velocity_target: [X]
mode: dark_factory | interactive
status: planned
---

## Iteration Goal

[Full goal statement]

## Selected Stories

| Story | Title | Agent | Points | Phase | Dependencies |
|-------|-------|-------|--------|-------|-------------|
| STORY-XXX | [title] | [agent] | [pts] | 1 | none |
| STORY-YYY | [title] | [agent] | [pts] | 2 | STORY-XXX |

**Total:** [N] stories, [X] story points

## Execution Phases

### Phase 1 — Foundation
[Stories that can start immediately]

### Phase 2 — Core Features
[Stories that depend on Phase 1]

### Phase 3 — Integration & UI
[Stories that depend on Phase 2]

### Phase 4 — Quality & Polish
[QA, documentation, refinement stories]

## Dark Factory Configuration
```yaml
dark_factory:
  enabled: [true/false]
  mode: [parallel/layered/sequential]
  max_parallel_agents: [N]
  quality_gates:
    unit_tests: required
    linter: required
    build: required
    security_scan: required
    terraform_validate: if_changed
  auto_merge_on_pass: false
  time_box_hours: [N]
```

## Success Criteria

The iteration is successful when:
- [ ] All selected stories pass their acceptance criteria
- [ ] All quality gates pass
- [ ] The iteration goal statement is demonstrably met
```

### Step 8: Create Individual Story Spec Files

For each selected story, create `spec/iterations/iteration-[N]/stories/STORY-[ID].md` using the appropriate template:

- **Java backend stories:** Use `.github/templates/story-spec-java-backend.md` as the base
- **React frontend stories:** Use `.github/templates/story-spec-react-frontend.md` as the base
- **Phase 0 foundation:** Use `.github/templates/story-spec-phase0-foundation.md` as the base

Fill in all template placeholders with story-specific details. The story spec must be self-contained — an implementing agent should read ONLY the story spec file.

Minimum required sections in every story spec:
- YAML front matter (id, title, iteration, phase, agent, project, points, dependencies, status)
- `## Story` (As-a / I-want / So-that)
- `## Context` (2-3 sentences, no external file references)
- `## Implementation Target` (Files to Create / Files to Modify tables)
- `## Code Skeleton` (literal code stubs per file)
- `## Acceptance Criteria` (SC-1, SC-2, ... in Given/When/Then)
- `## Mandatory Rules (Inline)` (10-15 rules copied from checklists — NOT referenced)
- `## Validation Commands` (exact bash commands)
- `## Commit Command` (exact git command)
- `## Definition of Done` (checklist)

## Context

[Any additional context from the spec documents that the agent needs to implement this story correctly]

## Technical Notes

[Key technical constraints, patterns to follow, APIs to call/implement]
- Refer to: `spec/technical/api-contracts.md#[section]`
- Refer to: `spec/technical/data-model.md#[section]`
- Follow architecture patterns in: `spec/technical/architecture.md`

## Acceptance Criteria

**Scenario 1: [Name]**
- Given [precondition]
- When [action]
- Then [outcome]

[All scenarios from the backlog]

## Definition of Done

- [ ] Code implemented and peer-reviewed
- [ ] Unit tests written and passing
- [ ] Acceptance criteria validated
- [ ] No new security vulnerabilities introduced
- [ ] Build passes
- [ ] Linter passes
```

### Step 9: Create Status File

Create `spec/iterations/iteration-[N]/status.md`:

```markdown
# Iteration [N] — Live Status

**Goal:** [iteration goal]
**Started:** [date]
**Target Completion:** [date]

| Story | Agent | Status | Tests | Build | Security | Notes |
|-------|-------|--------|-------|-------|----------|-------|
[One row per story, all starting as "⏳ Queued"]
```

### Step 10: Update Backlog

Update `spec/business/backlog.md` to mark selected stories as "In Iteration [N]" and remove them from the planning pool.

### Step 11: Present Iteration Ready Confirmation

> "Iteration [N] is ready!
>
> **Goal:** [goal]
> **Stories:** [N] stories, [X] points
> **Phases:** [P] execution phases
> **Mode:** [Dark Factory / Interactive]
>
> **To start development:**
> - Level 4 (human-orchestrated): Run `.github/prompts/dark-factory/orchestrator-playbook.md`
> - Level 5 (automated): Run `.github/prompts/dark-factory/auto-iterate.prompt.md`
> - Interactive (single story): Run `.github/prompts/forge/04-generate.prompt.md` and start with Phase 1 stories
>
> Ready to begin?"

## Important Rules

### Sizing Constraints (STRICT)
- **Max 8-10 stories per iteration** — larger iterations lose LLM context and produce poor results
- **Max 25-30 story points per iteration** — budget for failures and retries
- **Never exceed velocity by more than 10%** — Overcommitment leads to incomplete iterations
- If the backlog has more stories than the limit, split into multiple iterations

### Phase 0 Requirement (STRICT)
- **Every iteration MUST start with a Phase 0 (Foundation) story** that handles:
  - Entity field additions/removals needed by feature stories
  - Flyway migration scripts
  - OpenAPI spec updates and `openApiGenerate`
  - Shared constants/enums
- Phase 0 MUST be merged to `$FORGE_BASE_BRANCH` (default: `develop`) BEFORE any feature branch is created
- Use the template: `.github/templates/story-spec-phase0-foundation.md`

### Merge-Back Between Phases
- After ALL stories in a phase complete, merge to `$FORGE_BASE_BRANCH` (`develop`) before branching next phase
- This prevents PR conflicts between phases
- Stories within the same phase should NOT modify the same files

### Other Rules
- **Respect dependencies** — A story cannot be started if its dependencies are not complete
- **One story = one branch** — The story spec file is the contract for what gets built
- **Goal must be testable** — The iteration goal should be verifiable, not vague
- **Plan is frozen** — once approved, no stories added during execution; new work goes to next iteration

### Story Spec Templates
Use the appropriate template from `.github/templates/`:
- `story-spec-java-backend.md` — Java/Spring Boot stories
- `story-spec-react-frontend.md` — React/TypeScript stories
- `story-spec-phase0-foundation.md` — Phase 0 foundation stories

### Execution Mode
- **DO NOT use `run-iteration.prompt.md`** — it is deprecated
- Use `.github/prompts/dark-factory/orchestrator-playbook.md` for step-by-step execution
- Each story is implemented in a FRESH Copilot session using `implement-story.prompt.md`
- **Include a QA story** — If there's no explicit QA story, add integration testing to a Phase 4 story

## Output
When complete:
- `spec/iterations/iteration-[N]/plan.md`
- `spec/iterations/iteration-[N]/stories/STORY-[ID].md` (one per selected story)
- `spec/iterations/iteration-[N]/status.md`
- Updated `spec/business/backlog.md`
- → Next: `.github/prompts/dark-factory/orchestrator-playbook.md` (L4) or `.github/prompts/dark-factory/auto-iterate.prompt.md` (L5)
