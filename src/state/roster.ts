// Roster filtering and sorting: pure functions, no React, no store, no sim. They work on anything shaped like a
// creature view (`RosterItem`), so they run in node against the real `CreatureView`s the selectors build, and
// the UI reaches them through selectors.ts, which re-exports them.
//
// What "can work skill X" means is the sim's rule (`canWork`), not something to redo here: the selector that builds
// a creature view asks the sim once and stores the answer in `workableSkillIds`, and the filter only reads it.

/** What the roster needs to know about a creature. `CreatureView` satisfies it structurally. */
export interface RosterItem {
  id: string
  /** The number in `creature-<n>`. The tiebreak, so equal creatures always keep the same order. */
  seq: number
  /** The name it shows now (its current form's). */
  name: string
  /** One type, or two for a hybrid. `order` is the type's position in types.json. */
  types: readonly { id: string; order: number }[]
  rarity: { tier: number }
  form: number
  level: number
  shiny: boolean
  working: boolean
  workableSkillIds: readonly string[]
}

/** `null` on any field means "do not filter on this". All set fields must match. */
export interface RosterFilter {
  /** A hybrid matches either of its two types. */
  type: string | null
  /** Rarity tier. */
  rarity: number | null
  form: number | null
  /** true: only shinies. false: only non-shinies. */
  shiny: boolean | null
  work: 'working' | 'benched' | null
  /** Creatures the sim lets work this skill. */
  canWork: string | null
}

export const NO_FILTER: RosterFilter = { type: null, rarity: null, form: null, shiny: null, work: null, canWork: null }

export const SORT_KEYS = ['rarity', 'level', 'name', 'type', 'form'] as const
export type SortKey = (typeof SORT_KEYS)[number]
export type SortDir = 'asc' | 'desc'

export interface RosterSort {
  key: SortKey
  dir: SortDir
}

/** The direction a key opens in: best first for the numbers, A to Z for the words. */
export const defaultDirection = (key: SortKey): SortDir => (key === 'name' || key === 'type' ? 'asc' : 'desc')

export const DEFAULT_SORT: RosterSort = { key: 'rarity', dir: defaultDirection('rarity') }

export const isFiltered = (f: RosterFilter): boolean => Object.values(f).some((v) => v !== null)

/**
 * What a click on the Nexus page's bench strip does to the filter: show only the benched creatures, or, when that is
 * already what is shown, take that one condition off again. Every other field of the filter is left as it is.
 */
export const toggleBenched = (f: RosterFilter): RosterFilter => ({ ...f, work: f.work === 'benched' ? null : 'benched' })

export function matchesFilter(item: RosterItem, f: RosterFilter): boolean {
  if (f.type !== null && !item.types.some((t) => t.id === f.type)) return false
  if (f.rarity !== null && item.rarity.tier !== f.rarity) return false
  if (f.form !== null && item.form !== f.form) return false
  if (f.shiny !== null && item.shiny !== f.shiny) return false
  if (f.work === 'working' && !item.working) return false
  if (f.work === 'benched' && item.working) return false
  if (f.canWork !== null && !item.workableSkillIds.includes(f.canWork)) return false
  return true
}

/** Items that pass the filter, in their input order. Returns a new array. */
export const filterRoster = <T extends RosterItem>(items: readonly T[], filter: RosterFilter): T[] => items.filter((item) => matchesFilter(item, filter))

const collator = new Intl.Collator('en', { sensitivity: 'base' })

/** Compares on the sort key alone, ascending. Direction and the tiebreak are applied by `sortRoster`. */
function compareKey(a: RosterItem, b: RosterItem, key: SortKey): number {
  switch (key) {
    case 'rarity':
      return a.rarity.tier - b.rarity.tier
    case 'level':
      return a.level - b.level
    case 'form':
      return a.form - b.form
    case 'name':
      return collator.compare(a.name, b.name)
    case 'type': {
      // Types in the data's order (the wheel's), first type then second; a pure type sorts before its hybrids.
      const rank = (item: RosterItem, i: number): number => item.types[i]?.order ?? -1
      return rank(a, 0) - rank(b, 0) || rank(a, 1) - rank(b, 1)
    }
  }
}

/**
 * Sorts by `sort.key` in `sort.dir`, and always breaks a tie by creature sequence number ascending, whichever way
 * the primary key runs. The order is therefore a total order: the same creatures always come out in the same
 * sequence, so cards never swap places between renders. (An id with no number in it has no `seq`; the id text is the
 * last resort, so even that stays total.) Returns a new array.
 */
export function sortRoster<T extends RosterItem>(items: readonly T[], sort: RosterSort): T[] {
  const sign = sort.dir === 'desc' ? -1 : 1
  return items.slice().sort((a, b) => sign * compareKey(a, b, sort.key) || a.seq - b.seq || (a.id < b.id ? -1 : a.id > b.id ? 1 : 0))
}

/** Filter, then sort. */
export const arrangeRoster = <T extends RosterItem>(items: readonly T[], filter: RosterFilter, sort: RosterSort): T[] =>
  sortRoster(filterRoster(items, filter), sort)
