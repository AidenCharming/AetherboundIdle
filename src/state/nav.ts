// The navigation model (step 1.9b): which pages the sidebar offers, in which sections, built from the data and the
// state. Pure, with no React and no store, so it is tested in node. Which page is OPEN is UI-local state and is not
// here, and not in the save.
import { content, type Content } from '../data'

/** `skill:<id>` for a skill's page, or one of the fixed pages. */
export type PageId = 'nexus' | 'settings' | 'dev' | `skill:${string}`

export interface NavEntry {
  id: PageId
  label: string
  /** An emoji (a skill's own comes from skills.json), or a plain glyph when the data gives none. */
  icon: string
}

export type NavSectionId = 'skills' | 'creatures' | 'system'

export interface NavSection {
  id: NavSectionId
  heading: string
  entries: readonly NavEntry[]
}

/** The part of the game state that decides what the nav offers. */
export interface NavInput {
  devPanelEnabled: boolean
}

/** All the nav reads of the content: the skills, and which of them have something to gather. */
export type NavContent = Pick<Content, 'skills' | 'resources'>

const FALLBACK_ICON = '◆'

export const skillPageId = (skillId: string): PageId => `skill:${skillId}`

/** The skill a page belongs to, or null for the fixed pages. */
export const skillIdOfPage = (page: PageId): string | null => (page.startsWith('skill:') ? page.slice('skill:'.length) : null)

/**
 * SKILLS: one page per skill that has something to gather (data-driven, so Mining appears the day it gets a raw
 * resource). CREATURES: the Nexus, the one creature page. SYSTEM: Settings, and Dev only while the setting is on. A section with
 * nothing in it is left out.
 */
export function buildNav(input: NavInput, c: NavContent = content): readonly NavSection[] {
  const gatherable = new Set(c.resources.filter((r) => r.kind === 'raw').map((r) => r.skill))
  const skills: NavEntry[] = c.skills.filter((s) => gatherable.has(s.id)).map((s) => ({ id: skillPageId(s.id), label: s.name, icon: s.emoji ?? FALLBACK_ICON }))
  const system: NavEntry[] = [{ id: 'settings', label: 'Settings', icon: '⚙️' }]
  if (input.devPanelEnabled) system.push({ id: 'dev', label: 'Dev', icon: '🧪' })

  const sections: NavSection[] = [
    { id: 'skills', heading: 'Skills', entries: skills },
    {
      id: 'creatures',
      heading: 'Creatures',
      entries: [{ id: 'nexus', label: 'Nexus', icon: '🌀' }],
    },
    { id: 'system', heading: 'System', entries: system },
  ]
  return sections.filter((s) => s.entries.length > 0)
}

/** Every entry in reading order: the order arrow keys walk. */
export const flattenNav = (nav: readonly NavSection[]): readonly NavEntry[] => nav.flatMap((s) => s.entries)

/**
 * The page to show for what the player last chose. A choice the nav no longer offers falls back: the Dev page
 * vanishes when its setting is switched off while the player stands on it, and that lands on Settings, where the
 * switch is. With nothing chosen yet, the first entry (a skill page while there is one).
 */
export function resolvePage(nav: readonly NavSection[], chosen: PageId | null): PageId {
  const entries = flattenNav(nav)
  if (chosen && entries.some((e) => e.id === chosen)) return chosen
  if (chosen === 'dev' && entries.some((e) => e.id === 'settings')) return 'settings'
  return entries[0]?.id ?? 'nexus'
}
