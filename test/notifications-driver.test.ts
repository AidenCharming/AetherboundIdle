import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { serializeSave } from '../src/sim/save'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import { selectNotifications, selectUnreadCount } from '../src/state/selectors'
import { createGameStore } from '../src/state/store'
import { FakeEnv, HOUR, NOW, sproutletAtWork, variant } from './helpers'

// Random sources off (as helpers' quietContent), and a slot unlock at level 2 so one level-up also unlocks a slot.
const c = variant((raw) => {
  for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0
  raw.traits.find((t: { id: string }) => t.id === 'overgrowth').effects[0].valueByStrength = { moderate: 0 }
  raw.skills.find((s: { id: string }) => s.id === 'woodcutting').slotUnlockLevels = [1, 2, 3, 4, 5]
})
const AWAY_MS = c.tuning.offline.awayThresholdMs
/** Level 1 to 2 takes 250 XP: 25 oak logs at 10 XP each, 3 s apiece. */
const FIRST_LEVEL_MS = 75_000

function setup() {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(c), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, c))
  const driver = createTickDriver(store, env, c)
  const actions = createActions(store, driver, env.storage, () => env.reload(), c)
  return { env, store, driver, actions }
}
const texts = (store: ReturnType<typeof setup>['store']) => selectNotifications(store.getState()).map((n) => n.text)

describe('the online tick records level-ups and slot unlocks', () => {
  it('one step across the first level-up gives "reached level 2" and the slot it opens', () => {
    const { env, store, driver } = setup()
    expect(texts(store)).toEqual([])
    env.clock += FIRST_LEVEL_MS + 1000 // under the away threshold: an ordinary step, not an away window
    expect(FIRST_LEVEL_MS + 1000).toBeLessThan(AWAY_MS)
    driver.stepToNow()
    expect(store.getState().game.skills.woodcutting!.level).toBe(2)
    expect(texts(store)).toEqual(['Woodcutting reached level 2', 'Woodcutting unlocked slot 2'])
    expect(selectUnreadCount(store.getState())).toBe(2)
    expect(selectNotifications(store.getState())[0]!.at).toBe(env.clock) // stamped by the injected clock
  })

  it('an ordinary tick with actions finishing and no level-up records nothing, and leaves the log untouched', () => {
    const { env, store, driver } = setup()
    const before = store.getState().notifications
    env.clock += 9000 // three actions
    driver.stepToNow()
    expect(store.getState().game.resources['oak-log']).toBe(3) // action-complete happened, three times
    expect(store.getState().notifications).toBe(before)
    expect(texts(store)).toEqual([])
  })

  it('a fast skill is coalesced end to end: a level on every tick is one entry, and a pause longer than the window starts a new one', () => {
    // Oak is made worth 300 XP an action, so every 3 s tick crosses at least one level, and slots open only at level 50 and up.
    const fast = variant((raw) => {
      for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0
      raw.traits.find((t: { id: string }) => t.id === 'overgrowth').effects[0].valueByStrength = { moderate: 0 }
      raw.resources.find((r: { id: string }) => r.id === 'oak-log').xpPerAction = 300
    })
    const env = new FakeEnv()
    flushSave(env.storage, sproutletAtWork(fast), NOW)
    const store = createGameStore(loadGame(env.storage, env.now(), env.seed, fast))
    const driver = createTickDriver(store, env, fast)
    const level = () => store.getState().game.skills.woodcutting!.level
    const lines = () => selectNotifications(store.getState()).map((n) => n.text)

    const levelsSeen: number[] = []
    for (let i = 0; i < 8; i++) {
      env.clock += 3000 // one action, over 250 XP: a level-up every tick
      driver.stepToNow()
      levelsSeen.push(level())
    }
    expect(new Set(levelsSeen).size, 'the skill really did level on (nearly) every tick').toBeGreaterThanOrEqual(6)
    expect(lines()).toEqual([`Woodcutting reached level ${level()}`]) // eight steps, many levels, one line

    env.clock += 3000 + fast.tuning.ui.toastMs // a pause longer than the window, then another level
    driver.stepToNow()
    expect(lines()).toHaveLength(2)
    expect(lines()[1]).toBe(`Woodcutting reached level ${level()}`)
  })

  it('markNotificationsRead zeroes the count and clearNotifications empties the list', () => {
    const { env, store, driver, actions } = setup()
    env.clock += FIRST_LEVEL_MS + 1000
    driver.stepToNow()
    expect(selectUnreadCount(store.getState())).toBe(2)
    actions.markNotificationsRead()
    expect(selectUnreadCount(store.getState())).toBe(0)
    expect(texts(store)).toHaveLength(2)
    actions.clearNotifications()
    expect(texts(store)).toEqual([])
  })
})

