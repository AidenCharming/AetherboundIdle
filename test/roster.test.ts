import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { canWork } from '../src/sim/creature'
import { createActions } from '../src/state/actions'
import { createTickDriver } from '../src/state/driver'
import { flushSave, loadGame } from '../src/state/persistence'
import * as sel from '../src/state/selectors'
import { createGameStore, type GameStore } from '../src/state/store'
import type { Creature, GameState } from '../src/types/state'
import { FakeEnv, HOUR, MemoryStorage, NOW, rosterGame } from './helpers'

const view = (game: GameState): GameStore => ({ ...createGameStore(loadGame(new MemoryStorage(), NOW, 1)).getState(), game })

const game = rosterGame(120)
const creatures = game.creatures
const views = sel.selectCreatureViews(view(game))
const def = (cr: Creature) => content.creatureById.get(cr.speciesId)!
const idsOf = (list: readonly { id: string }[]) => list.map((v) => v.id)
/** The views whose creature passes `keep`: an oracle computed from the game state and the data, not from the views. */
const expected = (keep: (cr: Creature) => boolean) => creatures.filter(keep).map((cr) => cr.id)
const filtered = (patch: Partial<sel.RosterFilter>) => idsOf(sel.filterRoster(views, { ...sel.NO_FILTER, ...patch }))

describe('the test roster', () => {
  it('is 100+ creatures that cover every type, hybrid, rarity, form, shiny and both work states', () => {
    expect(creatures.length).toBeGreaterThanOrEqual(100)
    expect(views).toHaveLength(creatures.length)
    for (const t of content.types) expect(creatures.some((cr) => def(cr).types.length === 1 && def(cr).types[0] === t.id), t.id).toBe(true)
    expect(creatures.filter((cr) => cr.isHybrid).length).toBeGreaterThan(10)
    for (const r of content.rarities) expect(creatures.some((cr) => cr.rarityTier === r.tier), r.name).toBe(true)
    for (const f of [1, 2, 3]) expect(creatures.some((cr) => cr.form === f), `form ${f}`).toBe(true)
    expect(creatures.some((cr) => cr.shiny) && creatures.some((cr) => !cr.shiny)).toBe(true)
    expect(creatures.some((cr) => cr.assignment) && creatures.some((cr) => !cr.assignment)).toBe(true)
    expect(creatures.some((cr) => cr.poolTraits.length === 3)).toBe(true)
  })

  it('is deterministic', () => {
    expect(rosterGame(120)).toEqual(game)
  })
})

