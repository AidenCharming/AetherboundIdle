import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { creatureCooldown } from '../src/sim/creature'
import { applyOffline } from '../src/sim/offline'
import { step } from '../src/sim/tick'
import * as sel from '../src/state/selectors'
import { createGameStore, type GameStore } from '../src/state/store'
import { loadGame } from '../src/state/persistence'
import type { GameState } from '../src/types/state'
import { addCreature, MemoryStorage, newGame, NOW, pool, setSkillLevel, sproutletAtWork, work } from './helpers'

/** A store snapshot around any GameState: selectors take a GameStore, and this is what the hook feeds them. */
const view = (game: GameState, extra: Partial<GameStore> = {}): GameStore => {
  const store = createGameStore(loadGame(new MemoryStorage(), NOW, 1))
  return { ...store.getState(), game, ...extra }
}

const OAK_MS = content.resourceById.get('oak-log')!.baseActionMs!
const at = (game: GameState, ms: number): GameState => step(game, ms).state

describe('top bar', () => {
  it('floors Aether for display and never touches the stored value', () => {
    const game = { ...newGame(), aether: 12.9 }
    expect(sel.selectAetherDisplay(view(game))).toBe(12)
    expect(game.aether).toBe(12.9)
    expect(sel.selectAetherDisplay(view({ ...game, aether: 0.4 }))).toBe(0)
  })

  it('shows gold as stored', () => {
    expect(sel.selectGold(view({ ...newGame(), gold: 37 }))).toBe(37)
  })

  it('lists held resources in the data order, skipping empty ones, and keeps unknown ids last', () => {
    const game = { ...newGame(), resources: { 'yew-log': 2, 'oak-log': 5, 'willow-log': 0, 'verdant-seedcache': 1, 'removed-thing': 4 } }
    expect(sel.selectHeldResourceIds(view(game))).toEqual(['oak-log', 'yew-log', 'verdant-seedcache', 'removed-thing'])
    expect(sel.selectHeldResourceIds(view(newGame()))).toEqual([])
  })

  it('reads a quantity, defaulting to 0', () => {
    const game = { ...newGame(), resources: { 'oak-log': 5 } }
    expect(sel.selectResourceQty(view(game), 'oak-log')).toBe(5)
    expect(sel.selectResourceQty(view(game), 'yew-log')).toBe(0)
  })
})

