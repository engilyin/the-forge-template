# GitHub Copilot Workspace Instructions — FORGE Template

> **You are operating inside the FORGE AI-assisted SDLC Template.**
> This file is the primary entry point for GitHub Copilot in this workspace.
> Read this file fully before taking any action.

---

## What Is This Template?

This repository is a **FORGE Framework Template** — a structured methodology for AI-assisted software development using GitHub Copilot CLI. FORGE stands for:

| Phase | Meaning |
|-------|---------|
| **F** | Frame — Define the vision, goals, scope, and constraints |
| **O** | Obstruct — Surface blockers, unknowns, risks, and gaps |
| **R** | Reconstruct — Resolve obstructions and refine specifications |
| **G** | Generate — Produce code, infrastructure, tests, and documentation |
| **E** | Edit — Review, refine, and polish all artifacts |

The template integrates:
- **Dan Shapiro's 5 Levels of Vibe Coding** — targeting Levels 4 (Engineered Vibe) and 5 (Dark Factory)
- **StrongDM Dark Factory Model** — fully automated, agent-driven development using parallel git worktree fleets
- **OpenSpec.dev Format** — structured, AI-readable specification format
- **Agile SDLC Loop** — Discovery → Specification → Backlog → Grooming → Iteration Planning → Development → Review/QA → Release

---

## Two Operating Modes

### Mode 1: Greenfield (New Project)
Start from scratch. Run the greenfield init prompt to kick off the FORGE Frame phase.

```
Use prompt: .github/prompts/project/greenfield-init.prompt.md
```

Steps:
1. Open `.github/prompts/project/greenfield-init.prompt.md` in Copilot
2. Answer the clarifying questions about your project
3. Copilot will run the Frame phase and populate `spec/business/`
4. Continue through the SDLC flow

### Mode 2: Brownfield (Existing Codebase)
Place your existing codebase in the `solution/` folder, then run the brownfield analysis prompt.

```
Use prompt: .github/prompts/project/brownfield-analysis.prompt.md
```

Steps:
1. Copy or clone your existing project into `solution/`
2. Open `.github/prompts/project/brownfield-analysis.prompt.md` in Copilot
3. Copilot will scan the codebase and generate technical specs in `spec/technical/`
4. Use the specs as the starting point for new iterations

---

## Directory Guide

```
.github/
  instructions/       ← You are here. Workspace-level instructions for Copilot.
  prompts/            ← Reusable prompt files (.prompt.md) for each SDLC phase.
    forge/            ← FORGE phase prompts (01-frame through 05-edit)
    project/          ← Greenfield and brownfield initialization prompts
    backlog/          ← Story breakdown, grooming, and iteration planning
    dark-factory/     ← Autonomous iteration execution and assessment
  agents/             ← Agent role definitions (architect, dev, QA, etc.)
  instructions/      ← Workspace instructions + skill definitions (*.instructions.md)

spec/
  business/           ← Business specs, Frame documents, user stories
  technical/          ← Technical specs, architecture decisions, API contracts
  validation/         ← QA plans, acceptance criteria, test reports

solution/             ← Your project code lives here (greenfield output or brownfield input)
```

---

## Repository & worktree rules

To avoid accidental edits in the scaffold repository and ensure a clean separation between specification and implementation, follow these rules strictly:

