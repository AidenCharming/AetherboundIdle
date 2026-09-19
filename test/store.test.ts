import { afterEach, describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { createRng } from '../src/sim/rng'
import { parseSave } from '../src/sim/save'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { bootGame, stopGame } from '../src/state/runtime'
import { selectQuarantineNotice } from '../src/state/selectors'
import { createGameStore } from '../src/state/store'
import { assignmentProblems, FakeEnv, HOUR, MemoryStorage, NOW, quietContent, sproutletAtWork } from './helpers'

afterEach(() => stopGame())

describe('the store boots from a LoadOutcome', () => {
  it('holds the loaded state, and the rest of the outcome under loadReport (not a second copy of the state)', () => {
    const storage = new MemoryStorage()
    flushSave(storage, sproutletAtWork(), NOW)
    const outcome = loadGame(storage, NOW + 2 * HOUR, 1)
    const store = createGameStore(outcome)

    expect(store.getState().game).toBe(outcome.state)
    expect(store.getState().loadReport.summary).toBe(outcome.summary)
    expect(store.getState().loadReport.summary!.elapsedMs).toBe(2 * HOUR) // step 1.8 renders this
    expect(store.getState().loadReport.events).toBe(outcome.events)
    expect(store.getState().loadReport.isNewGame).toBe(false)
    expect('state' in store.getState().loadReport).toBe(false)
    expect(store.getState().noticeDismissed).toBe(false)
  })

  it('keeps a new game apart: no summary, no notice', () => {
    const store = createGameStore(loadGame(new MemoryStorage(), NOW, 7))
    expect(store.getState().loadReport).toMatchObject({ isNewGame: true, summary: null, notice: null })
    expect(store.getState().game.creatures).toHaveLength(1)
  })

  it('carries a quarantine notice, and dismissing it hides the banner without dropping the notice', () => {
    const storage = new MemoryStorage()
    storage.setItem(SAVE_KEY, '{ this is not a save')
    const env = new FakeEnv()
    const store = createGameStore(loadGame(storage, NOW, 3))
    const actions = createActions(store, createTickDriver(store, env), storage)

    const notice = selectQuarantineNotice(store.getState())
    expect(notice).toMatchObject({ kind: 'quarantined', reason: 'corrupt' })
    expect(notice!.message.length).toBeGreaterThan(0)
    expect(store.getState().game.creatures).toHaveLength(1) // a fresh game started

    actions.dismissNotice()
    expect(selectQuarantineNotice(store.getState())).toBeNull()
    expect(store.getState().loadReport.notice).toBe(notice)
  })
})

describe('bootGame', () => {
  it('draws the seed once, writes the new game, and starts one driver', () => {
    const env = new FakeEnv()
    const runtime = bootGame(env)
    expect(env.seedDraws).toBe(1)
    expect(runtime.store.getState().game.rngState).toBe(env.seed) // the fresh game starts from that draw
    expect(parseSave(env.storage.data.get(SAVE_KEY)!).ok).toBe(true)
    expect(env.periods).toEqual([content.tuning.ui.tickMs, content.tuning.save.autosaveMs].sort((a, b) => a - b))
  })

  it('a second boot returns the same game and starts nothing (StrictMode and hot reload cannot double the tick)', () => {
    const env = new FakeEnv()
    const first = bootGame(env)
    const second = bootGame(env)
    expect(second).toBe(first)
    expect(env.seedDraws).toBe(1)
    expect(env.intervals.size).toBe(2)
  })

  it('stopGame stops the driver and allows a fresh boot', () => {
    const env = new FakeEnv()
    bootGame(env)
    stopGame()
    expect(env.intervals.size).toBe(0)
    expect(bootGame(env)).toBeDefined()
    expect(env.intervals.size).toBe(2)
  })

  it('loads an existing save and catches it up, keeping the summary for step 1.8', () => {
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(), NOW)
    env.clock = NOW + HOUR
    const { store } = bootGame(env)
    expect(store.getState().loadReport.summary!.elapsedMs).toBe(HOUR)
    expect(store.getState().game.resources['oak-log']).toBeGreaterThan(0)
    expect(store.getState().game.lastSeen).toBe(NOW + HOUR)
  })

  it('a save the game cannot read is quarantined and reported, not thrown', () => {
    const env = new FakeEnv()
    env.storage.setItem(SAVE_KEY, 'garbage')
    const { store } = bootGame(env)
    expect(selectQuarantineNotice(store.getState())).not.toBeNull()
  })

  it('starts fine when storage refuses everything', () => {
    const env = new FakeEnv()
    env.storage.failWrites = true
    env.storage.failReads = true
    expect(() => bootGame(env)).not.toThrow()
  })
})

