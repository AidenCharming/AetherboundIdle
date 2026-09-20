import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { setSkillLevel as devSetSkillLevel } from '../src/sim/dev'
import { xpForLevel } from '../src/sim/formulas'
import { applyOffline } from '../src/sim/offline'
import { parseSave, serializeSave } from '../src/sim/save'
import { raiseSkillToLevel } from '../src/sim/skills'
import { step } from '../src/sim/tick'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame } from '../src/state/persistence'
import { selectSkillIdsWithXp, selectSkillMilestones } from '../src/state/selectors'
import { createGameStore } from '../src/state/store'
import type { GameState, LevelStamp } from '../src/types/state'
import { FakeEnv, HOUR, NOW, newGame, quietContent, sproutletAtWork } from './helpers'
import v1Fixture from './fixtures/save-v1.json?raw'

// When each skill level was reached (step 1.9c): `SkillState.reached` is a sparse map of level -> [playedMs, devMs],
// the play-time counters at that moment. It answers the question the designer could not answer after reaching
// Woodcutting 217 in five days with ten fast-forwards in it: how much of that was actually played.
//
// The rules under test:
//  - absent means UNKNOWN, never zero;
//  - an ordinary tick stamps the level at that tick;
//  - a level crossed inside ONE offline or fast-forward window is placed by interpolating over the window by XP,
//    so it lands inside the window, in order, and never after its end;
//  - the dev panel's "Set skill level" stamps nothing, because no time passed;
//  - the first stamp for a level wins.

const c = quietContent()
const woodcutting = content.skillById.get('woodcutting')!
const curve = content.tuning.xp.skillCurve
const OAK_MS = 3000

const reached = (s: GameState, skillId = 'woodcutting'): Record<string, LevelStamp> => s.skills[skillId]!.reached
const levels = (s: GameState, skillId = 'woodcutting'): number[] => Object.keys(reached(s, skillId)).map(Number).sort((a, b) => a - b)

/** A running game with the Sproutlet on oak, the driver built but not started. */
function setup() {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(c), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, c))
  const driver = createTickDriver(store, env, c)
  const actions = createActions(store, driver, env.storage, () => env.reload(), c)
  return { env, store, driver, actions, game: () => store.getState().game }
}

describe('a new game', () => {
  it('has level 1 at zero for every skill, and nothing else', () => {
    const s = newGame(c)
    for (const skill of content.skills) expect(s.skills[skill.id]!.reached, skill.id).toEqual({ 1: [0, 0] })
  })
})

describe('ordinary ticks stamp at the tick', () => {
  it('stamps the first level-up at the play time the counter says', () => {
    const { env, driver, game } = setup()
    // Oak is 10 XP per 3 s and level 2 costs the curve's first step, so this is the real first level-up.
    const need = xpForLevel(curve, 2, woodcutting.maxLevel)
    const actions = Math.ceil(need / 10)
    for (let i = 0; i < actions; i++) {
      env.clock += OAK_MS
      driver.stepToNow()
    }
    expect(game().skills.woodcutting!.level).toBe(2)
    expect(reached(game())[2]).toEqual([actions * OAK_MS, 0])
    expect(game().stats.onlineMs).toBe(actions * OAK_MS)
  })

  it('stamps within one tick of the true moment, and never later than the play time so far', () => {
    const { env, driver, game } = setup()
    for (let i = 0; i < 4000; i++) {
      env.clock += 100 // the real tick period
      driver.stepToNow()
    }
    const s = game()
    const played = s.stats.onlineMs + s.stats.awayMs
    expect(levels(s).length).toBeGreaterThan(1)
    for (const [level, stamp] of Object.entries(reached(s))) {
      expect(stamp[0], `level ${level}`).toBeLessThanOrEqual(played)
      expect(stamp[1], `level ${level}`).toBe(0)
    }
  })

  it('stamps every level crossed, in ascending order, and only once', () => {
    const { env, driver, game } = setup()
    env.clock += 2 * 60_000 // long enough for the first level-up (75 s of oak), still an ordinary tick
    driver.stepToNow()
    const at2 = reached(game())[2]
    expect(at2).toBeDefined()
    env.clock += 60_000
    driver.stepToNow()
    expect(reached(game())[2]).toEqual(at2) // the first stamp wins; a later tick does not move it
    const times = levels(game()).map((l) => reached(game())[l]![0])
    expect(times).toEqual([...times].sort((a, b) => a - b))
  })

  it('a tick that crosses no level adds no stamp', () => {
    const { env, driver, game } = setup()
    env.clock += 100
    driver.stepToNow()
    expect(reached(game())).toEqual({ 1: [0, 0] })
  })
})

