---
name: "React Virtualized CRUD Tables"
description: "Patterns for building large virtualized CRUD tables in React using Virtual Infinite Scroll."
user-invocable: false
---

# React Virtualized CRUD Tables — Virtual Infinite Scroll

**This is the canonical pattern for ALL data list screens in projects.**

Every list of records — jobs, agencies, staff, guardians, partners — MUST use the Virtual Infinite Scroll (VIS) `DataTable` pattern documented here. Do NOT use paginated tables (Previous/Next buttons, page number controls). The list looks seamless to the user: records load automatically as they scroll, with no visible page boundary.

The reference implementation lives in `solutions/acme-frontend/src/components/parts/DataTable.tsx`. Copy it to any new project's `src/components/parts/DataTable.tsx` and keep it identical unless you have a specific approved reason to diverge.

---

## The Golden Rule

> **Every list screen = `DataTable` + `StateManager` + feature Zustand store + `useInfinite` hook**

There is no exception for "small lists" or "simple cases". If you are showing more than 20 records, use this pattern.

---

## When To Use This Skill

Use for every entity list in an admin or staff portal:

- jobs, agencies, staff, guardians, partners, incidents
- any backend list API with offset/limit (first/max) paging
- any list that needs sort, filter, or refresh

Do not use for inline dropdown lookups, reference select lists, or non-scrollable chips.

---

## Architecture Split

Five responsibilities, five files:

| Responsibility | File |
|---|---|
| Durable table state (sort, filter, page size) | `src/store/use<Entity>Store.ts` |
| Page fetcher (bridges store to API) | `src/hooks/<entity>/useInfinite.ts` |
| HTTP request | `src/services/api/<entity>.ts` |
| Feature toolbar (filter form) | `src/features/<entity>/<Entity>Toolbar.tsx` |
| Feature list page (orchestrates all) | `src/features/<entity>/pages/index.tsx` |
| Shared table engine | `src/components/parts/DataTable.tsx` (do not modify per feature) |
| Shared row actions container | `src/components/parts/DataTableActions.tsx` |

The `DataTable` component knows nothing about jobs, agencies, or any entity. It receives a `StateManager` contract and column definitions.

---

## `DataTable` Component API

Location: `src/components/parts/DataTable.tsx`

### Types

```ts
// Column definition — one per visible column
type Column<T> = {
  key: string;             // property name (used as fallback renderer)
  label: string;           // header text
  sortable?: boolean;      // shows sort chevrons when true
  sortKeys?: [string, string]; // [ascToken, descToken] sent to backend via sortToken
  render?: (row: T) => React.ReactNode; // custom cell renderer
  width?: string;          // fixed flex-basis e.g. '120px'
  minWidth?: string;       // min-width for responsive layouts
};

// What the DataTable calls back to fetch each page
export type FetchResult<T> = { items: Array<T>; total?: number };

// Contract the feature page provides to the DataTable
export type StateManager<T> = {
  getState: () => DataTableState;
  subscribe?: (cb: () => void) => () => void; // triggers reset on change
  updateSort?: (keyA: string, keyB?: string) => void;
  fetchPage: (pageIndex: number, state: DataTableState) => Promise<FetchResult<T>>;
  getPageSize?: () => number;
};

export type DataTableState = {
  sortToken?: string | null;
  filter?: string | null;
  pageSize: number;
  [key: string]: unknown; // extra filter fields passed through
};

// Imperative handle (via ref)
export type DataTableHandle = {
  refresh: () => void;    // reset + re-fetch from page 0
  reset: () => void;      // clear cache, scroll to top
  updateRow: (id: string | number, updater: ((row: any) => any) | any) => void;
};
```

### Props

```ts
type Props<T> = {
  stateManager: StateManager<T>;
  columns: Array<Column<T>>;
  onRowClick?: (row: T) => void;  // makes rows clickable
  loading?: boolean;              // external loading flag (shows spinner over table)
  noRecordsText?: string;         // empty state message
  rowHeight?: number;             // default 52px
  height?: string | number;       // default 'calc(100vh - 280px)'
  pageBuffer?: number;            // pages to prefetch beyond viewport, default 4
};
```

### Behaviour

- Fetches page 0 on mount
- As the user scrolls, `@tanstack/react-virtual` reports which rows are visible
- `DataTable` maps visible row indices to page indices and fetches missing pages
- Pages outside `pageBuffer` on either side of the viewport are **pruned from memory** after 500ms — bounded memory, not unbounded accumulation
- When the store emits a change via `stateManager.subscribe()`, the table calls `reset()` internally — clears all pages, scrolls to top, fetches page 0 again
- A short page (length < pageSize) signals the definitive end of data
- Shows "Loading…" skeleton rows for unloaded positions; "All records loaded" footer when end reached

