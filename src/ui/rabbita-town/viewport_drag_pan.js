const VIEWPORT_PATH_FRAGMENT = 'viewport'
const VIEWPORT_FRAME_SELECTOR = '.viewport-frame'
const INITIAL_FOCUS_SELECTORS = [
  '.node-city-hall',
  '.node-book-house',
  '.scene-node',
]
const DRAG_IGNORE_SELECTOR = 'button, a, input, textarea, select, [contenteditable="true"]'
const VIEWPORT_NAVIGATION_SELECTOR = 'a.wenyu-module-building[href], a.viewport-back-town[href]'
const ZOOM_IN_SELECTOR = '.viewport-zoom-in'
const ZOOM_OUT_SELECTOR = '.viewport-zoom-out'
const ZOOM_TRANSITION_MS = 140
const DRAG_THRESHOLD_PX = 4
const ZOOM_LIMITS = {
  min: 0.55,
  max: 1.9,
  step: 0.25,
}

export function installViewportDragPan() {
  if (!viewportPathEnabled(globalThis.location)) {
    return
  }

  createViewportDragPanController(document, globalThis).install()
}

function viewportPathEnabled(location) {
  return location?.pathname?.includes(VIEWPORT_PATH_FRAGMENT) === true
}

function createViewportDragPanController(documentRef, windowRef) {
  const state = {
    frame: null,
    dragging: false,
    moved: false,
    pointerId: null,
    startX: 0,
    startY: 0,
    startScrollLeft: 0,
    startScrollTop: 0,
    pendingScrollLeft: 0,
    pendingScrollTop: 0,
    panFrame: 0,
    findFrameRaf: 0,
    zoomResetTimer: 0,
    initialPanDone: false,
    zoom: 1,
  }

  function install() {
    documentRef.addEventListener('pointerdown', onPointerDown)
    documentRef.addEventListener('pointermove', onPointerMove, { passive: false })
    documentRef.addEventListener('pointerup', stopDrag)
    documentRef.addEventListener('pointercancel', stopDrag)
    documentRef.addEventListener('click', onViewportNavigationClick, true)
    documentRef.addEventListener('click', onZoomClick, true)
    documentRef.addEventListener('click', suppressClickAfterDrag, true)
    observeFrameChanges()
    findFrame()
  }

  function findFrame() {
    state.frame = documentRef.querySelector(VIEWPORT_FRAME_SELECTOR)
    if (state.frame) {
      applyZoom(state.zoom, { preserveCenter: false })
      centerInitialViewport()
    }
    return state.frame
  }

  function centerInitialViewport() {
    if (!state.frame || state.initialPanDone) {
      return
    }

    const focus = findInitialFocus(documentRef)
    windowRef.requestAnimationFrame(() => {
      const maxLeft = Math.max(0, state.frame.scrollWidth - state.frame.clientWidth)
      const maxTop = Math.max(0, state.frame.scrollHeight - state.frame.clientHeight)
      const targetLeft = focus
        ? focus.offsetLeft - state.frame.clientWidth * 0.35
        : state.frame.scrollWidth * 0.5 - state.frame.clientWidth * 0.5
      const targetTop = focus
        ? focus.offsetTop - state.frame.clientHeight * 0.44
        : state.frame.scrollHeight * 0.5 - state.frame.clientHeight * 0.5

      state.frame.scrollLeft = clampScroll(targetLeft, maxLeft)
      state.frame.scrollTop = clampScroll(targetTop, maxTop)
      state.initialPanDone = true
    })
  }

  function applyZoom(nextZoom, options = {}) {
    const activeFrame = state.frame || findFrame()
    if (!activeFrame) {
      return
    }

    const previousZoom = state.zoom
    const centerX = activeFrame.scrollLeft + activeFrame.clientWidth / 2
    const centerY = activeFrame.scrollTop + activeFrame.clientHeight / 2
    state.zoom = clampZoom(nextZoom)
    if (state.zoom === previousZoom) {
      syncZoomDataset(activeFrame)
      return
    }

    activeFrame.classList.add('is-zooming')
    windowRef.clearTimeout(state.zoomResetTimer)
    state.zoomResetTimer = windowRef.setTimeout(() => {
      activeFrame.classList.remove('is-zooming')
    }, ZOOM_TRANSITION_MS)
    syncZoomDataset(activeFrame)
    if (options.preserveCenter === false || previousZoom === 0) {
      return
    }

    windowRef.requestAnimationFrame(() => {
      const ratio = state.zoom / previousZoom
      activeFrame.scrollLeft = centerX * ratio - activeFrame.clientWidth / 2
      activeFrame.scrollTop = centerY * ratio - activeFrame.clientHeight / 2
    })
  }

  function syncZoomDataset(activeFrame) {
    if (activeFrame.dataset.zoom === String(state.zoom)) {
      return
    }
    activeFrame.style.setProperty('--viewport-zoom', String(state.zoom))
    activeFrame.dataset.zoom = String(state.zoom)
  }

  function onZoomClick(event) {
    const zoomIn = event.target?.closest?.(ZOOM_IN_SELECTOR)
    const zoomOut = event.target?.closest?.(ZOOM_OUT_SELECTOR)
    if (!zoomIn && !zoomOut) {
      return
    }

    event.preventDefault()
    event.stopPropagation()
    event.stopImmediatePropagation?.()
    applyZoom(state.zoom + (zoomIn ? ZOOM_LIMITS.step : -ZOOM_LIMITS.step))
  }

  function onViewportNavigationClick(event) {
    const link = event.target?.closest?.(VIEWPORT_NAVIGATION_SELECTOR)
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
    windowRef.location.href = href
    windowRef.requestAnimationFrame(() => {
      windowRef.location.reload()
    })
  }

  function onPointerDown(event) {
    const activeFrame = state.frame || findFrame()
    if (!activeFrame || shouldIgnoreDragStart(event.target)) {
      return
    }

    state.dragging = true
    state.moved = false
    state.pointerId = event.pointerId
    state.startX = event.clientX
    state.startY = event.clientY
    state.startScrollLeft = activeFrame.scrollLeft
    state.startScrollTop = activeFrame.scrollTop
    state.pendingScrollLeft = state.startScrollLeft
    state.pendingScrollTop = state.startScrollTop
    activeFrame.classList.add('is-drag-panning')
    activeFrame.setPointerCapture?.(event.pointerId)
  }

  function onPointerMove(event) {
    if (!state.dragging || event.pointerId !== state.pointerId || !state.frame) {
      return
    }

    const dx = event.clientX - state.startX
    const dy = event.clientY - state.startY
    if (Math.abs(dx) + Math.abs(dy) > DRAG_THRESHOLD_PX) {
      state.moved = true
    }
    state.pendingScrollLeft = state.startScrollLeft - dx
    state.pendingScrollTop = state.startScrollTop - dy
    if (!state.panFrame) {
      state.panFrame = windowRef.requestAnimationFrame(flushPan)
    }
    event.preventDefault()
  }

  function flushPan() {
    state.panFrame = 0
    if (!state.dragging || !state.frame) {
      return
    }
    state.frame.scrollLeft = state.pendingScrollLeft
    state.frame.scrollTop = state.pendingScrollTop
  }

  function stopDrag(event) {
    if (!state.dragging || event.pointerId !== state.pointerId || !state.frame) {
      return
    }

    state.frame.releasePointerCapture?.(event.pointerId)
    state.frame.classList.remove('is-drag-panning')
    state.dragging = false
    state.pointerId = null
    if (state.panFrame) {
      windowRef.cancelAnimationFrame(state.panFrame)
      state.panFrame = 0
      state.frame.scrollLeft = state.pendingScrollLeft
      state.frame.scrollTop = state.pendingScrollTop
    }
  }

  function suppressClickAfterDrag(event) {
    if (!state.moved) {
      return
    }
    state.moved = false
    event.preventDefault()
    event.stopPropagation()
  }

  function observeFrameChanges() {
    const observer = new windowRef.MutationObserver(() => {
      if (state.findFrameRaf) {
        return
      }
      state.findFrameRaf = windowRef.requestAnimationFrame(() => {
        state.findFrameRaf = 0
        findFrame()
      })
    })
    observer.observe(documentRef.body, { childList: true, subtree: true })
  }

  function shouldIgnoreDragStart(target) {
    return target?.closest?.(DRAG_IGNORE_SELECTOR)
  }

  return { install }
}

function findInitialFocus(documentRef) {
  for (const selector of INITIAL_FOCUS_SELECTORS) {
    const element = documentRef.querySelector(selector)
    if (element) {
      return element
    }
  }
  return null
}

function clampZoom(value) {
  const rounded = Math.round(value * 100) / 100
  return Math.min(ZOOM_LIMITS.max, Math.max(ZOOM_LIMITS.min, rounded))
}

function clampScroll(value, maxValue) {
  return Math.min(maxValue, Math.max(0, value))
}
