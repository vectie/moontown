export function versionedUrl(url) {
  return `${url}?ts=${Date.now()}`
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
    const response = await fetch(versionedUrl(snapshot.url), { cache: 'no-store' })
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
