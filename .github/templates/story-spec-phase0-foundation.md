---
id: US-XX-00
title: "Phase 0 Foundation — [Iteration Goal Short]"
iteration: N
phase: 0
type: foundation
agent: java-backend-developer
project: PROJECT_NAME
points: 3
priority: must-have
dependencies: []
status: draft
---

## Story

**As a** development team,
**I want** shared entity changes, OpenAPI spec updates, and generated code committed to `main`,
**So that** all feature branches in this iteration start from a consistent, compile-clean baseline.

## Context

Phase 0 stories run FIRST and merge to `main` BEFORE any feature branch is created.
This prevents merge conflicts caused by multiple stories touching the same entity or schema.

## Scope — What Goes Here

1. **Entity field additions/removals** needed by stories in this iteration
2. **Flyway migration scripts** for the schema changes
3. **OpenAPI spec updates** (`api-contracts.yaml`) for new/changed endpoints
4. **`./gradlew openApiGenerate`** to regenerate Java stubs
5. **Shared service/utility** classes used by multiple stories
6. **Const/enum additions** needed by multiple stories

## Changes

### Entity Changes

| Entity | Change | Required By |
|--------|--------|-------------|
| `EntityName` | Add field `fieldName` (type, default) | US-XX-01, US-XX-02 |

### Migration Script

```sql
-- Flyway: V{N}__iteration_{N}_foundation.sql
-- TODO: write migration DDL
```

### OpenAPI Spec Changes

| Endpoint | Change |
|----------|--------|
| `POST /api/v2/staff/resource` | Added to spec |
| `GET /api/v2/staff/resource` | Added `locked` query param |

### Generated Code

After spec changes:
```bash
./gradlew openApiGenerate
```

Verify generated interfaces compile:
```bash
./gradlew clean build
```

## Acceptance Criteria

**SC-1: Entity changes compile**
- Given the entity field changes above
- When `./gradlew clean build` is run
- Then compilation succeeds with zero errors

**SC-2: OpenAPI stubs regenerated**
- Given the updated `api-contracts.yaml`
- When `./gradlew openApiGenerate` is run
- Then generated interfaces contain methods for all new endpoints

**SC-3: Migration script is valid SQL**
- Given the migration file in `db/migration/`
- When reviewed manually
- Then it contains valid DDL matching the entity field changes

## Mandatory Rules (Inline)

1. This story MUST be merged to `main` before ANY feature branch is created
2. NO business logic in this story — entities, schema, and stubs only
3. Do NOT implement controllers or services — that comes in feature stories
4. Flyway migration naming: `V{version}__description.sql`
5. Test that `./gradlew clean build` passes AFTER all changes

## Validation Commands

```bash
./gradlew openApiGenerate
./gradlew spotlessApply
./gradlew clean build
```

## Commit Command

```bash
git add .
git commit -m "chore(US-XX-00): Phase 0 foundation for iteration N"
```

## Definition of Done

- [ ] All entity field changes made
- [ ] Migration script created (if schema changes)
- [ ] OpenAPI spec updated for all new endpoints
- [ ] `./gradlew openApiGenerate` run successfully
- [ ] `./gradlew clean build` green
- [ ] Merged to `main`
- [ ] All feature branches created AFTER this merge