---

## `DataTableActions` Component

Location: `src/components/parts/DataTableActions.tsx`

A thin wrapper that renders action buttons inside a row's actions column.

```tsx
type Props<T> = {
  row?: T;
  actions?: (row: T) => ReactNode;
};

// Usage inside a column render:
{
  key: 'actions',
  label: '',
  render: (r: JobRecord) => (
    <DataTableActions
      row={r}
      actions={(row) => (
        <div className="flex items-center gap-2">
          <BaseButton size="sm" onClick={(e) => { e.stopPropagation(); handleEdit(row) }}>Edit</BaseButton>
        </div>
      )}
    />
  ),
  width: '120px',
  minWidth: '100px',
}
```

Always call `e.stopPropagation()` inside row-action click handlers when the row itself is navigable via `onRowClick`.

---

## Feature Store Pattern

The store holds durable UI intent only. It never holds fetched rows.

```ts
// src/store/useJobsStore.ts
import { create } from 'zustand'
import { persist, createJSONStorage } from 'zustand/middleware'

type JobsState = {
  sortKey: string | null
  statusFilter: string | null
  pageSize: number
  setSort: (key: string | null) => void
  setStatusFilter: (status: string | null) => void
  setPageSize: (n: number) => void
  reset: () => void
}

export const useJobsStore = create<JobsState>()(
  persist(
    (set) => ({
      sortKey: 'id-desc',
      statusFilter: null,
      pageSize: 50,
      setSort: (key) => set({ sortKey: key }),
      setStatusFilter: (status) => set({ statusFilter: status }),
      setPageSize: (n) => set({ pageSize: n }),
      reset: () => set({ sortKey: 'id-desc', statusFilter: null, pageSize: 50 }),
    }),
    { name: 'jobs-store', storage: createJSONStorage(() => localStorage) }
  )
)

export default useJobsStore
```

**Rules:**
- Store name is kebab-case entity name + `-store`
- Default sort should match backend default (usually `id-desc`)
- `reset()` restores defaults — called from toolbar "Clear" button
- Never store fetched arrays here

---

## `useInfinite` Hook Pattern

The hook is a thin page-fetcher adapter between the store and the API service. It converts the `DataTable`'s `(pageIndex, pageSize, sortKey, filters)` call into the specific API call shape.

```ts
// src/hooks/jobs/useInfinite.ts
import { list as listJobs } from '@/services/api/jobs'
import type { ShortJobInfo } from '@/types/jobs'

type FetchResult = { items: Array<ShortJobInfo> }

export function useJobsInfinite() {
  const fetchPage = async (
    pageIndex: number,
    pageSize: number,
    sortKey?: string,
    filters?: { status?: string }
  ): Promise<FetchResult> => {
    const offset = pageIndex * pageSize
    const res = await listJobs({
      first: offset,
      max: pageSize,
      sort: sortKey,
      status: filters?.status,
    })
    const items = Array.isArray(res) ? res : (res?.items ?? [])
    return { items }
  }

  return { fetchPage }
}

export default useJobsInfinite
```

---

## Feature List Page (Orchestration)

The list page wires the store, the hook, and the `DataTable` together via `stateManager`. The `stateManager` object is a `useMemo` so it stays stable across renders.

