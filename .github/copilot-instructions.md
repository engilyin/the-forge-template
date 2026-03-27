# GitHub Copilot Workspace Instructions — FORGE Template

> **You are operating inside the FORGE AI-assisted SDLC Template.**
> This file is the primary entry point for GitHub Copilot in this workspace.
> Read this file fully before taking any action.

---

## Terminology

- **Product**: The overall system managed by this scaffold. One scaffold repository per product. Example: "Acme Platform".
- **Project**: A single Git repository / service that is part of the product (e.g. `acme-api`, `acme-web`, `acme-mobile`, `acme-iac`). Each project lives in its own subdirectory under `solutions/`.

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

This scaffold supports **multiple projects** (repositories) under a single product umbrella. Coordinated changes across microservices, frontends, mobile apps, and infrastructure are managed together with shared specifications and cross-project stories.

---

## Two Operating Modes

### Mode 1: Greenfield (New Project)
Start from scratch. Run the greenfield init prompt to kick off the FORGE Frame phase.

```
Use prompt: .github/prompts/project/greenfield-init.prompt.md
```

Steps:
1. Open `.github/prompts/project/greenfield-init.prompt.md` in Copilot
2. Answer the clarifying questions about your product and its projects
3. Copilot will run the Frame phase and populate `spec/business/`
4. Continue through the SDLC flow

### Mode 2: Brownfield (Existing Codebase)
Clone your existing project repositories into the `solutions/` folder, then run the brownfield analysis prompt.

```
Use prompt: .github/prompts/project/brownfield-analysis.prompt.md
```

Steps:
1. Clone each project repository into `solutions/`:
   ```bash
   cd solutions
   git clone https://github.com/your-org/acme-api
   git clone https://github.com/your-org/acme-web
   git clone https://github.com/your-org/acme-mobile
   cd ..
   ```
2. Open `.github/prompts/project/brownfield-analysis.prompt.md` in Copilot
3. Copilot will scan all projects in `solutions/` and generate technical specs in `spec/technical/`
4. Use the specs as the starting point for new iterations

---

## Directory Guide

```
.github/
  copilot-instructions.md  ← 🚀 YOU ARE HERE — Primary entry point for Copilot
  instructions/       ← Workspace-level reference documents
  prompts/            ← Reusable prompt files (.prompt.md) for each SDLC phase
    forge/            ← FORGE phase prompts (01-frame through 05-edit)
    project/          ← Greenfield and brownfield initialization prompts
    backlog/          ← Story breakdown, grooming, and iteration planning
    dark-factory/     ← Autonomous iteration execution and assessment
  agents/             ← Agent role definitions (architect, dev, QA, etc.)
  skills/             ← Domain-specific coding standards and patterns

.agents/
  skills/             ← Copilot CLI discoverable skill wrappers (SKILL.md)

spec/
  business/           ← Business specs, Frame documents, user stories
  technical/          ← Technical specs, architecture decisions, API contracts
  validation/         ← QA plans, acceptance criteria, test reports
  iterations/         ← Per-iteration plans, story specs, and reports

solutions/                        ← All project repositories live here
  <project-name>/                 ← e.g. acme-api/ (plain git clone)
  <project-name>/                 ← e.g. acme-web/
  worktrees/                      ← Git worktrees for isolated feature work
    <project-name>/               ← e.g. acme-api/
      <feature-branch>/           ← e.g. feature-US-01-01-auth/
```

---

## Repository & worktree rules

To avoid accidental edits in the scaffold repository and ensure a clean separation between specification and implementation, follow these rules strictly:

- All implementation work MUST be done inside the project directories under `solutions/`. The root repo is a scaffolding/spec repository and should only contain specs, prompts, agents, and instructions. Do NOT add or modify source code under the root repo.
- Clone project repositories directly into `solutions/` using their GitHub name (plain `git clone` from within the `solutions/` folder): e.g. `cd solutions && git clone <url>` produces `solutions/acme-api/`.
- Create git worktrees for feature branches at `solutions/worktrees/<project-name>/<branch-slug>/`. Example:
  ```bash
  git -C solutions/acme-api worktree add ../worktrees/acme-api/feature-US-01-01-auth -b feature/US-01-01-auth main
  ```
