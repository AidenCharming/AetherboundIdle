/**
 * Keyboard movement in a horizontal tablist (the WAI-ARIA tabs pattern): Right and Left step to the next and previous
 * tab and wrap round the ends, Home and End jump to the first and last. Returns the index to move to, or null for a key
 * the tablist does not handle (Tab, Enter, Up, Down and the rest are left to the browser).
 */
export function nextTabIndex(key: string, from: number, count: number): number | null {
  if (count <= 0 || from < 0 || from >= count) return null
  switch (key) {
    case 'ArrowRight':
      return (from + 1) % count
    case 'ArrowLeft':
      return (from - 1 + count) % count
    case 'Home':
      return 0
    case 'End':
      return count - 1
    default:
      return null
  }
}
