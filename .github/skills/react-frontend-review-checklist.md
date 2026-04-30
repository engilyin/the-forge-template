---
name: "React Frontend Review Checklist"
description: "Mandatory pre-commit review checklist for every React/TypeScript frontend story. All items must pass before committing and raising a PR."
user-invocable: true
---

# React Frontend — Pre-Commit Review Checklist

> **Every React frontend story MUST pass this checklist before the code is committed and a PR is raised.**
> Validate each item against the changes made. Fix every ❌ before proceeding.
>
> **Mandatory build sequence (in order):**
> 1. Implement the story following `.github/skills/react-web-frontend.md`
> 2. All items on this checklist pass
> 3. `npx prettier --write src/` — auto-format code
> 4. `npx eslint src/` — must pass with zero errors
> 5. `npx tsc --noEmit` — must pass with zero type errors
> 6. `npm run build` — must succeed
> 7. `npx vitest run` — all tests pass (if tests exist)
> 8. Commit with default author — NO Co-authored-by trailer
> 9. Push branch and open PR

---

## 1. Project Structure Compliance

- [ ] **Feature module exists** — every new domain feature lives in `src/features/<domain>/` with a `Module.tsx` entry point that defines sub-routes.
- [ ] **No cross-feature imports** — feature modules never import from sibling `src/features/<other>/` directories. Shared code lives in `components/`, `hooks/`, `lib/`, `types/`, or `store/`.
- [ ] **Hooks in correct location** — custom hooks live in `src/hooks/<domain>/`. Feature-specific hooks that are reused outside the feature must be promoted to `src/hooks/`.
- [ ] **Types in correct location** — TypeScript types and interfaces live in `src/types/<domain>.ts`. No inline type definitions in component files unless truly local.
- [ ] **API services in correct location** — all API call functions live in `src/services/api/<domain>.ts`. No raw `axios` calls in components, hooks, or store files.
- [ ] **Store files in correct location** — Zustand stores live in `src/store/use<Entity>Store.ts`.

---

## 2. Feature Module Correctness

- [ ] **Module.tsx uses `<Routes>` with sub-routes** — each module defines `index`, `:id`, `:id/edit`, `create` routes as appropriate.
- [ ] **Lazy loading** — feature modules are loaded via `lazy()` in `router.tsx`. Only auth and dashboard may be eagerly loaded.
- [ ] **Thin route pages** — route page components are orchestrators: they compose shared components, call hooks, and render. They contain zero business logic.
- [ ] **No page-level API calls** — pages use TanStack Query hooks from `src/hooks/`, never call API functions directly.

---

## 3. API Communication — Layer Isolation

- [ ] **All HTTP calls go through `src/services/api/*.ts`** — no `axios.get()`, `fetch()`, or direct HTTP calls in components, hooks, or stores.
- [ ] **Uses correct Axios instance** — protected endpoints use `clientApi`; public endpoints (login, register) use `tokenlessApi`. Never create ad-hoc Axios instances.
- [ ] **API functions return typed data** — every API function has explicit input and return types (from `src/types/`). No `any` return types.
- [ ] **No business logic in API layer** — API service files are pure data transport: serialize request → HTTP call → deserialize response. No conditionals, no transformations.
- [ ] **Query keys follow convention** — TanStack Query keys follow `['entity', ...params]` pattern (e.g., `['guardians', guardianId]`).

---

## 4. State Management

- [ ] **Server data managed by TanStack Query** — lists, details, and mutations use `useQuery` / `useMutation`. Never store server data in Zustand.
- [ ] **Client state in Zustand** — auth tokens, UI preferences (sidebar, theme), and table state (sort, filter, page size) use Zustand stores.
- [ ] **Zustand stores are minimal** — stores hold only state + actions. No derived computations or API calls inside stores.
- [ ] **Persisted stores annotated** — stores using `persist()` middleware have a unique storage key (e.g., `app-auth`, `app-layout`).
- [ ] **No prop drilling for global state** — use Zustand selectors (`useStore(s => s.field)`) or context, not deep prop chains.
- [ ] **No large data in stores** — entity lists, arrays of records, and API responses must NOT be stored in Zustand. Use TanStack Query cache.

---

## 5. Forms

- [ ] **React Hook Form for all forms** — create/edit forms use `useForm()` from react-hook-form. No manual `useState` for form values.
- [ ] **FormSpec pattern for CRUD** — CRUD forms use the shared `RecordForm` shell with a per-entity `FormSpec`. Thin page wrappers, not per-entity form shells.
- [ ] **Dirty-field patch** — edit forms submit only changed fields (dirty-field tracking), not the entire object, when the backend supports PATCH.
- [ ] **Zod or validator-based validation** — validation uses Zod schemas or the shared validators from `src/validation/validators.ts`. No ad-hoc inline validation logic.
- [ ] **Shared field components** — form fields use shared components from `src/components/forms/` (TextField, CheckboxField, DropdownField, etc.). No raw `<input>` elements in pages.
- [ ] **Loading and error states displayed** — forms show loading spinners during fetch, disable submit during mutation, and display error messages on failure.

---

## 6. TypeScript Strictness

- [ ] **No `any` types** — zero uses of `any` in new or changed code. Use `unknown`, generics, or specific types.
- [ ] **No `// @ts-ignore` or `// @ts-expect-error`** — fix the type error instead of suppressing it.
- [ ] **No `as` type assertions for convenience** — type assertions are only acceptable for narrowing from `unknown` after a runtime check.
- [ ] **All function parameters typed** — no untyped function parameters or return types.
- [ ] **Interfaces and types exported from `src/types/`** — shared types are centralized, not defined inline in component files.
- [ ] **Enums avoided** — use `as const` objects or union types instead of TypeScript enums.