describe('filterRoster', () => {
  it('no filter keeps everyone in the input order, in a new array', () => {
    const out = sel.filterRoster(views, sel.NO_FILTER)
    expect(out).toEqual(views)
    expect(out).not.toBe(views)
    expect(sel.isFiltered(sel.NO_FILTER)).toBe(false)
  })

  it.each(content.types.map((t) => t.id))('type %s: a hybrid matches either of its two types', (typeId) => {
    const got = filtered({ type: typeId })
    expect(got).toEqual(expected((cr) => def(cr).types.includes(typeId)))
    // ...and that includes hybrids on both sides of the pair.
    const hybridsOf = got.map((id) => creatures.find((cr) => cr.id === id)!).filter((cr) => cr.isHybrid)
    expect(hybridsOf.length).toBeGreaterThan(0)
    expect(new Set(hybridsOf.map((cr) => def(cr).types.find((t) => t !== typeId))).size, 'partners differ').toBeGreaterThan(1)
  })

  it('a hybrid shows up under both of its types and only those', () => {
    const hybrid = creatures.find((cr) => cr.isHybrid)!
    const [a, b] = def(hybrid).types as [string, string]
    const other = content.types.find((t) => t.id !== a && t.id !== b)!.id
    expect(filtered({ type: a })).toContain(hybrid.id)
    expect(filtered({ type: b })).toContain(hybrid.id)
    expect(filtered({ type: other })).not.toContain(hybrid.id)
  })

  it.each(content.rarities.map((r) => r.tier))('rarity tier %i', (tier) => {
    expect(filtered({ rarity: tier })).toEqual(expected((cr) => cr.rarityTier === tier))
  })

  it.each([1, 2, 3])('form %i', (form) => {
    expect(filtered({ form })).toEqual(expected((cr) => cr.form === form))
  })

  it('shiny: only shinies, or only the rest', () => {
    expect(filtered({ shiny: true })).toEqual(expected((cr) => cr.shiny))
    expect(filtered({ shiny: false })).toEqual(expected((cr) => !cr.shiny))
    expect(filtered({ shiny: true }).length + filtered({ shiny: false }).length).toBe(creatures.length)
  })

  it('working and benched split the roster exactly', () => {
    const working = filtered({ work: 'working' })
    const benched = filtered({ work: 'benched' })
    expect(working).toEqual(expected((cr) => cr.assignment !== null))
    expect(benched).toEqual(expected((cr) => cr.assignment === null))
    expect(working.length).toBeGreaterThan(0)
    expect(working.length + benched.length).toBe(creatures.length)
  })

  it.each(content.skills.map((s) => s.id))('can work %s follows the sim rule for every creature', (skillId) => {
    expect(filtered({ canWork: skillId })).toEqual(expected((cr) => canWork(cr, skillId)))
  })

  it('can work: a locked skill takes its type and hybrids covering it, an open skill takes everyone', () => {
    const wood = filtered({ canWork: 'woodcutting' })
    expect(wood.length).toBeGreaterThan(0)
    expect(wood.length).toBeLessThan(creatures.length)
    for (const id of wood) {
      const d = def(creatures.find((cr) => cr.id === id)!)
      expect(d.types.includes('verdant') || ('coveredSkills' in d && d.coveredSkills.includes('woodcutting')), d.id).toBe(true)
    }
    expect(filtered({ canWork: 'scavenging' })).toHaveLength(creatures.length)
  })

  it('combines filters with AND', () => {
    const f = { type: 'verdant', rarity: 3, work: 'benched' as const }
    expect(filtered(f)).toEqual(expected((cr) => def(cr).types.includes('verdant') && cr.rarityTier === 3 && cr.assignment === null))
    expect(sel.isFiltered({ ...sel.NO_FILTER, ...f })).toBe(true)
    // Every extra condition can only narrow it.
    expect(filtered({ ...f, shiny: true }).length).toBeLessThanOrEqual(filtered(f).length)
  })

  it('matches nothing when the conditions cannot all hold, without throwing', () => {
    expect(filtered({ type: 'no-such-type' })).toEqual([])
    expect(filtered({ rarity: 99 })).toEqual([])
    expect(filtered({ canWork: 'no-such-skill' })).toEqual([])
    expect(filtered({ form: 1, shiny: true, rarity: 9, work: 'working' }).every((id) => id.startsWith('creature-'))).toBe(true)
  })

  it('does not change what it was given', () => {
    const before = [...views]
    filtered({ type: 'void', shiny: true })
    expect(views).toEqual(before)
  })
})

