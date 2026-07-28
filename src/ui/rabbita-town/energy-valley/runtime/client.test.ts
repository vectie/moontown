import assert from 'node:assert/strict'
import test from 'node:test'
import {
  createRuntimeProjectionController,
  DEFAULT_RUNTIME_STALE_AFTER_MS,
  type RuntimeProjectionController,
} from './client'
import {
  normalizeRuntimeProjection,
  RuntimeProjectionValidationError,
} from './normalize'
import {
  RUNTIME_PROJECTION_SCHEMA,
  type RuntimeProjection,
  type RuntimeProjectionPhase,
} from './types'

function projection(
  overrides: Partial<RuntimeProjection> = {},
): RuntimeProjection {
  return {
    schema: RUNTIME_PROJECTION_SCHEMA,
    mode: 'live',
    observedAt: new Date().toISOString(),
    tick: 12,
    tasks: [
      {
        id: 'work-1',
        title: 'Verify the valley runtime',
        status: 'running',
        buildingModuleKey: 'energy-lab',
        agentId: 'agent-1',
        agentName: 'Aster',
        role: 'worker',
        artifacts: ['book/synthesis/report.html'],
        source: 'town-runtime',
      },
    ],
    agents: [
      {
        id: 'agent-1',
        name: 'Aster',
        role: 'worker',
        status: 'running',
        buildingModuleKey: 'energy-lab',
        workItemId: 'work-1',
      },
    ],
    ...overrides,
  }
}

function jsonResponse(value: unknown, status = 200): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: { 'Content-Type': 'application/json' },
  })
}

async function waitForPhase(
  controller: RuntimeProjectionController,
  phase: RuntimeProjectionPhase,
): Promise<void> {
  if (controller.getSnapshot().phase === phase) return
  await new Promise<void>((resolve, reject) => {
    const timeout = setTimeout(() => {
      unsubscribe()
      reject(new Error(`Timed out waiting for runtime phase ${phase}`))
    }, 1_000)
    const unsubscribe = controller.subscribe(() => {
      if (controller.getSnapshot().phase !== phase) return
      clearTimeout(timeout)
      unsubscribe()
      resolve()
    })
  })
}

test('normalizes the complete v1 runtime contract', () => {
  const normalized = normalizeRuntimeProjection(projection())
  assert.equal(normalized.schema, RUNTIME_PROJECTION_SCHEMA)
  assert.equal(normalized.mode, 'live')
  assert.equal(normalized.tasks[0]?.status, 'running')
  assert.equal(normalized.tasks[0]?.source, 'town-runtime')
  assert.deepEqual(normalized.tasks[0]?.artifacts, [
    'book/synthesis/report.html',
  ])
  assert.equal(normalized.agents[0]?.role, 'worker')
})

test('normalizes correlated collaboration, progress, and verified local results', () => {
  const source = projection({
    tasks: [{
      ...projection().tasks[0],
      requestId: 'operator-17',
      standingGoalId: 'audit-real-work',
      correlationId: 'audit-real-work',
      resultLinks: [{
        label: 'Evidence',
        url: '/book-output/research-agent-work-projection/book/synthesis/evidence.html',
        kind: 'evidence',
      }],
      collaboration: {
        mode: 'parallel',
        participants: [{
          runId: 'child-run-1',
          parentRunId: 'parent-run-1',
          family: 'research',
          status: 'running',
          startedAt: 1_753_670_000_000,
          completedAt: '2026-07-28T12:00:00Z',
          artifacts: ['book/synthesis/evidence.html'],
        }],
      },
      progress: {
        checkedSources: 12,
        newSources: 3,
        acceptedFacts: 2,
        rejectedFacts: 1,
        pagesChanged: 1,
        bookChanged: true,
      },
    }],
  })
  const normalized = normalizeRuntimeProjection(source)
  const task = normalized.tasks[0]
  assert.equal(task?.requestId, 'operator-17')
  assert.equal(task?.collaboration?.mode, 'parallel')
  assert.equal(
    task?.collaboration?.participants[0]?.startedAt,
    1_753_670_000_000,
  )
  assert.equal(task?.progress?.checkedSources, 12)
  assert.equal(task?.progress?.bookChanged, true)
  assert.equal(task?.resultLinks?.[0]?.kind, 'evidence')
})

