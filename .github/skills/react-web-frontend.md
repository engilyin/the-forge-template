# ---
title: "React Web Frontend Quality Skill"
description: "Quality guidance for React + TypeScript web apps: routing, state, testing, and UI architecture."
tags: [skill, frontend, react]
type: skill
---

# React Web Frontend Quality Skill

Use this skill for React web applications built with TypeScript and Vite. It is the primary quality reference for React-based websites and internal web apps in FORGE projects.

This skill is based on a proven pattern used in a real CRUD-heavy admin application:

- React with strict TypeScript
- Vite
- React Router module-based routing
- TanStack Query for server state where caching helps
- Zustand for focused client state
- Axios clients with centralized auth refresh
- shadcn/ui and Radix primitives over a shared design system
- reusable CRUD form and virtual table primitives

For very large bounded-memory tables, use this skill together with `.github/skills/react-virtualized-crud-tables.md`.

---

## Baseline Stack

- React: current stable version used by the repo
- TypeScript: `strict: true`
- Build: Vite
- Routing: React Router with lazy-loaded feature modules
- Server state: TanStack Query
- Client state: Zustand
- Forms: React Hook Form
- Validation: use the existing validation approach consistently; Zod is acceptable when adopted deliberately for a feature or project
- HTTP: Axios through centralized API clients
- UI: shadcn/ui, Radix primitives, Tailwind CSS, project-specific shared components
- Tests: Vitest and React Testing Library

Do not mix competing architectural styles in one app. Follow the existing project's routing, form, state, and design-system conventions.

---

## Architecture Principles

### Separate route, screen, hook, service, and store responsibilities

- `src/features/` owns feature route modules and thin route entry files
- `src/components/` owns reusable UI, layout, dialogs, pages, forms, and table parts
- `src/hooks/` owns query hooks, mutation hooks, and reusable controller logic
- `src/services/` owns HTTP clients and backend-facing API modules
- `src/store/` owns focused persisted client state
- `src/lib/` owns cross-cutting utilities such as guards, navigation, table sync, and error helpers
- `src/integrations/` owns framework wiring such as TanStack Query provider setup
- `src/types/` owns app and API-facing TypeScript models
- `src/validation/` owns reusable validation logic
Pages and route files should stay thin. Business flow belongs in hooks and services.

The table layer may fetch pages, virtualize rows, and prune pages outside a buffer window. That is preferable to caching every loaded page forever. For the full table architecture, read `.github/skills/react-virtualized-crud-tables.md`.
---

### Feature module structure

Prefer a feature-module layout like this:

```text
src/
├── main.tsx
├── router.tsx
├── components/
│   ├── ui/
│   ├── forms/
│   ├── pages/
│   ├── parts/
│   └── layout/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── [entity]/
│   │   ├── Module.tsx
│   │   └── pages/
│   └── [feature]/
├── hooks/
│   ├── [entity]/
│   ├── [feature]/
│   └── forms/
├── services/
│   ├── clientApi.ts
│   └── api/
├── store/
├── lib/
├── integrations/
├── styles/
├── types/
└── validation/
```

Use shared primitives for recurring CRUD workflows instead of rebuilding list, toolbar, and form mechanics for each entity.

---

## App Shell And Root Wiring

### `main.tsx` owns provider composition

The app entry should compose global providers and global UI hosts exactly once:

- Query provider
- router
- dialog host
- toast container
- update/version banner

```tsx
const { queryClient } = getContext();

createRoot(root).render(
  <QueryProvider queryClient={queryClient}>
    <>
      <AppRouter />
      <DialogHost />
      <ToastContainer />
      <UpdateBanner />
    </>
  </QueryProvider>,
);
```

Do not create new `QueryClient` instances during rerenders.

### Root layout owns shell concerns

The root layout should own:

- theme provider
- header and top-level layout frame
- route outlet
- navigation initialization
- agency or tenant change side-effects
- devtools wiring when enabled

Keep route-level content under the layout; do not duplicate shell UI across features.

---

## Routing And Navigation

### Route modules

Use lazy-loaded feature modules in `router.tsx`, then let each feature own its nested routes in `features/<feature>/Module.tsx`.