describe('sortRoster', () => {
  const keys = sel.SORT_KEYS
  const combos = keys.flatMap((key) => (['asc', 'desc'] as const).map((dir) => ({ key, dir })))
  const seqOf = (v: { id: string }) => Number(v.id.replace('creature-', ''))

  /** The value a key sorts on, from the game state rather than the views. */
  const keyValue = (cr: Creature, key: sel.SortKey): number | string => {
    switch (key) {
      case 'rarity':
        return cr.rarityTier
      case 'level':
        return cr.level
      case 'form':
        return cr.form
      case 'name':
        return def(cr).forms[cr.form - 1]!.name.toLowerCase()
      case 'type':
        return def(cr).types.map((t) => content.types.findIndex((x) => x.id === t)).join(',')
    }
  }

  // A deterministic shuffle, so the input order is nothing like the creature order.
  const shuffled = <T>(list: readonly T[], mul: number): T[] => list.map((v, i) => ({ v, k: (i * mul) % 1009 })).sort((a, b) => a.k - b.k).map((x) => x.v)

  it.each(combos)('$key $dir: monotonic on the key, and ties keep creature sequence order', ({ key, dir }) => {
    const out = sel.sortRoster(views, { key, dir })
    expect(out).toHaveLength(views.length)
    expect(new Set(idsOf(out)).size).toBe(views.length)
    for (let i = 1; i < out.length; i++) {
      const a = creatures.find((cr) => cr.id === out[i - 1]!.id)!
      const b = creatures.find((cr) => cr.id === out[i]!.id)!
      if (key === 'type') continue // checked below with an explicit rank
      const [x, y] = [keyValue(a, key), keyValue(b, key)]
      if (x === y) expect(seqOf(out[i - 1]!), `tie at ${i}`).toBeLessThan(seqOf(out[i]!))
      else expect((x < y ? -1 : 1) * (dir === 'asc' ? 1 : -1), `order at ${i}`).toBe(-1)
    }
  })

  it.each(combos)('$key $dir: the same creatures always come out in the same order, whatever order they went in', ({ key, dir }) => {
    const reference = idsOf(sel.sortRoster(views, { key, dir }))
    for (const mul of [7, 31, 113, 509]) expect(idsOf(sel.sortRoster(shuffled(views, mul), { key, dir })), `shuffle ${mul}`).toEqual(reference)
  })

  it('a tie is broken by sequence number ascending even when the key runs descending', () => {
    const desc = sel.sortRoster(views, { key: 'rarity', dir: 'desc' })
    const tier = (v: sel.CreatureView) => v.rarity.tier
    const top = desc.filter((v) => tier(v) === 9)
    expect(top.length).toBeGreaterThan(2)
    expect(top.map(seqOf)).toEqual([...top.map(seqOf)].sort((a, b) => a - b))
  })

  it('rarity puts the best first when descending, level and form likewise', () => {
    expect(sel.sortRoster(views, { key: 'rarity', dir: 'desc' })[0]!.rarity.tier).toBe(content.rarities.length)
    expect(sel.sortRoster(views, { key: 'rarity', dir: 'asc' })[0]!.rarity.tier).toBe(1)
    expect(sel.sortRoster(views, { key: 'level', dir: 'desc' })[0]!.level).toBe(Math.max(...creatures.map((cr) => cr.level)))
    expect(sel.sortRoster(views, { key: 'form', dir: 'desc' })[0]!.form).toBe(3)
  })

  it('name sorts A to Z by the name shown, ignoring case', () => {
    const names = sel.sortRoster(views, { key: 'name', dir: 'asc' }).map((v) => v.name)
    expect(names).toEqual([...names].sort((a, b) => a.localeCompare(b, 'en', { sensitivity: 'base' })))
    const down = sel.sortRoster(views, { key: 'name', dir: 'desc' }).map((v) => v.name)
    expect(down).toEqual([...down].sort((a, b) => b.localeCompare(a, 'en', { sensitivity: 'base' })))
  })

  it('type sorts by the data order of the first type, and a pure type comes before its hybrids', () => {
    const out = sel.sortRoster(views, { key: 'type', dir: 'asc' })
    const first = out.map((v) => v.types[0]!.order)
    expect(first).toEqual([...first].sort((a, b) => a - b))
    for (let i = 1; i < out.length; i++) {
      if (out[i - 1]!.types[0]!.id !== out[i]!.types[0]!.id) continue
      expect((out[i - 1]!.types[1]?.order ?? -1) <= (out[i]!.types[1]?.order ?? -1), `${out[i - 1]!.id} then ${out[i]!.id}`).toBe(true)
    }
    // Verdant is first in types.json, so it opens the list.
    expect(out[0]!.types[0]!.id).toBe(content.types[0]!.id)
  })

  it('returns a new array and leaves the input alone', () => {
    const before = [...views]
    const out = sel.sortRoster(views, { key: 'level', dir: 'asc' })
    expect(out).not.toBe(views)
    expect(views).toEqual(before)
  })

  it('opens each key in its natural direction', () => {
    expect(sel.defaultDirection('rarity')).toBe('desc')
    expect(sel.defaultDirection('level')).toBe('desc')
    expect(sel.defaultDirection('form')).toBe('desc')
    expect(sel.defaultDirection('name')).toBe('asc')
    expect(sel.defaultDirection('type')).toBe('asc')
    expect(sel.DEFAULT_SORT).toEqual({ key: 'rarity', dir: 'desc' })
  })
})

