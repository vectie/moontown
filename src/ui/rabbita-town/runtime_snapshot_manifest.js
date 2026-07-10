import { parseWatcherRecords } from './runtime_snapshot_parser.js'

export const RUNTIME_TEXT_SNAPSHOTS = [
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

export const WENYU_TOWN_MODULES_SNAPSHOT = {
  url: './tilemap/modules/wenyu-town-modules.json',
  jsonGlobal: '__wenyuTownModulesJson',
  versionGlobal: '__wenyuTownModulesVersion',
  fallback: '{"modules":[]}',
}