describe('offline events NEVER notify (the welcome-back dialog reports them; nothing is said twice)', () => {
  it('a load after a long time away: the summary has level-ups, the bell stays empty', () => {
    const storage = new FakeEnv().storage
    flushSave(storage, sproutletAtWork(c), NOW)
    const outcome = loadGame(storage, NOW + 4 * HOUR, 1, c)
    expect(outcome.events.some((e) => e.type === 'skill-level-up'), 'the away window did level the skill').toBe(true)
    expect(outcome.events.some((e) => e.type === 'slot-unlocked')).toBe(true)
    const store = createGameStore(outcome)
    expect(store.getState().welcomeBack).not.toBeNull() // reported once, here
    expect(store.getState().notifications.items).toEqual([])
  })

  it('a long gap on an open tab (over the away threshold): welcome-back appears, the bell stays empty', () => {
    const { env, store, driver } = setup()
    env.clock += AWAY_MS + 1
    driver.stepToNow()
    expect(store.getState().game.skills.woodcutting!.level).toBeGreaterThan(1)
    expect(store.getState().welcomeBack).not.toBeNull()
    expect(texts(store)).toEqual([])
    expect(selectUnreadCount(store.getState())).toBe(0)
  })

  it('the dev panel\'s fast-forward goes through the offline path, so it is silent too', () => {
    const { store, actions } = setup()
    actions.fastForwardHours(3)
    expect(store.getState().game.skills.woodcutting!.level).toBeGreaterThan(1)
    expect(store.getState().welcomeBack).not.toBeNull()
    expect(texts(store)).toEqual([])
  })

  it('but the online ticks after an away window still notify: the two paths are separate', () => {
    const { env, store, driver } = setup()
    env.clock += AWAY_MS + 1
    driver.stepToNow()
    const awayLevel = store.getState().game.skills.woodcutting!.level
    expect(awayLevel).toBeGreaterThan(1)
    expect(texts(store)).toEqual([]) // the away levels were reported by the dialog

    for (let i = 0; i < 200 && store.getState().game.skills.woodcutting!.level === awayLevel; i++) {
      env.clock += 3000 // ordinary steps, well under the away threshold
      driver.stepToNow()
    }
    const level = store.getState().game.skills.woodcutting!.level
    expect(level).toBeGreaterThan(awayLevel)
    expect(texts(store)).toContain(`Woodcutting reached level ${level}`)
    expect(texts(store).some((t) => t === `Woodcutting reached level ${awayLevel}`), 'the away level is not reported late').toBe(false)
  })
})

describe('nothing about notifications reaches the save', () => {
  it('the notification log is not in GameState, and the bytes saved are the same with or without notifications', () => {
    const { env, store, driver, actions } = setup()
    env.clock += FIRST_LEVEL_MS + 1000
    driver.stepToNow()
    expect(texts(store).length).toBeGreaterThan(0)
    expect(Object.keys(store.getState().game)).not.toContain('notifications')

    const withNotifications = serializeSave(store.getState().game)
    actions.clearNotifications()
    expect(serializeSave(store.getState().game)).toBe(withNotifications)

    driver.flush()
    const raw = env.storage.data.get(SAVE_KEY)!
    for (const needle of ['reached level', 'unlocked slot', 'notification', 'skill-level-up', 'slot-unlocked', 'toast']) {
      expect(raw.includes(needle), `the save file contains "${needle}"`).toBe(false)
    }
    expect(Object.keys(JSON.parse(raw).state)).not.toContain('notifications')
  })

  it('a reload starts the log empty, even though the save is right there', () => {
    const { env, store, driver } = setup()
    env.clock += FIRST_LEVEL_MS + 1000
    driver.stepToNow()
    driver.flush()
    expect(texts(store).length).toBeGreaterThan(0)
    const reloaded = createGameStore(loadGame(env.storage, env.now(), env.seed, c))
    expect(reloaded.getState().notifications.items).toEqual([])
    expect(content.tuning.ui.maxNotifications).toBeGreaterThan(0)
  })

  it('flushing and autosaving do not touch the log', () => {
    const { env, store, driver } = setup()
    env.clock += FIRST_LEVEL_MS + 1000
    driver.stepToNow()
    const log = store.getState().notifications
    driver.flush()
    env.clock += 1000
    driver.flush()
    expect(store.getState().notifications).toBe(log)
  })
})
