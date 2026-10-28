export function versionedUrl(url) {
  return `${url}?ts=${Date.now()}`
}

const SNAPSHOT_FETCH_TIMEOUT_MS = 1600

async function fetchSnapshot(url, readValue, cacheable) {
  const accountCompute = url === './secret-compute-room.json'
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), accountCompute ? 11000 : SNAPSHOT_FETCH_TIMEOUT_MS)
  try {
    const organization = accountCompute
      ? new URLSearchParams(globalThis.location?.search || '').get('compute-organization') : null
    const response = await fetch(cacheable ? url : versionedUrl(url), {
      cache: cacheable ? 'default' : 'no-store',
      credentials: 'same-origin',
      headers: organization ? {'X-LunaNexa-Organization': organization} : {},
      signal: controller.signal,
    })
    if (!response.ok) {
      const error = new Error(`Snapshot HTTP ${response.status}`)
      error.status = response.status
      throw error
    }
    // Keep the deadline active through body download and parsing.
    return await readValue(response)
  } finally {
    clearTimeout(timeout)
  }
}

export function setSnapshotFallback(snapshot, options = {}) {
  return setSnapshotValue(snapshot, snapshot.fallback, options)
}

export function bumpSnapshotVersion(snapshot) {
  globalThis[snapshot.versionGlobal] =
    (globalThis[snapshot.versionGlobal] || 0) + 1
}

export function setSnapshotValue(snapshot, value, options = {}) {
  const changed = !Object.is(globalThis[snapshot.jsonGlobal], value)
  globalThis[snapshot.jsonGlobal] = value
  if (changed && options.bumpVersion && snapshot.versionGlobal) {
    bumpSnapshotVersion(snapshot)
  }
  return changed
}

async function loadSnapshotValue(snapshot, readValue, options = {}) {
  try {
    const value = await fetchSnapshot(snapshot.url, readValue, options.cacheable)
    if (snapshot.url === './secret-compute-room.json' && globalThis.__moontownUnifiedAccountActive) {
      const scope = JSON.parse(value)?.scope
      const current = JSON.parse(globalThis.__moontownAccountContextJson || '{}')
      const currentId = current.account_kind === 'member' ? current.user_id : ''
      const nextId = scope?.account?.user_id || ''
      if ((scope?.state === 'bound' || scope?.state === 'sign-in-required' ||
           scope?.state === 'public-demo') && currentId !== nextId) {
        setSnapshotFallback(snapshot, options)
        globalThis.location?.reload()
        return
      }
    }
    setSnapshotValue(snapshot, value, options)
  } catch (error) {
    setSnapshotFallback(snapshot, options)
    if (snapshot.url === './secret-compute-room.json' &&
        globalThis.__moontownUnifiedAccountActive && error.status === 401) {
      // A revoked gateway session can return plain text before the BFF runs.
      // Clear the old account as well as its machines; never wait for a JSON scope.
      globalThis.__moontownAccountContextJson = '{}'
      globalThis.__moontownSessionToken = ''
      globalThis.location?.reload()
    }
  }
}

export async function refreshTextSnapshot(snapshot) {
  await loadSnapshotValue(
    snapshot,
    async response => {
      const text = await response.text()
      return snapshot.transform ? snapshot.transform(text) : text
    },
    { bumpVersion: true },
  )
}

export async function loadJsonGlobal(snapshot) {
  await loadSnapshotValue(snapshot, response => response.json(), {cacheable: true})
}
