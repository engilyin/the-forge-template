---
name: react-frontend-review-checklist
description: >-
  Mandatory React/TypeScript pre-commit review checklist — 11-section gate covering
  project structure, API isolation, state management, forms, TypeScript strictness,
  component correctness, styling, build verification, and commit rules.
  MUST pass before every commit.
---

# React Frontend Review Checklist

This skill wraps the full checklist at `.github/skills/react-frontend-review-checklist.md`.

## When to invoke

Run this checklist **after** implementing a React frontend story and **before** committing:

1. Implement the story following `.github/skills/react-web-frontend.md`
2. **Invoke this checklist** — validate every section; fix all ❌ findings
3. `npx prettier --write src/`
4. `npx eslint src/`
5. `npx tsc --noEmit`
6. `npm run build`
7. `npx vitest run`
8. Commit and push

## Sections covered

1. Project Structure Compliance
2. Feature Module Correctness
3. API Communication — Layer Isolation
4. State Management
5. Forms
6. TypeScript Strictness
7. Component Correctness
8. Hook Correctness
9. Styling
10. Build Verification
11. Commit & PR

Read the full checklist: `.github/skills/react-frontend-review-checklist.md`
