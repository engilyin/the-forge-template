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
- **Branching strategy: Git Flow.** All feature branches are created from `$FORGE_BASE_BRANCH` (default: `develop`), and all PRs target `$FORGE_BASE_BRANCH`. The human releases to `main` manually at the end of an iteration. This keeps `main` stable while AI-generated code lands on `develop` for review.
- **Creating worktrees: use the init-worktree script.** Always prefer `.forge/init-worktree.sh` which handles branch creation from the correct base, git author setup, and secret file copying in one step:
  ```bash
  bash .forge/init-worktree.sh acme-api US-01-01 auth
  ```
  Manual equivalent:
  ```bash
  git -C solutions/acme-api worktree add ../worktrees/acme-api/US-01-01 -b feature/US-01-01-auth develop
  ```

  IMPORTANT: Do NOT create worktrees at the repository root or at top-level paths like `C:\code\myproduct\worktrees\...`. Implementation work MUST live under `solutions/worktrees/<project-name>/` so agents and CI can locate per-project codebases. If an agent or script accidentally created top-level worktrees, remove them and recreate correctly:
  ```bash
  # prune stale top-level entries
  git worktree prune

  # create the correct per-project worktree (via init script)
  bash .forge/init-worktree.sh acme-api US-01-01 auth
  ```

  The Dark Factory automation and agents rely on this layout; scripts and prompts expect `solutions/worktrees/<project>/<branch>/`.
- **`git -C` path gotcha — CRITICAL.** When using `git -C solutions/<project>`, the worktree path argument is resolved **relative to `solutions/<project>/`**, NOT the repo root. Always use `../worktrees/...` (goes up to `solutions/` then into `worktrees/`). Using `solutions/worktrees/...` with `git -C` creates the worktree at `solutions/<project>/solutions/worktrees/...` — completely wrong.
- **Secret/config file copying is mandatory.** When creating a worktree (either via `.forge/init-worktree.sh` or manually), copy all gitignored config files listed in `FORGE_SECRET_FILES` from the main project checkout into the worktree. Default patterns: `src/main/resources/application-default.properties`, `src/main/resources/application-local.properties`, `.env`, `.env.local`, `.env.development.local`.
- **Cross-project stories**: A single user story can touch multiple projects. Create one worktree per affected project. The story spec's `projects` field lists which repos are involved.
- The backlog and story definitions live in `spec/iterations/...` in the root repo. Use those files as the authoritative source of truth for which stories to implement and their acceptance criteria.
- Before starting a story, scan ALL relevant project directories under `solutions/` for any existing or partially implemented code. If code exists, update or extend it — do not re-implement functionality that already exists.
- Parallelism rule: only run stories in parallel when they belong to the same story-group (i.e., the middle segment is identical). For example, `US-01-01`, `US-01-02` may run in parallel (same `01` group). Do NOT parallelize stories across different groups. When in doubt, complete stories with smaller last-segment numbers first (e.g., finish `US-01-01` before `US-02-01`).
- Dependency rule: check `dependencies` in the story front-matter and `todo_deps` in the session DB before dispatching agents. Do not start a story that depends on unfinished work.
- When creating or updating branches, prefer small, reviewable commits and open a PR (targeting `$FORGE_BASE_BRANCH` / `develop`) in the relevant project repo for code changes. The root repo PRs should be limited to spec/iteration/backlog changes only.
- Database migration files belong at the repository root under `/db/migration/` and follow Flyway naming conventions (e.g., `V3__add_owner_table.sql`). Migrations are applied by the CD pipeline — do NOT rely on application startup to run migrations locally in the scaffold repo. For schema changes affecting a specific service, create a separate worktree in the target service repository (for example `solutions/acme-api` or the relevant project) and make migration and application changes there.
- If an accidental change to the root repo is required (rare), ask for explicit confirmation before committing.

These rules will be enforced by agents when running iterations. Update this section if your team workflow differs.

## Worktree initialization

Before any story implementation, run the init-worktree script:
```bash
bash .forge/init-worktree.sh <project-name> <story-id> [slug]
```

