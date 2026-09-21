import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { addAether, addGold, addResource, deleteCreature, DEV_MAX_AMOUNT, grantCreature, setSkillLevel, type GrantSpec } from '../src/sim/dev'
import { levelForXp, xpForLevel } from '../src/sim/formulas'
import { integrityProblems, parseSave, serializeSave } from '../src/sim/save'
import { raiseSkillToLevel } from '../src/sim/skills'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { brokenSaveKey, flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { createGameStore } from '../src/state/store'
import { addCreature, assignmentProblems, FakeEnv, HOUR, NOW, newGame, sproutletAtWork, work } from './helpers'

const woodcutting = content.skillById.get('woodcutting')!
const spec = (over: Partial<GrantSpec> = {}): GrantSpec => ({ speciesId: 'sproutlet', rarityTier: 1, level: 1, form: 1, shiny: false, poolTraits: [], ...over })

// ---------- sim: resources, Aether, gold ----------

const BAD_AMOUNTS: [string, unknown][] = [
  ['empty text', ''],
  ['spaces', '   '],
  ['not a number', 'abc'],
  ['a unit', '12 logs'],
  ['thousands separator', '1,000'],
  ['NaN', NaN],
  ['Infinity', Infinity],
  ['-Infinity', -Infinity],
  ['overflowing text', '1e999'],
  ['negative', -5],
  ['negative text', '-5'],
  ['zero', 0],
  ['negative zero', -0],
  ['zero text', '0'],
  ['undefined', undefined],
  ['null', null],
  ['an object', {}],
  ['a boolean', true],
  ['over the limit', DEV_MAX_AMOUNT + 1],
  ['absurdly large', 1e30],
]

describe('addResource / addAether / addGold (sim)', () => {
  const base = newGame()

  it('adds to what is held, for any resource id the data lists', () => {
    for (const r of content.resources) {
      const a = addResource(base, r.id, 25)
      expect(a.ok, r.id).toBe(true)
      if (a.ok) expect(a.state.resources[r.id]).toBe(25)
    }
    const twice = addResource(base, 'oak-log', '40')
    if (!twice.ok) throw new Error(twice.reason)
    const again = addResource(twice.state, 'oak-log', ' 2 ')
    if (!again.ok) throw new Error(again.reason)
    expect(again.state.resources['oak-log']).toBe(42)
    expect(again.message).toBe('Added 2 Oak Log.')
    expect(base.resources).toEqual({}) // the input state is never mutated
  })

  it('accepts exactly the limit and no more', () => {
    expect(addResource(base, 'oak-log', DEV_MAX_AMOUNT).ok).toBe(true)
    expect(addGold(base, DEV_MAX_AMOUNT).ok).toBe(true)
    expect(addAether(base, DEV_MAX_AMOUNT).ok).toBe(true)
  })

  it('refuses an unknown resource', () => {
    const r = addResource(base, 'unobtainium', 5)
    expect(r).toEqual({ ok: false, reason: 'Unknown resource "unobtainium".' })
  })

  for (const [name, bad] of BAD_AMOUNTS) {
    it(`refuses ${name} with a reason, for all three, without throwing`, () => {
      for (const run of [() => addResource(base, 'oak-log', bad), () => addAether(base, bad), () => addGold(base, bad)]) {
        let r: ReturnType<typeof run> | undefined
        expect(() => (r = run())).not.toThrow()
        expect(r!.ok).toBe(false)
        if (!r!.ok) expect(r!.reason.length).toBeGreaterThan(0)
      }
    })
  }

  it('says why: the reasons name the problem', () => {
    const reason = (v: unknown) => {
      const r = addGold(base, v)
      return r.ok ? '' : r.reason
    }
    expect(reason('')).toMatch(/enter an amount/i)
    expect(reason('abc')).toMatch(/not a valid number/i)
    expect(reason(-1)).toMatch(/negative/i)
    expect(reason(0)).toMatch(/greater than zero/i)
    expect(reason(DEV_MAX_AMOUNT + 1)).toMatch(/at most 1,000,000,000,000/)
  })

  it('resources and gold are whole numbers; Aether may carry a fraction', () => {
    expect(addResource(base, 'oak-log', 1.5)).toMatchObject({ ok: false, reason: 'Amount must be a whole number.' })
    expect(addGold(base, '2.5')).toMatchObject({ ok: false, reason: 'Amount must be a whole number.' })
    const a = addAether(base, '2.5')
    if (!a.ok) throw new Error(a.reason)
    expect(a.state.aether).toBe(2.5)
    const b = addAether(a.state, 0.25)
    if (!b.ok) throw new Error(b.reason)
    expect(b.state.aether).toBe(2.75)
  })

  it('refuses a grant that would push the total past the largest safe number', () => {
    const rich = { ...base, gold: Number.MAX_SAFE_INTEGER - 5, resources: { 'oak-log': Number.MAX_SAFE_INTEGER - 5 }, aether: Number.MAX_SAFE_INTEGER - 5 }
    expect(addGold(rich, 10).ok).toBe(false)
    expect(addResource(rich, 'oak-log', 10).ok).toBe(false)
    expect(addAether(rich, 10).ok).toBe(false)
    expect(addGold(rich, 5).ok).toBe(true)
  })

  it('never touches the RNG or anything but the one thing it grants', () => {
    const r = addGold(base, 7)
    if (!r.ok) throw new Error(r.reason)
    expect(r.state).toEqual({ ...base, gold: 7 })
  })
})

// ---------- sim: grant creature ----------

describe('grantCreature (sim)', () => {
  const base = newGame()

  it('grants every species and hybrid at every rarity and form; each result is a valid, savable creature', () => {
    let state = base
    for (const def of content.creatureById.values()) {
      for (const tier of content.rarities.map((r) => r.tier)) {
        const form = ((tier - 1) % 3) + 1
        const r = grantCreature(state, spec({ speciesId: def.id, rarityTier: tier, form, level: 1 + tier }))
        if (!r.ok) throw new Error(`${def.id} tier ${tier}: ${r.reason}`)
        state = r.state
        const made = state.creatures[state.creatures.length - 1]!
        expect(made).toMatchObject({ speciesId: def.id, rarityTier: tier, form, level: 1 + tier, isHybrid: def.origin === 'breed', assignment: null, shiny: false })
      }
    }
    expect(state.creatures).toHaveLength(1 + content.creatureById.size * content.rarities.length)
    expect(integrityProblems(state)).toEqual([])
    const reloaded = parseSave(serializeSave(state))
    expect(reloaded.ok).toBe(true)
  })

  it('form is stored, not derived: any form at any level is allowed (plan 7.1)', () => {
    for (const [level, form] of [[1, 3], [99, 1], [1, 2], [45, 3], [30, 1]] as const) {
      const r = grantCreature(base, spec({ level, form }))
      if (!r.ok) throw new Error(r.reason)
      expect(r.state.creatures[1]).toMatchObject({ level, form })
      expect(integrityProblems(r.state)).toEqual([])
    }
  })

  it("takes the next id, advances the id source by one, and leaves the RNG state exactly as it was", () => {
    const start = { ...base, rngState: 987654321 }
    const a = grantCreature(start, spec())
    if (!a.ok) throw new Error(a.reason)
    const b = grantCreature(a.state, spec({ speciesId: 'sproutlet' }))
    if (!b.ok) throw new Error(b.reason)
    expect(b.state.creatures.map((cr) => cr.id)).toEqual(['creature-1', 'creature-2', 'creature-3'])
    expect(b.state.nextCreatureSeq).toBe(4)
    expect(a.state.rngState).toBe(987654321)
    expect(b.state.rngState).toBe(987654321)
    expect(start.creatures).toHaveLength(1) // not mutated
  })

  it('sets the creature XP to what its level takes, so level and XP agree', () => {
    for (const level of [1, 2, 30, 60, 99]) {
      const r = grantCreature(base, spec({ level }))
      if (!r.ok) throw new Error(r.reason)
      const xp = r.state.creatures[1]!.xp
      expect(xp).toBe(xpForLevel(content.tuning.xp.creatureCurve, level, content.tuning.creature.maxLevel))
      expect(levelForXp(content.tuning.xp.creatureCurve, xp, content.tuning.creature.maxLevel)).toBe(level)
    }
  })

  it('takes level as text too, and reports what it granted', () => {
    const r = grantCreature(base, spec({ speciesId: 'sproutlet', level: ' 12 ', rarityTier: 9, form: 2, shiny: true }))
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.creatures[1]).toMatchObject({ level: 12, shiny: true, rarityTier: 9, form: 2 })
    expect(r.message).toBe(`Granted ${content.creatureById.get('sproutlet')!.forms[1]!.name} (creature-2): Zenith, level 12, form 2, shiny.`)
  })

  it('refuses bad picks with a reason and never throws', () => {
    const bad: [string, GrantSpec][] = [
      ['unknown species', spec({ speciesId: 'nope' })],
      ['rarity 0', spec({ rarityTier: 0 })],
      ['rarity past the ladder', spec({ rarityTier: content.rarities.length + 1 })],
      ['fractional rarity', spec({ rarityTier: 1.5 })],
      ['empty level', spec({ level: '' })],
      ['level text', spec({ level: 'ten' })],
      ['level 0', spec({ level: 0 })],
      ['negative level', spec({ level: -3 })],
      ['fractional level', spec({ level: 4.5 })],
      ['level past the max', spec({ level: content.tuning.creature.maxLevel + 1 })],
      ['NaN level', spec({ level: NaN })],
      ['Infinity level', spec({ level: Infinity })],
      ['form 0', spec({ form: 0 })],
      ['form 4', spec({ form: 4 })],
      ['too many traits', spec({ poolTraits: content.traits.filter((t) => t.kind === 'pool' && t.minStrength === null).slice(0, content.tuning.creature.maxPoolTraits + 1).map((t) => ({ traitId: t.id, strength: 'minor' })) })],
    ]
    for (const [name, s] of bad) {
      let r: ReturnType<typeof grantCreature> | undefined
      expect(() => (r = grantCreature(base, s)), name).not.toThrow()
      expect(r!.ok, name).toBe(false)
    }
  })

  describe('pool traits', () => {
    const pools = content.traits.filter((t) => t.kind === 'pool')
    const free = pools.find((t) => t.minStrength === null)!
    const voidOnly = pools.find((t) => t.minStrength === 'moderate')!
    const pick = (traitId: string, strength: string) => ({ traitId, strength })

    it('grants up to the data-driven maximum, each at the picked strength, unlocked', () => {
      const max = content.tuning.creature.maxPoolTraits
      const picks = pools.slice(0, max).map((t, i) => pick(t.id, (['minor', 'moderate', 'major'] as const)[i % 3]!))
      const r = grantCreature(base, spec({ poolTraits: picks }))
      if (!r.ok) throw new Error(r.reason)
      expect(r.state.creatures[1]!.poolTraits).toEqual(picks.map((p) => ({ ...p, locked: false })))
      expect(integrityProblems(r.state)).toEqual([])
    })

    it('defaults to no traits', () => {
      const r = grantCreature(base, spec())
      if (!r.ok) throw new Error(r.reason)
      expect(r.state.creatures[1]!.poolTraits).toEqual([])
    })

    it('has a trait with a minimum strength to test against', () => {
      expect(voidOnly).toBeDefined()
    })

    it('respects minStrength: a trait that starts at moderate refuses minor and accepts moderate and major', () => {
      expect(grantCreature(base, spec({ poolTraits: [pick(voidOnly.id, 'minor')] }))).toMatchObject({ ok: false })
      expect(grantCreature(base, spec({ poolTraits: [pick(voidOnly.id, 'moderate')] })).ok).toBe(true)
      expect(grantCreature(base, spec({ poolTraits: [pick(voidOnly.id, 'major')] })).ok).toBe(true)
      expect(grantCreature(base, spec({ poolTraits: [pick(free.id, 'minor')] })).ok).toBe(true)
    })

    it('refuses the same trait twice, an unknown or signature trait, and an unknown strength', () => {
      expect(grantCreature(base, spec({ poolTraits: [pick(free.id, 'minor'), pick(free.id, 'major')] }))).toMatchObject({ ok: false })
      expect(grantCreature(base, spec({ poolTraits: [pick('not-a-trait', 'minor')] }))).toMatchObject({ ok: false })
      const signature = content.traits.find((t) => t.kind === 'signature')!
      expect(grantCreature(base, spec({ poolTraits: [pick(signature.id, 'minor')] }))).toMatchObject({ ok: false })
      expect(grantCreature(base, spec({ poolTraits: [pick(free.id, 'epic')] }))).toMatchObject({ ok: false })
    })
  })
})

