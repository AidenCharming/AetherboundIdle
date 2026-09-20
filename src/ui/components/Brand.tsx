/** The game's name with its glyph. Shown at the top of the sidebar (and so at the top of the drawer). No tagline. */
export function Brand() {
  return (
    <div className="brand">
      <span className="brand-glyph" aria-hidden="true">
        🔮
      </span>
      <span className="brand-name">Aetherbound Idle</span>
    </div>
  )
}