```tsx
const CustomersModule = lazy(() => import('./features/customers/Module'));

<Route path="customers/*" element={<CustomersModule />} />
```

Feature module example:

```tsx
export default function CustomersModule() {
  return (
    <Routes>
      <Route index element={<CustomersIndex />} />
      <Route path="create" element={<CustomerCreate />} />
      <Route path=":customerId" element={<CustomerView />} />
      <Route path=":customerId/edit" element={<CustomerEdit />} />
    </Routes>
  );
}
```

### Guard ownership

Protected route files should enforce access near the route boundary. In this pattern, route components call `requireAuth()` and `requireRole()` inside `useEffect`.

```tsx
useEffect(() => {
  requireAuth();
  requireRole('root', 'admin');
}, []);
```

If a project later adopts TanStack Router, preserve the same boundary: authorization belongs to the route layer, not random child components.

### Navigation rules

- Use shared navigation helpers from `lib/navigation` when the project standardizes imperative navigation there
- Keep path-building centralized for parameterized routes
- Preserve intended-path redirects during auth flows
- Do not scatter manual `window.location` calls through feature components except where the guard strategy explicitly requires it

---

## API Communication

### Centralize API clients

Create shared axios clients in `services/clientApi.ts` or equivalent. Typical split:

- `publicApi` for login/refresh/public endpoints
- `protectedApi` or authenticated client for protected endpoints

The client layer owns:

- base URL
- auth header injection
- refresh-token flow
- agency or tenant hint headers
- normalized error messages
- one-time retry logic for 401 refresh scenarios

```ts
protectedApi.interceptors.request.use((config) => {
  const token = useAuthStore.getState().accessToken;
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});
```

### API module rules

- Put entity endpoints in `services/api/<entity>.ts`
- Export typed functions like `list`, `get`, `create`, `update`, `remove`
- Keep endpoint functions pure and thin
- Do not build raw axios calls in components or page files
- Convert backend errors into friendly messages at the service boundary

```ts
export async function listEntities(params?: { first?: number; max?: number; sort?: string }) {
  const res = await protectedApi.get<EntityListResponse>('/entities', { params });
  return res.data;
}
```

---

## Query, Mutation, And Fetch Strategy

### Use TanStack Query where caching is the right tool

TanStack Query is the default for:

- detail screens
- dashboard widgets
- lookups and reference data
- standard create/update/delete mutations

Mutation hooks should invalidate or update the relevant keys explicitly.

```ts
export function useCreateEntity() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: create,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['entities'] });
    },
  });
}
```

### Do not force `useInfiniteQuery` for virtualized tables

For large virtualized CRUD tables with stateless paging, this architecture prefers a custom fetch-page pattern plus a bounded-memory `DataTable` page cache.

Use TanStack Query only when its cache helps. Do not let it become an unbounded in-memory page store.

Good fit for custom table fetchers:

- offset or `first/max` paging APIs
- infinite virtual scrolling
- aggressive page pruning requirements
- table-owned page windows and state-manager orchestration

Read `.github/skills/react-virtualized-crud-tables.md` for the full architecture, state-manager contract, large-dataset pitfalls, and row-update patterns.

---

## Communication Between UI Parts

Reusable systems work only when communication contracts are explicit.

### Preferred communication model

#### Toolbar <-> Feature store

Toolbar components should emit user intent only:

- search text changed
- filter submitted
- filters cleared
- refresh requested
- page size changed

The toolbar should not know how data is fetched.

Example:

- `EntityToolbar` submits values
- the feature writes them into `useEntityTableStore`
- the table subscribes through `stateManager.subscribe()`
- the table resets and refetches

This keeps the toolbar reusable and dumb.

#### Feature page <-> DataTable

The feature page is the orchestrator.

It builds the `stateManager` and passes:

- `getState()`
- `subscribe()`
- `updateSort()`
- `fetchPage()`

The feature page may also hold a `ref` to the table so the toolbar or other UI can call `refresh()` when needed.

#### Row actions <-> Table / Page

Row action components should:

- receive the row data
- execute async operations
- emit the outcome upward

They should not own routing, cache design, or feature-level state.

Patterns like a generic `RowActions` component are correct when they:

