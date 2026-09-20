// What the UI can do to the game. Thin wrappers: each one steps the sim to now, calls the sim function, and
// commits the result to the store. The sim decides whether a move is legal and the wrapper hands back its reason
// (never throws), so the UI shows the rule's own words instead of re-implementing the rule.
//
// Stepping to now first matters: the tick lands every `ui.tickMs`, so without it the last few dozen milliseconds
// would be credited to whatever the slot looks like after the change instead of before it.
import { assignCreature, setSlotResource, unassignCreature } from '../sim/skills'
import type { GameState } from '../types/state'
import type { TickDriver } from './driver'
import { commitRoll, type StorageLike } from './persistence'
import type { GameStoreApi } from './store'

export type ActionResult = { ok: true } | { ok: false; reason: string }

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
  /**
   * For breed, hatch and capture (plan 4.6): runs `roll`, then saves the result and the advanced RNG state in
   * the same write, so a reload cannot replay the roll. Nothing calls it before phase 2. `saved` is false when
   * the write failed (storage full or blocked); the roll still happened in memory.
   */
  commitRoll<R>(roll: (state: GameState) => { state: GameState; result: R }): { result: R; saved: boolean }
}

export function createActions(store: GameStoreApi, driver: Pick<TickDriver, 'stepToNow'>, storage: StorageLike): Actions {
  const game = (): GameState => store.getState().game
  const commit = (state: GameState): void => store.setState({ game: state })

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

    commitRoll(roll) {
      // commitRoll stamps lastSeen = now, so the sim must be stepped to that same now first.
      const now = driver.stepToNow()
      const committed = commitRoll(storage, game(), roll, now)
      commit(committed.state)
      return { result: committed.result, saved: committed.saved }
    },
  }
}
