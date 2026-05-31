import '/styles.css'

const app = document.getElementById('app')

if (app) {
  app.innerHTML = `
    <div class="boot-shell">
      <div class="boot-panel">
        <p class="boot-eyebrow">Moontown</p>
        <h1 class="boot-headline">Loading Rabbita Town</h1>
        <p class="boot-copy">Preparing city hall, moonbook houses, worker yard, and anomaly corner.</p>
      </div>
    </div>
  `
}

async function refreshTownSnapshot() {
  try {
    const response = await fetch(`./town.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownTownSnapshotJson = await response.text()
      globalThis.__moontownTownSnapshotVersion =
        (globalThis.__moontownTownSnapshotVersion || 0) + 1
    } else {
      globalThis.__moontownTownSnapshotJson = ''
    }
  } catch {
    globalThis.__moontownTownSnapshotJson = ''
  }
}

async function refreshVisualProjection() {
  try {
    const response = await fetch(`./visual-projection.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownVisualProjectionJson = await response.text()
      globalThis.__moontownVisualProjectionVersion =
        (globalThis.__moontownVisualProjectionVersion || 0) + 1
    } else {
      globalThis.__moontownVisualProjectionJson = ''
    }
  } catch {
    globalThis.__moontownVisualProjectionJson = ''
  }
}

async function refreshModuleProjections() {
  try {
    const response = await fetch(`./module-projections.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownModuleProjectionsJson = await response.text()
      globalThis.__moontownModuleProjectionsVersion =
        (globalThis.__moontownModuleProjectionsVersion || 0) + 1
    } else {
      globalThis.__moontownModuleProjectionsJson = '{"projections":[]}'
    }
  } catch {
    globalThis.__moontownModuleProjectionsJson = '{"projections":[]}'
  }
}

async function refreshMoondeskBridge() {
  try {
    const response = await fetch(`./moondesk-bridge.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownMoondeskBridgeJson = await response.text()
      globalThis.__moontownMoondeskBridgeVersion =
        (globalThis.__moontownMoondeskBridgeVersion || 0) + 1
    } else {
      globalThis.__moontownMoondeskBridgeJson = '{"records":[]}'
    }
  } catch {
    globalThis.__moontownMoondeskBridgeJson = '{"records":[]}'
  }
}

async function refreshCivicStatus() {
  try {
    const response = await fetch(`./civic-status.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownCivicStatusJson = await response.text()
      globalThis.__moontownCivicStatusVersion =
        (globalThis.__moontownCivicStatusVersion || 0) + 1
    } else {
      globalThis.__moontownCivicStatusJson = '{"services":[]}'
    }
  } catch {
    globalThis.__moontownCivicStatusJson = '{"services":[]}'
  }
}

async function refreshMoondeskHandoff() {
  try {
    const response = await fetch(`./tilemap/modules/moondesk-handoff.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownMoondeskHandoffJson = await response.text()
      globalThis.__moontownMoondeskHandoffVersion =
        (globalThis.__moontownMoondeskHandoffVersion || 0) + 1
    } else {
      globalThis.__moontownMoondeskHandoffJson = '{"artifacts":[]}'
    }
  } catch {
    globalThis.__moontownMoondeskHandoffJson = '{"artifacts":[]}'
  }
}

async function refreshDaemonSnapshot() {
  try {
    const response = await fetch(`./daemon.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownDaemonSnapshotJson = await response.text()
      globalThis.__moontownDaemonSnapshotVersion =
        (globalThis.__moontownDaemonSnapshotVersion || 0) + 1
    } else {
      globalThis.__moontownDaemonSnapshotJson = ''
    }
  } catch {
    globalThis.__moontownDaemonSnapshotJson = ''
  }
}

async function refreshLiveAutonomy() {
  try {
    const response = await fetch(`./live-autonomy.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownLiveAutonomyJson = await response.text()
      globalThis.__moontownLiveAutonomyVersion =
        (globalThis.__moontownLiveAutonomyVersion || 0) + 1
    } else {
      globalThis.__moontownLiveAutonomyJson = ''
    }
  } catch {
    globalThis.__moontownLiveAutonomyJson = ''
  }
}

async function refreshEditorPipeline() {
  try {
    const response = await fetch(`./editor-pipeline.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownEditorPipelineJson = await response.text()
      globalThis.__moontownEditorPipelineVersion =
        (globalThis.__moontownEditorPipelineVersion || 0) + 1
    } else {
      globalThis.__moontownEditorPipelineJson = ''
    }
  } catch {
    globalThis.__moontownEditorPipelineJson = ''
  }
}

async function refreshStandingGoals() {
  try {
    const response = await fetch(`./standing-goals.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownStandingGoalsJson = await response.text()
      globalThis.__moontownStandingGoalsVersion =
        (globalThis.__moontownStandingGoalsVersion || 0) + 1
    } else {
      globalThis.__moontownStandingGoalsJson = '[]'
    }
  } catch {
    globalThis.__moontownStandingGoalsJson = '[]'
  }
}

