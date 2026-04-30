# Dan Shapiro's 5 Levels of Vibe Coding

> This document describes Dan Shapiro's "5 Levels of Vibe Coding" framework and explains how the FORGE template targets Levels 4 and 5.

---

## What Is "Vibe Coding"?

"Vibe coding" — a term popularized in the AI developer community — refers to the practice of using AI coding assistants to generate software based on natural language descriptions, often without the developer writing every line of code manually. At its most raw, it's "just describe what you want and see what comes out." At its most sophisticated, it becomes a disciplined, specification-driven engineering methodology.

Dan Shapiro (CEO of Glowforge) articulated a five-level maturity model for vibe coding that captures the spectrum from pure improvisation to fully automated, AI-driven software factories.

---

## Level 1: Pure Vibe

### Description
The developer describes a feature to an AI assistant in casual, conversational language with no prior planning, no specification, and no structure. They accept what the AI produces, iterate if something breaks, and ship when it seems to work.

### Characteristics
- No upfront requirements or design
- Output is unpredictable and often inconsistent
- Changes are made by re-prompting or editing directly
- No tests (or tests are also generated ad-hoc)
- No documentation
- Technical debt accumulates rapidly

### Who Does This
- Solo hackers, students, rapid prototypers
- Exploratory coding, throwaway demos
- Weekend projects with no production intent

### Risks
- Code is often brittle and non-maintainable
- Security vulnerabilities are common
- The AI "hallucinates" requirements that weren't specified
- Works fine for small scripts; fails badly for production software

### FORGE Equivalent
None — Pure Vibe has no FORGE equivalent. FORGE begins at Level 2.

---

## Level 2: Directed Vibe

### Description
The developer provides some direction before prompting — a rough outline, a list of requirements in plain text, or a basic architecture sketch. They guide the AI more intentionally but still lack formal structure.

### Characteristics
- Informal requirements (often a single markdown file or README)
- Some thought given to architecture before coding starts
- AI is given context but it's unstructured
- Testing is an afterthought or manual
- Documentation is sparse

### Who Does This
- Experienced developers using AI to accelerate familiar work
- Small teams moving fast on well-understood domains
- Startups building MVPs

### Risks
- Requirements drift as the AI interprets ambiguous instructions differently each time
- "Context window amnesia" — the AI forgets early decisions by the time later code is written
- Inconsistent patterns across the codebase
- Hard to onboard new developers

### FORGE Equivalent
A casual use of the Frame phase only — some vision is captured but Obstruct and Reconstruct are skipped.

---

## Level 3: Structured Vibe

### Description
The developer uses templates, patterns, and repeatable prompts to guide AI code generation. There is a consistent project structure, and requirements are captured in a recognizable format (even if not fully formalized).

### Characteristics
- Consistent project layout enforced by templates
- Reusable prompts for common tasks
- Requirements documented in a standard format
- Some automated testing is included
- Basic CI/CD exists

### Who Does This
- Engineering teams adopting AI tools systematically
- Organizations with coding standards and templates
- Teams that have "productized" their AI workflow

### Risks
- Structure exists but specs may still be ambiguous
- Testing coverage is inconsistent
- AI agents can still make significant interpretation errors
- No formal review or validation phase

### FORGE Equivalent
Using the FORGE prompts ad-hoc, without the full SDLC flow. Generates artifacts that are consistently structured but not fully validated.

---

## Level 4: Engineered Vibe

### Description
The developer (or team) treats AI-assisted development as a full engineering discipline. Requirements are formally specified before generation begins. Multiple AI agent personas are used for different roles (architect, developer, QA). Generated code is reviewed against specifications. Testing is systematic.

### Characteristics
- Formal specifications in a structured format (e.g., OpenSpec)
- Multiple agent roles with clear responsibilities
- Code generation is driven by specs, not conversational prompts
- All generated code has corresponding tests
- Code review is performed (possibly by a different AI agent)
- CI/CD is fully automated
- Traceability from spec to code to test

### Who Does This
- Engineering-mature organizations
- Teams building production-grade software with AI assistance
- Platform or product teams with defined quality gates