- stop row click propagation
- execute the action
- call a parent callback with either a patched row payload or a `__refresh` signal

#### Dialogs / global UI services

Cross-cutting interactions should use shared infrastructure:

- `DialogHost` / dialog service for imperative dialog opening
- `ToastContainer` for global notifications
- query invalidation for server-state refresh
- table `updateRow()` / `refresh()` for list updates

### Rules of thumb

- child components emit intent; parents choose orchestration
- shared stores hold durable cross-screen state, not ephemeral component chatter
- use explicit callback props instead of hidden cross-component coupling
- prefer a single orchestration owner per feature page

---

## State Management

Choose the smallest tool that fits.

| State Type | Tool | Examples |
|-----------|------|----------|
| Local interaction state | `useState` / `useReducer` | modal open, local form step, expanded section |
| Form state | React Hook Form | create/edit forms, filter forms |
| Server state | TanStack Query | detail views, dashboards, mutations |
| Persisted UI/workflow state | Zustand | auth session, current path, list filters, selected agency |

### Zustand rules

- Keep stores focused and small
- Persist only durable state such as auth session, intended path, selected tenant, sort/filter/page size
- Do not persist fetched datasets or large row buffers
- Read store state in services via `store.getState()` rather than hooks outside React render
- Keep actions explicit and predictable

```ts
export const useEntityTableStore = create<EntityTableState>()(
  persist(
    (set) => ({
      sortKey: 'id-desc',
      filter: null,
      pageSize: 50,
      setSort: (key) => set({ sortKey: key }),
    }),
    { name: 'entity-table-store', storage: createJSONStorage(() => localStorage) },
  ),
);
```

---

## Entities, CRUD Operations, And Feature Design

### A feature is a vertical slice

A feature like `src/features/customers` should contain everything needed for that business capability:

- module routes
- route pages: `index`, `create`, `view`, `edit`
- feature toolbar
- feature-specific hooks
- feature API endpoints
- feature store slice if needed
- types and validation already shared under app-level folders when reused broadly

The goal is that a new developer can open one feature folder and understand the list flow, view flow, edit flow, API contract, and form composition without hunting through unrelated modules.

### Entity implementation pattern

Entity-centric CRUD features are often more custom than they look. Preserve a repeatable bundle instead of reinventing it for every new record type.

Recommended reusable pieces per entity:

- entity type and list-filter type
- endpoint module with typed list/get/create/update/remove functions
- query hooks and mutation hooks
- shared form spec
- fields component
- list columns definition
- optional feature store when list state must persist

```ts
export type CustomerRecord = {
  id: number;
  firstName: string;
  lastName: string;
  email: string;
  status: 'active' | 'inactive';
  createdAt: string;
};

export type CustomerPatch = Partial<Pick<CustomerRecord, 'firstName' | 'lastName' | 'email' | 'status'>>;

export type CustomerListFilter = {
  text?: string;
  status?: 'active' | 'inactive';
};

export async function getCustomer(id: number) {
  const response = await protectedApi.get<CustomerRecord>(`/customers/${id}`);
  return response.data;
}

export async function saveCustomer(input: { id?: number; patch: CustomerPatch }) {
  if (input.id) {
    const response = await protectedApi.patch<CustomerRecord>(`/customers/${input.id}`, input.patch);
    return response.data;
  }

  const response = await protectedApi.post<CustomerRecord>('/customers', input.patch);
  return response.data;
}
```

That bundle becomes the hard-to-invent template for the next entity. Keep it obvious and consistent.

### Standard CRUD page model

For entity-driven admin features, prefer a repeatable four-page structure:

- `index.tsx` for list/table
- `create.tsx` for new entity form
- `view.tsx` for view/read-only details
- `edit.tsx` for update form

The route pages should stay thin and mostly compose:

- route guards
- form spec
- shared `RecordForm`
- navigation parameters

### Shared CRUD shell

`RecordForm` should be the reusable CRUD engine.

It should manage:

- create vs edit vs view mode
- fetch lifecycle
- patch submission lifecycle
- error and loading panels
- save/refresh/header actions
- standard layout and toolbar composition

Per-entity code should mostly provide configuration and field components, not duplicate all CRUD plumbing.

