import { spriteScaleFor, type CreatureView } from '../../state/selectors'
import { cssVars } from '../format'
import { spriteFor } from '../sprites'

/**
 * A creature drawn as art: its sprite when the file exists (ui/sprites.ts), else its emoji. It fills the art plate its
 * parent provides (`.art-plate` in theme.css, which is what makes a green creature readable on a green tile); it draws
 * no name, because every place that shows art has the name beside it, so the image is decorative (`alt=""`).
 *
 * The sprite is drawn at a per-form fraction of the plate (`tuning.ui.spriteFormScale`), since every sprite is cropped
 * to its own bounding box and a Form 1 would otherwise look as big as a Form 3. A shiny gets the same runtime hue turn
 * whichever of the two is drawn (`--shiny-hue`: the creature's first type's own `shinyHueDeg`, else `tuning.ui.shinyHueDeg`, see `shinyHueFor`): there is
 * no separate shiny art.
 */
export function CreatureArt({ view }: { view: CreatureView }) {
  const src = spriteFor(view.speciesId, view.form)
  const style = cssVars({
    '--sprite-scale': src ? String(spriteScaleFor(view.form)) : null,
    '--shiny-hue': view.shiny ? `${view.shinyHueDeg}deg` : null,
  })
  return src ? (
    <img className="creature-art" src={src} alt="" draggable={false} decoding="async" data-shiny={view.shiny} style={style} />
  ) : (
    <span className="creature-art creature-art-emoji" aria-hidden="true" data-shiny={view.shiny} style={style}>
      {view.emoji}
    </span>
  )
}
