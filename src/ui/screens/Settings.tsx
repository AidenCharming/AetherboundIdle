import type { ReactNode } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import { selectSetting, type SettingKey } from '../../state/selectors'

function Toggle({ setting, label, children }: { setting: SettingKey; label: string; children: ReactNode }) {
  const value = useGameStore((s) => selectSetting(s, setting))
  const actions = useActions()
  return (
    <label className="setting">
      <input type="checkbox" checked={value} onChange={(e) => actions.setSetting(setting, e.target.checked)} />
      <span>
        <span className="setting-label">{label}</span>
        <span className="small muted block">{children}</span>
      </span>
    </label>
  )
}

/** The player's own switches. Both live in the save, so they survive a reload (plan.md section 5). */
export function Settings() {
  return (
    <section className="panel" aria-label="Settings">
      <h2>Settings</h2>
      <Toggle setting="offlineSummary" label="Show welcome-back summary">
        Report what you earned while you were away. Turning this off does not change what you earn: the catch-up happens either way.
      </Toggle>
      <Toggle setting="devPanelEnabled" label="Dev panel">
        Adds a Dev tab for testing the game. Off by default.
      </Toggle>
    </section>
  )
}
