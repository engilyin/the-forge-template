# FORGE Framework — Complete Reference

> **FORGE** = **F**rame → **O**bstruct → **R**econstruct → **G**enerate → **E**dit
>
> An AI-assisted SDLC methodology originally designed for Claude Code and adapted for GitHub Copilot CLI.

---

## Overview

FORGE is a structured methodology that transforms the "vibe coding" instinct into a disciplined, repeatable, AI-assisted software development lifecycle. Rather than jumping straight to code generation, FORGE ensures that every artifact produced by an AI agent is grounded in a well-defined specification that has been deliberately framed, stress-tested, and refined.

The five phases are **sequential but iterative** — you can return to earlier phases as new information surfaces, just as in agile development. The key insight is that **AI agents are most effective when given precise, structured context**, and FORGE exists to produce exactly that context.

---

## Phase 1: FRAME

### Purpose
Define the **shape** of what you are building. This is the project charter, the product vision, and the initial scope — captured in a form that both humans and AI agents can act upon.

### What Happens
- The **Business Analyst** agent leads the session with support from the **Solution Architect**
- The user is interviewed with structured clarifying questions covering:
  - Problem statement: What pain are we solving? For whom?
  - Vision: What does success look like in 6 months? 12 months?
  - Constraints: Budget, timeline, team, existing systems, compliance requirements
  - Non-negotiables: What must be true? What must never happen?
  - Technology preferences: Existing stack, cloud provider, licensing requirements
  - Key actors: Who uses this system? What are their goals?
- A **Frame Document** is produced in `spec/business/frame.md`

### Output Artifacts
- `spec/business/frame.md` — Project frame document (OpenSpec format)
- `spec/business/actors.md` — Key actors and their goals
- Initial list of epics and feature areas

### SDLC Mapping
This phase maps to **Project Initiation** and early **Requirements Discovery** in a traditional SDLC, or to the **Product Vision** and **Roadmap** activities in Agile.

### Copilot Prompt
```
Use: .github/prompts/forge/01-frame.prompt.md
```

### Success Criteria
- [ ] Problem statement is clear and agreed upon
- [ ] Key actors are identified with primary goals
- [ ] Scope is bounded (what's in, what's out)
- [ ] At least 3-5 epics are identified
- [ ] Constraints and non-negotiables are documented
- [ ] Stakeholders have reviewed and approved the Frame document

---

## Phase 2: OBSTRUCT

### Purpose
Deliberately **stress-test** the Frame document by identifying everything that could block, delay, or derail the project. This is structured pessimism in service of better planning.

### What Happens
- The **Solution Architect** leads with input from all other agents
- Each element of the Frame document is challenged:
  - What do we not know yet? (Unknowns)
  - What could go wrong? (Risks)
  - What are we assuming that might be wrong? (Assumptions)
  - What's missing from the spec? (Gaps)
  - What external dependencies could block us? (Blockers)
  - What technical challenges will emerge? (Technical Debt / Spikes)
- An **Obstruct Report** is produced

### Output Artifacts
- `spec/business/obstruct-report.md` — Full risk, gap, assumption, and blocker register
- `spec/technical/technical-spikes.md` — List of technical unknowns requiring investigation
- Updated `spec/business/frame.md` with flags on uncertain areas

### SDLC Mapping
This phase maps to **Risk Assessment**, **Spike Planning**, and **Definition of Ready** activities. It also supports the **Non-Functional Requirements** discovery process.

### Copilot Prompt
```
Use: .github/prompts/forge/02-obstruct.prompt.md
```

### Success Criteria
- [ ] All assumptions from the Frame document are listed and challenged
- [ ] Risks are rated (likelihood × impact)
- [ ] Blockers have owners and mitigation plans
- [ ] Technical spikes are identified and scoped
- [ ] Gaps in requirements are flagged for resolution in Reconstruct

---

## Phase 3: RECONSTRUCT

### Purpose
**Resolve** the obstructions identified in Phase 2. This is the phase where specifications get refined, assumptions get validated, spikes get resolved, and the project gets a solid technical and business foundation.

### What Happens
- All agents collaborate in this phase
- Each obstruction from the Obstruct Report is addressed:
  - Unknowns → Research or spike → Decision
  - Risks → Mitigation plan → Updated constraints
  - Gaps → Additional requirements gathering → Spec updates
  - Blockers → Resolution plan or scope adjustment
- Business specs are finalized in `spec/business/`
- Technical architecture is designed and documented in `spec/technical/`
- User stories are written (or refined) with acceptance criteria
- The system is ready for generation

### Output Artifacts
- Finalized `spec/business/requirements.md`
- `spec/technical/architecture.md` — High-level system architecture
- `spec/technical/api-contracts.md` — API interface definitions
- `spec/technical/data-model.md` — Data entities and relationships
- `spec/technical/infrastructure.md` — Cloud/IaC design
- `spec/business/user-stories.md` — Full backlog of user stories
- `spec/validation/acceptance-criteria.md` — QA acceptance criteria

### SDLC Mapping
This phase maps to **System Design**, **Detailed Requirements**, and **Sprint 0** activities. It produces the Definition of Done and the initial product backlog.

### Copilot Prompt
```
Use: .github/prompts/forge/03-reconstruct.prompt.md
```

