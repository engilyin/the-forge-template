# React / TypeScript (Web) — Tech Stack Index

## Overview

Web frontend built with React 18+, TypeScript, Vite, React Router, TanStack Query,
React Hook Form, Zustand for state, and shadcn/ui components. Uses centralized API clients.

## Stack Files

| File | Purpose |
|------|---------|
| [`patterns.md`](patterns.md) | → `.github/skills/react-web-frontend.md` — Feature routing, API clients, CRUD patterns, forms, Zustand |
| [`review-checklist.md`](review-checklist.md) | → `.github/skills/react-frontend-review-checklist.md` — 11-section mandatory pre-commit gate |
| [`story-template.md`](story-template.md) | → `.github/templates/story-spec-react-frontend.md` — Code skeleton template |
| [`virtualized-tables.md`](virtualized-tables.md) | → `.github/skills/react-virtualized-crud-tables.md` — Large data grid patterns |

> **Migration path:** As patterns grow, split into focused files:
> - `patterns-forms.md` — React Hook Form, validation, Zod schemas
> - `patterns-tables.md` — Table components, sorting, filtering, pagination
> - `patterns-state.md` — Zustand stores, React Query cache, optimistic updates
> - `patterns-api.md` — API client, interceptors, error handling
> - `patterns-testing.md` — Vitest, Testing Library, MSW mocks

## Build & Validation Commands

```bash
# 1. Install dependencies
npm ci

# 2. Format
npx prettier --write src/

# 3. Lint
npx eslint src/

# 4. Type check
npx tsc --noEmit

# 5. Build
npm run build

# 6. Test
npx vitest run
```

## Mandatory Development Workflow

1. `npm ci` — ensure dependencies
2. Implement following patterns.md
3. Run review checklist — fix ALL findings
4. `npx prettier --write src/`
5. `npx eslint src/` — zero errors
6. `npx tsc --noEmit` — zero type errors
7. `npm run build` — success
8. `npx vitest run` — all pass
9. Commit with `git commit`
10. Push and open PR

## Agent

`react-frontend-developer` — see `.github/agents/react-frontend-developer.md`

## Secret/Config Files

Files to copy to worktrees (gitignored):
- `.env`
- `.env.local`
- `.env.development.local`
