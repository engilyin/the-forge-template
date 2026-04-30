---
description: "Review completed stories and apply human feedback. Use after an iteration when the human has reviewed AI-generated PRs and wants corrections applied."
agent: 'agent'
tools:
  - read
  - edit
  - search
  - execute
---

# Review Story — Apply Human Feedback

> This prompt processes human review feedback for one or more completed stories.
> Use it after the Dark Factory iteration when you've reviewed the AI-generated code
> and want corrections applied systematically.
>
> **Use cases:**
> - Code quality fixes (rename, restructure, simplify)
> - Bug fixes found during manual testing
> - Pattern violations the review checklist missed
> - Design improvements based on human judgment

## Input

You will receive:
1. **Story ID(s)** — which stories to fix
2. **Feedback** — human-written review notes describing what needs to change
3. **Worktree or branch location** — where the code lives

Example invocation:
```
Read @.github/prompts/dark-factory/review-story.prompt.md

Review US-07-01 in solutions/worktrees/citizen-report-api/US-07-01/

Feedback:
- The service method `listReports` should use pagination from the repository, not fetch-all-then-slice
- Remove the unused `ReportSummaryProjection` — the existing `ReportProjection` already has those fields
- The controller is returning 200 for create — should be 201 Created
- Add a `@Transactional` annotation on the delete method
```

## Process

### Step 1: Load Context

1. Read the story spec: `spec/iterations/iteration-N/stories/STORY-ID.md`
2. Identify the project and tech stack
3. Read the relevant stack index: `.github/skills/stacks/<stack>/index.md`
4. Switch to the worktree directory

### Step 2: Understand Feedback

For each feedback item:
- Classify: `bug` | `quality` | `design` | `pattern-violation` | `simplification`
- Identify affected file(s)
- Determine if the fix is safe (no risk of breaking other functionality)

Present the classified feedback back to the user:
```
Feedback Analysis:
1. [quality] listReports pagination — ReportService.java, ReportRepository.java
2. [simplification] Remove ReportSummaryProjection — delete file + update imports
3. [bug] Create endpoint status code — ReportController.java (200 → 201)
4. [pattern-violation] Missing @Transactional — ReportService.java

Proceed with all fixes? (y/n)
```

### Step 3: Apply Fixes

For each feedback item:
1. Read the affected file(s)
2. Apply the specific fix described in the feedback
3. Do NOT make additional changes beyond what the feedback asks for
4. Do NOT refactor surrounding code unless the feedback explicitly requests it

### Step 4: Validate

Run the tech stack's validation commands:

**Java:**
```bash
./gradlew spotlessApply
./gradlew clean build
```

**React:**
```bash
npx prettier --write src/
npx eslint src/
npx tsc --noEmit
npm run build
npx vitest run
```

### Step 5: Commit

If validation passes:
```bash
git add .
git commit -m "fix(STORY-ID): apply review feedback"
```

If the branch already has a PR, push to update it:
```bash
git push origin HEAD
```

## Multi-Story Batch Review

If reviewing multiple stories at once, process them **sequentially** (one story at a time).
After fixing each story, commit before moving to the next.

Format for batch feedback:
```
## US-07-01
- feedback item 1
- feedback item 2

## US-07-02
- feedback item 1

## US-07-03
- feedback item 1
- feedback item 2
- feedback item 3
```

## Output

When done, report:
```
Review Applied:
  Story: [ID]
  Fixes: [N] applied, [M] skipped (reason)
  Validation: build=[pass/fail] test=[pass/fail]
  Commit: [hash]
  PR: [updated / not applicable]
  
  Changes:
  - [file]: [what changed]
  - [file]: [what changed]
```

## Error Recovery

If a fix causes a build/test failure:
1. Identify whether the failure is from the fix or pre-existing
2. If from the fix: adjust the fix approach and retry
3. If pre-existing: note it in the output and continue with other fixes
4. After 2 failed attempts on a single fix: skip it with explanation and continue
