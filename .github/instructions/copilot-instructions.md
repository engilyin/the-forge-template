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
  skills/             ← Reusable skill definitions (review, testing, docs, etc.)

spec/
  business/           ← Business specs, Frame documents, user stories
  technical/          ← Technical specs, architecture decisions, API contracts
  validation/         ← QA plans, acceptance criteria, test reports

solution/             ← Your project code lives here (greenfield output or brownfield input)
```

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
- **DevOps Engineer** — AWS, Terraform, Jenkins, Kubernetes
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
5. **Agent fidelity** — When acting as an agent, stay in that role. Do not conflate responsibilities.
6. **Document decisions** — Every significant decision (architectural, product, technical) must be recorded as an ADR or spec entry.
7. **Small, reviewable commits** — Generate code in small, logically coherent units. Each story = one branch + one PR.
8. **Test-first mindset** — When generating implementation code, also generate corresponding tests.
9. **Security by default** — Never generate code with hardcoded secrets, insecure defaults, or known vulnerability patterns.
10. **Confirm before destructive actions** — Before deleting, overwriting, or making breaking changes, ask the user to confirm.

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
