import { useGameStore } from '../../state/runtime'
import { selectAetherPerHour, selectAetherPerMinute, selectBenchEntries } from '../../state/selectors'
import { formatRate } from '../format'
import { NexusCard } from '../components/NexusCard'
import { PageTitle } from '../components/PageTitle'

/**
 * The bench (plan.md 7, design.md section 11): every creature that is not working a slot, with the Aether each one
 * emits and the totals. Every number comes from the sim through a selector (`selectBenchEntries`,
 * `selectAetherPerMinute`), so this screen and the top bar cannot disagree with what actually accrues. Placeholder
 * styling; habitat and capacity are not designed yet and are not here.
 */
export function Nexus() {
  const entries = useGameStore(selectBenchEntries)
  const perMin = useGameStore(selectAetherPerMinute)
  const perHour = useGameStore(selectAetherPerHour)

  return (
    <section className="page nexus" aria-label="Nexus">
      <PageTitle lead="Creatures that are not working a slot rest here, and each one gathers Aether. Rarer creatures gather more.">Nexus</PageTitle>
      <div className="panel">
        <dl className="nexus-totals">
          <div>
            <dt>Per minute</dt>
            <dd>{formatRate(perMin)}</dd>
          </div>
          <div>
            <dt>Per hour</dt>
            <dd>{formatRate(perHour)}</dd>
          </div>
          <div>
            <dt>Benched</dt>
            <dd>{entries.length}</dd>
          </div>
        </dl>
      </div>

      {entries.length === 0 ? (
        <p className="empty muted">Nobody is benched. Unassign a creature from a work slot (on Skills or Roster) and it will gather Aether here.</p>
      ) : (
        <ul className="roster-grid">
          {entries.map((entry) => (
            <NexusCard key={entry.view.id} entry={entry} />
          ))}
        </ul>
      )}
    </section>
  )
}