test('rejects outbound or traversal result links', () => {
  for (const url of [
    'https://example.com/report',
    '//example.com/report',
    '/book-output/book/%2e%2e/private.txt',
    '/book-output/book/%252e%252e/private.txt',
  ]) {
    assert.throws(
      () => normalizeRuntimeProjection(projection({
        tasks: [{
          ...projection().tasks[0],
          resultLinks: [{ label: 'Unsafe', url, kind: 'report' }],
        }],
      })),
      RuntimeProjectionValidationError,
    )
  }
})

test('rejects malformed or unknown runtime data instead of presenting it as live', () => {
  assert.throws(
    () => normalizeRuntimeProjection({ ...projection(), tasks: undefined }),
    RuntimeProjectionValidationError,
  )
  assert.throws(
    () =>
      normalizeRuntimeProjection({
        ...projection(),
        agents: [{ ...projection().agents[0], status: 'dancing' }],
      }),
    RuntimeProjectionValidationError,
  )
  assert.throws(
    () =>
      normalizeRuntimeProjection({
        ...projection(),
        schema: 'moontown.energy-valley.runtime.v2',
      }),
    RuntimeProjectionValidationError,
  )
  assert.throws(
    () =>
      normalizeRuntimeProjection({
        ...projection(),
        observedAt: 'July 28, 2026',
      }),
    RuntimeProjectionValidationError,
  )
})

test('reports an explicit unavailable projection without calling it live', async () => {
  const unavailable = projection({
    mode: 'unavailable',
    tasks: [],
    agents: [],
    message: 'The MoonTown runtime is not connected.',
  })
  const controller = createRuntimeProjectionController({
    fetchFn: (async () => jsonResponse(unavailable)) as typeof fetch,
    intervalMs: 60_000,
  })

  controller.start()
  await waitForPhase(controller, 'unavailable')
  assert.equal(controller.getSnapshot().projection?.mode, 'unavailable')
  assert.equal(
    controller.getSnapshot().projection?.message,
    'The MoonTown runtime is not connected.',
  )
  controller.dispose()
})

test('reports invalid successful responses as an error', async () => {
  const controller = createRuntimeProjectionController({
    fetchFn: (async () =>
      jsonResponse({ mode: 'live', tasks: [], agents: [] })) as typeof fetch,
    intervalMs: 60_000,
  })

  controller.start()
  await waitForPhase(controller, 'error')
  assert.equal(controller.getSnapshot().projection, null)
  assert.match(controller.getSnapshot().error ?? '', /schema/)
  controller.dispose()
})

test('marks an old live observation stale immediately', async () => {
  const old = projection({
    observedAt: new Date(Date.now() - 60_000).toISOString(),
  })
  const controller = createRuntimeProjectionController({
    fetchFn: (async () => jsonResponse(old)) as typeof fetch,
    intervalMs: 60_000,
    staleAfterMs: 15_000,
  })

  controller.start()
  await waitForPhase(controller, 'stale')
  assert.equal(controller.getSnapshot().projection?.mode, 'live')
  assert.equal(controller.getSnapshot().lastUpdatedAt !== undefined, true)
  controller.dispose()
})

test('default stale window spans more than two daemon sleep cycles', () => {
  assert.equal(DEFAULT_RUNTIME_STALE_AFTER_MS, 75_000)
  assert.ok(DEFAULT_RUNTIME_STALE_AFTER_MS > 2 * 30_000)
})

test('disposal aborts an in-flight runtime request', async () => {
  let signal: AbortSignal | undefined
  const fetchFn = ((_input: RequestInfo | URL, init?: RequestInit) => {
    signal = init?.signal ?? undefined
    return new Promise<Response>((_resolve, reject) => {
      signal?.addEventListener('abort', () => {
        reject(new Error('aborted'))
      })
    })
  }) as typeof fetch
  const controller = createRuntimeProjectionController({
    fetchFn,
    intervalMs: 60_000,
  })

  controller.start()
  await Promise.resolve()
  assert.equal(signal?.aborted, false)
  controller.dispose()
  assert.equal(signal?.aborted, true)
})
