---
description: "Generate self-contained story specs with inline code skeletons and rules for an iteration. Run BEFORE Dark Factory execution."
agent: 'agent'
tools:
  - read
  - edit
  - search
---

# Pre-Process Iteration — Generate Self-Contained Story Specs

> Run this prompt AFTER iteration planning and BEFORE story implementation.
> It transforms story specs from reference-heavy outlines into self-contained implementation blueprints.

## Purpose

Transform each story spec in the current iteration from a requirements document into a
**self-contained implementation spec** that includes:
1. Literal code skeletons (file paths, package names, class stubs)
2. Inline mandatory rules (copied from checklists, not referenced)
3. Exact validation commands
4. Exact commit command
5. "Files to Create" and "Files to Modify" tables

The goal: **an agent implementing a story should read ONLY the story spec file** and
produce correct code without reading any other document.

## Input

Read:
1. `spec/iterations/[current-iteration]/plan.md` — iteration plan
2. All story specs in `spec/iterations/[current-iteration]/stories/`
3. The agent definition for each story's assigned agent (from `.github/agents/`)
4. The relevant review checklist from `.github/skills/`
5. The appropriate story template from `.github/templates/`

## Process

For EACH story spec in the iteration:

### Step 1: Choose Template

Select the appropriate template:
- Java backend → `.github/templates/story-spec-java-backend.md`
- React frontend → `.github/templates/story-spec-react-frontend.md`
- Phase 0 → `.github/templates/story-spec-phase0-foundation.md`

### Step 2: Determine File Set

Based on the story type, determine the exact files to create/modify using the template's
file table as a starting point. Replace all placeholders with actual package names,
class names, and paths from the project.

### Step 3: Generate Code Skeletons

For each file, write a literal code skeleton with:
- Correct package/import statements
- Class/function signature
- `// TODO:` comments for the agent to fill in
- Key patterns pre-written (reactive chains, mapper calls, hook usage)

Use the API contract and data model to derive exact field names, types, and method signatures.

### Step 4: Inline Mandatory Rules

From the relevant review checklist, select the 10-15 rules most relevant to THIS story type.
Copy them verbatim into the story spec's "Mandatory Rules" section.

### Step 5: Add Validation and Commit Commands

Copy the validation and commit commands from the template, adjusting project-specific details.

### Step 6: Write the Updated Story Spec

Replace the existing story spec with the enriched version following the template structure.
Every section from the template must be present.

## Confirmation

After enriching all story specs, present a summary:
> "Enriched [N] story specs for iteration [M]. Each spec now contains:
> - Code skeletons for [total files] files
> - [X] inline mandatory rules per story
> - Validation and commit commands
>
> The specs are ready for implementation via `implement-story.prompt.md`."
