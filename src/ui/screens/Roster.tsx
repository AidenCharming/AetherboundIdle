import { useCallback, useMemo, useState } from 'react'
import { useGameStore } from '../../state/runtime'
import {
  arrangeRoster,
  isFiltered,
  NO_FILTER,
  selectAetherPerHour,
  selectAetherPerMinute,
  selectBenchRates,
  selectCreatureViews,
  toggleBenched,
  type RosterFilter,
  type RosterSort,
} from '../../state/selectors'
import { formatRate } from '../format'
import { RosterCard } from '../components/RosterCard'
import { PageTitle } from '../components/PageTitle'
import { RosterFilters } from '../components/RosterFilters'

interface RosterProps {
  filter: RosterFilter
  sort: RosterSort
  onFilter: (filter: RosterFilter) => void
  onSort: (sort: RosterSort) => void
}

// The Roster code is the Nexus screen in the UI. Step 1.9d merged the old Roster page and the old Nexus page into one
// page called Nexus (the designer's decision): the internal names (roster.ts, RosterCard, RosterFilters, the Roster*
// types, selectRoster*) were kept on purpose, so nothing here or in the tests was renamed. The word "Roster" must not
// appear anywhere the player can read it.

/**
 * The Nexus: every creature as a card, with the bench strip above the filters. Filter, sort and which card is open are
 * UI-local state: none of it is in the game state or the save (App owns the filter and sort so they survive a visit to
 * another screen). The list comes from `selectCreatureViews`, which keeps its identity through every tick, so this
 * screen re-renders when a creature changes (an assignment, later a hatch) and not 10 times a second.
 *
 * The bench strip is what was unique to the old Nexus page: the Aether the benched creatures gather (per minute, per
 * hour) and how many there are, straight from the sim through the bench selectors, so it cannot disagree with the top
 * bar. Clicking it shows the benched creatures (the Status filter set to Benched); each benched creature's card shows
 * what it gathers. Habitat and bench upgrades are not designed yet and are not here.
 */
export function Roster({ filter, sort, onFilter, onSort }: RosterProps) {
  const views = useGameStore(selectCreatureViews)
  // What each benched creature gathers, by id: also who is benched (a creature that works a slot is not in it).
  const rates = useGameStore(selectBenchRates)
  const perMin = useGameStore(selectAetherPerMinute)
  const perHour = useGameStore(selectAetherPerHour)
  const [openId, setOpenId] = useState<string | null>(null)

  const shown = useMemo(() => arrangeRoster(views, filter, sort), [views, filter, sort])
  const toggle = useCallback((id: string) => setOpenId((cur) => (cur === id ? null : id)), [])

  const benchedOn = filter.work === 'benched'

  return (
    <section className="page roster" aria-label="Nexus">
      <PageTitle lead="Every creature you own. The ones not working a slot rest on the bench and gather Aether, and rarer creatures gather more.">Nexus</PageTitle>

      <button type="button" className="bench-strip" aria-pressed={benchedOn} onClick={() => onFilter(toggleBenched(filter))}>
        <span className="bench-strip-head">
          <span className="bench-strip-title">Bench</span>
          <span className="small muted">{benchedOn ? 'Showing only benched creatures. Click to show everyone.' : 'Click to show only benched creatures.'}</span>
        </span>
        <span className="bench-stats">
          <span className="bench-stat">
            <span className="small muted">Aether per minute</span>
            <strong>{formatRate(perMin)}</strong>
          </span>
          <span className="bench-stat">
            <span className="small muted">Aether per hour</span>
            <strong>{formatRate(perHour)}</strong>
          </span>
          <span className="bench-stat">
            <span className="small muted">Benched</span>
            <strong>{rates.size}</strong>
          </span>
        </span>
      </button>

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
          <p>{benchedOn && rates.size === 0 ? 'Nobody is benched. Unassign a creature from a work slot (on a skill page or here) and it will gather Aether on the bench.' : 'No creatures match these filters.'}</p>
          {isFiltered(filter) && (
            <button type="button" onClick={() => onFilter(NO_FILTER)}>
              Clear filters
            </button>
          )}
        </div>
      ) : (
        <ul className="roster-grid">
          {shown.map((view) => (
            <RosterCard key={view.id} view={view} expanded={view.id === openId} onToggle={toggle} aetherPerMin={rates.get(view.id) ?? null} />
          ))}
        </ul>
      )}
    </section>
  )
}
