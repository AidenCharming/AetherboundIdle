import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { creatureCooldown } from '../src/sim/creature'
import { step } from '../src/sim/tick'
import * as sel from '../src/state/selectors'
import { createGameStore, type GameStore } from '../src/state/store'
import { loadGame } from '../src/state/persistence'
import type { GameState } from '../src/types/state'
import { addCreature, MemoryStorage, newGame, NOW, setSkillLevel, sproutletAtWork, work } from './helpers'

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
    ['assignable', (s) => sel.selectAssignableCreatureIds(s, 'woodcutting', 0)],
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
