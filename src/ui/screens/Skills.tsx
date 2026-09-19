import { useGameStore } from '../../state/runtime'
import {
  gatherableSkillIds,
  selectNextSlotLevel,
  selectSkillLevel,
  selectSkillXpInLevel,
  selectSkillXpToNext,
  selectSlotCount,
  skillInfo,
} from '../../state/selectors'
import { ProgressBar } from '../components/ProgressBar'
import { SlotCard } from '../components/SlotCard'
import { cssVars, formatCount } from '../format'

function SkillPanel({ skillId }: { skillId: string }) {
  const info = skillInfo(skillId)
  const level = useGameStore((s) => selectSkillLevel(s, skillId))
  const xpInLevel = useGameStore((s) => selectSkillXpInLevel(s, skillId))
  const xpToNext = useGameStore((s) => selectSkillXpToNext(s, skillId))
  const slotCount = useGameStore((s) => selectSlotCount(s, skillId))
  const nextSlotLevel = useGameStore((s) => selectNextSlotLevel(s, skillId))

  return (
    <section className="skill" style={cssVars({ '--accent': info.color })} aria-label={info.name}>
      <div className="skill-head">
        <h2>{info.name}</h2>
        <span>Level {level}</span>
      </div>

      <div>
        <ProgressBar thin value={xpToNext === null ? 1 : xpInLevel / xpToNext} label={`${info.name} XP toward the next level`} />
        <p className="small muted">
          {xpToNext === null ? 'Max level' : `${formatCount(xpInLevel)} / ${formatCount(xpToNext)} XP to level ${level + 1}`}
        </p>
      </div>

      <p className="small muted">
        Slots {slotCount} / {info.totalSlots}
        {nextSlotLevel !== null && ` · next at level ${nextSlotLevel}`}
      </p>

      {Array.from({ length: slotCount }, (_, i) => (
        <SlotCard key={i} skillId={skillId} slotIndex={i} />
      ))}
    </section>
  )
}

export function Skills() {
  return (
    <>
      {gatherableSkillIds.map((id) => (
        <SkillPanel key={id} skillId={id} />
      ))}
    </>
  )
}