describe('skills', () => {
  it('slot count follows the skill level: 1 at level 1, then the data thresholds', () => {
    const unlocks = content.skillById.get('woodcutting')!.slotUnlockLevels
    const game = newGame()
    expect(sel.selectSlotCount(view(game), 'woodcutting')).toBe(1)
    unlocks.forEach((level, i) => {
      expect(sel.selectSlotCount(view(setSkillLevel(game, 'woodcutting', level)), 'woodcutting'), `level ${level}`).toBe(i + 1)
      if (level > 1) expect(sel.selectSlotCount(view(setSkillLevel(game, 'woodcutting', level - 1)), 'woodcutting')).toBe(i)
    })
  })

  it('names the next slot level, and null once they are all open', () => {
    const game = newGame()
    expect(sel.selectNextSlotLevel(view(game), 'woodcutting')).toBe(20)
    expect(sel.selectNextSlotLevel(view(setSkillLevel(game, 'woodcutting', 20)), 'woodcutting')).toBe(40)
    expect(sel.selectNextSlotLevel(view(setSkillLevel(game, 'woodcutting', 90)), 'woodcutting')).toBeNull()
  })

  it('locks a tier until the skill reaches its level, straight from the data', () => {
    const game = newGame()
    const locked = (g: GameState) => ['oak-log', 'willow-log', 'yew-log'].map((id) => !sel.selectResourceUnlocked(view(g), 'woodcutting', id))
    expect(locked(game)).toEqual([false, true, true])
    expect(locked(setSkillLevel(game, 'woodcutting', 14))).toEqual([false, true, true])
    expect(locked(setSkillLevel(game, 'woodcutting', 15))).toEqual([false, false, true])
    expect(locked(setSkillLevel(game, 'woodcutting', 30))).toEqual([false, false, false])
    expect(sel.resourceInfo('willow-log').requiredLevel).toBe(15)
    expect(sel.resourceInfo('yew-log').requiredLevel).toBe(30)
  })

  it('never unlocks something that is not gatherable', () => {
    expect(sel.selectResourceUnlocked(view(newGame()), 'woodcutting', 'verdant-seedcache')).toBe(false)
    expect(sel.selectResourceUnlocked(view(newGame()), 'woodcutting', 'no-such-thing')).toBe(false)
  })

  it('picks the lowest unlocked resource for an empty slot', () => {
    expect(sel.selectDefaultResourceId(view(newGame()), 'woodcutting')).toBe('oak-log')
  })

  it('reports XP inside the level and what the level takes; null to-next at the cap', () => {
    const game = newGame()
    expect(sel.selectSkillXpInLevel(view(game), 'woodcutting')).toBe(0)
    expect(sel.selectSkillXpToNext(view(game), 'woodcutting')).toBe(content.tuning.xp.skillCurve.base)

    const worked = at(sproutletAtWork(), 5 * OAK_MS) // 5 actions: 50 xp
    expect(sel.selectSkillXpInLevel(view(worked), 'woodcutting')).toBe(50)
    expect(sel.selectSkillLevel(view(worked), 'woodcutting')).toBe(1)

    const top = setSkillLevel(game, 'woodcutting', 99)
    expect(sel.selectSkillXpToNext(view(top), 'woodcutting')).toBeNull()
  })

  it('offers only skills that have something to gather, and their resources lowest level first', () => {
    expect(sel.gatherableSkillIds).toContain('woodcutting')
    expect(sel.gatherableSkillIds).not.toContain('mining') // no Mining content yet
    expect(sel.gatherableResourceIds('woodcutting')).toEqual(['oak-log', 'willow-log', 'yew-log'])
    expect(sel.gatherableResourceIds('mining')).toEqual([])
  })

  it('shows each resource with the emoji from the data, or null so the UI falls back to a dot', () => {
    for (const r of content.resources) expect(sel.resourceInfo(r.id).emoji, r.id).toBe(r.emoji)
    expect(sel.resourceInfo('oak-log').emoji).toBeTruthy()
    expect(sel.resourceInfo('verdant-seedcache').emoji).toBeTruthy()
    expect(sel.resourceInfo('no-such-thing').emoji).toBeNull()
  })

  it('takes colors from the data, not from the components', () => {
    expect(sel.skillInfo('woodcutting').color).toBe(content.typeById.get('verdant')!.color)
    expect(sel.skillInfo('scavenging').color).toBeNull() // an open skill has no type
    expect(sel.resourceInfo('oak-log').color).toBe(content.typeById.get('verdant')!.color)
  })
})

