---
description: "Implement a single user story. The story spec file contains ALL instructions — read ONLY that file."
agent: 'agent'
tools:
  - read
  - edit
  - search
  - execute
---

# Implement Single Story

> This prompt implements **exactly one story**. The story spec is **self-contained** —
> it includes code skeletons, inline rules, and validation commands.
> Do NOT read external rule files, checklists, or agent definitions.

## Input

You will receive a path to ONE story spec file. Example:
```
spec/iterations/iteration-3/stories/US-07-01.md
```

Read that file. It contains everything you need.

## Process

1. **Read the story spec** — one file, fully self-contained
2. **Verify prerequisites** — check that files listed in "Files to Modify" exist
3. **Create files** listed in "Files to Create" using the provided code skeletons as the starting point
4. **Implement the TODOs** in each skeleton, following the inline Mandatory Rules
5. **Write unit tests** that cover every Acceptance Criteria scenario
6. **Run validation commands** listed in the story spec (in order)
7. **Fix any failures** — retry validation up to 2 times
8. **Commit** using the exact commit command in the story spec

## Critical Rules

- **Read ONLY the story spec file** — all rules, patterns, and conventions are inlined there
- **Do NOT read or reference** `.github/skills/*.md`, `.github/agents/*.md`, or `spec/technical/*.md`
  unless the story spec explicitly quotes content from them inline
- **Do NOT modify files** outside the story's "Files to Create" and "Files to Modify" tables
- **Do NOT add features** beyond the explicit Acceptance Criteria
- **Do NOT add** comments, docstrings, or error handling beyond what the skeleton specifies
- **If ambiguous**, implement the simplest reasonable interpretation — do not invent requirements
- **Commit message format:** `feat(STORY-ID): title` — no Co-authored-by trailer
- **PR target:** `$FORGE_BASE_BRANCH` (default: `develop`), NOT `main`
- **Rate limits:** If you encounter HTTP 429 errors, wait 60 seconds and retry the operation

## Error Recovery

If a validation command fails:
1. Read the error output
2. Identify the specific issue (compile error, test failure, lint violation)
3. Fix ONLY the failing issue — do not refactor other code
4. Re-run the failing command
5. If it fails a second time, commit what you have with message:
   `wip(STORY-ID): title — [gate-name] failing, needs human review`
   and stop.

## Output

When done, report:
```
Story: [ID]
Status: [DONE | NEEDS_REVIEW]
Files created: [list]
Files modified: [list]
Validation: build=[pass/fail] test=[pass/fail] lint=[pass/fail]
Commit: [hash or "not committed"]
Notes: [any issues encountered]
```
