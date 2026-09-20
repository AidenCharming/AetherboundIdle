import { useState } from 'react'
import { useGameStore } from './state/runtime'
import { DEFAULT_SORT, NO_FILTER, selectDevPanelEnabled, type RosterFilter, type RosterSort } from './state/selectors'
import { NoticeBanner } from './ui/components/NoticeBanner'
import { TabBar, type Tab } from './ui/components/TabBar'
import { TopBar } from './ui/components/TopBar'
import { WelcomeBack } from './ui/components/WelcomeBack'
import { DevPanel } from './ui/screens/DevPanel'
import { Nexus } from './ui/screens/Nexus'
import { Roster } from './ui/screens/Roster'
import { Settings } from './ui/screens/Settings'
import { Skills } from './ui/screens/Skills'
import './ui/theme.css'

type ScreenId = 'skills' | 'roster' | 'nexus' | 'settings' | 'dev'

const TABS: readonly Tab<ScreenId>[] = [
  { id: 'skills', label: 'Skills' },
  { id: 'roster', label: 'Roster' },
  { id: 'nexus', label: 'Nexus' },
  { id: 'settings', label: 'Settings' },
]

const DEV_TAB: Tab<ScreenId> = { id: 'dev', label: 'Dev' }
const PANEL_ID = 'screen'

// The layout shell and the screen switch. Which screen is open is plain UI state (no router, and not in the save).
// The tick driver runs whichever screen is showing, so nothing pauses while you look at the roster.
export function App() {
  const [chosen, setChosen] = useState<ScreenId>('skills')
  // The roster's filter and sort live here, not in the Roster, so a trip to the Skills screen and back keeps them.
  // Still UI-local: none of it is in the game state or the save.
  const [filter, setFilter] = useState<RosterFilter>(NO_FILTER)
  const [sort, setSort] = useState<RosterSort>(DEFAULT_SORT)

  // The Dev tab exists only while the setting is on, so switching the setting off while standing on it has to send
  // the player somewhere real rather than leave an empty panel.
  const devEnabled = useGameStore(selectDevPanelEnabled)
  const tabs = devEnabled ? [...TABS, DEV_TAB] : TABS
  const screen = tabs.some((t) => t.id === chosen) ? chosen : 'settings'

  return (
    <div className="app">
      <TopBar />
      <NoticeBanner />
      <TabBar tabs={tabs} current={screen} onSelect={setChosen} panelId={PANEL_ID} />
      <main id={PANEL_ID} role="tabpanel" aria-labelledby={`tab-${screen}`} style={{ display: 'contents' }}>
        {screen === 'skills' && <Skills />}
        {screen === 'roster' && <Roster filter={filter} sort={sort} onFilter={setFilter} onSort={setSort} />}
        {screen === 'nexus' && <Nexus />}
        {screen === 'settings' && <Settings />}
        {screen === 'dev' && <DevPanel />}
      </main>
      <WelcomeBack />
    </div>
  )
}
