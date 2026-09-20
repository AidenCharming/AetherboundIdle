/**
 * Keyboard movement in the sidebar nav (a vertical list): Down and Up step to the next and previous entry and wrap
 * round the ends, Home and End jump to the first and last. Returns the index to move to, or null for a key the nav
 * does not handle (Tab, Enter, Space and the rest stay with the browser, and so do Left and Right, which mean nothing
 * in a vertical list). The nav moves FOCUS with these keys; Enter or Space on the focused entry opens its page.
 */
export function nextNavIndex(key: string, from: number, count: number): number | null {
  if (count <= 0 || from < 0 || from >= count) return null
  switch (key) {
    case 'ArrowDown':
      return (from + 1) % count
    case 'ArrowUp':
      return (from - 1 + count) % count
    case 'Home':
      return 0
    case 'End':
      return count - 1
    default:
      return null
  }
}
