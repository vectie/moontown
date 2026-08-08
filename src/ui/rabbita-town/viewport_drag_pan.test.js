import test from 'node:test'
import assert from 'node:assert/strict'

import {
  installViewportDragPan,
  teardownViewportDragPan,
} from './viewport_drag_pan.js'

function createHarness() {
  const listeners = new Map()
  const rafs = new Map()
  const timers = new Map()
  const observers = []
  let nextId = 1

  const listenerKey = (name, options) =>
    `${name}:${options === true || options?.capture === true}`
  const frame = {
    clientWidth: 800,
    clientHeight: 600,
    scrollWidth: 1280,
    scrollHeight: 720,
    scrollLeft: 0,
    scrollTop: 0,
    dataset: {},
    style: { setProperty() {} },
    classList: { add() {}, remove() {} },
    querySelector() {
      return { offsetWidth: 1280, offsetHeight: 720 }
    },
    releasePointerCapture() {},
  }
  const documentRef = {
    body: {},
    addEventListener(name, callback, options) {
      const key = listenerKey(name, options)
      const callbacks = listeners.get(key) || new Set()
      callbacks.add(callback)
      listeners.set(key, callbacks)
    },
    removeEventListener(name, callback, options) {
      const key = listenerKey(name, options)
      const callbacks = listeners.get(key)
      callbacks?.delete(callback)
      if (callbacks?.size === 0) listeners.delete(key)
    },
    querySelector(selector) {
      return selector === '.viewport-frame' ? frame : null
    },
  }
  class MutationObserver {
    constructor(callback) {
      this.callback = callback
      this.disconnected = false
      observers.push(this)
    }

    observe() {}

    disconnect() {
      this.disconnected = true
    }
  }
  const windowRef = {
    location: {
      href: 'http://local/index.html',
      reload() {},
    },
    MutationObserver,
    requestAnimationFrame(callback) {
      const id = nextId++
      rafs.set(id, callback)
      return id
    },
    cancelAnimationFrame(id) {
      rafs.delete(id)
    },
    setTimeout(callback) {
      const id = nextId++
      timers.set(id, callback)
      return id
    },
    clearTimeout(id) {
      timers.delete(id)
    },
  }
  return {
    documentRef,
    windowRef,
    observers,
    listenerCount: () =>
      [...listeners.values()].reduce((total, callbacks) => total + callbacks.size, 0),
    rafCount: () => rafs.size,
    timerCount: () => timers.size,
  }
}

test('viewport drag-pan install is idempotent and teardown releases resources', () => {
  const harness = createHarness()
  const first = installViewportDragPan(harness.documentRef, harness.windowRef)
  const second = installViewportDragPan(harness.documentRef, harness.windowRef)

  assert.equal(second, first)
  assert.equal(harness.listenerCount(), 7)
  assert.equal(harness.observers.length, 1)
  assert.equal(harness.rafCount(), 1)

  teardownViewportDragPan(harness.windowRef)

  assert.equal(first.isInstalled(), false)
  assert.equal(harness.listenerCount(), 0)
  assert.equal(harness.rafCount(), 0)
  assert.equal(harness.timerCount(), 0)
  assert.equal(harness.observers[0].disconnected, true)
  assert.equal(harness.windowRef.__moontownViewportDragPanController, undefined)
})

test('operations route tears down an already-installed controller', () => {
  const harness = createHarness()
  const controller = installViewportDragPan(harness.documentRef, harness.windowRef)
  harness.windowRef.location.href = 'http://local/index.html?surface=operations'

  assert.equal(
    installViewportDragPan(harness.documentRef, harness.windowRef),
    null,
  )
  assert.equal(controller.isInstalled(), false)
  assert.equal(harness.listenerCount(), 0)
  assert.equal(harness.rafCount(), 0)
})