// ---------- sim: set skill level ----------

describe('raiseSkillToLevel / setSkillLevel (sim)', () => {
  const base = newGame()
  const slots = (state: typeof base) => state.skills.woodcutting!.slots.length

  it('unlocks exactly the right slots at the tuned levels 50, 100, 165 and 225 (and not one level earlier)', () => {
    expect(woodcutting.slotUnlockLevels).toEqual([1, 50, 100, 165, 225]) // the numbers this test is about
    const expected: [number, number][] = [[49, 1], [50, 2], [99, 2], [100, 3], [164, 3], [165, 4], [224, 4], [225, 5], [250, 5]]
    for (const [level, count] of expected) {
      const r = raiseSkillToLevel(base, 'woodcutting', level)
      if (!r.ok) throw new Error(r.reason)
      expect(r.state.skills.woodcutting!.level, `level ${level}`).toBe(level)
      expect(slots(r.state), `slots at ${level}`).toBe(count)
    }
  })

  it('goes through the sim: the level cache matches the XP, the XP is the cumulative XP of that level, and slot events fire', () => {
    const r = raiseSkillToLevel(base, 'woodcutting', 225)
    if (!r.ok) throw new Error(r.reason)
    const sk = r.state.skills.woodcutting!
    expect(sk.xp).toBe(xpForLevel(content.tuning.xp.skillCurve, 225, woodcutting.maxLevel))
    expect(levelForXp(content.tuning.xp.skillCurve, sk.xp, woodcutting.maxLevel)).toBe(sk.level)
    expect(r.events.filter((e) => e.type === 'slot-unlocked').map((e) => (e as { slotIndex: number }).slotIndex)).toEqual([1, 2, 3, 4])
    expect(r.events.filter((e) => e.type === 'skill-level-up')).toHaveLength(224)
  })

  it('never lowers: a lower or equal level is refused and the skill is left exactly as it was', () => {
    const high = raiseSkillToLevel(base, 'woodcutting', 120)
    if (!high.ok) throw new Error(high.reason)
    for (const level of [1, 50, 100, 119, 120]) {
      const r = raiseSkillToLevel(high.state, 'woodcutting', level)
      expect(r.ok, `level ${level}`).toBe(false)
    }
    expect(high.state.skills.woodcutting!.level).toBe(120)
    expect(slots(high.state)).toBe(3)
    // Text goes through the same rule, and the reason says it only raises.
    const viaText = setSkillLevel(high.state, 'woodcutting', '50')
    expect(viaText).toMatchObject({ ok: false })
    if (!viaText.ok) expect(viaText.reason).toMatch(/only raises/)
  })

  it('a level the skill is already partway through refuses when the XP already covers it', () => {
    const r = raiseSkillToLevel({ ...base, skills: { ...base.skills, woodcutting: { level: 50, xp: xpForLevel(content.tuning.xp.skillCurve, 50, 250) + 100, slots: [null, null], reached: {} } } }, 'woodcutting', 50)
    expect(r.ok).toBe(false)
  })

  it('a fractional XP total (bonus_xp) lands exactly on the level threshold, never one short', () => {
    const curve = content.tuning.xp.skillCurve
    for (const target of [2, 15, 50, 99, 100, 165, 224, 225, 249, 250]) {
      const need = xpForLevel(curve, target, woodcutting.maxLevel)
      for (const frac of [0.1, 0.3, 0.5, 0.7, 0.9, 0.999999, 1e-9]) {
        for (const from of [need / 3, need / 2, need - 1, need - 0.5]) {
          const xp = Math.floor(from) + frac
          if (xp >= need) continue
          const lvl = levelForXp(curve, xp, woodcutting.maxLevel)
          const start = { ...base, skills: { ...base.skills, woodcutting: { level: lvl, xp, slots: base.skills.woodcutting!.slots, reached: {} } } }
          const r = raiseSkillToLevel(start, 'woodcutting', target)
          if (!r.ok) throw new Error(`${xp} -> ${target}: ${r.reason}`)
          expect(r.state.skills.woodcutting!.level, `${xp} -> ${target}`).toBe(target)
          expect(r.state.skills.woodcutting!.xp, `${xp} -> ${target}`).toBe(need)
        }
      }
    }
  })

  it('keeps whoever is working and their progress, and grows the slot array with empty slots', () => {
    const working = sproutletAtWork()
    const r = raiseSkillToLevel({ ...working, skills: { ...working.skills, woodcutting: { ...working.skills.woodcutting!, slots: [{ ...working.skills.woodcutting!.slots[0]!, progressMs: 1234 }] } } }, 'woodcutting', 100)
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.skills.woodcutting!.slots).toEqual([{ creatureId: 'creature-1', resourceId: 'oak-log', progressMs: 1234 }, null, null])
    expect(assignmentProblems(r.state)).toEqual([])
  })

  it('touches no other skill and no other part of the game', () => {
    const r = raiseSkillToLevel(base, 'woodcutting', 60)
    if (!r.ok) throw new Error(r.reason)
    expect({ ...r.state, skills: base.skills }).toEqual(base)
    expect(r.state.skills.mining).toBe(base.skills.mining)
  })

  it('works on every skill the data lists, up to each one\'s own max level', () => {
    for (const skill of content.skills) {
      const r = raiseSkillToLevel(base, skill.id, skill.maxLevel)
      if (!r.ok) throw new Error(`${skill.id}: ${r.reason}`)
      expect(r.state.skills[skill.id]!.level).toBe(skill.maxLevel)
      expect(r.state.skills[skill.id]!.slots).toHaveLength(skill.slotUnlockLevels.length)
      expect(raiseSkillToLevel(r.state, skill.id, skill.maxLevel).ok).toBe(false)
    }
  })

  it('refuses a level outside 1..max, a fractional one, an unknown skill, and bad text, without throwing', () => {
    const max = woodcutting.maxLevel
    for (const level of [0, -1, max + 1, 1e9, 2.5, NaN, Infinity]) expect(raiseSkillToLevel(base, 'woodcutting', level).ok, String(level)).toBe(false)
    expect(raiseSkillToLevel(base, 'nope', 5)).toMatchObject({ ok: false })
    for (const raw of ['', '  ', 'abc', '1e999', '-4', 'Infinity', undefined, null]) {
      let r: ReturnType<typeof setSkillLevel> | undefined
      expect(() => (r = setSkillLevel(base, 'woodcutting', raw)), String(raw)).not.toThrow()
      expect(r!.ok, String(raw)).toBe(false)
    }
    expect(setSkillLevel(base, 'nope', 5)).toMatchObject({ ok: false })
    const ok = setSkillLevel(base, 'woodcutting', ' 100 ')
    expect(ok).toMatchObject({ ok: true, message: 'Set Woodcutting to level 100.' })
  })
})

