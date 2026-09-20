import { memo } from 'react'
import type { BenchEntry } from '../../state/selectors'
import { formatRate } from '../format'
import { cardStyle } from './cardStyle'

/**
 * A benched creature in the Nexus: the roster's card language (type-colored art, rarity frame and glow, shiny hue), with
 * what it emits instead of the working badge. Read-only. `memo` plus an identity-stable entry (selectors.ts) means it
 * re-renders only when its own creature changes, not on the tick.
 */
export const NexusCard = memo(function NexusCard({ entry }: { entry: BenchEntry }) {
  const { view, perMin } = entry
  return (
    <li className="rcard" data-shiny={view.shiny} data-rarity={view.rarity.id} style={cardStyle(view)}>
      <div className="rcard-static">
        <span className="rcard-art" aria-hidden="true">
          <span className="rcard-emoji">{view.emoji}</span>
        </span>
        <span className="rcard-body">
          <span className="rcard-name">
            {view.name}
            {view.shiny && <span className="shiny-tag"> ✨ Shiny</span>}
          </span>
          <span className="small muted">
            Lv {view.level} · Form {view.form}
          </span>
          <span className="rcard-rarity small">{view.rarity.name}</span>
          <span className="nexus-rate">
            <strong>{formatRate(perMin)}</strong> Aether/min
          </span>
        </span>
      </div>
    </li>
  )
})
