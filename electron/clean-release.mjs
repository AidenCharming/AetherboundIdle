// Empties release/ before an exe build, so the folder only ever holds the new build. `npm run electron:pack` runs it after
// `npm run build` and before electron-builder:
//
//   node electron/clean-release.mjs
//
// It deletes everything INSIDE release/ (installers, portable exes, blockmaps, win-unpacked, builder debug files) and leaves
// the folder itself. Safety: the folder is resolved from the repo root (this file's parent), and the script refuses to run
// unless that is exactly <repo>/release, is a real folder (not a link pointing somewhere else) and the repo root looks like
// this repo. Links found inside release/ are removed as links; nothing outside release/ is ever followed or touched.
// A file that is locked (a running copy of the game, antivirus, an open Explorer window) is retried for a few seconds,
// then the script stops with exit code 1 so electron-builder does not start on a half-cleaned folder.
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

/** Errors that mean "something has this open right now" on Windows, so waiting can help. */
const LOCKED = new Set(['EBUSY', 'EPERM', 'ENOTEMPTY'])

/** A problem with a plain-language message, printed as it is (no stack trace). */
export class CleanError extends Error {}

const removeEntry = (entry) => {
  // A link (a junction or symlink) is unlinked, never recursed into: its target is not ours to delete.
  if (fs.lstatSync(entry).isSymbolicLink()) fs.unlinkSync(entry)
  else fs.rmSync(entry, { recursive: true, force: true })
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

/**
 * Deletes everything inside `<repoRoot>/release`. Resolves to the names removed (an absent release/ is fine: nothing to do).
 * `retries` and `delayMs` set how long a locked file is waited for (5 x 1 s by default); `remove` is only for tests.
 */
export async function cleanRelease(repoRoot, { retries = 5, delayMs = 1000, remove = removeEntry, log = () => {} } = {}) {
  const root = path.resolve(repoRoot)
  const release = path.join(root, 'release')
  if (path.relative(root, release) !== 'release') throw new CleanError(`Refusing to clean ${release}: it is not <repo>/release.`)
  if (!fs.existsSync(path.join(root, 'package.json'))) throw new CleanError(`Refusing to clean ${release}: ${root} has no package.json, so it is not the repo root.`)
  if (!fs.existsSync(release) && !isLink(release)) return []
  if (isLink(release) || !fs.statSync(release).isDirectory() || fs.realpathSync(release) !== path.join(fs.realpathSync(root), 'release')) {
    throw new CleanError(`Refusing to clean ${release}: it is a link or not a plain folder, so it may point outside the repo. Delete or fix it by hand.`)
  }

  const removed = []
  let pending = fs.readdirSync(release)
  for (let attempt = 0; ; attempt++) {
    const locked = []
    for (const name of pending) {
      try {
        remove(path.join(release, name))
        removed.push(name)
      } catch (error) {
        if (!LOCKED.has(error?.code)) throw new CleanError(`Could not delete release/${name}: ${error?.message ?? error}`)
        locked.push(name)
      }
    }
    if (locked.length === 0) break
    if (attempt >= retries) {
      throw new CleanError(`release/ is not clean: ${locked.join(', ')} is locked. Close the game and any Explorer window in release/, then run it again.`)
    }
    log(`release/: ${locked.join(', ')} is locked, waiting (${attempt + 1} of ${retries})...`)
    pending = locked
    await sleep(delayMs)
  }
  return removed
}

function isLink(p) {
  try {
    return fs.lstatSync(p).isSymbolicLink()
  } catch {
    return false
  }
}

// Only when run as a script (npm run electron:pack), not when a test imports cleanRelease.
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
  try {
    const removed = await cleanRelease(root, { log: console.log })
    console.log(removed.length ? `Cleaned release/: removed ${removed.join(', ')}.` : 'release/ is already empty.')
  } catch (error) {
    console.error(error instanceof CleanError ? error.message : error)
    process.exit(1)
  }
}
