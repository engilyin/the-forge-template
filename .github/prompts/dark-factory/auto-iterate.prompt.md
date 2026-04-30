---
description: "Automated Dark Factory: Execute an entire iteration unattended. Stories run sequentially. Build/test/validation runs in parallel. Updates state.json throughout."
agent: 'agent'
tools:
  - read
  - edit
  - search
  - execute
---

# Automated Dark Factory — Unattended Iteration Execution

> This prompt executes an entire iteration unattended. Start it and walk away.
> Stories are implemented sequentially (one at a time) to stay within context limits.
> Build, test, and validation commands run between story implementations.
>
> **Prerequisites:** Stories MUST be preprocessed (self-contained with code skeletons).
> Run `preprocess-iteration.prompt.md` first if not already done.

## Critical Design Rules

1. **ONE story at a time** — never read two story specs simultaneously
2. **Forget previous story** — after committing a story, do NOT reference its code again
3. **state.json is the single source of truth** — read it before each story to know what's next
4. **Self-contained specs** — read ONLY the story spec file for implementation rules
5. **No external rule files** — do NOT read `.github/skills/*.md` or `.github/agents/*.md` during implementation
6. **Stop on blockers** — if a story fails validation twice, mark it `failed` and move on
7. **Git Flow branching** — all PRs target `$FORGE_BASE_BRANCH` (default: `develop`), NOT `main`
8. **Rate limit awareness** — pause `$FORGE_STORY_DELAY_SECONDS` between stories to avoid API throttling
9. **Init worktree via script** — use `.forge/init-worktree.sh` to create worktrees (handles author + secrets)

## Input

Read the iteration number from the user, or detect it:

```bash
ls spec/iterations/ | grep "iteration-" | sort -V | tail -1
```

Set `ITER` to the iteration directory name (e.g., `iteration-3`).

## Step 1: Load Plan and Initialize State

Read `spec/iterations/$ITER/plan.md` to get:
- List of stories with phases and dependencies
- Project name(s) for each story

Read or create `spec/iterations/$ITER/state.json`.
If `state.json` doesn't exist, create it from the plan using `.github/templates/state.json.template`.

Read `.forge/config.env` to get all configuration:
```bash
source .forge/config.env 2>/dev/null || true
FORGE_AUTHOR_NAME="${FORGE_AUTHOR_NAME:-$(git config user.name)}"
FORGE_AUTHOR_EMAIL="${FORGE_AUTHOR_EMAIL:-$(git config user.email)}"
FORGE_BASE_BRANCH="${FORGE_BASE_BRANCH:-develop}"
FORGE_STORY_DELAY_SECONDS="${FORGE_STORY_DELAY_SECONDS:-30}"
FORGE_SECRET_FILES="${FORGE_SECRET_FILES:-src/main/resources/application-default.properties,src/main/resources/application-local.properties,.env,.env.local,.env.development.local}"
FORGE_AUTO_MERGE_PR="${FORGE_AUTO_MERGE_PR:-true}"
```

Ensure the base branch exists in each project:
```bash
for PROJECT in $(jq -r '.stories[].project' spec/iterations/$ITER/state.json | sort -u); do
  if ! git -C solutions/$PROJECT rev-parse --verify $FORGE_BASE_BRANCH &>/dev/null; then
    git -C solutions/$PROJECT branch $FORGE_BASE_BRANCH main
    echo "Created $FORGE_BASE_BRANCH from main in $PROJECT"
  fi
done
```

Set iteration status to `executing`.

## Step 2: Execute Phase 0 (Foundation)

Find the Phase 0 story (if any) from state.json.

### 2a. Implement Phase 0

Read the Phase 0 story spec. Implement it.

### 2b. Validate Phase 0

```bash
cd solutions/PROJECT_NAME
./gradlew spotlessApply 2>&1 | tail -20
./gradlew clean build 2>&1 | tail -30
```

If build fails: attempt fix once. If still fails: mark `failed` in state.json and HALT.
Phase 0 failure = entire iteration blocked.

### 2c. Commit and Merge Phase 0

```bash
cd solutions/PROJECT_NAME
git add .
git commit -m "chore(STORY-ID): Phase 0 foundation for $ITER"
```

