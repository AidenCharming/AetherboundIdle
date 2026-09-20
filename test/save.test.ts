import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { createRng } from '../src/sim/rng'
import { integrityProblems, MIGRATIONS, parseSave, reconcile, serializeSave, type LoadResult } from '../src/sim/save'
import { step } from '../src/sim/tick'
import type { GameState } from '../src/types/state'
import { levelForXp } from '../src/sim/formulas'
import { slotCount } from '../src/sim/skills'
import { addCreature, HOUR, newGame, pool, setSkillLevel, sproutletAtWork, variant, work } from './helpers'
import v1Fixture from './fixtures/save-v1.json?raw'

/** A mid-game state with floats, pool traits, a working slot, a benched creature and a moved RNG. */
function midGame(): GameState {
  let s = addCreature(sproutletAtWork(), 'sproutlet', { rarityTier: 3, level: 12, xp: 400, poolTraits: [pool('glimmer', 'minor'), pool('swift-worker', 'major')] }).state
  s = step(s, 2 * HOUR + 1234.567).state
  return { ...s, gold: 17, resources: { ...s.resources, 'oak-log': s.resources['oak-log'] ?? 0 } }
}

/** The level the second work slot opens at, read from skills.json so a retune moves these tests with it. */
const SLOT2 = content.skillById.get('woodcutting')!.slotUnlockLevels[1]!

const ok = (r: LoadResult) => {
  if (!r.ok) throw new Error(`expected a good load, got ${r.reason}: ${r.message}`)
  return r
}
const failed = (r: LoadResult) => {
  if (r.ok) throw new Error('expected the load to fail')
  return r
}
/** Serialize, let `tamper` edit the parsed JSON, and re-stringify: a save that was damaged or hand-edited. */
const tampered = (state: GameState, tamper: (file: any) => void): string => {
  const file = JSON.parse(serializeSave(state))
  tamper(file)
  return JSON.stringify(file)
}

describe('round trip', () => {
  it('serialize -> parse gives back exactly the same state, floats included', () => {
    const s = midGame()
    expect(Number.isInteger(s.aether)).toBe(false) // the point: a fractional value survives
    const r = ok(parseSave(serializeSave(s)))
    expect(r.state).toEqual(s)
    expect(r.migratedFrom).toBeNull()
  })

  it('is written as { version, state }', () => {
    const file = JSON.parse(serializeSave(newGame()))
    expect(Object.keys(file)).toEqual(['version', 'state'])
    expect(file.version).toBe(content.tuning.save.version)
    expect(file.state.version).toBe(file.version)
  })

  it('holds IDs and progress only: no display names or balance numbers leak in', () => {
    const text = serializeSave(midGame())
    for (const banned of ['Sproutlet', 'Woodcutting', 'baseActionMs', 'statMultiplier', 'benchEmissionPerMin']) expect(text).not.toContain(banned)
    expect(text).toContain('"speciesId":"sproutlet"')
  })

  it('a fresh game, and a game where every skill has moved, both survive', () => {
    expect(ok(parseSave(serializeSave(newGame()))).state).toEqual(newGame())
    let s = newGame()
    for (const skill of content.skills) s = setSkillLevel(s, skill.id, 65)
    expect(ok(parseSave(serializeSave(s))).state).toEqual(s)
  })
})

describe('the RNG state in a save is the current one, not the seed (plan 4.6)', () => {
  it('advances with play, so a reload cannot replay the same numbers', () => {
    const seed = 424242
    const s0 = sproutletAtWork(content, seed)
    expect(s0.rngState).toBe(seed)
    const played = step(s0, 3000 * 5000, { offline: true }).state
    expect(played.rngState).not.toBe(seed)

    const reloaded = ok(parseSave(serializeSave(played))).state
    expect(reloaded.rngState).toBe(played.rngState) // the live state, not the initial seed
    expect(reloaded.rngState).not.toBe(seed)
  })

  it('a round trip through save.ts reproduces the same next value', () => {
    const played = step(sproutletAtWork(content, 99), 3000 * 4000).state
    const live = createRng(played.rngState)
    const reloaded = createRng(ok(parseSave(serializeSave(played))).state.rngState)
    for (let i = 0; i < 50; i++) expect(reloaded.next()).toBe(live.next())
  })

  it('save -> reload -> roll continues the stream instead of replaying it', () => {
    const s = sproutletAtWork(content, 7)
    const rng = createRng(s.rngState)
    const first = rng.next()
    const saved = serializeSave({ ...s, rngState: rng.state }) // saved after the first roll
    const second = createRng(ok(parseSave(saved)).state.rngState).next()
    expect(second).toBe(rng.next()) // continues
    expect(second).not.toBe(first) // does not replay
    // The mistake this prevents: persisting only the initial seed makes the reloaded stream start over.
    expect(createRng(s.rngState).next()).toBe(first)
  })
})

