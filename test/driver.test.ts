import { describe, expect, it, vi } from 'vitest'
import { content } from '../src/data'
import { applyOffline } from '../src/sim/offline'
import { step } from '../src/sim/tick'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { createGameStore } from '../src/state/store'
import { parseSave } from '../src/sim/save'
import { FakeEnv, HOUR, NOW, quietContent, sproutletAtWork, variant } from './helpers'

// quietContent switches off every random source, so a test can assert exact action counts.
const c = quietContent()
const OAK_MS = 3000 // the Sproutlet's cooldown on oak logs at level 1
const AWAY_MS = c.tuning.offline.awayThresholdMs // a gap longer than this is an away window, not a tick
const CAP_MS = c.tuning.offline.capHours * HOUR

/** A running game: a save holding the Sproutlet on oak, loaded at NOW, with the driver built but not started. */
function setup(content = c) {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(content), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, content))
  const step_ = vi.fn(step)
  const offline_ = vi.fn(applyOffline)
  const driver = createTickDriver(store, env, content, step_, offline_)
  return { env, store, driver, step: step_, offline: offline_ }
}

const oak = (store: ReturnType<typeof setup>['store']) => store.getState().game.resources['oak-log'] ?? 0
const saved = (env: FakeEnv) => {
  const r = parseSave(env.storage.data.get(SAVE_KEY)!, c)
  if (!r.ok) throw new Error(r.message)
  return r.state
}

describe('dt: real elapsed time, clamped, never looped', () => {
  it('steps by the time that actually passed, so a late tick loses nothing', () => {
    const { env, store, driver } = setup()
    env.clock += 4500 // a tick that fired 4.5 s late
    driver.stepToNow()
    expect(oak(store)).toBe(1)
    expect(store.getState().game.skills.woodcutting!.slots[0]!.progressMs).toBe(1500)
    env.clock += 1500
    driver.stepToNow()
    expect(oak(store)).toBe(2)
  })

  it('does nothing, and does not touch the store, when no time has passed', () => {
    const { store, driver, step } = setup()
    const before = store.getState().game
    driver.stepToNow()
    expect(step).not.toHaveBeenCalled()
    expect(store.getState().game).toBe(before)
  })

  it('clamps a negative dt to zero and re-anchors, so progress resumes rather than freezing', () => {
    const { env, store, driver, step } = setup()
    env.clock += 1000
    driver.stepToNow()
    const before = store.getState().game

    env.clock -= 60_000 // the system clock jumped back a minute
    driver.stepToNow()
    expect(store.getState().game).toBe(before) // no backwards step, no progress
    expect(store.getState().game.skills.woodcutting!.slots[0]!.progressMs).toBe(1000)

    // Measured from the new anchor: 2 s more brings 1 s of progress to 3 s, one action. A driver that kept the
    // old anchor would still see a negative dt here and stay frozen for a minute.
    env.clock += 2000
    driver.stepToNow()
    expect(oak(store)).toBe(1)
    expect(step.mock.calls.map(([, dt]) => dt)).toEqual([1000, 2000]) // step never saw a negative or zero dt
  })

  it('does not treat a backwards clock as an away window: nothing is granted and no summary appears', () => {
    const { env, store, driver, offline } = setup()
    env.clock -= 20 * HOUR // a clock correction, not twenty hours of play
    driver.stepToNow()
    expect(offline).not.toHaveBeenCalled()
    expect(oak(store)).toBe(0)
    expect(store.getState().welcomeBack).toBeNull()

    env.clock += OAK_MS // re-anchored, so ordinary time resumes at once
    driver.stepToNow()
    expect(oak(store)).toBe(1)
  })

  it('ignores a clock that reads NaN', () => {
    const { env, store, driver } = setup()
    const before = store.getState().game
    env.clock = NaN
    driver.stepToNow()
    expect(store.getState().game).toBe(before)
  })

  it('passes a large dt straight to step in one call and matches the sim exactly', () => {
    const { env, store, driver, step } = setup()
    const initial = store.getState().game
    const dt = AWAY_MS // the longest gap that is still an ordinary tick, not an away window
    env.clock += dt
    driver.stepToNow()
    expect(step).toHaveBeenCalledTimes(1)
    expect(step.mock.calls[0]![1]).toBe(dt)
    expect(store.getState().game).toEqual(step(initial, dt, {}, c).state)
    expect(oak(store)).toBe(dt / OAK_MS)
  })

  it('returns the now it stepped to', () => {
    const { env, driver } = setup()
    env.clock += 1234
    expect(driver.stepToNow()).toBe(NOW + 1234)
  })
})

