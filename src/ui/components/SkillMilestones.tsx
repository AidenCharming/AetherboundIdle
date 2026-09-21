import { useGameStore } from '../../state/runtime'
import { selectSkillIdsWithXp, selectSkillMilestones, skillInfo } from '../../state/selectors'
import { cssVars, formatDuration } from '../format'

function SkillTable({ skillId }: { skillId: string }) {
  const rows = useGameStore((s) => selectSkillMilestones(s, skillId))
  const info = skillInfo(skillId)
  return (
    <div className="milestones" style={cssVars({ '--accent': info.color })}>
      <h3>
        {info.emoji && <span aria-hidden="true">{info.emoji}</span>} {info.name}
      </h3>
      <table>
        <thead>
          <tr>
            <th scope="col">Level</th>
            <th scope="col">Reached after</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.level}>
              <th scope="row">
                {row.level}
                {row.slot && <span className="small muted nowrap"> slot</span>}
                {row.max && <span className="small muted nowrap"> max</span>}
              </th>
              <td>
                {row.playedMs === null ? (
                  <span className="muted">unknown</span>
                ) : (
                  <>
                    {formatDuration(row.playedMs)}
                    {row.devMs > 0 && <span className="small muted nowrap"> + dev {formatDuration(row.devMs)}</span>}
                  </>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

/**
 * How long each skill took to reach the levels worth knowing about (step 1.9c): its slot unlock levels, its last
 * level, and the extra levels in `tuning.ui.pacingMilestones`. One table per skill that has earned any XP. There is no
 * row for level 1 (everyone starts there and the first slot is open at once): the table opens at level 2, the first
 * level-up.
 *
 * Reading it: the time shown is real play time (online plus away). "+ dev" means the dev panel's fast-forward had
 * already added that much game time by then, so some of the work was not played. "unknown" means the level was
 * never stamped: it was reached before this save was upgraded to version 2, or it was handed over by the dev
 * panel's "Set skill level", where no time passed at all.
 */
export function SkillMilestones() {
  const skillIds = useGameStore(selectSkillIdsWithXp)
  return (
    <div className="dev-control">
      <h2>Skill milestones</h2>
      <p className="small muted">
        When each skill reached the levels that matter. "+ dev" marks time added by the Dev panel's fast-forward, and "unknown" a level that was never timed (it was reached before this save recorded times, or
        a Dev panel "Set skill level" granted it).
      </p>
      {skillIds.length === 0 ? (
        <p className="small muted">No skill has earned any XP yet.</p>
      ) : (
        <div className="milestone-grid">
          {skillIds.map((id) => (
            <SkillTable key={id} skillId={id} />
          ))}
        </div>
      )}
    </div>
  )
}
