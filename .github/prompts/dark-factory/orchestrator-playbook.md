---
description: "Human-driven orchestration playbook for running an iteration at Level 4 (Engineered Vibe). The HUMAN drives step-by-step; Copilot executes one step at a time."
---

# Iteration Orchestration Playbook (Level 4 — Engineered Vibe)

> **You (the human) are the orchestrator.** This playbook tells you exactly which
> command or prompt to run at each step. Copilot executes ONE step at a time.
> You advance to the next step when the current one is done.
>
> This is NOT a prompt to paste into Copilot. This is YOUR checklist.

---

## Why Level 4 Instead of Level 5 (Dark Factory)

Level 5 (full Dark Factory) requires the LLM to:
- Maintain state across dozens of stories
- Context-switch between agent personas
- Track dependencies, merge branches, handle failures

Current LLMs cannot reliably do all of this in one session. At Level 4, **you** handle orchestration (state, sequencing, branching) and **Copilot** handles implementation (code generation, tests, validation). This produces dramatically better results.

---

## Pre-Iteration Checklist

Before starting, verify:

- [ ] Iteration plan exists: `spec/iterations/iteration-N/plan.md`
- [ ] All story specs are in: `spec/iterations/iteration-N/stories/`
- [ ] Stories are preprocessed (self-contained with code skeletons) — if not, run Step 1
- [ ] `state.json` created for this iteration — if not, run Step 2
- [ ] `main` branch is clean and all tests pass

---

## Step 1: Preprocess Stories (ONE TIME)

Run this in Copilot CLI or VS Code Copilot Chat:

```
Read @.github/prompts/dark-factory/preprocess-iteration.prompt.md
and enrich all stories in @spec/iterations/iteration-N/stories/
using the templates from @.github/templates/
```

**Verify:** Open each story spec and confirm it has:
- [ ] `## Code Skeleton` section with actual code
- [ ] `## Mandatory Rules (Inline)` section
- [ ] `## Validation Commands` section
- [ ] `## Commit Command` section

---

## Step 2: Initialize State

Create `spec/iterations/iteration-N/state.json` from the template at
`.github/templates/state.json.template`, filling in story details from the plan.

---

## Step 3: Execute Phase 0 (Foundation)

Phase 0 MUST complete and merge before any feature branch is created.

### 3a. Implement Phase 0 (Copilot)
```
Read @spec/iterations/iteration-N/stories/US-XX-00.md and implement it.
```

### 3b. Validate (you — no LLM needed)
```bash
cd solutions/PROJECT_NAME
./gradlew spotlessApply && ./gradlew clean build
```

### 3c. Merge Phase 0 to main
```bash
git add . && git commit -m "chore(US-XX-00): Phase 0 foundation"
git checkout main && git merge feature/US-XX-00-foundation
```

### 3d. Update state.json — US-XX-00 → done, current_phase → 1

---

## Step 4: Execute Feature Stories (Phase by Phase)

For each phase (1, 2, 3, ...):

### 4a. Create Worktrees (no LLM needed)
```bash
git -C solutions/PROJECT worktree add \
  solutions/worktrees/PROJECT/US-XX-XX \
  -b feature/US-XX-XX-slug main
```

### 4b. Implement Stories — ONE AT A TIME, FRESH SESSION EACH
```
Read @spec/iterations/iteration-N/stories/US-XX-XX.md and implement it.
Work in solutions/worktrees/PROJECT/US-XX-XX/
```

### 4c. Validate (you — no LLM needed)
Run the validation commands from the story spec yourself.

### 4d. Fix Issues (if needed — new Copilot session)
Paste the error into a fresh session with the story spec reference.

### 4e. Commit and update state.json

### 4f. After ALL stories in phase complete — merge back to main
```bash
git checkout main
git merge feature/US-XX-01 && git merge feature/US-XX-02 # etc
./gradlew clean build  # verify main still builds
```

### 4g. Repeat for next phase (branch from updated main)

---

## Step 5: Assess Iteration

```
Read @.github/prompts/dark-factory/assess-iteration.prompt.md
Assess iteration N using state.json and story specs.
```

---

## Parallelism Strategy (Rate-Limit Aware)

```
[Copilot: Implement A]  →  [Copilot: Implement B]  →  [Copilot: Implement C]
                         ↗                          ↗
[You: Validate A]  ────────  [You: Validate B]  ────────  [You: Validate C]
```

While Copilot generates code, you validate the previous story in parallel.
Build, test, lint commands don't need Copilot.
