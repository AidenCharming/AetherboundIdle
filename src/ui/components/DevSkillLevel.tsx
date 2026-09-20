import { useState } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import { selectSkillLevel, skillInfo, skillOptions } from '../../state/selectors'
import { DevMessage, toOutcome, type DevOutcome } from './DevMessage'

/**
 * Set skill level (designer-approved, step 1.8b). Fast-forward is capped at 12 h a press, so the upper levels cannot be
 * reached by playing or by fast-forwarding; this raises a skill's XP to what a level takes, through the sim's own XP
 * code, so slots unlock and the level is right exactly as if it had been earned. It only raises.
 */
export function DevSkillLevel() {
  const actions = useActions()
  const [skillId, setSkillId] = useState(skillOptions[0]!.id)
  const [level, setLevel] = useState('')
  const [outcome, setOutcome] = useState<DevOutcome>(null)
  const current = useGameStore((s) => selectSkillLevel(s, skillId))
  const max = skillInfo(skillId).maxLevel

  return (
    <div className="dev-control">
      <h2>Set skill level</h2>
      <p className="small muted">
        Raises the skill's XP to what that level takes; slots unlock as normal. It only raises, never lowers.
      </p>
      <div className="dev-row">
        <label className="field">
          <span className="small muted">Skill</span>
          <select
            value={skillId}
            onChange={(e) => {
              setSkillId(e.target.value)
              setOutcome(null)
            }}
          >
            {skillOptions.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
        </label>
        <label className="field">
          <span className="small muted">
            Level (1 to {max}), now {current}
          </span>
          <input className="dev-input" type="text" inputMode="numeric" value={level} placeholder="Target level" onChange={(e) => setLevel(e.target.value)} />
        </label>
        <button type="button" className="primary" onClick={() => setOutcome(toOutcome(actions.setSkillLevel(skillId, level)))}>
          Set level
        </button>
      </div>
      <DevMessage outcome={outcome} />
    </div>
  )
}
