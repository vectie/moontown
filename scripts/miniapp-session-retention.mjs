export const MAX_MINIAPP_SESSIONS = 256

/**
 * Remove unusable dev sessions and retain the sessions that expire latest.
 * Ties are ordered by session id so every process makes the same eviction
 * choice for the same map contents.
 */
export function pruneMiniappSessions(
  sessions,
  nowMs = Date.now(),
  maxSessions = MAX_MINIAPP_SESSIONS,
) {
  for (const [sessionId, session] of sessions) {
    const expiresAtMs = Number(session?.expiresAtMs)
    if (!Number.isFinite(expiresAtMs) || expiresAtMs <= nowMs) {
      sessions.delete(sessionId)
    }
  }

  const limit = Math.max(0, Math.floor(Number(maxSessions) || 0))
  const overflow = sessions.size - limit
  if (overflow <= 0) return sessions

  const oldest = [...sessions.entries()].sort((left, right) => {
    const expiryOrder = Number(left[1].expiresAtMs) - Number(right[1].expiresAtMs)
    if (expiryOrder) return expiryOrder
    const leftId = String(left[0])
    const rightId = String(right[0])
    return leftId < rightId ? -1 : leftId > rightId ? 1 : 0
  })
  for (let index = 0; index < overflow; index += 1) {
    sessions.delete(oldest[index][0])
  }
  return sessions
}

/**
 * Resolve local-backend authentication after retention has run. An explicitly
 * supplied token is authoritative: it must never fall through to the
 * development user fallback after expiry or eviction.
 */
export function authorizeMiniappRequest({
  sessions,
  users,
  sessionId = '',
  userId = '',
  nowMs = Date.now(),
}) {
  pruneMiniappSessions(sessions, nowMs)
  if (sessionId) {
    const session = sessions.get(sessionId)
    return session
      ? { ok: true, userId: session.userId, sessionId }
      : { ok: false, status: 401, reason: 'session-invalid' }
  }

  const effectiveUserId = userId || 'user-a'
  return users.some(user => user.id === effectiveUserId)
    ? { ok: true, userId: effectiveUserId, sessionId: '' }
    : {
        ok: false,
        status: 401,
        reason: 'session-invalid',
        userId: effectiveUserId,
      }
}
