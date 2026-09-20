import { describe, expect, it } from 'vitest'
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