describe('an offline window places its levels inside itself, by XP', () => {
  const eightHours = () => {
    const before = sproutletAtWork(c)
    const after = applyOffline(before, before.lastSeen + 8 * HOUR, c)
    return { before, state: after.state, granted: after.summary.elapsedMs }
  }

  it('stamps several levels, in order, between the start and the end of the window', () => {
    const { state, granted } = eightHours()
    const crossed = levels(state).filter((l) => l > 1)
    expect(crossed.length).toBeGreaterThan(5) // the case this test is about: one window, many levels
    let previous = 0
    for (const level of crossed) {
      const [playedMs, devMs] = reached(state)[level]!
      expect(playedMs, `level ${level} before the window started`).toBeGreaterThanOrEqual(0)
      expect(playedMs, `level ${level} after the window ended`).toBeLessThanOrEqual(granted)
      expect(playedMs, `level ${level} out of order`).toBeGreaterThanOrEqual(previous)
      expect(devMs, `level ${level} claims dev time`).toBe(0)
      previous = playedMs
    }
    expect(reached(state)[crossed[crossed.length - 1]!]![0]).toBeLessThanOrEqual(granted)
  })

  it('the last level is stamped at or before the end, and NOT all of them at the end', () => {
    const { state, granted } = eightHours()
    const crossed = levels(state).filter((l) => l > 1)
    const times = crossed.map((l) => reached(state)[l]![0])
    // The mutation this pins down: stamping every level at the window's end.
    expect(new Set(times).size).toBe(times.length)
    expect(Math.max(...times)).toBeLessThanOrEqual(granted)
    expect(Math.min(...times)).toBeLessThan(granted / 2)
  })

  it('places them where the XP says: the early levels take a small share of the window', () => {
    const { state, granted } = eightHours()
    // Level 2 costs 250 XP of the roughly 96,000 this window earns, so it lands in the first percent of it.
    expect(reached(state)[2]![0]).toBeLessThan(granted * 0.01)
  })

  it('a window that crosses no level adds no stamp', () => {
    const before = sproutletAtWork(c)
    const after = applyOffline(before, before.lastSeen + 2000, c)
    expect(reached(after.state)).toEqual({ 1: [0, 0] })
  })

  it('a second window starts where the counters are, not at zero', () => {
    const first = applyOffline(sproutletAtWork(c), NOW + 4 * HOUR, c)
    const second = applyOffline(first.state, NOW + 4 * HOUR + 4 * HOUR, c)
    const newInSecond = levels(second.state).filter((l) => reached(first.state)[l] === undefined)
    expect(newInSecond.length).toBeGreaterThan(0)
    for (const level of newInSecond) expect(reached(second.state)[level]![0], `level ${level}`).toBeGreaterThanOrEqual(4 * HOUR)
  })
})

describe('fast-forward is stamped as dev time, and the play time beside it does not move', () => {
  it('records the dev counter, and leaves real play time where it was', () => {
    const { env, driver, game } = setup()
    env.clock += 30_000
    driver.stepToNow()
    driver.fastForwardHours(6)
    const s = game()
    const afterFF = levels(s).filter((l) => reached(s)[l]![1] > 0)
    expect(afterFF.length).toBeGreaterThan(0)
    for (const level of afterFF) {
      const [playedMs, devMs] = reached(s)[level]!
      expect(playedMs, `level ${level}`).toBeLessThanOrEqual(30_000) // no real time passed during the fast-forward
      expect(devMs, `level ${level}`).toBeGreaterThan(0)
      expect(devMs, `level ${level}`).toBeLessThanOrEqual(6 * HOUR)
    }
  })

  it('a level reached before any fast-forward carries no dev time, so the table can tell them apart', () => {
    const { env, driver, game } = setup()
    for (let i = 0; i < 40; i++) {
      env.clock += OAK_MS
      driver.stepToNow()
    }
    expect(reached(game())[2]![1]).toBe(0)
    driver.fastForwardHours(6)
    expect(reached(game())[2]![1]).toBe(0) // unchanged: the stamp is when it was reached, not a running total
  })
})

