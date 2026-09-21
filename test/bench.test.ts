import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { creatureEmissionPerMin, emissionPerMin } from '../src/sim/aether'
import { applyOffline } from '../src/sim/offline'
import { step } from '../src/sim/tick'
import * as sel from '../src/state/selectors'
import { loadGame } from '../src/state/persistence'
import { createGameStore, type GameStore } from '../src/state/store'
import { formatRate } from '../src/ui/format'
import type { GameState } from '../src/types/state'
import { addCreature, MemoryStorage, newGame, NOW, pool, rosterGame, work } from './helpers'

const view = (game: GameState): GameStore => ({ ...createGameStore(loadGame(new MemoryStorage(), NOW, 1)).getState(), game })

const rate = (tier: number): number => content.rarities[tier - 1]!.benchEmissionPerMin

/** A game with the starter plus one creature at each of the listed rarity tiers, all benched. */
function benchOf(...tiers: number[]): GameState {
  let state = newGame()
  for (const tier of tiers) state = addCreature(state, 'sproutlet', { rarityTier: tier }).state
  return state
}

describe('bench emission selectors expose the sim numbers', () => {
  it("each entry is the sim's own creatureEmissionPerMin, and the total is the sim's own emissionPerMin, exactly", () => {
    const game = rosterGame(60) // 61 creatures, all rarities, traits, some working
    const s = view(game)
    const entries = sel.selectBenchEntries(s)
    const benched = game.creatures.filter((cr) => cr.assignment === null)
    expect(entries).toHaveLength(benched.length)
    for (const entry of entries) {
      const cr = game.creatures.find((c) => c.id === entry.view.id)!
      expect(entry.perMin).toBe(creatureEmissionPerMin(cr))
    }
    expect(sel.selectAetherPerMinute(s)).toBe(emissionPerMin(game))
    expect(sel.selectAetherPerMinute(s)).toBeCloseTo(entries.reduce((sum, e) => sum + e.perMin, 0), 9)
  })

  it('a Zenith creature on the bench is worth the data\'s Zenith rate, on top of the starter', () => {
    const zenith = content.rarities.length
    expect(rate(zenith)).toBe(256) // the number this test is about: rarities.json, Zenith
    const s = view(benchOf(zenith))
    expect(sel.selectAetherPerMinute(s)).toBe(rate(1) + rate(zenith))
    expect(sel.selectAetherPerHour(s)).toBe((rate(1) + rate(zenith)) * 60)
  })

  it('emission traits scale a creature\'s rate and the selector shows the fraction', () => {
    const glimmer = content.traitById.get('glimmer')!
    const minor = (glimmer.effects[0]!.valueByStrength as Record<string, number>).minor!
    let game = newGame()
    game = addCreature(game, 'sproutlet', { rarityTier: 1, poolTraits: [pool('glimmer', 'minor')] }).state
    const s = view(game)
    const withTrait = sel.selectBenchEntries(s).find((e) => e.view.id === 'creature-2')!
    expect(withTrait.perMin).toBeCloseTo(rate(1) * (1 + minor), 12)
    expect(withTrait.perMin).not.toBe(rate(1))
    expect(sel.selectAetherPerMinute(s)).toBe(emissionPerMin(game))
  })

  it('lists only the benched: working a slot takes a creature off the list and out of the total', () => {
    let game = benchOf(3, 5)
    const before = view(game)
    expect(sel.selectBenchEntries(before)).toHaveLength(3)
    expect(sel.selectAetherPerMinute(before)).toBe(rate(1) + rate(3) + rate(5))

    game = work(game, 'creature-3', 'woodcutting', 0, 'oak-log') // the tier-5 creature
    const after = view(game)
    expect(sel.selectBenchEntries(after).map((e) => e.view.id).sort()).toEqual(['creature-1', 'creature-2'])
    expect(sel.selectAetherPerMinute(after)).toBe(rate(1) + rate(3))
  })

  it('says 0 and lists nobody when nothing is benched', () => {
    const game = work(newGame(), 'creature-1', 'woodcutting', 0, 'oak-log')
    const s = view(game)
    expect(sel.selectBenchEntries(s)).toEqual([])
    expect(sel.selectAetherPerMinute(s)).toBe(0)
    expect(sel.selectAetherPerHour(s)).toBe(0)
  })

  it('sorts the biggest emitter first, and the older creature first when they tie', () => {
    const game = benchOf(2, 9, 2, 5) // ids creature-2 (tier 2), -3 (9), -4 (2), -5 (5); the starter is tier 1
    const expected = ['creature-3', 'creature-5', 'creature-2', 'creature-4', 'creature-1']
    expect(sel.selectBenchEntries(view(game)).map((e) => e.view.id)).toEqual(expected)
    // The tie-break is the id, not the order the game happens to hold the creatures in.
    const reversed = { ...game, creatures: game.creatures.slice().reverse() }
    expect(sel.selectBenchEntries(view(reversed)).map((e) => e.view.id)).toEqual(expected)
  })

  it('carries the roster view of each creature, so the Nexus shows the same card', () => {
    const s = view(benchOf(9))
    const entry = sel.selectBenchEntries(s).find((e) => e.view.id === 'creature-2')!
    expect(entry.view).toBe(sel.selectCreatureView(s, 'creature-2'))
    expect(entry.view.rarity.name).toBe('Zenith')
  })
})

