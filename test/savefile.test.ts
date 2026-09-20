import { afterEach, describe, expect, it } from 'vitest'
import { content, type Content } from '../src/data'
import { applyOffline } from '../src/sim/offline'
import { MIGRATIONS, parseSave, serializeSave } from '../src/sim/save'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { brokenSaveKey, exportFileName, flushSave, loadGame, MAX_IMPORT_BYTES, SAVE_KEY, saveReplacedKey } from '../src/state/persistence'
import { createGameStore } from '../src/state/store'
import type { GameState } from '../src/types/state'
import { addCreature, FakeEnv, HOUR, NOW, newGame, quietContent, sproutletAtWork, variant } from './helpers'

// Save export and import (Settings, step 1.9). Import has no loader of its own: it validates, backs up, writes the file's
// text as the save, retires the driver and reloads, so the page boots through the same loadGame as any stored save.

interface Write {
  key: string
  value: string
}

function wired(seedState: GameState = sproutletAtWork(), c: Content = content) {
  const env = new FakeEnv()
  flushSave(env.storage, seedState, NOW)
  const store = createGameStore(loadGame(env.storage, env.now(), env.seed, c))
  const driver = createTickDriver(store, env, c)
  driver.start()
  const actions = createActions(store, driver, env.storage, () => env.reload(), c)
  // Every successful write, in order, so a test can see what was written and in what sequence.
  const writes: Write[] = []
  const realSet = env.storage.setItem.bind(env.storage)
  env.storage.setItem = (key: string, value: string) => {
    realSet(key, value)
    writes.push({ key, value })
  }
  const game = () => store.getState().game
  return { env, store, driver, actions, game, writes, c }
}

/** What the page finds when it boots after the import: the real loadGame, on whatever the storage now holds. */
function boot(env: FakeEnv, c: Content = content) {
  const outcome = loadGame(env.storage, env.now(), env.seed, c)
  return { outcome, store: createGameStore(outcome) }
}

/** A different game from the default one, as a save file. */
function otherGameFile(lastSeen = NOW, c: Content = content): { text: string; state: GameState } {
  const two = addCreature({ ...sproutletAtWork(c), gold: 777, aether: 12_345 }, 'sproutlet', {}, c).state
  const state = { ...two, lastSeen }
  return { text: serializeSave(state), state }
}

const keys = (env: FakeEnv) => [...env.storage.data.keys()].sort()

afterEach(() => {
  delete MIGRATIONS[1]
})

// ---------- export ----------

describe('export', () => {
  it('returns exactly the text the game saved, after stepping to now (nothing since the last tick is lost)', () => {
    const { env, actions, game } = wired()
    env.clock += 60_000 // a minute of work that no tick has seen
    const out = actions.exportSave()
    expect(out.text).toBe(env.storage.data.get(SAVE_KEY))
    expect(out.text).toBe(serializeSave(game()))
    const parsed = parseSave(out.text)
    if (!parsed.ok) throw new Error(parsed.message)
    expect(parsed.state.lastSeen).toBe(env.clock)
    expect(parsed.state.skills.woodcutting!.xp).toBeGreaterThan(0) // the minute was stepped in before it was written
  })

  it('is a real save: it parses with the strict schema, keeps the RNG state, and its file name carries the game and the time', () => {
    const { env, actions, game } = wired()
    const out = actions.exportSave()
    const parsed = parseSave(out.text)
    if (!parsed.ok) throw new Error(parsed.message)
    expect(parsed.state).toEqual(game())
    expect(parsed.state.rngState).toBe(game().rngState)
    expect(out.fileName).toBe(exportFileName(env.clock))
    expect(out.fileName).toMatch(/^aetherbound-idle-save-\d{4}-\d{2}-\d{2}-\d{6}\.json$/)
  })

  it('names the file after the local time', () => {
    expect(exportFileName(new Date(2026, 8, 20, 10, 14, 11).getTime())).toBe('aetherbound-idle-save-2026-09-20-101411.json')
    expect(exportFileName(new Date(2027, 0, 5, 0, 0, 0).getTime())).toBe('aetherbound-idle-save-2027-01-05-000000.json')
  })

  it('still exports when the storage refuses the write (the file comes from memory)', () => {
    const { env, actions, game } = wired()
    env.storage.failWrites = true
    env.clock += 1000
    const out = actions.exportSave()
    expect(out.text).toBe(serializeSave(game()))
  })

  it('does not change what the game does: it is a save, like every other', () => {
    const { env, actions, driver } = wired()
    actions.exportSave()
    expect(driver.retired).toBe(false)
    expect(env.reloads).toBe(0)
    expect(env.intervals.size).toBe(2)
  })
})

// ---------- import: refused files ----------

