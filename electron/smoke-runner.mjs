// Runs the wrapper's smoke checks (electron/smoke.cjs) as separate launches and reports one line per check.
//
//   node electron/smoke-runner.mjs                       the dev run: electron . against dist/
//   node electron/smoke-runner.mjs --packaged            the unpacked build in release/win-unpacked
//   node electron/smoke-runner.mjs --exe="<path>"        any packaged exe (the portable one, the installed one)
//   ... --only=load,progress,single                      a subset (default: all three)
//
// Every launch gets its own throw-away --user-data-dir, so it never reads or writes the player's real save, and a
// smoke run can happen while the game itself is open. The path may contain spaces (this project's does): nothing
// here goes through a shell. Exit code 0 only if every check passed.
import { spawn, spawnSync } from 'node:child_process'
import fs from 'node:fs'
import { createRequire } from 'node:module'
import os from 'node:os'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
const flag = (name) => process.argv.find((a) => a === `--${name}` || a.startsWith(`--${name}=`))
const flagValue = (name) => flag(name)?.split('=').slice(1).join('=')

let command
let baseArgs = []
let cwd = root
let label
const exeFlag = flagValue('exe')
if (exeFlag || flag('packaged')) {
  command = path.resolve(exeFlag ?? path.join(root, 'release', 'win-unpacked', 'Aetherbound Idle.exe'))
  if (!fs.existsSync(command)) {
    console.error(`No such file: ${command}. Run "npm run electron:pack" first.`)
    process.exit(1)
  }
  label = `packaged: ${path.relative(root, command)}`
} else {
  if (!fs.existsSync(path.join(root, 'dist', 'index.html'))) {
    console.error('dist/index.html does not exist. Run "npm run build" first.')
    process.exit(1)
  }
  command = createRequire(import.meta.url)('electron')
  baseArgs = ['.']
  label = 'dev: electron . against dist/'
}

const checks = (flagValue('only') ?? 'load,progress,single').split(',')
const timeoutMs = 120_000
for (const check of checks) {
  if (!['load', 'progress', 'single'].includes(check)) {
    console.error(`Unknown check "${check}" (use load, progress, single)`)
    process.exit(1)
  }
}

function makeUserDataDir() {
  return fs.mkdtempSync(path.join(os.tmpdir(), 'aetherbound-smoke-'))
}

function removeDir(dir) {
  try {
    fs.rmSync(dir, { recursive: true, force: true, maxRetries: 8, retryDelay: 500 })
  } catch {
    console.warn(`(could not delete ${dir}; it only holds a throw-away test profile)`)
  }
}

/** Ends a process and everything it started (a portable exe is a launcher around the real game). */
function killTree(child) {
  if (child.exitCode !== null || child.pid === undefined) return
  spawnSync('taskkill', ['/pid', String(child.pid), '/T', '/F'], { stdio: 'ignore' })
}

/** Starts one launch and resolves with its output, exit code and a way to wait for a line of output. */
function launch(mode, userDataDir) {
  const child = spawn(command, [...baseArgs, `--smoke=${mode}`, `--user-data-dir=${userDataDir}`], { cwd, stdio: ['ignore', 'pipe', 'pipe'], windowsHide: true })
  let output = ''
  const watchers = []
  const onData = (chunk) => {
    output += chunk.toString()
    for (const w of [...watchers]) if (w.test()) w.done()
  }
  child.stdout.on('data', onData)
  child.stderr.on('data', onData)
  const exited = new Promise((resolve) => child.on('exit', (code) => resolve(code)))
  const timer = setTimeout(() => killTree(child), timeoutMs)
  exited.then(() => clearTimeout(timer))
  return {
    child,
    exited,
    get output() {
      return output
    },
    /** Resolves true when `needle` appears in the output, false after `ms`. */
    sees(needle, ms) {
      return new Promise((resolve) => {
        const test = () => output.includes(needle)
        if (test()) return resolve(true)
        const w = { test, done: () => { clearTimeout(t); watchers.splice(watchers.indexOf(w), 1); resolve(true) } }
        const t = setTimeout(() => { watchers.splice(watchers.indexOf(w), 1); resolve(false) }, ms)
        watchers.push(w)
      })
    },
  }
}

const smokeLines = (output) =>
  output
    .split(/\r?\n/)
    .filter((l) => l.startsWith('[smoke]') || l.startsWith('[wrapper]'))
    .map((l) => `    ${l}`)
    .join('\n')

async function runOne(mode) {
  const dir = makeUserDataDir()
  try {
    const run = launch(mode, dir)
    const code = await run.exited
    return { ok: code === 0, detail: smokeLines(run.output) || `    (no output; exit code ${code})\n${run.output}` }
  } finally {
    removeDir(dir)
  }
}

/** A second launch on the same profile must quit by itself, and the first must be told about it. */
async function runSingleInstance() {
  const dir = makeUserDataDir()
  let first
  let second
  try {
    first = launch('hold', dir)
    if (!(await first.sees('[smoke] hold: loaded', 60_000))) return { ok: false, detail: `    the first instance never loaded:\n${first.output}` }
    second = launch('hold', dir)
    const secondCode = await Promise.race([second.exited, new Promise((resolve) => setTimeout(() => resolve('still running'), 20_000))])
    const told = await first.sees('[wrapper] second launch', 5_000)
    const ok = secondCode === 0 && told
    const detail = [
      `    second launch: ${secondCode === 0 ? 'quit by itself (exit 0)' : `did NOT quit (${secondCode})`}`,
      `    first instance was told: ${told ? 'yes' : 'no'}`,
      smokeLines(first.output),
    ].join('\n')
    return { ok, detail }
  } finally {
    for (const run of [first, second]) if (run) killTree(run.child)
    await Promise.all([first?.exited, second?.exited].filter(Boolean))
    removeDir(dir)
  }
}

console.log(`Smoke test (${label})`)
let failed = 0
for (const check of checks) {
  const started = Date.now()
  const result = check === 'single' ? await runSingleInstance() : await runOne(check)
  console.log(`${result.ok ? 'PASS' : 'FAIL'}  ${check}  (${((Date.now() - started) / 1000).toFixed(1)} s)`)
  console.log(result.detail)
  if (!result.ok) failed++
}
console.log(failed === 0 ? 'Smoke test passed.' : `Smoke test FAILED (${failed} of ${checks.length} checks).`)
process.exit(failed === 0 ? 0 : 1)
