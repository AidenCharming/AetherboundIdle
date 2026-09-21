import type { CSSProperties } from 'react'
import type { CreatureView } from '../../state/selectors'
import { cssVars } from '../format'

/**
 * The custom properties a creature's CSS reads (theme.css: `.rcard`, and the slot's `.creature`), all from the data: the
 * type colors for the art plate's rim (a dual-type hybrid splits it, a single type fills it) and the rarity frame tint and
 * glow. The shiny hue turn is not here: CreatureArt sets it on the art itself, wherever the art is drawn.
 * One card language for every creature.
 */
export function cardStyle(view: CreatureView): CSSProperties {
  const first = view.types[0]?.color ?? view.color
  return cssVars({
    '--type-a': first,
    '--type-b': view.types[1]?.color ?? first,
    '--rarity': view.rarity.tint,
    '--glow': String(view.rarity.glow),
  })
}
