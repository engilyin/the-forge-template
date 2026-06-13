# Tech Stack Registry

> **This file lists all active implementation tech stacks** supported by this FORGE scaffold.
> Agents, prompts, and preprocessing use this registry to determine which
> stack-local workflow/checklist/template files apply to each project.

---

## How It Works

Each tech stack is a self-contained directory under `.github/skills/stacks/<stack-name>/`.
A stack directory contains:

| File | Purpose | Required |
|------|---------|----------|
| `patterns.md` | Code patterns, conventions, anti-patterns | ✅ Yes |
| `review-checklist.md` | Pre-commit mandatory review checklist | ✅ Yes |
| `story-template.md` | Story spec template with code skeletons | ✅ Yes |
| `*.md` (additional) | Supplementary aspect files (e.g., `virtualized-tables.md`) | Optional |

When a stack grows too large, split aspect files from `patterns.md`:
- `patterns-reactive.md` — reactive/async patterns
- `patterns-mappers.md` — mapper conventions
- `patterns-testing.md` — testing patterns
- `patterns-forms.md` — form handling

Shared knowledge that applies across stacks (API design, spec authoring, testing strategy,
documentation, architecture as code) belongs in `.github/skills/domains/`.

## Stack vs Domain Rule

- Use a **stack** for runtime/framework-specific implementation workflow.
- Use a **domain** for reusable knowledge that can be consumed by multiple stacks.
- Stack canonical files (`patterns.md`, `review-checklist.md`, `story-template.md`) should link to applicable domain skills.

## Cross-Tool Compatibility

To keep stack skills loadable across VS Code GitHub Copilot addon, Copilot CLI, and Claude Code workflows:

- Use repository-relative paths (no editor-specific URI schemes)
- Keep the required stack files present in every stack directory
- Keep `.agents/skills/*/SKILL.md` wrappers pointing to canonical files in `.github/skills/`
- Keep prompt references stable (`.github/skills/stacks/<stack>/patterns.md` and `review-checklist.md`)
- Keep `.github/skills/catalog.yaml` in sync with stack/domain registries

---

## Active Stacks

| Stack | Directory | Agent | Projects |
|-------|-----------|-------|----------|
| Java / Spring Boot / WebFlux | `java-spring-webflux/` | `java-backend-developer` | `citizen-report-api`, `g2sentry-api`, `jurisdiction-lookup-api` |
| React / TypeScript (Web) | `react-web/` | `react-frontend-developer` | `g2sentry-ecitizen` |
| Expo / React Native (Mobile) | `expo-react-native/` | `mobile-developer` | `citizen-police-report`, `g2sentry-guardian` |

## Shared Domains Referenced By Stacks

Use `.github/skills/domains/_registry.md` as the source for cross-stack capabilities.

---

## Adding a New Tech Stack

1. Create directory: `.github/skills/stacks/<stack-name>/`
2. Create required files: `patterns.md`, `review-checklist.md`, `story-template.md`
3. Add the stack to the **Active Stacks** table above
4. Reference applicable domains from `.github/skills/domains/_registry.md` in stack files directly
5. Create an agent in `.github/agents/` (if one doesn't exist)
6. Create a CLI skill wrapper in `.agents/skills/<stack-name>/SKILL.md`
7. Update `.github/skills/catalog.yaml`
8. Update `copilot-instructions.md` rules section to reference the new stack when needed

---

## Removing a Tech Stack

1. Remove the directory from `.github/skills/stacks/`
2. Remove from the **Active Stacks** table above
3. Remove it from `.github/skills/catalog.yaml`
4. Optionally remove the agent and CLI skill wrapper
