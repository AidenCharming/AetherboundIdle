import { readdirSync, readFileSync, statSync } from 'node:fs'
import { join, relative } from 'node:path'
import { fileURLToPath } from 'node:url'
import { describe, expect, it } from 'vitest'
import themeCss from '../src/ui/theme.css?raw'

/** theme.css without its comments, so a comment that names a forbidden property is not a violation. */
const themeCode = themeCss.replace(/\/\*[\s\S]*?\*\//g, '')

// The shipped art (step 1.9c). Two things can go wrong silently with an image asset, and both did here:
//  1. theme.css names a file that is not there, and the page just has no background;
//  2. a file's EXTENSION lies about its contents. `app-bg.png` was really JPEG data, which Vite will happily bundle
//     and serve as image/png, leaving the browser to sniff it. It worked, but nothing promised it would keep working
//     from file:// in the packaged app, so the file was renamed to .jpg. This guard stops the next one.

const root = fileURLToPath(new URL('..', import.meta.url))
const assetsDir = join(root, 'src', 'ui', 'assets')

/** Every file under src/ui/assets, as repo-relative paths with forward slashes. */
function walk(dir: string): string[] {
  const out: string[] = []
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry)
    if (statSync(full).isDirectory()) out.push(...walk(full))
    else out.push(relative(root, full).split('\\').join('/'))
  }
  return out
}

/** The first bytes that identify a format, and the extensions that may carry them. */
const SIGNATURES: ReadonlyArray<{ name: string; extensions: string[]; matches: (b: Buffer) => boolean }> = [
  { name: 'PNG', extensions: ['.png'], matches: (b) => b.subarray(0, 8).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])) },
  { name: 'JPEG', extensions: ['.jpg', '.jpeg'], matches: (b) => b[0] === 0xff && b[1] === 0xd8 && b[2] === 0xff },
  { name: 'WebP', extensions: ['.webp'], matches: (b) => b.subarray(0, 4).toString('latin1') === 'RIFF' && b.subarray(8, 12).toString('latin1') === 'WEBP' },
  { name: 'GIF', extensions: ['.gif'], matches: (b) => b.subarray(0, 3).toString('latin1') === 'GIF' },
]

const files = walk(assetsDir).filter((p) => !p.endsWith('.gitkeep'))

