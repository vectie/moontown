import test from 'node:test'
import assert from 'node:assert/strict'

import {
  MAX_MINIAPP_SESSIONS,
  authorizeMiniappRequest,
  pruneMiniappSessions,
} from './miniapp-session-retention.mjs'

test('session retention removes expired and malformed entries', () => {
  const sessions = new Map([
    ['expired', { expiresAtMs: 99 }],
    ['boundary', { expiresAtMs: 100 }],
    ['malformed', { expiresAtMs: 'never' }],
    ['live', { expiresAtMs: 101 }],
  ])

  pruneMiniappSessions(sessions, 100)

  assert.deepEqual([...sessions.keys()], ['live'])
})

test('session retention deterministically evicts the oldest expiries', () => {
  const sessions = new Map()
  for (let index = MAX_MINIAPP_SESSIONS + 12; index >= 1; index -= 1) {
    const id = `session-${String(index).padStart(3, '0')}`
    sessions.set(id, { expiresAtMs: 10_000 + index })
  }

  pruneMiniappSessions(sessions, 1_000)

  assert.equal(sessions.size, MAX_MINIAPP_SESSIONS)
  assert.equal(sessions.has('session-012'), false)
  assert.equal(sessions.has('session-013'), true)
  assert.equal(sessions.has(`session-${MAX_MINIAPP_SESSIONS + 12}`), true)
})

test('equal-expiry eviction uses session id as a stable tie-breaker', () => {
  const sessions = new Map([
    ['session-c', { expiresAtMs: 5_000 }],
    ['session-a', { expiresAtMs: 5_000 }],
    ['session-b', { expiresAtMs: 5_000 }],
  ])

  pruneMiniappSessions(sessions, 1_000, 2)

  assert.deepEqual([...sessions.keys()].sort(), ['session-b', 'session-c'])
})

test('an expired explicit token is rejected instead of using the dev fallback', () => {
  const sessions = new Map([
    ['expired-token', { userId: 'user-b', expiresAtMs: 100 }],
  ])

  const result = authorizeMiniappRequest({
    sessions,
    users: [{ id: 'user-a' }, { id: 'user-b' }],
    sessionId: 'expired-token',
    nowMs: 100,
  })

  assert.deepEqual(result, {
    ok: false,
    status: 401,
    reason: 'session-invalid',
  })
  assert.equal(sessions.has('expired-token'), false)
})