describe('bench selectors keep identity (zustand v5 loops on a fresh array per call)', () => {
  it('returns the same list and the same numbers on every call, and through a tick that changes no creature', () => {
    let game = benchOf(4, 7)
    const a = view(game)
    const list = sel.selectBenchEntries(a)
    expect(sel.selectBenchEntries(a)).toBe(list)
    const ticked = view(step(game, 100).state)
    expect(ticked.game.creatures).toBe(game.creatures) // the tick never replaces the array
    expect(sel.selectBenchEntries(ticked)).toBe(list)
    for (let i = 0; i < 50; i++) game = step(game, 100).state
    expect(sel.selectBenchEntries(view(game))).toBe(list)
    expect(sel.selectAetherPerMinute(view(game))).toBe(sel.selectAetherPerMinute(a))
  })

  it('changes identity when somebody moves on or off the bench, and only then', () => {
    const game = benchOf(4, 7)
    const list = sel.selectBenchEntries(view(game))
    const working = work(game, 'creature-2', 'woodcutting', 0, 'oak-log')
    const next = sel.selectBenchEntries(view(working))
    expect(next).not.toBe(list)
    expect(next).toHaveLength(list.length - 1)
    // the entries of the two who did not move are the same objects
    expect(next.every((e) => list.includes(e))).toBe(true)
  })

  it('reuses the previous list when a new creatures array leaves the bench exactly as it was', () => {
    const game = benchOf(4, 7)
    const list = sel.selectBenchEntries(view(game))
    const same = { ...game, creatures: game.creatures.slice() } // a new array, the same creature objects
    expect(sel.selectBenchEntries(view(same))).toBe(list)
  })
})