describe('flush steps to now first (flushSave stamps lastSeen = now)', () => {
  it('saves the time since the last tick instead of forfeiting it', () => {
    const { env, store, driver } = setup()
    env.clock += HOUR // no tick ran for an hour
    driver.flush()

    const file = saved(env)
    expect(file.lastSeen).toBe(NOW + HOUR)
    expect(file.resources['oak-log']).toBe(HOUR / OAK_MS)
    expect(file.skills.woodcutting!.xp).toBe((HOUR / OAK_MS) * 10)
    expect(store.getState().game).toEqual(file)
  })

  it('leaves nothing for the next load to double-count or to lose', () => {
    const { env, store, driver } = setup()
    env.clock += HOUR
    driver.flush()
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.summary!.elapsedMs).toBe(0)
    expect(reloaded.state).toEqual(store.getState().game)
  })

  it('does the same on pagehide and beforeunload', () => {
    for (const type of ['pagehide', 'beforeunload']) {
      const { env, driver } = setup()
      driver.start()
      env.clock += 5 * OAK_MS
      env.win.dispatchEvent(new Event(type))
      expect(saved(env).resources['oak-log'], type).toBe(5)
      expect(saved(env).lastSeen, type).toBe(NOW + 5 * OAK_MS)
    }
  })

  it('does the same on the autosave timer', () => {
    const { env, driver } = setup()
    driver.start()
    env.clock += 2 * OAK_MS
    env.fire(content.tuning.save.autosaveMs)
    expect(saved(env).resources['oak-log']).toBe(2)
    expect(saved(env).lastSeen).toBe(NOW + 2 * OAK_MS)
  })

  it('still steps when the write fails, and does not throw', () => {
    const { env, store, driver } = setup()
    env.storage.failWrites = true
    env.clock += OAK_MS
    expect(() => driver.flush()).not.toThrow()
    expect(oak(store)).toBe(1)
  })
})

describe('start / stop', () => {
  it('runs the tick and the autosave at the periods in tuning.json, not hardcoded ones', () => {
    const custom = variant((raw) => {
      raw.tuning.ui.tickMs = 250
      raw.tuning.save.autosaveMs = 7000
      for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0
    })
    const { env, driver } = setup(custom)
    driver.start()
    expect(env.periods).toEqual([250, 7000])
  })

  it('the tick timer steps the sim', () => {
    const { env, store, driver } = setup()
    driver.start()
    env.clock += OAK_MS
    env.fire(content.tuning.ui.tickMs)
    expect(oak(store)).toBe(1)
  })

  it('starting twice registers one set of timers and one set of listeners', () => {
    const { env, driver } = setup()
    driver.start()
    driver.start()
    expect(env.intervals.size).toBe(2)
    const writes = env.storage.writes
    env.win.dispatchEvent(new Event('pagehide'))
    expect(env.storage.writes).toBe(writes + 1) // one flush, not two
  })

  it('steps to now when the tab becomes visible again, and only then', () => {
    const { env, store, driver } = setup()
    driver.start()
    env.visibility = 'hidden'
    env.clock += 3 * OAK_MS
    env.doc.dispatchEvent(new Event('visibilitychange'))
    expect(oak(store)).toBe(0)

    env.visibility = 'visible'
    env.doc.dispatchEvent(new Event('visibilitychange'))
    expect(oak(store)).toBe(3)
  })

  it('stop clears the timers and removes the listeners', () => {
    const { env, driver } = setup()
    driver.start()
    driver.stop()
    expect(env.intervals.size).toBe(0)
    const writes = env.storage.writes
    env.win.dispatchEvent(new Event('pagehide'))
    env.win.dispatchEvent(new Event('beforeunload'))
    expect(env.storage.writes).toBe(writes)
  })
})