The script (`.forge/init-worktree.sh`):
1. Sources `.forge/config.env` for all configuration
2. Creates the worktree from `$FORGE_BASE_BRANCH` (default: `develop`)
3. Sets `git config user.name` / `user.email` on the worktree (from `FORGE_AUTHOR_NAME` / `FORGE_AUTHOR_EMAIL`)
4. Copies all files matching `FORGE_SECRET_FILES` patterns from the main project checkout

If `$FORGE_BASE_BRANCH` doesn't exist yet, the script creates it from `main`.

For first-time setup of all projects at once, also run:
```bash
bash setauthor.sh
```
This sets git author and ensures `$FORGE_BASE_BRANCH` exists in every project under `solutions/`.

## Tooling & search guidance

- The `solutions/` directory contains multiple nested Git repositories. Search and file tools do not automatically traverse nested repos — always operate explicitly inside the target project when inspecting or modifying implementation code.
- Preferred file discovery commands (use these when in doubt):
  - `git -C solutions/<project-name> ls-files '<pattern>'` — preferred for tracked files
  - PowerShell: `Get-ChildItem -Path .\solutions\<project-name> -Recurse -Filter *.java`
  - For targeted patterns use explicit paths: e.g. `solutions\acme-api\src\main\java\**\*.java`
- The glob tool in this environment may not match files inside nested repos. If a glob returns no matches, verify with `git -C solutions/<project>` or PowerShell `Get-ChildItem`.
- When creating worktrees or branches for implementation, run commands targeting the nested repo:
  ```bash
  # IMPORTANT: with git -C, the worktree path is relative to the -C directory (solutions/<project>/),
  # so use ../worktrees/ to resolve to solutions/worktrees/. NEVER use solutions/worktrees/ with git -C.
  git -C solutions/acme-api worktree add ../worktrees/acme-api/feature-US-01-01 -b feature/US-01-01-auth develop
  ```
- Automation and agents MUST perform a pre-check: confirm the project directory exists and `git -C solutions/<project> rev-parse --is-inside-work-tree` before assuming files are present.
- To list all available projects: `ls solutions/` or `Get-ChildItem -Path .\solutions -Directory -Exclude worktrees`.

These guidelines reduce mistakes when tools or agents search for sources and will be enforced by agents and CI checks.

## Copilot CLI — Platform notes (Windows vs macOS / Linux)

- **Windows (PowerShell)**:
  - Ensure PowerShell execution policy allows running scripts when installing or invoking the CLI: `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force`.
  - Environment variables (temporary): `$env:NAME='value'`. To persist env vars use `setx NAME "value"`.
  - Path and quoting: prefer double-quotes for paths with spaces. Many tools accept forward slashes (`/`) — prefer them for cross-platform compatibility.
  - If repository scripts assume POSIX tools (bash, sh), prefer running Copilot CLI from **Git Bash** or **WSL** to avoid subtle differences.

- **macOS / Linux (bash, zsh)**:
  - Export variables with `export NAME=value`.
  - Make local scripts executable when needed: `chmod +x ./script.sh`.
  - Shell quoting rules differ from PowerShell: use single quotes to prevent expansion, double quotes to allow it.

- **Cross-platform tips**:
  - Always run the Copilot CLI from the workspace root so relative paths and multi-repo worktrees resolve correctly.
  - When sharing examples in prompts or scripts, use forward slashes in paths and avoid shell-specific syntax unless you document it.
  - For nested git repositories and worktrees, prefer `git -C <repo> <command>` to avoid cwd confusion across shells.
  - If you want consistent Unix-like behavior on Windows, use WSL or Git Bash rather than PowerShell for automation scripts.

## Copilot CLI Autopilot / "Dark Factory" tips

- **Design prompts and specs first**: put high-level requirements, constraints, and acceptance criteria in `spec/` (OpenSpec/.prompt.md). Autopilot works best when it has a clear spec to follow.

- **Prefer many small, explicit tasks**: break large work into focused prompts (one intent per prompt). This reduces ambiguity and makes autopilot decisions predictable.

