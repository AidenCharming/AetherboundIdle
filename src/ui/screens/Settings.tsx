import type { ReactNode } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import { selectSetting, type SettingKey } from '../../state/selectors'
import { PageTitle } from '../components/PageTitle'
import { PlayTime } from '../components/PlayTime'
import { SaveFile } from '../components/SaveFile'
import { SkillMilestones } from '../components/SkillMilestones'

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

/** The player's own switches (both live in the save, so they survive a reload: plan.md section 5), and the save file export and import. */
export function Settings() {
  return (
    <section className="page" aria-label="Settings">
      <PageTitle>Settings</PageTitle>
      <div className="panel">
        <Toggle setting="offlineSummary" label="Show welcome-back summary">
          Report what you earned while you were away. Turning this off does not change what you earn: the catch-up happens either way.
        </Toggle>
        <Toggle setting="devPanelEnabled" label="Dev panel">
          Adds a Dev page under System for testing the game. Off by default.
        </Toggle>
        <SaveFile />
        <PlayTime />
        <SkillMilestones />
      </div>
    </section>
  )
}
