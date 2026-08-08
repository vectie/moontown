import {
  parseOperatorRequests,
  parseWatcherRecords,
} from './runtime_snapshot_parser.js'

export const RUNTIME_TEXT_SNAPSHOTS = [
  {
    url: './energy-valley-runtime.json',
    jsonGlobal: '__moontownEnergyValleyRuntimeJson',
    versionGlobal: '__moontownEnergyValleyRuntimeVersion',
    fallback:
      '{"schema":"moontown.energy-valley.runtime.v1","mode":"error","observedAt":"","tasks":[],"agents":[],"message":"Unable to read the MoonTown runtime."}',
  },
  {
    url: './town.json',
    jsonGlobal: '__moontownTownSnapshotJson',
    versionGlobal: '__moontownTownSnapshotVersion',
    fallback: '',
  },
  {
    url: './visual-projection.json',
    jsonGlobal: '__moontownVisualProjectionJson',
    versionGlobal: '__moontownVisualProjectionVersion',
    fallback: '',
  },
  {
    url: './module-projections.json',
    jsonGlobal: '__moontownModuleProjectionsJson',
    versionGlobal: '__moontownModuleProjectionsVersion',
    fallback: '{"projections":[]}',
  },
  {
    url: './moondesk-bridge.json',
    jsonGlobal: '__moontownMoondeskBridgeJson',
    versionGlobal: '__moontownMoondeskBridgeVersion',
    fallback: '{"records":[]}',
  },
  {
    url: './civic-status.json',
    jsonGlobal: '__moontownCivicStatusJson',
    versionGlobal: '__moontownCivicStatusVersion',
    fallback: '{"services":[]}',
  },
  {
    url: './tilemap/modules/moondesk-handoff.json',
    jsonGlobal: '__moontownMoondeskHandoffJson',
    versionGlobal: '__moontownMoondeskHandoffVersion',
    fallback: '{"artifacts":[]}',
  },
  {
    url: './daemon.json',
    jsonGlobal: '__moontownDaemonSnapshotJson',
    versionGlobal: '__moontownDaemonSnapshotVersion',
    fallback: '',
  },
  {
    url: './live-autonomy.json',
    jsonGlobal: '__moontownLiveAutonomyJson',
    versionGlobal: '__moontownLiveAutonomyVersion',
    fallback: '',
  },
  {
    url: './editor-pipeline.json',
    jsonGlobal: '__moontownEditorPipelineJson',
    versionGlobal: '__moontownEditorPipelineVersion',
    fallback: '',
  },
  {
    url: './standing-goals.json',
    jsonGlobal: '__moontownStandingGoalsJson',
    versionGlobal: '__moontownStandingGoalsVersion',
    fallback: '[]',
  },
  {
    url: './watchers/index.json',
    jsonGlobal: '__moontownWatcherRecordsJson',
    versionGlobal: '__moontownWatcherRecordsVersion',
    fallback: '[]',
    transform: text => JSON.stringify(parseWatcherRecords(text)),
  },
  {
    url: './operator-requests.json',
    jsonGlobal: '__moontownOperatorRequestsJson',
    versionGlobal: '__moontownOperatorRequestsVersion',
    fallback: '[]',
    transform: text => JSON.stringify(parseOperatorRequests(text)),
  },
  {
    url: './book-template-requests.json',
    jsonGlobal: '__moontownBookTemplateRequestsJson',
    versionGlobal: '__moontownBookTemplateRequestsVersion',
    fallback: '{"requests":[]}',
  },
]

export const WENYU_REFERENCE_LABELS_SNAPSHOT = {
  url: './tilemap/wenyu_reference_labels.json',
  jsonGlobal: '__wenyuReferenceLabels',
  fallback: null,
}

export const WENYU_REFERENCE_BUILDINGS_SNAPSHOT = {
  url: './tilemap/wenyu_reference_buildings.json',
  jsonGlobal: '__wenyuReferenceBuildings',
  fallback: null,
}

export const WENYU_REFERENCE_ROADS_SNAPSHOT = {
  url: './tilemap/wenyu_reference_roads.json',
  jsonGlobal: '__wenyuReferenceRoadGraph',
  fallback: null,
}

export const WENYU_TOWN_MODULES_SNAPSHOT = {
  url: './tilemap/modules/wenyu-town-modules.json',
  jsonGlobal: '__wenyuTownModulesJson',
  versionGlobal: '__wenyuTownModulesVersion',
  fallback: '{"modules":[]}',
}

export const KNOWLEDGE_DOMAIN_CATALOG_SNAPSHOT = {
  // The desktop service resolves this URL from the same source used for agent
  // routing, including an explicit environment override. Static deployments
  // serve the bundled file at the identical path.
  url: './knowledge-domain-catalog.json',
  jsonGlobal: '__moontownKnowledgeDomainCatalogJson',
  versionGlobal: '__moontownKnowledgeDomainCatalogVersion',
  fallback: '',
}
