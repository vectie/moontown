export function versionedUrl(url) {
  return `${url}?ts=${Date.now()}`
}

const SNAPSHOT_FETCH_TIMEOUT_MS = 1600

async function fetchSnapshot(url, readValue, cacheable) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), SNAPSHOT_FETCH_TIMEOUT_MS)
  try {
    const response = await fetch(cacheable ? url : versionedUrl(url), {
      cache: cacheable ? 'default' : 'no-store',
      signal: controller.signal,
    })
    if (!response.ok) throw new Error(`Snapshot HTTP ${response.status}`)
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
    setSnapshotValue(snapshot, value, options)
  } catch {
    setSnapshotFallback(snapshot, options)
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
