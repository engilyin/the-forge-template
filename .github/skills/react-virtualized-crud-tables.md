# ---
title: "React Virtualized CRUD Tables Skill"
description: "Patterns for building virtualized, bounded-memory CRUD table engines with toolbar orchestration and page caching."
tags: [skill, frontend, tables]
type: skill
---

# React Virtualized CRUD Tables Skill

Use this skill for React web features that render very large datasets through virtualized, infinitely scrolling CRUD tables. Apply it together with `.github/skills/react-web-frontend.md` when a feature needs a reusable table engine, bounded-memory paging, row actions, or rich toolbar-to-table orchestration.

---

## When To Use This Skill

Use this skill when all or most of the following are true:

- the feature can load thousands or millions of rows
- the backend exposes stateless offset or page-based list APIs
- the UI must scroll fluidly without rendering the full dataset
- filters, sort, or page size must survive route changes or refreshes
- row-level actions need precise local updates without reloading everything

Do not use this skill for tiny reference lists, simple lookup dropdowns, or ordinary paginated detail pages.

---

## Architecture Split

Large admin tables are not ordinary list components. Split responsibilities deliberately.

- feature store owns durable table state such as sort token, filter values, page size, and refresh signals
- toolbar owns user intent only: filter submit, clear, refresh, export, page-size changes
- table owns virtualization, visible-window fetching, bounded page cache, and scroll-aware pruning
- row action components own row-local actions only
- API modules own request contracts and response parsing
- feature page is the orchestration boundary that wires the state manager, toolbar, and table together

The reusable table must behave like an engine. It should not know feature-specific field names, routes, or business language.

---

## What The Table Engine Must Do

- request pages by page index and current durable state
- keep a bounded in-memory page map
- estimate totals conservatively when the backend does not provide an exact count
- fetch more pages when the visible range approaches unloaded space
- prune pages outside a configurable overscan or buffer window
- expose imperative helpers such as `refresh()`, `reset()`, `scrollToTop()`, and `updateRow()`
- preserve stable row identity so targeted row patching is possible

The page map is a working window, not a permanent cache.

---

## Layout Constraints

Virtualization works only when layout is explicit.

- the table must render inside a controlled-height scroll container
- parent pages must not introduce competing nested scroll regions accidentally
- banners, filters, and toolbars above the table must be accounted for in the height calculation
- dialogs with embedded tables need their own explicit scroll boundary

If scroll ownership is ambiguous, the virtualizer becomes unstable and user perception degrades immediately.

---

## Cache And Fetch Rules

### Prefer custom page fetching over unbounded query caches

TanStack Query is excellent for detail screens, lookups, and ordinary mutations. It is often the wrong cache model for large virtualized lists.

For large table flows:

- avoid using `useInfiniteQuery` as a hidden permanent page store
- avoid mirroring loaded rows into Zustand
- keep only nearby pages in memory
- reset page windows when sort or filter changes

### Sort and filter invalidation

When the query shape changes:

- clear cached pages
- reset the estimated total or high-water mark
- scroll back to the appropriate anchor, usually the top
- fetch a fresh first page only

Do not leave stale rows visible after a filter or sort transition.

---

## State Manager Contract

The feature page should adapt feature state into a reusable table contract.

```ts
type DataTableState = {
  sortToken: string | null;
  filter: CustomerListFilter | null;
  pageSize: number;
};

type StateManager<Row> = {
  getState: () => DataTableState;
  subscribe: (listener: () => void) => () => void;
  updateSort: (ascendingToken: string, descendingToken?: string) => void;
  fetchPage: (pageIndex: number, state: DataTableState) => Promise<PageResponse<Row>>;
};
```

Concrete feature sample:

```ts
const stateManager: StateManager<CustomerRow> = {
  getState: () => {
    const state = useCustomerTableStore.getState();
    return {
      sortToken: state.sortToken,
      filter: state.filter,
      pageSize: state.pageSize,
    };
  },
  subscribe: (listener) => useCustomerTableStore.subscribe(listener),
  updateSort: (ascendingToken, descendingToken) => {
    const store = useCustomerTableStore.getState();
    const next = store.sortToken === ascendingToken ? (descendingToken ?? null) : ascendingToken;
    store.setSortToken(next);
  },
  fetchPage: async (pageIndex, state) => {
    return listCustomersPage({
      offset: pageIndex * state.pageSize,
      limit: state.pageSize,
      sort: state.sortToken ?? undefined,
      filter: state.filter ?? undefined,
    });
  },
};
```

---

## Feature Store Sample

The store should keep durable UI intent, not loaded datasets.