// ---------- state layer: the actions ----------

function wired(seedState = sproutletAtWork()) {
  const env = new FakeEnv()
  flushSave(env.storage, seedState, NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed))
  const driver = createTickDriver(store, env)
  driver.start()
  const actions = createActions(store, driver, env.storage, () => env.reload())
  const game = () => store.getState().game
  const saved = () => {
    const raw = env.storage.data.get(SAVE_KEY)
    if (raw === undefined) return null
    const r = parseSave(raw)
    if (!r.ok) throw new Error(r.message)
    return r.state
  }
  return { env, store, driver, actions, game, saved }
}

describe('dev actions change the state, save at once, and refuse bad input without touching anything', () => {
  it('grantCreature: adds the creature, saves it, and does not touch the RNG', () => {
    const { actions, game, saved } = wired()
    const rngBefore = game().rngState
    const r = actions.grantCreature(spec({ speciesId: 'sproutlet', rarityTier: 9, level: 40, form: 2, shiny: true, poolTraits: [{ traitId: content.traits.find((t) => t.kind === 'pool')!.id, strength: 'major' }] }))
    expect(r).toMatchObject({ ok: true })
    expect(game().creatures).toHaveLength(2)
    expect(game().creatures[1]).toMatchObject({ id: 'creature-2', rarityTier: 9, level: 40, form: 2, shiny: true, assignment: null })
    expect(game().nextCreatureSeq).toBe(3)
    expect(game().rngState).toBe(rngBefore)
    expect(saved()!.creatures).toHaveLength(2)
    expect(saved()!.creatures[1]).toEqual(game().creatures[1])
    expect(saved()!.rngState).toBe(rngBefore)
  })

  it('addResource / addAether / addGold: change the state and are in the saved file straight away', () => {
    const { actions, game, saved } = wired()
    const gold = game().gold
    expect(actions.addResource('yew-log', '250')).toMatchObject({ ok: true })
    expect(actions.addGold(1000)).toMatchObject({ ok: true })
    expect(actions.addAether('12.5')).toMatchObject({ ok: true })
    expect(game().resources['yew-log']).toBe(250)
    expect(game().gold).toBe(gold + 1000)
    expect(game().aether).toBeGreaterThanOrEqual(12.5)
    expect(saved()!.resources['yew-log']).toBe(250)
    expect(saved()!.gold).toBe(gold + 1000)
    expect(saved()!.aether).toBe(game().aether)
  })

  it('setSkillLevel: raises the level, opens the slots, saves, and refuses to lower', () => {
    const { actions, game, saved } = wired()
    expect(actions.setSkillLevel('woodcutting', '100')).toMatchObject({ ok: true, message: 'Set Woodcutting to level 100.' })
    expect(game().skills.woodcutting!.level).toBe(100)
    expect(game().skills.woodcutting!.slots).toHaveLength(3)
    expect(saved()!.skills.woodcutting!.level).toBe(100)
    expect(saved()!.skills.woodcutting!.slots).toHaveLength(3)

    const before = game()
    const r = actions.setSkillLevel('woodcutting', 60)
    expect(r).toMatchObject({ ok: false })
    expect(game().skills.woodcutting).toBe(before.skills.woodcutting) // untouched, same object
    expect(saved()!.skills.woodcutting!.level).toBe(100)
  })

  it('the action credits the time since the last tick before it changes anything (no time is lost or double counted)', () => {
    const { env, actions, game } = wired()
    env.clock += 30_000 // 30 s of oak with no tick yet: 10 actions
    expect(actions.addGold(1)).toMatchObject({ ok: true })
    expect(game().resources['oak-log']).toBeGreaterThanOrEqual(10)
  })

  it('every refusal leaves the store and the save exactly as they were', () => {
    const { env, actions, game, saved } = wired()
    const before = game()
    const writes = env.storage.writes
    const savedBefore = env.storage.data.get(SAVE_KEY)
    const attempts = [
      () => actions.grantCreature(spec({ level: '' })),
      () => actions.grantCreature(spec({ speciesId: 'nope' })),
      () => actions.grantCreature(spec({ form: 9 })),
      () => actions.addResource('oak-log', ''),
      () => actions.addResource('oak-log', -3),
      () => actions.addResource('oak-log', 'abc'),
      () => actions.addResource('nope', 3),
      () => actions.addGold(NaN),
      () => actions.addGold(Infinity),
      () => actions.addGold(1e30),
      () => actions.addAether(0),
      () => actions.addAether('-0.5'),
      () => actions.setSkillLevel('woodcutting', ''),
      () => actions.setSkillLevel('woodcutting', 0),
      () => actions.setSkillLevel('woodcutting', 251),
      () => actions.setSkillLevel('woodcutting', 1), // not a raise
      () => actions.setSkillLevel('nope', 5),
    ]
    for (const attempt of attempts) {
      let r: ReturnType<typeof attempt> | undefined
      expect(() => (r = attempt())).not.toThrow()
      expect(r!.ok).toBe(false)
      if (!r!.ok) expect(r!.reason.length).toBeGreaterThan(0)
    }
    expect(game()).toBe(before)
    expect(env.storage.writes).toBe(writes)
    expect(env.storage.data.get(SAVE_KEY)).toBe(savedBefore)
    expect(saved()).not.toBeNull()
  })

  it('a grant, an add and a set-level all survive a reload', () => {
    const { env, actions } = wired()
    actions.grantCreature(spec({ speciesId: 'sproutlet', rarityTier: 5, level: 20 }))
    actions.addGold(77)
    actions.setSkillLevel('woodcutting', 50)
    const reloaded = loadGame(env.storage, env.now(), 1)
    expect(reloaded.isNewGame).toBe(false)
    expect(reloaded.state.creatures).toHaveLength(2)
    expect(reloaded.state.gold).toBe(77)
    expect(reloaded.state.skills.woodcutting!.level).toBe(50)
  })

  it('a granted creature can be assigned and benched like any other, and bench emission counts it', () => {
    const { actions, game } = wired()
    actions.grantCreature(spec({ speciesId: 'sproutlet', rarityTier: 9 }))
    expect(actions.setSkillLevel('woodcutting', 50)).toMatchObject({ ok: true })
    expect(actions.assignCreature('creature-2', 'woodcutting', 1, 'oak-log')).toEqual({ ok: true })
    expect(assignmentProblems(game())).toEqual([])
    actions.unassignCreature('creature-2')
    expect(game().creatures[1]!.assignment).toBeNull()
  })
})