describe('arrangeRoster', () => {
  it('filters, then sorts what is left', () => {
    const filter = { ...sel.NO_FILTER, type: 'aqueous', shiny: false }
    const out = sel.arrangeRoster(views, filter, { key: 'level', dir: 'desc' })
    expect(idsOf(out)).toEqual(idsOf(sel.sortRoster(sel.filterRoster(views, filter), { key: 'level', dir: 'desc' })))
    expect(out.length).toBeGreaterThan(0)
    expect(out.length).toBeLessThan(views.length)
    expect(out.every((v) => v.types.some((t) => t.id === 'aqueous') && !v.shiny)).toBe(true)
  })

  it('gives an empty list, not an error, when nothing matches', () => {
    expect(sel.arrangeRoster(views, { ...sel.NO_FILTER, rarity: 99 }, sel.DEFAULT_SORT)).toEqual([])
    expect(sel.arrangeRoster([], sel.NO_FILTER, sel.DEFAULT_SORT)).toEqual([])
  })
})

// ---------- the roster must not re-render on the 100 ms tick ----------
// React re-renders a component when a value its hook selected changes by identity. The roster screen selects the list of
// creature views, and each card gets one view, so what has to hold is: a tick (or any step) that only moves slot progress,
// resources, XP or Aether hands back the very same objects.