```tsx
// src/features/jobs/pages/index.tsx
import { useMemo, useRef } from 'react'
import type { DataTableHandle } from '@/components/parts/DataTable'
import type { ShortJobInfo } from '@/types/jobs'
import useJobsInfinite from '@/hooks/jobs/useInfinite'
import useJobsStore from '@/store/useJobsStore'
import { goTo } from '@/lib/navigation'
import DataTable from '@/components/parts/DataTable'
import DataTableActions from '@/components/parts/DataTableActions'
import Toolbar from '@/components/parts/Toolbar'
import BaseButton from '@/components/ui/BaseButton'
import StatusBadge from '@/components/entities/jobs/StatusBadge'
import JobsToolbar from '@/features/jobs/JobsToolbar'

export default function JobsIndex() {
  const { fetchPage } = useJobsInfinite()
  const tableRef = useRef<DataTableHandle | null>(null)
  const statusFilter = useJobsStore((s) => s.statusFilter)

  const stateManager = useMemo(() => ({
    updateSort: (keyA: string, keyB?: string) => {
      const store = useJobsStore.getState()
      const current = store.sortKey ?? undefined
      if (current === keyA) {
        store.setSort(keyB ?? null)
      } else if (current === keyB) {
        store.setSort(keyA)
      } else {
        store.setSort(keyA)
      }
    },

    getState: () => {
      const s = useJobsStore.getState()
      return {
        sortToken: s.sortKey,
        statusFilter: s.statusFilter,
        pageSize: s.pageSize,
      }
    },

    subscribe: (cb: () => void) => useJobsStore.subscribe(cb),

    getPageSize: () => useJobsStore.getState().pageSize || 50,

    fetchPage: async (pageIndex: number, state: Record<string, unknown>) => {
      const pageSize = (state.pageSize as number) || 50
      const sortToken = state.sortToken as string | undefined
      const status = state.statusFilter as string | undefined
      const res = await fetchPage(pageIndex, pageSize, sortToken, { status })
      return { items: res.items }
    },
  }), [fetchPage])

  const handleView = (r: ShortJobInfo) => goTo('/staff/jobs/$jobId', { jobId: String(r.jobId) })
  const handleEdit = (r: ShortJobInfo) => goTo('/staff/jobs/$jobId/edit', { jobId: String(r.jobId) })

  return (
    <div className="p-6 bg-slate-50 dark:bg-slate-900 min-h-screen">
      <Toolbar
        title="Jobs"
        subtitle="Manage security jobs and shift assignments."
      />

      <div className="bg-white dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700 shadow-sm">
        <JobsToolbar
          statusFilter={statusFilter}
          onSubmit={(vals) => {
            const store = useJobsStore.getState()
            store.setStatusFilter(vals.status || null)
          }}
          onClear={() => useJobsStore.getState().reset()}
          onRefresh={() => tableRef.current?.refresh()}
        />
        <div className="h-1 bg-orange" />
        <DataTable
          ref={tableRef}
          stateManager={stateManager}
          noRecordsText="No jobs found"
          columns={[
            { key: 'jobId', label: 'ID', sortable: true, sortKeys: ['id-asc', 'id-desc'], width: '72px', minWidth: '56px' },
            { key: 'name', label: 'Job Name', sortable: true, sortKeys: ['name-asc', 'name-desc'], minWidth: '200px' },
            { key: 'status', label: 'Status', render: (r: ShortJobInfo) => <StatusBadge status={r.status} />, width: '140px' },
            { key: 'agencyName', label: 'Agency', render: (r: ShortJobInfo) => r.agencyName ?? '—', minWidth: '160px' },
            { key: 'guardianName', label: 'Guardian', render: (r: ShortJobInfo) => r.guardianName ?? '—', minWidth: '160px' },
            { key: 'whenDate', label: 'Scheduled', render: (r: ShortJobInfo) => r.whenDate ? new Date(r.whenDate).toLocaleDateString() : '—', width: '130px' },
            { key: 'actions', label: '', render: (r: ShortJobInfo) => (
              <DataTableActions
                row={r}
                actions={(row: ShortJobInfo) => (
                  <div className="flex items-center gap-2">
                    <BaseButton size="sm" onClick={(e: React.MouseEvent) => { e.stopPropagation(); handleEdit(row) }}>Edit</BaseButton>
                  </div>
                )}
              />
            ), width: '100px', minWidth: '80px' },
          ]}
          onRowClick={handleView}
        />
      </div>
    </div>
  )
}
```

---

## Feature Toolbar Pattern

The toolbar owns filter form state only. It emits values upward via callbacks and calls `onClear` / `onRefresh`.

