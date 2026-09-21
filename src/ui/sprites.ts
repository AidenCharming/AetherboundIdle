/**
 * Creature sprites, found by file name and nothing else: `src/ui/assets/creatures/<species or hybrid id>-f<form 1 to 3>.png`
 * (`sproutlet-f2.png`, `ashwood-f1.png`). Adding a sprite is dropping the file in that folder: no data and no code changes,
 * and a creature with no file simply keeps its emoji (CreatureArt.tsx). test/sprites.test.ts fails the build if a file's
 * name does not match, so a typo cannot silently fall back to the emoji.
 *
 * Vite turns each file into a URL at build time. The app is built with `base: './'`, so the URLs are relative to the script
 * and load from file:// inside the desktop wrapper exactly as the background image (theme.css) does.
 */
const files = import.meta.glob('./assets/creatures/*.png', { eager: true, query: '?url', import: 'default' }) as Record<string, string>

/** `sproutlet-f2` -> its URL. */
const urls = new Map<string, string>()
for (const [path, url] of Object.entries(files)) {
  const name = /([^/]+)\.png$/.exec(path)?.[1]
  if (name) urls.set(name, url)
}

/** The sprite URL for a species or hybrid id in a form (1 to 3), or null when that art has not been made yet. */
export function spriteFor(speciesId: string, form: number): string | null {
  return urls.get(`${speciesId}-f${form}`) ?? null
}