### What This Template Enables
The FORGE template is **optimized for Level 4**. By providing:
- Structured agent definitions (`.github/agents/`)
- OpenSpec-format specification templates
- Phased FORGE prompts for each SDLC stage
- Explicit quality gates and human checkpoints
- Dedicated skills files for review, testing, and documentation

### FORGE Usage at Level 4
Run all five FORGE phases in order. Use the full SDLC flow from Discovery through Release. Engage multiple agent roles. Review all specs before generating code. Use the Edit phase rigorously.

---

## Level 5: Dark Factory

### Description
The highest level of vibe coding maturity. Human involvement is reduced to setting high-level goals and reviewing iteration outputs. AI agent fleets work autonomously in parallel on multiple features simultaneously, using techniques like git worktrees to isolate concurrent work. The human acts as a product manager and quality gatekeeper, not a developer.

### Characteristics
- Fully automated development pipelines
- Parallel AI agent fleets (multiple agents working simultaneously on different stories)
- Git worktrees used for isolated concurrent development
- Automated CI/CD triggers on completion of each story
- Human checkpoints only at iteration boundaries
- Quality gates are automated (tests, linters, security scans must pass before human review)
- Minimal human intervention during execution

### Who Does This
- Organizations that have fully systematized their AI workflow
- Teams with large backlogs that need high throughput
- Platform teams running "lights-out" development overnight

### Risks at Level 5
- Quality can drift without adequate human review
- Parallel agents may make conflicting decisions
- Specs must be extremely precise to avoid divergent interpretations
- Infrastructure costs can be significant (parallel agent execution)
- Over-reliance on automation can mask fundamental requirement errors

### FORGE Usage at Level 5
Preprocess stories first, then run `.github/prompts/dark-factory/auto-iterate.prompt.md`. The system will:
1. Read all iteration stories from `spec/iterations/iteration-N/` and update `state.json`
2. Create a git worktree for each story. Implement feature stories sequentially (one session per story). Make sure you have branch from the `develop` HEAD
3. Copy gitignored secrets
4. Assign each story to the appropriate agent role
5. Implement story
6. Run validation gates (build, lint, test) after each story
7. Commit, push, and create PRs against `develop` branch automatically
8. Merge PR to `develop` branch
9. Continue with the next story unless you complete the iteration
10. Present a completion iteration report for human review

See `.github/instructions/dark-factory.md` for full Dark Factory configuration and usage.

---

## Maturity Model Summary

| Level | Name | Specs | Agents | Testing | Automation | Human Role |
|-------|------|-------|--------|---------|------------|-----------|
| 1 | Pure Vibe | None | One (general) | None | None | Full developer |
| 2 | Directed Vibe | Informal | One (general) | Ad-hoc | None | Active developer |
| 3 | Structured Vibe | Templates | One (with prompts) | Some | Basic CI | Technical lead |
| 4 | Engineered Vibe | Formal (OpenSpec) | Multiple (specialized) | Systematic | Full CI/CD | Reviewer/approver |
| 5 | Dark Factory | Rigorous | Fleet (parallel) | Automated | Fully automated | Product manager |

---

## How to Advance Through the Levels

### From 1 → 2
Start capturing requirements in a `README.md` or simple markdown file before prompting. Even one page of context significantly improves AI output quality.

### From 2 → 3
Adopt a standard project layout. Create reusable prompts for your most common tasks. Establish a consistent naming and structure convention.

### From 3 → 4
Formalize your specifications using OpenSpec or a similar structured format. Introduce multiple agent roles. Add a dedicated review/QA phase. Add test generation to your workflow.

### From 4 → 5
Invest in the iteration planning and spec quality to make them "agent-executable without clarification." Configure git worktrees and learn the Dark Factory execution model. Gradually reduce human touchpoints within iterations (but keep checkpoints at iteration boundaries).

---

## Recommended Starting Point

For most teams adopting this template:

> **Start at Level 3, target Level 4 within 2-3 iterations.**

Level 5 requires significant spec quality and process maturity. Rushing to Dark Factory mode with immature specs will produce poor results and erode trust in the AI tooling.

The FORGE template gives you the scaffolding for both. Use Level 4 features from day one, and activate Level 5 (Dark Factory) when your team has confidence in the spec-to-code pipeline.
