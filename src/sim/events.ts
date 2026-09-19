// The event queue the UI subscribes to (plan.md 4.7). Every step returns `{ state, events }`, so the
// progress animations and, later, the hatch reveal need no sim rework. Egg, shiny and discovery events
// arrive with phase 2.

export type SimEvent =
  /**
   * One or more actions finished in a slot. `count` is aggregated: a 200 ms frame usually reports 1, and a
   * 6-hour offline window reports one event per slot with a large count rather than thousands of events.
   */
  | {
      type: 'action-complete'
      skillId: string
      slotIndex: number
      creatureId: string
      resourceId: string
      count: number
      /** Everything gained, keyed by resource id: the gathered resource, extra output and rare drops. */
      outputs: Record<string, number>
      skillXp: number
    }
  /** One event per level crossed, in ascending order. */
  | { type: 'skill-level-up'; skillId: string; level: number }
  | { type: 'slot-unlocked'; skillId: string; slotIndex: number }
  | { type: 'creature-level-up'; creatureId: string; level: number }
  | { type: 'form-evolved'; creatureId: string; form: number }

export interface SimResult<S> {
  state: S
  events: SimEvent[]
}
