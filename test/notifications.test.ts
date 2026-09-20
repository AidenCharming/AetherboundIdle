import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import type { SimEvent } from '../src/sim/events'
import { clearLog, emptyLog, markAllRead, notify, unreadCount, visibleToasts, type NotificationLog } from '../src/state/notifications'
import { variant } from './helpers'

const WINDOW = content.tuning.ui.toastMs
const MAX = content.tuning.ui.maxNotifications
const T = 1_700_000_000_000

const levelUp = (skillId: string, level: number): SimEvent => ({ type: 'skill-level-up', skillId, level })
const slot = (skillId: string, slotIndex: number): SimEvent => ({ type: 'slot-unlocked', skillId, slotIndex })
const actionComplete: SimEvent = { type: 'action-complete', skillId: 'woodcutting', slotIndex: 0, creatureId: 'creature-1', resourceId: 'oak-log', count: 3, outputs: { 'oak-log': 3 }, skillXp: 30 }

/** Runs several steps: each `[time, events]` is one online step. */
const run = (steps: [number, SimEvent[]][], log: NotificationLog = emptyLog()) => steps.reduce((l, [now, events]) => notify(l, events, now), log)

describe('what is recorded, and how it reads', () => {
  it('a level-up says which skill reached which level, in the data\'s own name', () => {
    const log = notify(emptyLog(), [levelUp('woodcutting', 2)], T)
    expect(log.items).toEqual([{ id: 1, at: T, kind: 'skill-level-up', text: 'Woodcutting reached level 2', read: false, skillId: 'woodcutting', level: 2 }])
    expect(notify(emptyLog(), [levelUp('aether-weaving', 7)], T).items[0]!.text).toBe('Aether-Weaving reached level 7')
  })

  it('a slot unlock says which skill and which slot, counted from 1 as the player counts', () => {
    const log = notify(emptyLog(), [slot('woodcutting', 1)], T)
    expect(log.items[0]).toMatchObject({ kind: 'slot-unlocked', text: 'Woodcutting unlocked slot 2', read: false, skillId: 'woodcutting', level: null })
  })

  it('takes the name from the data: rename the skill and the text follows', () => {
    const c = variant((raw) => (raw.skills.find((s: { id: string }) => s.id === 'woodcutting').name = 'Lumbering'))
    expect(notify(emptyLog(), [levelUp('woodcutting', 3)], T, c).items[0]!.text).toBe('Lumbering reached level 3')
    expect(notify(emptyLog(), [slot('woodcutting', 2)], T, c).items[0]!.text).toBe('Lumbering unlocked slot 3')
  })

  it('records level-ups and slot unlocks and nothing else: action-complete never notifies', () => {
    const others: SimEvent[] = [actionComplete, { type: 'creature-level-up', creatureId: 'creature-1', level: 5 }, { type: 'form-evolved', creatureId: 'creature-1', form: 2 }]
    const start = emptyLog()
    expect(notify(start, others, T)).toBe(start) // and the very same object back, so the store does not change
    expect(notify(start, [], T)).toBe(start)
    expect(notify(start, [actionComplete, levelUp('woodcutting', 2), actionComplete], T).items).toHaveLength(1)
  })

  it('gives every entry its own id, counting on and never reusing one, even after a clear', () => {
    const a = run([[T, [slot('woodcutting', 1)]], [T + 1, [slot('woodcutting', 2)]]])
    expect(a.items.map((i) => i.id)).toEqual([1, 2])
    const cleared = clearLog(a)
    expect(cleared.items).toEqual([])
    expect(notify(cleared, [slot('woodcutting', 3)], T + 2).items[0]!.id).toBe(3)
  })
})

