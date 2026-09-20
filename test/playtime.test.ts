import { describe, expect, it, vi } from 'vitest'
import { content } from '../src/data'
import { applyOffline } from '../src/sim/offline'
import { parseSave, serializeSave } from '../src/sim/save'
import { step } from '../src/sim/tick'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { selectAwayMs, selectDevMs, selectOnlineMs, selectPlayedMs } from '../src/state/selectors'
import { createGameStore } from '../src/state/store'
import { FakeEnv, HOUR, NOW, quietContent, sproutletAtWork } from './helpers'

// The play-time counters (step 1.9c). They exist because the dev panel's fast-forward makes game time and real time
// diverge: the designer reached Woodcutting 217 in five days of wall-clock time with ten 12-hour fast-forwards in it,
// and nothing in the save said so. `stats` splits that apart:
//   onlineMs  the dt ordinary ticks granted while the game was open
//   awayMs    the window applyOffline GRANTED for a closed-tab load or a long open-tab gap (capped, never requested)
//   devMs     the window the dev panel's fast-forward granted
//
// The one rule that makes them trustworthy: `stats` is written only by `creditPlayTime` in sim/tick.ts, from the very
// same `dt` that earned the progress. A window that earns nothing counts nothing, and no path can count twice.

const c = quietContent()
const OAK_MS = 3000
const CAP_MS = c.tuning.offline.capHours * HOUR
const AWAY_MS = c.tuning.offline.awayThresholdMs

const zero = { onlineMs: 0, awayMs: 0, devMs: 0 }

/** A running game: the Sproutlet on oak, saved at NOW, loaded, with the driver built but not started. */
function setup() {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(c), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, c))
  const driver = createTickDriver(store, env, c)
  const actions = createActions(store, driver, env.storage, () => env.reload(), c)
  return { env, store, driver, actions, stats: () => store.getState().game.stats }
}

describe('a new game starts at zero', () => {
  it('has all three counters at zero and nothing played', () => {
    const { store } = setup()
    const fresh = createGameStore(loadGame(new FakeEnv().storage, NOW, 1, c))
    expect(fresh.getState().game.stats).toEqual(zero)
    expect(selectPlayedMs(store.getState())).toBe(0)
  })
})

describe('ordinary ticks count as online time, exactly', () => {
  it('adds the dt the driver handed to step, tick by tick', () => {
    const { env, driver, stats } = setup()
    for (const dt of [100, 250, 3000, 17]) {
      env.clock += dt
      driver.stepToNow()
    }
    expect(stats()).toEqual({ onlineMs: 100 + 250 + 3000 + 17, awayMs: 0, devMs: 0 })
  })

  it('counts the same dt the sim used, so the counter and the progress cannot disagree', () => {
    const { env, store, driver } = setup()
    env.clock += 10 * OAK_MS
    driver.stepToNow()
    expect(store.getState().game.resources['oak-log']).toBe(10)
    expect(store.getState().game.stats.onlineMs).toBe(10 * OAK_MS)
  })

  it('a tick with an empty slot still counts: it is time the player spent in the game', () => {
    const { env, store, driver, stats } = setup()
    // Bench the creature, so nothing is earned at all.
    const game = store.getState().game
    store.setState({ game: { ...game, creatures: game.creatures.map((cr) => ({ ...cr, assignment: null })), skills: { ...game.skills, woodcutting: { ...game.skills.woodcutting!, slots: [null, ...game.skills.woodcutting!.slots.slice(1)] } } } })
    env.clock += 5000
    driver.stepToNow()
    expect(stats()).toEqual({ onlineMs: 5000, awayMs: 0, devMs: 0 })
  })

  it('a step with a zero dt changes nothing and does not replace the state object', () => {
    const { store } = setup()
    const before = store.getState().game
    expect(step(before, 0, {}, c).state).toBe(before)
  })
})

describe('away time is the window that was GRANTED, never the one that was requested', () => {
  it('a 20-hour gap on an open tab grants, and counts, exactly the 12-hour cap', () => {
    const { env, driver, stats } = setup()
    env.clock += 20 * HOUR
    driver.stepToNow()
    expect(stats()).toEqual({ onlineMs: 0, awayMs: CAP_MS, devMs: 0 })
    expect(stats().awayMs).not.toBe(20 * HOUR) // the mutation this pins down: counting `requestedMs`
  })

  it('a closed-tab load of 8 hours counts 8 hours', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(c), NOW)
    env.clock = NOW + 8 * HOUR
    const outcome = loadGame(env.storage, env.clock, env.seed, c)
    expect(outcome.state.stats).toEqual({ onlineMs: 0, awayMs: 8 * HOUR, devMs: 0 })
  })

  it('a closed-tab load longer than the cap counts the cap', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(c), NOW)
    const outcome = loadGame(env.storage, NOW + 100 * HOUR, env.seed, c)
    expect(outcome.state.stats.awayMs).toBe(CAP_MS)
  })

  it('a gap at the away threshold is still an ordinary tick, and counts as online', () => {
    const { env, driver, stats } = setup()
    env.clock += AWAY_MS
    driver.stepToNow()
    expect(stats()).toEqual({ onlineMs: AWAY_MS, awayMs: 0, devMs: 0 })
  })

  it('a zero-length window counts nothing', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(c), NOW)
    expect(loadGame(env.storage, NOW, env.seed, c).state.stats).toEqual(zero)
  })
})

