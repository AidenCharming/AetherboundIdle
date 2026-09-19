import { describe, expect, it } from 'vitest'
import { binomial, createRng } from '../src/sim/rng'

// Independent copy of the canonical mulberry32, to prove createRng is the real thing.
function reference(seed: number): () => number {
  let a = seed >>> 0
  return () => {
    a = (a + 0x6d2b79f5) >>> 0
    let t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}

describe('mulberry32', () => {
  it('produces a fixed, known sequence', () => {
    const rng = createRng(1)
    expect([rng.next(), rng.next(), rng.next()]).toEqual([0.6270739405881613, 0.002735721180215478, 0.5274470399599522])
  })

  it('matches the reference implementation over a long run and stays in [0, 1)', () => {
    const rng = createRng(987654321)
    const ref = reference(987654321)
    for (let i = 0; i < 5000; i++) {
      const v = rng.next()
      expect(v).toBe(ref())
      expect(v).toBeGreaterThanOrEqual(0)
      expect(v).toBeLessThan(1)
    }
  })

  it('is fully described by its uint32 state', () => {
    const rng = createRng(42)
    for (let i = 0; i < 10; i++) rng.next()
    const resumed = createRng(rng.state)
    for (let i = 0; i < 100; i++) expect(resumed.next()).toBe(rng.next())
  })

  it('normalises the seed to a uint32', () => {
    expect(createRng(-1).state).toBe(4294967295)
    expect(createRng(2 ** 32 + 5).state).toBe(5)
  })
})

describe('the state advances on every consume', () => {
  it('next, int and chance each move the state', () => {
    for (const draw of [(r: ReturnType<typeof createRng>) => r.next(), (r: ReturnType<typeof createRng>) => r.int(10), (r: ReturnType<typeof createRng>) => r.chance(0.5)]) {
      const rng = createRng(7)
      const before = rng.state
      draw(rng)
      expect(rng.state).not.toBe(before)
    }
  })

  it('chance consumes exactly one value whatever p is, so the stream stays aligned', () => {
    const a = createRng(9)
    const b = createRng(9)
    a.chance(0)
    b.chance(1)
    expect(a.state).toBe(b.state)
  })

  it('int stays in range and uses the whole range', () => {
    const rng = createRng(3)
    const seen = new Set<number>()
    for (let i = 0; i < 500; i++) {
      const v = rng.int(6)
      expect(Number.isInteger(v) && v >= 0 && v < 6).toBe(true)
      seen.add(v)
    }
    expect(seen.size).toBe(6)
  })

  it('a save/reload between rolls continues the stream instead of replaying it', () => {
    const live = createRng(2024)
    live.next()
    live.next()
    const savedState = live.state // what the save file holds
    const reloaded = createRng(savedState)
    const next = live.next()
    expect(reloaded.next()).toBe(next)
    // Restarting from the ORIGINAL seed (the mistake persisting only the seed would make) replays the start.
    expect(createRng(2024).next()).not.toBe(next)
  })
})

describe('binomial', () => {
  it('handles the degenerate cases without consuming anything', () => {
    const rng = createRng(5)
    const before = rng.state
    expect(rng.binomial(0, 0.5)).toBe(0)
    expect(rng.binomial(100, 0)).toBe(0)
    expect(rng.binomial(100, -1)).toBe(0)
    expect(rng.binomial(100, 1)).toBe(100)
    expect(rng.binomial(100, 7)).toBe(100)
    expect(rng.binomial(NaN, 0.5)).toBe(0)
    expect(rng.state).toBe(before)
  })

  it('is deterministic for a given state', () => {
    expect(binomial(createRng(11), 5000, 0.37)).toBe(binomial(createRng(11), 5000, 0.37))
  })

  // Mean and variance over many draws, in each regime: exact waiting-time (small n*p), normal, and the
  // p > 0.5 complement of each.
  for (const [n, p] of [
    [50, 0.1],
    [200, 0.02],
    [10_000, 0.3],
    [40, 0.9],
    [100_000, 0.85],
  ] as const) {
    it(`draws with the right mean and spread for n=${n}, p=${p}`, () => {
      const rng = createRng(n * 31 + Math.round(p * 100))
      const draws = 4000
      let sum = 0
      let sumSq = 0
      for (let i = 0; i < draws; i++) {
        const v = rng.binomial(n, p)
        expect(Number.isInteger(v) && v >= 0 && v <= n).toBe(true)
        sum += v
        sumSq += v * v
      }
      const mean = sum / draws
      const variance = sumSq / draws - mean * mean
      const sd = Math.sqrt(n * p * (1 - p))
      expect(Math.abs(mean - n * p)).toBeLessThan((5 * sd) / Math.sqrt(draws))
      expect(variance / (sd * sd)).toBeGreaterThan(0.85)
      expect(variance / (sd * sd)).toBeLessThan(1.15)
    })
  }

  it('costs about n*p draws in the rare-drop regime, not n', () => {
    const rng = createRng(1)
    const start = rng.state
    rng.binomial(1_000_000, 0.00001) // expect ~10 successes
    const reference = createRng(start)
    let draws = 0
    while (reference.state !== rng.state && draws < 1000) {
      reference.next()
      draws++
    }
    expect(draws).toBeLessThan(100)
  })
})
