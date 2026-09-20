import { useGameStore } from '../../state/runtime'
import {
  activityPanelMax,
  resourceInfo,
  selectActivity,
  selectCreatureView,
  selectSlotCreatureId,
  selectSlotProgress,
  selectSlotResourceId,
  skillInfo,
  type ActivitySlot,
} from '../../state/selectors'
import { cssVars } from '../format'
import { ProgressBar } from './ProgressBar'
import { ResourceIcon } from './ResourceIcon'

/** The only part of a row that re-renders on the tick: its bar. */
function ActivityProgress({ skillId, slotIndex, label }: ActivitySlot & { label: string }) {
  const progress = useGameStore((s) => selectSlotProgress(s, skillId, slotIndex))
  return <ProgressBar thin tone="gold" value={progress} label={label} />
}

function ActivityRow({ skillId, slotIndex }: ActivitySlot) {
  const creatureId = useGameStore((s) => selectSlotCreatureId(s, skillId, slotIndex))
  const view = useGameStore((s) => (creatureId ? selectCreatureView(s, creatureId) : null))
  const resourceId = useGameStore((s) => selectSlotResourceId(s, skillId, slotIndex))
  if (!view) return null
  const skill = skillInfo(skillId)
  const resource = resourceId ? resourceInfo(resourceId) : null
  return (
    <li className="activity-row">
      <span className="activity-emoji" style={cssVars({ '--accent': view.color })} aria-hidden="true">
        {view.emoji}
      </span>
      <div className="activity-main">
        <p className="activity-name">{view.name}</p>
        <p className="small muted">
          {skill.name}
          {resource && (
            <>
              {' · '}
              <span className="nowrap">
                <ResourceIcon info={resource} /> {resource.name}
              </span>
            </>
          )}
        </p>
        <ActivityProgress skillId={skillId} slotIndex={slotIndex} label={`${view.name}, ${skill.name}: action progress`} />
      </div>
    </li>
  )
}

/**
 * Pinned at the bottom of the sidebar: what the working creatures are doing, at most `tuning.ui.activityPanelMax` of
 * them and then "+N more". The list re-renders only when a slot starts or stops working (selectActivity keeps its
 * identity through ticks), and each row's bar is the only thing that follows the tick, so the shell does not re-render.
 * Below it, the autosave status.
 */
export function ActivityPanel() {
  const slots = useGameStore(selectActivity)
  const shown = slots.slice(0, activityPanelMax)
  const more = slots.length - shown.length
  return (
    <>
      <section className="activity" aria-label="Current activity">
        <p className="eyebrow">Current activity</p>
        {slots.length === 0 ? (
          <p className="small muted">Nothing is working. Put a creature in a skill slot and it shows up here.</p>
        ) : (
          <ul className="activity-list">
            {shown.map((slot) => (
              <ActivityRow key={`${slot.skillId}:${slot.slotIndex}`} skillId={slot.skillId} slotIndex={slot.slotIndex} />
            ))}
          </ul>
        )}
        {more > 0 && <p className="small muted">+{more} more</p>}
      </section>
      <p className="autosave small muted">
        <span className="status-dot" aria-hidden="true" /> Autosaves locally
      </p>
    </>
  )
}
