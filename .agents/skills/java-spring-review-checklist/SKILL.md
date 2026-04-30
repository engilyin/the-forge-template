---
name: java-spring-review-checklist
description: "Mandatory Java/Spring pre-commit review checklist — 11-section gate covering API-First, layer separation, MapStruct, testing, build verification, and commit rules. MUST pass before every commit."
metadata:
  reference: .github/skills/java-spring-review-checklist.md
---

# java-spring-review-checklist

Mandatory pre-commit review checklist for every Java/Spring Boot WebFlux story. All items must pass before committing and raising a PR.

Keywords: java, spring, webflux, review, checklist, pre-commit, mapstruct, testing, api-first, layer, separation, build

Full reference: `.github/skills/java-spring-review-checklist.md`

Read the full skill file before applying:
```
Read @.github/skills/java-spring-review-checklist.md and run through every checklist item against the current changes.

Minimize boilerplate: prefer convention over configuration where the framework can infer behavior. Specifically, avoid redundant @Column annotations when the Java field name maps reliably to the database column name.
```
