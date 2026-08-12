import {
  loadEnergyValleyOsmBlockGraph,
  loadWenyuReferenceBuildings,
  loadWenyuReferenceIntersections,
  loadWenyuReferenceLabels,
  loadWenyuReferenceRoads,
  loadWenyuTownModules,
  loadKnowledgeDomainCatalog,
  refreshRuntimeSnapshots,
  startRuntimeSnapshotRefresh,
} from './runtime_snapshots.js'
import './viewport_drag_pan.js'
import { installAccountManagement } from './account_management.js'
import { ACCOUNT_DEMO_FIXTURES } from './account_demo_fixtures.js'

const app = document.getElementById('app')
const ACCOUNT_SESSION_KEY = 'moontown.account-session.v1'

function accountDemoFixture() {
  const params = new URLSearchParams(globalThis.location?.search || '')
  const host = globalThis.location?.hostname || ''
  const localPreview =
    host === '127.0.0.1' || host === 'localhost' || host === '::1'
  if (!localPreview || params.get('demo') !== '1') return null
  return ACCOUNT_DEMO_FIXTURES[params.get('account') || 'visitor'] || null
}

function accountProjectionForMoon(account) {
  const projection = { ...account }
  if (projection.active_tenant_id == null) delete projection.active_tenant_id
  if (projection.active_tenant_name == null) delete projection.active_tenant_name
  return projection
}

function storedAccountSession() {
  if (typeof globalThis.__moontownSessionToken === 'string') {
    return globalThis.__moontownSessionToken
  }
  try {
    return globalThis.localStorage?.getItem(ACCOUNT_SESSION_KEY) || ''
  } catch {
    return ''
  }
}

function storeAccountSession(token) {
  if (!token) return
  try {
    globalThis.localStorage?.setItem(ACCOUNT_SESSION_KEY, token)
  } catch {
    // Storage can be unavailable in privacy-restricted browser contexts.
  }
}

async function fetchAccountContext(token) {
  if (!token) return null
  const response = await fetch('/miniapp/me', {
    cache: 'no-store',
    headers: { 'x-miniapp-session': token },
  })
  if (!response.ok) return null
  return (await response.json()).account || null
}

async function createVisitorAccount() {
  const response = await fetch('/miniapp/auth/visitor', {
    method: 'POST',
    cache: 'no-store',
    headers: { 'content-type': 'application/json' },
    body: '{}',
  })
  if (!response.ok) return null
  const result = await response.json()
  storeAccountSession(result.session_token)
  return result.account || null
}

async function prepareAccountContext() {
  const demo = accountDemoFixture()
  if (demo) {
    globalThis.__moontownAccountContextJson = JSON.stringify(
      accountProjectionForMoon(demo),
    )
    document.documentElement.dataset.accountPlan = demo.plan
    return
  }
  let account = null
  try {
    account = await fetchAccountContext(storedAccountSession())
    if (!account) account = await createVisitorAccount()
  } catch {
    // Static builds remain browsable as visitor previews without an API host.
  }
  globalThis.__moontownAccountContextJson = JSON.stringify(
    accountProjectionForMoon(account || ACCOUNT_DEMO_FIXTURES.visitor),
  )
  document.documentElement.dataset.accountPlan =
    account?.plan || ACCOUNT_DEMO_FIXTURES.visitor.plan
}

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
    prepareAccountContext(),
    refreshRuntimeSnapshots(),
    loadEnergyValleyOsmBlockGraph(),
    loadWenyuReferenceBuildings(),
    loadWenyuReferenceIntersections(),
    loadWenyuReferenceLabels(),
    loadWenyuReferenceRoads(),
    loadWenyuTownModules(),
    loadKnowledgeDomainCatalog(),
  ])
}

async function startMoontown() {
  await prepareRuntimeBridge()
  startRuntimeSnapshotRefresh()
  await import('./main.js?account-system-v2')
  installAccountManagement()
}

void startMoontown().catch(error => {
  showBootFailure(error?.message || String(error))
})