describe('slots', () => {
  it('progress is progressMs / cooldown, and the cooldown comes from the creature', () => {
    const game = at(sproutletAtWork(), OAK_MS / 2)
    expect(sel.selectSlotCooldownMs(view(game), 'woodcutting', 0)).toBe(OAK_MS)
    expect(sel.selectSlotProgress(view(game), 'woodcutting', 0)).toBeCloseTo(0.5, 10)
  })

  it('uses the real cooldown for a creature with a better rarity', () => {
    const base = newGame()
    const { state, creature } = addCreature(base, 'sproutlet', { rarityTier: 3, level: 10 })
    const game = work(state, creature.id)
    const expected = creatureCooldown(creature, 'woodcutting', OAK_MS, [{ creature, skillId: 'woodcutting' }]).cooldownMs
    expect(expected).toBeLessThan(OAK_MS)
    expect(sel.selectSlotCooldownMs(view(game), 'woodcutting', 0)).toBe(expected)
    const half = at(game, expected / 2)
    expect(sel.selectSlotProgress(view(half), 'woodcutting', 0)).toBeCloseTo(0.5, 10)
  })

  it('is 0 and null for an empty slot', () => {
    expect(sel.selectSlotProgress(view(newGame()), 'woodcutting', 0)).toBe(0)
    expect(sel.selectSlotCooldownMs(view(newGame()), 'woodcutting', 0)).toBeNull()
    expect(sel.selectSlotCreatureId(view(newGame()), 'woodcutting', 0)).toBeNull()
    expect(sel.selectSlotResourceId(view(newGame()), 'woodcutting', 0)).toBeNull()
  })

  it('is idle (0 and null) when the sim would idle the slot: the resource is above the skill level', () => {
    const game = sproutletAtWork()
    const idle: GameState = {
      ...game,
      skills: { ...game.skills, woodcutting: { ...game.skills.woodcutting!, slots: [{ creatureId: 'creature-1', resourceId: 'yew-log', progressMs: 900 }] } },
    }
    expect(sel.selectSlotProgress(view(idle), 'woodcutting', 0)).toBe(0)
    expect(sel.selectSlotCooldownMs(view(idle), 'woodcutting', 0)).toBeNull()
    // and the sim agrees: stepping it changes no progress
    expect(at(idle, OAK_MS).skills.woodcutting!.slots[0]!.progressMs).toBe(900)
  })

  it('never reads above 1, even if a cooldown shrank under a slot that was already part-way', () => {
    const game = sproutletAtWork()
    const past: GameState = {
      ...game,
      skills: { ...game.skills, woodcutting: { ...game.skills.woodcutting!, slots: [{ creatureId: 'creature-1', resourceId: 'oak-log', progressMs: OAK_MS * 5 }] } },
    }
    expect(sel.selectSlotProgress(view(past), 'woodcutting', 0)).toBe(1)
  })

  it('progress falls back near 0 when an action completes (the bar wraps once per cycle, not per frame)', () => {
    let game = sproutletAtWork()
    const series: number[] = []
    for (let i = 0; i < 40; i++) {
      game = at(game, 100)
      series.push(sel.selectSlotProgress(view(game), 'woodcutting', 0))
    }
    const drops = series.filter((v, i) => i > 0 && v < series[i - 1]!)
    expect(drops).toHaveLength(Math.floor(4000 / OAK_MS)) // 4 s of 100 ms ticks: one wrap
    expect(series.every((v) => v >= 0 && v < 1)).toBe(true)
  })
})

