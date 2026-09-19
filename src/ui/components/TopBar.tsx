import { useGameStore } from '../../state/runtime'
import { resourceInfo, selectAetherDisplay, selectGold, selectHeldResourceIds, selectResourceQty } from '../../state/selectors'
import { cssVars, formatCount } from '../format'

function ResourceChip({ resourceId }: { resourceId: string }) {
  const qty = useGameStore((s) => selectResourceQty(s, resourceId))
  const info = resourceInfo(resourceId)
  return (
    <li className="resource">
      <span className="dot" style={cssVars({ '--dot': info.color })} aria-hidden="true" />
      <span>{info.name}</span>
      <strong>{formatCount(qty)}</strong>
    </li>
  )
}

export function TopBar() {
  const gold = useGameStore(selectGold)
  const aether = useGameStore(selectAetherDisplay) // whole Aether for display; the stored value keeps its fraction
  const held = useGameStore(selectHeldResourceIds)
  return (
    <header className="topbar">
      <div className="topbar-row">
        <h1>Aetherbound Idle</h1>
        <dl className="currencies" style={{ margin: 0 }}>
          <div>
            <dt>Gold</dt>
            <dd>{formatCount(gold)}</dd>
          </div>
          <div>
            <dt>Aether</dt>
            <dd>{formatCount(aether)}</dd>
          </div>
        </dl>
      </div>
      {held.length === 0 ? (
        <p className="muted small">No resources yet.</p>
      ) : (
        <ul className="resources" aria-label="Resources held">
          {held.map((id) => (
            <ResourceChip key={id} resourceId={id} />
          ))}
        </ul>
      )}
    </header>
  )
}
