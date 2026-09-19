import { useState } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import {
  gatherableResourceIds,
  resourceInfo,
  selectAssignableCreatureIds,
  selectCreatureView,
  selectDefaultResourceId,
  selectResourceUnlocked,
  selectSlotCooldownMs,
  selectSlotCreatureId,
  selectSlotProgress,
  selectSlotResourceId,
} from '../../state/selectors'
import { cssVars, formatSeconds } from '../format'
import { ProgressBar } from './ProgressBar'

interface Slot {
  skillId: string
  slotIndex: number
}

function Creature({ creatureId }: { creatureId: string }) {
  const view = useGameStore((s) => selectCreatureView(s, creatureId))
  if (!view) return null
  return (
    <span className="creature" style={cssVars({ '--accent': view.color })}>
      <span className="creature-emoji" aria-hidden="true">
        {view.emoji}
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

function Tier({ skillId, resourceId, selected, onPick }: { skillId: string; resourceId: string; selected: boolean; onPick: (id: string) => void }) {
  const unlocked = useGameStore((s) => selectResourceUnlocked(s, skillId, resourceId))
  const info = resourceInfo(resourceId)
  return (
    <button type="button" className="tier" aria-pressed={selected} disabled={!unlocked} onClick={() => onPick(resourceId)}>
      <span className="tier-name">
        <span className="dot" style={cssVars({ '--dot': info.color })} aria-hidden="true" />
        {info.name}
      </span>
      <span className="small muted">{unlocked ? `Level ${info.requiredLevel}` : `Needs level ${info.requiredLevel}`}</span>
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
        {creatureId ? <Creature creatureId={creatureId} /> : <span className="muted">Slot {slotIndex + 1}: empty</span>}
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
          <Tier key={id} skillId={skillId} resourceId={id} selected={id === selected} onPick={pick} />
        ))}
      </fieldset>

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
