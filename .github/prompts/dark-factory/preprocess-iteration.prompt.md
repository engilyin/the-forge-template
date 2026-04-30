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
4. The relevant sections of:
   - `spec/technical/api-contracts.md` (only for the story's endpoint)
   - `spec/technical/g2sentry-portal-api-design-decisions.md` (only relevant DDs)
   - `.github/skills/java-spring-review-checklist.md` or `.github/skills/react-frontend-review-checklist.md`

## Process

For EACH story spec in the iteration:

### Step 1: Determine File Set

Based on the story type and agent, determine the exact files to create/modify:

**Java Backend Story:**
| Layer | File Pattern |
|-------|-------------|
| Controller | `src/main/java/.../controllers/{Domain}Controller.java` |
| Controller Mapper | `src/main/java/.../controllers/mappers/{Domain}ApiMapper.java` |
| Service | `src/main/java/.../services/{domain}/{FunctionalName}Service.java` |
| Service Request | `src/main/java/.../services/{domain}/models/{Name}Request.java` |
| Service Response | `src/main/java/.../services/{domain}/models/{Name}Response.java` (if needed) |
| Service Mapper | `src/main/java/.../services/{domain}/mappers/{Domain}ServiceMapper.java` |
| DAO Repository | `src/main/java/.../dao/{Entity}Repository.java` |
| DAO Projection | `src/main/java/.../dao/projections/{Name}Projection.java` (if read query) |
| Unit Test | `src/test/java/.../services/{domain}/{FunctionalName}ServiceTest.java` |

**React Frontend Story:**
| Layer | File Pattern |
|-------|-------------|
| Page | `src/features/{feature}/pages/{PageName}Page.tsx` |
| API Service | `src/services/api/{domain}Api.ts` |
| Query Hook | `src/hooks/use{Domain}{Action}.ts` |
| Form Component | `src/features/{feature}/components/{Name}Form.tsx` |
| Table Component | `src/features/{feature}/components/{Name}Table.tsx` |
| Store | `src/store/{domain}Store.ts` (if needed) |
| Types | `src/types/{domain}.ts` |
| Test | `src/features/{feature}/__tests__/{PageName}Page.test.tsx` |

### Step 2: Generate Code Skeletons

For each file, write a literal Java/TypeScript skeleton with:
- Correct package/import statements
- Class/function signature
- `// TODO:` comments for the agent to fill in
- Key patterns pre-written (reactive chains, mapper calls, hook usage)

Use the API contract and data model to derive exact field names, types, and method signatures.

### Step 3: Inline Mandatory Rules

From the relevant review checklist, select the 10-15 rules most relevant to THIS story type.
Copy them verbatim into the story spec's "Mandatory Rules" section. Organize them under:
- Layer Rules
- Mapper Rules
- Reactive/State Rules
- Test Rules
- Style Rules

### Step 4: Add Validation Commands

For Java stories:
```bash
./gradlew spotlessApply
./gradlew clean build
```

For React stories:
```bash
npx prettier --write src/
npx eslint src/
npx tsc --noEmit
npm run build
npx vitest run
```

### Step 5: Add Commit Command

```bash
git add .
git commit -m "feat(US-XX-XX): Story title"
```

Push and open PR targeting `$FORGE_BASE_BRANCH` (default: `develop`):
```bash
git push origin feature/US-XX-XX-slug
gh pr create --base $FORGE_BASE_BRANCH --head feature/US-XX-XX-slug \
  --title "feat(US-XX-XX): Story title" --body "Implements US-XX-XX."
```

### Step 6: Write the Updated Story Spec

Replace the existing story spec with the enriched version following this EXACT structure:

```markdown
---
id: US-XX-XX
title: "Story Title"
iteration: N
phase: P
agent: [agent-role]
project: [project-name]
points: N
dependencies: [list or empty]
status: ready
---

## Story
[The As-a/I-want/So-that]

## Implementation Target

### Files to Create
[Table of files to create]

### Files to Modify
[Table of existing files and what changes — or "None"]

## Code Skeleton

### [Layer 1: e.g., Controller]
```java
// Full skeleton with TODO markers
```

### [Layer 2: e.g., Service]
```java
// Full skeleton with TODO markers
```

[...one block per file...]

## Acceptance Criteria
[SC-1 through SC-N in Given/When/Then format]

## Mandatory Rules (Inline)
[10-15 most relevant rules, copied from checklists]

## Validation Commands
[Exact commands to run, in order]

## Commit Command
[Exact git commit command]

## Definition of Done
[Checklist]
```

## Confirmation

After enriching all story specs, present a summary:
> "Enriched [N] story specs for iteration [M]. Each spec now contains:
> - Code skeletons for [total files] files
> - [X] inline mandatory rules per story
> - Validation and commit commands
>
> The specs are ready for implementation via `implement-story.prompt.md`."