describe('migrations', () => {
  const SHIPPED = content.tuning.save.version

  it('ships the chain the current version needs, with no gaps', () => {
    expect(SHIPPED).toBe(2)
    for (let v = 1; v < SHIPPED; v++) expect(typeof MIGRATIONS[v], `migration ${v} -> ${v + 1}`).toBe('function')
    // A migration out of the current version would upgrade a save to a version this build cannot read.
    expect(MIGRATIONS[SHIPPED]).toBeUndefined()
  })

  it('chains several steps in order, each seeing the previous step\'s output', () => {
    const seen: number[] = []
    const migrations = {
      // Step one is the real 1 -> 2 migration with a gold change bolted on, so the chain produces a shape the schema still accepts.
      1: (s: any) => (seen.push(1), { ...MIGRATIONS[1]!(s), gold: 1 }),
      2: (s: any) => (seen.push(2), { ...s, gold: s.gold + 10 }),
      3: (s: any) => (seen.push(3), { ...s, gold: s.gold * 5 }),
    }
    const r = ok(parseSave(v1Fixture, content, { targetVersion: 4, migrations }))
    expect(seen).toEqual([1, 2, 3])
    expect(r.state.gold).toBe(55)
    expect(r.migratedFrom).toBe(1)
  })

  it('starts the chain at the file\'s own version, not at 1', () => {
    const v3 = tampered(newGame(), (file) => {
      file.version = 3
      file.state.version = 3
    })
    const seen: number[] = []
    ok(parseSave(v3, content, { targetVersion: 4, migrations: { 1: (s) => (seen.push(1), s), 2: (s) => (seen.push(2), s), 3: (s) => (seen.push(3), s) } }))
    expect(seen).toEqual([3])
  })

  it('fails cleanly when a step is missing or throws', () => {
    const missing = failed(parseSave(serializeSave(newGame()), content, { targetVersion: 4, migrations: { 2: (s) => s } }))
    expect(missing).toMatchObject({ reason: 'migration-failed' })
    expect(missing.message).toMatch(/no migration from version 3 to 4/)
    const boom = failed(parseSave(serializeSave(newGame()), content, { targetVersion: 3, migrations: { 2: () => { throw new Error('boom') } } }))
    expect(boom).toMatchObject({ reason: 'migration-failed' })
    expect(boom.message).toMatch(/boom/)
  })

  it('refuses a save from a newer build instead of mangling it', () => {
    // The case the designer has to live with after step 1.9c: the 0.1.0 exe reads a version-2 save exactly like this,
    // quarantines it and starts fresh. It does not delete it.
    const newer = tampered(newGame(), (file) => {
      file.version = SHIPPED + 1
    })
    expect(failed(parseSave(newer))).toMatchObject({ reason: 'too-new' })
  })

  it('a migration that returns a bad shape is caught by validation, not trusted', () => {
    const r = failed(parseSave(serializeSave(newGame()), content, { targetVersion: 3, migrations: { 2: (s) => ({ ...s, aether: 'lots' }) } }))
    expect(r.reason).toBe('invalid')
  })
})

