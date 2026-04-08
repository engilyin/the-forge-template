---
description: "FORGE Phase 6 — Amend: Update specifications and backlog when design decisions change during implementation."
agent: 'agent'
tools:
  - read
  - edit
  - search
---

# FORGE Phase 6: AMEND

> Run this prompt when you discover during implementation that specifications need updating.
> This is the **agile feedback loop** — FORGE is not waterfall.

## When to Use

- A design decision turned out to be wrong
- Requirements were incomplete or ambiguous
- Technical constraints emerged during implementation
- Architecture needs adjustment
- A story's acceptance criteria need revision
- New stories are needed that weren't anticipated

## Process

### Step 1: Describe What Changed

Ask the user:
1. **What did you learn?** — What happened during implementation that triggered this amendment?
2. **What was the original decision/spec?** — Reference the spec ID, story ID, or DD number.
3. **What should it be instead?** — What's the corrected approach?

Document this as an amendment record.

### Step 2: Impact Assessment

Identify ALL affected artifacts. For each, state whether it needs UPDATE, DELETE, or NEW:

**Specifications:**
- [ ] `spec/business/frame.md` — scope change?
- [ ] `spec/business/requirements.md` — requirement change?
- [ ] `spec/business/backlog.md` — story changes?
- [ ] `spec/technical/api-contracts.md` — API change?
- [ ] `spec/technical/architecture.md` — architecture change?
- [ ] `spec/technical/data-model.md` — data model change?

**Stories:**
- [ ] Which completed stories need rework? (create rework stories)
- [ ] Which upcoming stories need modification?
- [ ] What new stories are needed?

**Code:**
- [ ] Which existing code must be refactored?
- [ ] Which code can remain as-is?

Present the impact assessment to the user for confirmation before proceeding.

### Step 3: Update Specs

For each affected spec file, make the change and add a change log entry:

```markdown
## Change Log

| Date | Amendment | Description | Affected Stories | Reason |
|------|-----------|-------------|-----------------|---------|
| YYYY-MM-DD | AMEND-NNN | [what changed] | US-XX-XX, US-YY-YY | [why] |
```

### Step 4: Update Backlog

In `spec/business/backlog.md`:
1. **Modify** affected story descriptions and acceptance criteria
2. **Add** rework stories for already-implemented code that needs changes:
   ```
   REWORK-XX-XX: Refactor [component] per AMEND-NNN
   ```
3. **Remove** or mark as `deprecated` any stories that are no longer valid
4. **Update** story points if scope changed

### Step 5: Update Current Iteration (if mid-iteration)

If we are currently in an active iteration, ask the user to choose:

**Option A: Continue + Carry Forward**
> Finish unaffected stories in this iteration. Move amended stories to the next iteration.

**Option B: Halt and Re-Plan**
> Stop current iteration. Run `iteration-planning.prompt.md` with the updated backlog.

**Option C: Absorb**
> If the amendment is small, absorb the changes into the current iteration's remaining stories.
> Only valid if amendment affects ≤2 stories and adds ≤5 points.

Update `spec/iterations/iteration-N/plan.md` accordingly.

### Step 6: Record the Amendment

Create `spec/amendments/AMEND-NNN.md`:

```markdown
---
id: AMEND-NNN
date: YYYY-MM-DD
title: "Brief description"
trigger: "What happened that caused this amendment"
affected_specs: [SPEC-IDs]
affected_stories: [US-IDs]
decision: "continue | halt | absorb"
status: applied
---

## Original Decision
[What was originally specified]

## What We Learned
[What happened during implementation]

## New Decision
[What we're changing to]

## Impact
- Stories modified: [list]
- Stories added: [list]
- Stories removed: [list]
- Rework needed: [list of rework stories]
```

### Step 7: Confirm

Present a summary to the user:
> "Amendment AMEND-NNN applied. [N] spec files updated, [M] stories modified,
> [P] rework stories created. The current iteration has been [continued/halted/absorbed].
> Next step: [what to do next]."

## Output Artifacts

- `spec/amendments/AMEND-NNN.md` — amendment record
- Updated spec files (with change log entries)
- Updated `spec/business/backlog.md`
- Updated iteration plan (if mid-iteration)