describe('the dev panel’s "Set skill level" leaves the levels unknown', () => {
  it('stamps nothing, because no time passed', () => {
    const raised = raiseSkillToLevel(newGame(c), 'woodcutting', 100, c)
    if (!raised.ok) throw new Error(raised.reason)
    expect(raised.state.skills.woodcutting!.level).toBe(100)
    expect(raised.state.skills.woodcutting!.reached).toEqual({ 1: [0, 0] }) // only what the new game had
  })

  it('the same through the dev action, and the levels it skipped stay unknown afterwards', () => {
    const set = devSetSkillLevel(sproutletAtWork(c), 'woodcutting', 50, c)
    if (!set.ok) throw new Error(set.reason)
    expect(levels(set.state)).toEqual([1])
    // Playing on from there stamps only the levels actually earned: 2 to 50 stay unknown for ever.
    const played = step(set.state, HOUR, {}, c).state
    expect(played.skills.woodcutting!.level).toBeGreaterThan(50)
    expect(levels(played).filter((l) => l > 1 && l <= 50)).toEqual([])
    expect(levels(played).filter((l) => l > 50).length).toBeGreaterThan(0)
  })
})

describe('the first stamp wins, even when a retune takes the level back', () => {
  it('re-earning a level after a harder curve keeps the original time', () => {
    // A save that earned level 30, then a curve that makes its XP worth less: it re-earns 30 later.
    const env = new FakeEnv()
    const before = applyOffline(sproutletAtWork(c), NOW + 3 * HOUR, c).state
    const original = reached(before)[30]
    expect(original).toBeDefined()

    const harder = { ...before, skills: { ...before.skills, woodcutting: { ...before.skills.woodcutting!, level: 20 } } }
    const again = step(harder, HOUR, {}, c).state
    expect(again.skills.woodcutting!.level).toBeGreaterThanOrEqual(30)
    expect(reached(again)[30]).toEqual(original)
    expect(env.storage.data.size).toBe(0)
  })
})

describe('the save carries the stamps, and the migration invents none', () => {
  it('a v1 save gets an empty map for a skill that has XP, and level 1 for a skill that has none', () => {
    const r = parseSave(v1Fixture)
    if (!r.ok) throw new Error(r.message)
    const raw = JSON.parse(v1Fixture)
    expect(raw.state.skills.woodcutting.xp).toBeGreaterThan(0)
    expect(r.state.skills.woodcutting!.reached).toEqual({}) // the levels it already had are unknown, not invented
    for (const skill of content.skills) {
      if (skill.id === 'woodcutting') continue
      expect(r.state.skills[skill.id]!.reached, skill.id).toEqual({ 1: [0, 0] })
    }
  })

  it('a migrated save starts stamping from the next level it earns', () => {
    const migrated = parseSave(v1Fixture)
    if (!migrated.ok) throw new Error(migrated.message)
    const level = migrated.state.skills.woodcutting!.level
    const played = step(migrated.state, 6 * HOUR, {}, content).state
    expect(played.skills.woodcutting!.level).toBeGreaterThan(level)
    expect(levels(played).every((l) => l > level)).toBe(true)
  })

  it('export and import keep every stamp, byte for byte', () => {
    const { env, driver, actions, game } = setup()
    env.clock += 5 * 60_000
    driver.stepToNow()
    driver.fastForwardHours(2)
    const exported = actions.exportSave()
    const parsed = parseSave(exported.text, c)
    if (!parsed.ok) throw new Error(parsed.message)
    expect(parsed.state.skills.woodcutting!.reached).toEqual(game().skills.woodcutting!.reached)
    expect(serializeSave(parsed.state)).toBe(exported.text)
  })

  it('save and load keep them', () => {
    const { env, driver, game } = setup()
    env.clock += 4 * HOUR
    driver.stepToNow()
    driver.flush()
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.state.skills.woodcutting!.reached).toEqual(game().skills.woodcutting!.reached)
  })

  it('the schema refuses a bad map, and takes a good one', () => {
    const good = JSON.parse(serializeSave(applyOffline(sproutletAtWork(c), NOW + HOUR, c).state))
    const bad = (tamper: (state: any) => void) => {
      const file = structuredClone(good)
      tamper(file.state)
      const r = parseSave(JSON.stringify(file), c)
      return r.ok ? null : r.reason
    }
    expect(bad(() => {})).toBeNull()
    expect(bad((s) => delete s.skills.woodcutting.reached)).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { two: [0, 0] }))).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { 0: [0, 0] }))).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { 2: [-1, 0] }))).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { 2: [0] }))).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { 2: [0, 0, 0] }))).toBe('invalid')
    expect(bad((s) => (s.skills.woodcutting.reached = { 2: 5 }))).toBe('invalid')
  })
})

