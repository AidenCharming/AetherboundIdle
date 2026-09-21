import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { buildNav, flattenNav, resolvePage, selectNav, skillIdOfPage, skillPageId, type NavContent, type PageId } from '../src/state/selectors'
import type { GameStore } from '../src/state/store'
import { newGame, variant } from './helpers'

const ids = (nav: ReturnType<typeof buildNav>) => flattenNav(nav).map((e) => e.id)
const gameWith = (devPanelEnabled: boolean): GameStore => {
  const game = newGame()
  return { game: { ...game, settings: { ...game.settings, devPanelEnabled } } } as unknown as GameStore
}

describe('buildNav', () => {
  it('has Skills, Creatures and System, in that order, with the headings the designer named', () => {
    const nav = buildNav({ devPanelEnabled: false })
    expect(nav.map((s) => [s.id, s.heading])).toEqual([
      ['skills', 'Skills'],
      ['creatures', 'Creatures'],
      ['system', 'System'],
    ])
    expect(nav[1]!.entries.map((e) => e.id)).toEqual(['nexus'])
    expect(nav[2]!.entries.map((e) => e.id)).toEqual(['settings'])
  })

  it('has ONE creature page, and it is called Nexus (step 1.9d merged the Roster into it): the word Roster is nowhere in the nav', () => {
    const nav = buildNav({ devPanelEnabled: true })
    expect(nav[1]!.entries).toEqual([{ id: 'nexus', label: 'Nexus', icon: expect.any(String) }])
    for (const section of nav) {
      expect(section.heading).not.toMatch(/roster/i)
      for (const entry of section.entries) expect(`${entry.id} ${entry.label}`).not.toMatch(/roster/i)
    }
  })

  it('offers a page for every skill that has something to gather, and only those', () => {
    const gatherable = content.skills.filter((s) => content.resources.some((r) => r.kind === 'raw' && r.skill === s.id)).map((s) => skillPageId(s.id))
    expect(gatherable.length).toBeGreaterThan(0)
    expect(buildNav({ devPanelEnabled: false })[0]!.entries.map((e) => e.id)).toEqual(gatherable)
    expect(ids(buildNav({ devPanelEnabled: false }))).not.toContain('skill:mining')
  })

  it('is data-driven: a skill appears the moment the data gives it a raw resource, in skills.json order', () => {
    const c = variant((raw) => {
      raw.resources.push({
        id: 'copper-ore', name: 'Copper Ore', emoji: '🥉', tier: 1, skill: 'mining', kind: 'raw', elementType: 'telluric',
        requiredSkillLevel: 1, baseActionMs: 3000, xpPerAction: 10, goldValue: 1, rareDrop: null,
      })
    })
    const skills = buildNav({ devPanelEnabled: false }, c)[0]!
    expect(skills.entries.map((e) => e.id)).toEqual(['skill:woodcutting', 'skill:mining'])
    expect(skills.entries[1]).toMatchObject({ label: 'Mining', icon: c.skillById.get('mining')!.emoji })
  })

  it('does not count a resource that is only dropped, never gathered', () => {
    const c: NavContent = {
      skills: content.skills.filter((s) => s.id === 'herbalism'),
      resources: [{ ...content.resourceById.get('verdant-seedcache')!, skill: 'herbalism' }],
    }
    expect(content.resourceById.get('verdant-seedcache')!.kind).toBe('rare')
    expect(buildNav({ devPanelEnabled: false }, c).map((s) => s.id)).not.toContain('skills')
  })

  it('leaves out a section with nothing in it, so no heading stands over an empty list', () => {
    const nav = buildNav({ devPanelEnabled: false }, { skills: content.skills, resources: [] })
    expect(nav.map((s) => s.id)).toEqual(['creatures', 'system'])
  })

  it('shows Dev under System only while the setting is on', () => {
    expect(ids(buildNav({ devPanelEnabled: false }))).not.toContain('dev')
    const on = buildNav({ devPanelEnabled: true })
    expect(on[2]!.entries.map((e) => e.id)).toEqual(['settings', 'dev'])
    expect(on[1]!.entries.map((e) => e.id)).not.toContain('dev')
  })

  it("uses a skill's own emoji, and a plain glyph when the data has none", () => {
    const woodcutting = buildNav({ devPanelEnabled: false })[0]!.entries[0]!
    expect(woodcutting.icon).toBe(content.skillById.get('woodcutting')!.emoji)
    const bare = { ...content.skillById.get('woodcutting')!, emoji: undefined }
    const c: NavContent = { skills: [bare], resources: content.resources }
    expect(buildNav({ devPanelEnabled: false }, c)[0]!.entries[0]!.icon).toBe('◆')
  })

  it('gives every entry a distinct id, a label and an icon', () => {
    const all = flattenNav(buildNav({ devPanelEnabled: true }))
    expect(new Set(all.map((e) => e.id)).size).toBe(all.length)
    for (const e of all) {
      expect(e.label.length, e.id).toBeGreaterThan(0)
      expect(e.icon.length, e.id).toBeGreaterThan(0)
    }
  })

  it('reads nothing but its arguments: the same input gives an equal nav, and the input is not changed', () => {
    const input = { devPanelEnabled: true }
    const before = JSON.stringify(input)
    expect(buildNav(input)).toEqual(buildNav({ devPanelEnabled: true }))
    expect(JSON.stringify(input)).toBe(before)
  })
})