describe('creatures', () => {
  it('shows the name and emoji of the current form, and the type color from the data', () => {
    const v = sel.selectCreatureView(view(newGame()), 'creature-1')!
    expect(v).toMatchObject({ id: 'creature-1', name: 'Sproutlet', emoji: '🌱', level: 1, workingAt: null })
    expect(v.color).toBe(content.typeById.get('verdant')!.color)
    expect(sel.selectCreatureView(view(newGame()), 'nobody')).toBeNull()
  })

  it('shows where a working creature is', () => {
    expect(sel.selectCreatureView(view(sproutletAtWork()), 'creature-1')!.workingAt).toBe('Woodcutting, slot 1')
  })

  it('the view carries what a roster card needs: species, types, rarity frame, form, shiny, lean, skills, traits', () => {
    const base = newGame()
    const { state } = addCreature(base, 'sproutlet', {
      rarityTier: 6,
      level: 34,
      form: 2,
      shiny: true,
      poolTraits: [pool('vitality', 'major'), pool('night-owl', 'minor')],
    })
    const v = sel.selectCreatureView(view(state), 'creature-2')!
    const rarity = content.rarities[5]!
    expect(v).toMatchObject({
      id: 'creature-2',
      seq: 2,
      name: 'Timberhorn', // the form's name...
      speciesName: 'Sproutlet', // ...and the species it belongs to
      isHybrid: false,
      emoji: '🦌',
      form: 2,
      level: 34,
      shiny: true,
      statLean: 'guard',
      primarySkill: 'Woodcutting',
      secondaryAptitude: 'Scavenging',
      working: false,
      workingAt: null,
    })
    expect(v.rarity).toEqual({ tier: 6, id: rarity.id, name: rarity.name, tint: rarity.frame.tint, glow: rarity.frame.glow })
    expect(v.types.map((t) => t.id)).toEqual(['verdant'])
    expect(v.types[0]!.color).toBe(content.typeById.get('verdant')!.color)
    expect(v.signatureTrait).toMatchObject({ id: 'overgrowth', name: content.traitById.get('overgrowth')!.name, strength: 'moderate' })
    expect(v.poolTraits.map((t) => [t.id, t.name, t.strength])).toEqual([
      ['vitality', content.traitById.get('vitality')!.name, 'major'],
      ['night-owl', content.traitById.get('night-owl')!.name, 'minor'],
    ])
    expect(v.poolTraits.every((t) => t.text.length > 0)).toBe(true)
  })

  it('a hybrid shows both of its types, in the data order, and its own species name', () => {
    const hybrid = content.hybrids[0]!
    const { state } = addCreature(newGame(), hybrid.id, { isHybrid: true })
    const v = sel.selectCreatureView(view(state), 'creature-2')!
    expect(v.isHybrid).toBe(true)
    expect(v.speciesName).toBe(hybrid.name)
    expect(v.types.map((t) => t.id)).toEqual([...hybrid.types])
    expect(v.types).toHaveLength(2)
    expect(v.types.map((t) => t.color)).toEqual(hybrid.types.map((t) => content.typeById.get(t)!.color))
    expect(v.color).toBe(v.types[0]!.color) // the single "color" is still the first type's
    expect(v.primarySkill).toBe(content.skillById.get(hybrid.primarySkill)!.name)
  })

  it('takes each rarity frame from rarities.json and shows an unknown tier plainly rather than breaking', () => {
    content.rarities.forEach((r) => {
      const { state } = addCreature(newGame(), 'sproutlet', { rarityTier: r.tier })
      expect(sel.selectCreatureView(view(state), 'creature-2')!.rarity).toEqual({ tier: r.tier, id: r.id, name: r.name, tint: r.frame.tint, glow: r.frame.glow })
    })
    const { state } = addCreature(newGame(), 'sproutlet', { rarityTier: 99 })
    expect(sel.selectCreatureView(view(state), 'creature-2')!.rarity).toMatchObject({ tier: 99, glow: 0 })
  })

  it('says which skills a creature can work (the sim rule) and which of those can be assigned now', () => {
    const { state } = addCreature(addCreature(newGame(), 'cinderpup').state, content.hybrids.find((h) => h.coveredSkills.includes('woodcutting'))!.id, { isHybrid: true })
    const [starter, pyric, hybrid] = state.creatures.map((cr) => sel.selectCreatureView(view(state), cr.id)!)
    expect(starter!.workableSkillIds).toEqual(expect.arrayContaining(['woodcutting', 'herbalism', 'scavenging', 'fabrication']))
    expect(starter!.workableSkillIds).not.toContain('mining')
    expect(pyric!.workableSkillIds).not.toContain('woodcutting')
    expect(hybrid!.workableSkillIds).toContain('woodcutting')
    // Only Woodcutting has anything to gather in phase 1, so only that can be assigned.
    expect(starter!.assignableSkillIds).toEqual(['woodcutting'])
    expect(pyric!.assignableSkillIds).toEqual([])
    expect(hybrid!.assignableSkillIds).toEqual(['woodcutting'])
  })

  it('says a working creature is working, and where', () => {
    const v = sel.selectCreatureView(view(sproutletAtWork()), 'creature-1')!
    expect(v.working).toBe(true)
    expect(v.workingAt).toBe('Woodcutting, slot 1')
  })

  it('exposes the shiny hue and the roster vocabulary straight from the data', () => {
    expect(sel.shinyHueDeg).toBe(content.tuning.ui.shinyHueDeg)
    expect(sel.typeOptions.map((t) => t.id)).toEqual(content.types.map((t) => t.id))
    expect(sel.typeOptions.map((t) => t.order)).toEqual(content.types.map((_, i) => i))
    expect(sel.rarityOptions.map((r) => r.name)).toEqual(content.rarities.map((r) => r.name))
    expect(sel.skillOptions.map((k) => k.id)).toEqual(content.skills.map((k) => k.id))
    expect(sel.formNumbers).toEqual([1, 2, 3])
  })

  it('picks the resource a roster assignment gathers: the slot own resource, else the lowest unlocked tier', () => {
    expect(sel.selectSlotAssignResourceId(view(newGame()), 'woodcutting', 0)).toBe('oak-log')
    const onYew = work(setSkillLevel(newGame(), 'woodcutting', 30), 'creature-1', 'woodcutting', 0, 'yew-log')
    expect(sel.selectSlotAssignResourceId(view(onYew), 'woodcutting', 0)).toBe('yew-log')
    // Level 30 opens a second slot. It is empty, so it starts on the lowest tier, not on the yew of the first slot.
    expect(sel.selectSlotAssignResourceId(view(onYew), 'woodcutting', 1)).toBe('oak-log')
  })

  it('lists who can go in a slot: skill-capable creatures not already in it', () => {
    const empty = newGame()
    expect(sel.selectAssignableCreatureIds(view(empty), 'woodcutting', 0)).toEqual(['creature-1'])
    expect(sel.selectAssignableCreatureIds(view(sproutletAtWork()), 'woodcutting', 0)).toEqual([])

    const { state } = addCreature(empty, 'cinderpup') // Pyric: cannot cut wood
    expect(sel.selectAssignableCreatureIds(view(state), 'woodcutting', 0)).toEqual(['creature-1'])
  })
})