describe('fast-forward is counted apart, and never as play time', () => {
  it('fastForwardHours(100) grants the 12-hour cap as dev time and leaves online and away alone', () => {
    const { driver, stats } = setup()
    driver.fastForwardHours(100)
    expect(stats()).toEqual({ onlineMs: 0, awayMs: 0, devMs: CAP_MS })
  })

  it('fastForwardHours(1) is exactly an hour of dev time', () => {
    const { driver, stats } = setup()
    driver.fastForwardHours(1)
    expect(stats()).toEqual({ onlineMs: 0, awayMs: 0, devMs: HOUR })
  })

  it('the un-ticked time before a fast-forward is online time, and the granted window is dev time', () => {
    const { env, driver, stats } = setup()
    env.clock += 30_000
    driver.fastForwardHours(1)
    expect(stats()).toEqual({ onlineMs: 30_000, awayMs: 0, devMs: HOUR })
    expect(stats().awayMs).toBe(0) // the mutation this pins down: counting dev time as away
  })

  it('ten 12-hour presses (the designer\'s run) read as five days of dev time and no play time', () => {
    const { store, driver, stats } = setup()
    for (let i = 0; i < 10; i++) driver.fastForwardHours(12)
    expect(stats()).toEqual({ onlineMs: 0, awayMs: 0, devMs: 10 * 12 * HOUR })
    expect(selectPlayedMs(store.getState())).toBe(0) // five days of game time, none of it played
  })

  it('the action saves it, so a reload still knows it was fast-forwarded', () => {
    const { env, actions, driver } = setup()
    actions.fastForwardHours(3)
    driver.flush()
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.state.stats.devMs).toBe(3 * HOUR)
  })
})

describe('bad clocks add nothing', () => {
  it('a backwards clock on an open tab counts no time at all', () => {
    const { env, driver, stats } = setup()
    env.clock -= 20 * HOUR
    driver.stepToNow()
    expect(stats()).toEqual(zero)
    env.clock += 4000 // and it resumes normally from the new anchor
    driver.stepToNow()
    expect(stats()).toEqual({ onlineMs: 4000, awayMs: 0, devMs: 0 })
  })

  it('a save written in the future grants and counts nothing', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(c), NOW + 5 * HOUR)
    const outcome = loadGame(env.storage, NOW, env.seed, c)
    expect(outcome.summary!.clockSkewed).toBe(true)
    expect(outcome.state.stats).toEqual(zero)
  })

  it('a NaN clock counts nothing', () => {
    const { env, driver, stats } = setup()
    env.clock = NaN
    driver.stepToNow()
    expect(stats()).toEqual(zero)
  })

  it('a negative or non-finite dt handed straight to the sim counts nothing', () => {
    const s = sproutletAtWork(c)
    for (const dt of [-1, -HOUR, NaN, Infinity, -Infinity, 0]) expect(step(s, dt, {}, c).state.stats, String(dt)).toEqual(zero)
  })
})

describe('a scripted session: online plus away is the real elapsed time', () => {
  it('adds up to the wall clock when nothing was capped', () => {
    const { env, driver, stats } = setup()
    const start = env.clock

    // 20 minutes of play, a 3-hour gap with the tab open, 10 more minutes, then the tab is closed for 2 hours.
    for (let i = 0; i < 20; i++) {
      env.clock += 60_000
      driver.stepToNow()
    }
    env.clock += 3 * HOUR
    driver.stepToNow()
    for (let i = 0; i < 10; i++) {
      env.clock += 60_000
      driver.stepToNow()
    }
    driver.flush()
    const closedAt = env.clock
    const reopened = loadGame(env.storage, closedAt + 2 * HOUR, env.seed, c)

    expect(reopened.state.stats.onlineMs).toBe(30 * 60_000)
    expect(reopened.state.stats.awayMs).toBe(3 * HOUR + 2 * HOUR)
    expect(reopened.state.stats.onlineMs + reopened.state.stats.awayMs).toBe(closedAt + 2 * HOUR - start)
    expect(reopened.state.stats.devMs).toBe(0)
    expect(stats().devMs).toBe(0)
  })

  it('a capped window is the only way the total falls short of the clock, and it falls short by exactly the excess', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(c), NOW)
    const away = 20 * HOUR
    const outcome = loadGame(env.storage, NOW + away, env.seed, c)
    expect(away - outcome.state.stats.awayMs).toBe(away - CAP_MS)
  })
})