```tsx
const customerFormSpec: FormSpec<CustomerFormValues> = {
  title: 'Customer',
  initial: () => ({
    firstName: '',
    lastName: '',
    email: '',
    status: 'active',
  }),
  useFetch: useCustomer,
  useSubmit: useSaveCustomer,
  transformPatch: (patch) => trimEmptyStrings(patch),
  onSuccessRoute: '/customers/{id}',
  Fields: CustomerFields,
};
```

### Reusability mandate

Every repeatable piece of UI must become its own component instead of being reimplemented in pages.

Examples:

- `RecordFormLayout`
- `RecordFormHeaderActions`
- `RecordFormToolbar`
- `DataTable`
- `DataTableActions`
- `ActionGroup`
- `Toolbar`
- field components in `src/components/forms/`

If you see the same page section repeated twice, stop and extract it.

---

## Forms, Field Components, And CRUD Screens

### Reuse shared form infrastructure

For CRUD-heavy admin apps, use a shared form shell such as `RecordForm` plus a per-entity `FormSpec`.

The shared form shell should handle:

- create/edit/view mode detection
- fetch lifecycle
- submit lifecycle
- loading and error states
- dirty-patch submission
- header actions and toolbar

Per-entity specs should supply:

- `useFetch`
- `useSubmit`
- initial values
- title and submit label
- route-on-success
- `Fields` component
- optional patch transformation

```ts
type FormSpec<T> = {
  useFetch?: (id?: number) => any;
  useSubmit?: () => any;
  initial?: () => T;
  Fields?: React.ComponentType<FieldsProps>;
  transformPatch?: (patch: Partial<T>, mode: 'create' | 'edit' | 'view') => Partial<T>;
};
```

### Form rules

- Route pages for create/edit/view should be thin wrappers around shared form primitives
- Use React Hook Form for non-trivial forms
- Submit patch payloads from dirty fields when backend semantics support partial updates
- Keep validation consistent inside the feature; do not mix multiple validation styles casually
- Surface loading, fetch errors, and submit errors explicitly

### Shared field components are part of the architecture

The folder `src/components/forms/` should be the main toolbox for field rendering and validation behavior.

Examples:

- `TextField`
- `CheckboxField`
- `DropdownField`
- `AutocompleteField`
- `DateTimePickerField`
- `ErrorMessage`
- `LabeledText`

These components should encapsulate:

- label wiring
- accessibility attributes
- error rendering
- formatting and masking
- editable vs read-only behavior
- validation hints
- input-mode and keyboard semantics

A neutral shared text input component is a good example of a reusable input abstraction that handles:

- controlled and uncontrolled usage modes
- textarea vs text vs secure inputs
- validators and sanitizer support
- masking
- min/max length hints
- read-only display state

#### Form component sample

```tsx
type ControlledTextFieldProps<TValues extends FieldValues> = {
  control: Control<TValues>;
  name: Path<TValues>;
  label: string;
  editable?: boolean;
  placeholder?: string;
  inputType?: React.InputHTMLAttributes<HTMLInputElement>['type'];
};

export function ControlledTextField<TValues extends FieldValues>({
  control,
  name,
  label,
  editable = true,
  placeholder,
  inputType = 'text',
}: ControlledTextFieldProps<TValues>) {
  return (
    <Controller
      control={control}
      name={name}
      render={({ field, fieldState }) => (
        <FieldShell label={label} error={fieldState.error?.message}>
          {editable ? (
            <Input {...field} type={inputType} placeholder={placeholder} aria-invalid={Boolean(fieldState.error)} />
          ) : (
            <ReadOnlyValue value={field.value} emptyLabel="-" />
          )}
        </FieldShell>
      )}
    />
  );
}
```

This kind of component is worth documenting because teams otherwise reinvent label wiring, error display, and read-only behavior in every feature.

### Form communication model

- `usePatchForm()` owns dirty-field and reset behavior
- `RecordForm` owns screen-level fetch/submit operation state
- field components receive `control`, `editable`, and controlled helpers such as `setValue` when needed
- per-entity `Fields` components only compose form fields, not submission orchestration

### Strong recommendation for typing

Avoid loose `any`-style field props in shared form components where possible.

