import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { makeCreature } from '../src/sim/creature'
import { dynamicEffectValue, modifier, type ActiveEntry } from '../src/sim/modifiers'
import { pool, variant } from './helpers'

const mk = (id: string, species: string, traits: ReturnType<typeof pool>[] = []) => makeCreature(id, species, { poolTraits: traits })
const active = (...entries: [ReturnType<typeof mk>, string][]): ActiveEntry[] => entries.map(([creature, skillId]) => ({ creature, skillId }))
const cooldownOf = (target: ReturnType<typeof mk>, skill: string | null, act: ActiveEntry[] = [], c = content) =>
  modifier('cooldown_reduction', target, skill, act, c)

describe('effect collection', () => {
  it("reads the signature trait at its fixed strength and pool traits at the creature's roll", () => {
    const c = mk('a', 'pebblescoot', [pool('swift-worker', 'major')])
    const r = cooldownOf(c, 'mining')
    expect(r.sources.map((s) => [s.traitId, s.value])).toEqual([['rhythmic-tunnels', 0.05], ['swift-worker', 0.2]])
    expect(r.total).toBeCloseTo(0.25)
    expect(r.capped).toBeCloseTo(0.25)
  })

  it('a creature with no relevant trait gets zero, and other mechanics are not mixed in', () => {
    const sprout = mk('a', 'sproutlet')
    expect(cooldownOf(sprout, 'woodcutting').total).toBe(0)
    expect(modifier('extra_output_chance', sprout, 'woodcutting', [], content).total).toBeCloseTo(0.1)
  })

  it('honours scope.skills: a Woodcutting/Herbalism trait does nothing elsewhere', () => {
    const c = mk('a', 'sproutlet', [pool('spreading-roots', 'moderate')])
    expect(cooldownOf(c, 'woodcutting').total).toBeCloseTo(0.1)
    expect(cooldownOf(c, 'herbalism').total).toBeCloseTo(0.1)
    expect(cooldownOf(c, 'scavenging').total).toBe(0)
    expect(cooldownOf(c, null).total).toBe(0)
  })

  it('a self effect only applies to its own creature', () => {
    const fast = mk('fast', 'sproutlet', [pool('swift-worker', 'major')])
    const other = mk('other', 'sproutlet')
    const act = active([fast, 'woodcutting'], [other, 'woodcutting'])
    expect(cooldownOf(other, 'woodcutting', act).total).toBe(0)
    expect(cooldownOf(fast, 'woodcutting', act).total).toBeCloseTo(0.2)
  })
})

describe('the shared cap (modifiers.json)', () => {
  it('clamps the sum of every cooldown_reduction source to the registry cap', () => {
    const c = mk('a', 'pebblescoot', [pool('swift-worker', 'major'), pool('swift-worker', 'major'), pool('swift-worker', 'major')])
    const r = cooldownOf(c, 'mining')
    expect(r.total).toBeCloseTo(0.05 + 0.6)
    expect(r.cap).toBe(0.5)
    expect(r.capped).toBe(0.5)
  })

  it('signature, pool and aura sources all draw on that one cap', () => {
    const geode = mk('g', 'geodecore') // aura 0.05 to other miners
    const miner = mk('m', 'pebblescoot', [pool('swift-worker', 'major'), pool('swift-worker', 'major'), pool('swift-worker', 'major')])
    const r = cooldownOf(miner, 'mining', active([geode, 'mining'], [miner, 'mining']))
    expect(r.total).toBeCloseTo(0.05 + 0.6 + 0.05)
    expect(r.capped).toBe(0.5)
  })

  it('reads the cap from data: lowering it in modifiers.json lowers the result, with no code change', () => {
    const tight = variant((raw) => {
      raw.modifiers.find((m: any) => m.key === 'cooldown_reduction').cap = 0.1
    })
    const c = makeCreature('a', 'sproutlet', { poolTraits: [pool('swift-worker', 'major')] }, tight)
    expect(modifier('cooldown_reduction', c, 'woodcutting', [], tight).capped).toBe(0.1)
  })

  it('every mechanic has its own cap: Geneticist-style 3% caps do not leak into other keys', () => {
    expect(content.modifierByKey.get('mutation_odds')!.cap).toBe(0.03)
    const c = mk('a', 'sproutlet', [pool('geneticist', 'major')])
    const r = modifier('mutation_odds', c, null, [], content)
    expect(r.total).toBeCloseTo(0.02)
    expect(r.capped).toBeLessThanOrEqual(0.03)
  })
})