Merge Phase 0 to the base branch (`$FORGE_BASE_BRANCH`, default: `develop`):
```bash
git checkout $FORGE_BASE_BRANCH
git merge feature/STORY-ID-foundation --no-edit
```

Update state.json: Phase 0 → `done`, `current_phase` → 1.

## Step 3: Execute Feature Stories (Phase by Phase)

For each phase (1, 2, 3, ...) in ascending order:

### 3a. Check Phase Readiness

Read state.json. For the current phase, verify:
- All dependency stories (from earlier phases) have status `done`
- If any dependency is `failed` or `blocked`, mark dependent stories as `blocked` and skip them

### 3b. Create Worktrees for This Phase

For each `queued` story in this phase, use the init-worktree script:

```bash
STORY_ID="US-XX-XX"
SLUG="short-slug"
PROJECT="project-name"

# This script: creates worktree from $FORGE_BASE_BRANCH, sets git author, copies secret files
bash .forge/init-worktree.sh "$PROJECT" "$STORY_ID" "$SLUG"
```

If the script is not available, do it manually:
```bash
# IMPORTANT: git -C changes CWD, so worktree path must be relative to the project dir.
# Use ../worktrees/ (NOT solutions/worktrees/) because git resolves from solutions/$PROJECT/.
git -C solutions/$PROJECT worktree add \
  ../worktrees/$PROJECT/$STORY_ID \
  -b feature/$STORY_ID-$SLUG $FORGE_BASE_BRANCH 2>&1

# Set author
git -C solutions/worktrees/$PROJECT/$STORY_ID config user.name "$FORGE_AUTHOR_NAME"
git -C solutions/worktrees/$PROJECT/$STORY_ID config user.email "$FORGE_AUTHOR_EMAIL"

# Copy ALL secret/config files from FORGE_SECRET_FILES
IFS=',' read -ra SECRET_PATTERNS <<< "$FORGE_SECRET_FILES"
for pattern in "${SECRET_PATTERNS[@]}"; do
  pattern="$(echo "$pattern" | xargs)"
  if [ -f "solutions/$PROJECT/$pattern" ]; then
    mkdir -p "$(dirname "solutions/worktrees/$PROJECT/$STORY_ID/$pattern")"
    cp "solutions/$PROJECT/$pattern" "solutions/worktrees/$PROJECT/$STORY_ID/$pattern"
  fi
done
```

Update state.json: set `branch` and `worktree` for each story.

### 3c. Copy Secrets/Config to Worktree

For each worktree, copy environment-specific files that are gitignored:

```bash
# Java projects
if [ -f "solutions/$PROJECT/src/main/resources/application-local.properties" ]; then
  cp solutions/$PROJECT/src/main/resources/application-local.properties \
     solutions/worktrees/$PROJECT/$STORY_ID/src/main/resources/
fi

# Node/React projects
if [ -f "solutions/$PROJECT/.env.local" ]; then
  cp solutions/$PROJECT/.env.local \
     solutions/worktrees/$PROJECT/$STORY_ID/
fi

# Generic .env
if [ -f "solutions/$PROJECT/.env" ]; then
  cp solutions/$PROJECT/.env \
     solutions/worktrees/$PROJECT/$STORY_ID/
fi
```

### 3d. Implement Each Story Sequentially

For each story in the current phase (ordered by story ID):

