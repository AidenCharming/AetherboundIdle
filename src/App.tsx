import { useState } from 'react'
import { DEFAULT_SORT, NO_FILTER, type RosterFilter, type RosterSort } from './state/selectors'
import { NoticeBanner } from './ui/components/NoticeBanner'
import { TabBar, type Tab } from './ui/components/TabBar'
import { TopBar } from './ui/components/TopBar'
import { Roster } from './ui/screens/Roster'
import { Skills } from './ui/screens/Skills'
import './ui/theme.css'

type ScreenId = 'skills' | 'roster'

const TABS: readonly Tab<ScreenId>[] = [
  { id: 'skills', label: 'Skills' },
  { id: 'roster', label: 'Roster' },
]

const PANEL_ID = 'screen'

// The layout shell and the screen switch. Which screen is open is plain UI state (no router, and not in the save).
// The tick driver runs whichever screen is showing, so nothing pauses while you look at the roster.
export function App() {
  const [screen, setScreen] = useState<ScreenId>('skills')
  // The roster's filter and sort live here, not in the Roster, so a trip to the Skills screen and back keeps them.
  // Still UI-local: none of it is in the game state or the save.
  const [filter, setFilter] = useState<RosterFilter>(NO_FILTER)
  const [sort, setSort] = useState<RosterSort>(DEFAULT_SORT)
  return (
    <div className="app">
      <TopBar />
      <NoticeBanner />
      <TabBar tabs={TABS} current={screen} onSelect={setScreen} panelId={PANEL_ID} />
      <main id={PANEL_ID} role="tabpanel" aria-labelledby={`tab-${screen}`} style={{ display: 'contents' }}>
        {screen === 'skills' ? <Skills /> : <Roster filter={filter} sort={sort} onFilter={setFilter} onSort={setSort} />}
      </main>
    </div>
  )
}
