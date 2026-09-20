import { useGameStore } from '../../state/runtime'
import {
  selectNextSlotLevel,
  selectSkillLevel,
  selectSkillXpInLevel,
  selectSkillXpToNext,
  selectSlotCount,
  skillInfo,
} from '../../state/selectors'
import { PageTitle } from '../components/PageTitle'
import { ProgressBar } from '../components/ProgressBar'
import { SlotCard } from '../components/SlotCard'
import { cssVars, formatCount } from '../format'

/**
 * One skill: a header card (its emoji, level, XP bar, how many slots it has and where the next one comes), then its
 * slots. The skill's type color (from types.json, through the selector) is the page's accent; the open skills have none
 * and keep the neutral one.
 */
export function SkillPage({ skillId }: { skillId: string }) {
  const info = skillInfo(skillId)
  const level = useGameStore((s) => selectSkillLevel(s, skillId))
  const xpInLevel = useGameStore((s) => selectSkillXpInLevel(s, skillId))
  const xpToNext = useGameStore((s) => selectSkillXpToNext(s, skillId))
  const slotCount = useGameStore((s) => selectSlotCount(s, skillId))
  const nextSlotLevel = useGameStore((s) => selectNextSlotLevel(s, skillId))

  return (
    <section className="page" style={cssVars({ '--accent': info.color })} aria-label={info.name}>
      <PageTitle>{info.name}</PageTitle>

      <div className="skill-card">
        <span className="skill-emoji" aria-hidden="true">
          {info.emoji ?? '◆'}
        </span>
        <div className="skill-card-body">
          <p className="eyebrow">Skill progress</p>
          <p className="skill-level">Level {level}</p>
          <ProgressBar thin value={xpToNext === null ? 1 : xpInLevel / xpToNext} label={`${info.name} XP toward the next level`} />
          <p className="small muted">
            {xpToNext === null ? 'Max level' : `${formatCount(xpInLevel)} / ${formatCount(xpToNext)} XP to level ${level + 1}`}
          </p>
        </div>
        <p className="skill-slots">
          <span className="eyebrow">Slots</span>
          <strong>
            {slotCount} / {info.totalSlots}
          </strong>
          <span className="small muted">{nextSlotLevel !== null ? `next at level ${nextSlotLevel}` : 'all open'}</span>
        </p>
      </div>

      <div className="slots">
        {Array.from({ length: slotCount }, (_, i) => (
          <SlotCard key={i} skillId={skillId} slotIndex={i} />
        ))}
      </div>
    </section>
  )
}