**Before implementing:**
- Re-read state.json (it may have been updated by a previous story's failure)
- Skip if status is `blocked`
- Update story status to `implementing`

**Rate limit mitigation:** If `FORGE_STORY_DELAY_SECONDS` > 0, wait that many seconds
before starting each story (except the first). This reduces Copilot API throttling risk.

**Implement:**
1. Read ONLY `spec/iterations/$ITER/stories/$STORY_ID.md`
2. Work in `solutions/worktrees/$PROJECT/$STORY_ID/`
3. Implement all TODOs from the code skeletons
4. Follow the inline Mandatory Rules in the story spec
5. Do NOT read any external files beyond the story spec

**After implementing — run validation:**

For Java stories:
```bash
cd solutions/worktrees/$PROJECT/$STORY_ID
./gradlew spotlessApply 2>&1 | tail -20
./gradlew clean build 2>&1 | tail -30
```

For React stories:
```bash
cd solutions/worktrees/$PROJECT/$STORY_ID
npx prettier --write src/ 2>&1 | tail -10
npx eslint src/ 2>&1 | tail -20
npx tsc --noEmit 2>&1 | tail -20
npm run build 2>&1 | tail -20
npx vitest run 2>&1 | tail -30
```

**Record gate results** in state.json.

**If validation fails:**
1. Read the error output
2. Fix the specific issue
3. Re-run the failing command
4. If it fails a second time: set status → `failed`, record `error_summary`, move to next story

**If validation passes — commit:**
```bash
cd solutions/worktrees/$PROJECT/$STORY_ID
git add .
git commit -m "feat($STORY_ID): Story title"
```

Update state.json: status → `done`, record gate results.

**Push and create PR (targeting $FORGE_BASE_BRANCH, default: develop):**
```bash
cd solutions/worktrees/$PROJECT/$STORY_ID
git push origin feature/$STORY_ID-$SLUG 2>&1
gh pr create --base $FORGE_BASE_BRANCH \
  --head feature/$STORY_ID-$SLUG \
  --title "feat($STORY_ID): Story title" \
  --body "Implements $STORY_ID per $ITER spec." 2>&1
```

Record `pr_url` in state.json.

### 3d. Phase Complete — Merge to Base Branch

After all stories in the phase are done (or failed/blocked):

```bash
cd solutions/$PROJECT
git checkout $FORGE_BASE_BRANCH

# Merge each done story
for each DONE story in this phase:
  git merge feature/$STORY_ID-$SLUG --no-edit 2>&1
done

# Verify base branch builds
./gradlew clean build 2>&1 | tail -30  # or: npm run build
```

If merge conflicts occur: attempt auto-resolution. If that fails, record the conflict in state.json and continue with remaining phases (dependent stories will be blocked).

Update state.json: `current_phase` → next phase, add `phase_transitions` entry.

### 3e. Repeat for Next Phase

Go back to 3a for the next phase.

## Step 4: Produce Completion Report

After all phases complete (or all remaining stories are blocked/failed):

Update state.json: iteration status → `done` (or `halted` if there are failures).

Print a summary:

```
═══════════════════════════════════════════════════════
  DARK FACTORY — ITERATION COMPLETE
═══════════════════════════════════════════════════════

  Iteration: [N]
  Goal: [goal]
  Base branch: [FORGE_BASE_BRANCH]

  Stories:  [done]/[total] completed
  Points:   [delivered]/[planned] delivered
  PRs:      [count] created (targeting [FORGE_BASE_BRANCH])

  ✅ Done:    [list]
  ❌ Failed:  [list with error summaries]
  🔒 Blocked: [list with reason]

  state.json updated: spec/iterations/$ITER/state.json

  NEXT STEPS:
  - Review PRs on [FORGE_BASE_BRANCH]: [PR URLs]
  - Apply review feedback: review-story.prompt.md
  - Fix failed stories manually or schedule for next iteration
  - Run: assess-iteration.prompt.md for detailed assessment
  - When ready to release: merge [FORGE_BASE_BRANCH] → main
═══════════════════════════════════════════════════════
```

## Error Recovery

If the entire process crashes mid-execution:
1. Read `spec/iterations/$ITER/state.json`
2. Find the last story with status `implementing`
3. Resume from that story (it may need cleanup)
4. All completed stories are safe — they were committed

## Rate Limit Recovery

If you encounter HTTP 429 (rate limit) errors from the Copilot API:
1. Record the current story ID and status in state.json (`status: "rate_limited"`)
2. Wait at least 60 seconds before retrying
3. If rate limits persist, increase `FORGE_STORY_DELAY_SECONDS` in `.forge/config.env`
4. Resume from the rate-limited story

Preventive measures:
- Keep `FORGE_STORY_DELAY_SECONDS` ≥ 30 when using premium models
- Avoid running multiple FORGE agents in parallel against the same Copilot account
- Prefer smaller stories (fewer files/lines) to reduce API calls per story
- If using Level 4 (human-orchestrated): stagger story starts by 2-3 minutes

## Context Management

To prevent context window exhaustion across many stories:
- After committing a story, **do not** reference its implementation files again
- The only persistent state is `state.json` — re-read it before each story
- Each story spec is self-contained — no shared context needed between stories
- If context becomes too large, prioritize: current story spec > state.json > plan.md