describe('the counters survive every way a save travels', () => {
  const played = () => {
    const { env, driver, actions } = setup()
    env.clock += 90_000
    driver.stepToNow()
    driver.fastForwardHours(2)
    env.clock += 30 * HOUR // a long absence on an open tab: capped
    driver.stepToNow()
    driver.flush()
    return { env, actions, stats: JSON.parse(env.storage.data.get(SAVE_KEY)!).state.stats }
  }

  it('save and load keep every number', () => {
    const { env, stats } = played()
    expect(stats).toEqual({ onlineMs: 90_000, awayMs: CAP_MS, devMs: 2 * HOUR })
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.state.stats).toEqual(stats)
  })

  it('export and import keep every number', () => {
    const { actions, stats } = played()
    const exported = actions.exportSave()
    const parsed = parseSave(exported.text, c)
    if (!parsed.ok) throw new Error(parsed.message)
    expect(parsed.state.stats).toEqual(stats)
    expect(serializeSave(parsed.state)).toBe(exported.text) // byte for byte, no rounding on the way through
  })

  it('the schema refuses a save whose counters are missing, negative or not numbers', () => {
    const good = JSON.parse(serializeSave(sproutletAtWork(c)))
    const bad = (tamper: (state: any) => void) => {
      const file = structuredClone(good)
      tamper(file.state)
      const r = parseSave(JSON.stringify(file), c)
      return r.ok ? null : r.reason
    }
    expect(bad((s) => delete s.stats)).toBe('invalid')
    expect(bad((s) => (s.stats.onlineMs = -1))).toBe('invalid')
    expect(bad((s) => (s.stats.awayMs = 'lots'))).toBe('invalid')
    expect(bad((s) => (s.stats.extra = 1))).toBe('invalid')
    expect(bad(() => {})).toBeNull() // the untouched save is fine, so the cases above fail for their own reason
  })

  it('a reset starts a new game, so the counters start again at zero', () => {
    const { env, actions, driver } = setup()
    driver.fastForwardHours(5)
    driver.flush()
    actions.resetSave()
    expect(env.storage.data.get(SAVE_KEY)).toBeUndefined()
    expect(loadGame(env.storage, env.clock, env.seed, c).state.stats).toEqual(zero)
  })
})

describe('the selectors the Settings screen reads', () => {
  it('report each counter, and add only online and away into the total', () => {
    const { env, driver, store } = setup()
    env.clock += 4 * HOUR
    driver.stepToNow() // a 4-hour gap: away
    env.clock += 1000
    driver.stepToNow()
    driver.fastForwardHours(6)
    const s = store.getState()
    expect(selectOnlineMs(s)).toBe(1000)
    expect(selectAwayMs(s)).toBe(4 * HOUR)
    expect(selectDevMs(s)).toBe(6 * HOUR)
    expect(selectPlayedMs(s)).toBe(4 * HOUR + 1000)
  })
})

describe('the sim stays pure: no clock, one writer', () => {
  it('applyOffline credits the window it granted, through step, with no maths of its own', () => {
    const before = sproutletAtWork(c)
    const spy = vi.fn(step)
    const away = applyOffline(before, NOW + 100 * HOUR, c)
    const dev = applyOffline(before, NOW + 100 * HOUR, c, { dev: true })
    expect(away.state.stats).toEqual({ onlineMs: 0, awayMs: away.summary.elapsedMs, devMs: 0 })
    expect(dev.state.stats).toEqual({ onlineMs: 0, awayMs: 0, devMs: dev.summary.elapsedMs })
    expect(away.summary.elapsedMs).toBe(CAP_MS)
    expect(spy).not.toHaveBeenCalled()
  })

  it("'none' credits nothing, for a caller that counts the window itself", () => {
    const s = sproutletAtWork(c)
    expect(step(s, HOUR, { credit: 'none' }, c).state.stats).toEqual(zero)
    expect(step(s, HOUR, { credit: 'none' }, c).state.resources['oak-log']).toBe(HOUR / OAK_MS) // it still earns
  })

  it('every counter is a plain non-negative number the save can hold', () => {
    const { env, driver, stats } = setup()
    env.clock += 7 * HOUR
    driver.stepToNow()
    driver.fastForwardHours(1)
    env.clock += 1234.5 // a fractional dt, as a real frame gives
    driver.stepToNow()
    for (const [key, value] of Object.entries(stats())) {
      expect(Number.isFinite(value), key).toBe(true)
      expect(value >= 0, key).toBe(true)
    }
  })
})

describe('content is not involved: the counters are milliseconds, not balance', () => {
  it('the save version this needed is the one tuning.json ships', () => {
    expect(content.tuning.save.version).toBe(2)
  })
})
