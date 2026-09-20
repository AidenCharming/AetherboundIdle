import { useCallback, useSyncExternalStore } from 'react'

/**
 * Whether a CSS media query matches right now, and re-renders when that changes. The shell asks it whether the sidebar
 * is a fixed column or a drawer, because a drawer needs focus, inert and Escape handling that CSS alone cannot give.
 * It reads the first value synchronously, so the very first render already has the right layout.
 */
export function useMediaQuery(query: string): boolean {
  const subscribe = useCallback(
    (notify: () => void) => {
      const mq = window.matchMedia(query)
      mq.addEventListener('change', notify)
      return () => mq.removeEventListener('change', notify)
    },
    [query],
  )
  return useSyncExternalStore(
    subscribe,
    () => window.matchMedia(query).matches,
    () => false,
  )
}
