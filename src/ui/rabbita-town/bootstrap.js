import '/styles.css'
import {
  loadWenyuReferenceLabels,
  loadWenyuTownModules,
  refreshRuntimeSnapshots,
  startRuntimeSnapshotRefresh,
} from './runtime_snapshots.js'
import './viewport_drag_pan.js'

const app = document.getElementById('app')

function installBrowserRequireShim() {
  if (typeof globalThis.require === 'function') {
    return
  }

  globalThis.require = specifier => {
    if (specifier === 'process') {
      return { platform: 'browser' }
    }

    throw new Error(`Unsupported browser require: ${specifier}`)
  }
}

function showBootFailure(detail) {
  if (!app) {
    return
  }

  const message = detail || 'The browser entry failed before the town surface mounted.'

  app.innerHTML = `
    <div class="boot-shell">
      <div class="boot-panel">
        <p class="boot-eyebrow">MoonTown</p>
        <h1 class="boot-headline">MoonTown could not start</h1>
        <p class="boot-copy"></p>
      </div>
    </div>
  `
  app.querySelector('.boot-copy').textContent = message
}

installBrowserRequireShim()

globalThis.addEventListener('error', event => {
  showBootFailure(event.error?.message || event.message)
})

globalThis.addEventListener('unhandledrejection', event => {
  showBootFailure(event.reason?.message || String(event.reason || 'Startup promise rejected.'))
})

if (app) {
  app.innerHTML = `
    <div class="boot-shell">
      <div class="boot-panel">
        <p class="boot-eyebrow">MoonTown</p>
        <h1 class="boot-headline">Loading Rabbita Town</h1>
        <p class="boot-copy">Preparing city hall, moonbook houses, worker yard, and anomaly corner.</p>
      </div>
    </div>
  `
}

async function prepareRuntimeBridge() {
  await Promise.allSettled([
    refreshRuntimeSnapshots(),
    loadWenyuReferenceLabels(),
    loadWenyuTownModules(),
  ])
}

async function startMoontown() {
  startRuntimeSnapshotRefresh()
  await prepareRuntimeBridge()
  await import('/main.js')
}

void startMoontown().catch(error => {
  showBootFailure(error?.message || String(error))
})