describe('every stamp agrees with the counters it came from', () => {
  it('after a mixed session, no level claims more time than the save says was played', () => {
    const { env, driver, game } = setup()
    for (let i = 0; i < 50; i++) {
      env.clock += 100
      driver.stepToNow()
    }
    env.clock += 5 * HOUR // a long gap: away
    driver.stepToNow()
    driver.fastForwardHours(3)
    env.clock += 20 * HOUR // longer than the cap
    driver.stepToNow()

    const s = game()
    const played = s.stats.onlineMs + s.stats.awayMs
    for (const skill of content.skills) {
      for (const [level, [playedMs, devMs]] of Object.entries(s.skills[skill.id]!.reached)) {
        expect(playedMs, `${skill.id} level ${level}`).toBeLessThanOrEqual(played)
        expect(devMs, `${skill.id} level ${level}`).toBeLessThanOrEqual(s.stats.devMs)
        expect(playedMs >= 0 && devMs >= 0, `${skill.id} level ${level}`).toBe(true)
      }
    }
  })
})

describe('the selectors the Settings table reads', () => {
  it('lists only the skills that have earned XP, in the data order', () => {
    const { env, driver, store } = setup()
    expect(selectSkillIdsWithXp(store.getState())).toEqual([])
    env.clock += 10 * OAK_MS
    driver.stepToNow()
    expect(selectSkillIdsWithXp(store.getState())).toEqual(['woodcutting'])
  })

  it('reports the slot unlock levels, the max level and the pacing milestones, sorted and distinct', () => {
    const { store } = setup()
    const rows = selectSkillMilestones(store.getState(), 'woodcutting')
    const shown = rows.map((r) => r.level)
    expect(shown).toEqual([...new Set([...woodcutting.slotUnlockLevels, ...content.tuning.ui.pacingMilestones, woodcutting.maxLevel])].sort((a, b) => a - b))
    expect(shown).toEqual([...shown].sort((a, b) => a - b))
    expect(rows.filter((r) => r.slot).map((r) => r.level)).toEqual([...woodcutting.slotUnlockLevels])
    expect(rows.filter((r) => r.max).map((r) => r.level)).toEqual([woodcutting.maxLevel])
  })

  it('says unknown (null) for a level that was never stamped, and a time for one that was', () => {
    const { env, driver, store } = setup()
    const before = selectSkillMilestones(store.getState(), 'woodcutting')
    expect(before.find((r) => r.level === 1)).toMatchObject({ playedMs: 0, devMs: 0 })
    expect(before.find((r) => r.level === 50)).toMatchObject({ playedMs: null, devMs: 0 })

    env.clock += 4 * HOUR
    driver.stepToNow()
    const after = selectSkillMilestones(store.getState(), 'woodcutting')
    const fifty = after.find((r) => r.level === 50)!
    expect(fifty.playedMs).not.toBeNull()
    expect(fifty.playedMs!).toBeLessThanOrEqual(4 * HOUR)
  })

  it('carries the dev time, so the table can say "+ dev"', () => {
    const { driver, store } = setup()
    driver.fastForwardHours(6)
    const rows = selectSkillMilestones(store.getState(), 'woodcutting')
    expect(rows.filter((r) => r.playedMs !== null && r.devMs > 0).length).toBeGreaterThan(0)
  })

  it('hands back the same array while nothing has changed, so the table does not re-render every tick', () => {
    const { env, driver, store } = setup()
    const first = selectSkillMilestones(store.getState(), 'woodcutting')
    env.clock += 100
    driver.stepToNow()
    expect(selectSkillMilestones(store.getState(), 'woodcutting')).toBe(first)
    env.clock += 4 * HOUR
    driver.stepToNow()
    expect(selectSkillMilestones(store.getState(), 'woodcutting')).not.toBe(first) // and a new one once a milestone lands
  })

  it('an unknown skill has no rows rather than throwing', () => {
    const { store } = setup()
    expect(selectSkillMilestones(store.getState(), 'telepathy')).toEqual([])
  })
})
