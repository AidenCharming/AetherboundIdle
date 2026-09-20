import { useRef, type KeyboardEvent } from 'react'
import { nextTabIndex } from '../tabKeys'

export interface Tab<Id extends string> {
  id: Id
  label: string
}

/**
 * The screen switch. On a phone it is pinned to the bottom edge, where a thumb reaches it, and on a wide screen it
 * sits under the top bar (theme.css). Which screen is showing is UI-local state, never part of the save.
 *
 * Keyboard, as in the ARIA tabs pattern: only the selected tab is in the Tab order (a roving tabindex), and Left and
 * Right (wrapping), Home and End move to another tab, select it and focus it. Selecting on arrow is fine here: a screen
 * costs nothing to show, and the tick driver runs whichever one is open.
 */
export function TabBar<Id extends string>({ tabs, current, onSelect, panelId }: { tabs: readonly Tab<Id>[]; current: Id; onSelect: (id: Id) => void; panelId: string }) {
  const buttons = useRef(new Map<Id, HTMLButtonElement>())

  const onKeyDown = (e: KeyboardEvent<HTMLDivElement>): void => {
    const from = tabs.findIndex((t) => `tab-${t.id}` === (e.target as HTMLElement).id)
    const to = nextTabIndex(e.key, from, tabs.length)
    if (to === null) return
    e.preventDefault()
    const target = tabs[to]!
    onSelect(target.id)
    buttons.current.get(target.id)?.focus()
  }

  return (
    <nav className="tabbar" aria-label="Screens">
      <div className="tabbar-inner" role="tablist" aria-orientation="horizontal" onKeyDown={onKeyDown}>
        {tabs.map((tab) => (
          <button
            key={tab.id}
            ref={(el) => {
              if (el) buttons.current.set(tab.id, el)
              else buttons.current.delete(tab.id)
            }}
            type="button"
            role="tab"
            id={`tab-${tab.id}`}
            aria-selected={tab.id === current}
            aria-controls={panelId}
            tabIndex={tab.id === current ? 0 : -1}
            onClick={() => onSelect(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </nav>
  )
}