- **Use agent personas and skills**: include the intended agent/skill in the prompt (see `.github/agents/` and `.agents/skills/`) so agents follow expected conventions and patterns.

- **Dry-run / review-first**: run Autopilot in preview/no-commit or review mode (if available) to inspect suggested changes before automatic commits or pushes. Always validate large changes manually first.

- **Worktree strategy**: create git worktrees per project/feature and point Autopilot at the worktree directories. This keeps cross-project changes isolated and safely reversible.

- **Constrain iterations and side-effects**: set clear iteration limits and explicit branching/commit rules in the prompt (branch naming, commit message templates, whether to open a PR, etc.).

- **Monitor and intervene on ambiguity**: Autopilot excels at routine, well-scoped work. For design choices, ambiguous tradeoffs, or security-sensitive code, pause autopilot and request human review.

- **Safety checklist to include in prompts**:
  - No hard-coded secrets (always mention secrets management).
  - Tests and linters must pass locally before commits are made.
  - Generate small, reviewable commits (one logical change per commit).

These additions are intended as pragmatic, platform-aware guidance for running Copilot CLI and using Autopilot effectively with the FORGE template.

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
| 6 | `forge/06-amend.prompt.md` | Agile feedback — update specs when implementation reveals issues |

Dark Factory execution uses these prompts (in order):

| Step | Prompt File | Purpose |
|------|-------------|---------|
| 0 | `dark-factory/orchestrator-playbook.md` | **START HERE** — Human-driven step-by-step execution checklist |
| 1 | `dark-factory/preprocess-iteration.prompt.md` | Generate self-contained story specs with code skeletons and inline rules |
| 2 | `dark-factory/implement-story.prompt.md` | Implement ONE story per Copilot session (repeat per story) |
| 3 | `dark-factory/assess-iteration.prompt.md` | Review results, produce Go/No-Go |
| 4 | `dark-factory/auto-iterate.prompt.md` | **Level 5 — Fully automated** unattended iteration (sequential stories, parallel validation) |
| 5 | `dark-factory/review-story.prompt.md` | Apply human review feedback to completed stories |

> ⚠️ `run-iteration.prompt.md` is **DEPRECATED**. It tried to run all stories in one LLM session,
> which causes context loss, rule-ignoring, and state confusion. Use the orchestrator playbook or auto-iterate instead.

Story spec templates (use during iteration planning and preprocessing):

| Template | Purpose |
|----------|---------|
| `.github/templates/story-spec-java-backend.md` | Java/Spring Boot story with code skeleton |
| `.github/templates/story-spec-react-frontend.md` | React/TypeScript story with code skeleton |
| `.github/templates/story-spec-phase0-foundation.md` | Phase 0 foundation story (entities, migrations, stubs) |
| `.github/templates/state.json.template` | Iteration state tracking template |

## Iteration Sizing Rules

