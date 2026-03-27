# 🔥 FORGE Template — AI-Assisted Development with GitHub Copilot CLI

> **The professional's framework for AI-assisted software development.**
> Stop vibe coding. Start engineering with AI.

[![GitHub Copilot](https://img.shields.io/badge/GitHub_Copilot-Ready-blue?logo=github)](https://github.com/features/copilot)
[![FORGE Framework](https://img.shields.io/badge/FORGE-Framework-orange)](https://www.tomsguide.com/ai/i-tested-forge-a-new-ai-coding-workflow-that-actually-works)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## What Is This?

The **FORGE Template** is a production-quality project scaffold for building software using **GitHub Copilot CLI** as an AI-assisted development partner. It implements the FORGE methodology — a structured, specification-driven approach to AI-assisted software development that targets Dan Shapiro's Level 4 (Engineered Vibe) and Level 5 (Dark Factory) coding maturity.

Instead of "describe what you want and hope for the best," FORGE gives you:

| Without FORGE | With FORGE |
|--------------|-----------|
| Vague prompts → inconsistent code | Structured specs → precise, traceable code |
| Single AI agent doing everything | Specialized agent roles (BA, Architect, Dev, QA) |
| No process → no reproducibility | Full SDLC loop → repeatable, auditable process |
| Manual, one-at-a-time generation | Dark Factory: parallel fleet agents via git worktrees |
| Code disconnected from requirements | Every line traces back to a spec and a story |

---

## Key Concepts

### 🔥 FORGE Framework (Frame → Obstruct → Reconstruct → Generate → Edit)

FORGE is a five-phase AI-assisted SDLC methodology:

| Phase | What Happens | Output |
|-------|-------------|--------|
| **Frame** | Interview stakeholders. Define vision, goals, scope, actors. | `spec/business/frame.md` |
| **Obstruct** | Stress-test the frame. Find risks, gaps, assumptions, unknowns. | `spec/business/obstruct-report.md` |
| **Reconstruct** | Resolve obstructions. Design architecture. Write full specs. | Full `spec/business/` + `spec/technical/` |
| **Generate** | Build code, tests, infrastructure. Story by story. | Code in `solutions/` |
| **Edit** | Review, validate, refactor, polish. Go/No-Go decision. | Validated release candidate |

FORGE ensures AI agents are always working from precise, reviewed specifications — not improvising from vague prompts.

→ Full guide: [`.github/instructions/forge-framework.md`](.github/instructions/forge-framework.md)

---

### 🎯 5 Levels of Vibe Coding (Dan Shapiro)

Dan Shapiro's maturity model for AI-assisted development:

| Level | Name | Description | Human Role |
|-------|------|-------------|-----------|
| 1 | **Pure Vibe** | Casual prompts, no structure | Full developer |
| 2 | **Directed Vibe** | Rough requirements, some guidance | Active developer |
| 3 | **Structured Vibe** | Templates and patterns | Technical lead |
| 4 | **Engineered Vibe** | Formal specs, multiple agents, SDLC | Reviewer/approver |
| 5 | **Dark Factory** | Fully automated, parallel fleets | Product manager |

**This template targets Level 4-5.** It provides all the scaffolding for Level 4 from day one, with Dark Factory (Level 5) capabilities available when your process matures.

→ Full guide: [`.github/instructions/5-levels-vibe-coding.md`](.github/instructions/5-levels-vibe-coding.md)

---

### 🏭 Dark Factory Model (StrongDM)

Inspired by the manufacturing concept of lights-out factories — facilities that run fully automated with no human workers on the floor.

In software, the Dark Factory means:
- **Parallel agent fleets** work simultaneously on multiple stories
- **Git worktrees** isolate each agent's work on its own branch
- **Automated quality gates** validate each story before human review
- **Human checkpoints** occur only at iteration boundaries (before/after each sprint)
- **Autonomous execution** within each iteration

```
Iteration Start (Human approves plan)
    ↓
Dark Factory executes all stories in parallel
    ├── Backend Agent → STORY-001 (worktree: feature/STORY-001)
    ├── Frontend Agent → STORY-002 (worktree: feature/STORY-002)
    ├── Mobile Agent → STORY-003 (worktree: feature/STORY-003)
    └── DevOps Agent → STORY-004 (worktree: feature/STORY-004)
    ↓
Quality gates pass → Stories complete
    ↓
Iteration End (Human reviews report, decides Go/No-Go)
```

→ Full guide: [`.github/instructions/dark-factory.md`](.github/instructions/dark-factory.md)

---

### 📋 OpenSpec.dev Format

All specifications in this template use **OpenSpec** — a structured, AI-readable specification format that provides:
- YAML front matter for machine-readable metadata
- Standardized sections: overview, actors, user stories, acceptance criteria, NFRs
- Full traceability from business goal to code to test
- Version control friendly (plain markdown, diffs cleanly)

Every spec follows: `spec_id` → `title` → `status` → structured sections.

→ Full guide: [`.github/instructions/openspec-format.md`](.github/instructions/openspec-format.md)

---

### 🌿 Git Worktrees for Parallel Agents

Git worktrees allow multiple working directories from the same repository simultaneously — each on a different branch. This is how the Dark Factory runs parallel agents:

```bash
# Create isolated environments for parallel agent work
git worktree add worktrees/story-001 -b feature/STORY-001-auth
git worktree add worktrees/story-002 -b feature/STORY-002-profile-ui
git worktree add worktrees/story-003 -b feature/STORY-003-ios-screens

# Agents work simultaneously in their respective worktrees
# No branch switching, no stashing, no conflicts

# Clean up after merging
git worktree prune
```

Requires Git 2.5+ (included in all modern Git installations).

---

## Project Structure

```
the-forge-template/
│
├── .github/
│   ├── instructions/          ← Workspace instructions for Copilot
│   │   ├── copilot-instructions.md    ← 🚀 ENTRY POINT — Start here
│   │   ├── forge-framework.md         ← Full FORGE methodology guide
│   │   ├── sdlc-flow.md               ← Interactive SDLC flow stages
│   │   ├── 5-levels-vibe-coding.md    ← Dan Shapiro's maturity model
│   │   ├── dark-factory.md            ← Dark Factory model guide
│   │   └── openspec-format.md         ← OpenSpec specification format
│   │
│   ├── prompts/               ← Reusable Copilot prompt files (.prompt.md)
│   │   ├── forge/
│   │   │   ├── 01-frame.prompt.md         ← FORGE Phase 1: Frame
│   │   │   ├── 02-obstruct.prompt.md      ← FORGE Phase 2: Obstruct
│   │   │   ├── 03-reconstruct.prompt.md   ← FORGE Phase 3: Reconstruct
│   │   │   ├── 04-generate.prompt.md      ← FORGE Phase 4: Generate
│   │   │   └── 05-edit.prompt.md          ← FORGE Phase 5: Edit
│   │   ├── project/
│   │   │   ├── greenfield-init.prompt.md      ← Start a new project
│   │   │   └── brownfield-analysis.prompt.md  ← Analyze existing code
│   │   ├── backlog/
│   │   │   ├── story-breakdown.prompt.md      ← Break epics into stories
│   │   │   ├── backlog-grooming.prompt.md     ← Estimate and ready stories
│   │   │   └── iteration-planning.prompt.md   ← Plan a sprint
│   │   └── dark-factory/
│   │       ├── run-iteration.prompt.md        ← Execute iteration autonomously
│   │       └── assess-iteration.prompt.md     ← Review and Go/No-Go
│   │
│   ├── agents/                ← Agent role definitions
│   │   ├── solution-architect.md
│   │   ├── business-analyst.md
│   │   ├── project-manager.md
│   │   ├── scrum-master.md
│   │   ├── tech-lead.md
│   │   ├── java-backend-developer.md
│   │   ├── react-frontend-developer.md
│   │   ├── mobile-developer.md
│   │   ├── devops-engineer.md
│   │   └── qa-engineer.md
│   │
│   └── skills/                ← Reusable skill definitions
│       ├── api-first.md
│       ├── spring-boot-webflux.md
│       ├── expo-react-native.md
│       ├── react-web-frontend.md
│       ├── react-virtualized-crud-tables.md
│       ├── aws-terraform-jenkins-infrastructure.md
│       ├── aws-ecs-fargate-runtime-deployments.md
│       ├── code-review.md
│       ├── refactoring.md
│       ├── testing.md
│       ├── documentation.md
│       └── openspec-authoring.md
│
├── spec/                      ← All project specifications (OpenSpec format)
│   ├── README.md              ← Spec folder guide
│   ├── business/              ← Business requirements and stories
│   ├── technical/             ← Architecture, APIs, data model, infra
│   ├── validation/            ← Test strategy and acceptance criteria
│   └── iterations/            ← Per-iteration plans and reports
│
└── solutions/                 ← Project repositories live here (cloned or generated)
    └── .gitkeep               ← Empty; populated during Brownfield clone or Generate phase
```

---

## Prerequisites

### Required
- **GitHub Copilot** — Active subscription with Copilot CLI access
  - Install CLI: `gh extension install github/gh-copilot`
- **Git 2.5+** — For git worktree support (Dark Factory mode)
  - Check: `git --version`

### By Technology Layer (install what you need)

**Backend (Java/Spring Boot):**
- Java 25+ — [Adoptium Temurin](https://adoptium.net/) recommended
- Gradle 9.4+ (or use the included `gradlew` wrapper)
- Docker Desktop — for Testcontainers

**Frontend (React):**
- Node.js 24+
- npm 11+

**Mobile (Expo React Native):**
- Node.js 24+
- Expo CLI: `npm install -g expo`
- Android Studio (for Android emulator) and/or Xcode (for iOS simulator, macOS only)

**Infrastructure (AWS/Terraform/Kubernetes):**
- AWS CLI v2 + configured credentials
- Terraform 1.6+
- kubectl
- Helm 3+

**CI/CD (Jenkins):**
- Jenkins 2.500+ (LTS)
- Jenkins plugins: Pipeline, Kubernetes, Docker, Blue Ocean

---

## Quick Start

Simple CLI runbook: [`COPILOT-CLI-RUNBOOK.md`](COPILOT-CLI-RUNBOOK.md)

### Model Policy

- Default to `GPT-5 Mini` for routine work: backlog grooming, iteration planning, generation, edits, tests, refactors, docs, and implementation.
- Use a premium model only for high-level analysis: greenfield framing, brownfield analysis, large architecture trade-offs, or explicit user request.
- After analysis is complete, switch back to `GPT-5 Mini` before continuing execution work.

### Mode 1: Greenfield (New Project)

**Start a brand-new project from scratch.**

1. **Open this repository in VS Code** with GitHub Copilot extension enabled

2. **Run the Greenfield Initializer:**
   ```
   @workspace Run .github/prompts/project/greenfield-init.prompt.md
   ```

3. **Answer Copilot's questions** about your project (name, domain, goals, stack preferences)

4. **Follow the FORGE flow** — Copilot will guide you through:
   - Frame → `spec/business/frame.md` produced
   - Obstruct → risks and gaps identified
   - Reconstruct → full specs in `spec/business/` and `spec/technical/`

5. **Create your backlog:**
   ```
   @workspace Run .github/prompts/backlog/story-breakdown.prompt.md
   @workspace Run .github/prompts/backlog/backlog-grooming.prompt.md
   @workspace Run .github/prompts/backlog/iteration-planning.prompt.md
   ```

6. **Generate your first iteration:**
   - Interactive mode (one story at a time):
     ```
     @workspace Run .github/prompts/forge/04-generate.prompt.md
     ```
   - Dark Factory mode (all stories in parallel):
     ```
     @workspace Run .github/prompts/dark-factory/run-iteration.prompt.md
     ```

7. **Review and release:**
   ```
   @workspace Run .github/prompts/dark-factory/assess-iteration.prompt.md
   ```

---

### Mode 2: Brownfield (Existing Codebase)

**Bring an existing project into the FORGE workflow.**

1. **Clone your existing project repositories into `solutions/`:**
   ```bash
   cd solutions
   git clone https://github.com/your-org/your-api
   git clone https://github.com/your-org/your-web
   cd ..
   ```

2. **Run the Brownfield Analysis:**
   ```
   @workspace Run .github/prompts/project/brownfield-analysis.prompt.md
   ```
   Copilot will scan your codebase and generate:
   - `spec/technical/architecture.md` — reverse-engineered architecture
   - `spec/technical/api-contracts.md` — documented API surface
   - `spec/technical/data-model.md` — entity discovery
   - `spec/business/brownfield-discovery.md` — full discovery report

3. **Review the generated specs** — Correct any inaccuracies Copilot may have inferred

4. **Run the Obstruct phase** to identify improvement opportunities:
   ```
   @workspace Run .github/prompts/forge/02-obstruct.prompt.md
   ```

5. **Plan your first improvement iteration:**
   ```
   @workspace Run .github/prompts/backlog/story-breakdown.prompt.md
   ```

---

## SDLC Flow

```
Discovery → Specification → Backlog → Grooming → Iteration Planning → Development → Review/QA → Release
     ↑                                                                                              │
     └──────────────────────────── Next Iteration ────────────────────────────────────────────────┘
```

| Stage | Copilot Prompt | Agent Roles | Artifacts |
|-------|---------------|-------------|-----------|
| Discovery | `project/greenfield-init` or `project/brownfield-analysis` | BA, SA, PM | Discovery notes, initial epics |
| Specification | `forge/01-frame` → `02-obstruct` → `03-reconstruct` | BA, SA, TL | Full spec set |
| Backlog | `backlog/story-breakdown` | BA, SM | `spec/business/backlog.md` |
| Grooming | `backlog/backlog-grooming` | SM, TL, BA | Estimated, Ready backlog |
| Iteration Planning | `backlog/iteration-planning` | SM, PM, TL | Iteration plan + story specs |
| Development | `forge/04-generate` or `dark-factory/run-iteration` | Dev agents | Code in `solutions/` |
| Review/QA | `forge/05-edit` | TL, QA | QA report, release candidate |
| Release | (manual + DevOps agent) | DevOps, TL | Deployed release |

Human checkpoints occur after every stage. The user reviews artifacts and decides whether to proceed.

→ Full guide: [`.github/instructions/sdlc-flow.md`](.github/instructions/sdlc-flow.md)

---

## Agent Roles

| Agent | File | Responsibilities |
|-------|------|-----------------|
| **Solution Architect** | `agents/solution-architect.md` | System design, ADRs, technology decisions |
| **Business Analyst** | `agents/business-analyst.md` | Requirements, user stories, acceptance criteria |
| **Project Manager** | `agents/project-manager.md` | Timeline, risk, stakeholder communication |
| **Scrum Master** | `agents/scrum-master.md` | Agile ceremonies, backlog health, flow |
| **Tech Lead** | `agents/tech-lead.md` | Code standards, architecture compliance, reviews |
| **Java Backend Dev** | `agents/java-backend-developer.md` | Spring Boot 3, WebFlux, Spring Cloud |
| **React Frontend Dev** | `agents/react-frontend-developer.md` | React web frontends, TypeScript, TanStack Query, shadcn/ui |
| **Mobile Developer** | `agents/mobile-developer.md` | Expo React Native, Android + iOS |
| **DevOps Engineer** | `agents/devops-engineer.md` | AWS infrastructure, Terraform, Jenkins, CI/CD |
| **QA Engineer** | `agents/qa-engineer.md` | Testing strategy, automation, quality gates |

### Invoking an Agent
```
@workspace Read .github/agents/java-backend-developer.md and act as this agent for this session.
```

---

## Technology Stack

This template is designed for (but not limited to):

| Layer | Technology |
|-------|-----------|
| Backend | Java 21 · Spring Boot 3.x · Spring WebFlux · Spring Cloud |
| Frontend | React · TypeScript · Vite · React Router · TanStack Query · Zustand · Tailwind CSS · shadcn/ui |
| Mobile | Expo SDK · React Native · TypeScript · Expo Router |
| Database | PostgreSQL (R2DBC) · DynamoDB · Redis |
| Cloud | AWS (EKS, RDS, S3, ElastiCache, Route 53, ACM, Secrets Manager) |
| IaC | Terraform 1.6+ · Kustomize · Helm 3 |
| CI/CD | Jenkins (declarative pipelines) · Docker · ECR |
| Orchestration | Kubernetes (EKS) |
| Observability | CloudWatch · X-Ray · Prometheus · Grafana |

You can adapt the stack — the FORGE process works with any technology. Agent files contain the tech-specific knowledge; the SDLC flow is technology-agnostic.

---

## Dark Factory Mode

Dark Factory is the Level 5 autonomous execution mode. Activate it when:
- Your specs are mature (high-quality, unambiguous)
- Your team has confidence in the spec-to-code pipeline
- You want maximum throughput across a known backlog

### To Activate
```
@workspace Run .github/prompts/dark-factory/run-iteration.prompt.md
```

### What Happens
1. Copilot reads the iteration plan from `spec/iterations/iteration-N/plan.md`
2. Creates a git worktree for each story
3. Assigns each worktree to the appropriate agent role
4. Executes all stories (in parallel where dependencies allow)
5. Runs quality gates after each story (tests, lint, build, security scan)
6. Updates `spec/iterations/iteration-N/status.md` continuously
7. Presents a consolidated report for human review

### Quality Gates (automated)
- ✅ Unit tests: 100% pass
- ✅ Linter: 0 errors
- ✅ Build: successful
- ✅ Security scan: no new critical/high CVEs
- ✅ `terraform validate`: passes (if IaC changed)

→ Full guide: [`.github/instructions/dark-factory.md`](.github/instructions/dark-factory.md)

---

## Specification Format

All specs follow **OpenSpec** — structured markdown with YAML front matter:

```yaml
---
spec_id: SPEC-001
title: "My Project — Frame Document"
version: "0.1.0"
status: approved
type: business
---

## Overview
## Actors
## User Stories
## Acceptance Criteria
## Non-Functional Requirements
## Constraints
## Open Questions
```

→ Full format guide: [`.github/instructions/openspec-format.md`](.github/instructions/openspec-format.md)
→ Authoring skill: [`.github/skills/openspec-authoring.md`](.github/skills/openspec-authoring.md)
→ API-First skill: [`.github/skills/api-first.md`](.github/skills/api-first.md)
→ Spring Boot WebFlux quality skill: [`.github/skills/spring-boot-webflux.md`](.github/skills/spring-boot-webflux.md)
→ Expo React Native quality skill: [`.github/skills/expo-react-native.md`](.github/skills/expo-react-native.md)
→ React web frontend quality skill: [`.github/skills/react-web-frontend.md`](.github/skills/react-web-frontend.md)
→ React virtualized CRUD tables skill: [`.github/skills/react-virtualized-crud-tables.md`](.github/skills/react-virtualized-crud-tables.md)
→ AWS Terraform Jenkins infrastructure skill: [`.github/skills/aws-terraform-jenkins-infrastructure.md`](.github/skills/aws-terraform-jenkins-infrastructure.md)
→ AWS ECS/Fargate runtime and deployments skill: [`.github/skills/aws-ecs-fargate-runtime-deployments.md`](.github/skills/aws-ecs-fargate-runtime-deployments.md)
→ Spec folder guide: [`spec/README.md`](spec/README.md)

---

## References & Credits

### FORGE Framework
- **Original Article:** ["I tested FORGE, a new AI coding workflow that actually works"](https://www.tomsguide.com/ai/i-tested-forge-a-new-ai-coding-workflow-that-actually-works) — Tom's Guide
- The FORGE acronym and methodology were developed for Claude Code and adapted here for GitHub Copilot CLI

### 5 Levels of Vibe Coding
- **Dan Shapiro** (CEO of Glowforge) — articulated the five-level maturity model for AI-assisted development
- Framework helps teams understand where they are and where to grow

### Dark Factory Model
- **StrongDM** — popularized the "Dark Factory" concept applied to software development
- Inspired by lights-out manufacturing facilities operating without human workers on the floor

### OpenSpec.dev
- **[openspec.dev](https://openspec.dev)** — structured specification format designed for AI-readable, version-controllable specs
- This template's spec format is inspired by and compatible with the OpenSpec convention

### Related Projects & Inspiration
- **[safe-agentic-workflow (bybren-llc)](https://github.com/bybren-llc/safe-agentic-workflow)** — Safe patterns for agentic AI workflows, inspiration for human checkpoints
- **[fspec (sengac)](https://github.com/sengac/fspec)** — Functional specification format ideas informing the OpenSpec approach used here
- **[Conventional Commits](https://www.conventionalcommits.org/)** — Commit message convention used in Generate phase
- **[Architecture Decision Records (ADRs)](https://adr.github.io/)** — Michael Nygard's ADR format used in technical specs
- **[Keep a Changelog](https://keepachangelog.com/)** — CHANGELOG format convention
- **[OWASP ASVS](https://owasp.org/www-project-application-security-verification-standard/)** — Security standards referenced in NFRs
- **[The Twelve-Factor App](https://12factor.net/)** — Application design principles followed in DevOps patterns

---

## Contributing

This is a template repository. To contribute improvements:

1. Fork the repository
2. Create a feature branch
3. Make your changes following the existing patterns
4. Submit a pull request with a description of what you improved and why

Areas particularly welcome for contribution:
- Additional agent roles (Data Engineer, ML Engineer, Security Engineer)
- Technology stack variants (Python/FastAPI, Go, .NET)
- Additional skill files
- Cloud provider variants (GCP, Azure)
- CI/CD platform variants (GitHub Actions, GitLab CI, CircleCI)

---

## License

MIT License — see [LICENSE](LICENSE) file for details.

---

<div align="center">

**Built for engineers who take AI-assisted development seriously.**

*FORGE · Dark Factory · OpenSpec · GitHub Copilot CLI*

</div>
