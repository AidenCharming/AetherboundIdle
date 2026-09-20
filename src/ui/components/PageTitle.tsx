import type { ReactNode } from 'react'

/** The page's one h1, big and plain, with an optional line under it. */
export function PageTitle({ children, lead }: { children: ReactNode; lead?: ReactNode }) {
  return (
    <div className="page-title">
      <h1>{children}</h1>
      {lead && <p className="muted">{lead}</p>}
    </div>
  )
}
