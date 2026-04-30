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

If any story is missing these, re-run preprocessing for that story individually.

---

## Step 2: Initialize State

Create `spec/iterations/iteration-N/state.json`:

```
Read spec/iterations/iteration-N/plan.md and create
spec/iterations/iteration-N/state.json following the schema
in spec/iterations/.state-schema.json.
Set all story statuses to "queued". Set iteration status to "planned".
```

---

## Step 3: Execute Phase 0 (Foundation)

Phase 0 MUST complete and merge before any feature branch is created.

### 3a. Implement Phase 0

```
Read @spec/iterations/iteration-N/stories/US-XX-00.md and implement it.
Follow the instructions in the story spec EXACTLY.
```

### 3b. Validate Phase 0

Run these yourself in a terminal (no LLM needed):
```bash
cd solutions/PROJECT_NAME
./gradlew openApiGenerate
./gradlew spotlessApply
./gradlew clean build
```

### 3c. Merge Phase 0

Merge to the base branch (`$FORGE_BASE_BRANCH`, default: `develop`):
```bash
cd solutions/PROJECT_NAME
git add .
git commit -m "chore(US-XX-00): Phase 0 foundation for iteration N"
git checkout develop   # or $FORGE_BASE_BRANCH from .forge/config.env
git merge feature/US-XX-00-foundation
```

### 3d. Update State

Update `state.json`: set US-XX-00 status to `done`, set `current_phase` to 1.

---

## Step 4: Execute Feature Stories (Phase by Phase)

For each phase (1, 2, 3, ...) in the iteration plan:

### 4a. Create Worktrees (do this yourself — no LLM needed)

Use the init-worktree script (handles author + secret file copying):
```bash
bash .forge/init-worktree.sh PROJECT US-XX-XX slug
```

Or manually (branches from `develop` / `$FORGE_BASE_BRANCH`):
```bash
# IMPORTANT: git -C changes CWD to solutions/PROJECT/, so use ../worktrees/ (NOT solutions/worktrees/)
git -C solutions/PROJECT worktree add \
  ../worktrees/PROJECT/US-XX-XX \
  -b feature/US-XX-XX-slug develop
```

### 4b. Implement Stories (ONE AT A TIME)

For each story in the current phase, start a **fresh Copilot session**:

```
Read @spec/iterations/iteration-N/stories/US-XX-XX.md and implement it.
Work in solutions/worktrees/PROJECT/US-XX-XX/
Follow the instructions in the story spec EXACTLY.
Do NOT read any other files unless the story spec tells you to.
```

> **IMPORTANT:** Each story = fresh session. Do NOT implement multiple
> stories in the same Copilot session. Context pollution causes rule-ignoring.

### 4c. Validate (do this yourself — no LLM needed)

After Copilot finishes, run the validation commands yourself:

**Java:**
```bash
cd solutions/worktrees/PROJECT/US-XX-XX
./gradlew spotlessApply
./gradlew clean build
# ./gradlew integrationTest  # if applicable
```

**React:**
```bash
cd solutions/worktrees/PROJECT/US-XX-XX
npx prettier --write src/
npx eslint src/
npx tsc --noEmit
npm run build
npx vitest run
```

> **Rate-limit optimization:** While Copilot implements story N, you can
> run validation commands for story N-1 in a separate terminal.

### 4d. Fix Issues (if validation fails)

If build/test fails, start a NEW Copilot session:

```
Read @spec/iterations/iteration-N/stories/US-XX-XX.md
The build failed with this error:
[paste error output]
Fix the issue in solutions/worktrees/PROJECT/US-XX-XX/
```

### 4e. Commit and Update State

```bash
cd solutions/worktrees/PROJECT/US-XX-XX
git add .
git commit -m "feat(US-XX-XX): Story title"
```

Update `state.json`: set story status to `done`, record gate results.

### 4f. Phase Complete — Merge Back to develop

When ALL stories in a phase are done, merge to `develop` (or `$FORGE_BASE_BRANCH`):

```bash
cd solutions/PROJECT
git checkout develop   # or $FORGE_BASE_BRANCH

# Merge each completed story branch
git merge feature/US-XX-01-slug
git merge feature/US-XX-02-slug
# ... etc

# Verify develop still builds
./gradlew clean build  # or npm run build
```

> **This merge-back is critical.** Without it, Phase 2 branches diverge from
> Phase 1 changes and you get massive PR conflicts.

### 4g. Review & Apply Feedback (optional)

If you reviewed the code and have corrections:
```
Read @.github/prompts/dark-factory/review-story.prompt.md
Review US-XX-XX in solutions/worktrees/PROJECT/US-XX-XX/
Feedback:
- [your feedback items]
```

> When the full iteration is done, merge `develop` → `main` manually to release.

Update `state.json`: set `current_phase` to next phase number.

### 4g. Repeat for Next Phase

Create new worktrees from the updated `main`, then repeat 4b-4f.

---

## Step 5: Assess Iteration

After all phases complete:

```
Read @.github/prompts/dark-factory/assess-iteration.prompt.md
Assess iteration N using @spec/iterations/iteration-N/state.json
and the story specs in @spec/iterations/iteration-N/stories/
```

---

## Step 6: PR Creation

For each completed story that passed validation:

```bash
cd solutions/PROJECT
git push origin feature/US-XX-XX-slug
gh pr create --base develop --head feature/US-XX-XX-slug \
  --title "feat(US-XX-XX): Story title" \
  --body "Implements US-XX-XX per iteration N spec."
```

> **Tip:** All PRs target `develop` (or `$FORGE_BASE_BRANCH`). When the iteration
> is assessed and approved, the human merges `develop` → `main` to release.

---

## Parallelism Strategy (Rate-Limit Aware)

Since Copilot CLI has rate limits, here's how to maximize throughput:

```
Timeline for stories A, B, C in same phase:

[Copilot: Implement A]  →  [Copilot: Implement B]  →  [Copilot: Implement C]
                         ↗                          ↗
[You: Validate A]  ────────  [You: Validate B]  ────────  [You: Validate C]
```

- While Copilot generates story B, you validate story A in a terminal
- Build, test, lint commands don't need Copilot — run them in parallel
- Integration test suites run independently
- You can even run a code quality scanner (SonarQube, etc.) in parallel

---

## Troubleshooting

### Story output ignores rules
- Check that the story spec has `## Mandatory Rules (Inline)` section
- Ensure you started a FRESH Copilot session (context bleed from prior stories)
- Verify story spec is self-contained (no "see file X" references)

### PR conflicts between stories
- Ensure Phase 0 was merged before feature branches
- Ensure inter-phase merge-back happened
- Stories in the same phase should NOT modify the same files

### Story blocked by dependency
- Check `state.json` — is the dependency actually `done`?
- If dependency failed, mark dependent story as `blocked` and skip

### Build fails after merge-back
- Resolve conflicts in the merge commit
- Re-run validation on merged `develop`
- If a story introduced a bad merge, fix in a separate commit on `develop`
