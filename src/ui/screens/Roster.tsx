import { useCallback, useMemo, useState } from 'react'
import { useGameStore } from '../../state/runtime'
import { arrangeRoster, isFiltered, NO_FILTER, selectCreatureViews, type RosterFilter, type RosterSort } from '../../state/selectors'
import { RosterCard } from '../components/RosterCard'
import { RosterFilters } from '../components/RosterFilters'

interface RosterProps {
  filter: RosterFilter
  sort: RosterSort
  onFilter: (filter: RosterFilter) => void
  onSort: (sort: RosterSort) => void
}

/**
 * Every creature as a card. Filter, sort and which card is open are UI-local state: none of it is in the game state
 * or the save (App owns the filter and sort so they survive a visit to another screen). The list comes from
 * `selectCreatureViews`, which keeps its identity through every tick, so this screen re-renders when a creature
 * changes (an assignment, later a hatch) and not 10 times a second.
 */
export function Roster({ filter, sort, onFilter, onSort }: RosterProps) {
  const views = useGameStore(selectCreatureViews)
  const [openId, setOpenId] = useState<string | null>(null)

  const shown = useMemo(() => arrangeRoster(views, filter, sort), [views, filter, sort])
  const toggle = useCallback((id: string) => setOpenId((cur) => (cur === id ? null : id)), [])

  return (
    <section className="roster" aria-label="Roster">
      <RosterFilters filter={filter} sort={sort} onFilter={onFilter} onSort={onSort} />

      <p className="roster-count" aria-live="polite">
        <strong>
          {shown.length} of {views.length}
        </strong>{' '}
        <span className="muted">{views.length === 1 ? 'creature' : 'creatures'}</span>
      </p>

      {views.length === 0 ? (
        <p className="empty muted">You have no creatures yet.</p>
      ) : shown.length === 0 ? (
        <div className="empty">
          <p>No creatures match these filters.</p>
          {isFiltered(filter) && (
            <button type="button" onClick={() => onFilter(NO_FILTER)}>
              Clear filters
            </button>
          )}
        </div>
      ) : (
        <ul className="roster-grid">
          {shown.map((view) => (
            <RosterCard key={view.id} view={view} expanded={view.id === openId} onToggle={toggle} />
          ))}
        </ul>
      )}
    </section>
  )
}
