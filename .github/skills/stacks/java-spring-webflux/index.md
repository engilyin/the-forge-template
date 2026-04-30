# Java / Spring Boot / WebFlux — Tech Stack Index

## Overview

Backend services built with Spring Boot 3 + WebFlux (reactive), R2DBC for database access,
MapStruct for mapping, and Gradle for builds. Follows API-First with OpenAPI code generation.

## Stack Files

| File | Purpose |
|------|---------|
| [`patterns.md`](patterns.md) | → `.github/skills/spring-boot-webflux.md` — Project structure, layers, reactive patterns, MapStruct, error handling |
| [`review-checklist.md`](review-checklist.md) | → `.github/skills/java-spring-review-checklist.md` — 12-section mandatory pre-commit gate |
| [`story-template.md`](story-template.md) | → `.github/templates/story-spec-java-backend.md` — Code skeleton template |
| [`phase0-template.md`](phase0-template.md) | → `.github/templates/story-spec-phase0-foundation.md` — Foundation story template |
| `.github/skills/api-first.md` | API-First conventions (shared across stacks) |

> **Migration path:** The files above currently reference existing skill files at their original
> locations. As patterns grow, split them into focused files within this directory:
> - `patterns-reactive.md` — Reactive chains, error handling, backpressure
> - `patterns-mappers.md` — MapStruct conventions, inheritance, custom mappings
> - `patterns-testing.md` — StepVerifier, test slices, integration tests
> - `patterns-dao.md` — R2DBC repositories, projections, custom queries

## Build & Validation Commands

```bash
# 1. Code generation (API-First)
./gradlew openApiGenerate

# 2. Format
./gradlew spotlessApply

# 3. Build (compile + unit tests)
./gradlew clean build

# 4. Integration tests
./gradlew integrationTest
```

## Mandatory Development Workflow

1. **Read project-specific design decisions** — for stories in any project, read `spec/technical/<project>-design-decisions.md` in full before writing any code. Keep those decisions active in context throughout the story.
2. `./gradlew openApiGenerate` — generate Java classes from the OpenAPI spec BEFORE writing any implementation code
3. Implement the story (controller implements generated interface, service in its own class, DAO with projections)
4. **Run the Java Spring Review Checklist** (`review-checklist.md`) — go through **every single item** section by section. Fix **ALL** findings before proceeding. Do NOT skip sections. This includes the project-specific decisions section.
5. `./gradlew spotlessApply` — format code
6. `./gradlew clean build` — must succeed with zero warnings/errors
7. `./gradlew integrationTest` — must succeed with all tests passing
8. Commit with `git commit` (author set by `.forge/init-worktree.sh`)
9. Push and open PR with `gh pr create --base $FORGE_BASE_BRANCH`

## Code Style Rules

- **Always import, never fully-qualify** — Never use fully-qualified class names (e.g., `com.example.SomeClass`) inline in code when an `import` statement is available. The only exception is when two classes share the same simple name and disambiguation is required.

## Agent

`java-backend-developer` — see `.github/agents/java-backend-developer.md`

## Secret/Config Files

Files to copy to worktrees (gitignored):
- `src/main/resources/application-default.properties`
- `src/main/resources/application-local.properties`
