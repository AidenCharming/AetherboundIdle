// The notification log (step 1.9b): what the bell lists and the toasts announce. It is UI state. It lives in the store next
// to the game but never inside `GameState`, so it is not in the save and a reload starts it empty. Pure functions on a
// plain `{ items, nextId }` value: no timers, no clock (the caller passes `now`), no React. Showing, pausing and dismissing
// toasts is the UI's business; this only records what happened.
//
// Only the ONLINE tick feeds it (driver.ts). Whatever `applyOffline` produced is reported once, by the welcome-back dialog,
// and never here.
import { content, type Content } from '../data'
import type { SimEvent } from '../sim/events'

export type NotificationKind = 'skill-level-up' | 'slot-unlocked'

export interface Notification {
  id: number
  /** When it was recorded, or last updated by coalescing (epoch ms, from the caller's clock). */
  at: number
  kind: NotificationKind
  /** Built here from the data's names, so the UI prints it as it is. */
  text: string
  read: boolean
  /** The skill it is about (its emoji and name come from the data). */
  skillId: string
  /** The level reached, for a level-up; null for a slot. Kept so a later level-up can coalesce into this entry. */
  level: number | null
}

export interface NotificationLog {
  /** Oldest first, at most `tuning.ui.maxNotifications`. */
  readonly items: readonly Notification[]
  /** The id the next new entry gets. Never reused, even after a clear, so a UI keyed by id cannot confuse two entries. */
  readonly nextId: number
}

export const emptyLog = (): NotificationLog => ({ items: [], nextId: 1 })

const skillName = (c: Content, skillId: string): string => c.skillById.get(skillId)?.name ?? skillId

const levelUpText = (c: Content, skillId: string, level: number): string => `${skillName(c, skillId)} reached level ${level}`
const slotText = (c: Content, skillId: string, slotIndex: number): string => `${skillName(c, skillId)} unlocked slot ${slotIndex + 1}`

/** Newest entries win when the list is over the bound. */
const bound = (items: readonly Notification[], max: number): readonly Notification[] => (items.length > max ? items.slice(items.length - max) : items)

/**
 * Records what an ONLINE step reported. Only two kinds of event matter: `skill-level-up` and `slot-unlocked`. Everything
 * else (`action-complete` above all, which arrives every action) is ignored. Returns the same log object when nothing was
 * worth recording, so the store does not change on a quiet tick.
 *
 * Coalescing: a level-up joins the NEWEST entry, instead of adding one, when that entry is a level-up of the same skill
 * and was recorded within `tuning.ui.toastMs`. The entry then says the latest level, moves its `at` forward (so a burst
 * stays one entry for as long as it keeps going) and becomes unread again, since it says something new. So a fast skill
 * cannot spam the bell: two levels in one step, or a level every few seconds, are one line.
 */
export function notify(log: NotificationLog, events: readonly SimEvent[], now: number, c: Content = content): NotificationLog {
  let items = log.items
  let nextId = log.nextId
  const windowMs = c.tuning.ui.toastMs

  for (const e of events) {
    if (e.type === 'skill-level-up') {
      const newest = items[items.length - 1]
      if (newest && newest.kind === 'skill-level-up' && newest.skillId === e.skillId && now - newest.at <= windowMs) {
        const merged: Notification = { ...newest, at: now, level: e.level, text: levelUpText(c, e.skillId, e.level), read: false }
        items = [...items.slice(0, -1), merged]
      } else {
        items = [...items, { id: nextId++, at: now, kind: 'skill-level-up', text: levelUpText(c, e.skillId, e.level), read: false, skillId: e.skillId, level: e.level }]
      }
    } else if (e.type === 'slot-unlocked') {
      items = [...items, { id: nextId++, at: now, kind: 'slot-unlocked', text: slotText(c, e.skillId, e.slotIndex), read: false, skillId: e.skillId, level: null }]
    }
  }

  if (items === log.items) return log
  return { items: bound(items, c.tuning.ui.maxNotifications), nextId }
}

/**
 * Which notifications have a toast up right now: the ones recorded from `firstId` on (so a host that mounts late does not
 * replay history), minus those dismissed (`dismissed` maps an id to the `at` that was dismissed, so an entry that later
 * coalesces to a newer `at` shows again with its new text), and at most `max` of them, the newest. Oldest first.
 */
export function visibleToasts(items: readonly Notification[], firstId: number, dismissed: ReadonlyMap<number, number>, max: number): readonly Notification[] {
  return items.filter((n) => n.id >= firstId && dismissed.get(n.id) !== n.at).slice(-max)
}

export const unreadCount = (items: readonly Notification[]): number => items.reduce((n, it) => (it.read ? n : n + 1), 0)

/** Marks everything read. Same object back when nothing was unread. */
export function markAllRead(log: NotificationLog): NotificationLog {
  if (log.items.every((it) => it.read)) return log
  return { ...log, items: log.items.map((it) => (it.read ? it : { ...it, read: true })) }
}

/** Empties the list. `nextId` carries on. Same object back when it was already empty. */
export function clearLog(log: NotificationLog): NotificationLog {
  return log.items.length === 0 ? log : { ...log, items: [] }
}
