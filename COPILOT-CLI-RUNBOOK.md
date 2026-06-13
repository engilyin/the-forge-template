# FORGE Dev Process Runbook

> Concise reference for the full development lifecycle. See individual prompts for detailed instructions.

---

## Dev Process — State Machine

```
NEW PRODUCT:    greenfield-init → Frame → Obstruct → Reconstruct ─┐
EXISTING CODE:  brownfield-analysis ──────────────────────────────┤
                                                                   ↓
                         BACKLOG  (story-breakdown + backlog-grooming)
                                                   ↓
                                     iteration-planning
                              max 10 stories / 30 pts / Phase 0 first
                                                   ↓
                                   preprocess-iteration
                            (inlines code skeletons + rules per story)
                                                   ↓
                ┌────────────────────────────────────┴────────────────────────────────────┐
                │  Level 4 (human-orchestrated)       │  Level 5 (automated, walk away)   │
                │  orchestrator-playbook.md            │  auto-iterate.prompt.md           │
                └────────────────────────────────────┴────────────────────────────────────┘
                                                   ↓
                             GENERATE (implementation only)
                             Phase 0 → commit → merge develop
                             Phase 1 stories  → commit/PR/merge policy
                             Phase N stories  → commit/PR/merge policy
                                        ↓
                             EDIT (mandatory hardening gate)
                        .github/prompts/forge/05-edit.prompt.md
                                                   ↓
                                         assess-iteration
                                       Go ↓           No-Go ↓
                                    develop → main      fix / replan
                                       (human)

  MID-ITERATION:
    Spec/design change → 06-amend.prompt.md  (spec/backlog updates only)
    Story blocked      → edit state.json, continue with remaining stories
    Major pivot        → assess → close early → replan next iteration
```

---

## 0. One-time Setup

```bash
# Set your git author (gitignored — never commit this file)
cp .forge/config.env.example .forge/config.env
# Edit .forge/config.env: set FORGE_AUTHOR_NAME, FORGE_AUTHOR_EMAIL
# Branching: FORGE_BASE_BRANCH defaults to "develop" (Git Flow)

# Set author and create develop branch in all project repos
bash setauthor.sh
```

Set model in Copilot:
```text
/model GPT-5 Mini
```

---

## 1. Greenfield — New Product

Switch to premium for FORGE Frame/Obstruct/Reconstruct:
```text
/model claude-sonnet-4-6
```

```text
Read @.github/prompts/project/greenfield-init.prompt.md and start the flow. Ask clarifying questions first.
Read @.github/prompts/forge/01-frame.prompt.md and continue from the current repo state.
Read @.github/prompts/forge/02-obstruct.prompt.md and continue from the current repo state.
Read @.github/prompts/forge/03-reconstruct.prompt.md and continue from the current repo state.
```

Output: `spec/business/` and `spec/technical/` — Switch back: `/model GPT-5 Mini`

---

## 2. Brownfield — Existing Code

Clone repos into `solutions/`:

```bash
cd solutions
git clone https://github.com/other-org/cool-project _ref-cool-project
cd ..
```

Analyze (premium model):
```text
Read @.github/prompts/project/brownfield-analysis.prompt.md and analyze all projects under @solutions. Produce technical specs under @spec/technical.
```

Output: `spec/technical/` — Switch back: `/model GPT-5 Mini`

---

## 3. Build & Groom Backlog

```text
Read @.github/prompts/backlog/story-breakdown.prompt.md and break the approved specs into stories.
Read @.github/prompts/backlog/backlog-grooming.prompt.md and groom the current backlog.
```

Repeat grooming whenever new features arrive or requirements change.

---

## 4. Plan an Iteration

```text
Read @.github/prompts/backlog/iteration-planning.prompt.md and create the next iteration plan.
```

Enforced: max 8-10 stories · max 25-30 pts · Phase 0 always first · stories grouped by dependency into execution phases.

Output: `spec/iterations/iteration-N/plan.md` + per-story spec files.

---

## 5. Preprocess Stories (Required Before Any Execution)