```tsx
// src/features/jobs/JobsToolbar.tsx
import { useForm } from 'react-hook-form'
import { RefreshCw, X } from 'lucide-react'
import { JOB_STATUS_OPTIONS } from '@/types/jobs'

type FormValues = { status: string }

type Props = {
  statusFilter?: string | null
  onSubmit?: (v: FormValues) => void
  onClear?: () => void
  onRefresh?: () => void
}

export default function JobsToolbar({ statusFilter, onSubmit, onClear, onRefresh }: Props) {
  const { register, handleSubmit, reset } = useForm<FormValues>({
    defaultValues: { status: statusFilter ?? '' },
  })

  const handleClear = () => {
    reset({ status: '' })
    onClear?.()
  }

  return (
    <form onSubmit={handleSubmit((v) => onSubmit?.(v))} className="bg-white dark:bg-slate-800 p-4">
      <div className="flex flex-col lg:flex-row lg:items-end gap-3">
        <div className="flex flex-col gap-1">
          <label className="text-xs text-slate-500 dark:text-slate-400">Status</label>
          <select {...register('status')} className="h-10 px-3 text-sm rounded-lg border border-slate-200 dark:border-slate-600 bg-slate-50 dark:bg-slate-700 focus:ring-2 focus:ring-orange/20 focus:border-orange focus:outline-none">
            {JOB_STATUS_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
        <div className="flex items-center gap-2">
          <button type="submit" className="h-10 px-4 text-sm font-medium text-white bg-orange hover:bg-orange-dark rounded-lg transition-colors">Apply</button>
          <button type="button" onClick={handleClear} className="h-10 px-3 text-sm font-medium text-slate-500 hover:text-slate-700 hover:bg-slate-100 rounded-lg transition-colors flex items-center gap-1">
            <X size={14} /> Clear
          </button>
          {onRefresh && (
            <button type="button" onClick={onRefresh} className="h-10 w-10 flex items-center justify-center text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors" title="Refresh">
              <RefreshCw size={18} />
            </button>
          )}
        </div>
      </div>
    </form>
  )
}
```

---

## Entity Component Pattern

Status badges, avatar chips, and other entity-specific display primitives belong in `src/components/entities/<entity>/`. They are NOT feature-specific — they can be used in list columns, detail views, and forms.

```tsx
// src/components/entities/jobs/StatusBadge.tsx
import { cn } from '@/lib/utils'
import type { JobStatus } from '@/types/jobs'

const STATUS_COLOURS: Record<string, string> = {
  New: 'bg-gray-100 text-gray-700',
  WrongAgency: 'bg-yellow-100 text-yellow-800',
  Unfilled: 'bg-blue-100 text-blue-700',
  Active: 'bg-green-100 text-green-700',
  Completed: 'bg-emerald-100 text-emerald-700',
  Cancelled: 'bg-red-100 text-red-700',
}

export default function StatusBadge({ status }: { status: JobStatus }) {
  return (
    <span className={cn('inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', STATUS_COLOURS[status] ?? 'bg-gray-100 text-gray-700')}>
      {status}
    </span>
  )
}
```

---

## Layout Constraints

Virtualization requires explicit heights.

- the table's scroll container defaults to `calc(100vh - 280px)` — adjust via the `height` prop when toolbars or banners change the available space
- never place the `DataTable` inside a CSS `overflow: hidden` ancestor that is shorter than one viewport row
- do not nest two scroll containers (DataTable inside a scrollable modal without an explicit `height` override will break)

---

## Cache And Fetch Rules

- do NOT use `useInfiniteQuery` for VIS lists — the DataTable page cache is its own bounded store
- do NOT mirror fetched rows into Zustand
- sort or filter change → `subscribe()` fires → DataTable calls `reset()` internally → pages cleared → page 0 fetched
- short page (len < pageSize) → DataTable records definitive end and stops requesting further pages

---

## Row Update vs Refresh

After a mutation (edit, status change):

- If the mutation returns the updated row: call `tableRef.current?.updateRow(row.id, updatedRow)` — patches the row in-place without a full re-fetch
- If the mutation does not return the updated row, or if the change affects sort order: call `tableRef.current?.refresh()` — full reset and re-fetch from page 0

---

## Anti-Patterns

❌ Using `useState` + `useEffect` to load a list with Previous/Next buttons  
❌ Calling `useQuery` with the full list as a single cache key  
❌ Storing fetched rows in Zustand  
❌ Passing sort/filter state as React component props through multiple layers  
❌ Placing `DataTable` inside an `overflow-auto` parent without an explicit height override  
❌ Importing `@tanstack/react-table` for list screens — use `DataTable` from `components/parts/`  

---

## Checklist

Before submitting a list screen:

- [ ] `DataTable` from `src/components/parts/DataTable.tsx` is used (not a plain HTML table or TanStack Table direct usage)
- [ ] `stateManager` is built with `useMemo` in the feature page
- [ ] Feature Zustand store holds sort/filter/pageSize — never holds rows
- [ ] `useInfinite` hook adapts store state to API call shape
- [ ] Toolbar emits intent only via callbacks — does not call table internals directly
- [ ] Sort toggle uses `updateSort(ascToken, descToken)` on the state manager
- [ ] Row action buttons call `e.stopPropagation()` when row has `onRowClick`
- [ ] Post-mutation: `updateRow()` for in-place patch, `refresh()` for full reload
- [ ] `DataTable` scroll container height is explicit — either default or `height` prop override
- [ ] No paginated controls (Previous/Next/page numbers) anywhere on the screen