// ---------- delete creature (the trash can on a Nexus card in dev mode) ----------

describe('deleteCreature (sim)', () => {
  it('removes a benched creature and changes nothing else', () => {
    const base = addCreature(newGame(), 'emberfang').state
    const r = deleteCreature(base, 'creature-2')
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.creatures.map((cr) => cr.id)).toEqual(['creature-1'])
    expect(r.state).toEqual({ ...base, creatures: base.creatures.filter((cr) => cr.id !== 'creature-2') })
    expect(r.message).toBe('Deleted Emberfang (creature-2).')
    expect(base.creatures).toHaveLength(2) // the input state is never mutated
  })

  it('benches one that is at work first: its slot is emptied and the save stays valid', () => {
    const working = sproutletAtWork()
    expect(working.skills.woodcutting!.slots[0]).not.toBeNull()
    const r = deleteCreature(working, 'creature-1')
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.creatures).toEqual([])
    expect(r.state.skills.woodcutting!.slots[0]).toBeNull()
    expect(assignmentProblems(r.state)).toEqual([])
    expect(integrityProblems(r.state)).toEqual([])
    expect(parseSave(serializeSave(r.state)).ok).toBe(true)
  })

  it('leaves the other creatures, and their work, exactly as they were', () => {
    const raised = raiseSkillToLevel(sproutletAtWork(), 'woodcutting', 50)
    if (!raised.ok) throw new Error(raised.reason)
    const two = work(addCreature(raised.state, 'sproutlet').state, 'creature-2', 'woodcutting', 1, 'oak-log')
    expect(two.skills.woodcutting!.slots[1]).not.toBeNull()
    const r = deleteCreature(two, 'creature-2')
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.creatures).toEqual([two.creatures[0]])
    expect(r.state.skills.woodcutting!.slots[0]).toEqual(two.skills.woodcutting!.slots[0])
    expect(r.state.skills.woodcutting!.slots[1]).toBeNull()
    expect(assignmentProblems(r.state)).toEqual([])
  })

  it('does not reuse the id, and does not touch the RNG', () => {
    const base = addCreature(newGame(), 'emberfang').state
    const r = deleteCreature(base, 'creature-2')
    if (!r.ok) throw new Error(r.reason)
    expect(r.state.nextCreatureSeq).toBe(base.nextCreatureSeq)
    expect(r.state.rngState).toBe(base.rngState)
    const granted = grantCreature(r.state, spec())
    if (!granted.ok) throw new Error(granted.reason)
    expect(granted.state.creatures.map((cr) => cr.id)).toEqual(['creature-1', 'creature-3'])
  })

  it('refuses an id that does not exist, with a reason, and never throws', () => {
    const base = newGame()
    for (const id of ['creature-99', '', 'nobody']) {
      expect(deleteCreature(base, id), id).toEqual({ ok: false, reason: `Unknown creature "${id}".` })
    }
  })
})

