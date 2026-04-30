# Tech Stack Registry

> **This file lists all active tech stacks** supported by this FORGE scaffold.
> Agents, prompts, and preprocessing use this registry to determine which
> skills, checklists, templates, and patterns apply to each project.

---

## How It Works

Each tech stack is a self-contained directory under `.github/skills/stacks/<stack-name>/`.
A stack directory contains:

| File | Purpose | Required |
|------|---------|----------|
| `index.md` | Stack overview, file layout, build/validation commands, **Mandatory Development Workflow** | ✅ Yes |
| `patterns.md` | Code patterns, conventions, anti-patterns | ✅ Yes |
| `review-checklist.md` | Pre-commit mandatory review checklist | ✅ Yes |
| `story-template.md` | Story spec template with code skeletons | ✅ Yes |
| `*.md` (additional) | Supplementary aspect files (e.g., `virtualized-tables.md`) | Optional |

> **Contract:** Every `index.md` MUST contain a `## Mandatory Development Workflow` section.
> This is the authoritative step-by-step sequence Copilot follows for every story of that stack.
> The generic rule in `copilot-instructions.md` (rule 16) delegates all stack-specific workflow
> and checklist details to this section. When adding a new stack, this section is required.

When a stack grows too large, **split aspect files** from `patterns.md`:
- `patterns-reactive.md` — reactive/async patterns
- `patterns-mappers.md` — mapper conventions
- `patterns-testing.md` — testing patterns
- `patterns-forms.md` — form handling

The `index.md` file in each stack directory serves as the entry point and lists all files in that stack.

---

## Active Stacks

| Stack | Directory | Agent | Projects |
|-------|-----------|-------|----------|
| Java / Spring Boot / WebFlux | `java-spring-webflux/` | `java-backend-developer` | `citizen-report-api`, `g2sentry-api`, `jurisdiction-lookup-api` |
| React / TypeScript (Web) | `react-web/` | `react-frontend-developer` | `g2sentry-ecitizen` |
| Expo / React Native (Mobile) | `expo-react-native/` | `mobile-developer` | `citizen-police-report`, `g2sentry-guardian` |

---

## Adding a New Tech Stack

1. Create directory: `.github/skills/stacks/<stack-name>/`
2. Create required files: `index.md`, `patterns.md`, `review-checklist.md`, `story-template.md`
3. Add the stack to the **Active Stacks** table above
4. Create an agent in `.github/agents/` (if one doesn't exist)
5. Create a CLI skill wrapper in `.agents/skills/<stack-name>/SKILL.md`
6. Update `copilot-instructions.md` rules section to reference the new stack

### Template for `index.md`

```markdown
# [Stack Name] — Tech Stack Index

## Overview
[1-2 sentence description]

## Stack Files
| File | Purpose |
|------|---------|
| `patterns.md` | ... |
| `review-checklist.md` | ... |
| `story-template.md` | ... |

## Build & Validation Commands
[commands]

## Mandatory Development Workflow

1. [Step 1 — e.g., install deps / code generation]
2. Implement the story following `patterns.md`
3. Run review checklist (`review-checklist.md`) — fix ALL findings
4. [Format command]
5. [Lint/type-check commands] — must pass with zero errors
6. [Build command] — must succeed
7. [Test command] — must pass
8. Commit with `git commit` (author set by `.forge/init-worktree.sh`)
9. Push and open PR with `gh pr create --base $FORGE_BASE_BRANCH`

## Agent
`[agent-name]`
```

---

## Removing a Tech Stack

1. Remove the directory from `.github/skills/stacks/`
2. Remove from the **Active Stacks** table above
3. Optionally remove the agent and CLI skill wrapper