- All implementation work MUST be done inside the nested `solution/` repository. The root repo is a scaffolding/spec repository and should only contain specs, prompts, agents, and instructions. Do NOT add or modify source code under the root repo.
- Create branches and git worktrees inside `solution/`. Example: from `solution/` run `git worktree add -b feature/xyz ../worktrees/solution-feature-xyz main`.
- The backlog and story definitions live in `spec/iterations/...` in the root repo. Use those files as the authoritative source of truth for which stories to implement and their acceptance criteria.
- Before starting a story, scan `solution/` for any existing or partially implemented code for that story. If code exists, update or extend it — do not re-implement functionality that already exists.
- Parallelism rule: only run stories in parallel when they belong to the same story-group (i.e., the middle segment is identical). For example, `US-01-01`, `US-01-02` may run in parallel (same `01` group). Do NOT parallelize stories across different groups. When in doubt, complete stories with smaller last-segment numbers first (e.g., finish `US-01-01` before `US-02-01`).
- Dependency rule: check `dependencies` in the story front-matter and `todo_deps` in the session DB before dispatching agents. Do not start a story that depends on unfinished work.
- When creating or updating branches, prefer small, reviewable commits and open a PR in the nested `solution/` repo for code changes. The root repo PRs should be limited to spec/iteration/backlog changes only.
- If an accidental change to the root repo is required (rare), ask for explicit confirmation before committing.

These rules will be enforced by agents when running iterations. Update this section if your team workflow differs.

---

## FORGE Phase Prompts

Run these in order for a new project:

| Step | Prompt File | Purpose |
|------|-------------|---------|
| 1 | `forge/01-frame.prompt.md` | Define vision, goals, scope |
| 2 | `forge/02-obstruct.prompt.md` | Identify risks and unknowns |
| 3 | `forge/03-reconstruct.prompt.md` | Resolve gaps, refine specs |
| 4 | `forge/04-generate.prompt.md` | Generate code and infrastructure |
| 5 | `forge/05-edit.prompt.md` | Review and polish artifacts |

---

## Agent Roles Available

Each agent in `.github/agents/` represents a specialized Copilot persona:

- **Solution Architect** — High-level design, technology decisions
- **Business Analyst** — Requirements, user stories, acceptance criteria
- **Project Manager** — Timeline, risk, stakeholder communication
- **Scrum Master** — Agile ceremonies, backlog health, flow
- **Tech Lead** — Technical standards, code quality, architecture enforcement
- **Java Backend Developer** — Spring Boot, WebFlux, Spring Cloud
- **React Frontend Developer** — React, TypeScript, UI/UX
- **Mobile Developer** — Expo React Native (Android/iOS)
- **DevOps Engineer** — AWS infrastructure, Terraform, Jenkins, and deployment systems
- **QA Engineer** — Testing strategy, automation, quality gates

To invoke an agent persona, reference the agent file at the start of your Copilot session:
```
@workspace Read .github/agents/java-backend-developer.md and act as this agent.
```

---

## Key Behavioral Rules for Copilot

When operating in this workspace, Copilot **MUST**:

1. **Be interactive** — Always ask clarifying questions before generating large artifacts. Confirm understanding before proceeding.
2. **Follow the SDLC flow** — Do not skip phases. Frame before Generate. Obstruct before Reconstruct.
3. **Respect specifications** — All generated code must trace back to a spec in `spec/`. Do not invent requirements.
4. **Use OpenSpec format** — All specifications must follow the OpenSpec.dev format defined in `.github/instructions/openspec-format.md`.
5. **API-First** — Before implementing any REST endpoint, the OpenAPI spec must exist and be agreed in `spec/technical/api-contracts.yaml`. Follow `.github/skills/api-first.md` for conventions.
6. **Expo mobile work follows the mobile skill** — For Expo/React Native stories, follow `.github/skills/expo-react-native.md` for route structure, state, API communication, notifications, config, and anti-patterns.
7. **React web work follows the web skill** — For React website and admin UI stories, follow `.github/skills/react-web-frontend.md` for feature routing, CRUD structure, API clients, forms, entity patterns, state, and anti-patterns.
8. **Large React data grids follow the table skill** — For huge virtualized CRUD tables, also follow `.github/skills/react-virtualized-crud-tables.md` for bounded-memory paging, state-manager contracts, toolbar orchestration, and row-action update patterns.
9. **AWS infrastructure work follows the AWS skills** — For Terraform + Jenkins infrastructure changes, follow `.github/skills/aws-terraform-jenkins-infrastructure.md` for stack boundaries, state handling, env files, parameter stacks, and AWS design rules, and follow `.github/skills/aws-ecs-fargate-runtime-deployments.md` for ECS/Fargate runtime, image delivery, ALB integration, and rollout rules.
10. **Use low-cost models by default** — Default to `GPT-5 Mini` for routine execution work such as backlog grooming, iteration planning, generation, editing, tests, refactors, docs, and implementation. Use a premium model only for high-level analysis tasks such as greenfield framing, brownfield analysis, large architecture trade-off analysis, or when the user explicitly asks for it.
11. **Agent fidelity** — When acting as an agent, stay in that role. Do not conflate responsibilities.
12. **Document decisions** — Every significant decision (architectural, product, technical) must be recorded as an ADR or spec entry.
13. **Small, reviewable commits** — Generate code in small, logically coherent units. Each story = one branch + one PR.
14. **Test-first mindset** — When generating implementation code, also generate corresponding tests.
15. **Security by default** — Never generate code with hardcoded secrets, insecure defaults, or known vulnerability patterns.
16. **Confirm before destructive actions** — Before deleting, overwriting, or making breaking changes, ask the user to confirm.
17. **Git commit authorship** — All commits and PRs must be authored as user which would be set. Use `git -c user.name='<set user>' -c user.email='<set email>' commit ...`. Do NOT add a `Co-authored-by: Copilot` trailer or any other co-author to any commit message.

