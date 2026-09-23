import { readdirSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createElement } from 'react'
import { renderToStaticMarkup } from 'react-dom/server'
import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { CreatureArt } from '../src/ui/components/CreatureArt'
import { spriteFor } from '../src/ui/sprites'
import * as sel from '../src/state/selectors'
import { createGameStore, type GameStore } from '../src/state/store'
import { loadGame } from '../src/state/persistence'
import type { GameState } from '../src/types/state'
import { addCreature, MemoryStorage, newGame, NOW } from './helpers'

// Sprites are found by file name (src/ui/sprites.ts), so the name IS the data. A typo would not fail anything at run time:
// the creature would just show its emoji for ever. These tests are what makes a wrong name fail the build instead.

const dir = join(fileURLToPath(new URL('..', import.meta.url)), 'src', 'ui', 'assets', 'creatures')
const files = readdirSync(dir).filter((f) => f !== '.gitkeep')

/** `sproutlet-f2.png` -> { id: 'sproutlet', form: 2 }, or null when the name is not exactly `<id>-f<1 to 3>.png`. */
const parseName = (file: string): { id: string; form: number } | null => {
  const m = /^([a-z0-9]+(?:-[a-z0-9]+)*)-f([1-3])\.png$/.exec(file)
  return m ? { id: m[1]!, form: Number(m[2]) } : null
}

/** The real sprites shipped so far: Sproutlet and Emberfang (step 1.9e), Brambletrundle and Riftsneak (1.9f). More arrive by dropping files in the folder; these must not go missing. */
const SHIPPED = ['sproutlet', 'emberfang', 'brambletrundle', 'riftsneak'].flatMap((id) => [1, 2, 3].map((form) => ({ id, form })))

describe('sprite files', () => {
  it('finds the folder and the twelve shipped sprites', () => {
    expect(files.length).toBeGreaterThanOrEqual(SHIPPED.length)
    for (const { id, form } of SHIPPED) expect(files, `${id}-f${form}.png`).toContain(`${id}-f${form}.png`)
  })

  it('every file is named <known species or hybrid id>-f<1 to 3>.png, so a typo fails here and not silently at run time', () => {
    for (const file of files) {
      const parsed = parseName(file)
      expect(parsed, `${file} is not named <id>-f<1 to 3>.png (lower case, .png)`).not.toBeNull()
      expect(content.creatureById.has(parsed!.id), `${file}: "${parsed!.id}" is not a species or hybrid id in src/data`).toBe(true)
    }
  })

  it('no two files are the same sprite', () => {
    const names = files.map((f) => f.toLowerCase())
    expect(new Set(names).size).toBe(names.length)
  })

  it('the name check itself is strict: it rejects the typos it exists to catch', () => {
    for (const ok of ['sproutlet-f1.png', 'emberfang-f3.png', 'ashwood-f2.png']) expect(parseName(ok), ok).not.toBeNull()
    for (const bad of ['sproutlet-f4.png', 'sproutlet-f0.png', 'sproutlet-f01.png', 'sproutlet-1.png', 'sproutlet_f1.png', 'sproutlet-f1.PNG', 'Sproutlet-f1.png', 'sproutlet-f1.png.png', 'sproutlet-f1.jpg', 'sproutlet.png', '-f1.png', 'sproutlet--f1.png']) {
      expect(parseName(bad), bad).toBeNull()
    }
    // and the id check catches a misspelt species, which the pattern alone cannot
    expect(content.creatureById.has('sproutlt')).toBe(false)
    expect(content.creatureById.has('sproutlet')).toBe(true)
  })
})

describe('spriteFor', () => {
  it('returns a URL for each of the twelve shipped sprites', () => {
    for (const { id, form } of SHIPPED) {
      const url = spriteFor(id, form)
      expect(url, `${id} form ${form}`).toEqual(expect.any(String))
      expect(url!.length).toBeGreaterThan(0)
      expect(url, 'the URL is the sprite\'s own file').toContain(`${id}-f${form}`)
    }
  })

  it('finds every file in the folder (the glob misses nothing) and gives each its own URL', () => {
    const urls = files.map((f) => spriteFor(parseName(f)!.id, parseName(f)!.form))
    for (const [i, url] of urls.entries()) expect(url, files[i]).not.toBeNull()
    expect(new Set(urls).size).toBe(files.length)
  })

  it('returns null for anything without a sprite: no file yet, an unknown id, or a form out of range', () => {
    expect(spriteFor('brambletide', 1)).toBeNull()
    expect(spriteFor('ashwood', 2)).toBeNull()
    expect(spriteFor('no-such-creature', 1)).toBeNull()
    expect(spriteFor('', 1)).toBeNull()
    for (const form of [0, 4, -1, 1.5, NaN]) expect(spriteFor('sproutlet', form), `form ${form}`).toBeNull()
    // exact match only: not a prefix, not a different case
    expect(spriteFor('sprout', 1)).toBeNull()
    expect(spriteFor('Sproutlet', 1)).toBeNull()
    expect(spriteFor('sproutlet-f1', 1)).toBeNull()
  })

  it('every species and hybrid without a file is null, so the emoji is the fallback for all the rest', () => {
    let without = 0
    for (const def of content.creatureById.values()) {
      for (const form of [1, 2, 3]) {
        if (files.includes(`${def.id}-f${form}.png`)) continue
        without++
        expect(spriteFor(def.id, form), `${def.id} form ${form}`).toBeNull()
      }
    }
    expect(without, "the species that still have no art").toBeGreaterThan(0)
  })
})

// ---------- the component ----------
// Rendered to a string in node (react-dom/server): CreatureArt is a pure function of a CreatureView, so no DOM is needed.

