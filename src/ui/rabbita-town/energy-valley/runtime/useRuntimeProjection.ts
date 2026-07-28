import {
  useCallback,
  useEffect,
  useMemo,
  useSyncExternalStore,
} from 'react'
import {
  createRuntimeProjectionController,
  type RuntimeProjectionControllerOptions,
} from './client'
import type {
  RuntimeProjection,
  RuntimeProjectionPhase,
} from './types'

export interface UseRuntimeProjectionResult {
  phase: RuntimeProjectionPhase
  projection: RuntimeProjection | null
  error?: string
  lastUpdatedAt?: number
  refresh: () => void
}

export function useRuntimeProjection(
  options: RuntimeProjectionControllerOptions = {},
): UseRuntimeProjectionResult {
  const controller = useMemo(
    () => createRuntimeProjectionController(options),
    [
      options.url,
      options.intervalMs,
      options.staleAfterMs,
      options.fetchFn,
      options.now,
      options.setTimeoutFn,
      options.clearTimeoutFn,
    ],
  )
  const state = useSyncExternalStore(
    controller.subscribe,
    controller.getSnapshot,
    controller.getSnapshot,
  )

  useEffect(() => {
    controller.start()
    return () => controller.stop()
  }, [controller])

  const refresh = useCallback(() => controller.refresh(), [controller])
  return useMemo(
    () => ({ ...state, refresh }),
    [refresh, state],
  )
}