---

## Reference Documents

| Document | Purpose |
|----------|---------|
| `.github/instructions/forge-framework.md` | Full FORGE framework explanation |
| `.github/instructions/sdlc-flow.md` | Interactive SDLC flow stages |
| `.github/instructions/5-levels-vibe-coding.md` | Dan Shapiro's 5 levels framework |
| `.github/instructions/dark-factory.md` | StrongDM Dark Factory model |
| `.github/instructions/openspec-format.md` | OpenSpec.dev specification format |
| `spec/README.md` | Spec folder structure guide |

## Skills Available

| Skill | Purpose |
|-------|---------|
| `.github/skills/api-first.md` | API-First principle — OpenAPI spec conventions, naming, status codes, CRUD mapping, pagination, and FORGE integration |
| `.github/skills/spring-boot-webflux.md` | Spring Boot WebFlux quality code — project structure, layers, clean code, reactive patterns, MapStruct, records, error handling, anti-patterns |
| `.github/skills/expo-react-native.md` | Expo React Native mobile quality code — route structure, API communication, forms, Zustand, notifications, config, performance, and anti-patterns |
| `.github/skills/react-web-frontend.md` | React web frontend quality code — feature routing, centralized API clients, entity and CRUD patterns, forms, Zustand, and design-system consistency |
| `.github/skills/react-virtualized-crud-tables.md` | React virtualized CRUD tables — bounded-memory page windows, state-manager contracts, toolbar orchestration, row updates, and large-dataset pitfalls |
| `.github/skills/aws-terraform-jenkins-infrastructure.md` | AWS infrastructure provisioning — Terraform stack boundaries, Jenkins pipelines, S3 state, env tfvars, Parameter Store, and AWS design guidance |
| `.github/skills/aws-ecs-fargate-runtime-deployments.md` | AWS runtime and deployment patterns — ECS/Fargate services, task definitions, ALB integration, image publishing, EFS usage, and rollout guidance |
| `.github/skills/openspec-authoring.md` | Writing OpenSpec specification documents |
| `.github/skills/code-review.md` | Code review guidelines |
| `.github/skills/testing.md` | Testing strategy and patterns |
| `.github/skills/refactoring.md` | Safe refactoring techniques |
| `.github/skills/documentation.md` | Documentation standards |

To apply a skill, reference it at the start of your session:
```
@workspace Read .github/skills/api-first.md and apply it when designing or reviewing APIs.
```

---

## Getting Help

If you are unsure what to do next, ask Copilot:
```
@workspace What phase of FORGE am I in, and what should I do next?
```

Or to get a status summary:
```
@workspace Summarize the current state of the project based on what's in spec/ and solution/.
```