describe('page ids', () => {
  it('a skill page id round-trips, and the fixed pages belong to no skill', () => {
    expect(skillIdOfPage(skillPageId('aether-weaving'))).toBe('aether-weaving')
    for (const page of ['nexus', 'settings', 'dev'] as const) expect(skillIdOfPage(page)).toBeNull()
  })
})

describe('resolvePage', () => {
  const nav = buildNav({ devPanelEnabled: false })
  const withDev = buildNav({ devPanelEnabled: true })

  it('keeps a choice the nav offers', () => {
    expect(resolvePage(nav, 'nexus')).toBe('nexus')
    expect(resolvePage(nav, skillPageId('woodcutting'))).toBe('skill:woodcutting')
    expect(resolvePage(withDev, 'dev')).toBe('dev')
  })

  it('opens the first entry, a skill page, when nothing has been chosen', () => {
    expect(resolvePage(nav, null)).toBe(flattenNav(nav)[0]!.id)
    expect(resolvePage(nav, null)).toMatch(/^skill:/)
  })

  it('sends a player standing on Dev to Settings when the setting goes off', () => {
    expect(resolvePage(nav, 'dev')).toBe('settings')
  })

  it('falls back to the first entry for a page that no longer exists', () => {
    expect(resolvePage(nav, 'skill:no-such-skill')).toBe(flattenNav(nav)[0]!.id)
    // the old Roster page id is gone, and nothing in the UI state or the save can hold it, but it must not white-screen
    expect(resolvePage(nav, 'roster' as unknown as PageId)).toBe(flattenNav(nav)[0]!.id)
  })

  it('lands on the Nexus when the nav has no skill page at all', () => {
    const noSkills = buildNav({ devPanelEnabled: false }, { skills: content.skills, resources: [] })
    expect(resolvePage(noSkills, null)).toBe('nexus')
    expect(resolvePage([], null)).toBe('nexus')
  })
})

describe('selectNav', () => {
  it('is stable by identity, and changes only with the dev panel setting', () => {
    expect(selectNav(gameWith(false))).toBe(selectNav(gameWith(false)))
    expect(selectNav(gameWith(true))).toBe(selectNav(gameWith(true)))
    expect(ids(selectNav(gameWith(true)))).toContain('dev')
    expect(ids(selectNav(gameWith(false)))).not.toContain('dev')
  })

  it('which page is open is not part of the game state, so it cannot reach the save', () => {
    for (const k of Object.keys(newGame())) expect(k).not.toMatch(/page|nav|screen|tab/i)
  })
})