describe('1 -> 2: the play-time counters (step 1.9c)', () => {
  // test/fixtures/save-v1.json is a real save written by this project's 0.1.0 build, before `stats` existed. It is
  // checked in so the migration keeps being tested against the format players actually have on disk, not against a
  // hand-built object that a later refactor would quietly keep in step with the code.
  const raw = JSON.parse(v1Fixture)

  it('the fixture really is a version-1 save, and really has no stats', () => {
    expect(raw.version).toBe(1)
    expect(raw.state.version).toBe(1)
    expect('stats' in raw.state).toBe(false)
  })

  it('migrates it, stamps version 2, and starts the counters at zero', () => {
    const r = ok(parseSave(v1Fixture))
    expect(r.migratedFrom).toBe(1)
    expect(r.state.version).toBe(2)
    // Zeros, not a guess. A v1 save never recorded how long it had been played and `lastSeen` is when it was last
    // written, not when it was started, so there is nothing to derive a history from. Inventing one would make the
    // counter a lie for every old save.
    expect(r.state.stats).toEqual({ onlineMs: 0, awayMs: 0, devMs: 0 })
  })

  it('changes nothing else: XP, creatures, resources and the RNG all survive', () => {
    const r = ok(parseSave(v1Fixture))
    const { stats, version, skills, ...rest } = r.state
    const { version: _oldVersion, skills: oldSkills, ...oldRest } = raw.state
    expect(rest).toEqual(oldRest)
    expect(skills.woodcutting!.xp).toBe(oldSkills.woodcutting.xp)
    expect(skills.woodcutting!.slots).toEqual(oldSkills.woodcutting.slots)
  })

  it('the migrated save re-saves as version 2 and is not migrated a second time', () => {
    const once = ok(parseSave(v1Fixture)).state
    const twice = ok(parseSave(serializeSave(once)))
    expect(twice.migratedFrom).toBeNull()
    expect(twice.state).toEqual(once)
  })

  it('a broken v1 save is still refused, not migrated into a valid-looking one', () => {
    const broken = JSON.stringify({ version: 1, state: { ...raw.state, aether: -1 } })
    expect(failed(parseSave(broken)).reason).toBe('invalid')
  })

  it('counts play time from the migration onwards, so an old save starts measuring now', () => {
    const migrated = ok(parseSave(v1Fixture)).state
    expect(step(migrated, 90_000).state.stats).toEqual({ onlineMs: 90_000, awayMs: 0, devMs: 0 })
  })
})

describe('bad saves are reported, never thrown', () => {
  const good = midGame()

  for (const [label, text] of [
    ['an empty string', ''],
    ['not JSON', '{oops'],
    ['a JSON array', '[1,2,3]'],
    ['null', 'null'],
    ['no state', JSON.stringify({ version: 1 })],
    ['no version', JSON.stringify({ state: {} })],
  ] as const) {
    it(`${label} is corrupt`, () => {
      expect(failed(parseSave(text)).reason).toBe('corrupt')
    })
  }

  it('a non-integer, zero or textual version is corrupt', () => {
    for (const v of [0, -1, 1.5, '1', null]) expect(failed(parseSave(tampered(good, (f) => { f.version = v }))).reason, String(v)).toBe('corrupt')
  })

  const invalid: [string, (file: any) => void][] = [
    ['a wrong type', (f) => { f.state.aether = 'lots' }],
    ['a NaN turned null by JSON', (f) => { f.state.aether = null }],
    ['negative Aether', (f) => { f.state.aether = -1 }],
    ['a fractional rngState', (f) => { f.state.rngState = 1.5 }],
    ['an rngState beyond uint32', (f) => { f.state.rngState = 2 ** 32 }],
    ['an unknown extra field', (f) => { f.state.cheatCode = true }],
    ['a missing field', (f) => { delete f.state.creatures }],
    ['a bad form', (f) => { f.state.creatures[0].form = 4 }],
    ['negative XP', (f) => { f.state.skills.woodcutting.xp = -5 }],
    ['negative slot progress', (f) => { f.state.skills.woodcutting.slots[0].progressMs = -1 }],
    ['an unknown strength', (f) => { f.state.creatures[1].poolTraits[0].strength = 'ultra' }],
    ['state.version disagreeing with the file', (f) => { f.state.version = 9 }],
    ['an unknown species', (f) => { f.state.creatures[0].speciesId = 'ghost' }],
    ['a rarity tier that does not exist', (f) => { f.state.creatures[0].rarityTier = 10 }],
    ['a level above the max', (f) => { f.state.creatures[0].level = 100 }],
    ['a pool trait that is not a pool trait', (f) => { f.state.creatures[1].poolTraits[0].traitId = 'overgrowth' }],
    ['a duplicate creature id', (f) => { f.state.creatures[1].id = f.state.creatures[0].id }],
    ['an unknown skill', (f) => { f.state.skills.telepathy = { level: 1, xp: 0, slots: [null] } }],
    ['a creature claiming a slot that holds someone else', (f) => { f.state.creatures[1].assignment = { skillId: 'woodcutting', slotIndex: 0 } }],
    ['a slot holding a creature that says it is benched', (f) => { f.state.creatures[0].assignment = null }],
    ['a slot holding a creature that does not exist', (f) => { f.state.skills.woodcutting.slots[0].creatureId = 'ghost' }],
  ]
  for (const [label, tamper] of invalid) {
    it(`${label} is invalid`, () => {
      const r = failed(parseSave(tampered(good, tamper)))
      expect(r.reason).toBe('invalid')
      expect(r.message.length).toBeGreaterThan(0)
    })
  }

  it('says what was wrong, so the notice can be specific', () => {
    expect(failed(parseSave(tampered(good, (f) => { f.state.creatures[0].speciesId = 'ghost' }))).message).toMatch(/unknown species "ghost"/)
  })

  it('the untouched save is fine, so the cases above are failing for their own reason', () => {
    expect(ok(parseSave(serializeSave(good))).state).toEqual(good)
    expect(integrityProblems(good)).toEqual([])
  })
})