describe('import of a file that cannot be loaded', () => {
  const good = serializeSave(newGame())
  const parsedGood = JSON.parse(good) as { version: number; state: Record<string, unknown> }
  const target = content.tuning.save.version

  const BAD: [string, string, RegExp][] = [
    ['empty', '', /not a readable/],
    ['not JSON', 'this is not a save', /not a readable/],
    ['truncated', good.slice(0, good.length >> 1), /not a readable/],
    ['no version', JSON.stringify({ state: parsedGood.state }), /not a readable/],
    ['a bad version', JSON.stringify({ version: 'one', state: parsedGood.state }), /not a readable/],
    ['no state', JSON.stringify({ version: 1 }), /not a readable/],
    ['an array', '[]', /not a readable/],
    ['a schema violation', JSON.stringify({ version: target, state: { ...parsedGood.state, gold: -5 } }), /not a valid.*gold/],
    ['an unknown field', JSON.stringify({ version: target, state: { ...parsedGood.state, cheat: true } }), /not a valid/],
    [
      'an unknown species',
      JSON.stringify({ version: target, state: { ...parsedGood.state, creatures: [{ ...(parsedGood.state.creatures as object[])[0], speciesId: 'no-such-thing' }] } }),
      /not a valid.*no-such-thing/,
    ],
    ['newer than this build', JSON.stringify({ version: target + 1, state: parsedGood.state }), /newer version of the game.*version 2 but this build only understands up to 1/],
    ['too large', ' '.repeat(MAX_IMPORT_BYTES + 1), /too large/],
  ]

  for (const [name, text, reason] of BAD) {
    it(`refuses ${name} with the reason, and nothing at all changes`, () => {
      const { env, store, driver, actions, game, writes } = wired()
      const before = game()
      const storedBefore = env.storage.data.get(SAVE_KEY)
      const keysBefore = keys(env)

      const result = actions.importSave(text)
      expect(result).toMatchObject({ ok: false })
      if (result.ok) throw new Error('unreachable')
      expect(result.reason).toMatch(reason)

      expect(game()).toBe(before) // the very same object: not even a step
      expect(store.getState().game).toBe(before)
      expect(writes).toEqual([]) // no flush, no backup, no write
      expect(env.storage.data.get(SAVE_KEY)).toBe(storedBefore)
      expect(keys(env)).toEqual(keysBefore) // no save-broken-*, no save-replaced-*
      expect(driver.retired).toBe(false)
      expect(env.reloads).toBe(0)
    })
  }

  it('is not quarantined the way a broken stored save is', () => {
    const { env, actions } = wired()
    actions.importSave('garbage')
    actions.importSave(JSON.stringify({ version: target + 1, state: {} }))
    expect(keys(env).filter((k) => k.startsWith(brokenSaveKey(0).slice(0, -1)))).toEqual([])
    expect(keys(env)).toEqual([SAVE_KEY])
  })

  it('leaves the game running: the next tick and autosave carry on as if nothing was tried', () => {
    const { env, actions, game, writes } = wired()
    actions.importSave('garbage')
    const xp = game().skills.woodcutting!.xp
    env.clock += 30_000
    env.fire(content.tuning.ui.tickMs)
    expect(game().skills.woodcutting!.xp).toBeGreaterThan(xp)
    env.fire(content.tuning.save.autosaveMs)
    expect(writes.filter((w) => w.key === SAVE_KEY)).toHaveLength(1)
  })

  it('inspectSave gives the same reasons and changes nothing either', () => {
    const { actions, writes } = wired()
    expect(actions.inspectSave('nope')).toMatchObject({ ok: false, reason: expect.stringMatching(/not a readable/) })
    expect(writes).toEqual([])
  })
})

// ---------- import: a file that loads ----------

