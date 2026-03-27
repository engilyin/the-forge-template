# Dark Factory Model — Fully Automated Agent-Driven Development

> Based on the StrongDM "Dark Factory" concept: a software development pipeline that runs like a lights-out manufacturing facility — fully automated, minimal human intervention, maximum throughput.

---

## What Is the Dark Factory?

A **Dark Factory** (also called a lights-out factory) is a manufacturing facility that operates entirely by automated machines with no human workers on the floor. The name comes from the fact that you could turn off all the lights — no humans need them.

Applied to software development, the **Dark Factory model** means:

> An AI-driven development pipeline where agent fleets work autonomously on a defined backlog, producing code, tests, and documentation with zero human intervention during execution — and minimal, structured human intervention at iteration checkpoints.

The human's role shifts from **developer** to **product manager and quality gatekeeper**:
- You define *what* to build (specifications)
- You review *what was built* (iteration reports)
- The Dark Factory builds *how it gets built*

---

## Core Principles

### 1. Specification-First
Dark Factory requires high-quality, unambiguous specifications. The factory can only produce what is specified. Vague specs produce vague code. In Dark Factory mode, there is no opportunity for clarifying questions mid-execution — the agents work autonomously from the spec.

**Prerequisite:** Complete the full FORGE Frame → Obstruct → Reconstruct cycle before activating Dark Factory mode.

### 2. Parallel Execution via Git Worktrees
The Dark Factory achieves throughput by running multiple agent instances simultaneously. Each agent works in an isolated **git worktree** — a separate working directory linked to the same repository but on its own branch.

```
scaffold repository
├── .git/
├── solutions/                  ← all project repositories
│   ├── <project-a>/            ← e.g. acme-api/
│   ├── <project-b>/            ← e.g. acme-web/
│   └── worktrees/              ← git worktrees for isolated feature work
│       ├── <project-a>/
│       │   ├── story-001/      ← worktree for STORY-001 (Backend Agent)
│       │   └── story-003/      ← worktree for STORY-003
│       └── <project-b>/
│           ├── story-002/      ← worktree for STORY-002 (Frontend Agent)
│           └── story-004/      ← worktree for STORY-004 (Mobile Agent)
```

Each worktree is on its own feature branch. Agents work in parallel without interfering with each other.

### 3. Quality Gates Before Human Review
Before presenting results to the human, the Dark Factory runs automated quality gates:
- Unit tests must pass (100% green)
- Linter checks must pass
- Security scan must show no new critical/high vulnerabilities
- Build must succeed
- terraform validate (if infrastructure changed)

Only stories that pass all gates are included in the iteration review.

### 4. Iteration Checkpoints
Human intervention occurs **only at iteration boundaries**:
- Before iteration: approve the iteration plan
- After iteration: review the iteration report and decide go/no-go

Within an iteration, agents work autonomously.

### 5. Story-to-Worktree Mapping
Each story in the iteration is mapped to:
- A git worktree (isolated working directory)
- An agent role (determined by story type)
- A feature branch
- An automated quality gate sequence

---

## Setting Up Dark Factory Mode

### Prerequisites
- Git 2.5+ (for worktree support)
- GitHub Copilot CLI configured
- All FORGE phases completed through Reconstruct
- Iteration plan created in `spec/iterations/iteration-N/plan.md`
- All stories in the plan have status "Ready"

### Step 1: Review the Iteration Plan
Before triggering Dark Factory mode, confirm the iteration plan is complete:
- [ ] Iteration goal is defined
- [ ] All stories are "Ready" (see Definition of Ready in `sdlc-flow.md`)
- [ ] Story specs are in `spec/iterations/iteration-N/stories/`
- [ ] Agent assignments are made for each story

### Step 2: Trigger Dark Factory Execution
```
@workspace Run .github/prompts/dark-factory/run-iteration.prompt.md
```

Copilot will:
1. Read the iteration plan from `spec/iterations/iteration-N/plan.md`
2. Create a git worktree for each story
3. Initialize each worktree on a new feature branch
4. Execute stories in parallel (or sequentially if parallel mode is not supported)
5. Run quality gates after each story completes
6. Aggregate results into an iteration status report

### Step 3: Review the Iteration Report
When all stories are complete (or the time-box expires), review:
```
@workspace Run .github/prompts/dark-factory/assess-iteration.prompt.md
```

The assessment includes:
- Stories completed vs. planned
- Quality gate results per story
- Any deviations from spec
- Issues requiring human decision
- Go/No-Go recommendation

### Step 4: Decide and Act
- **Go:** Merge all passing PRs, tag the release, deploy
- **Fix specific issues:** Targeted edit phase for failed stories
- **Extend iteration:** Add time for stories that need more work
- **Descope:** Remove failing stories from the release, carry to next iteration

---

## Git Worktree Commands Reference

### Create a Worktree for a Story
```bash
git worktree add worktrees/story-001 -b feature/STORY-001-user-authentication
```

### List Active Worktrees
```bash
git worktree list
```

### Remove a Worktree After Completion
```bash
git worktree remove worktrees/story-001
```

