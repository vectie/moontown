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

async function boot() {
  try {
    const response = await fetch('./town.json', { cache: 'no-store' })
    if (response.ok) {
      globalThis.__moontownTownSnapshotJson = await response.text()
    } else {
      globalThis.__moontownTownSnapshotJson = ''
    }
  } catch {
    globalThis.__moontownTownSnapshotJson = ''
  }

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
