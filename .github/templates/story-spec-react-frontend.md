---
id: US-XX-XX
title: "TITLE"
iteration: N
phase: P
type: feature | bugfix | rework
agent: react-frontend-developer
project: PROJECT_NAME
points: N
priority: must-have | should-have | could-have
dependencies: []
status: draft | ready | preprocessed | implementing | done | failed | blocked
---

## Story

**As a** [ACTOR],
**I want** [ACTION on PAGE/FEATURE],
**So that** [BUSINESS VALUE].

## Context

<!-- 2-3 sentences of domain context. No links to external files.
     Include ONLY facts the agent needs to implement THIS story. -->

## Implementation Target

### Files to Create

| Layer | File Path | Description |
|-------|-----------|-------------|
| Page | `src/features/FEATURE/pages/NamePage.tsx` | Main page component |
| Table Component | `src/features/FEATURE/components/NameTable.tsx` | Data table (if list view) |
| Form Component | `src/features/FEATURE/components/NameForm.tsx` | Form (if create/edit) |
| Dialog Component | `src/features/FEATURE/components/NameDialog.tsx` | Dialog (if modal form) |
| API Service | `src/services/api/domainApi.ts` | Centralized API calls |
| Query Hook | `src/hooks/useDomainAction.ts` | React Query hook |
| Types | `src/types/domain.ts` | TypeScript interfaces |
| Test | `src/features/FEATURE/__tests__/NamePage.test.tsx` | Component tests |

### Files to Modify

| File Path | What Changes |
|-----------|-------------|
| `src/router.tsx` | Add route for new page |

<!-- Use "None" if no modifications needed -->

## Code Skeleton

### Page Component

```tsx
import { useParams } from 'react-router-dom';
import { NameTable } from '../components/NameTable';
// TODO: additional imports

export function NamePage() {
  // TODO: implement
  // Pattern:
  // 1. useQuery hook for data fetching
  // 2. Render loading/error/data states
  // 3. Pass data to child components
  return (
    <div>
      {/* TODO: page layout */}
    </div>
  );
}
```

### API Service

```ts
import { apiClient } from './apiClient';
import type { DomainType, CreateDomainRequest } from '@/types/domain';

// TODO: implement API functions
// Pattern: one function per endpoint
// export async function listDomains(params: ListParams): Promise<PagedResponse<DomainType>> {
//   return apiClient.get('/api/v2/staff/domains', { params });
// }
```

### Query Hook

```ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { listDomains, createDomain } from '@/services/api/domainApi';

// TODO: implement hooks
// export function useDomainList(params: ListParams) {
//   return useQuery({
//     queryKey: ['domains', params],
//     queryFn: () => listDomains(params),
//   });
// }
```

### Types

```ts
// TODO: define interfaces that match API contracts
// export interface DomainType {
//   id: number;
//   name: string;
// }
```

### Table Component

```tsx
import type { ColumnDef } from '@tanstack/react-table';
// TODO: implement table with columns

// export function NameTable({ data }: { data: DomainType[] }) {
//   const columns: ColumnDef<DomainType>[] = [
//     // TODO: define columns
//   ];
//   return <DataTable columns={columns} data={data} />;
// }
```

### Test

```tsx
import { render, screen } from '@testing-library/react';
import { NamePage } from '../pages/NamePage';

// TODO: one test per acceptance scenario
// describe('NamePage', () => {
//   it('SC-1: renders list of items', () => {});
//   it('SC-2: shows empty state', () => {});
// });
```

## Acceptance Criteria

**SC-1: [Scenario name]**
- Given [precondition]
- When [action]
- Then [expected outcome]

**SC-2: [Scenario name]**
- Given [precondition]
- When [action]
- Then [expected outcome]

## Mandatory Rules (Inline — DO NOT SKIP)

### Project Structure Rules
1. Pages in `src/features/FEATURE/pages/`, components in `src/features/FEATURE/components/`
2. API calls ONLY in `src/services/api/` — never call `fetch`/`axios` directly in components
3. One API service file per domain/resource
4. Types in `src/types/` — interfaces match API contract exactly

### State Rules
5. Server state via React Query (`@tanstack/react-query`) — NOT Zustand/Redux
6. Client-only UI state via `useState` / Zustand
7. NEVER cache server data in Zustand — that's React Query's job
8. Invalidate queries after mutations: `queryClient.invalidateQueries()`

### Component Rules
9. Forms use `react-hook-form` with `zodResolver` for validation
10. NO `any` type — use proper TypeScript interfaces everywhere
11. Props interfaces defined and exported for every component
12. Error boundaries around data-fetching pages

### Style Rules
13. Use project design system components — NO raw HTML for buttons, inputs, tables
14. Responsive layout — test at mobile and desktop breakpoints
15. Loading states: show skeleton/spinner during data fetch

### Test Rules
16. One test per acceptance scenario (SC-1, SC-2, ...)
17. Use `@testing-library/react` — test behavior, not implementation
18. Mock API calls, don't mock React Query internals

## Validation Commands

Run these IN ORDER after implementation:

```bash
# 1. Format
npx prettier --write src/

# 2. Lint
npx eslint src/

# 3. Type check
npx tsc --noEmit

# 4. Build
npm run build

# 5. Tests
npx vitest run
```

If any command fails: fix the error, re-run the failing command. If it fails twice, commit as WIP.

## Commit Command

```bash
git add .
git commit -m "feat(US-XX-XX): TITLE"
```

NO `Co-authored-by` trailer. Author is taken from local git config (set via `setauthor.sh` or `.forge/config.env`).

## Definition of Done

- [ ] API service uses centralized `apiClient` — no direct fetch/axios in components
- [ ] TypeScript types match API contract
- [ ] React Query for all server state
- [ ] Forms use react-hook-form + zod validation
- [ ] Tests cover all acceptance scenarios
- [ ] `npx prettier --write src/` run
- [ ] `npx eslint src/` clean
- [ ] `npx tsc --noEmit` clean
- [ ] `npm run build` green
- [ ] Committed with correct author