// ---------- actions ----------

const c = quietContent()

function running() {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(c), NOW)
  const store = createGameStore(loadGame(env.storage, NOW, 1, c))
  const driver = createTickDriver(store, env, c)
  const actions = createActions(store, driver, env.storage)
  return { env, store, driver, actions, game: () => store.getState().game }
}

describe('actions', () => {
  it('assign and unassign go through the sim and keep creature and slot in agreement', () => {
    const { actions, game } = running()
    actions.unassignCreature('creature-1')
    expect(game().skills.woodcutting!.slots[0]).toBeNull()
    expect(game().creatures[0]!.assignment).toBeNull()

    expect(actions.assignCreature('creature-1', 'woodcutting', 0, 'oak-log')).toEqual({ ok: true })
    expect(game().skills.woodcutting!.slots[0]).toEqual({ creatureId: 'creature-1', resourceId: 'oak-log', progressMs: 0 })
    expect(assignmentProblems(game())).toEqual([])
  })

  it("returns the sim's own reason when a move is rejected, and changes nothing", () => {
    const { actions, game } = running()
    const before = game()
    expect(actions.assignCreature('creature-1', 'woodcutting', 0, 'willow-log')).toEqual({ ok: false, reason: 'Willow Log needs woodcutting level 15' })
    expect(actions.assignCreature('creature-1', 'woodcutting', 3, 'oak-log')).toEqual({ ok: false, reason: 'woodcutting slot 3 is locked' })
    expect(actions.assignCreature('creature-9', 'woodcutting', 0, 'oak-log')).toEqual({ ok: false, reason: 'unknown creature "creature-9"' })
    expect(actions.setSlotResource('woodcutting', 0, 'yew-log')).toEqual({ ok: false, reason: 'Yew Log needs woodcutting level 30' })
    expect(game()).toBe(before)
  })

  it('setSlotResource refuses an empty slot', () => {
    const { actions } = running()
    actions.unassignCreature('creature-1')
    expect(actions.setSlotResource('woodcutting', 0, 'oak-log')).toEqual({ ok: false, reason: 'woodcutting slot 0 is empty' })
  })

  it('steps to now before acting, so time already passed is credited to what was there', () => {
    const { env, actions, game } = running()
    env.clock += 30_000 // ten actions since the last tick
    actions.unassignCreature('creature-1')
    expect(game().resources['oak-log']).toBe(10)
    expect(game().creatures[0]!.assignment).toBeNull()
  })

  it('does not double-credit that time on the next tick', () => {
    const { env, driver, actions, game } = running()
    env.clock += 30_000
    actions.unassignCreature('creature-1')
    env.clock += 30_000 // nobody is working now
    driver.stepToNow()
    expect(game().resources['oak-log']).toBe(10)
  })
})

describe('actions.commitRoll (phase 2 plumbing)', () => {
  const roll = (state: ReturnType<typeof sproutletAtWork>) => {
    const rng = createRng(state.rngState)
    const result = rng.next()
    return { state: { ...state, rngState: rng.state }, result }
  }

  it('flushes the result and the advanced RNG state in one write, so a reload cannot replay the roll', () => {
    const { env, actions, game } = running()
    const before = game().rngState
    const writes = env.storage.writes
    const { result, saved } = actions.commitRoll(roll)

    expect(saved).toBe(true)
    expect(env.storage.writes).toBe(writes + 1)
    expect(game().rngState).not.toBe(before)

    const reloaded = loadGame(env.storage, env.clock, 999, c).state
    expect(reloaded.rngState).toBe(game().rngState)
    expect(createRng(reloaded.rngState).next()).not.toBe(result) // the stream continues; it does not replay
  })

  it('steps to now first, and reports a failed write instead of throwing', () => {
    const { env, actions, game } = running()
    env.storage.failWrites = true
    env.clock += 3 * 3000
    const { saved } = actions.commitRoll(roll)
    expect(saved).toBe(false)
    expect(game().resources['oak-log']).toBe(3)
    expect(game().lastSeen).toBe(env.clock)
  })
})
