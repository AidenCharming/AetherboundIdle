import { useState } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import {
  gatherableResourceIds,
  resourceInfo,
  selectAssignableCreatureIds,
  selectCreatureView,
  selectDefaultResourceId,
  selectResourceQty,
  selectResourceUnlocked,
  selectSlotCooldownMs,
  selectSlotCreatureId,
  selectSlotProgress,
  selectSlotResourceId,
  skillInfo,
} from '../../state/selectors'
import { formatCount, formatSeconds } from '../format'
import { CreatureArt } from './CreatureArt'
import { ProgressBar } from './ProgressBar'
import { ResourceIcon } from './ResourceIcon'
import { cardStyle } from './cardStyle'

interface Slot {
  skillId: string
  slotIndex: number
}

function Creature({ creatureId }: { creatureId: string }) {
  const view = useGameStore((s) => selectCreatureView(s, creatureId))
  if (!view) return null
  return (
    <span className="creature" style={cardStyle(view)}>
      <span className="creature-plate art-plate" aria-hidden="true">
        <CreatureArt view={view} />
      </span>
      <span>
        <strong>{view.name}</strong> <span className="muted">Lv {view.level}</span>
      </span>
    </span>
  )
}

/** The only piece that re-renders every tick: everything else on the card changes when the player acts. */
function SlotProgress({ skillId, slotIndex }: Slot) {
  const progress = useGameStore((s) => selectSlotProgress(s, skillId, slotIndex))
  const cooldownMs = useGameStore((s) => selectSlotCooldownMs(s, skillId, slotIndex))
  return (
    <div className="slot-progress">
      <ProgressBar value={progress} label={`Action progress, slot ${slotIndex + 1}`} />
      <div className="slot-progress-text small muted">
        <span>{cooldownMs === null ? 'Idle' : `${Math.floor(progress * 100)}%`}</span>
        <span>{cooldownMs === null ? '' : `${formatSeconds(cooldownMs)} per action`}</span>
      </div>
    </div>
  )
}

/**
 * One resource the slot can gather, as a card: emoji, name, the base time and XP of an action, and how many the player
 * holds. The selected one is marked, and one the skill's level does not reach yet is greyed out, disabled, and says
 * what level it needs. Choosing it does what the old tier button did.
 */
function Option({ skillId, resourceId, selected, onPick }: { skillId: string; resourceId: string; selected: boolean; onPick: (id: string) => void }) {
  const unlocked = useGameStore((s) => selectResourceUnlocked(s, skillId, resourceId))
  const have = useGameStore((s) => selectResourceQty(s, resourceId))
  const info = resourceInfo(resourceId)
  return (
    <button type="button" className="option" aria-pressed={selected} disabled={!unlocked} onClick={() => onPick(resourceId)}>
      <span className="option-icon" aria-hidden="true">
        <ResourceIcon info={info} />
      </span>
      <span className="option-body">
        <span className="option-name">{info.name}</span>
        {info.baseActionMs !== null && info.xpPerAction !== null && (
          <span className="small muted">
            {formatSeconds(info.baseActionMs)} base · {formatCount(info.xpPerAction)} XP
          </span>
        )}
        <span className="small option-status">{unlocked ? <>You have <strong>{formatCount(have)}</strong></> : `Needs level ${info.requiredLevel}`}</span>
      </span>
    </button>
  )
}

function AssignChoice({ creatureId, onAssign }: { creatureId: string; onAssign: (creatureId: string) => void }) {
  const view = useGameStore((s) => selectCreatureView(s, creatureId))
  if (!view) return null
  return (
    <button type="button" onClick={() => onAssign(creatureId)}>
      {view.emoji} {view.name} <span className="muted">Lv {view.level}</span>
      {view.workingAt && <span className="muted small"> (from {view.workingAt})</span>}
    </button>
  )
}

export function SlotCard({ skillId, slotIndex }: Slot) {
  const actions = useActions()
  const creatureId = useGameStore((s) => selectSlotCreatureId(s, skillId, slotIndex))
  const slotResourceId = useGameStore((s) => selectSlotResourceId(s, skillId, slotIndex))
  const defaultResourceId = useGameStore((s) => selectDefaultResourceId(s, skillId))
  const candidates = useGameStore((s) => selectAssignableCreatureIds(s, skillId, slotIndex))

  // An empty slot has no resource yet, so the picker keeps the player's choice here until they assign someone.
  const [pending, setPending] = useState<string | null>(null)
  // The sim's reason when it refuses a move, shown as it wrote it.
  const [error, setError] = useState<string | null>(null)
  const selected = slotResourceId ?? pending ?? defaultResourceId

  const report = (result: { ok: true } | { ok: false; reason: string }): void => setError(result.ok ? null : result.reason)

  const pick = (resourceId: string): void => {
    if (creatureId) report(actions.setSlotResource(skillId, slotIndex, resourceId))
    else {
      setPending(resourceId)
      setError(null)
    }
  }
  const assign = (id: string): void => {
    if (selected) report(actions.assignCreature(id, skillId, slotIndex, selected))
  }
  const unassign = (): void => {
    if (!creatureId) return
    actions.unassignCreature(creatureId)
    setPending(null)
    setError(null)
  }

  return (
    <article className="slot" aria-label={`Slot ${slotIndex + 1}`}>
      <div className="slot-head">
        {creatureId ? <Creature creatureId={creatureId} /> : <span className="slot-empty">Slot {slotIndex + 1}: empty</span>}
        {creatureId && (
          <button type="button" onClick={unassign}>
            Unassign
          </button>
        )}
      </div>

      <SlotProgress skillId={skillId} slotIndex={slotIndex} />

      <fieldset className="picker">
        <legend>Gathering</legend>
        {gatherableResourceIds(skillId).map((id) => (
          <Option key={id} skillId={skillId} resourceId={id} selected={id === selected} onPick={pick} />
        ))}
      </fieldset>

      {candidates.length === 0 && !creatureId && (
        <p className="small muted">None of your creatures can work {skillInfo(skillId).name} yet.</p>
      )}

      {candidates.length > 0 && (
        <fieldset className="assign">
          <legend>{creatureId ? 'Replace with' : 'Assign'}</legend>
          {candidates.map((id) => (
            <AssignChoice key={id} creatureId={id} onAssign={assign} />
          ))}
        </fieldset>
      )}

      {error && (
        <p className="error" role="alert">
          {error}
        </p>
      )}
    </article>
  )
}
