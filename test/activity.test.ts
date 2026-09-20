import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { step } from '../src/sim/tick'
import { unassignCreature } from '../src/sim/skills'
import { loadGame } from '../src/state/persistence'
import { activityPanelMax, maxToasts, selectActivity, toastMs } from '../src/state/selectors'
import { createGameStore, type GameStore } from '../src/state/store'
import type { GameState } from '../src/types/state'
import { MemoryStorage, newGame, NOW, rosterGame, sproutletAtWork } from './helpers'

const view = (game: GameState): GameStore => ({ ...createGameStore(loadGame(new MemoryStorage(), NOW, 1)).getState(), game })
const keys = (game: GameState) => selectActivity(view(game)).map((a) => `${a.skillId}:${a.slotIndex}`)

describe('selectActivity (the sidebar\'s current activity list)', () => {
  it('is empty while nobody is working', () => {
    expect(keys(newGame())).toEqual([])
  })

  it('lists a working slot, and takes it off when the creature is unassigned', () => {
    const working = sproutletAtWork()
    expect(keys(working)).toEqual(['woodcutting:0'])
    expect(keys(unassignCreature(working, 'creature-1'))).toEqual([])
  })

  it('lists every working slot, skills in the data\'s order and slots ascending', () => {
    const game = rosterGame(60)
    const expected = game.skills.woodcutting!.slots.map((s, i) => (s ? `woodcutting:${i}` : null)).filter(Boolean)
    expect(expected.length).toBeGreaterThan(activityPanelMax) // enough to need "+N more"
    expect(keys(game)).toEqual(expected)
  })

  it('does not list a slot the sim would idle: a resource above the skill\'s level is not being worked', () => {
    const working = sproutletAtWork()
    const slot = working.skills.woodcutting!.slots[0]!
    expect(content.resourceById.get('willow-log')!.requiredSkillLevel!).toBeGreaterThan(working.skills.woodcutting!.level)
    const idle: GameState = { ...working, skills: { ...working.skills, woodcutting: { ...working.skills.woodcutting!, slots: [{ ...slot, resourceId: 'willow-log' }] } } }
    expect(keys(idle)).toEqual([])
  })

  it('keeps its identity through ticks, so the panel re-renders only when a slot starts or stops', () => {
    const game = sproutletAtWork()
    const first = selectActivity(view(game))
    let next = game
    for (let i = 0; i < 50; i++) next = step(next, 100).state // 5 s of ticks: progress moves, the set does not
    expect(next.skills.woodcutting!.slots[0]!.progressMs).not.toBe(game.skills.woodcutting!.slots[0]!.progressMs)
    expect(selectActivity(view(next))).toBe(first)
    expect(selectActivity(view(unassignCreature(next, 'creature-1')))).not.toBe(first)
  })

  it('gives the same slot the same object each time', () => {
    const a = selectActivity(view(sproutletAtWork()))[0]
    const b = selectActivity(view(step(sproutletAtWork(), 1000).state))[0]
    expect(a).toBe(b)
  })
})

describe('the notification UI numbers come from tuning.json', () => {
  it('are exposed to the UI as read from the data', () => {
    expect(activityPanelMax).toBe(content.tuning.ui.activityPanelMax)
    expect(maxToasts).toBe(content.tuning.ui.maxToasts)
    expect(toastMs).toBe(content.tuning.ui.toastMs)
  })
})
