import { describe, expect, it, vi } from 'vitest'
import { content } from '../src/data'
import { step } from '../src/sim/tick'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { createGameStore } from '../src/state/store'
import { parseSave } from '../src/sim/save'
import { FakeEnv, HOUR, NOW, quietContent, sproutletAtWork, variant } from './helpers'

// quietContent switches off every random source, so a test can assert exact action counts.
const c = quietContent()
const OAK_MS = 3000 // the Sproutlet's cooldown on oak logs at level 1

/** A running game: a save holding the Sproutlet on oak, loaded at NOW, with the driver built but not started. */
function setup(content = c) {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(content), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, content))
  const step_ = vi.fn(step)
  const driver = createTickDriver(store, env, content, step_)
  return { env, store, driver, step: step_ }
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

  it('ignores a clock that reads NaN', () => {
    const { env, store, driver } = setup()
    const before = store.getState().game
    env.clock = NaN
    driver.stepToNow()
    expect(store.getState().game).toBe(before)
  })

  it('passes a huge dt straight to step in one call and matches the sim exactly', () => {
    const { env, store, driver, step } = setup()
    const initial = store.getState().game
    env.clock += 10 * HOUR // a tab that was throttled or asleep for ten hours
    driver.stepToNow()
    expect(step).toHaveBeenCalledTimes(1)
    expect(step.mock.calls[0]![1]).toBe(10 * HOUR)
    expect(store.getState().game).toEqual(step(initial, 10 * HOUR, {}, c).state)
    expect(oak(store)).toBe((10 * HOUR) / OAK_MS)
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