describe('a save written before the 1.8t retune (old XP curve, old slot unlock levels)', () => {
  // The tuning this project shipped before step 1.8t, pinned here so these tests keep describing a real old
  // save whatever today's numbers are.
  const OLD = variant((raw) => {
    raw.tuning.xp.skillCurve = { base: 100, growth: 1.1 }
    for (const skill of raw.skills) {
      skill.slotUnlockLevels = [1, 20, 40, 65, 90]
      skill.maxLevel = 99
    }
  })
  const woodcutting = content.skillById.get('woodcutting')!

  /** An old-tuning game at `oldLevel` with `occupied` creatures cutting oak, serialized as that build wrote it. */
  function oldSave(oldLevel: number, occupied: number, resourceId = 'oak-log'): { text: string; state: GameState } {
    let s = setSkillLevel(newGame(OLD), 'woodcutting', oldLevel, OLD)
    for (let i = 1; i < occupied; i++) s = addCreature(s, 'sproutlet', {}, OLD).state
    for (let i = 0; i < occupied; i++) s = work(s, `creature-${i + 1}`, 'woodcutting', i, resourceId, OLD)
    return { text: serializeSave(s), state: s }
  }

  it('a high-XP skill with three occupied slots loads cleanly', () => {
    const { text } = oldSave(65, 3) // old level 65 had four slots open
    const r = parseSave(text)
    expect(r.ok).toBe(true)
    const loaded = ok(r).state
    expect(integrityProblems(loaded)).toEqual([])
    expect(loaded.skills.woodcutting!.slots.filter(Boolean)).toHaveLength(3)
  })

  it('no creature disappears, and none is silently benched', () => {
    const { text, state } = oldSave(65, 3)
    const loaded = ok(parseSave(text)).state
    expect(loaded.creatures.map((c) => c.id)).toEqual(state.creatures.map((c) => c.id))
    expect(loaded.creatures.map((c) => c.assignment)).toEqual(state.creatures.map((c) => c.assignment))
  })

  it('XP is untouched: the level is re-derived from it, never the other way round', () => {
    for (const oldLevel of [5, 20, 40, 65, 90, 99]) {
      const { text, state } = oldSave(oldLevel, 1)
      const loaded = ok(parseSave(text)).state
      expect(loaded.skills.woodcutting!.xp, `old level ${oldLevel}`).toBe(state.skills.woodcutting!.xp)
      expect(loaded.skills.woodcutting!.level).toBe(levelForXp(content.tuning.xp.skillCurve, state.skills.woodcutting!.xp, woodcutting.maxLevel))
    }
  })

  it('a second load changes nothing (reconcile is idempotent)', () => {
    const { text } = oldSave(65, 3)
    const once = ok(parseSave(text)).state
    expect(ok(parseSave(serializeSave(once))).state).toEqual(once)
    expect(reconcile(once)).toEqual(once)
  })

  it('keeps a slot the new level no longer earns, with its creature still working it', () => {
    // Old level 20 opened a second slot; its XP is worth less than that under the new curve.
    const { text } = oldSave(20, 2)
    const loaded = ok(parseSave(text)).state
    const sk = loaded.skills.woodcutting!
    expect(slotCount(woodcutting, sk.level)).toBeLessThan(sk.slots.length) // the case this test is about
    expect(sk.slots.filter(Boolean)).toHaveLength(2) // grandfathered: neither slot nor creature is taken away
    expect(integrityProblems(loaded)).toEqual([])

    // And the sim still runs the grandfathered slot rather than ignoring it.
    const { events } = step(loaded, 3000 * 10)
    const done = events.filter((e): e is Extract<typeof e, { type: 'action-complete' }> => e.type === 'action-complete')
    expect(done.map((e) => [e.slotIndex, e.count])).toEqual([
      [0, 10],
      [1, 10],
    ])
  })

  it('a slot whose tier the new level no longer unlocks idles, and is not emptied', () => {
    const willow = content.resourceById.get('willow-log')!
    const { text } = oldSave(15, 1, 'willow-log') // old level 15 opened willow
    const loaded = ok(parseSave(text)).state
    expect(loaded.skills.woodcutting!.level).toBeLessThan(willow.requiredSkillLevel!) // the case this test is about
    expect(loaded.skills.woodcutting!.slots[0]).toMatchObject({ creatureId: 'creature-1', resourceId: 'willow-log' })
    const worked = step(loaded, 3_600_000).state
    expect(worked.resources).toEqual({}) // idle, not throwing and not gathering
    expect(worked.creatures).toHaveLength(1)
  })
})

