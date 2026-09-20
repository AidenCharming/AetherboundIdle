import { useState, type ReactNode } from 'react'
import {
  DEFAULT_SORT,
  defaultDirection,
  formNumbers,
  isFiltered,
  NO_FILTER,
  rarityOptions,
  skillOptions,
  SORT_KEYS,
  typeOptions,
  type RosterFilter,
  type RosterSort,
  type SortKey,
} from '../../state/selectors'

const SORT_LABELS: Record<SortKey, string> = { rarity: 'Rarity', level: 'Level', name: 'Name', type: 'Type', form: 'Form' }

/** How many of the filter's fields are set: shown on the summary so a closed panel still says something is on. */
const activeCount = (f: RosterFilter): number => Object.values(f).filter((v) => v !== null).length

const num = (value: string): number | null => (value === '' ? null : Number(value))

function Select({ label, value, onChange, children }: { label: string; value: string; onChange: (value: string) => void; children: ReactNode }) {
  return (
    <label className="field">
      <span className="small muted">{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)}>
        {children}
      </select>
    </label>
  )
}

/**
 * The roster's filter and sort controls. They only edit the two values the screen owns (UI-local state, not the game);
 * the filtering itself is the pure code in state/roster.ts.
 */
export function RosterFilters({
  filter,
  sort,
  onFilter,
  onSort,
}: {
  filter: RosterFilter
  sort: RosterSort
  onFilter: (filter: RosterFilter) => void
  onSort: (sort: RosterSort) => void
}) {
  // Open on a wide screen, where there is room; folded on a phone, where the roster should come first.
  const [open, setOpen] = useState(() => globalThis.matchMedia?.('(min-width: 768px)').matches ?? false)
  const set = (patch: Partial<RosterFilter>): void => onFilter({ ...filter, ...patch })
  const active = activeCount(filter)

  return (
    <details className="filters" open={open} onToggle={(e) => setOpen(e.currentTarget.open)}>
      <summary>
        Filter &amp; sort
        <span className="muted small">
          {' '}
          · {active === 0 ? 'no filters' : `${active} filter${active === 1 ? '' : 's'} on`}
        </span>
      </summary>

      <div className="filters-grid">
        <Select label="Type" value={filter.type ?? ''} onChange={(v) => set({ type: v === '' ? null : v })}>
          <option value="">All types</option>
          {typeOptions.map((t) => (
            <option key={t.id} value={t.id}>
              {t.name}
            </option>
          ))}
        </Select>

        <Select label="Rarity" value={filter.rarity === null ? '' : String(filter.rarity)} onChange={(v) => set({ rarity: num(v) })}>
          <option value="">All rarities</option>
          {rarityOptions.map((r) => (
            <option key={r.tier} value={r.tier}>
              {r.name}
            </option>
          ))}
        </Select>

        <Select label="Form" value={filter.form === null ? '' : String(filter.form)} onChange={(v) => set({ form: num(v) })}>
          <option value="">All forms</option>
          {formNumbers.map((f) => (
            <option key={f} value={f}>
              Form {f}
            </option>
          ))}
        </Select>

        <Select label="Shiny" value={filter.shiny === null ? '' : filter.shiny ? 'shiny' : 'normal'} onChange={(v) => set({ shiny: v === '' ? null : v === 'shiny' })}>
          <option value="">Any</option>
          <option value="shiny">Shiny only</option>
          <option value="normal">Not shiny</option>
        </Select>

        <Select label="Status" value={filter.work ?? ''} onChange={(v) => set({ work: v === '' ? null : (v as RosterFilter['work']) })}>
          <option value="">Any</option>
          <option value="working">Working</option>
          <option value="benched">Benched</option>
        </Select>

        <Select label="Can work" value={filter.canWork ?? ''} onChange={(v) => set({ canWork: v === '' ? null : v })}>
          <option value="">Any skill</option>
          {skillOptions.map((s) => (
            <option key={s.id} value={s.id}>
              {s.name}
            </option>
          ))}
        </Select>

        <Select label="Sort by" value={sort.key} onChange={(v) => onSort({ key: v as SortKey, dir: defaultDirection(v as SortKey) })}>
          {SORT_KEYS.map((k) => (
            <option key={k} value={k}>
              {SORT_LABELS[k]}
            </option>
          ))}
        </Select>

        <div className="field">
          <span className="small muted">Order</span>
          <button type="button" onClick={() => onSort({ ...sort, dir: sort.dir === 'asc' ? 'desc' : 'asc' })} aria-label={`Order: ${sort.dir === 'asc' ? 'ascending' : 'descending'}. Tap to reverse.`}>
            {sort.dir === 'asc' ? '↑ Ascending' : '↓ Descending'}
          </button>
        </div>
      </div>

      <div className="filters-actions">
        <button type="button" disabled={!isFiltered(filter)} onClick={() => onFilter(NO_FILTER)}>
          Clear filters
        </button>
        <button type="button" disabled={sort.key === DEFAULT_SORT.key && sort.dir === DEFAULT_SORT.dir} onClick={() => onSort(DEFAULT_SORT)}>
          Reset sort
        </button>
      </div>
    </details>
  )
}
