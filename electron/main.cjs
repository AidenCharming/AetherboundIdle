'use strict'
// The Windows desktop wrapper (step 1.9): one window around the built game, dist/index.html. It contains no game
// code and no IPC, and there is no preload script: the game talks to nothing but its own page (saves stay in the
// page's localStorage). Plain CommonJS so Electron runs it as written, with no compile step to keep in sync.
const fs = require('node:fs')
const path = require('node:path')
const { app, BrowserWindow, dialog, Menu, shell } = require('electron')

// The game's own background (`--bg` in src/ui/theme.css), shown before the first paint. test/electron.test.ts fails if they drift.
const BACKGROUND = '#0d1015'
const INDEX = path.join(__dirname, '..', 'dist', 'index.html')

// `--smoke[=load|progress|hold]` is the wrapper's own test hook (electron/smoke.cjs): hidden window, no player.
const smokeFlag = process.argv.find((a) => a === '--smoke' || a.startsWith('--smoke='))
const smokeMode = smokeFlag ? smokeFlag.split('=')[1] || 'load' : null
// `--smoke-out=<file>` also appends the test's output lines to a file: a portable exe is a launcher, and its child's stdout is not the caller's.
const smokeOut = process.argv.find((a) => a.startsWith('--smoke-out='))?.slice('--smoke-out='.length)
const say = (line) => {
  console.log(line)
  if (smokeOut) fs.appendFileSync(smokeOut, `${line}
`)
}

// One save location for the dev run and the packaged app, so both play the same game. A test overrides it with
// Chromium's own --user-data-dir, which must win (the smoke test never touches a real save). Set before the lock below.
if (!app.commandLine.hasSwitch('user-data-dir')) app.setPath('userData', path.join(app.getPath('appData'), 'Aetherbound Idle'))

// Two windows on one save overwrite each other (found in 1.8a on two browser tabs), so there is only ever one.
// A second launch quits at once and the first window comes forward.
const gotLock = app.requestSingleInstanceLock()
if (!gotLock) app.quit()

/** @type {BrowserWindow | null} */
let win = null

function focusWindow() {
  if (!win || smokeMode) return // a smoke run has a hidden window and no player to show it to
  if (win.isMinimized()) win.restore()
  win.show()
  win.focus()
}

app.on('second-instance', () => {
  say('[wrapper] second launch: focusing the first window')
  focusWindow()
})

function createWindow() {
  const w = new BrowserWindow({
    width: 1280,
    height: 800,
    // The game's phone layout starts at 375 px, so the window may shrink to it. Sizes are of the page, not the frame.
    useContentSize: true,
    minWidth: 375,
    minHeight: 560,
    backgroundColor: BACKGROUND,
    autoHideMenuBar: true,
    show: false,
    webPreferences: {
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      devTools: !app.isPackaged,
      // backgroundThrottling stays at its default (on): a minimized window may tick slowly, and that loses nothing,
      // because the tick driver measures real elapsed time and routes a long gap through applyOffline.
    },
  })

  // Nothing in the game leaves the page. If a link ever does, it opens in the default browser, never in this window.
  w.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//i.test(url)) void shell.openExternal(url)
    return { action: 'deny' }
  })
  // Reloading the page (the dev panel's reset save does) is the only navigation the game makes to itself.
  w.webContents.on('will-navigate', (event, url) => {
    const current = new URL(w.webContents.getURL())
    const next = new URL(url)
    if (next.protocol === 'file:' && next.pathname === current.pathname) return
    event.preventDefault()
    if (/^https?:$/.test(next.protocol)) void shell.openExternal(url)
  })
  w.webContents.session.setPermissionRequestHandler((_wc, _permission, callback) => callback(false))

  if (!app.isPackaged) {
    w.webContents.on('before-input-event', (event, input) => {
      if (input.type === 'keyDown' && (input.key === 'F12' || (input.control && input.shift && input.key.toLowerCase() === 'i'))) {
        w.webContents.toggleDevTools()
        event.preventDefault()
      }
    })
  }
  w.once('ready-to-show', () => {
    if (!smokeMode) w.show()
  })
  w.on('closed', () => {
    win = null
  })
  return w
}

if (gotLock) {
  void app.whenReady().then(async () => {
    Menu.setApplicationMenu(null)
    win = createWindow()
    const smoke = smokeMode ? require('./smoke.cjs').attach(win, smokeMode, say) : null
    const loaded = win.loadFile(INDEX)
    if (smoke) return smoke.run(loaded)
    try {
      await loaded
    } catch (e) {
      dialog.showErrorBox('Aetherbound Idle', `The game could not be loaded (${e instanceof Error ? e.message : String(e)}). Run "npm run build" first.`)
      app.quit()
    }
  })
}
