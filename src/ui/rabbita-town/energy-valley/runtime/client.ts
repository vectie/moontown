import { normalizeRuntimeProjection } from './normalize'
import type {
  RuntimeProjection,
  RuntimeProjectionState,
} from './types'

export const DEFAULT_RUNTIME_PROJECTION_URL = '/energy-valley-runtime.json'
export const DEFAULT_RUNTIME_POLL_INTERVAL_MS = 2_000
export const DEFAULT_RUNTIME_STALE_AFTER_MS = 75_000

type Timer = ReturnType<typeof globalThis.setTimeout>
type StateListener = () => void

export interface RuntimeProjectionControllerOptions {
  url?: string
  intervalMs?: number
  staleAfterMs?: number
  fetchFn?: typeof fetch
  now?: () => number
  setTimeoutFn?: typeof globalThis.setTimeout
  clearTimeoutFn?: typeof globalThis.clearTimeout
}

export interface RuntimeProjectionController {
  getSnapshot: () => RuntimeProjectionState
  subscribe: (listener: StateListener) => () => void
  start: () => void
  stop: () => void
  refresh: () => void
  dispose: () => void
}

function errorMessage(value: unknown): string {
  if (value instanceof Error && value.message.trim()) return value.message
  return 'Unable to read the MoonTown runtime.'
}

function positiveDuration(value: number | undefined, fallback: number): number {
  return typeof value === 'number' && Number.isFinite(value) && value > 0
    ? value
    : fallback
}

export function createRuntimeProjectionController(
  options: RuntimeProjectionControllerOptions = {},
): RuntimeProjectionController {
  const url = options.url ?? DEFAULT_RUNTIME_PROJECTION_URL
  const intervalMs = positiveDuration(
    options.intervalMs,
    DEFAULT_RUNTIME_POLL_INTERVAL_MS,
  )
  const staleAfterMs = positiveDuration(
    options.staleAfterMs,
    DEFAULT_RUNTIME_STALE_AFTER_MS,
  )
  const fetchFn = options.fetchFn ?? globalThis.fetch.bind(globalThis)
  const now = options.now ?? Date.now
  const setTimeoutFn = options.setTimeoutFn ?? globalThis.setTimeout
  const clearTimeoutFn = options.clearTimeoutFn ?? globalThis.clearTimeout

  let state: RuntimeProjectionState = {
    phase: 'loading',
    projection: null,
  }
  let active = false
  let disposed = false
  let requestSequence = 0
  let request: AbortController | null = null
  let pollTimer: Timer | null = null
  let staleTimer: Timer | null = null
  let liveFreshAt: number | null = null
  const listeners = new Set<StateListener>()

  function emit(next: RuntimeProjectionState): void {
    if (disposed) return
    state = next
    for (const listener of listeners) listener()
  }

  function clearTimer(timer: Timer | null): null {
    if (timer !== null) clearTimeoutFn(timer)
    return null
  }

  function clearPollTimer(): void {
    pollTimer = clearTimer(pollTimer)
  }

  function clearStaleTimer(): void {
    staleTimer = clearTimer(staleTimer)
  }

  function markStale(): void {
    if (
      !active ||
      state.projection?.mode !== 'live' ||
      liveFreshAt === null
    ) {
      return
    }
    const age = Math.max(0, now() - liveFreshAt)
    if (age < staleAfterMs) {
      staleTimer = setTimeoutFn(markStale, staleAfterMs - age)
      return
    }
    emit({
      phase: 'stale',
      projection: state.projection,
      error: state.error,
      lastUpdatedAt: state.lastUpdatedAt,
    })
  }

  function armStaleTimer(): void {
    clearStaleTimer()
    if (liveFreshAt === null) return
    const remaining = staleAfterMs - Math.max(0, now() - liveFreshAt)
    if (remaining <= 0) {
      markStale()
      return
    }
    staleTimer = setTimeoutFn(markStale, remaining)
  }

  function acceptProjection(projection: RuntimeProjection): void {
    const receivedAt = now()
    if (projection.mode === 'unavailable') {
      liveFreshAt = null
      clearStaleTimer()
      emit({
        phase: 'unavailable',
        projection,
        lastUpdatedAt: receivedAt,
      })
      return
    }

    // A future server timestamp cannot keep a disconnected client "live"
    // indefinitely. Freshness is capped at the moment the response arrived.
    liveFreshAt = Math.min(receivedAt, Date.parse(projection.observedAt))
    emit({
      phase: 'live',
      projection,
      lastUpdatedAt: receivedAt,
    })
    armStaleTimer()
  }

  function acceptError(value: unknown): void {
    const message = errorMessage(value)
    if (
      state.projection?.mode === 'live' &&
      liveFreshAt !== null &&
      now() - liveFreshAt >= staleAfterMs
    ) {
      emit({
        phase: 'stale',
        projection: state.projection,
        error: message,
        lastUpdatedAt: state.lastUpdatedAt,
      })
      return
    }
    emit({
      phase: 'error',
      projection: state.projection,
      error: message,
      lastUpdatedAt: state.lastUpdatedAt,
    })
  }

  function schedulePoll(): void {
    clearPollTimer()
    if (!active || disposed) return
    pollTimer = setTimeoutFn(() => {
      void poll()
    }, intervalMs)
  }

  async function poll(): Promise<void> {
    if (!active || disposed) return
    clearPollTimer()
    const sequence = ++requestSequence
    request?.abort()
    const controller = new AbortController()
    request = controller

    try {
      const response = await fetchFn(url, {
        method: 'GET',
        headers: { Accept: 'application/json' },
        cache: 'no-store',
        credentials: 'same-origin',
        signal: controller.signal,
      })
      if (!response.ok) {
        throw new Error(`Runtime request failed (${response.status}).`)
      }
      const projection = normalizeRuntimeProjection(await response.json())
      if (
        active &&
        !disposed &&
        !controller.signal.aborted &&
        sequence === requestSequence
      ) {
        acceptProjection(projection)
      }
    } catch (error) {
      if (
        active &&
        !disposed &&
        !controller.signal.aborted &&
        sequence === requestSequence
      ) {
        acceptError(error)
      }
    } finally {
      if (sequence === requestSequence) {
        request = null
        schedulePoll()
      }
    }
  }

  function start(): void {
    if (disposed || active) return
    active = true
    if (state.projection?.mode === 'live' && liveFreshAt !== null) {
      armStaleTimer()
    }
    void poll()
  }

  function stop(): void {
    if (!active) return
    active = false
    requestSequence += 1
    request?.abort()
    request = null
    clearPollTimer()
    clearStaleTimer()
  }

  function refresh(): void {
    if (disposed) return
    if (!active) {
      start()
      return
    }
    requestSequence += 1
    request?.abort()
    request = null
    clearPollTimer()
    void poll()
  }

  function dispose(): void {
    if (disposed) return
    stop()
    disposed = true
    listeners.clear()
  }

  return {
    getSnapshot: () => state,
    subscribe(listener) {
      if (disposed) return () => {}
      listeners.add(listener)
      return () => listeners.delete(listener)
    },
    start,
    stop,
    refresh,
    dispose,
  }
}