describe('content can change under an existing save (a save holds IDs, not copies)', () => {
  it('a skill added since the save is created at level 1 with its first slot', () => {
    const r = ok(parseSave(tampered(newGame(), (f) => { delete f.state.skills.mining })))
    expect(r.state.skills.mining).toEqual({ level: 1, xp: 0, slots: [null] })
  })

  it('a stale cached level is re-derived from XP, and slots grow to match', () => {
    // SLOT2 is the level the second work slot opens at, read from skills.json.
    const s = setSkillLevel(newGame(), 'woodcutting', SLOT2)
    const r = ok(parseSave(tampered(s, (f) => { f.state.skills.woodcutting.level = 1; f.state.skills.woodcutting.slots = [null] })))
    expect(r.state.skills.woodcutting.level).toBe(SLOT2)
    expect(r.state.skills.woodcutting.slots).toHaveLength(2)
  })

  it('a retuned XP curve re-levels the player from their XP, and never removes a slot', () => {
    const s = setSkillLevel(newGame(), 'woodcutting', SLOT2)
    const harder = variant((raw) => {
      raw.tuning.xp.skillCurve.growth *= 1.15
    })
    const r = ok(parseSave(serializeSave(s), harder))
    expect(r.state.skills.woodcutting.level).toBeLessThan(SLOT2)
    expect(r.state.skills.woodcutting.xp).toBe(s.skills.woodcutting!.xp) // progress is never taken away
    expect(r.state.skills.woodcutting.slots.length).toBeGreaterThanOrEqual(2)
  })

  it('a slot whose resource was removed by a rebalance loads fine; the sim just idles it', () => {
    const s = sproutletAtWork()
    const r = ok(parseSave(tampered(s, (f) => { f.state.skills.woodcutting.slots[0].resourceId = 'deleted-log' })))
    expect(r.state.skills.woodcutting.slots[0]!.resourceId).toBe('deleted-log')
  })

  it('reconcile never removes creatures or shrinks slots, and returns equal data for an up-to-date state', () => {
    const s = midGame()
    expect(reconcile(s)).toEqual(s)
  })
})
