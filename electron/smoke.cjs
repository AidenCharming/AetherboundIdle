'use strict'
// The wrapper's own test (npm run electron:smoke). main.cjs runs this instead of showing a window when it is
// launched with --smoke=<mode>: the window stays hidden, the page is driven from here with executeJavaScript (which
// needs no IPC and no preload), and the process exits 0 (pass) or 1 (fail) after printing what it found.
//
//   load      the page loads, shows "Woodcutting", and logged no console error
//   progress  a hidden (so throttled) window really plays: assign, wait, and the XP matches the time that passed; then
//             a reload keeps the progress (this is the "throttled timers lose nothing" check)
//   hold      loads, then stays open. Only the runner's single-instance check uses it.
const { app } = require('electron')

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))
const say = (line) => console.log(`[smoke] ${line}`)

// Text of the progress line the Skills screen prints, and of the "next slot / level" line above it.
const XP_LINE = /([\d,]+) \/ ([\d,]+) XP to level (\d+)/
const PER_ACTION = /([\d.]+) s per action/

function attach(win, mode) {
  const wc = win.webContents
  const problems = []
  const fail = (message) => problems.push(message)

  // Attached before the page loads, so nothing logged during boot is missed.
  wc.on('console-message', (event) => {
    if (event.level === 'error') fail(`console error: ${event.message}`)
  })
  wc.on('did-fail-load', (_event, code, description, url) => fail(`the page failed to load (${code} ${description}) ${url}`))
  wc.on('render-process-gone', (_event, details) => fail(`the renderer process died (${details.reason})`))

  const page = (code) => wc.executeJavaScript(code)
  const text = () => page('document.body.innerText')
  async function waitFor(check, ms, what) {
    const end = Date.now() + ms
    for (;;) {
      const value = await check()
      if (value) return value
      if (Date.now() > end) throw new Error(`timed out waiting for ${what}`)
      await sleep(100)
    }
  }
  const readXp = async () => {
    const m = XP_LINE.exec(await text())
    // The line says "to level N": N is the NEXT level.
    return m ? { xp: Number(m[1].replaceAll(',', '')), level: Number(m[3]) - 1 } : null
  }

  async function loadCheck(loaded) {
    await loaded
    await waitFor(async () => (await text()).includes('Woodcutting'), 15000, 'the page to show "Woodcutting"')
    say(`page text contains "Woodcutting" (electron ${process.versions.electron}, packaged=${app.isPackaged}, userData=${app.getPath('userData')})`)
    await sleep(500) // a late render error would land here
  }

  async function progressCheck() {
    // A window that was never shown still counts as visible, so it is minimized like a player would: the page goes
    // hidden and Chromium throttles its timers (about once a second at first). Whether that took is printed, not
    // asserted: it says whether the check below is testing anything.
    win.minimize()
    await sleep(500)
    const visibility = await page('document.visibilityState')
    const ticks = await page('new Promise((done) => { let n = 0; const id = setInterval(() => n++, 100); setTimeout(() => { clearInterval(id); done(n) }, 3000) })')
    say(`window is ${visibility}: a 100 ms interval ran ${ticks} times in 3 s (${ticks < 20 ? 'throttled' : 'NOT throttled, so this run proves less'})`)

    await page(`(() => {
      const button = document.querySelector('article[aria-label="Slot 1"] fieldset.assign button')
      if (!button) throw new Error('no creature offered for Woodcutting slot 1')
      button.click()
    })()`)
    const assignedAt = Date.now()
    const cooldown = await waitFor(async () => PER_ACTION.exec(await text()), 5000, 'the slot to show its cooldown')
    const cooldownMs = Number(cooldown[1]) * 1000

    // The first completed action tells us what one action is worth without writing any balance number here.
    const first = await waitFor(async () => (await readXp())?.xp > 0 && (await readXp()), cooldownMs * 2 + 5000, 'the first action to complete')
    await sleep(9000)
    const now = await readXp()
    const elapsed = Date.now() - assignedAt
    const expected = elapsed / cooldownMs
    const actions = now.xp / first.xp
    say(`after ${(elapsed / 1000).toFixed(1)} s: xp ${now.xp} = ${actions} actions of ${first.xp} (expected about ${expected.toFixed(1)})`)
    if (now.level !== 1) fail(`the skill levelled up during the check (level ${now.level}); the maths below assumes it did not`)
    if (!Number.isInteger(actions)) fail(`xp ${now.xp} is not a whole number of actions of ${first.xp}`)
    // The screen can trail the clock by a tick (a throttled window ticks about once a second), never by more than one action.
    else if (actions < expected - 1.5 || actions > expected + 0.5) fail(`${actions} actions, expected about ${expected.toFixed(1)}: time was lost or invented`)

    // A reload flushes and boots again (this is also what the dev panel's reset save relies on).
    const reloaded = new Promise((done) => wc.once('did-finish-load', done))
    await page('location.reload()')
    await reloaded
    await waitFor(async () => readXp(), 15000, 'the reloaded page to show the skill')
    await sleep(500)
    const after = await readXp()
    const expectedAfter = (Date.now() - assignedAt) / cooldownMs
    say(`after reload: xp ${after.xp} = ${after.xp / first.xp} actions (expected about ${expectedAfter.toFixed(1)}), level ${after.level}`)
    if (after.xp < now.xp) fail(`progress went backwards across a reload (${now.xp} -> ${after.xp})`)
    else if (Math.abs(after.xp / first.xp - expectedAfter) > 2) fail(`after a reload xp is ${after.xp / first.xp} actions, expected about ${expectedAfter.toFixed(1)}`)
  }

  async function run(loaded) {
    const timer = setTimeout(() => {
      say('FAIL: gave up after 90 s')
      app.exit(1)
    }, 90000)
    try {
      await loadCheck(loaded)
      if (mode === 'progress') await progressCheck()
      if (mode === 'hold') {
        say('hold: loaded')
        return // stay open; the runner ends this process
      }
    } catch (e) {
      fail(e instanceof Error ? e.message : String(e))
    }
    clearTimeout(timer)
    for (const p of problems) say(`FAIL: ${p}`)
    say(problems.length === 0 ? `PASS (${mode})` : `FAIL (${mode})`)
    app.exit(problems.length === 0 ? 0 : 1)
  }

  return { run }
}

module.exports = { attach }
