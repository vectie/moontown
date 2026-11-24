import './town-wheel.js'
// The town artwork and its registered roads already share an isometric camera.
// Use its projected coordinates directly for both display and picking.
export function viewport(width, height) {
  return {
    w: width,
    h: height,
    height,
    shear: 0,
    offset: 0,
    screenY(_x, y) {
      return y
    },
    localY(_x, y) {
      return y
    },
  }
}
export const compact =
  (navigator.deviceMemory > 0 && navigator.deviceMemory <= 4) ||
  /RK3588|rockchip/i.test(navigator.userAgent) ||
  (!navigator.deviceMemory &&
    /linux.*(?:aarch64|armv8)/i.test(navigator.userAgent) &&
    navigator.hardwareConcurrency <= 8)
export function forCanvas(canvas) {
  const w = canvas.clientWidth,
    h = canvas.clientHeight
  const previous = canvas.townProjection
  if (previous && previous.w === w && previous.height === h) return previous
  return (canvas.townProjection = viewport(w, h))
}
globalThis.__townDisplay = { compact, forCanvas }

// Canonicalize old public bookmarks before MoonBit reads its initial model.
// Explicit authoring and indoor/operations routes keep their own entry.
const url = new URL(location.href)
const view = url.searchParams.get('view')
if (
  view === 'region' ||
  (view === 'town' &&
    !['area', 'panel', 'layer', 'edit', 'request', 'registration-review'].some(
      (k) => url.searchParams.has(k),
    ))
) {
  url.searchParams.set('view', 'overview')
  if (view === 'region' && !url.searchParams.has('district'))
    url.searchParams.set('projects', '1')
  history.replaceState(history.state, '', url)
}
const valid = (c) => c && [c.x, c.y, c.z].every(Number.isFinite) && c.z > 0
const snapshots = new Map()
const newId = () =>
  crypto.randomUUID?.() || String(performance.timeOrigin + performance.now())
let entry = history.state?.townEntry || newId(),
  restoring = false
history.replaceState({ ...history.state, townEntry: entry }, '')
function currentCamera() {
  const c = globalThis.__moontownGoldenValleyCamera
  return valid(c) && c.livingRoom
    ? { x: c.x, y: c.y, z: c.z, follow: !!c.streetFollow }
    : null
}
export function saveCamera() {
  const c = currentCamera()
  if (!c || restoring || entry !== history.state?.townEntry) return
  snapshots.set(entry, c)
  history.replaceState({ ...history.state, townCamera: c }, '')
}
export function pushMap(url, sameView = false) {
  if (
    restoring ||
    (!sameView && new URL(url, location.href).href === location.href)
  )
    return
  saveCamera()
  entry = newId()
  history.pushState(
    {
      ...history.state,
      townEntry: entry,
      townCamera: null,
      townViewerFrom: false,
    },
    '',
    url,
  )
}
// A MoonBit action can set several search parameters in one dispatch.
const surfaceKey = (target) =>
  ['request', 'layer', 'area', 'building']
    .map((k) => target.searchParams.get(k) || '')
    .join('|')
let activeSurface = surfaceKey(url),
  writingSurface = false
globalThis.__townDisplay.writeRoute = function (target) {
  if (restoring || target.href === location.href) return
  const next = surfaceKey(target)
  if (
    next !== activeSurface &&
    !writingSurface &&
    document.querySelector('#app')?.firstChild
  ) {
    const camera = currentCamera() || history.state?.townCamera
    pushMap(target)
    if (camera)
      history.replaceState({ ...history.state, townCamera: camera }, '', target)
    writingSurface = true
    queueMicrotask(() => {
      writingSurface = false
    })
  } else history.replaceState(history.state, '', target)
  activeSurface = next
}
export function restoreCamera() {
  const saved = snapshots.get(entry) || history.state?.townCamera,
    c = globalThis.__moontownGoldenValleyCamera
  if (!valid(saved) || !c?.livingRoom) return false
  delete c.streetTransition
  Object.assign(c, {
    x: saved.x,
    y: saved.y,
    z: saved.z,
    streetFollow: saved.follow,
  })
  globalThis.__moontownGoldenValleyRender?.('history')
  return true
}
let pending
function afterGesture(event) {
  if (event.target?.id !== 'energy-valley-canvas' &&
      !event.target?.closest?.('.street-world-entry, .town-landmark-pins button')) return
  clearTimeout(pending)
  pending = setTimeout(saveCamera, 120)
}
document.addEventListener('wheel', afterGesture, {
  passive: true,
  capture: true,
})
document.addEventListener('pointerup', afterGesture, true)
addEventListener('pagehide', saveCamera)
document.addEventListener(
  'click',
  (event) => {
    const recenter = event.target.closest?.('.street-recenter')
    if (!recenter && !event.target.closest?.('#street-overview')) return
    const u = new URL(location.href)
    u.searchParams.set(
      'view',
      recenter ||
        document
          .getElementById('street-overview')
          .getAttribute('aria-pressed') === 'true'
        ? 'living-room'
        : 'overview',
    )
    for (const key of ['road', 'district', 'projects', 'landmarks'])
      u.searchParams.delete(key)
    pushMap(u, !!recenter)
  },
  true,
)
let restoreGeneration = 0, requestedOverview = false
addEventListener('popstate', () => {
  const generation = ++restoreGeneration
  const button = document.getElementById('street-overview')
  const target = new URL(location.href)
  clearTimeout(pending)
  const leaving = currentCamera()
  if (leaving && !restoring) snapshots.set(entry, leaving)
  const state = history.state
  entry = state?.townEntry || newId()
  if (surfaceKey(target) !== activeSurface || !button) {
    location.reload()
    return
  }
  const overview = target.searchParams.get('view') === 'overview'
  // Rabbita commits the button state on a later frame. A second traversal
  // can arrive after the first toggle was dispatched but before that paint.
  const previous = restoring ? requestedOverview : button.getAttribute('aria-pressed') === 'true'
  requestedOverview = overview
  restoring = true
  if (previous !== overview) button.click()
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      if (generation !== restoreGeneration) return
      history.replaceState(state, '', target)
      dispatchEvent(new Event('town-map-route'))
      restoreCamera()
      restoring = false
    }),
  )
})
