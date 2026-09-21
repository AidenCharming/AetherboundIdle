import type { CSSProperties } from 'react'
import { shinyHueDeg, type CreatureView } from '../../state/selectors'
import { cssVars } from '../format'

/**
 * The custom properties a creature card's CSS reads (theme.css, `.rcard`), all from the data: the type colors for the art
 * panel (a dual-type hybrid splits it, a single type fills it), the rarity frame tint and glow, and the shiny hue turn.
 * One card language for every creature (the Nexus page is the only screen that lists them, so far).
 */
export function cardStyle(view: CreatureView): CSSProperties {
  const first = view.types[0]?.color ?? view.color
  return cssVars({
    '--type-a': first,
    '--type-b': view.types[1]?.color ?? first,
    '--rarity': view.rarity.tint,
    '--glow': String(view.rarity.glow),
    '--shiny-hue': view.shiny ? `${shinyHueDeg}deg` : null,
  })
}