describe('load notice', () => {
  it('shows a quarantine notice until dismissed', () => {
    const notice = { kind: 'quarantined' as const, reason: 'corrupt' as const, message: 'bad save', brokenKey: 'k' }
    const base = view(newGame())
    const s = { ...base, loadReport: { ...base.loadReport, notice } }
    expect(sel.selectQuarantineNotice(s)).toBe(notice)
    expect(sel.selectQuarantineNotice({ ...s, noticeDismissed: true })).toBeNull()
    expect(sel.selectQuarantineNotice(base)).toBeNull()
  })
})

// Zustand v5 loops forever on a selector that returns a new object or array on every call for the same state.
// So every selector must give the SAME answer (by identity) twice in a row, and the ones that build lists must
// also keep it across states that differ but yield an equal list.
describe('selectors are safe for zustand v5 (stable references)', () => {
  const calls: [string, (s: GameStore) => unknown][] = [
    ['gold', sel.selectGold],
    ['aether', sel.selectAetherDisplay],
    ['held', sel.selectHeldResourceIds],
    ['qty', (s) => sel.selectResourceQty(s, 'oak-log')],
    ['notice', sel.selectQuarantineNotice],
    ['level', (s) => sel.selectSkillLevel(s, 'woodcutting')],
    ['xp', (s) => sel.selectSkillXpInLevel(s, 'woodcutting')],
    ['xpNext', (s) => sel.selectSkillXpToNext(s, 'woodcutting')],
    ['slots', (s) => sel.selectSlotCount(s, 'woodcutting')],
    ['nextSlot', (s) => sel.selectNextSlotLevel(s, 'woodcutting')],
    ['unlocked', (s) => sel.selectResourceUnlocked(s, 'woodcutting', 'willow-log')],
    ['default', (s) => sel.selectDefaultResourceId(s, 'woodcutting')],
    ['slotCreature', (s) => sel.selectSlotCreatureId(s, 'woodcutting', 0)],
    ['slotResource', (s) => sel.selectSlotResourceId(s, 'woodcutting', 0)],
    ['cooldown', (s) => sel.selectSlotCooldownMs(s, 'woodcutting', 0)],
    ['progress', (s) => sel.selectSlotProgress(s, 'woodcutting', 0)],
    ['creature', (s) => sel.selectCreatureView(s, 'creature-1')],
    ['creatures', sel.selectCreatureViews],
    ['assignResource', (s) => sel.selectSlotAssignResourceId(s, 'woodcutting', 0)],
    ['assignable', (s) => sel.selectAssignableCreatureIds(s, 'woodcutting', 0)],
    ['setting', (s) => sel.selectSetting(s, 'offlineSummary')],
    ['dev', sel.selectDevPanelEnabled],
    ['welcomeBack', sel.selectWelcomeBack],
  ]

  it.each(calls)('%s returns the same value for the same state', (_name, select) => {
    for (const game of [newGame(), sproutletAtWork(), at(sproutletAtWork(), 4500)]) {
      const s = view(game)
      expect(Object.is(select(s), select(s))).toBe(true)
    }
  })

  it('the held list and the creature view survive ticks that change nothing they show', () => {
    const game = { ...sproutletAtWork(), resources: { 'oak-log': 3 } }
    const before = view(game)
    const after = view(at(game, 100)) // a tick: new state, new skills object, new resources object
    expect(after.game.resources).not.toBe(before.game.resources)
    expect(sel.selectHeldResourceIds(after)).toBe(sel.selectHeldResourceIds(before))
    expect(sel.selectCreatureView(after, 'creature-1')).toBe(sel.selectCreatureView(before, 'creature-1'))
    expect(sel.selectAssignableCreatureIds(after, 'woodcutting', 0)).toBe(sel.selectAssignableCreatureIds(before, 'woodcutting', 0))
  })

  it('the held list changes identity when what is held changes', () => {
    const a = sel.selectHeldResourceIds(view({ ...newGame(), resources: { 'oak-log': 1 } }))
    const b = sel.selectHeldResourceIds(view({ ...newGame(), resources: { 'oak-log': 1, 'yew-log': 1 } }))
    expect(b).not.toBe(a)
    expect(b).toEqual(['oak-log', 'yew-log'])
  })
})