describe('bounds', () => {
  it('never holds more than tuning.ui.maxNotifications, dropping the oldest first', () => {
    const many = Array.from({ length: MAX + 20 }, (_, i) => slot('woodcutting', i))
    const log = notify(emptyLog(), many, T)
    expect(log.items).toHaveLength(MAX)
    expect(log.items[0]!.text).toBe(`Woodcutting unlocked slot ${21 + 0}`) // the first 20 fell off the front
    expect(log.items.at(-1)!.text).toBe(`Woodcutting unlocked slot ${MAX + 20}`)
    expect(new Set(log.items.map((i) => i.id)).size).toBe(MAX)
  })

  it('stays bounded across many steps, and follows the knob', () => {
    const c = variant((raw) => (raw.tuning.ui.maxNotifications = 4))
    let log = emptyLog()
    for (let i = 0; i < 30; i++) log = notify(log, [slot('woodcutting', i)], T + i, c)
    expect(log.items.map((i) => i.id)).toEqual([27, 28, 29, 30])
    expect(log.nextId).toBe(31)
  })

  it('a bound of 1 keeps just the newest', () => {
    const c = variant((raw) => (raw.tuning.ui.maxNotifications = 1))
    const log = notify(emptyLog(), [slot('woodcutting', 1), slot('woodcutting', 2)], T, c)
    expect(log.items.map((i) => i.text)).toEqual(['Woodcutting unlocked slot 3'])
  })
})

describe('coalescing: a fast skill cannot spam', () => {
  it('two levels in one step are one entry that says the last level', () => {
    const log = notify(emptyLog(), [levelUp('woodcutting', 2), levelUp('woodcutting', 3), levelUp('woodcutting', 4)], T)
    expect(log.items).toHaveLength(1)
    expect(log.items[0]).toMatchObject({ id: 1, text: 'Woodcutting reached level 4', level: 4 })
  })

  it('level-ups on successive steps inside the toast window are one entry, keeping its id', () => {
    const log = run([[T, [levelUp('woodcutting', 2)]], [T + 1000, [levelUp('woodcutting', 3)]], [T + 2500, [levelUp('woodcutting', 4)]]])
    expect(log.items).toHaveLength(1)
    expect(log.items[0]).toMatchObject({ id: 1, text: 'Woodcutting reached level 4', at: T + 2500 })
  })

  it('a skill levelling every second for a whole minute is one line, not sixty', () => {
    let log = emptyLog()
    for (let i = 0; i < 60; i++) log = notify(log, [levelUp('woodcutting', 2 + i)], T + i * 1000)
    expect(log.items).toHaveLength(1)
    expect(log.items[0]!.text).toBe('Woodcutting reached level 61')
  })

  it('the window is tuning.ui.toastMs: at the edge it still joins, one ms past it starts a new entry', () => {
    const edge = run([[T, [levelUp('woodcutting', 2)]], [T + WINDOW, [levelUp('woodcutting', 3)]]])
    expect(edge.items).toHaveLength(1)
    const past = run([[T, [levelUp('woodcutting', 2)]], [T + WINDOW + 1, [levelUp('woodcutting', 3)]]])
    expect(past.items.map((i) => i.text)).toEqual(['Woodcutting reached level 2', 'Woodcutting reached level 3'])
    const c = variant((raw) => (raw.tuning.ui.toastMs = 500))
    const short = notify(notify(emptyLog(), [levelUp('woodcutting', 2)], T, c), [levelUp('woodcutting', 3)], T + 501, c)
    expect(short.items).toHaveLength(2)
  })

  it('the window slides: it counts from the entry\'s last update, so a steady burst stays one entry', () => {
    // Each level is 4 s after the last, inside the 5 s window, though the 3rd is 8 s after the first.
    const log = run([[T, [levelUp('woodcutting', 2)]], [T + 4000, [levelUp('woodcutting', 3)]], [T + 8000, [levelUp('woodcutting', 4)]]])
    expect(log.items).toHaveLength(1)
  })

  it('different skills do not coalesce', () => {
    const log = run([[T, [levelUp('woodcutting', 2)]], [T + 100, [levelUp('mining', 2)]], [T + 200, [levelUp('woodcutting', 3)]]])
    expect(log.items.map((i) => i.text)).toEqual(['Woodcutting reached level 2', 'Mining reached level 2', 'Woodcutting reached level 3'])
  })

  it('an entry in between (a slot unlock) breaks the run: only CONSECUTIVE level-ups coalesce', () => {
    const log = run([[T, [levelUp('woodcutting', 2), slot('woodcutting', 1)]], [T + 100, [levelUp('woodcutting', 3)]]])
    expect(log.items.map((i) => i.text)).toEqual(['Woodcutting reached level 2', 'Woodcutting unlocked slot 2', 'Woodcutting reached level 3'])
  })

  it('never coalesces slot unlocks: each new slot is its own line', () => {
    const log = notify(emptyLog(), [slot('woodcutting', 1), slot('woodcutting', 2)], T)
    expect(log.items).toHaveLength(2)
  })

  it('does not change the entries before it, or the list it was given', () => {
    const before = run([[T, [slot('woodcutting', 1)]], [T + 1, [levelUp('woodcutting', 2)]]])
    const snapshot = JSON.stringify(before)
    const after = notify(before, [levelUp('woodcutting', 3)], T + 2)
    expect(JSON.stringify(before)).toBe(snapshot)
    expect(after.items[0]).toBe(before.items[0])
  })
})