async function refreshWatcherRecords() {
  try {
    const response = await fetch(`./watchers/index.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      const text = await response.text()
      const records = parseWatcherRecords(text)
      globalThis.__moontownWatcherRecordsJson = JSON.stringify(records)
      globalThis.__moontownWatcherRecordsVersion =
        (globalThis.__moontownWatcherRecordsVersion || 0) + 1
    } else {
      globalThis.__moontownWatcherRecordsJson = '[]'
    }
  } catch {
    globalThis.__moontownWatcherRecordsJson = '[]'
  }
}

function parseWatcherRecords(text) {
  try {
    const parsed = JSON.parse(text)
    if (Array.isArray(parsed)) {
      return parsed
    }
    if (Array.isArray(parsed?.records)) {
      return parsed.records
    }
  } catch {
    // Fall through to JSONL parsing for old static builds.
  }

  return text
    .split('\n')
    .map(line => line.trim())
    .filter(Boolean)
    .map(line => {
      try {
        return JSON.parse(line)
      } catch {
        return null
      }
    })
    .filter(Boolean)
}

async function refreshOperatorRequests() {
  try {
    const response = await fetch(`./operator-requests.json?ts=${Date.now()}`, { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownOperatorRequestsJson = await response.text()
      globalThis.__moontownOperatorRequestsVersion =
        (globalThis.__moontownOperatorRequestsVersion || 0) + 1
    } else {
      globalThis.__moontownOperatorRequestsJson = '[]'
    }
  } catch {
    globalThis.__moontownOperatorRequestsJson = '[]'
  }
}

async function refreshRuntimeSnapshots() {
  await Promise.all([
    refreshTownSnapshot(),
    refreshVisualProjection(),
    refreshModuleProjections(),
    refreshMoondeskBridge(),
    refreshCivicStatus(),
    refreshMoondeskHandoff(),
    refreshDaemonSnapshot(),
    refreshLiveAutonomy(),
    refreshEditorPipeline(),
    refreshStandingGoals(),
    refreshWatcherRecords(),
    refreshOperatorRequests(),
  ])
}

globalThis.__moontownRefreshRuntimeSnapshots = refreshRuntimeSnapshots

async function boot() {
  await refreshRuntimeSnapshots()

  if (globalThis.__moontownTownSnapshotRefreshTimer) {
    clearInterval(globalThis.__moontownTownSnapshotRefreshTimer)
  }
  globalThis.__moontownTownSnapshotRefreshTimer = setInterval(refreshRuntimeSnapshots, 5000)

  try {
    const response = await fetch('./tilemap/wenyu_reference_labels.json', { cache: 'no-store' })
    if (response.ok) {
      globalThis.__wenyuReferenceLabels = await response.json()
    } else {
      globalThis.__wenyuReferenceLabels = null
    }
  } catch {
    globalThis.__wenyuReferenceLabels = null
  }

  try {
    const response = await fetch('./tilemap/modules/wenyu-town-modules.json', { cache: 'no-store' })
    if (response.ok) {
      globalThis.__wenyuTownModulesJson = await response.text()
      globalThis.__wenyuTownModulesVersion =
        (globalThis.__wenyuTownModulesVersion || 0) + 1
    } else {
      globalThis.__wenyuTownModulesJson = '{"modules":[]}'
    }
  } catch {
    globalThis.__wenyuTownModulesJson = '{"modules":[]}'
  }

  await import('/main.js')
  installViewportDragPan()
}

boot()

function installViewportDragPan() {
  if (!globalThis.location?.pathname?.includes('viewport')) {
    return
  }

  let frame = null
  let dragging = false
  let moved = false
  let pointerId = null
  let startX = 0
  let startY = 0
  let startScrollLeft = 0
  let startScrollTop = 0
  let pendingScrollLeft = 0
  let pendingScrollTop = 0
  let panFrame = 0
  let findFrameRaf = 0
  let zoomResetTimer = 0
  let initialPanDone = false
  let zoom = 1
  const minZoom = 0.55
  const maxZoom = 1.9
  const zoomStep = 0.25

  function findFrame() {
    frame = document.querySelector('.viewport-frame')
    if (frame) {
      applyZoom(zoom, { preserveCenter: false })
      centerInitialViewport()
    }
    return frame
  }

  function centerInitialViewport() {
    if (!frame || initialPanDone) {
      return
    }
    const focus =
      document.querySelector('.node-city-hall') ||
      document.querySelector('.node-book-house') ||
      document.querySelector('.scene-node')
    requestAnimationFrame(() => {
      const maxLeft = Math.max(0, frame.scrollWidth - frame.clientWidth)
      const maxTop = Math.max(0, frame.scrollHeight - frame.clientHeight)
      const targetLeft = focus
        ? focus.offsetLeft - frame.clientWidth * 0.35
        : frame.scrollWidth * 0.5 - frame.clientWidth * 0.5
      const targetTop = focus
        ? focus.offsetTop - frame.clientHeight * 0.44
        : frame.scrollHeight * 0.5 - frame.clientHeight * 0.5
      frame.scrollLeft = Math.min(
        maxLeft,
        Math.max(0, targetLeft),
      )
      frame.scrollTop = Math.min(maxTop, Math.max(0, targetTop))
      initialPanDone = true
    })
  }

  function shouldIgnoreDragStart(target) {
    return target?.closest?.('button, a, input, textarea, select, [contenteditable="true"]')
  }

  function clampZoom(value) {
    return Math.min(maxZoom, Math.max(minZoom, Math.round(value * 100) / 100))
  }

  function applyZoom(nextZoom, options = {}) {
    const activeFrame = frame || findFrame()
    if (!activeFrame) {
      return
    }
    const previousZoom = zoom
    const centerX = activeFrame.scrollLeft + activeFrame.clientWidth / 2
    const centerY = activeFrame.scrollTop + activeFrame.clientHeight / 2
    zoom = clampZoom(nextZoom)
    if (zoom === previousZoom) {
      if (activeFrame.dataset.zoom !== String(zoom)) {
        activeFrame.style.setProperty('--viewport-zoom', String(zoom))
        activeFrame.dataset.zoom = String(zoom)
      }
      return
    }
    activeFrame.classList.add('is-zooming')
    clearTimeout(zoomResetTimer)
    zoomResetTimer = setTimeout(() => {
      activeFrame.classList.remove('is-zooming')
    }, 140)
    activeFrame.style.setProperty('--viewport-zoom', String(zoom))
    activeFrame.dataset.zoom = String(zoom)
    if (options.preserveCenter === false || previousZoom === 0) {
      return
    }
    requestAnimationFrame(() => {
      const ratio = zoom / previousZoom
      activeFrame.scrollLeft = centerX * ratio - activeFrame.clientWidth / 2
      activeFrame.scrollTop = centerY * ratio - activeFrame.clientHeight / 2
    })
  }

  function onZoomClick(event) {
    const zoomIn = event.target?.closest?.('.viewport-zoom-in')
    const zoomOut = event.target?.closest?.('.viewport-zoom-out')
    if (!zoomIn && !zoomOut) {
      return
    }
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation?.()
    applyZoom(zoom + (zoomIn ? zoomStep : -zoomStep))
  }

  function onViewportNavigationClick(event) {
    const link = event.target?.closest?.(
      'a.wenyu-module-building[href], a.viewport-back-town[href]',
    )
    if (!link) {
      return
    }
    const href = link.getAttribute('href')
    if (!href) {
      return
    }
    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation?.()
    globalThis.location.href = href
    requestAnimationFrame(() => {
      globalThis.location.reload()
    })
  }

  function onPointerDown(event) {
    const activeFrame = frame || findFrame()
    if (!activeFrame || shouldIgnoreDragStart(event.target)) {
      return
    }
    dragging = true
    moved = false
    pointerId = event.pointerId
    startX = event.clientX
    startY = event.clientY
    startScrollLeft = activeFrame.scrollLeft
    startScrollTop = activeFrame.scrollTop
    pendingScrollLeft = startScrollLeft
    pendingScrollTop = startScrollTop
    activeFrame.classList.add('is-drag-panning')
    activeFrame.setPointerCapture?.(event.pointerId)
  }

  function flushPan() {
    panFrame = 0
    if (!dragging || !frame) {
      return
    }
    frame.scrollLeft = pendingScrollLeft
    frame.scrollTop = pendingScrollTop
  }

  function onPointerMove(event) {
    if (!dragging || event.pointerId !== pointerId || !frame) {
      return
    }
    const dx = event.clientX - startX
    const dy = event.clientY - startY
    if (Math.abs(dx) + Math.abs(dy) > 4) {
      moved = true
    }
    pendingScrollLeft = startScrollLeft - dx
    pendingScrollTop = startScrollTop - dy
    if (!panFrame) {
      panFrame = requestAnimationFrame(flushPan)
    }
    event.preventDefault()
  }

  function stopDrag(event) {
    if (!dragging || event.pointerId !== pointerId || !frame) {
      return
    }
    frame.releasePointerCapture?.(event.pointerId)
    frame.classList.remove('is-drag-panning')
    dragging = false
    pointerId = null
    if (panFrame) {
      cancelAnimationFrame(panFrame)
      panFrame = 0
      frame.scrollLeft = pendingScrollLeft
      frame.scrollTop = pendingScrollTop
    }
  }

  document.addEventListener('pointerdown', onPointerDown)
  document.addEventListener('pointermove', onPointerMove, { passive: false })
  document.addEventListener('pointerup', stopDrag)
  document.addEventListener('pointercancel', stopDrag)
  document.addEventListener('click', onViewportNavigationClick, true)
  document.addEventListener('click', onZoomClick, true)
  document.addEventListener(
    'click',
    event => {
      if (!moved) {
        return
      }
      moved = false
      event.preventDefault()
      event.stopPropagation()
    },
    true,
  )

  const observer = new MutationObserver(() => {
    if (findFrameRaf) {
      return
    }
    findFrameRaf = requestAnimationFrame(() => {
      findFrameRaf = 0
      findFrame()
    })
  })
  observer.observe(document.body, { childList: true, subtree: true })
  findFrame()
}