describe('deleteCreature (action)', () => {
  it('removes the creature, saves at once, and the save no longer holds it', () => {
    const { actions, game, saved } = wired()
    actions.grantCreature(spec({ speciesId: 'emberfang' }))
    expect(game().creatures).toHaveLength(2)
    expect(actions.deleteCreature('creature-2')).toEqual({ ok: true, message: 'Deleted Emberfang (creature-2).' })
    expect(game().creatures.map((cr) => cr.id)).toEqual(['creature-1'])
    expect(saved()!.creatures.map((cr) => cr.id)).toEqual(['creature-1'])
    expect(saved()!.nextCreatureSeq).toBe(3)
  })

  it('a creature at work is benched and removed: the slot in the save is empty too', () => {
    const { actions, game, saved } = wired()
    expect(actions.deleteCreature('creature-1')).toMatchObject({ ok: true })
    expect(game().creatures).toEqual([])
    expect(game().skills.woodcutting!.slots[0]).toBeNull()
    expect(assignmentProblems(game())).toEqual([])
    expect(saved()!.skills.woodcutting!.slots[0]).toBeNull()
  })

  it('an unknown id is refused and leaves the store and the save exactly as they were', () => {
    const { actions, game, saved } = wired()
    const before = game()
    const savedBefore = JSON.stringify(saved())
    expect(actions.deleteCreature('creature-99')).toEqual({ ok: false, reason: 'Unknown creature "creature-99".' })
    expect(game()).toBe(before)
    expect(JSON.stringify(saved())).toBe(savedBefore)
  })

  it('the deletion survives a reload', () => {
    const { actions, env } = wired()
    actions.grantCreature(spec({ speciesId: 'emberfang' }))
    actions.deleteCreature('creature-1')
    const reloaded = loadGame(env.storage, env.now(), 1)
    expect(reloaded.isNewGame).toBe(false)
    expect(reloaded.state.creatures.map((cr) => cr.id)).toEqual(['creature-2'])
    expect(assignmentProblems(reloaded.state)).toEqual([])
  })
})