// A tab left open across a long gap (a laptop asleep, a tab throttled for hours) is "away" exactly as a closed
// tab is: the same applyOffline, the same 12-hour cap, the same summary (designer, 2026-09-19).
describe('a gap longer than offline.awayThresholdMs goes through applyOffline, not step', () => {
  it('grants exactly the capped window for a 20-hour gap, and says it was capped', () => {
    const { env, store, driver, step, offline } = setup()
    const initial = store.getState().game
    env.clock += 20 * HOUR
    driver.stepToNow()

    expect(offline).toHaveBeenCalledTimes(1)
    expect(step).not.toHaveBeenCalled() // the driver never stepped the raw 20 h itself
    // Identical to the sim called directly for the same window: resources, XP, levels, Aether and the RNG state.
    expect(store.getState().game).toEqual(applyOffline(initial, NOW + 20 * HOUR, c).state)
    expect(oak(store)).toBe(CAP_MS / OAK_MS)
    expect(store.getState().welcomeBack).toMatchObject({ capped: true, elapsedMs: CAP_MS, requestedMs: 20 * HOUR })
  })

  it('an uncapped away window grants the whole gap', () => {
    const { env, store, driver } = setup()
    env.clock += 3 * HOUR
    driver.stepToNow()
    expect(oak(store)).toBe((3 * HOUR) / OAK_MS)
    expect(store.getState().welcomeBack).toMatchObject({ capped: false, elapsedMs: 3 * HOUR })
  })

  it('a gap at the threshold is still an ordinary tick, with no summary', () => {
    const { env, store, driver, step, offline } = setup()
    env.clock += AWAY_MS
    driver.stepToNow()
    expect(step).toHaveBeenCalledTimes(1)
    expect(offline).not.toHaveBeenCalled()
    expect(store.getState().welcomeBack).toBeNull()
  })

  it('measures the window from the own anchor of the driver, not the stale lastSeen of the save', () => {
    // THE TRAP. lastSeen is only stamped when the save is flushed (every 15 s), but the driver has already stepped
    // the sim past it. Measuring the away window from lastSeen would grant that already-spent time a second time.
    const { env, store, driver, offline } = setup()
    env.clock += 90_000 // 90 s of ordinary ticks, no flush, so the save still says lastSeen = NOW
    driver.stepToNow()
    const anchor = env.clock
    const before = store.getState().game
    expect(before.lastSeen).toBe(NOW) // stale by 90 s, on purpose
    expect(oak(store)).toBe(90_000 / OAK_MS)

    const gap = AWAY_MS + 7 * 60_000
    env.clock += gap
    driver.stepToNow()

    const expected = applyOffline({ ...before, lastSeen: anchor }, anchor + gap, c)
    expect(store.getState().game).toEqual(expected.state)
    expect(oak(store)).toBe((90_000 + gap) / OAK_MS) // not (90_000 * 2 + gap) / OAK_MS
    expect(offline.mock.calls[0]![0].lastSeen).toBe(anchor)
    expect(store.getState().welcomeBack!.elapsedMs).toBe(gap)
  })

  it('leaves lastSeen and the anchor at now, so the next tick and the next load start from zero', () => {
    const { env, store, driver } = setup()
    env.clock += 5 * HOUR
    driver.stepToNow()
    const at = NOW + 5 * HOUR
    expect(store.getState().game.lastSeen).toBe(at)

    const afterCatchUp = oak(store)
    driver.stepToNow() // same clock: the anchor moved with it, so nothing more is granted
    expect(oak(store)).toBe(afterCatchUp)

    env.clock += OAK_MS
    driver.stepToNow()
    expect(oak(store)).toBe(afterCatchUp + 1)
  })

  it('advances the RNG state as the sim does, and grants the rare drops of the window (real content)', () => {
    const { env, store, driver } = setup(content)
    const initial = store.getState().game
    env.clock += 4 * HOUR
    driver.stepToNow()
    const expected = applyOffline(initial, NOW + 4 * HOUR, content).state
    expect(store.getState().game.rngState).toBe(expected.rngState)
    expect(store.getState().game.rngState).not.toBe(initial.rngState)
    expect(store.getState().game.resources).toEqual(expected.resources)
  })

  it('a flush straight after a routed catch-up does not double-count on reload', () => {
    const { env, store, driver } = setup()
    env.clock += 6 * HOUR
    driver.stepToNow()
    driver.flush()

    const after = store.getState().game
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.summary!.elapsedMs).toBe(0)
    expect(reloaded.state).toEqual(after)
    expect(reloaded.state.resources['oak-log']).toBe((6 * HOUR) / OAK_MS)
  })

  it('routes the same way from the autosave timer and from becoming visible again', () => {
    for (const wake of ['autosave', 'visible'] as const) {
      const { env, store, driver, offline } = setup()
      driver.start()
      env.visibility = 'hidden'
      env.clock += 20 * HOUR
      if (wake === 'autosave') env.fire(c.tuning.save.autosaveMs)
      else {
        env.visibility = 'visible'
        env.doc.dispatchEvent(new Event('visibilitychange'))
      }
      expect(offline, wake).toHaveBeenCalledTimes(1)
      expect(oak(store), wake).toBe(CAP_MS / OAK_MS)
      driver.stop()
    }
  })
})