describe('import of a good file', () => {
  it('inspectSave reports what is in the file without changing anything', () => {
    const { actions, writes } = wired()
    const file = otherGameFile(NOW - 5 * HOUR)
    expect(actions.inspectSave(file.text)).toEqual({ ok: true, creatures: 2, savedAt: NOW - 5 * HOUR, migratedFrom: null })
    expect(writes).toEqual([])
  })

  it('round trip: what one game exports, another imports, and the reloaded game is the same game', () => {
    const a = wired()
    a.env.clock += 90_000
    a.env.fire(content.tuning.ui.tickMs)
    const out = a.actions.exportSave()

    // A different player's storage: a brand new game.
    const b = wired(newGame())
    b.env.clock = a.env.clock
    expect(b.actions.importSave(out.text)).toEqual({ ok: true })
    expect(b.env.storage.data.get(SAVE_KEY)).toBe(out.text) // the file's text, byte for byte
    expect(b.env.reloads).toBe(1)

    const { outcome, store } = boot(b.env)
    expect(outcome.isNewGame).toBe(false)
    expect(outcome.notice).toBeNull()
    expect(outcome.summary?.elapsedMs ?? 0).toBe(0) // exported at this very clock: nothing away
    expect(store.getState().game).toEqual(a.game())
  })

  it('takes a pretty-printed file too, and keeps its text as the save until the page boots', () => {
    const { env, actions } = wired()
    const pretty = JSON.stringify(JSON.parse(otherGameFile().text), null, 2)
    expect(actions.importSave(pretty)).toEqual({ ok: true })
    expect(env.storage.data.get(SAVE_KEY)).toBe(pretty)
    expect(boot(env).store.getState().game.gold).toBe(777)
  })

  it('a v1 file goes through the migration chain on the way in', () => {
    const c2 = variant((raw) => {
      raw.tuning.save.version = 2
    })
    MIGRATIONS[1] = (state) => ({ ...state, gold: state.gold + 1000 }) // a stand-in v1 -> v2 upgrade
    const v1 = serializeSave({ ...newGame(), gold: 5 }) // written by a v1 build
    expect(JSON.parse(v1).version).toBe(1)

    const { env, actions } = wired(newGame(), c2)
    expect(actions.inspectSave(v1)).toMatchObject({ ok: true, migratedFrom: 1 })
    expect(actions.importSave(v1)).toEqual({ ok: true })
    expect(env.storage.data.get(SAVE_KEY)).toBe(v1)

    const { outcome, store } = boot(env, c2)
    expect(outcome.migratedFrom).toBe(1)
    expect(store.getState().game.version).toBe(2)
    expect(store.getState().game.gold).toBe(1005)
  })

  it('a file from a newer build is refused, not migrated or quarantined', () => {
    const c2 = variant((raw) => {
      raw.tuning.save.version = 2
    })
    const v3 = JSON.stringify({ version: 3, state: {} })
    const { env, actions } = wired(newGame(c2), c2)
    expect(actions.importSave(v3)).toMatchObject({ ok: false, reason: expect.stringMatching(/newer version/) })
    expect(keys(env)).toEqual([SAVE_KEY])
  })

  it('a stale file is caught up by the real offline path: the time away is granted, and the welcome-back can show', () => {
    const quiet = quietContent()
    const file = otherGameFile(NOW - 5 * HOUR, quiet)
    const { env, actions } = wired(sproutletAtWork(quiet), quiet)
    expect(actions.importSave(file.text)).toEqual({ ok: true })

    const { outcome, store } = boot(env, quiet)
    // No parallel logic: the boot state is exactly what applyOffline gives the parsed file.
    const parsed = parseSave(file.text, quiet)
    if (!parsed.ok) throw new Error(parsed.message)
    const expected = applyOffline(parsed.state, env.clock, quiet)
    expect(store.getState().game).toEqual({ ...expected.state, lastSeen: env.clock })
    expect(outcome.summary?.elapsedMs).toBe(5 * HOUR)
    expect(store.getState().game.resources['oak-log']).toBe((5 * HOUR) / 3000) // 6,000, exactly (quiet content)
    expect(store.getState().welcomeBack).not.toBeNull()
  })

  it('a file older than the cap earns exactly the cap, and says so', () => {
    const quiet = quietContent()
    const file = otherGameFile(NOW - 100 * HOUR, quiet)
    const { env, actions } = wired(sproutletAtWork(quiet), quiet)
    actions.importSave(file.text)
    const { outcome, store } = boot(env, quiet)
    expect(outcome.summary).toMatchObject({ capped: true, elapsedMs: 12 * HOUR })
    expect(store.getState().game.resources['oak-log']).toBe((12 * HOUR) / 3000)
    expect(store.getState().welcomeBack?.capped).toBe(true)
  })

  it('a file saved in the future (a clock that moved back) grants nothing rather than breaking', () => {
    const file = otherGameFile(NOW + 5 * HOUR)
    const { env, actions } = wired()
    actions.importSave(file.text)
    const { outcome } = boot(env)
    expect(outcome.summary?.clockSkewed).toBe(true)
    expect(outcome.state.resources['oak-log'] ?? 0).toBe(0)
  })
})

// ---------- the backup ----------