describe('unread', () => {
  it('counts what has not been read, and Mark all read zeroes it', () => {
    const log = run([[T, [slot('woodcutting', 1)]], [T + 10_000, [levelUp('woodcutting', 2)]], [T + 20_000, [levelUp('mining', 2)]]])
    expect(unreadCount(log.items)).toBe(3)
    const read = markAllRead(log)
    expect(unreadCount(read.items)).toBe(0)
    expect(read.items).toHaveLength(3) // read, not removed
    expect(unreadCount(notify(read, [slot('mining', 1)], T + 30_000).items)).toBe(1)
  })

  it('a level-up that coalesces into a READ entry makes it unread again: it says something new', () => {
    let log = notify(emptyLog(), [levelUp('woodcutting', 2)], T)
    log = markAllRead(log)
    expect(unreadCount(log.items)).toBe(0)
    log = notify(log, [levelUp('woodcutting', 3)], T + 1000)
    expect(log.items).toHaveLength(1)
    expect(unreadCount(log.items)).toBe(1)
  })

  it('marking read and clearing hand back the same object when there is nothing to do', () => {
    const empty = emptyLog()
    expect(markAllRead(empty)).toBe(empty)
    expect(clearLog(empty)).toBe(empty)
    const read = markAllRead(notify(empty, [slot('woodcutting', 1)], T))
    expect(markAllRead(read)).toBe(read)
  })

  it('Clear empties the list and so the count', () => {
    const log = clearLog(run([[T, [slot('woodcutting', 1)]], [T + 1, [slot('woodcutting', 2)]]]))
    expect(log.items).toEqual([])
    expect(unreadCount(log.items)).toBe(0)
  })
})

describe('visibleToasts', () => {
  const MAX_TOASTS = content.tuning.ui.maxToasts
  const five = notify(emptyLog(), Array.from({ length: 5 }, (_, i) => slot('woodcutting', i)), T)

  it('shows at most tuning.ui.maxToasts, the newest, oldest first', () => {
    const shown = visibleToasts(five.items, 1, new Map(), MAX_TOASTS)
    expect(shown).toHaveLength(MAX_TOASTS)
    expect(shown.map((n) => n.id)).toEqual(five.items.slice(-MAX_TOASTS).map((n) => n.id))
    expect(visibleToasts(five.items, 1, new Map(), 1).map((n) => n.id)).toEqual([5])
  })

  it('shows nothing that was recorded before the host mounted', () => {
    expect(visibleToasts(five.items, five.nextId, new Map(), MAX_TOASTS)).toEqual([])
    expect(visibleToasts(five.items, 4, new Map(), MAX_TOASTS).map((n) => n.id)).toEqual([4, 5])
  })

  it('leaves out a dismissed toast, and shows an entry again once coalescing gives it a newer time', () => {
    const one = notify(emptyLog(), [levelUp('woodcutting', 2)], T)
    const dismissed = new Map([[1, T]])
    expect(visibleToasts(one.items, 1, dismissed, MAX_TOASTS)).toEqual([])
    const grown = notify(one, [levelUp('woodcutting', 3)], T + 1000)
    expect(visibleToasts(grown.items, 1, dismissed, MAX_TOASTS).map((n) => n.text)).toEqual(['Woodcutting reached level 3'])
  })

  it('a dismissed toast makes room for the next older one, still within the bound', () => {
    const dismissed = new Map([[five.items.at(-1)!.id, five.items.at(-1)!.at]])
    const shown = visibleToasts(five.items, 1, dismissed, MAX_TOASTS)
    expect(shown).toHaveLength(MAX_TOASTS)
    expect(shown.map((n) => n.id)).not.toContain(5)
  })
})
