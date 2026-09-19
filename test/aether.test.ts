import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { accrueAether, benchedCreatures, creatureEmissionPerMin, emissionPerMin } from '../src/sim/aether'
import { makeCreature } from '../src/sim/creature'
import { addCreature, HOUR, newGame, pool, sproutletAtWork, variant } from './helpers'

const MIN = 60_000

describe('emission rate', () => {
  it('a benched Dim creature emits 1/min, and each rarity tier doubles it (rarities.json)', () => {
    expect(emissionPerMin(newGame())).toBe(1)
    const rates = content.rarities.map((r) => creatureEmissionPerMin(makeCreature('a', 'sproutlet', { rarityTier: r.tier })))
    expect(rates).toEqual([1, 2, 4, 8, 16, 32, 64, 128, 256])
  })

  it('only benched creatures emit: a creature in a work slot is excluded', () => {
    const working = sproutletAtWork()
    expect(benchedCreatures(working)).toEqual([])
    expect(emissionPerMin(working)).toBe(0)
    const both = addCreature(working, 'sproutlet', { rarityTier: 3 }).state
    expect(benchedCreatures(both).map((c) => c.id)).toEqual(['creature-2'])
    expect(emissionPerMin(both)).toBe(4)
  })

  it('sums over the whole bench', () => {
    let s = newGame()
    s = addCreature(s, 'sproutlet', { rarityTier: 2 }).state
    s = addCreature(s, 'sproutlet', { rarityTier: 4 }).state
    expect(emissionPerMin(s)).toBe(1 + 2 + 8)
  })

  it('scales with the capped bench_aether_emission modifier', () => {
    expect(creatureEmissionPerMin(makeCreature('a', 'sproutlet', { poolTraits: [pool('glimmer', 'moderate')] }))).toBeCloseTo(1.1)
    // Gridrift's Singularity Glow is Major (+20%) on a Steady (4/min) creature
    expect(creatureEmissionPerMin(makeCreature('g', 'gridrift', { rarityTier: 3 }))).toBeCloseTo(4 * 1.2)
    const capped = variant((raw) => {
      raw.modifiers.find((m: any) => m.key === 'bench_aether_emission').cap = 0.1
    })
    expect(creatureEmissionPerMin(makeCreature('a', 'sproutlet', { poolTraits: [pool('glimmer', 'major')] }, capped), capped)).toBeCloseTo(1.1)
  })
})

describe('accrual is continuous and fractional (plan 4.4)', () => {
  it('accrues emission * dt / 60000 with whatever dt the step carries, never in lumps', () => {
    const s = newGame()
    expect(accrueAether(s, 30_000).aether).toBeCloseTo(0.5) // half a minute of 1/min is half an Aether
    expect(accrueAether(s, 1).aether).toBeCloseTo(1 / 60_000, 12)
    expect(accrueAether(s, MIN).aether).toBeCloseTo(1)
    expect(accrueAether(s, 200).aether).toBeGreaterThan(0) // a single 200 ms frame is not worth zero
  })

  it('stores the float: nothing is rounded', () => {
    const a = accrueAether(newGame(), 12_345).aether
    expect(a).toBeCloseTo(12_345 / MIN, 12)
    expect(Number.isInteger(a)).toBe(false)
  })

  it('one 60-minute call equals N smaller calls summing to 60 minutes', () => {
    let s = newGame()
    s = addCreature(s, 'sproutlet', { rarityTier: 3, poolTraits: [pool('glimmer', 'minor')] }).state // 4.2/min
    s = addCreature(s, 'sproutlet', { rarityTier: 6 }).state // 32/min
    const oneShot = accrueAether(s, HOUR).aether

    const equalSteps = (n: number) => {
      let cur = s
      for (let i = 0; i < n; i++) cur = accrueAether(cur, HOUR / n)
      return cur.aether
    }
    for (const n of [2, 60, 3600, 36_000]) expect(equalSteps(n), `${n} steps`).toBeCloseTo(oneShot, 6)

    // a ragged split that still sums to an hour
    let ragged = s
    const parts = [1, 199, 15_000, 3, 999_997, 1_000_000, 700_000, 884_800]
    expect(parts.reduce((a, b) => a + b, 0)).toBe(HOUR)
    for (const p of parts) ragged = accrueAether(ragged, p)
    expect(ragged.aether).toBeCloseTo(oneShot, 6)
    expect(oneShot).toBeCloseTo((1 + 4.2 + 32) * 60, 8)
  })

  it('benchEmissionTickMs is a display/save cadence and cannot change what is earned', () => {
    const totals = [1, 1000, 60_000, 86_400_000].map((tickMs) => {
      const c = variant((raw) => {
        raw.tuning.aether.benchEmissionTickMs = tickMs
      })
      const s = addCreature(newGame(c), 'sproutlet', { rarityTier: 5 }, c).state
      let cur = s
      for (let i = 0; i < 90; i++) cur = accrueAether(cur, 10 * MIN, c)
      return cur.aether
    })
    for (const t of totals) expect(t).toBeCloseTo(totals[0]!, 9)
    expect(totals[0]).toBeCloseTo((1 + 16) * 900, 6)
  })

  it('does not touch the RNG, whatever the window', () => {
    const s = newGame()
    expect(accrueAether(s, 100 * HOUR).rngState).toBe(s.rngState)
  })

  for (const [label, dt] of [['zero', 0], ['negative (clock skew)', -HOUR], ['NaN', NaN], ['infinite', Infinity]] as const) {
    it(`a ${label} window accrues nothing and returns the same state`, () => {
      const s = newGame()
      expect(accrueAether(s, dt)).toBe(s)
    })
  }

  it('an empty bench accrues nothing and returns the same state', () => {
    const s = sproutletAtWork()
    expect(accrueAether(s, HOUR)).toBe(s)
  })

  it('does not mutate its input', () => {
    const s = newGame()
    accrueAether(s, HOUR)
    expect(s.aether).toBe(0)
  })
})