describe('the rate is the rate that accrues: online and offline agree with it', () => {
  it('a minute of ticks, a single minute-long step and a minute offline all add the selector rate', () => {
    let game = benchOf(9, 6, 3)
    game = { ...game, aether: 100, lastSeen: NOW }
    const perMin = sel.selectAetherPerMinute(view(game))
    expect(perMin).toBe(rate(1) + rate(9) + rate(6) + rate(3))

    let ticked = game
    for (let i = 0; i < 600; i++) ticked = step(ticked, 100).state // 600 x 100 ms
    const stepped = step(game, 60_000).state
    const offline = applyOffline(game, NOW + 60_000).state

    expect(ticked.aether - game.aether).toBeCloseTo(perMin, 6)
    expect(stepped.aether - game.aether).toBeCloseTo(perMin, 6)
    expect(offline.aether - game.aether).toBeCloseTo(perMin, 6)
    expect(ticked.aether).toBeCloseTo(offline.aether, 6)
  })

  it('an hour offline adds exactly the per-hour figure, and nothing lumps into once-a-minute steps', () => {
    let game = benchOf(9)
    game = { ...game, aether: 0, lastSeen: NOW }
    const s = view(game)
    const offline = applyOffline(game, NOW + 3_600_000).state
    expect(offline.aether).toBeCloseTo(sel.selectAetherPerHour(s), 6)
    // Half a minute in is half a minute's worth, not zero until the minute turns.
    expect(step(game, 30_000).state.aether).toBeCloseTo(sel.selectAetherPerMinute(s) / 2, 9)
  })
})

describe('formatRate', () => {
  it('shows zero as 0 and a tiny nonzero rate as "<0.01", never a misleading 0', () => {
    expect(formatRate(0)).toBe('0')
    expect(formatRate(-3)).toBe('0')
    expect(formatRate(NaN)).toBe('0')
    expect(formatRate(0.004)).toBe('<0.01')
    expect(formatRate(0.01)).toBe('0.01')
  })

  it('keeps up to two decimals below 10, one below 1,000, none above, and drops trailing zeros', () => {
    expect(formatRate(1)).toBe('1')
    expect(formatRate(0.5)).toBe('0.5')
    expect(formatRate(1.05)).toBe('1.05')
    expect(formatRate(1.3333)).toBe('1.33')
    expect(formatRate(9.999)).toBe('10')
    expect(formatRate(12.5)).toBe('12.5')
    expect(formatRate(12.0)).toBe('12')
    expect(formatRate(256)).toBe('256')
    expect(formatRate(333.36)).toBe('333.4')
    expect(formatRate(999.96)).toBe('1,000')
    expect(formatRate(1024)).toBe('1,024')
    expect(formatRate(15360)).toBe('15,360')
    expect(formatRate(1234567.6)).toBe('1,234,568')
  })
})

describe('selectBenchRates (what each card on the Nexus page shows)', () => {
  it("has exactly the benched creatures, each at the sim's own creatureEmissionPerMin, and none of the working ones", () => {
    const game = rosterGame(60) // 61 creatures, all rarities and traits, some working
    const rates = sel.selectBenchRates(view(game))
    const benched = game.creatures.filter((cr) => cr.assignment === null)
    expect(rates.size).toBe(benched.length)
    for (const cr of game.creatures) {
      if (cr.assignment === null) expect(rates.get(cr.id), cr.id).toBe(creatureEmissionPerMin(cr))
      else expect(rates.has(cr.id), `${cr.id} works a slot`).toBe(false)
    }
    // ...and it adds up to the strip's total, which is the sim's own number
    expect([...rates.values()].reduce((a, b) => a + b, 0)).toBeCloseTo(sel.selectAetherPerMinute(view(game)), 9)
  })

  it('is empty when nothing is benched, and follows a creature onto and off the bench', () => {
    const working = work(newGame(), 'creature-1', 'woodcutting', 0, 'oak-log')
    expect(sel.selectBenchRates(view(working)).size).toBe(0)
    expect(sel.selectBenchRates(view(newGame())).get('creature-1')).toBe(rate(1))
  })

  it('keeps its identity while the bench does, through ticks', () => {
    const game = benchOf(4, 7)
    const a = sel.selectBenchRates(view(game))
    expect(sel.selectBenchRates(view(game))).toBe(a)
    expect(sel.selectBenchRates(view(step(game, 100).state))).toBe(a)
    expect(sel.selectBenchRates(view(work(game, 'creature-2', 'woodcutting', 0, 'oak-log')))).not.toBe(a)
  })
})