Prefer typed shared field props so feature field components know exactly what they receive. Reusable form infrastructure should reduce type boilerplate, not erase type safety.

### Neutral code samples

#### Feature module sample

```tsx
export default function CustomersModule() {
  return (
    <Routes>
      <Route index element={<CustomersListPage />} />
      <Route path="create" element={<CustomerCreatePage />} />
      <Route path=":customerId" element={<CustomerViewPage />} />
      <Route path=":customerId/edit" element={<CustomerEditPage />} />
    </Routes>
  );
}
```

#### Shared form shell sample

```tsx
type CustomerForm = {
  firstName: string;
  lastName: string;
  email: string;
};

const customerSpec: FormSpec<CustomerForm> = {
  title: 'Customer',
  initial: () => ({ firstName: '', lastName: '', email: '' }),
  useFetch: useCustomer,
  useSubmit: useSaveCustomer,
  onSuccessRoute: '/customers/{id}',
  Fields: CustomerFields,
};

function CustomerFields({ control, editable, setValue }: TypedFieldsProps<CustomerForm>) {
  return (
    <>
      <TextField control={control} name="firstName" label="First name" editable={editable} />
      <TextField control={control} name="lastName" label="Last name" editable={editable} />
      <TextField control={control} name="email" label="Email" editable={editable} inputType="email" />
    </>
  );
}
```

Read `.github/skills/react-virtualized-crud-tables.md` for the full virtual table samples, including store wiring, toolbar communication, and row-action orchestration.

---

## UI And Styling

### Use the existing design system

Default to the shared UI layer already present in the app:

- shadcn/ui and Radix primitives for foundational controls
- shared wrappers like `BaseButton`, `Toolbar`, `Panel`, `ErrorBanner`
- app theme tokens and shared stylesheets
- Lucide icons

Do not introduce a second UI library unless the project explicitly approves it.

### Styling rules

- Prefer composition of shared components over bespoke one-off markup for common patterns
- Keep classes readable and intentional
- Reuse theme tokens and layout conventions
- Respect dark mode and theme persistence
- Keep accessibility intact when wrapping Radix or shadcn primitives

### Avoid raw styling noise in page markup

Do not let route pages become walls of raw utility classes.

Preferred order:

1. Use existing shared UI components
2. Extract repeated visual patterns into dedicated components
3. Use variant helpers such as `class-variance-authority`, `clsx`, and `tailwind-merge` inside those components
4. Use CSS modules or component-scoped style helpers for complex layout/styling logic when utility classes become noisy

The goal is not zero `className` usage. The goal is:

- page markup stays readable
- styling decisions are isolated in reusable components
- visual variants are centralized instead of duplicated

For this kind of project, the best low-boilerplate approach is usually:

- shared primitives like `BaseButton`, `Panel`, `Toolbar`, `IconButton`
- variant-based components using CVA-style helpers
- app-level theme tokens in shared stylesheets

Avoid giant ad-hoc class strings repeated across CRUD pages.

---

## Async UX, Progress, And Perceived Performance

All UI operations should be async-friendly and visibly progressive. Users should never wonder whether the system is frozen.

### Required progress strategy

Use the smallest feedback that honestly matches the operation scope.

#### Local progress

Use local feedback for narrow actions:

- spinner in a button during save/delete/action execution
- inline loading state in a table row or small panel
- retry button state during a refetch

#### Section-level progress

Use section-level feedback when a card, dialog, or form section is busy:

- entity loading panel for forms
- loading state inside a modal dialog
- table fetch state or retry banner

#### Global progress

Use a blocking overlay only when the entire screen or modal is unavailable:

- full-screen load on major dashboard initialization
- modal `BlockingOverlay` during a blocking confirm action
- global obscure panel when a long-running operation must prevent conflicting interaction

### Operation-state pattern

A simple explicit state machine is better than scattered booleans.

Example:

- `idle`
- `fetch`
- `refresh`
- `submit`

This makes it obvious which UI should be disabled and which progress component should be shown.

### Long-running operations

If an operation may take noticeable time:

- disable conflicting controls
- show progress immediately
- keep the previous context visible when possible
- prefer optimistic or partial updates where safe
- report completion or failure clearly through local message, toast, or banner

