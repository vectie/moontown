///|
extern "js" fn load_bootstrap_town_snapshot_json() -> String =
  #| () => globalThis.__moontownTownSnapshotJson || ""

///|
extern "js" fn town_snapshot_version() -> Int =
  #| () => globalThis.__moontownTownSnapshotVersion || 0

///|
extern "js" fn load_bootstrap_visual_projection_json() -> String =
  #| () => globalThis.__moontownVisualProjectionJson || ""

///|
extern "js" fn visual_projection_version() -> Int =
  #| () => globalThis.__moontownVisualProjectionVersion || 0

///|
extern "js" fn load_bootstrap_module_projections_json() -> String =
  #| () => globalThis.__moontownModuleProjectionsJson || "{\"projections\":[]}"

///|
extern "js" fn module_projections_version() -> Int =
  #| () => globalThis.__moontownModuleProjectionsVersion || 0

///|
extern "js" fn load_bootstrap_civic_status_json() -> String =
  #| () => globalThis.__moontownCivicStatusJson || "{\"services\":[]}"

///|
extern "js" fn civic_status_version() -> Int =
  #| () => globalThis.__moontownCivicStatusVersion || 0

///|
extern "js" fn load_bootstrap_moondesk_handoff_json() -> String =
  #| () => globalThis.__moontownMoondeskHandoffJson || "{\"artifacts\":[]}"

///|
extern "js" fn moondesk_handoff_version() -> Int =
  #| () => globalThis.__moontownMoondeskHandoffVersion || 0

///|
extern "js" fn load_bootstrap_moondesk_bridge_json() -> String =
  #| () => globalThis.__moontownMoondeskBridgeJson || "{\"records\":[]}"

///|
extern "js" fn moondesk_bridge_version() -> Int =
  #| () => globalThis.__moontownMoondeskBridgeVersion || 0

///|
extern "js" fn load_bootstrap_daemon_snapshot_json() -> String =
  #| () => globalThis.__moontownDaemonSnapshotJson || ""

///|
extern "js" fn daemon_snapshot_version() -> Int =
  #| () => globalThis.__moontownDaemonSnapshotVersion || 0

///|
extern "js" fn load_bootstrap_live_autonomy_json() -> String =
  #| () => globalThis.__moontownLiveAutonomyJson || ""

///|
extern "js" fn live_autonomy_version() -> Int =
  #| () => globalThis.__moontownLiveAutonomyVersion || 0

///|
extern "js" fn load_bootstrap_editor_pipeline_json() -> String =
  #| () => globalThis.__moontownEditorPipelineJson || ""

///|
extern "js" fn editor_pipeline_version() -> Int =
  #| () => globalThis.__moontownEditorPipelineVersion || 0

///|
extern "js" fn load_bootstrap_standing_goals_json() -> String =
  #| () => globalThis.__moontownStandingGoalsJson || "[]"

///|
extern "js" fn standing_goals_version() -> Int =
  #| () => globalThis.__moontownStandingGoalsVersion || 0

///|
extern "js" fn load_bootstrap_watcher_records_json() -> String =
  #| () => globalThis.__moontownWatcherRecordsJson || "[]"

///|
extern "js" fn watcher_records_version() -> Int =
  #| () => globalThis.__moontownWatcherRecordsVersion || 0

///|
extern "js" fn load_bootstrap_operator_requests_json() -> String =
  #| () => globalThis.__moontownOperatorRequestsJson || "[]"

///|
extern "js" fn operator_requests_version() -> Int =
  #| () => globalThis.__moontownOperatorRequestsVersion || 0

///|
extern "js" fn load_bootstrap_wenyu_modules_json() -> String =
  #| () => globalThis.__wenyuTownModulesJson || "{\"modules\":[]}"

///|
extern "js" fn wenyu_modules_version() -> Int =
  #| () => globalThis.__wenyuTownModulesVersion || 0
