// What the UI can do to the game. Thin wrappers: each one steps the sim to now, calls the sim function, and
// commits the result to the store. The sim decides whether a move is legal and the wrapper hands back its reason
// (never throws), so the UI shows the rule's own words instead of re-implementing the rule.
//
// Stepping to now first matters: the tick lands every `ui.tickMs`, so without it the last few dozen milliseconds
// would be credited to whatever the slot looks like after the change instead of before it.
import { content, type Content } from '../data'
import { addAether, addGold, addResource, deleteCreature, grantCreature, setSkillLevel, type DevResult, type GrantSpec } from '../sim/dev'
import { serializeSave } from '../sim/save'
import { assignCreature, setSlotResource, unassignCreature } from '../sim/skills'
import type { GameState, Settings } from '../types/state'
import type { TickDriver } from './driver'
import { clearLog, markAllRead } from './notifications'
import { checkImport, commitRoll, exportFileName, replaceSave, SAVE_KEY, type ImportCheck, type StorageLike } from './persistence'
import type { GameStoreApi } from './store'

export type ActionResult = { ok: true } | { ok: false; reason: string }

/** A dev action's outcome: what it did in words, or why it refused. Neither case throws. */
export type DevActionResult = { ok: true; message: string } | { ok: false; reason: string }

export type { GrantSpec, ImportCheck }

/** A save file for the player to keep: what `sim/save.ts` writes, and the name to offer it under. */
export interface ExportedSave {
  fileName: string
  text: string
}

export interface Actions {
  /** Puts a creature in a slot on a resource. A creature already working elsewhere is moved. */
  assignCreature(creatureId: string, skillId: string, slotIndex: number, resourceId: string): ActionResult
  /** Benches a creature, emptying its slot. */
  unassignCreature(creatureId: string): void
  /** Switches what an occupied slot gathers. Progress on the old action is lost. */
  setSlotResource(skillId: string, slotIndex: number, resourceId: string): ActionResult
  /** Closes the quarantine banner. */
  dismissNotice(): void
  /** Closes the welcome-back summary. It is gone for good: the progress it reported was already granted. */
  dismissWelcomeBack(): void
  /** Marks every notification read (the bell's badge goes to zero). */
  markNotificationsRead(): void
  /** Empties the bell's list. */
  clearNotifications(): void
  /** Flips one of the player's settings and saves at once, so it survives a reload however the tab ends. */
  setSetting(key: keyof Settings, value: boolean): void
  /**
   * The dev panel (plan 7.1). Grants `hours` of the REAL offline path: the same `applyOffline`, the same cap, the
   * same welcome-back summary as a long gap. It has no maths of its own, so 100 hours under a 12-hour cap grants 12.
   * It saves straight afterwards, because this tab's own flush would otherwise be the only record of it.
   */
  fastForwardHours(hours: number): void
  /**
   * For breed, hatch and capture (plan 4.6): runs `roll`, then saves the result and the advanced RNG state in
   * the same write, so a reload cannot replay the roll. Nothing calls it before phase 2. `saved` is false when
   * the write failed (storage full or blocked); the roll still happened in memory.
   */
  commitRoll<R>(roll: (state: GameState) => { state: GameState; result: R }): { result: R; saved: boolean }

  // ---- save files (Settings, step 1.9) ----

  /** Steps to now and saves, then returns exactly the text just written (`serializeSave`), with a file name carrying the game and the time. */
  exportSave(): ExportedSave
  /** Reads a save file the way a load would and says what is in it, or why it is refused. Changes nothing at all. */
  inspectSave(text: string): ImportCheck
  /**
   * Replaces the current game with a save file. A file that fails to parse or validate is refused with the reason and
   * nothing changes (it is not quarantined). Otherwise: save the current game, copy that save byte for byte to
   * `save-replaced-<now>`, write the file's text as the save, RETIRE the driver, and reload, so the page boots through
   * `loadGame` (parse, migrations, reconcile, `applyOffline`, welcome-back) like any stored save. Retiring is what stops
   * this tab's own pagehide / beforeunload flush from writing the old game back over the import (the reset trap).
   */
  importSave(text: string): ActionResult

  // ---- the dev panel (plan 7.1, step 1.8b). Each validates, never throws, saves at once, and leaves the RNG alone. ----

  /** Adds a benched creature exactly as specified (nothing is rolled). Any species, rarity, level, form and shiny flag. */
  grantCreature(spec: GrantSpec): DevActionResult
  /** Removes a creature for good (the trash can on a Nexus card in dev mode). One at work is benched first, so its slot is emptied. Its id is not reused. */
  deleteCreature(creatureId: string): DevActionResult
  /** Adds a whole number of any resource. `amount` is what the field holds: empty, negative, non-finite and huge are refused. */
  addResource(resourceId: string, amount: unknown): DevActionResult
  /** Adds Aether (a fraction is fine). */
  addAether(amount: unknown): DevActionResult
  /** Adds gold (whole numbers). */
  addGold(amount: unknown): DevActionResult
  /**
   * Raises a skill's XP to what `level` takes, through the sim's own XP code so slots unlock and the level cache is
   * right. It only raises: a skill already at or past the level is refused with a reason.
   */
  setSkillLevel(skillId: string, level: unknown): DevActionResult
  /**
   * Wipes the save (only `SAVE_KEY`; the `save-broken-*` copies stay) and reloads the page. The driver is retired
   * FIRST, so this tab's own pagehide / beforeunload flush cannot write the old game back over the wipe. After it
   * runs nothing saves any more; the reload starts a new game.
   */
  resetSave(): void
}