- **Cross-project stories**: A single user story can touch multiple projects. Create one worktree per affected project. The story spec's `projects` field lists which repos are involved.
- The backlog and story definitions live in `spec/iterations/...` in the root repo. Use those files as the authoritative source of truth for which stories to implement and their acceptance criteria.
- Before starting a story, scan ALL relevant project directories under `solutions/` for any existing or partially implemented code. If code exists, update or extend it — do not re-implement functionality that already exists.
- Parallelism rule: only run stories in parallel when they belong to the same story-group (i.e., the middle segment is identical). For example, `US-01-01`, `US-01-02` may run in parallel (same `01` group). Do NOT parallelize stories across different groups. When in doubt, complete stories with smaller last-segment numbers first (e.g., finish `US-01-01` before `US-02-01`).
- Dependency rule: check `dependencies` in the story front-matter and `todo_deps` in the session DB before dispatching agents. Do not start a story that depends on unfinished work.
- When creating or updating branches, prefer small, reviewable commits and open a PR in the relevant project repo for code changes. The root repo PRs should be limited to spec/iteration/backlog changes only.
- If an accidental change to the root repo is required (rare), ask for explicit confirmation before committing.

These rules will be enforced by agents when running iterations. Update this section if your team workflow differs.

## Tooling & search guidance

- The `solutions/` directory contains multiple nested Git repositories. Search and file tools do not automatically traverse nested repos — always operate explicitly inside the target project when inspecting or modifying implementation code.
- Preferred file discovery commands (use these when in doubt):
  - `git -C solutions/<project-name> ls-files '<pattern>'` — preferred for tracked files
  - PowerShell: `Get-ChildItem -Path .\solutions\<project-name> -Recurse -Filter *.java`
  - For targeted patterns use explicit paths: e.g. `solutions\acme-api\src\main\java\**\*.java`
- The glob tool in this environment may not match files inside nested repos. If a glob returns no matches, verify with `git -C solutions/<project>` or PowerShell `Get-ChildItem`.
- When creating worktrees or branches for implementation, run commands targeting the nested repo:
  ```bash
  git -C solutions/acme-api worktree add ../worktrees/acme-api/feature-US-01-01 -b feature/US-01-01-auth main
  ```
- Automation and agents MUST perform a pre-check: confirm the project directory exists and `git -C solutions/<project> rev-parse --is-inside-work-tree` before assuming files are present.
- To list all available projects: `ls solutions/` or `Get-ChildItem -Path .\solutions -Directory -Exclude worktrees`.

These guidelines reduce mistakes when tools or agents search for sources and will be enforced by agents and CI checks.

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
13. **Small, reviewable commits** — Generate code in small, logically coherent units. Each story = one branch + one PR per project.
14. **Test-first mindset** — When generating implementation code, also generate corresponding tests.
15. **Security by default** — Never generate code with hardcoded secrets, insecure defaults, or known vulnerability patterns.
16. **Confirm before destructive actions** — Before deleting, overwriting, or making breaking changes, ask the user to confirm.
17. **Git commit authorship** — All commits and PRs must be authored as user which would be set. Use `git -c user.name='<set user>' -c user.email='<set email>' commit ...`. Do NOT add a `Co-authored-by: Copilot` trailer or any other co-author to any commit message.
18. **Multi-project awareness** — When implementing a story, check its `projects` field to determine which repositories under `solutions/` are affected. Create worktrees and branches in each affected project.

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

Skills are available in two formats:
- **Full reference:** `.github/skills/<name>.md` — detailed patterns, anti-patterns, and examples
- **Copilot CLI discovery:** `.agents/skills/<name>/SKILL.md` — thin wrappers for `/skills reload` and `/skills list`

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
@workspace Summarize the current state of the project based on what's in spec/ and solutions/.
```