const storeOf = (game: GameState): GameStore => ({ ...createGameStore(loadGame(new MemoryStorage(), NOW, 1)).getState(), game })

function viewOf(speciesId: string, overrides: { form?: 1 | 2 | 3; shiny?: boolean } = {}): sel.CreatureView {
  const { state, creature } = addCreature(newGame(), speciesId, overrides)
  return sel.selectCreatureView(storeOf(state), creature.id)!
}

describe('CreatureView carries the id the sprite is looked up by', () => {
  it('is the species or hybrid id, in every form, for a species and for a hybrid', () => {
    expect(viewOf('sproutlet').speciesId).toBe('sproutlet')
    expect(viewOf('sproutlet', { form: 3 }).speciesId).toBe('sproutlet')
    expect(viewOf('emberfang', { form: 2 }).speciesId).toBe('emberfang')
    expect(viewOf('ashwood').speciesId).toBe('ashwood')
  })
})

describe('CreatureArt', () => {
  it('draws the sprite as a decorative, undraggable image at the form\'s scale', () => {
    for (const form of [1, 2, 3] as const) {
      const html = renderToStaticMarkup(createElement(CreatureArt, { view: viewOf('emberfang', { form }) }))
      // React 19 puts a preload <link> for the image ahead of it in server markup; the client renders only the <img>
      expect(html.replace(/<link [^>]*>/g, ''), `form ${form}`).toMatch(/^<img /)
      expect(html).toContain(`src="${spriteFor('emberfang', form)}"`)
      expect(html, 'decorative: the name is always beside it').toContain('alt=""')
      expect(html).toContain('draggable="false"')
      expect(html).toContain(`--sprite-scale:${sel.spriteScaleFor(form)}`)
      expect(html, 'a normal creature has no hue turn').not.toContain('--shiny-hue')
    }
  })

  it('draws the emoji, hidden from assistive tech, for a creature with no sprite', () => {
    const view = viewOf('brambletide')
    const html = renderToStaticMarkup(createElement(CreatureArt, { view }))
    expect(html).not.toContain('<img')
    expect(html).toContain('aria-hidden="true"')
    expect(html).toContain(view.emoji)
    expect(html, 'the emoji is one size for every form').not.toContain('--sprite-scale')
    // a hybrid with no art at all falls back too
    const hybrid = renderToStaticMarkup(createElement(CreatureArt, { view: viewOf('ashwood', { form: 2 }) }))
    expect(hybrid).not.toContain('<img')
  })

  it('a shiny gets the hue turn of its first type on the sprite and on the emoji, and nothing else changes', () => {
    const sproutlet = viewOf('sproutlet', { shiny: true })
    const turn = `--shiny-hue:${sproutlet.shinyHueDeg}deg`
    expect(sproutlet.shinyHueDeg, 'Verdant has no hue of its own, so the tuned one').toBe(sel.shinyHueDeg)
    const sprite = renderToStaticMarkup(createElement(CreatureArt, { view: sproutlet }))
    expect(sprite).toContain(turn)
    expect(sprite).toContain('data-shiny="true"')
    expect(sprite).toContain(`src="${spriteFor('sproutlet', 1)}"`)
    const brambletide = viewOf('brambletide', { shiny: true })
    const emoji = renderToStaticMarkup(createElement(CreatureArt, { view: brambletide }))
    expect(emoji).toContain(`--shiny-hue:${brambletide.shinyHueDeg}deg`)
    expect(emoji).toContain('data-shiny="true"')
    const plain = renderToStaticMarkup(createElement(CreatureArt, { view: viewOf('sproutlet') }))
    expect(plain).toContain('data-shiny="false"')
    // the same file either way: there is no shiny art
    expect(plain.match(/src="([^"]+)"/)![1]).toBe(sprite.match(/src="([^"]+)"/)![1])
  })
})

describe('CreatureArt, shiny hue per type', () => {
  it('a Void shiny is turned by the Void type 270 (sprite and emoji), the others by the tuned value', () => {
    // Riftsneak has a sprite; Eclipseed (a hybrid) has none, so it draws its emoji
    expect(spriteFor('riftsneak', 1)).not.toBeNull()
    expect(spriteFor('eclipseed', 1)).toBeNull()
    for (const [id, want] of [['riftsneak', 270], ['hushflutter', 270], ['sproutlet', 150], ['emberfang', 150], ['eclipseed', 270], ['ashwood', 150]] as const) {
      const html = renderToStaticMarkup(createElement(CreatureArt, { view: viewOf(id, { shiny: true }) }))
      expect(html, id).toContain(`--shiny-hue:${want}deg`)
    }
  })

  it('a normal Void creature has no hue turn at all', () => {
    expect(renderToStaticMarkup(createElement(CreatureArt, { view: viewOf('riftsneak') }))).not.toContain('--shiny-hue')
  })
})

describe('sprite scale (tuning.ui.spriteFormScale)', () => {
  it('is what the data says for each form, and grows with the form so growth shows', () => {
    const s = content.tuning.ui.spriteFormScale
    expect([sel.spriteScaleFor(1), sel.spriteScaleFor(2), sel.spriteScaleFor(3)]).toEqual([s['1'], s['2'], s['3']])
    expect(sel.spriteScaleFor(1)).toBeLessThan(sel.spriteScaleFor(2))
    expect(sel.spriteScaleFor(2)).toBeLessThan(sel.spriteScaleFor(3))
    for (const f of [1, 2, 3]) expect(sel.spriteScaleFor(f)).toBeGreaterThan(0)
    for (const f of [1, 2, 3]) expect(sel.spriteScaleFor(f)).toBeLessThanOrEqual(1)
  })
})