// ---------- reset save ----------

describe('reset save', () => {
  it('wipes the main save, reloads once, and a fresh load is a new game', () => {
    const { env, actions } = wired()
    actions.grantCreature(spec({ speciesId: 'sproutlet', rarityTier: 9 }))
    expect(env.storage.data.has(SAVE_KEY)).toBe(true)
    actions.resetSave()
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.reloads).toBe(1)
    const fresh = loadGame(env.storage, env.now() + 1000, 999)
    expect(fresh.isNewGame).toBe(true)
    expect(fresh.state.creatures).toHaveLength(1)
    expect(fresh.state.creatures[0]!.rarityTier).toBe(1)
    expect(fresh.state.rngState).toBe(999)
    expect(fresh.state.gold).toBe(0)
    expect(fresh.state.settings.devPanelEnabled).toBe(false)
  })

  it("THE TRAP: this tab's own pagehide / beforeunload flush, the autosave and a visibility change cannot rewrite the save after the wipe", () => {
    const { env, actions } = wired()
    actions.addGold(500)
    actions.resetSave()
    env.clock += 60_000
    env.win.dispatchEvent(new Event('pagehide'))
    env.win.dispatchEvent(new Event('beforeunload'))
    env.doc.dispatchEvent(new Event('visibilitychange'))
    env.fire(content.tuning.save.autosaveMs)
    env.fire(content.tuning.ui.tickMs)
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.intervals.size).toBe(0) // the timers are gone
    // ...and what a reload finds is a new game, not the one that was wiped.
    expect(loadGame(env.storage, env.clock, 5).isNewGame).toBe(true)
  })

  it('retires the driver BEFORE it wipes (the order is what makes it safe)', () => {
    const { env, driver, actions } = wired()
    const order: string[] = []
    const realRemove = env.storage.removeItem.bind(env.storage)
    env.storage.removeItem = (key: string) => {
      order.push(`remove:${key}:retired=${driver.retired}`)
      realRemove(key)
    }
    actions.resetSave()
    expect(order).toEqual([`remove:${SAVE_KEY}:retired=true`])
  })

  it('a flushing action after the reset (a click while the page is going away) does not write the old game back', () => {
    const { env, actions, driver } = wired()
    actions.resetSave()
    const writes = env.storage.writes
    actions.setSetting('devPanelEnabled', true)
    actions.addGold(10)
    actions.fastForwardHours(1)
    driver.flush()
    expect(env.storage.writes).toBe(writes)
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
  })

  it('commitRoll after the reset is not saved either', () => {
    const { env, actions, game } = wired()
    actions.resetSave()
    const out = actions.commitRoll((state) => ({ state: { ...state, gold: state.gold + 1 }, result: 'x' }))
    expect(out.saved).toBe(false)
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(game().gold).toBeGreaterThanOrEqual(1)
  })

  it('wipes only the main save key: the save-broken-* copies stay', () => {
    const { env, actions } = wired()
    const key = brokenSaveKey(12345)
    env.storage.setItem(key, '{ half a save')
    env.storage.setItem('aetherbound-idle:something-else', 'keep')
    actions.resetSave()
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.storage.data.get(key)).toBe('{ half a save')
    expect(env.storage.data.get('aetherbound-idle:something-else')).toBe('keep')
  })

  it('does not throw if the storage refuses the wipe, and still asks for the reload', () => {
    const { env, actions } = wired()
    env.storage.removeItem = () => {
      throw new Error('blocked')
    }
    expect(() => actions.resetSave()).not.toThrow()
    expect(env.reloads).toBe(1)
  })

  it('a save that was not reset keeps saving on pagehide (the guard is only for a reset)', () => {
    const { env, actions } = wired()
    actions.addGold(5)
    env.clock += HOUR
    const writes = env.storage.writes
    env.win.dispatchEvent(new Event('pagehide'))
    expect(env.storage.writes).toBe(writes + 1)
  })
})
