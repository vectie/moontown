// Browser I/O only. Identity, membership and permissions are resolved in MoonBit.
export async function loadUnifiedAccount() {
  const response = await fetch('/account/self.json', {
    credentials: 'same-origin', cache: 'no-store', signal: AbortSignal.timeout(4500),
  })
  // Compatibility with older/static desktop hosts; a configured provider never
  // returns disabled on an expired session or upstream failure.
  if (response.status === 404) return {authoritative: false, account: null}
  if (response.status === 401 || response.status === 403) {
    return {authoritative: true, account: null}
  }
  if (!response.ok) throw new Error('Unified identity unavailable')
  const result = await response.json()
  if (globalThis.__MOONTOWN_PUBLIC_PLATFORM === true &&
      result.storage_scope !== globalThis.__MOONTOWN_ACCOUNT_SCOPE) {
    // A login/logout in another tab between scope bootstrap and this request
    // must not load B's scene into A's browser-storage namespace.
    globalThis.location?.reload()
    throw new Error('Account changed during bootstrap')
  }
  if (result.state === 'disabled') return {authoritative: false, account: null}
  if (!['bound', 'sign-in-required', 'unavailable'].includes(result.state)) {
    throw new Error('Invalid unified identity response')
  }
  if (result.state === 'bound' && !result.account?.user_id) {
    throw new Error('Incomplete unified identity')
  }
  return {authoritative: true, account: result.state === 'bound' ? result.account : null}
}