describe('the pending welcome-back summary', () => {
  it('is set at boot from the load, when the player was away long enough', () => {
    const storage = new FakeEnv().storage
    flushSave(storage, sproutletAtWork(c), NOW)
    const store = createGameStore(loadGame(storage, NOW + 8 * HOUR, 1, c))
    expect(store.getState().welcomeBack).toMatchObject({ elapsedMs: 8 * HOUR, capped: false })
  })

  it('is not set for a short absence, or for a new game', () => {
    const short = new FakeEnv().storage
    flushSave(short, sproutletAtWork(c), NOW)
    expect(createGameStore(loadGame(short, NOW + AWAY_MS, 1, c)).getState().welcomeBack).toBeNull()
    expect(createGameStore(loadGame(new FakeEnv().storage, NOW, 1, c)).getState().welcomeBack).toBeNull()
  })

  it('is not set when the player turned the summary off, but the catch-up still happens', () => {
    const storage = new FakeEnv().storage
    const game = sproutletAtWork(c)
    flushSave(storage, { ...game, settings: { ...game.settings, offlineSummary: false } }, NOW)
    const store = createGameStore(loadGame(storage, NOW + 8 * HOUR, 1, c))
    expect(store.getState().welcomeBack).toBeNull()
    expect(store.getState().game.resources['oak-log']).toBe((8 * HOUR) / OAK_MS)
  })

  it('combines with one already pending instead of dropping either', () => {
    const { env, store, driver } = setup()
    env.clock += 3 * HOUR
    driver.stepToNow()
    const first = store.getState().welcomeBack!
    env.clock += 20 * HOUR
    driver.stepToNow()

    const both = store.getState().welcomeBack!
    expect(both.requestedMs).toBe(23 * HOUR)
    expect(both.elapsedMs).toBe(3 * HOUR + CAP_MS)
    expect(both.capped).toBe(true) // the second window was
    expect(both.resourcesGained['oak-log']).toBe(first.resourcesGained['oak-log']! + CAP_MS / OAK_MS)
    const wc = both.skills.find((s) => s.skillId === 'woodcutting')!
    expect(wc.actions).toBe((3 * HOUR + CAP_MS) / OAK_MS)
    expect(wc.levelBefore).toBe(1)
    expect(wc.levelAfter).toBe(store.getState().game.skills.woodcutting!.level)
    expect(wc.slotsUnlocked).toEqual([...wc.slotsUnlocked].sort((a, b) => a - b))
    expect(new Set(wc.slotsUnlocked).size).toBe(wc.slotsUnlocked.length)
  })

  it('is cleared by the dismiss action', () => {
    const { env, store, driver } = setup()
    const actions = createActions(store, driver, env.storage)
    env.clock += 3 * HOUR
    driver.stepToNow()
    expect(store.getState().welcomeBack).not.toBeNull()
    actions.dismissWelcomeBack()
    expect(store.getState().welcomeBack).toBeNull()
  })
})

describe('fastForwardHours (the dev panel, plan 7.1)', () => {
  it('runs the real offline path, so the cap applies: 100 hours grants 12', () => {
    const { env, store, driver, offline } = setup()
    const initial = store.getState().game
    driver.fastForwardHours(100)
    expect(offline).toHaveBeenCalledTimes(1)
    expect(store.getState().game).toEqual(applyOffline({ ...initial, lastSeen: NOW - 100 * HOUR }, NOW, c).state)
    expect(oak(store)).toBe(CAP_MS / OAK_MS)
    expect(store.getState().welcomeBack).toMatchObject({ capped: true, elapsedMs: CAP_MS, requestedMs: 100 * HOUR })
    expect(env.clock).toBe(NOW) // it grants time, it does not move the clock
    expect(store.getState().game.lastSeen).toBe(NOW)
  })

  it('grants exactly one hour for one hour, matching the sim', () => {
    const { store, driver } = setup()
    const initial = store.getState().game
    driver.fastForwardHours(1)
    expect(oak(store)).toBe(HOUR / OAK_MS)
    expect(store.getState().game).toEqual(applyOffline({ ...initial, lastSeen: NOW - HOUR }, NOW, c).state)
  })

  it('credits the time since the last tick first, and does not count it twice', () => {
    const { env, store, driver } = setup()
    env.clock += 30_000 // half a minute of un-ticked time
    driver.fastForwardHours(1)
    expect(oak(store)).toBe((30_000 + HOUR) / OAK_MS)
  })

  it('leaves nothing for the next load to re-grant', () => {
    const { env, store, driver } = setup()
    driver.fastForwardHours(2)
    driver.flush()
    const reloaded = loadGame(env.storage, env.clock, env.seed, c)
    expect(reloaded.summary!.elapsedMs).toBe(0)
    expect(reloaded.state).toEqual(store.getState().game)
  })
})
