import { existsSync, mkdirSync, mkdtempSync, readdirSync, rmSync, symlinkSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { afterEach, describe, expect, it } from 'vitest'
import builderConfig from '../electron-builder.yml?raw'
import packageJson from '../package.json'
import gitignore from '../.gitignore?raw'
import mainSource from '../electron/main.cjs?raw'
import smokeSource from '../electron/smoke.cjs?raw'
import themeCss from '../src/ui/theme.css?raw'
import viteConfig from '../vite.config.ts?raw'

// The desktop wrapper's rules (step 1.9), checked against its source so they cannot rot. The wrapper itself is
// exercised by `npm run electron:smoke`, which needs a real Electron and is not part of `npm test`.

const sources = import.meta.glob('../src/**/*.{ts,tsx}', { query: '?raw', import: 'default', eager: true }) as Record<string, string>
/** Code without comments, so a comment that names a forbidden thing is not a violation. */
const code = (source: string): string => source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '')

const main = code(mainSource)
const wrapper = main + code(smokeSource)

describe('desktop wrapper', () => {
  it('opens the built game with the game window locked down', () => {
    expect(main).toMatch(/loadFile\(INDEX\)/)
    expect(main).toMatch(/'dist', 'index\.html'/)
    expect(main).toMatch(/contextIsolation:\s*true/)
    expect(main).toMatch(/nodeIntegration:\s*false/)
    expect(main).toMatch(/sandbox:\s*true/)
  })

  it('has no IPC and no preload script', () => {
    expect(wrapper).not.toMatch(/\b(ipcMain|ipcRenderer|contextBridge|preload)\b/)
  })

  it('leaves background throttling alone (the tick driver handles any gap)', () => {
    expect(wrapper).not.toMatch(/backgroundThrottling/)
    expect(wrapper).not.toMatch(/setBackgroundThrottling|disable-renderer-backgrounding|disable-background-timer-throttling|disable-backgrounding-occluded-windows/)
  })

  it('takes the single-instance lock and quits when it does not get it', () => {
    expect(main).toMatch(/requestSingleInstanceLock\(\)/)
    expect(main).toMatch(/if \(!gotLock\) app\.quit\(\)/)
    expect(main).toMatch(/'second-instance'/)
  })

  it('shows DevTools only when not packaged, and has no menu bar', () => {
    expect(main).toMatch(/devTools:\s*!app\.isPackaged/)
    expect(main).toMatch(/Menu\.setApplicationMenu\(null\)/)
  })

  it('never opens an external link inside the game window', () => {
    expect(main).toMatch(/setWindowOpenHandler/)
    expect(main).toMatch(/action: 'deny'/)
    expect(main).toMatch(/'will-navigate'/)
  })

  it("paints the game's own background before the first frame", () => {
    const window = /BACKGROUND = '(#[0-9a-fA-F]{6})'/.exec(mainSource)?.[1]
    const theme = /--bg:\s*(#[0-9a-fA-F]{6})/.exec(themeCss)?.[1]
    expect(window, 'BACKGROUND in electron/main.cjs').toBeDefined()
    expect(theme, '--bg in theme.css').toBeDefined()
    expect(window!.toLowerCase()).toBe(theme!.toLowerCase())
  })

  it('the built page loads from file:// (relative base) and nothing in src knows about Electron', () => {
    expect(viteConfig).toMatch(/base:\s*'\.\/'/)
    for (const [path, source] of Object.entries(sources)) expect(/electron/i.test(code(source)), path).toBe(false)
  })
})

describe('clean release folder (electron/clean-release.mjs)', () => {
  type Clean = (root: string, options?: { retries?: number; delayMs?: number; remove?: (entry: string) => void }) => Promise<string[]>
  // A file: URL keeps the plain-JS script out of tsc's reach (electron/ is not in tsconfig) while node still loads it.
  const load = async () => (await import(/* @vite-ignore */ new URL('../electron/clean-release.mjs', import.meta.url).href)) as { cleanRelease: Clean }
  const made: string[] = []
  afterEach(() => {
    for (const dir of made.splice(0)) rmSync(dir, { recursive: true, force: true })
  })
  const fakeRepo = () => {
    const base = mkdtempSync(join(tmpdir(), 'clean-release-'))
    made.push(base)
    const root = join(base, 'repo')
    mkdirSync(join(root, 'release', 'win-unpacked', 'resources'), { recursive: true })
    writeFileSync(join(root, 'package.json'), '{}')
    writeFileSync(join(root, 'release', 'Aetherbound-Idle-0.1.2-setup.exe'), 'old')
    writeFileSync(join(root, 'release', 'win-unpacked', 'resources', 'app.asar'), 'old')
    return { base, root }
  }

  it('empties release/ but keeps the folder, and touches nothing beside it or behind a link inside it', async () => {
    const { cleanRelease } = await load()
    const { base, root } = fakeRepo()
    mkdirSync(join(base, 'outside'))
    writeFileSync(join(base, 'outside', 'keep.txt'), 'mine')
    writeFileSync(join(root, 'keep-beside.txt'), 'mine')
    symlinkSync(join(base, 'outside'), join(root, 'release', 'link'), 'junction')
    const removed = await cleanRelease(root)
    expect(removed.sort()).toEqual(['Aetherbound-Idle-0.1.2-setup.exe', 'link', 'win-unpacked'])
    expect(readdirSync(join(root, 'release'))).toEqual([])
    expect(existsSync(join(base, 'outside', 'keep.txt')), 'the link target is not followed').toBe(true)
    expect(existsSync(join(root, 'keep-beside.txt'))).toBe(true)
    expect(await cleanRelease(join(base, 'repo')), 'a second run finds nothing to do').toEqual([])
  })

  it('refuses a release/ that is a link out of the repo, and a folder that is not the repo root', async () => {
    const { cleanRelease } = await load()
    const { base, root } = fakeRepo()
    mkdirSync(join(base, 'outside'))
    writeFileSync(join(base, 'outside', 'keep.txt'), 'mine')
    rmSync(join(root, 'release'), { recursive: true })
    symlinkSync(join(base, 'outside'), join(root, 'release'), 'junction')
    await expect(cleanRelease(root)).rejects.toThrow(/Refusing to clean/)
    expect(existsSync(join(base, 'outside', 'keep.txt'))).toBe(true)
    rmSync(join(root, 'package.json'))
    await expect(cleanRelease(root)).rejects.toThrow(/not the repo root/)
  })

  it('retries a locked file, then stops with the plain-language message so the build does not start', async () => {
    const { cleanRelease } = await load()
    const { root } = fakeRepo()
    let calls = 0
    const locked = () => {
      calls++
      throw Object.assign(new Error('resource busy or locked'), { code: 'EBUSY' })
    }
    await expect(cleanRelease(root, { retries: 2, delayMs: 1, remove: locked })).rejects.toThrow(/Close the game and any Explorer window in release\/, then run it again/)
    expect(calls, 'two entries, three attempts each').toBe(6)
    // a lock that clears on the second attempt is fine
    let first = true
    const clears = (entry: string) => {
      if (first) {
        first = false
        throw Object.assign(new Error('busy'), { code: 'EPERM' })
      }
      rmSync(entry, { recursive: true, force: true })
    }
    expect((await cleanRelease(root, { retries: 2, delayMs: 1, remove: clears })).length).toBe(2)
  })

  it('runs between the build and electron-builder in `npm run electron:pack`', () => {
    const pack = (packageJson.scripts as Record<string, string>)['electron:pack']!
    const steps = pack.split('&&').map((s) => s.trim())
    expect(steps).toEqual(['npm run build', 'node electron/clean-release.mjs', 'electron-builder --win'])
  })
})

describe('desktop packaging', () => {
  it('builds both a Windows installer and a portable single exe, named Aetherbound Idle, into release/', () => {
    expect(builderConfig).toMatch(/productName:\s*Aetherbound Idle/)
    expect(builderConfig).toMatch(/target:\s*nsis/)
    expect(builderConfig).toMatch(/target:\s*portable/)
    expect(builderConfig).toMatch(/output:\s*release/)
    expect(gitignore).toMatch(/^release\/$/m)
  })

  it('packs only the built game and the wrapper: no sources, no node_modules', () => {
    expect(builderConfig).toMatch(/- dist\/\*\*/)
    expect(builderConfig).toMatch(/- electron\/main\.cjs/)
    expect(builderConfig).toMatch(/'!\*\*\/node_modules\/\*\*'/)
    expect(builderConfig).not.toMatch(/- src\//)
  })

  it('runs the icon and the packaged main from the paths the wrapper ships', () => {
    expect(builderConfig).toMatch(/icon:\s*electron\/assets\/icon\.ico/)
    expect(builderConfig).toMatch(/buildResources:\s*electron\/assets/)
  })
})