describe('the roster is identity-stable through ticks', () => {
  /** The real store, real driver and real actions around the 121-creature roster, with a clock the test moves. */
  function live() {
    const env = new FakeEnv()
    flushSave(env.storage, game, NOW)
    const store = createGameStore(loadGame(env.storage, NOW, 1))
    expect(store.getState().loadReport.isNewGame, 'the roster saved and loaded').toBe(false)
    const driver = createTickDriver(store, env)
    const actions = createActions(store, driver, env.storage)
    driver.start()
    const tick = (ms = content.tuning.ui.tickMs): void => {
      env.clock += ms
      env.fire(content.tuning.ui.tickMs)
    }
    return { env, store, actions, tick }
  }

  it('a tick changes progress, resources and XP but not one creature-related value', () => {
    const { store, tick } = live()
    const before = store.getState()
    const listBefore = sel.selectCreatureViews(before)
    const viewsBefore = before.game.creatures.map((cr) => sel.selectCreatureView(before, cr.id))

    for (let i = 0; i < 3; i++) tick()
    expect(sel.selectSlotProgress(store.getState(), 'woodcutting', 0), 'a bar moved').toBeGreaterThan(0)
    for (let i = 0; i < 57; i++) tick() // six seconds in all: at least one action finished in every working slot

    const after = store.getState()
    // The premise: the tick really did change what it is meant to.
    expect(after.game).not.toBe(before.game)
    expect(after.game.resources).not.toEqual(before.game.resources)
    expect(after.game.skills.woodcutting!.xp).toBeGreaterThan(before.game.skills.woodcutting!.xp)
    // The claim: nothing the roster selected changed by identity.
    expect(after.game.creatures).toBe(before.game.creatures)
    expect(sel.selectCreatureViews(after)).toBe(listBefore)
    after.game.creatures.forEach((cr, i) => expect(sel.selectCreatureView(after, cr.id), cr.id).toBe(viewsBefore[i]))
    const arranged = (s: GameStore) => sel.arrangeRoster(sel.selectCreatureViews(s), sel.NO_FILTER, sel.DEFAULT_SORT)
    expect(arranged(after)).toEqual(arranged(before))
  })

  it('so does a long catch-up step, and the assign menu selectors', () => {
    const { store, tick } = live()
    const before = store.getState()
    tick(3 * HOUR)
    const after = store.getState()
    expect(after.game.resources).not.toEqual(before.game.resources)
    expect(sel.selectCreatureViews(after)).toBe(sel.selectCreatureViews(before))
    for (let slot = 0; slot < sel.selectSlotCount(after, 'woodcutting'); slot++) {
      expect(sel.selectSlotCreatureId(after, 'woodcutting', slot)).toBe(sel.selectSlotCreatureId(before, 'woodcutting', slot))
      expect(sel.selectSlotAssignResourceId(after, 'woodcutting', slot)).toBe(sel.selectSlotAssignResourceId(before, 'woodcutting', slot))
    }
    expect(sel.selectSlotCount(after, 'woodcutting')).toBe(sel.selectSlotCount(before, 'woodcutting'))
  })

  it('the moment the player acts is the opposite: only the creatures the move touched get a new view', () => {
    const { store, actions } = live()
    const before = store.getState()
    const viewsBefore = new Map(sel.selectCreatureViews(before).map((v) => [v.id, v]))
    const benched = sel.selectCreatureViews(before).find((v) => !v.working && v.assignableSkillIds.includes('woodcutting'))!
    const occupant = sel.selectSlotCreatureId(before, 'woodcutting', 0)!

    // The roster's own move: put a benched creature into slot 1, replacing whoever is there.
    expect(actions.assignCreature(benched.id, 'woodcutting', 0, sel.selectSlotAssignResourceId(before, 'woodcutting', 0)!)).toEqual({ ok: true })

    const after = store.getState()
    const list = sel.selectCreatureViews(after)
    expect(list).not.toBe(sel.selectCreatureViews(before))
    const changed = list.filter((v) => v !== viewsBefore.get(v.id)).map((v) => v.id)
    expect(changed.sort()).toEqual([benched.id, occupant].sort())
    expect(list.find((v) => v.id === benched.id)!.workingAt).toBe('Woodcutting, slot 1')
    expect(list.find((v) => v.id === occupant)!.workingAt).toBeNull()

    // ...and unassigning changes only that creature.
    const mid = new Map(list.map((v) => [v.id, v]))
    actions.unassignCreature(benched.id)
    const end = sel.selectCreatureViews(store.getState())
    expect(end.filter((v) => v !== mid.get(v.id)).map((v) => v.id)).toEqual([benched.id])
  })
})

describe('toggleBenched (the Nexus page\'s bench strip)', () => {
  it('sets the Benched filter, keeps every other field, and takes it off again on a second click', () => {
    const on = sel.toggleBenched(sel.NO_FILTER)
    expect(on).toEqual({ ...sel.NO_FILTER, work: 'benched' })
    expect(sel.toggleBenched(on)).toEqual(sel.NO_FILTER)

    const busy = { ...sel.NO_FILTER, type: 'verdant', shiny: true, canWork: 'woodcutting' }
    expect(sel.toggleBenched(busy)).toEqual({ ...busy, work: 'benched' })
    expect(sel.toggleBenched(sel.toggleBenched(busy))).toEqual(busy)
  })

  it('switches a Working filter straight to Benched instead of clearing it', () => {
    expect(sel.toggleBenched({ ...sel.NO_FILTER, work: 'working' }).work).toBe('benched')
  })

  it('does not change the filter it was given', () => {
    const f = { ...sel.NO_FILTER }
    sel.toggleBenched(f)
    expect(f).toEqual(sel.NO_FILTER)
  })

  it('lists exactly the creatures the strip counts as benched', () => {
    const s = view(game)
    const listed = sel.arrangeRoster(sel.selectCreatureViews(s), sel.toggleBenched(sel.NO_FILTER), sel.DEFAULT_SORT)
    expect(listed.map((v) => v.id).sort()).toEqual(sel.selectBenchEntries(s).map((e) => e.view.id).sort())
    expect(listed.length).toBe(sel.selectBenchRates(s).size)
  })
})