describe('auras: strongest of each kind, never stacking', () => {
  it("Resonant Frequency reaches other active miners but not its own source, and not other skills", () => {
    const geode = mk('g', 'geodecore')
    const miner = mk('m', 'pebblescoot')
    const act = active([geode, 'mining'], [miner, 'mining'])
    expect(cooldownOf(miner, 'mining', act).sources.map((s) => s.traitId)).toContain('resonant-frequency')
    expect(cooldownOf(geode, 'mining', act).sources.map((s) => s.traitId)).not.toContain('resonant-frequency')
    // a Telluric creature working a different skill is not "another active miner"
    const scav = mk('s', 'tuskcub')
    expect(cooldownOf(scav, 'scavenging', active([geode, 'mining'], [scav, 'scavenging'])).total).toBe(0)
  })

  it('a benched miner is not in the aura, and a benched aura source projects nothing', () => {
    const geode = mk('g', 'geodecore')
    const miner = mk('m', 'tuskcub')
    expect(cooldownOf(miner, null, active([geode, 'mining'])).total).toBe(0)
    expect(cooldownOf(miner, 'mining', active([miner, 'mining'])).total).toBe(0)
  })

  it('two of the same aura do not stack', () => {
    const g1 = mk('g1', 'geodecore')
    const g2 = mk('g2', 'geodecore')
    const miner = mk('m', 'tuskcub')
    const act = active([g1, 'mining'], [g2, 'mining'], [miner, 'mining'])
    const r = cooldownOf(miner, 'mining', act)
    expect(r.sources).toHaveLength(2) // both are collected...
    expect(r.total).toBeCloseTo(0.05) // ...but only the strongest counts
    expect(cooldownOf(g1, 'mining', act).total).toBeCloseTo(0.05) // g1 gets g2's, not its own
  })

  it('picks the strongest when the sources differ', () => {
    const c = variant((raw) => {
      const t = raw.traits.find((x: any) => x.id === 'rhythmic-tunnels')
      t.effects[0] = {
        key: 'cooldown_reduction',
        scope: { target: 'other-active-in-skill', skills: ['mining'] },
        aura: { group: 'resonant-frequency', stacking: 'strongest-only' },
        valueByStrength: { minor: 0.12 },
      }
    })
    const weak = makeCreature('geode', 'geodecore', {}, c) // 0.05
    const strong = makeCreature('scoot', 'pebblescoot', {}, c) // 0.12
    const miner = makeCreature('m', 'tuskcub', {}, c)
    const act = active([weak, 'mining'], [strong, 'mining'], [miner, 'mining'])
    expect(modifier('cooldown_reduction', miner, 'mining', act, c).total).toBeCloseTo(0.12) // not 0.17
    expect(modifier('cooldown_reduction', weak, 'mining', act, c).total).toBeCloseTo(0.12)
    expect(modifier('cooldown_reduction', strong, 'mining', act, c).total).toBeCloseTo(0.05)
  })

  it('different aura kinds are independent: each kind contributes its own strongest, and the kinds add', () => {
    // Point Sea Breeze at Telluric creatures so one miner sits inside both auras.
    const c = variant((raw) => {
      raw.traits.find((t: any) => t.id === 'sea-breeze').effects[0].scope.types = ['telluric']
    })
    const geode = makeCreature('g', 'geodecore', {}, c) // Resonant Frequency 0.05, to other miners
    const froth = makeCreature('f', 'frothsprite', {}, c) // Sea Breeze 0.05, to active Telluric creatures
    const froth2 = makeCreature('f2', 'frothsprite', {}, c) // a second Sea Breeze: same kind, must not stack
    const miner = makeCreature('m', 'tuskcub', {}, c)
    const act = active([geode, 'mining'], [froth, 'fishing'], [froth2, 'fishing'], [miner, 'mining'])
    const r = modifier('cooldown_reduction', miner, 'mining', act, c)
    expect(r.sources.map((s) => s.aura).sort()).toEqual(['resonant-frequency', 'sea-breeze', 'sea-breeze'])
    expect(r.total).toBeCloseTo(0.1) // one of each kind, not 0.15
  })

  it('Sea Breeze reaches every active Aqueous creature including its source, and nobody else', () => {
    const froth = mk('f', 'frothsprite')
    const fish = mk('s', 'splashfin')
    const sprout = mk('p', 'sproutlet')
    const act = active([froth, 'fishing'], [fish, 'fishing'], [sprout, 'woodcutting'])
    expect(cooldownOf(froth, 'fishing', act).total).toBeCloseTo(0.05)
    expect(cooldownOf(fish, 'fishing', act).total).toBeCloseTo(0.05)
    expect(cooldownOf(sprout, 'woodcutting', act).total).toBe(0)
    // an Aqueous creature that is benched is not "active"
    expect(cooldownOf(fish, null, active([froth, 'fishing'])).total).toBe(0)
  })
})

describe('dynamic effects (Overclocked) are not modelled yet', () => {
  it('the hook contributes nothing, so Coilchirp gets no cooldown reduction from Overclocked', () => {
    const coil = mk('c', 'coilchirp')
    const effect = content.traitById.get('overclocked')!.effects[0]!
    expect(effect.dynamic).toBeDefined()
    expect(dynamicEffectValue(effect, coil)).toBe(0)
    const r = cooldownOf(coil, 'circuitry', active([coil, 'circuitry']))
    expect(r.total).toBe(0)
    expect(r.capped).toBe(0)
  })

  it('a dynamic effect does not disturb the other sources on the same creature', () => {
    const coil = mk('c', 'coilchirp', [pool('swift-worker', 'moderate')])
    expect(cooldownOf(coil, 'circuitry', active([coil, 'circuitry'])).total).toBeCloseTo(0.1)
  })
})

describe('party-scoped effects', () => {
  it('never apply to work: they are expedition-only', () => {
    const c = mk('a', 'sproutlet', [pool('captivating', 'major')])
    expect(modifier('bind_rate', c, 'woodcutting', active([c, 'woodcutting']), content).total).toBe(0)
  })
})