Do not wait silently and then suddenly replace the UI.

### Boilerplate reduction for async work

Reduce repetitive HTTP and progress code by standardizing:

- shared axios clients and interceptors
- typed API modules per entity
- query/mutation hooks per entity
- shared error extraction helpers
- shared loading components like `BlockingOverlay` and `FormLoadingPanel`
- reusable callback contracts like `onApplyUpdatedRow()` or `onRefresh()`

---

## Theme Support

Theme support is part of architecture, not decoration.

### Theme provider ownership

The app shell should provide a single theme provider responsible for:

- persisted theme preference
- applying `light` / `dark` / `system` mode to the document root
- exposing `theme` and `setTheme()` through context

This is the correct boundary for theme concerns.

### Theme toggle behavior

Components like a theme toggle control should be pure consumers:

- read current theme from context
- trigger theme changes through the provider
- remain accessible with proper labels/title

### Theme rules

- every shared component must support theme tokens from the start
- do not hardcode colors directly in feature pages when theme tokens exist
- dark mode and light mode should both be legible and intentional
- theme persistence belongs in the provider, not scattered across random components

---

## Error Handling And Feedback

- Use shared error helpers such as `getErrorMessage()`
- Show explicit loading, empty, retry, and error states
- Normalize backend error payloads at the client/service layer
- Do not silently swallow request failures
- Keep user-facing errors readable and actionable
- Global infrastructure like dialogs, toasts, and update banners belongs in app shell wiring

---

## Testing Strategy

- Vitest for unit and component tests
- React Testing Library for user-behavior testing
- Test hooks, service functions, guards, and reusable form/table components where the logic is non-trivial
- Prefer testing behavior and observable state, not internal implementation details
- For CRUD features, cover list, create, edit, validation, empty, and error states

---

## Anti-Patterns

| Anti-pattern | Instead |
|-------------|---------|
| Raw `axios` calls in route components or pages | Call typed service functions from `services/api/` |
| One giant page owning fetch, form, mutation, and table logic | Split into route file, page component, hooks, and services |
| Using TanStack Query as an unbounded infinite-page cache for huge virtual lists | Use a bounded-memory table fetch strategy with page pruning |
| Persisting fetched rows in Zustand | Persist only filter/sort/session-like state |
| Route authorization spread through deep child components | Guard at route boundary |
| Rebuilding CRUD forms from scratch for every entity | Reuse shared `RecordForm`-style form shells and specs |
| Mixing multiple validation styles inside one feature without reason | Pick one consistent validation approach per feature |
| Introducing new UI libraries casually | Stay inside the shared design system |
| Silent error handling or generic `something went wrong` everywhere | Normalize backend errors and surface clear actions |
| Toolbar, table, and row actions directly mutating each other | Communicate through stores, state-manager contracts, and explicit callbacks |
| Keeping far-away pages from virtual tables forever | Prune pages outside the active viewport buffer |
| Blocking user actions with no visible progress | Show local, section, or global progress immediately |
| Repeating huge utility-class strings in every page | Extract reusable styled primitives and variant-based components |

---

## Checklist For Every Story

- [ ] Feature routing is added through a lazy module and thin route files
- [ ] Authorization is enforced at the route boundary where required
- [ ] API calls go through centralized clients and typed API modules
- [ ] Query usage is appropriate; large virtualized tables do not grow memory unbounded
- [ ] Toolbar, table, dialog, and row actions communicate through explicit contracts, not hidden coupling
- [ ] Zustand stores persist only durable client state
- [ ] Screen/page components stay thin and delegate logic to hooks/services
- [ ] Shared CRUD form infrastructure is reused when the feature fits the pattern
- [ ] Shared form field components are used instead of bespoke field markup where applicable
- [ ] Loading, empty, error, and retry states are present
- [ ] Long-running operations show appropriate local or global progress feedback
- [ ] Styling follows the existing design system and theme rules
- [ ] Repeated UI patterns are extracted into dedicated reusable components
- [ ] Theme support is preserved for all new shared components
- [ ] Accessibility and keyboard interaction are preserved
- [ ] Vitest/RTL coverage exists for the new behavior where practical