- **Max 8-10 stories per iteration** — larger iterations lose context and produce poor results
- **Max 25-30 story points per iteration** — budget for failures and retries
- **Stories requiring spikes** must complete their spike in a prior iteration — never include unresolved spikes
- **Phase 0 (Foundation)** — every iteration must start with a Phase 0 story that handles shared changes (entity modifications, OpenAPI updates, `openApiGenerate`, shared services). Phase 0 must be merged to `$FORGE_BASE_BRANCH` (`develop`) BEFORE feature branches are created.
- **Merge-back between phases** — after completing a phase, merge all completed branches to `$FORGE_BASE_BRANCH` (`develop`), then branch the next phase from the updated `develop`. This prevents PR conflicts.
- **Release to main is manual** — at the end of an iteration (after assessment + review), the human merges `develop` → `main` to release. AI agents NEVER merge directly to `main`.
- **Plan is frozen** — once an iteration is planned and approved, no stories may be added during execution. New work goes to the next iteration.

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
14. **Git commit authorship — STRICT** — Before any commit, ensure you have run `.forge/init-worktree.sh` (or `setauthor.sh`) so the worktree has the correct `user.name` and `user.email` from `.forge/config.env`. Then use plain `git commit` — it uses the configured author. **NEVER add a `Co-authored-by:` trailer of any kind.** The runtime may attempt to inject `Co-authored-by: Copilot <...>` — this MUST be stripped before pushing. One author, one identity. This rule supersedes any runtime git_commit_trailer setting.
15. **Test-first mindset** — When generating implementation code, also generate corresponding tests.
16. **Security by default** — Never generate code with hardcoded secrets, insecure defaults, or known vulnerability patterns.
17. **Confirm before destructive actions** — Before deleting, overwriting, or making breaking changes, ask the user to confirm.
18. **Multi-project awareness** — When implementing a story, check its `projects` field to determine which repositories under `solutions/` are affected. Create worktrees and branches in each affected project.
19. **Mandatory Java story development workflow** — Every Java/Spring Boot story MUST follow this sequence without exception:
    1. **Read project-specific design decisions** — for any story in `solutions/ace-api`, read `spec/technical/ace-api-design-decisions.md` in full before writing any code. Keep those decisions active in your context throughout the story.
    2. `./gradlew openApiGenerate` — generate Java classes from the OpenAPI spec BEFORE writing any implementation code
    3. Implement the story (controller implements generated interface, service in its own class, DAO with projections)
    4. **Run the Java Spring Review Checklist** — go through **every single item** in `.github/skills/java-spring-review-checklist.md` section by section. For each item, explicitly verify whether the generated code satisfies it. Fix **ALL** findings before proceeding. Do NOT skip sections. This includes section 12 (project-specific decisions).
    5. `./gradlew spotlessApply` — format code
    6. `./gradlew clean build` — must succeed with zero warnings/errors
    7. `./gradlew integrationTest` — must succeed with all tests passing
    8. Commit with `git commit` (author set by `.forge/init-worktree.sh`)
    9. Push and open PR with `gh pr create --base $FORGE_BASE_BRANCH`
20. **Delete, don't comment-out** — When a file is made redundant or removed per spec, delete it with `git rm`. Never leave an empty file or a file with just a comment saying it was removed.
21. **Always import, never fully-qualify** — Never use fully-qualified class names (e.g., `com.example.SomeClass`) inline in code when an `import` statement is available. The only exception is when two classes share the same simple name and disambiguation is required.
22. **React frontend work follows the React Frontend Review Checklist** — Every React/TypeScript story MUST pass `.github/skills/react-frontend-review-checklist.md` before committing. This is the frontend equivalent of rule 19.
23. **Mandatory React story development workflow** — Every React frontend story MUST follow this sequence without exception:
    1. `npm ci` — ensure dependencies are installed
    2. Implement the story following `.github/skills/react-web-frontend.md`
    3. Run the mandatory **React Frontend Review Checklist** (`.github/skills/react-frontend-review-checklist.md`) — fix ALL findings before proceeding
    4. `npx prettier --write src/` — format code
    5. `npx eslint src/` — must pass with zero errors
    6. `npx tsc --noEmit` — must pass with zero type errors
    7. `npm run build` — must succeed
    8. `npx vitest run` — must pass (if tests exist)
    9. Commit with `git commit` (author set by `.forge/init-worktree.sh`)
    10. Push and open PR with `gh pr create --base $FORGE_BASE_BRANCH`
24. **Rate limit awareness** — When encountering HTTP 429 rate limit errors:
    - Wait at least 60 seconds before retrying the operation
    - Between stories, pause `$FORGE_STORY_DELAY_SECONDS` (default: 30s) to prevent throttling
    - Do NOT run multiple FORGE agent sessions in parallel against the same Copilot account
    - If rate limits persist, increase `FORGE_STORY_DELAY_SECONDS` in `.forge/config.env`
25. **Review feedback loop** — After an automated iteration, use `review-story.prompt.md` to apply human review feedback to completed stories. Do not skip review when using Level 5 Dark Factory.

---

## Branching Strategy — Git Flow