describe('shipped art assets', () => {
  it('finds the asset folder', () => {
    expect(files.length).toBeGreaterThan(0)
  })

  it('every file is really the format its extension claims', () => {
    for (const path of files) {
      const bytes = readFileSync(join(root, path))
      const ext = path.slice(path.lastIndexOf('.')).toLowerCase()
      const actual = SIGNATURES.find((s) => s.matches(bytes))
      expect(actual, `${path} has no recognised image signature (first bytes ${[...bytes.subarray(0, 4)].map((b) => b.toString(16)).join(' ')})`).toBeDefined()
      expect(actual!.extensions, `${path} is ${actual!.name} data with a ${ext} name; rename it so the served MIME type is right`).toContain(ext)
    }
  })

  it('every file theme.css references exists on disk', () => {
    const referenced = [...themeCss.matchAll(/url\(\s*['"]?([^'")]+)['"]?\s*\)/g)].map((m) => m[1]!).filter((u) => !u.startsWith('data:') && !u.startsWith('http'))
    expect(referenced.length, 'theme.css references no asset at all').toBeGreaterThan(0)
    for (const url of referenced) {
      // theme.css lives in src/ui/, and its urls are relative to it.
      const onDisk = join(root, 'src', 'ui', url)
      expect(() => statSync(onDisk), `theme.css references ${url}, which is not on disk`).not.toThrow()
    }
  })

  it('the background image is wired in through tokens, over a scrim, as a fixed layer', () => {
    expect(themeCss).toMatch(/--bg-image:\s*url\(/)
    expect(themeCss).toMatch(/--bg-scrim:\s*linear-gradient/)
    expect(themeCss).toMatch(/background-image:\s*var\(--bg-scrim\),\s*var\(--bg-image\)/)
    expect(themeCss).toMatch(/background-size:\s*cover/)
    // background-attachment: fixed repaints the image on every scroll frame; the layer is a fixed pseudo-element instead.
    expect(themeCode).not.toMatch(/background-attachment:\s*fixed/)
  })

  it('stays static: no animation on the background layer and no large backdrop blur anywhere', () => {
    const layer = /\.shell::before\s*\{([^}]*)\}/.exec(themeCode)?.[1] ?? ''
    expect(layer.length, '.shell::before is the background layer and must exist').toBeGreaterThan(0)
    expect(layer).not.toMatch(/animation|transition|filter/)
    // The blur is a token (--glass-blur) so the designer retunes it in one place; every value in the file is capped.
    const blurs = [...themeCode.matchAll(/blur\((\d+)px\)/g)].map((m) => Number(m[1]))
    expect(blurs.length, 'no blur found: the glass token is gone').toBeGreaterThan(0)
    for (const px of blurs) expect(px, 'a large backdrop blur is slow on weak GPUs').toBeLessThanOrEqual(12)
  })

  it('glass: the surfaces are see-through by tokens, the blur is on the sidebar and the header only, and what covers content is opaque', () => {
    const token = (name: string): string => new RegExp(`${name}:\\s*([^;]+);`).exec(themeCode)?.[1]?.trim() ?? ''
    // the three opacities the designer retunes, each a percentage strictly between 0 and 100
    for (const name of ['--glass-panel', '--glass-raised', '--glass-chrome']) {
      const pct = Number(/^(\d+)%$/.exec(token(name))?.[1])
      expect(pct, `${name} must be a whole percentage`).toBeGreaterThan(0)
      expect(pct, `${name} must be see-through, or it is not glass`).toBeLessThan(100)
    }
    expect(token('--panel'), 'the card surface reads the glass token').toContain('var(--glass-panel)')
    expect(token('--panel-raised')).toContain('var(--glass-raised)')
    expect(token('--sidebar-surface')).toContain('var(--glass-chrome)')
    expect(token('--header-surface')).toContain('var(--glass-chrome)')
    // the designer's limit for the blur is 8 px (the general cap above is 12)
    expect(Number(/blur\((\d+)px\)/.exec(token('--glass-blur'))?.[1])).toBeLessThanOrEqual(8)
    // backdrop-filter appears exactly twice, once for the docked sidebar and once for the header, and never on the many cards
    const rules = [...themeCode.matchAll(/([^{}]+)\{[^{}]*backdrop-filter:\s*var\(--glass-blur\)[^{}]*\}/g)].map((m) => m[1]!.trim())
    expect(rules).toEqual([".sidebar[data-drawer='false']", '.header'])
    expect((themeCode.match(/backdrop-filter:/g) ?? []).length).toBe(2)
    // what slides over the page (the phone drawer, the notification panel, the dialogs) is opaque, so the page does not ghost through it
    for (const selector of [/\.sidebar\[data-drawer='true'\]\s*\{\s*background:\s*var\(--panel-solid\)/, /\.notif-panel\s*\{[^}]*background:\s*var\(--panel-solid\)/, /\.wb\s*\{[^}]*background:\s*var\(--panel-solid\)/, /\.toast\s*\{[^}]*background:\s*var\(--panel-high\)/]) {
      expect(themeCode).toMatch(selector)
    }
    // the light edge and the control edge are tokens, so a card's outline and a control's boundary are each one edit
    expect(token('--edge')).toMatch(/^rgb\(255 255 255 \/ \d+%\)$/)
    expect(token('--control-edge')).toMatch(/^#[0-9a-f]{6}$/i)
  })

  it('keeps the shipped image small enough to bundle without thought', () => {
    const bg = files.find((p) => p.includes('app-bg.jpg'))!
    expect(bg, 'the background image the theme references').toBeDefined()
    expect(statSync(join(root, bg)).size).toBeLessThan(1_500_000)
  })
})