export function createActions(
  store: GameStoreApi,
  driver: Pick<TickDriver, 'stepToNow' | 'flush' | 'fastForwardHours' | 'retire' | 'retired'>,
  storage: StorageLike,
  reload: () => void = () => {},
  c: Content = content,
): Actions {
  const game = (): GameState => store.getState().game
  const commit = (state: GameState): void => store.setState({ game: state })

  // commitRoll writes straight to storage rather than through the driver, so once the save has been reset it must
  // be refused here too: a throwing write is what `flushSave` reports as `saved: false`.
  const rollStorage: StorageLike = {
    getItem: (key) => storage.getItem(key),
    setItem: (key, value) => {
      if (driver.retired) throw new Error('the save was reset')
      storage.setItem(key, value)
    },
    removeItem: (key) => storage.removeItem(key),
  }

  /** Steps to now, applies a dev change, commits it and saves, or hands back the reason. */
  const dev = (change: (state: GameState) => DevResult): DevActionResult => {
    driver.stepToNow()
    const result = change(game())
    if (!result.ok) return result
    commit(result.state)
    driver.flush()
    return { ok: true, message: result.message }
  }

  return {
    assignCreature(creatureId, skillId, slotIndex, resourceId) {
      driver.stepToNow()
      const result = assignCreature(game(), creatureId, skillId, slotIndex, resourceId)
      if (!result.ok) return result
      commit(result.state)
      return { ok: true }
    },

    unassignCreature(creatureId) {
      driver.stepToNow()
      commit(unassignCreature(game(), creatureId))
    },

    setSlotResource(skillId, slotIndex, resourceId) {
      driver.stepToNow()
      const result = setSlotResource(game(), skillId, slotIndex, resourceId)
      if (!result.ok) return result
      commit(result.state)
      return { ok: true }
    },

    dismissNotice() {
      store.setState({ noticeDismissed: true })
    },

    dismissWelcomeBack() {
      store.setState({ welcomeBack: null })
    },

    markNotificationsRead() {
      store.setState({ notifications: markAllRead(store.getState().notifications) })
    },

    clearNotifications() {
      store.setState({ notifications: clearLog(store.getState().notifications) })
    },

    setSetting(key, value) {
      const state = game()
      if (state.settings[key] === value) return
      commit({ ...state, settings: { ...state.settings, [key]: value } })
      driver.flush()
    },

    fastForwardHours(hours) {
      driver.fastForwardHours(hours)
      driver.flush()
    },

    commitRoll(roll) {
      // commitRoll stamps lastSeen = now, so the sim must be stepped to that same now first.
      const now = driver.stepToNow()
      const committed = commitRoll(rollStorage, game(), roll, now)
      commit(committed.state)
      return { result: committed.result, saved: committed.saved }
    },

    exportSave() {
      const now = driver.stepToNow()
      driver.flush()
      return { fileName: exportFileName(now), text: serializeSave(game()) }
    },

    inspectSave: (text) => checkImport(text, c),

    importSave(text) {
      // Validate first: a bad file must not cost the player anything, not even a flush.
      const checked = checkImport(text, c)
      if (!checked.ok) return checked
      // Save now, so the backup is the game as it is at this moment and not up to one autosave old.
      const now = driver.stepToNow()
      driver.flush()
      const replaced = replaceSave(storage, text, now)
      if (!replaced.ok) return replaced
      // Retire in the same synchronous block as the write, before anything else can run: after this nothing this
      // driver does may write the save, or the pagehide flush of the reload below would put the old game back.
      driver.retire()
      reload()
      return { ok: true }
    },

    grantCreature: (spec) => dev((state) => grantCreature(state, spec)),
    deleteCreature: (creatureId) => dev((state) => deleteCreature(state, creatureId)),
    addResource: (resourceId, amount) => dev((state) => addResource(state, resourceId, amount)),
    addAether: (amount) => dev((state) => addAether(state, amount)),
    addGold: (amount) => dev((state) => addGold(state, amount)),

    setSkillLevel: (skillId, level) => dev((state) => setSkillLevel(state, skillId, level)),

    resetSave() {
      // Order matters. Retire first: it removes the pagehide / beforeunload listeners and the autosave timer and blocks
      // every later flush. Only then wipe, and only the main key. Then reload into a new game.
      driver.retire()
      try {
        storage.removeItem(SAVE_KEY)
      } catch {
        // Storage blocked: nothing was saved to wipe, and the reload starts fresh regardless.
      }
      reload()
    },
  }
}
