export function versionedUrl(url) {
  return `${url}?ts=${Date.now()}`
}

const SNAPSHOT_FETCH_TIMEOUT_MS = 1600

async function fetchSnapshot(url) {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), SNAPSHOT_FETCH_TIMEOUT_MS)
  try {
    return await fetch(versionedUrl(url), {
      cache: 'no-store',
      signal: controller.signal,
    })
  } finally {
    clearTimeout(timeout)
  }
}

export function setSnapshotFallback(snapshot) {
  setSnapshotValue(snapshot, snapshot.fallback)
}

export function bumpSnapshotVersion(snapshot) {
  globalThis[snapshot.versionGlobal] =
    (globalThis[snapshot.versionGlobal] || 0) + 1
}

function setSnapshotValue(snapshot, value, options = {}) {
  globalThis[snapshot.jsonGlobal] = value
  if (options.bumpVersion && snapshot.versionGlobal) {
    bumpSnapshotVersion(snapshot)
  }
}

async function loadSnapshotValue(snapshot, readValue, options = {}) {
  try {
    const response = await fetchSnapshot(snapshot.url)
    if (!response.ok) {
      setSnapshotFallback(snapshot)
      return
    }

    setSnapshotValue(snapshot, await readValue(response), options)
  } catch {
    setSnapshotFallback(snapshot)
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
  await loadSnapshotValue(snapshot, response => response.json())
}