// ---------- step 1.8a: settings and the welcome-back view ----------

describe('settings', () => {
  it('reads each setting, and the Dev tab follows devPanelEnabled', () => {
    const game = newGame()
    expect(sel.selectSetting(view(game), 'offlineSummary')).toBe(true)
    expect(sel.selectSetting(view(game), 'devPanelEnabled')).toBe(false)
    expect(sel.selectDevPanelEnabled(view(game))).toBe(false)
    const on = { ...game, settings: { offlineSummary: false, devPanelEnabled: true } }
    expect(sel.selectSetting(view(on), 'offlineSummary')).toBe(false)
    expect(sel.selectDevPanelEnabled(view(on))).toBe(true)
  })
})

describe('the welcome-back view', () => {
  /** A real summary: `hours` away with the Sproutlet on oak, through the sim, not hand-built. */
  const summaryFor = (hours: number, game = sproutletAtWork()) => applyOffline(game, NOW + hours * 3_600_000).summary
  const wb = (hours: number, game?: GameState) => sel.selectWelcomeBack(view(game ?? sproutletAtWork(), { welcomeBack: summaryFor(hours, game) }))!

  it('is null when nothing is pending', () => {
    expect(sel.selectWelcomeBack(view(newGame()))).toBeNull()
  })

  it('reports the time away, the time earned and the cap as the sim measured them', () => {
    const v = wb(3)
    expect(v.awayMs).toBe(3 * 3_600_000)
    expect(v.earnedMs).toBe(3 * 3_600_000)
    expect(v.capped).toBe(false)
    expect(v.capMs).toBe(content.tuning.offline.capHours * 3_600_000)
  })

  it('separates time away from time earned when the cap bit', () => {
    const v = wb(100)
    expect(v.awayMs).toBe(100 * 3_600_000)
    expect(v.earnedMs).toBe(content.tuning.offline.capHours * 3_600_000)
    expect(v.capped).toBe(true)
  })

  it('never shows negative time away for a backwards clock', () => {
    const summary = applyOffline(sproutletAtWork(), NOW - 5 * 3_600_000).summary
    const v = sel.selectWelcomeBack(view(sproutletAtWork(), { welcomeBack: summary }))!
    expect(summary.requestedMs).toBeLessThan(0)
    expect(v.awayMs).toBe(0)
    expect(v.empty).toBe(true)
  })

  it('lists resources in the data order, with their name, emoji and color, and drops the empty ones', () => {
    const v = wb(3)
    expect(v.resources.map((r) => r.id)).toEqual(['oak-log', 'verdant-seedcache'])
    expect(v.resources.every((r) => r.qty > 0)).toBe(true)
    const oak = v.resources[0]!
    expect(oak.name).toBe(content.resourceById.get('oak-log')!.name)
    expect(oak.emoji).toBe(content.resourceById.get('oak-log')!.emoji)
    expect(oak.color).toBe(content.typeById.get(content.resourceById.get('oak-log')!.elementType!)!.color)
  })

  it('carries the summary numbers per skill, with 1-based slot numbers and the display name', () => {
    const summary = summaryFor(3)
    const v = wb(3)
    const raw = summary.skills.find((s) => s.skillId === 'woodcutting')!
    const shown = v.skills.find((s) => s.id === 'woodcutting')!
    expect(shown.name).toBe(content.skillById.get('woodcutting')!.name)
    expect(shown.color).toBe(content.typeById.get(content.skillById.get('woodcutting')!.requiredType!)!.color)
    expect(shown.actions).toBe(raw.actions)
    expect(shown.xpGained).toBe(raw.xpGained)
    expect(shown.levelBefore).toBe(raw.levelBefore)
    expect(shown.levelAfter).toBe(raw.levelAfter)
    expect(shown.levelAfter).toBeGreaterThan(shown.levelBefore)
    expect(shown.slotsUnlocked).toEqual(raw.slotsUnlocked.map((i) => i + 1)) // the player counts slots from 1
    expect(shown.slotsUnlocked).toContain(2)
  })

  it('floors the Aether gained for display only', () => {
    const benched = newGame() // the starter Sproutlet is on the bench, so it emits
    const summary = applyOffline(benched, NOW + 3 * 3_600_000 + 7_000).summary // a ragged window, so the total is fractional
    const v = sel.selectWelcomeBack(view(benched, { welcomeBack: summary }))!
    expect(summary.aetherGained % 1).not.toBe(0)
    expect(v.aetherGained).toBe(Math.floor(summary.aetherGained))
  })

  it('says so when nothing happened', () => {
    const idle: GameState = { ...newGame(), creatures: [] }
    const v = sel.selectWelcomeBack(view(idle, { welcomeBack: applyOffline(idle, NOW + 3 * 3_600_000).summary }))!
    expect(v.empty).toBe(true)
    expect(v.resources).toEqual([])
    expect(v.skills).toEqual([])
  })

  it('is the same object for the same summary, so the dialog is not rebuilt on every tick', () => {
    const summary = summaryFor(3)
    const s = view(sproutletAtWork(), { welcomeBack: summary })
    expect(sel.selectWelcomeBack(s)).toBe(sel.selectWelcomeBack(s))
    expect(sel.selectWelcomeBack({ ...s, game: at(s.game, 100) })).toBe(sel.selectWelcomeBack(s))
  })
})
