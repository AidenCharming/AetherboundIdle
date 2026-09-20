import { describe, expect, it } from 'vitest'

// The layering rules from plan.md section 1 and CLAUDE.md, checked against the source so they cannot rot.

const sources = import.meta.glob('../src/**/*.{ts,tsx}', { query: '?raw', import: 'default', eager: true }) as Record<string, string>
const styles = import.meta.glob('../src/**/*.css', { query: '?raw', import: 'default', eager: true }) as Record<string, string>

/** 'src/sim/tick.ts' style paths, sorted. */
const all = Object.entries(sources)
  .map(([path, source]) => ({ path: path.replace('../src/', ''), source }))
  .sort((a, b) => a.path.localeCompare(b.path))
const under = (prefix: string) => all.filter((f) => f.path.startsWith(prefix))

/** Every module specifier a file imports (`from '...'`, bare `import '...'`, dynamic `import('...')`). */
const imports = (source: string): string[] => [...source.matchAll(/(?:from\s+|import\s*\(?\s*)['"]([^'"]+)['"]/g)].map((m) => m[1]!)

/** Code without comments, so a comment that mentions `window` or `Math.random` is not a violation. */
const code = (source: string): string => source.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/.*$/gm, '')

describe('layering', () => {
  it('finds the source tree', () => {
    expect(under('sim/').length).toBeGreaterThan(5)
    expect(under('state/').length).toBeGreaterThan(3)
    expect(under('ui/').length).toBeGreaterThan(3)
  })

  it('the UI never imports the sim (it reads through state/selectors.ts)', () => {
    for (const f of [...under('ui/'), ...under('App.tsx'), ...under('main.tsx')]) {
      for (const spec of imports(f.source)) expect(/(^|\/)sim(\/|$)/.test(spec), `${f.path} imports ${spec}`).toBe(false)
    }
  })

  it('the UI reaches the game only through selectors, actions and the runtime hooks', () => {
    const allowed = new Set(['selectors', 'runtime', 'actions'])
    for (const f of [...under('ui/'), ...under('App.tsx')]) {
      for (const spec of imports(f.source)) {
        const m = spec.match(/\/state\/([\w-]+)$/)
        if (m) expect(allowed.has(m[1]!), `${f.path} imports ${spec}`).toBe(true)
      }
    }
  })

  it('the sim imports only sim, data and types (and no React or zustand), and reads no clock or randomness', () => {
    for (const f of under('sim/')) {
      for (const spec of imports(f.source)) {
        if (spec.startsWith('.')) expect(/^\.\/[\w-]+$|^\.\.\/(data|types)(\/|$)/.test(spec), `${f.path} imports ${spec}`).toBe(true)
        else expect(/^(react|zustand)/.test(spec), `${f.path} imports ${spec}`).toBe(false)
      }
      expect(/Date\.now\s*\(|new Date\s*\(|Math\.random\s*\(/.test(code(f.source)), `${f.path} reads the clock or Math.random`).toBe(false)
    }
  })

  it('nothing in src calls Math.random (seeds come from crypto.getRandomValues, rolls from the seeded RNG)', () => {
    for (const f of all) expect(/Math\.random\s*\(/.test(code(f.source)), f.path).toBe(false)
  })

  it('nothing in ui/ hardcodes a color: type and rarity colors come from the data, and CSS holds only the neutral chrome tokens', () => {
    const hex = /#[0-9a-fA-F]{3,8}(?![0-9a-zA-Z])/
    for (const f of under('ui/')) expect(hex.test(code(f.source)), `${f.path} contains a hex color`).toBe(false)
    expect(Object.keys(styles).length).toBeGreaterThan(0)
    for (const [path, css] of Object.entries(styles)) {
      expect(css.length, `${path} was read as empty (vitest.config.ts must let .css through)`).toBeGreaterThan(0)
      // The one place a hex may live: the `:root` block of custom properties (neutral background, text and line colors).
      const outsideRoot = css.replace(/\/\*[\s\S]*?\*\//g, '').replace(/:root\s*\{[^}]*\}/, '')
      expect(hex.test(outsideRoot), `${path} has a hex color outside :root`).toBe(false)
    }
  })

  it('only runtime.ts touches the browser globals in the state layer', () => {
    for (const f of under('state/')) {
      if (f.path === 'state/runtime.ts') continue
      expect(/\b(window|document|localStorage|Date\.now)\b/.test(code(f.source)), f.path).toBe(false)
    }
  })
})