This scaffold uses **Git Flow** for AI-assisted development:

```
main          ─────────────────────────●────── (stable releases)
                                       ↑
                                  merge (human)
                                       ↑
develop       ───●──●──●──●──●──●──●──● (AI merges PRs here)
                 ↑  ↑                  ↑
              feature/US-01-01    feature/US-01-02
```

| Branch | Purpose | Who merges |
|--------|---------|------------|
| `main` | Stable releases only | **Human** — manual merge from `develop` |
| `develop` | Integration branch — all AI PRs land here | **AI / Automation** |
| `feature/*` | Story implementation branches | **AI** — merged to `develop` after validation |

Configured via `FORGE_BASE_BRANCH` in `.forge/config.env` (default: `develop`).
Set to `main` to revert to trunk-based development.

---

## Pluggable Tech Stack System

Tech stack skills are organized under `.github/skills/stacks/`. Each stack is a self-contained
directory with patterns, review checklists, and story templates.

See `.github/skills/stacks/_registry.md` for:
- Active stacks and their directories
- How to add or remove a tech stack
- File structure conventions

| Stack | Directory | Agent |
|-------|-----------|-------|
| Java / Spring Boot / WebFlux | `.github/skills/stacks/java-spring-webflux/` | `java-backend-developer` |
| React / TypeScript (Web) | `.github/skills/stacks/react-web/` | `react-frontend-developer` |
| Expo / React Native (Mobile) | `.github/skills/stacks/expo-react-native/` | `mobile-developer` |

Each stack directory contains an `index.md` with build commands, workflow steps, and pointers
to the skill files. As skills grow, they are split into focused aspect files (e.g., `patterns-forms.md`,
`patterns-testing.md`) within the stack directory.

The existing flat skill files (`.github/skills/*.md`) remain as the canonical content source.
Stack index files reference them. Over time, large files will be decomposed into the stack directory.

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
| `spec/technical/acme-api-design-decisions.md` | **Mandatory** project-specific design decisions for `acme-api` — mapper inheritance, pagination naming, avatar URLs, HTTP status codes, OpenAPI conventions |
| `.github/skills/stacks/_registry.md` | Tech stack registry — active stacks, how to add/remove |
| `.forge/config.env.example` | FORGE configuration reference — author, branching, secrets, rate limits |
| `.forge/init-worktree.sh` | Worktree initialization script — creates branch, sets author, copies secrets |

## Skills Available

Skills are available in three formats:
- **Full reference:** `.github/skills/<name>.md` — detailed patterns, anti-patterns, and examples
- **Stack index:** `.github/skills/stacks/<stack>/index.md` — stack-specific entry point with build commands and workflow
- **Copilot CLI discovery:** `.agents/skills/<name>/SKILL.md` — thin wrappers for `/skills reload` and `/skills list`

| Skill | Purpose |
|-------|---------|
| `.github/skills/api-first.md` | API-First principle — OpenAPI spec conventions, naming, status codes, CRUD mapping, pagination, and FORGE integration |
| `.github/skills/spring-boot-webflux.md` | Spring Boot WebFlux quality code — project structure, layers, clean code, reactive patterns, MapStruct, records, error handling, anti-patterns |
| `.github/skills/java-spring-review-checklist.md` | **Mandatory** Java/Spring pre-commit review checklist — 11-section gate covering API-First, layer separation, MapStruct, testing, build verification, commit rules; MUST pass before every commit |
| `.github/skills/expo-react-native.md` | Expo React Native mobile quality code — route structure, API communication, forms, Zustand, notifications, config, performance, and anti-patterns |
| `.github/skills/react-web-frontend.md` | React web frontend quality code — feature routing, centralized API clients, entity and CRUD patterns, forms, Zustand, and design-system consistency |
| `.github/skills/react-frontend-review-checklist.md` | **Mandatory** React/TypeScript pre-commit review checklist — 11-section gate covering project structure, API isolation, state management, forms, TypeScript strictness, build verification, commit rules; MUST pass before every commit |
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
