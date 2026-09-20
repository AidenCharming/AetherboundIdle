import type { ResourceInfo } from '../../state/selectors'
import { cssVars } from '../format'

/** A resource's emoji, or the type-colored dot when the data gives it none. Decorative: the name always sits beside it. */
export function ResourceIcon({ info }: { info: Pick<ResourceInfo, 'emoji' | 'color'> }) {
  if (info.emoji) {
    return (
      <span className="resource-emoji" aria-hidden="true">
        {info.emoji}
      </span>
    )
  }
  return <span className="dot" style={cssVars({ '--dot': info.color })} aria-hidden="true" />
}