### Success Criteria
- [ ] All obstructions from Phase 2 are resolved or have accepted mitigation
- [ ] Architecture is documented with key decisions as ADRs
- [ ] All epics are broken into user stories with acceptance criteria
- [ ] API contracts are defined for all service interfaces
- [ ] Data model is documented
- [ ] Infrastructure design is complete
- [ ] Team has agreed the specs are ready for development

---

## Phase 4: GENERATE

### Purpose
**Produce** the software artifacts — code, infrastructure, tests, documentation — based on the specifications created in Phases 1-3. This is where AI agents do the heavy lifting.

### What Happens
- Developer agents (**Java Backend**, **React Frontend**, **Mobile**, **DevOps**) take individual user stories and implement them
- Each story generates:
  - Application code with inline documentation
  - Unit tests
  - Integration tests (where applicable)
  - Infrastructure-as-Code changes (Terraform, Kubernetes manifests)
  - CI/CD pipeline updates
  - API documentation updates
- In **Dark Factory mode**, stories are distributed across parallel git worktrees and worked simultaneously by a fleet of agents
- In **interactive mode**, stories are worked one at a time with human review between each

### Output Artifacts
- Source code in `solution/` (organized by component)
- Test suites for each component
- Terraform modules in `solution/infra/`
- Kubernetes manifests in `solution/k8s/`
- Jenkins pipeline definitions in `solution/ci/`
- Updated API documentation

### SDLC Mapping
This phase maps to **Sprint Execution** — the development phase. Each iteration through Generate corresponds to one sprint.

### Copilot Prompt
```
Use: .github/prompts/forge/04-generate.prompt.md
```

### Success Criteria
- [ ] All stories in the iteration are implemented
- [ ] Unit test coverage meets threshold (≥80%)
- [ ] Code compiles and all tests pass
- [ ] Infrastructure changes are valid (terraform validate)
- [ ] No hardcoded secrets or security vulnerabilities
- [ ] Code review has been completed

---

## Phase 5: EDIT

### Purpose
**Refine and polish** all artifacts produced in Phase 4. Catch what was missed. Improve what was rushed. Validate that the implementation matches the specification.

### What Happens
- The **Tech Lead** and **QA Engineer** agents lead this phase
- Activities include:
  - Code review against standards and specs
  - Refactoring for readability, performance, and maintainability
  - Security review (SAST, secret scanning, dependency auditing)
  - Integration testing across components
  - Performance testing for critical paths
  - Documentation review and improvement
  - Acceptance criteria validation
- A **Release Candidate** is produced

### Output Artifacts
- Refactored source code
- Code review reports
- QA test reports in `spec/validation/`
- Updated documentation
- Release notes draft
- Go/No-Go recommendation for release

### SDLC Mapping
This phase maps to **Sprint Review**, **QA**, **Code Review**, and **Release Preparation** activities.

### Copilot Prompt
```
Use: .github/prompts/forge/05-edit.prompt.md
```

### Success Criteria
- [ ] All code review feedback has been addressed
- [ ] All acceptance criteria are met and validated
- [ ] Security review passed (no critical/high findings unaddressed)
- [ ] Integration tests pass
- [ ] Documentation is up to date
- [ ] Release notes are drafted
- [ ] Go/No-Go decision made by stakeholders

---

## FORGE Iteration Model

FORGE is not a one-time waterfall. Each **iteration** of the Generate → Edit cycle maps to an Agile sprint. The Frame → Obstruct → Reconstruct cycle maps to initial project setup and re-runs whenever significant new work is needed.

```
Frame ──► Obstruct ──► Reconstruct
                           │
                    ┌──────▼──────┐
                    │  Backlog    │
                    │  Grooming   │
                    └──────┬──────┘
                           │
              ┌────────────▼────────────┐
              │  Iteration Planning      │
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  Generate (Sprint)       │◄──── Dark Factory Fleet
              └────────────┬────────────┘
                           │
              ┌────────────▼────────────┐
              │  Edit (Review/QA)        │
              └────────────┬────────────┘
                           │
                    ┌──────▼──────┐
                    │  Release?   │──── Yes ──► Deploy
                    └──────┬──────┘
                           │ No
                    ┌──────▼──────┐
                    │  Next       │
                    │  Iteration  │
                    └─────────────┘
```

---

## Using FORGE with GitHub Copilot CLI

### Interactive Mode (Levels 3-4)
Use Copilot chat to walk through each phase manually. Reference prompts explicitly:
```
@workspace Run .github/prompts/forge/01-frame.prompt.md
```

### Dark Factory Mode (Level 5)
Trigger autonomous parallel execution using:
```
@workspace Run .github/prompts/dark-factory/run-iteration.prompt.md
```

This mode uses git worktrees to spin up parallel agent instances, each working on a different story simultaneously. See `.github/instructions/dark-factory.md` for details.

---

## FORGE vs. Traditional SDLC

| FORGE Phase | Traditional SDLC Equivalent | Agile Equivalent |
|-------------|----------------------------|-----------------|
| Frame | Project Initiation, Vision Doc | Product Vision, Roadmap |
| Obstruct | Risk Assessment, Gap Analysis | Spike Planning, Impediment Log |
| Reconstruct | System Design, Detailed Requirements | Sprint 0, Backlog Creation |
| Generate | Development | Sprint Execution |
| Edit | QA, Code Review, UAT | Sprint Review, Definition of Done |
