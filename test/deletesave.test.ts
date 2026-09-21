import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { brokenSaveKey, flushSave, loadGame, saveReplacedKey, SAVE_KEY } from '../src/state/persistence'
import { DELETE_CONFIRM_WORDS, isDeleteConfirmed } from '../src/state/selectors'
import { createGameStore } from '../src/state/store'
import { FakeEnv, HOUR, NOW, sproutletAtWork } from './helpers'

// Delete save (Settings, step 1.9d). The dialog is UI; what is testable in node is the rule that enables its OK button
// (`isDeleteConfirmed`) and what OK does (`actions.resetSave`, the Dev panel's reset, so the trap tests in dev.test.ts
// already cover its ordering; here the whole player flow is walked once: wrong text, then the right text, then a reload).

describe('isDeleteConfirmed', () => {
  it('accepts yes and accept, in any case, with spaces or other whitespace around them', () => {
    for (const text of ['yes', 'YES', 'Yes', 'yEs', 'accept', 'ACCEPT', 'Accept', ' Accept ', '  yes', 'yes  ', '\tyes\n', '  accept  ']) {
      expect(isDeleteConfirmed(text), JSON.stringify(text)).toBe(true)
    }
  })

  it('rejects everything else: a part of a word, more than a word, an empty box, no, and look-alikes', () => {
    for (const text of ['y', 'ye', 'yess', 'yes please', 'yes accept', 'accept yes', 'accepted', 'acept', 'ye s', 'y e s', 'yes.', 'yes!', 'no', 'NO', 'delete', 'ok', '', ' ', '\n', '0', 'true', 'yеs' /* the e is Cyrillic */, 'ｙｅｓ' /* full-width */]) {
      expect(isDeleteConfirmed(text), JSON.stringify(text)).toBe(false)
    }
  })

  it('is decided by the words the dialog names: its label is built from the same list', () => {
    expect([...DELETE_CONFIRM_WORDS]).toEqual(['yes', 'accept'])
    expect(`Type ${DELETE_CONFIRM_WORDS.join(' or ')} to confirm`).toBe('Type yes or accept to confirm')
    for (const word of DELETE_CONFIRM_WORDS) expect(isDeleteConfirmed(word)).toBe(true)
  })

  it('reads nothing but its argument', () => {
    expect(isDeleteConfirmed('yes')).toBe(isDeleteConfirmed('yes'))
    expect(isDeleteConfirmed('nope')).toBe(isDeleteConfirmed('nope'))
  })
})

/** What the dialog's OK button does: only when the typed text confirms, and only then is the game deleted. */
function pressOk(typed: string, actions: { resetSave(): void }): boolean {
  if (!isDeleteConfirmed(typed)) return false // OK is disabled, and Enter in the box does nothing
  actions.resetSave()
  return true
}

function wired() {
  const env = new FakeEnv()
  flushSave(env.storage, sproutletAtWork(), NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed))
  const driver = createTickDriver(store, env)
  driver.start()
  const actions = createActions(store, driver, env.storage, () => env.reload())
  return { env, store, driver, actions }
}

describe('Delete save, walked as the player does it', () => {
  it('a wrong text first: nothing is deleted, nothing reloads, the game keeps saving; then yes deletes it, and a reload is a new game', () => {
    const { env, actions } = wired()
    actions.addGold(123)
    const saved = env.storage.data.get(SAVE_KEY)!

    for (const wrong of ['', 'y', 'yes please', 'no', 'delete']) expect(pressOk(wrong, actions), wrong).toBe(false)
    expect(env.storage.data.get(SAVE_KEY)).toBe(saved)
    expect(env.reloads).toBe(0)
    env.clock += HOUR
    env.win.dispatchEvent(new Event('pagehide')) // the game still saves on the way out
    expect(env.storage.data.has(SAVE_KEY)).toBe(true)

    expect(pressOk('  Yes ', actions)).toBe(true)
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.reloads).toBe(1)

    // the reload: a new game, one Sproutlet, nothing carried over
    const fresh = loadGame(env.storage, env.clock + 1000, 777)
    expect(fresh.isNewGame).toBe(true)
    expect(fresh.state.gold).toBe(0)
    expect(fresh.state.creatures).toHaveLength(1)
    expect(fresh.state.creatures[0]!.assignment).toBeNull()
    expect(fresh.state.stats).toMatchObject({ onlineMs: 0, awayMs: 0, devMs: 0 })
    expect(fresh.state.skills.woodcutting!.reached).toEqual({ 1: [0, 0] })
  })

  it('stays deleted: this tab\'s own flushes, the autosave and a visibility change after OK cannot write the old game back', () => {
    const { env, actions, driver } = wired()
    actions.addGold(500)
    expect(pressOk('accept', actions)).toBe(true)
    env.clock += 60_000
    env.win.dispatchEvent(new Event('pagehide'))
    env.win.dispatchEvent(new Event('beforeunload'))
    env.doc.dispatchEvent(new Event('visibilitychange'))
    env.fire(content.tuning.save.autosaveMs)
    env.fire(content.tuning.ui.tickMs)
    driver.flush()
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.intervals.size).toBe(0)
    // ...and the page that comes up after the reload starts a new game and saves it under the same key, on its own
    const next = loadGame(env.storage, env.clock, 5)
    expect(next.isNewGame).toBe(true)
    flushSave(env.storage, next.state, env.clock)
    expect(loadGame(env.storage, env.clock + 1000, 6).isNewGame).toBe(false)
  })

  it('keeps the backup copies that imports and damaged saves left behind (the dialog says it will)', () => {
    const { env, actions } = wired()
    const broken = brokenSaveKey(1_000)
    const replaced = saveReplacedKey(2_000)
    env.storage.setItem(broken, '{ half a save')
    env.storage.setItem(replaced, env.storage.data.get(SAVE_KEY)!)
    expect(pressOk('YES', actions)).toBe(true)
    expect(env.storage.data.has(SAVE_KEY)).toBe(false)
    expect(env.storage.data.get(broken)).toBe('{ half a save')
    expect(env.storage.data.has(replaced)).toBe(true)
  })

  it('the export the dialog offers first is the save as it is right now, and does not delete anything', () => {
    const { env, actions } = wired()
    actions.addGold(42)
    const { fileName, text } = actions.exportSave()
    expect(fileName).toMatch(/\.json$/)
    expect(JSON.parse(text).state.gold).toBe(42)
    expect(env.storage.data.has(SAVE_KEY)).toBe(true)
    expect(env.reloads).toBe(0)
  })
})