Inlines code skeletons and mandatory rules into each story spec so agents need no external files during implementation:

```text
Read @.github/prompts/dark-factory/preprocess-iteration.prompt.md and preprocess iteration N.
```

## 6. Run Iteration — Level 4 (Human-Orchestrated)

Open the orchestrator playbook and follow it step by step:

```text
Read @.github/prompts/dark-factory/orchestrator-playbook.md
```

**Phase 0 — fresh session:**
```text
Read @spec/iterations/iteration-N/stories/US-XX-00.md and implement it.
```
Validate → commit → merge Phase 0 to `develop`.

**Each feature story — one fresh session per story:**
```text
Read @spec/iterations/iteration-N/stories/US-XX-XX.md and implement it.
Work in solutions/worktrees/PROJECT/US-XX-XX/.
```

> ⚠️ **One story per session.** Context bleed between stories causes rule-ignoring.

Create worktrees with the init script:
```bash
bash .forge/init-worktree.sh PROJECT US-XX-XX slug
```

**Rate-limit optimization:** while Copilot works on story B, validate story A yourself:
```bash
cd solutions/worktrees/PROJECT/US-XX-01
./gradlew spotlessApply && ./gradlew clean build
```

**After each phase:** merge done branches to `develop`, then branch next phase from updated `develop`.

**After all phases:** review changes, apply feedback with `review-story.prompt.md`, then merge `develop` → `main` to release.

---

## 7. Run Iteration — Level 5 (Automated)

Start once, walk away:

```text
Read @.github/prompts/dark-factory/auto-iterate.prompt.md and execute iteration N.
```

- Sequential stories — state tracked in `state.json` between sessions
- Auto-validates, commits, pushes, creates PRs after each story
- Skips failed stories after 2 retries; continues the rest
- Phase merge-back handled automatically
- Uses a deterministic PR policy from `.forge/config.env`:
  - `FORGE_AUTO_MERGE_PR=false` (recommended): create PRs, do not auto-merge
  - `FORGE_AUTO_MERGE_PR=true`: create and merge PRs before moving forward

Track progress: `cat spec/iterations/iteration-N/state.json`

## 8. Post-Level-5 Single Flow (Required)

After `auto-iterate.prompt.md` completes, follow this exact sequence.
There are no alternate paths.

### Step 1 — Run FORGE Edit (mandatory)

```text
Read @.github/prompts/forge/05-edit.prompt.md and run it for iteration N.
```

Expected output:
- `spec/iterations/iteration-N/report.md`
- Defects/regressions list
- Acceptance criteria coverage
- Clear release recommendation

### Step 2 — Triage outcomes from Edit report

Use the report to decide what happens next:

1. Problems, regressions, or missing quality items:
  - fix them
  - re-run `05-edit.prompt.md`
2. Story scope not fully implemented:
  - mark unfinished story parts as carry-over
  - move them to next iteration backlog
3. Goals changed or new goals discovered:
  - run `06-amend.prompt.md` to update specs/backlog
  - include in future iteration planning

Note:
- `05-edit` is quality and completion validation
- `06-amend` is scope/spec/backlog evolution

### Step 3 — Run iteration assessment (Go/No-Go)

```text
Read @.github/prompts/dark-factory/assess-iteration.prompt.md
and assess iteration N using @spec/iterations/iteration-N/state.json
```

### Step 4 — Close or continue

- If **Go**: merge approved PRs to `develop`, then merge `develop` → `main` manually
- If **No-Go**: keep fixes/carry-overs in backlog, plan next iteration, then continue

### Non-Negotiable Guardrails

- No `Co-authored-by` trailers in commits
- No release from `feature/*` branches (release is `develop` → `main` only)
- No skipping `05-edit`, even if build/tests are green

---

## 9. CLI Quick Reference

```bash
copilot                                               # interactive
copilot -s -p "..."                                   # non-interactive prompt
copilot -s --agent java-backend-developer -p "..."    # specific agent role
```

```text
/model GPT-5 Mini      /agent           /skills reload
/skills list           /session          /usage
```