---

## 7. Component Correctness

- [ ] **No business logic in components** — components render UI. Conditional logic, data transformations, and side effects live in hooks or lib utilities.
- [ ] **Shared components for repeated patterns** — if the same UI pattern appears in more than one page, extract it to `src/components/`.
- [ ] **Variant-based components** — button variants, badge colors, and similar visual variants use `class-variance-authority` (CVA) or equivalent, not conditional className strings.
- [ ] **Accessible components** — interactive elements have proper ARIA attributes. Forms use `<label>` elements. Modals trap focus.
- [ ] **No `key={index}` on dynamic lists** — use stable, unique identifiers as keys (e.g., `entity.id`).
- [ ] **No inline functions in JSX** for callbacks passed to child components — extract to named functions or use the React compiler's auto-memoization.

---

## 8. Hook Correctness

- [ ] **Custom hooks in `src/hooks/`** — reusable logic is extracted into custom hooks, not duplicated across components.
- [ ] **Dependency arrays correct** — `useEffect`, `useMemo`, `useCallback` dependency arrays include all referenced values. ESLint `react-hooks/exhaustive-deps` rule must pass.
- [ ] **No side effects in render** — API calls, subscriptions, and DOM mutations happen in `useEffect`, `useMutation`, or event handlers — never during render.
- [ ] **Query hooks wrap TanStack Query** — all `useQuery`/`useMutation` calls are in dedicated hook files (e.g., `useGuardians.ts`), not inline in components.
- [ ] **Mutation hooks invalidate related queries** — after a successful create/update/delete, the relevant query cache is invalidated via `queryClient.invalidateQueries()`.

---

## 9. Styling

- [ ] **Tailwind CSS for utility classes** — use Tailwind utilities, not inline `style={}` props.
- [ ] **shadcn/ui for primitives** — use shadcn/ui components (Button, Card, Input, etc.) as the base. Do not introduce Ant Design, Material UI, or other UI libraries.
- [ ] **No raw utility class walls in pages** — if a page has more than 3 lines of className strings, extract into a shared component.
- [ ] **Dark mode supported** — new components respect the `dark:` Tailwind variant. No hardcoded colors that break in dark mode.
- [ ] **Theme tokens used** — brand colors use CSS custom properties from `src/styles/theme.css`, not hardcoded hex values.
- [ ] **`cn()` utility for conditional classes** — use the `cn()` helper (clsx + tailwind-merge) for conditional class merging, not string concatenation.

---

## 10. Build Verification (mandatory before commit)

- [ ] `npx prettier --write src/` — no formatting violations remain
- [ ] `npx eslint src/` — **zero errors** (warnings acceptable but should be minimized)
- [ ] `npx tsc --noEmit` — **zero type errors**
- [ ] `npm run build` — **BUILD SUCCESSFUL**, zero compile errors
- [ ] `npx vitest run` — **all tests pass** (if tests exist)
- [ ] No regressions — all tests that existed before the story still pass

---

## 11. Commit & PR

- [ ] **Author is default set on the repo** — use `git commit -m "US-XX-XX commit description"` with no `--author` flag, no `Co-authored-by` trailers. The commit author must be the default configured on the local machine, with no additional trailers.
- [ ] **NO `Co-authored-by: Copilot` trailer** — this trailer must never appear in any commit message in this repository
- [ ] **Branch name matches story** — `feature/US-FE-XX-YY` format
- [ ] **PR created in the correct project repo** — not in the scaffold root repo
- [ ] **Story status updated** — story file in `spec/iterations/` status changed to `done`

---

## Quick Reference — Common Anti-Patterns to Reject

| Anti-Pattern | Correct Approach |
|---|---|
| `axios.get('/api/...')` in a component | Use API service function from `services/api/*.ts` |
| `const [data, setData] = useState([])` for server data | Use `useQuery` from TanStack Query |
| `any` type on function parameter | Use specific type from `src/types/` |
| Raw `<input>` element in form page | Use `TextField` or `FormField` from `components/forms/` |
| `import { something } from '../../../features/users/...'` | Move shared code to `components/`, `hooks/`, or `lib/` |
| `useEffect(() => { fetch(...) }, [])` | Use `useQuery` hook |
| `key={index}` on mapped list items | Use stable ID: `key={item.id}` |
| `style={{ color: '#F49D36' }}` | Use Tailwind class or CSS custom property |
| Zustand store holding API response arrays | Use TanStack Query cache; store only sort/filter/page state |
| Manual `React.memo()` wrapper | Let babel-plugin-react-compiler handle memoization |
| `// @ts-ignore` to suppress type error | Fix the type error properly |
| `import { Button } from 'antd'` | Use `import { Button } from '@/components/ui/button'` (shadcn) |
| Giant className string in page component | Extract to shared component with CVA variants |
| Form with manual `useState` for each field | Use `useForm()` from react-hook-form |
| Inline Zod schema in component file | Define schema in `src/types/` or `src/validation/` |
| `queryClient.fetchQuery` in component render | Use `useQuery` hook for declarative data fetching |
| Committing without running prettier/eslint | Always run format + lint before commit |
| `Co-authored-by: Copilot` in commit message | Remove — only default author, no trailers |
