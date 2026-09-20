import { memo, useState } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import {
  selectCreatureView,
  selectSlotAssignResourceId,
  selectSlotCount,
  selectSlotCreatureId,
  shinyHueDeg,
  skillInfo,
  type CreatureView,
} from '../../state/selectors'
import { cssVars } from '../format'

type Outcome = { ok: true } | { ok: false; reason: string }

/** One slot of a skill as an assignment target: empty, or held by someone who would be benched. */
function SlotOption({ creatureId, skillId, slotIndex, onOutcome }: { creatureId: string; skillId: string; slotIndex: number; onOutcome: (outcome: Outcome) => void }) {
  const actions = useActions()
  const occupant = useGameStore((s) => {
    const id = selectSlotCreatureId(s, skillId, slotIndex)
    return id ? selectCreatureView(s, id) : null
  })
  const resourceId = useGameStore((s) => selectSlotAssignResourceId(s, skillId, slotIndex))
  const here = occupant?.id === creatureId

  return (
    <button
      type="button"
      className="slot-option"
      disabled={here || resourceId === null}
      onClick={() => resourceId && onOutcome(actions.assignCreature(creatureId, skillId, slotIndex, resourceId))}
    >
      <strong>Slot {slotIndex + 1}</strong>
      <span className="small muted">
        {here ? 'working here now' : occupant ? `replaces ${occupant.emoji} ${occupant.name}` : 'empty'}
      </span>
    </button>
  )
}

function SkillSlots({ creatureId, skillId, onOutcome }: { creatureId: string; skillId: string; onOutcome: (outcome: Outcome) => void }) {
  const slotCount = useGameStore((s) => selectSlotCount(s, skillId))
  return (
    <fieldset className="assign-skill">
      <legend>{skillInfo(skillId).name}</legend>
      {Array.from({ length: slotCount }, (_, i) => (
        <SlotOption key={i} creatureId={creatureId} skillId={skillId} slotIndex={i} onOutcome={onOutcome} />
      ))}
    </fieldset>
  )
}

function Details({ view, id }: { view: CreatureView; id: string }) {
  const actions = useActions()
  // The sim's reason when it refuses a move, shown as it wrote it.
  const [error, setError] = useState<string | null>(null)
  const report = (outcome: Outcome): void => setError(outcome.ok ? null : outcome.reason)

  return (
    <div className="rcard-details" id={id}>
      <dl className="facts">
        <div>
          <dt>Species</dt>
          <dd>
            {view.speciesName}
            {view.isHybrid && <span className="muted"> (hybrid)</span>}
          </dd>
        </div>
        <div>
          <dt>{view.types.length > 1 ? 'Types' : 'Type'}</dt>
          <dd>{view.types.map((t) => t.name).join(' / ')}</dd>
        </div>
        <div>
          <dt>Rarity</dt>
          <dd>{view.rarity.name}</dd>
        </div>
        <div>
          <dt>Form</dt>
          <dd>
            {view.form}: {view.name}
          </dd>
        </div>
        <div>
          <dt>Stat lean</dt>
          <dd className="cap">{view.statLean}</dd>
        </div>
        <div>
          <dt>Primary skill</dt>
          <dd>{view.primarySkill}</dd>
        </div>
        <div>
          <dt>Aptitude</dt>
          <dd>{view.secondaryAptitude}</dd>
        </div>
      </dl>

      <div className="traits">
        {view.signatureTrait && (
          <p>
            <strong>{view.signatureTrait.name}</strong> <span className="muted small cap">signature, {view.signatureTrait.strength}</span>
            <span className="small muted block">{view.signatureTrait.text}</span>
          </p>
        )}
        {view.poolTraits.length === 0 ? (
          <p className="small muted">No pool traits.</p>
        ) : (
          view.poolTraits.map((t, i) => (
            <p key={`${t.id}-${i}`}>
              <strong>{t.name}</strong> <span className="muted small cap">{t.strength}</span>
              <span className="small muted block">{t.text}</span>
            </p>
          ))
        )}
      </div>

      <div className="work">
        <p>
          <strong>{view.working ? `Working: ${view.workingAt}` : 'Benched'}</strong>
        </p>
        {view.working && (
          <button
            type="button"
            onClick={() => {
              actions.unassignCreature(view.id)
              setError(null)
            }}
          >
            Unassign
          </button>
        )}

        {view.assignableSkillIds.length === 0 ? (
          <p className="small muted">Nothing this creature can work has anything to gather yet.</p>
        ) : (
          <>
            <p className="small muted">Assign to...</p>
            {view.assignableSkillIds.map((skillId) => (
              <SkillSlots key={skillId} creatureId={view.id} skillId={skillId} onOutcome={report} />
            ))}
          </>
        )}

        {error && (
          <p className="error" role="alert">
            {error}
          </p>
        )}
      </div>
    </div>
  )
}

/**
 * One creature. `memo` plus a view that is identity-stable (selectors.ts) means a card re-renders only when its own
 * creature changes or it is opened or closed: not on the 10 Hz tick, and not when a neighbour changes.
 */
export const RosterCard = memo(function RosterCard({ view, expanded, onToggle }: { view: CreatureView; expanded: boolean; onToggle: (id: string) => void }) {
  const first = view.types[0]?.color ?? view.color
  const style = cssVars({
    // Dual-type hybrids split the art panel between their two type colors; a single type fills it with one.
    '--type-a': first,
    '--type-b': view.types[1]?.color ?? first,
    '--rarity': view.rarity.tint,
    '--glow': String(view.rarity.glow),
    '--shiny-hue': view.shiny ? `${shinyHueDeg}deg` : null,
  })
  const detailsId = `details-${view.id}`

  return (
    <li className="rcard" data-expanded={expanded} data-shiny={view.shiny} data-rarity={view.rarity.id} style={style}>
      <button type="button" className="rcard-toggle" aria-expanded={expanded} aria-controls={detailsId} onClick={() => onToggle(view.id)}>
        <span className="rcard-art" aria-hidden="true">
          <span className="rcard-emoji">{view.emoji}</span>
        </span>
        <span className="rcard-body">
          <span className="rcard-name">
            {view.name}
            {view.shiny && <span className="shiny-tag"> ✨ Shiny</span>}
          </span>
          <span className="small muted">
            Lv {view.level} · Form {view.form}
          </span>
          <span className="rcard-rarity small">{view.rarity.name}</span>
          <span className="badge" data-state={view.working ? 'working' : 'benched'}>
            {view.workingAt ?? 'Benched'}
          </span>
        </span>
      </button>
      {expanded && <Details view={view} id={detailsId} />}
    </li>
  )
})
