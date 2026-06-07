import {
  RUNTIME_TEXT_SNAPSHOTS,
  WENYU_REFERENCE_LABELS_SNAPSHOT,
  WENYU_TOWN_MODULES_SNAPSHOT,
} from './runtime_snapshot_manifest.js'
import {
  loadJsonGlobal,
  refreshTextSnapshot,
} from './runtime_snapshot_fetch.js'

const RUNTIME_REFRESH_INTERVAL_MS = 5000

export async function refreshRuntimeSnapshots() {
  await Promise.all(RUNTIME_TEXT_SNAPSHOTS.map(refreshTextSnapshot))
}

export function startRuntimeSnapshotRefresh() {
  if (globalThis.__moontownTownSnapshotRefreshTimer) {
    clearInterval(globalThis.__moontownTownSnapshotRefreshTimer)
  }
  globalThis.__moontownTownSnapshotRefreshTimer = setInterval(
    refreshRuntimeSnapshots,
    RUNTIME_REFRESH_INTERVAL_MS,
  )
}

export async function loadWenyuReferenceLabels() {
  await loadJsonGlobal(WENYU_REFERENCE_LABELS_SNAPSHOT)
}

export async function loadWenyuTownModules() {
  await refreshTextSnapshot(WENYU_TOWN_MODULES_SNAPSHOT)
}

globalThis.__moontownRefreshRuntimeSnapshots = refreshRuntimeSnapshots