describe('import keeps a copy of the game it replaces', () => {
  it('copies the current save byte for byte to save-replaced-<now>, taken after a flush, before the file is written', () => {
    const { env, actions, writes } = wired()
    env.clock += HOUR // an hour of work that no tick and no autosave has seen
    const file = otherGameFile(env.clock)
    expect(actions.importSave(file.text)).toEqual({ ok: true })

    const backupKey = saveReplacedKey(env.clock)
    const order = writes.map((w) => (w.key === SAVE_KEY ? (w.value === file.text ? 'file' : 'flush') : w.key === backupKey ? 'backup' : w.key))
    expect(order).toEqual(['flush', 'backup', 'file'])
    // Byte for byte: the backup is the text of the flush just before it, not a re-serialisation.
    expect(env.storage.data.get(backupKey)).toBe(writes[0]!.value)
    // ...and that flush held the hour that had not been saved.
    const backup = parseSave(env.storage.data.get(backupKey)!)
    if (!backup.ok) throw new Error(backup.message)
    expect(backup.state.lastSeen).toBe(env.clock)
    expect(backup.state.resources['oak-log']).toBeGreaterThanOrEqual(1200)
    expect(backup.state.gold).toBe(0)
    // The save is the file. Nothing else is created.
    expect(env.storage.data.get(SAVE_KEY)).toBe(file.text)
    expect(keys(env)).toEqual([SAVE_KEY, backupKey].sort())
  })

  it('refuses, changing nothing, when the backup cannot be written', () => {
    const { env, driver, actions, game } = wired()
    env.storage.failWrites = true
    const before = game()
    const result = actions.importSave(otherGameFile().text)
    expect(result).toMatchObject({ ok: false, reason: expect.stringMatching(/backup.*nothing was changed/) })
    env.storage.failWrites = false
    expect(env.storage.data.get(SAVE_KEY)).not.toBe(otherGameFile().text)
    expect(driver.retired).toBe(false)
    expect(env.reloads).toBe(0)
    expect(game().gold).toBe(before.gold)
  })

  it('refuses, and removes the copy, when the file itself cannot be written', () => {
    const { env, driver, actions } = wired()
    const file = otherGameFile()
    const realSet = env.storage.setItem
    env.storage.setItem = (key: string, value: string) => {
      if (key === SAVE_KEY && value === file.text) throw new Error('quota exceeded')
      realSet.call(env.storage, key, value)
    }
    const result = actions.importSave(file.text)
    expect(result).toMatchObject({ ok: false, reason: expect.stringMatching(/write the imported save.*nothing was changed/) })
    expect(keys(env)).toEqual([SAVE_KEY])
    expect(driver.retired).toBe(false)
    expect(env.reloads).toBe(0)
  })
})

// ---------- the trap ----------

describe('THE TRAP: the old game cannot be written back over the import', () => {
  it("this tab's own pagehide / beforeunload flush, the autosave and a visibility change leave the file as the save", () => {
    const { env, actions } = wired()
    env.clock += 30_000
    const file = otherGameFile(env.clock)
    actions.importSave(file.text)
    env.clock += 60_000
    env.win.dispatchEvent(new Event('pagehide'))
    env.win.dispatchEvent(new Event('beforeunload'))
    env.doc.dispatchEvent(new Event('visibilitychange'))
    env.fire(content.tuning.save.autosaveMs)
    env.fire(content.tuning.ui.tickMs)
    expect(env.storage.data.get(SAVE_KEY)).toBe(file.text)
    expect(env.intervals.size).toBe(0)
    expect(boot(env).store.getState().game.gold).toBe(777) // what the reload finds is the imported game
  })

  it('a reload that runs its unload handlers synchronously, as a page does, still cannot write the old game back', () => {
    const { env, actions } = wired()
    const file = otherGameFile(env.clock)
    env.reload = () => {
      env.reloads++
      env.win.dispatchEvent(new Event('pagehide'))
      env.win.dispatchEvent(new Event('beforeunload'))
    }
    actions.importSave(file.text)
    expect(env.reloads).toBe(1)
    expect(env.storage.data.get(SAVE_KEY)).toBe(file.text)
  })

  it('a flushing action after the import (a click while the page is going away) writes nothing', () => {
    const { env, actions, driver, writes } = wired()
    const file = otherGameFile(env.clock)
    actions.importSave(file.text)
    const count = writes.length
    actions.setSetting('devPanelEnabled', true)
    actions.addGold(10)
    actions.fastForwardHours(1)
    actions.exportSave()
    driver.flush()
    const rolled = actions.commitRoll((state) => ({ state: { ...state, gold: state.gold + 1 }, result: 'x' }))
    expect(rolled.saved).toBe(false)
    expect(writes).toHaveLength(count)
    expect(env.storage.data.get(SAVE_KEY)).toBe(file.text)
  })

  it('a failed import does not retire the driver, so the game still saves afterwards', () => {
    const { env, actions, writes } = wired()
    actions.importSave('garbage')
    env.clock += 1000
    env.win.dispatchEvent(new Event('pagehide'))
    expect(writes.filter((w) => w.key === SAVE_KEY)).toHaveLength(1)
  })
})
