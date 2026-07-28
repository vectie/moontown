import assert from 'node:assert/strict'
import test from 'node:test'
import {
  DEFAULT_OPERATOR_REQUEST,
  matchesAcceptedRequest,
  OPERATOR_REQUEST_URL,
  submitOperatorRequest,
} from './requests'
import type { RuntimeWorkItem } from './types'

test('uses the safe long-cadence research defaults', () => {
  assert.equal(
    DEFAULT_OPERATOR_REQUEST.targetBookId,
    'research-agent-work-projection',
  )
  assert.equal(DEFAULT_OPERATOR_REQUEST.cadenceTicks, 1_000_000)
  assert.equal(DEFAULT_OPERATOR_REQUEST.qualityThreshold, 85)
})

test('matches accepted receipts across queued and dispatched correlation forms', () => {
  const accepted = {
    requestId: 'operator-17',
    standingGoalId: 'audit-real-work',
    status: 'accepted',
  } as const
  const task = {
    id: 'town-task-44',
    title: 'Audit',
    status: 'running',
    buildingModuleKey: 'energy-lab',
    artifacts: [],
    source: 'town-runtime',
  } satisfies RuntimeWorkItem
  assert.equal(matchesAcceptedRequest({
    ...task,
    requestId: 'operator-17',
  }, accepted), true)
  assert.equal(matchesAcceptedRequest({
    ...task,
    correlationId: 'standing-goal:audit-real-work',
  }, accepted), true)
  assert.equal(matchesAcceptedRequest({
    ...task,
    id: 'standing-goal:audit-real-work',
  }, accepted), true)
  assert.equal(matchesAcceptedRequest(task, accepted), false)
})

test('submits the exact operator request contract and normalizes its receipt', async () => {
  let requestUrl = ''
  let requestInit: RequestInit | undefined
  const fetchFn = (async (input: RequestInfo | URL, init?: RequestInit) => {
    requestUrl = String(input)
    requestInit = init
    return new Response(JSON.stringify({
      ok: true,
      request_id: 'operator-17',
      standing_goal_id: 'audit-real-work',
      status: 'accepted',
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    })
  }) as typeof fetch

  const receipt = await submitOperatorRequest({
    ...DEFAULT_OPERATOR_REQUEST,
    title: ' Audit real work ',
    prompt: ' Verify the runtime projection. ',
  }, { fetchFn })

  assert.equal(requestUrl, OPERATOR_REQUEST_URL)
  assert.equal(requestInit?.method, 'POST')
  assert.equal(requestInit?.credentials, 'same-origin')
  assert.deepEqual(JSON.parse(String(requestInit?.body)), {
    title: 'Audit real work',
    prompt: 'Verify the runtime projection.',
    target_book_id: 'research-agent-work-projection',
    cadence_ticks: 1_000_000,
    quality_threshold: 85,
  })
  assert.deepEqual(receipt, {
    requestId: 'operator-17',
    standingGoalId: 'audit-real-work',
    status: 'accepted',
  })
})

test('rejects missing required fields before touching the transport', async () => {
  let called = false
  const fetchFn = (async () => {
    called = true
    return new Response()
  }) as typeof fetch
  await assert.rejects(
    submitOperatorRequest(DEFAULT_OPERATOR_REQUEST, { fetchFn }),
    /Title is required/,
  )
  assert.equal(called, false)
})

test('surfaces a safe endpoint error and rejects malformed success data', async () => {
  await assert.rejects(
    submitOperatorRequest({
      ...DEFAULT_OPERATOR_REQUEST,
      title: 'Audit',
      prompt: 'Do the work',
    }, {
      fetchFn: (async () => new Response(JSON.stringify({
        ok: false,
        error: 'Runtime write transport is unavailable.',
      }), { status: 503 })) as typeof fetch,
    }),
    /Runtime write transport is unavailable/,
  )

  await assert.rejects(
    submitOperatorRequest({
      ...DEFAULT_OPERATOR_REQUEST,
      title: 'Audit',
      prompt: 'Do the work',
    }, {
      fetchFn: (async () => new Response(JSON.stringify({
        ok: true,
        status: 'accepted',
      }))) as typeof fetch,
    }),
    /invalid response/,
  )
})
