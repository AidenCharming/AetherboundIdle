export interface Tab<Id extends string> {
  id: Id
  label: string
}

/**
 * The screen switch. On a phone it is pinned to the bottom edge, where a thumb reaches it, and on a wide screen it
 * sits under the top bar (theme.css). Which screen is showing is UI-local state, never part of the save.
 */
export function TabBar<Id extends string>({ tabs, current, onSelect, panelId }: { tabs: readonly Tab<Id>[]; current: Id; onSelect: (id: Id) => void; panelId: string }) {
  return (
    <nav className="tabbar" aria-label="Screens">
      <div className="tabbar-inner" role="tablist">
        {tabs.map((tab) => (
          <button
            key={tab.id}
            type="button"
            role="tab"
            id={`tab-${tab.id}`}
            aria-selected={tab.id === current}
            aria-controls={panelId}
            onClick={() => onSelect(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </div>
    </nav>
  )
}
