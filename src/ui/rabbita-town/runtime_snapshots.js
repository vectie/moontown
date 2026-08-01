import {
  WENYU_REFERENCE_BUILDINGS_SNAPSHOT,
  RUNTIME_TEXT_SNAPSHOTS,
  WENYU_REFERENCE_LABELS_SNAPSHOT,
  WENYU_REFERENCE_ROADS_SNAPSHOT,
  WENYU_TOWN_MODULES_SNAPSHOT,
  KNOWLEDGE_DOMAIN_CATALOG_SNAPSHOT,
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

export function indexWenyuReferenceBuildingComponents() {
  const snapshot = globalThis.__wenyuReferenceBuildings
  const width = snapshot?.tileGrid?.width
  const height = snapshot?.tileGrid?.height
  const rows = snapshot?.labelRows
  if (
    snapshot?.schema !== 'moontown.wenyu_reference_buildings.v4' ||
    width !== 256 ||
    height !== 144 ||
    !Array.isArray(rows) ||
    rows.length !== height ||
    rows.some(row => typeof row !== 'string' || row.length !== width)
  ) {
    globalThis.__wenyuReferenceBuildingComponentRows = null
    return
  }

  const codeForKind = {
    lowrise: 'l',
    row: 'r',
    block: 'b',
    tower: 't',
    courtyard: 'q',
    campus: 'c',
    civic: 'v',
    industrial: 'i',
  }
  const componentRows = Array.from(
    { length: height },
    () => Array(width).fill(null),
  )
  for (let index = 0; index < (snapshot.components || []).length; index += 1) {
    const component = snapshot.components[index]
    const code = codeForKind[component?.type]
    const bbox = component?.bbox
    if (!code || !bbox) {
      continue
    }
    for (let y = bbox.minY; y <= bbox.maxY; y += 1) {
      for (let x = bbox.minX; x <= bbox.maxX; x += 1) {
        if (
          rows[y]?.[x] === code &&
          componentRows[y]?.[x] == null
        ) {
          componentRows[y][x] = {
            index,
            anchorX: bbox.minX,
            anchorY: bbox.minY,
          }
        }
      }
    }
  }
  globalThis.__wenyuReferenceBuildingComponentRows = componentRows
}

export async function loadWenyuReferenceBuildings() {
  await loadJsonGlobal(WENYU_REFERENCE_BUILDINGS_SNAPSHOT)
  indexWenyuReferenceBuildingComponents()
}

export async function loadWenyuReferenceRoads() {
  await loadJsonGlobal(WENYU_REFERENCE_ROADS_SNAPSHOT)
}

export async function loadWenyuTownModules() {
  await refreshTextSnapshot(WENYU_TOWN_MODULES_SNAPSHOT)
}

export async function loadKnowledgeDomainCatalog() {
  await refreshTextSnapshot(KNOWLEDGE_DOMAIN_CATALOG_SNAPSHOT)
  const text = globalThis.__moontownKnowledgeDomainCatalogJson || ''
  if (!text) {
    globalThis.__moontownKnowledgeDomainCatalogDigest = ''
    return
  }
  const bytes = new TextEncoder().encode(text)
  const digest = await globalThis.crypto.subtle.digest('SHA-256', bytes)
  const hex = Array.from(new Uint8Array(digest), byte =>
    byte.toString(16).padStart(2, '0')).join('')
  globalThis.__moontownKnowledgeDomainCatalogDigest = `sha256:${hex}`
}

globalThis.__moontownRefreshRuntimeSnapshots = refreshRuntimeSnapshots
