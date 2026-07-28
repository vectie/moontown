import assert from 'node:assert/strict'
import test from 'node:test'
import {
  buildOperatorRequestRecords,
  normalizeOperatorPayload,
  persistOperatorRequestRecords,
} from './vite_api_handlers.js'

const POLICY = { sourcePolicy: 'approved sources only' }

test('repeat operator titles receive distinct request and standing-goal identities', () => {
  const input = normalizeOperatorPayload({
    title: 'Track agent work',
    prompt: 'Inspect durable results.',
  })
  const first = buildOperatorRequestRecords(input, POLICY, {
    nowMs: 1_000,
    nonce: 'first',
  })
  const second = buildOperatorRequestRecords(input, POLICY, {
    nowMs: 1_000,
    nonce: 'second',
  })

  assert.notEqual(first.request.id, second.request.id)
  assert.notEqual(first.goal.id, second.goal.id)
  assert.equal(first.request.standing_goal_id, first.goal.id)
  assert.equal(second.request.standing_goal_id, second.goal.id)
  assert.equal(Object.hasOwn(first.goal, 'last_run_tick'), false)
})

test('explicit operator goal identity remains intentionally reusable', () => {
  const input = normalizeOperatorPayload({
    title: 'Track agent work',
    prompt: 'Inspect durable results.',
    goal_id: 'shared-agent-work-watch',
  })
  const first = buildOperatorRequestRecords(input, POLICY, {
    nowMs: 1_000,
    nonce: 'first',
  })
  const second = buildOperatorRequestRecords(input, POLICY, {
    nowMs: 2_000,
    nonce: 'second',
  })

  assert.notEqual(first.request.id, second.request.id)
  assert.equal(first.goal.id, 'shared-agent-work-watch')
  assert.equal(second.goal.id, 'shared-agent-work-watch')
})

test('partial operator persistence rolls back an activated standing goal', async () => {
  const records = buildOperatorRequestRecords(
    normalizeOperatorPayload({
      title: 'Rollback request',
      prompt: 'Exercise the persistence boundary.',
    }),
    POLICY,
    { nowMs: 3_000, nonce: 'rollback' },
  )
  const originalGoals = [{ id: 'existing-goal', enabled: true }]
  let goals = [...originalGoals]
  const writtenRequests = []
  const storage = {
    readGoals: async () => [...goals],
    writeGoals: async value => {
      goals = [...value]
    },
    writeRequest: async value => {
      writtenRequests.push({ ...value })
    },
    appendRequest: async () => {
      throw new Error('ledger unavailable')
    },
  }

  await assert.rejects(
    persistOperatorRequestRecords(records, storage),
    /was not accepted/,
  )
  assert.deepEqual(goals, originalGoals)
  assert.equal(writtenRequests.at(-1).status, 'failed')
  assert.equal(
    writtenRequests.some(request => request.status === 'preparing'),
    true,
  )
})
