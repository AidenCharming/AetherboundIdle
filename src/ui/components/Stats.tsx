import { useGameStore } from '../../state/runtime'
import { resourceInfo, selectAetherDisplay, selectAetherPerMinute, selectGold, selectHeldResourceIds, selectResourceQty } from '../../state/selectors'
import { formatCount, formatRate } from '../format'
import { ResourceIcon } from './ResourceIcon'

function ResourceChip({ resourceId }: { resourceId: string }) {
  const qty = useGameStore((s) => selectResourceQty(s, resourceId))
  const info = resourceInfo(resourceId)
  return (
    <li className="chip">
      <ResourceIcon info={info} />
      <span>{info.name}</span>
      <strong>{formatCount(qty)}</strong>
    </li>
  )
}

/** Gold, Aether with its per-minute rate, and a chip per resource held. Each part selects its own number. */
export function Stats() {
  const gold = useGameStore(selectGold)
  const aether = useGameStore(selectAetherDisplay) // whole Aether for display; the stored value keeps its fraction
  const perMin = useGameStore(selectAetherPerMinute) // the sim's own bench emission; 0 when nobody is benched, and always shown
  const held = useGameStore(selectHeldResourceIds)
  return (
    <div className="stats">
      <dl className="currencies">
        <div className="chip chip-gold">
          <dt>
            <span aria-hidden="true">🪙</span> Gold
          </dt>
          <dd>{formatCount(gold)}</dd>
        </div>
        <div className="chip chip-gold">
          <dt>
            <span aria-hidden="true">✨</span> Aether
          </dt>
          <dd>{formatCount(aether)}</dd>
          <dd className="rate" aria-label={`${formatRate(perMin)} Aether per minute`}>
            {formatRate(perMin)}/min
          </dd>
        </div>
      </dl>
      {held.length === 0 ? (
        <p className="muted small">No resources yet.</p>
      ) : (
        <ul className="resources" aria-label="Resources held">
          {held.map((id) => (
            <ResourceChip key={id} resourceId={id} />
          ))}
        </ul>
      )}
    </div>
  )
}