```ts
type CustomerListFilter = {
  name?: string;
  tier?: 'standard' | 'premium';
  status?: 'active' | 'inactive';
};

type CustomerTableState = {
  sortToken: string | null;
  pageSize: number;
  filter: CustomerListFilter | null;
  refreshToken: number;
  setSortToken: (sortToken: string | null) => void;
  setPageSize: (pageSize: number) => void;
  setFilter: (filter: CustomerListFilter | null) => void;
  requestRefresh: () => void;
};

export const useCustomerTableStore = create<CustomerTableState>()(
  persist(
    (set) => ({
      sortToken: 'createdAt-desc',
      pageSize: 50,
      filter: null,
      refreshToken: 0,
      setSortToken: (sortToken) => set({ sortToken }),
      setPageSize: (pageSize) => set({ pageSize }),
      setFilter: (filter) => set({ filter }),
      requestRefresh: () => set((state) => ({ refreshToken: state.refreshToken + 1 })),
    }),
    { name: 'customer-table-state', storage: createJSONStorage(() => localStorage) },
  ),
);
```

---

## Toolbar-To-Table Communication

The toolbar emits intent. The feature page decides orchestration.

```tsx
function CustomerToolbar() {
  const { control, handleSubmit, reset } = useForm<CustomerListFilter>({
    defaultValues: useCustomerTableStore((state) => state.filter ?? {}),
  });
  const setFilter = useCustomerTableStore((state) => state.setFilter);
  const requestRefresh = useCustomerTableStore((state) => state.requestRefresh);

  const submit = handleSubmit((values) => {
    setFilter(normalizeCustomerFilter(values));
  });

  return (
    <Toolbar>
      <form onSubmit={submit} className="flex flex-wrap gap-3">
        <ControlledTextField control={control} name="name" label="Name" />
        <ControlledSelectField control={control} name="status" label="Status" options={statusOptions} />
        <Button type="submit">Apply</Button>
        <Button
          type="button"
          variant="secondary"
          onClick={() => {
            reset({});
            setFilter(null);
          }}
        >
          Clear
        </Button>
        <Button type="button" variant="outline" onClick={() => requestRefresh()}>
          Refresh
        </Button>
      </form>
    </Toolbar>
  );
}
```

The table subscribes to the state manager and resets its working window when those durable inputs change.

---

## Row Actions Pattern

Rows in a virtual list are ephemeral. Row action components must not assume they stay mounted.

- stop row-click propagation when the row itself is navigable
- execute the async action locally
- emit the outcome upward through a callback
- let the parent decide whether to patch the row or refresh the table

```tsx
type RowActionResult<Row> =
  | { type: 'row-updated'; row: Row }
  | { type: 'refresh-requested' };

function CustomerRowActions({
  row,
  onResult,
}: {
  row: CustomerRow;
  onResult: (result: RowActionResult<CustomerRow>) => void;
}) {
  const archiveMutation = useArchiveCustomer();

  return (
    <ActionGroup onClick={(event) => event.stopPropagation()}>
      <Button
        size="sm"
        disabled={archiveMutation.isPending}
        onClick={async () => {
          const updated = await archiveMutation.mutateAsync(row.id);
          onResult({ type: 'row-updated', row: updated });
        }}
      >
        Archive
      </Button>
    </ActionGroup>
  );
}
```

---

## Reusable Feature Page Sample

This is the orchestration layer that is hard to reinvent cleanly if the pattern is undocumented.

```tsx
export function CustomersIndexPage() {
  const navigate = useNavigate();
  const tableRef = useRef<DataTableHandle<CustomerRow>>(null);

  return (
    <PageLayout
      title="Customers"
      toolbar={<CustomerToolbar />}
      actions={<Button onClick={() => navigate('/customers/create')}>New customer</Button>}
    >
      <DataTable
        ref={tableRef}
        stateManager={stateManager}
        columns={customerColumns}
        estimateRowHeight={44}
        pageBuffer={2}
        onRowClick={(row) => navigate(`/customers/${row.id}`)}
        onRowActionResult={(result) => {
          if (result.type === 'row-updated') {
            tableRef.current?.updateRow(result.row.id, result.row);
            return;
          }
          tableRef.current?.refresh();
        }}
      />
    </PageLayout>
  );
}
```

---

## Anti-Patterns

- do not flatten all loaded pages into a permanent Zustand array
- do not store the whole dataset in TanStack Query and again in component state
- do not make toolbar components call table internals directly
- do not make row action components own refresh or invalidation policy
- do not let sort and filter logic drift differently across features
- do not couple the reusable table engine to one entity name or route scheme

---

## Checklist

- the table scroll container has an explicit and stable height
- cached pages are bounded and pruned outside the active window
- sort and filter changes clear stale rows and reset fetch state
- durable list state lives in a small focused store
- row updates use stable entity identifiers
- toolbar, page, and table communicate through explicit contracts
- row action outcomes are routed through callbacks rather than hidden side effects
- the feature page stays thin but remains the orchestration owner