### Prune Stale Worktrees
```bash
git worktree prune
```

---

## Agent Fleet Configuration

### Story-to-Agent Role Mapping

Dark Factory automatically assigns agent roles based on story type tags in the story spec:

| Story Type Tag | Agent Role | Worktree Prefix |
|---------------|-----------|----------------|
| `type: backend` | Java Backend Developer | `worktrees/be-` |
| `type: frontend` | React Frontend Developer | `worktrees/fe-` |
| `type: mobile` | Mobile Developer | `worktrees/mob-` |
| `type: infrastructure` | DevOps Engineer | `worktrees/ops-` |
| `type: qa` | QA Engineer | `worktrees/qa-` |
| `type: fullstack` | Tech Lead coordinates | `worktrees/fs-` |

### Story Spec Tags for Dark Factory

Each story spec in `spec/iterations/iteration-N/stories/STORY-XXX.md` must include:

```yaml
---
id: STORY-001
title: User Authentication - JWT Login
type: backend
agent: java-backend-developer
points: 3
dependencies: []
acceptance_criteria_file: spec/validation/acceptance-criteria.md#STORY-001
---
```

---

## Dark Factory Execution Modes

### Mode 1: Full Parallel (Level 5)
All stories start simultaneously. Maximum throughput. Requires careful spec quality to avoid conflicts.

```
Time ──────────────────────────────────────────────►
STORY-001 [backend]  ████████████████ DONE
STORY-002 [frontend] █████████████ DONE
STORY-003 [mobile]   ████████████████████ DONE
STORY-004 [devops]   ████████ DONE
                                          ↑
                                    [Human Review]
```

### Mode 2: Sequential with Parallelism by Layer (Level 4.5)
Backend stories first (they define APIs), then frontend/mobile in parallel (they consume APIs).

```
Time ──────────────────────────────────────────────►
Phase 1: STORY-001 [backend]  ████████████ DONE
Phase 2: STORY-002 [frontend] ████████████ DONE
         STORY-003 [mobile]   ████████████ DONE
Phase 3: STORY-004 [devops]   ████████ DONE
                                              ↑
                                        [Human Review]
```

### Mode 3: Story-by-Story Interactive (Level 4)
Each story is completed and reviewed before the next begins. No parallelism.

---

## Quality Gate Pipeline

Each worktree runs this quality gate sequence before reporting completion:

```
Story Implementation
        │
        ▼
Unit Tests (must: 100% pass)
        │
        ▼
Linter / Code Style (must: 0 errors)
        │
        ▼
Build Compilation (must: succeed)
        │
        ▼
Security Scan (must: no new critical/high)
        │
        ▼
Terraform Validate (if IaC changed)
        │
        ▼
Story Spec Compliance Check
        │
        ▼
✅ PASS → Flag for human review
❌ FAIL → Log failure, flag for human decision
```

---

## Monitoring Dark Factory Execution

### Status File
During execution, each worktree updates `spec/iterations/iteration-N/status.md`:

```markdown
## Iteration N Status

Last Updated: [timestamp]

| Story | Agent | Status | Tests | Build | Security | Notes |
|-------|-------|--------|-------|-------|----------|-------|
| STORY-001 | java-backend | ✅ Complete | ✅ Pass | ✅ Pass | ✅ Pass | |
| STORY-002 | react-frontend | 🔄 In Progress | - | - | - | |
| STORY-003 | mobile | ⏳ Queued | - | - | - | |
| STORY-004 | devops | ❌ Failed | ✅ Pass | ❌ Fail | - | Build error on line 42 |
```

### Checking Status
```
@workspace Read spec/iterations/iteration-N/status.md and give me a current progress summary.
```

---

## Human Review Triggers

Even in full Dark Factory mode, certain events trigger an immediate human review request:

1. **Spec conflict detected** — Two stories have incompatible changes to the same interface
2. **Quality gate failure** — A story fails any quality gate after 2 retry attempts
3. **Unresolvable dependency** — A story depends on another story that has failed
4. **Security finding** — A new critical or high security vulnerability is detected
5. **Architectural deviation** — Agent detects that the spec requires a change not covered by the agreed architecture

---

## Dark Factory Configuration

Configure Dark Factory behavior in `spec/iterations/iteration-N/plan.md`:

```yaml
dark_factory:
  enabled: true
  mode: parallel          # parallel | layered | sequential
  max_parallel_agents: 4  # limit concurrent worktrees
  quality_gates:
    unit_tests: required
    linter: required
    build: required
    security_scan: required
    terraform_validate: if_changed
  auto_merge_on_pass: false   # always require human approval to merge
  notification_on_failure: immediate
  time_box_hours: 8           # max execution time before forced review
```

---

## After the Dark Factory Run

1. Review the iteration assessment report
2. Decide which stories to include in the release
3. Merge passing PRs: `git merge feature/STORY-XXX` (or via GitHub PR)
4. Clean up worktrees: `git worktree prune`
5. Archive the iteration folder
6. Update the backlog (mark completed stories, carry forward incomplete)
7. Plan the next iteration
