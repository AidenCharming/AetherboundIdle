// Delete save (Settings, step 1.9d): what the player must type before the button that deletes their game is enabled.
// Pure, so it is tested in node; the dialog reads it through selectors.ts like the roster's filter and the nav.

/** The words that confirm a deletion. The dialog's label is built from them, so the words and the label cannot disagree. */
export const DELETE_CONFIRM_WORDS = ['yes', 'accept'] as const

/**
 * Whether `text` is a confirmation: exactly one of the words, once the spaces around it are trimmed and the case is
 * ignored. "yes", "YES" and " Accept " confirm; "y", "yess", "yes please", "yes accept" and an empty box do not.
 */
export function isDeleteConfirmed(text: string): boolean {
  const typed = text.trim().toLowerCase()
  return DELETE_CONFIRM_WORDS.some((word) => typed === word)
}
