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
    for (const [, px] of themeCode.matchAll(/backdrop-filter:\s*blur\((\d+)px\)/g)) expect(Number(px), 'a large backdrop blur is slow on weak GPUs').toBeLessThanOrEqual(12)
  })

  it('keeps the shipped image small enough to bundle without thought', () => {
    const bg = files.find((p) => p.includes('app-bg.jpg'))!
    expect(bg, 'the background image the theme references').toBeDefined()
    expect(statSync(join(root, bg)).size).toBeLessThan(1_500_000)
  })
})
