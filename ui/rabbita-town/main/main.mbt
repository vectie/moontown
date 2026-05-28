///|
using @html {
  a,
  article,
  aside,
  button,
  div,
  h1,
  h2,
  h3,
  header,
  img,
  input,
  main_,
  p,
  section,
  span,
  textarea,
}

///|
using @rabbita {type Cmd, type Dispatch}

///|
priv enum Strategy {
  Balanced
  Throughput
  Recovery
} derive(Eq)

///|
priv enum Selection {
  Overview
  Node(String)
  Worker(String)
}

///|
priv enum StateSourceKind {
  DemoSimulation
  SnapshotFile
} derive(Eq)

///|
priv enum ViewportMode {
  ViewMode
  EditorMode
  OutputMode
} derive(Eq)

///|
priv struct Model {
  tick : Int
  paused : Bool
  strategy : Strategy
  selection : Selection
  state_source : StateSourceKind
  viewport_mode : ViewportMode
  projection_snapshot : ProjectionSnapshot?
  snapshot_version : Int
  visual_projection : VisualProjectionSnapshot?
  visual_projection_version : Int
  module_projections : Array[BookProjectionFragment]
  module_projections_version : Int
  civic_status : CivicServicePortfolioSnapshot?
  civic_status_version : Int
  moondesk_handoff_artifacts : Array[MoondeskHandoffArtifact]
  moondesk_handoff_version : Int
  moondesk_bridge : MoondeskBridgeIndex?
  moondesk_bridge_version : Int
  daemon_snapshot : DaemonSnapshot?
  daemon_snapshot_version : Int
  standing_goals : Array[StandingGoalSnapshot]
  standing_goals_version : Int
  watcher_records : Array[WatcherRunRecordSnapshot]
  watcher_records_version : Int
  operator_requests : Array[OperatorRequestSnapshot]
  operator_requests_version : Int
  request_title : String
  request_prompt : String
  request_book_id : String
  request_cadence : String
  request_quality_threshold : String
  request_submitting : Bool
  request_status : String
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
}

///|
priv struct VitalityMetric {
  label : String
  value : String
  fill : Int
  tone : String
  detail : String
}

///|
priv enum Msg {
  Tick
  ViewportControlNoop
  TogglePause
  Step
  SelectWorker(String)
  SelectNode(String)
  SelectOverview
  SetStrategy(Strategy)
  SetViewportMode(ViewportMode)
  ToggleStateSource
  InjectBudget
  RelieveQueue
  StabilityDrill
  SetRequestTitle(String)
  SetRequestPrompt(String)
  SetRequestBookId(String)
  SetRequestCadence(String)
  SetRequestQualityThreshold(String)
  SubmitOperatorRequest
  OperatorRequestSubmitted(String)
}

///|
priv struct WorkerSim {
  id : String
  title : String
  role : String
  book_id : String
  status : @core.WorkerStatus
  zone_key : String
  energy : Int
  load : Int
  summary : String
}

///|
priv struct FeedItem {
  title : String
  detail : String
  tone : String
}

///|
priv struct ResidentSim {
  name : String
  venture : String
  need : String
  mood : String
  agent_goal : String
  memory : String
  reflection : String
  plan : String
  recent_action : String
  privacy_scope : String
  zone : String
}

///|
priv struct CivicQuestSim {
  title : String
  area : String
  stage : String
  reward : String
  status : String
  status_class : String
  detail : String
  next_action : String
}

///|
priv struct SocialMatchSim {
  left : String
  right : String
  reason : String
  next_step : String
  confidence : Int
}

///|
priv struct TalentSignalSim {
  name : String
  domain : String
  project : String
  skills : String
  recent_achievement : String
  evidence_status : String
  reception_note : String
  activity : Int
}

///|
priv struct TalentRouteStopSim {
  order : Int
  stop_title : String
  signal_name : String
  talking_point : String
  operator_note : String
  evidence_status : String
  readiness : Int
}

///|
priv struct ProjectionSnapshot {
  town : @core.TownState
  event_count : Int
} derive(FromJson)

///|
priv struct VisualAgentSnapshot {
  worker_id : String
  worker_name : String
  book_id : String
  book_title : String
  role : String
  status : String
  phase : String
  task_id : String?
  task_title : String?
  run_id : String?
  sprite_key : String
  zone_key : String
  location : String
  destination : String
  behavior : String
  effect : String
  visible_on_overworld : Bool
  message : String
  grid_x : Int
  grid_y : Int
  z : Int
} derive(FromJson)

///|
priv struct VisualBuildingSnapshot {
  book_id : String
  title : String
  zone_key : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  effect : String
  message : String
} derive(FromJson)

///|
priv struct VisualModuleSnapshot {
  module_id : String
  book_id : String
  status : String
  source : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  active_agent_count : Int
  message : String
} derive(FromJson)

///|
priv struct VisualProjectionSnapshot {
  tick : Int
  agents : Array[VisualAgentSnapshot]
  buildings : Array[VisualBuildingSnapshot]
  modules : Array[VisualModuleSnapshot]?
  messages : Array[String]
} derive(FromJson)

///|
priv struct DaemonJobSnapshot {
  id : String
  kind : String
  interval_seconds : Int
} derive(FromJson)

///|
priv struct DaemonSnapshot {
  daemon_id : String
  lease_owner : String
  tick_sequence : Int
  last_heartbeat_event_count : Int
  active_goal_ids : Array[String]
  jobs : Array[DaemonJobSnapshot]
} derive(FromJson)

///|
priv struct StandingGoalSnapshot {
  id : String
  title : String
  prompt : String
  target_book_id : String?
  cadence_ticks : Int
  next_due_tick : Int
  last_run_tick : Int?
  enabled : Bool
  source_policy : String
  quality_threshold : Int
} derive(FromJson)

///|
priv struct WatcherRunRecordSnapshot {
  goal_id : String
  tick : Int
  target_book_id : String
  decision : String
  delta_score : Int
  new_source_count : Int
  checked_sources_count : Int?
  new_sources_found : Int?
  accepted_facts_count : Int?
  rejected_facts_count : Int?
  wiki_pages_changed_count : Int?
  book_changed : String?
  detail : String
  task_id : String?
  run_id : String?
  next_due_tick : Int
} derive(FromJson)

///|
priv struct OperatorRequestSnapshot {
  id : String
  status : String
  created_at : String
  title : String
  prompt : String
  target_book_id : String
  cadence_ticks : Int
  source_policy : String
  quality_threshold : Int
  standing_goal_id : String
} derive(FromJson)

///|
priv struct OperatorRequestSubmitResult {
  ok : Bool
  request_id : String?
  standing_goal_id : String?
  status : String?
  error : String?
} derive(FromJson)

///|
priv struct ProjectionChipSnapshot {
  label : String
  tone : String
} derive(FromJson)

///|
priv struct ProjectionMetricSnapshot {
  label : String
  value : String
  note : String
  tone : String
} derive(FromJson)

///|
priv struct ProjectionItemSnapshot {
  title : String
  detail : String
  meta : String
} derive(FromJson)

///|
priv struct ProjectionJourneySnapshot {
  title : String
  stage : String
  status : String
  summary : String
  highlights : Array[String]
} derive(FromJson)

///|
priv struct ProjectionLinkSnapshot {
  label : String
  kind : String
  url : String
} derive(FromJson)

///|
priv struct BookProjectionFragment {
  book_id : String
  title : String
  summary : String
  status_chips : Array[ProjectionChipSnapshot]
  metrics : Array[ProjectionMetricSnapshot]
  readiness : Array[ProjectionItemSnapshot]
  review_queue : Array[ProjectionItemSnapshot]
  page_families : Array[ProjectionItemSnapshot]
  journey : Array[ProjectionJourneySnapshot]
  links : Array[ProjectionLinkSnapshot]
} derive(FromJson)

///|
priv struct ModuleProjectionIndex {
  generated_at : String
  projections : Array[BookProjectionFragment]
} derive(FromJson)

///|
priv struct CivicServiceHealthSnapshot {
  service_id : String
  title : String
  book_id : String
  service_kind : String
  module_mode : String
  book_role : String
  skill_mode : String
  protocol_status : String
  protocol_ready : Bool
  protocol_inbox_count : Int
  protocol_contribution_count : Int
  protocol_reduction_count : Int
  protocol_outbox_count : Int
  protocol_review_count : Int
  latest_protocol_summary : String
  status : String
  operable : Bool
  proven_by_result : Bool
  latest_decision : String
  latest_pages_changed : Int
  latest_accepted_facts : Int
  latest_review_items : Int
  missing_required_paths : Array[String]
  notes : Array[String]
} derive(FromJson)

///|
priv struct CivicServicePortfolioSnapshot {
  total : Int
  operable_count : Int
  proven_count : Int
  seeded_count : Int
  missing_count : Int
  review_count : Int
  blocked_count : Int
  changed_count : Int
  no_change_count : Int
  services : Array[CivicServiceHealthSnapshot]
} derive(FromJson)

///|
priv struct MoondeskHandoffArtifact {
  id : String
  title : String
  kind : String
  status : String
  scope : String
  source_path : String
  target_path : String
  summary : String
  import_contract : Array[String]
} derive(FromJson)

///|
priv struct MoondeskHandoffIndex {
  version : Int
  description : String
  artifacts : Array[MoondeskHandoffArtifact]
} derive(FromJson)

///|
priv struct MoondeskBridgeRecord {
  id : String
  kind : String
  status : String
  path : String
  title : String
  summary : String
  target : String
  created_at : String
} derive(FromJson)

///|
priv struct MoondeskBridgeIndex {
  generated_at : String
  moondesk_root_available : Bool
  records : Array[MoondeskBridgeRecord]
} derive(FromJson)

///|
priv struct WenyuTownModuleConfig {
  version : Int
  description : String
  modules : Array[WenyuTownModule]
} derive(FromJson)

///|
priv struct WenyuTownModule {
  id : String
  enabled : Bool
  title : String
  book_id : String
  district : String
  building_kind : String
  grid_x : Int
  grid_y : Int
  footprint_w : Int
  footprint_h : Int
  display_w : Int
  display_h : Int
  entrance_x : Int
  entrance_y : Int
  interior_kind : String
  style_family : String
  asset_base : String
  asset_roof : String
  protocol_pattern : String
  use_case : String
  agent_flow : String
  summary : String
} derive(FromJson)

///|
priv struct WenyuModuleRuntimeState {
  status_class : String
  status_label : String
  source_label : String
  detail : String
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
  visible_agent_count : Int
  issue_count : Int
}

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

///|
extern "js" fn submit_operator_request_json(
  title : String,
  prompt : String,
  target_book_id : String,
  cadence_ticks : String,
  quality_threshold : String,
) -> String =
  #| async (title, prompt, targetBookId, cadenceTicks, qualityThreshold) => {
  #|   try {
  #|     const response = await fetch("./api/operator-requests", {
  #|       method: "POST",
  #|       headers: { "Content-Type": "application/json" },
  #|       body: JSON.stringify({
  #|         title,
  #|         prompt,
  #|         target_book_id: targetBookId,
  #|         cadence_ticks: cadenceTicks,
  #|         quality_threshold: qualityThreshold,
  #|       }),
  #|     });
  #|     const text = await response.text();
  #|     if (globalThis.__moontownRefreshRuntimeSnapshots) {
  #|       await globalThis.__moontownRefreshRuntimeSnapshots();
  #|     }
  #|     if (!response.ok) {
  #|       try {
  #|         const parsed = JSON.parse(text);
  #|         return JSON.stringify({ ok: false, error: parsed.error || text });
  #|       } catch (_) {
  #|         return JSON.stringify({ ok: false, error: text || response.statusText });
  #|       }
  #|     }
  #|     return text;
  #|   } catch (error) {
  #|     return JSON.stringify({ ok: false, error: String(error) });
  #|   }
  #| }

///|
extern "js" fn real_time_label() -> String =
  #| () => new Date().toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit", second: "2-digit" })

///|
extern "js" fn real_calendar_label() -> String =
  #| () => new Date().toLocaleDateString(undefined, { weekday: "short", month: "short", day: "numeric", year: "numeric" })

///|
extern "js" fn real_local_hour() -> Int =
  #| () => new Date().getHours()

///|
extern "js" fn current_browser_path() -> String =
  #| () => `${globalThis.location?.pathname || ""}${globalThis.location?.hash || ""}`

///|
extern "js" fn current_viewport_mode_param() -> String =
  #| () => {
  #|   try {
  #|     return new URL(globalThis.location?.href || "http://local/").searchParams.get("mode") || "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn current_viewport_module_param() -> String =
  #| () => {
  #|   try {
  #|     return new URL(globalThis.location?.href || "http://local/").searchParams.get("module") || "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn reference_tile_code_at(grid_x : Int, grid_y : Int) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceLabels?.rows?.[gridY]?.[gridX] || ""

///|
fn standalone_viewport_requested() -> Bool {
  let path = current_browser_path()
  path.contains("viewport")
}

///|
fn initial_viewport_mode() -> ViewportMode {
  match current_viewport_mode_param() {
    "editor" => ViewportMode::EditorMode
    "edit" => ViewportMode::EditorMode
    "output" => ViewportMode::OutputMode
    "final" => ViewportMode::OutputMode
    _ => ViewportMode::ViewMode
  }
}

///|
fn initial_selection() -> Selection {
  let module_id = current_viewport_module_param()
  if module_id.is_empty() {
    Selection::Overview
  } else {
    Selection::Node(module_id)
  }
}

///|
fn init_model() -> Model {
  let projection_snapshot = parse_bootstrap_town_snapshot()
  let visual_projection = parse_bootstrap_visual_projection()
  let module_projections = parse_bootstrap_module_projections()
  let civic_status = parse_bootstrap_civic_status()
  let moondesk_handoff_artifacts = parse_bootstrap_moondesk_handoff_artifacts()
  let moondesk_bridge = parse_bootstrap_moondesk_bridge()
  let daemon_snapshot = parse_bootstrap_daemon_snapshot()
  let standing_goals = parse_bootstrap_standing_goals()
  let watcher_records = parse_bootstrap_watcher_records()
  let operator_requests = parse_bootstrap_operator_requests()
  {
    tick: 0,
    paused: false,
    strategy: Strategy::Balanced,
    selection: initial_selection(),
    state_source: initial_state_source(projection_snapshot),
    viewport_mode: initial_viewport_mode(),
    projection_snapshot,
    snapshot_version: town_snapshot_version(),
    visual_projection,
    visual_projection_version: visual_projection_version(),
    module_projections,
    module_projections_version: module_projections_version(),
    civic_status,
    civic_status_version: civic_status_version(),
    moondesk_handoff_artifacts,
    moondesk_handoff_version: moondesk_handoff_version(),
    moondesk_bridge,
    moondesk_bridge_version: moondesk_bridge_version(),
    daemon_snapshot,
    daemon_snapshot_version: daemon_snapshot_version(),
    standing_goals,
    standing_goals_version: standing_goals_version(),
    watcher_records,
    watcher_records_version: watcher_records_version(),
    operator_requests,
    operator_requests_version: operator_requests_version(),
    request_title: "Track a new research topic",
    request_prompt: "Research the latest useful updates, screen sources carefully, and update the target MoonBook only when the evidence changes the baseline.",
    request_book_id: "research-topic",
    request_cadence: "60",
    request_quality_threshold: "85",
    request_submitting: false,
    request_status: "Ready to submit a standing watch request.",
    budget: 76,
    energy: 68,
    pressure: 34,
    stability: 78,
  }
}

///|
fn parse_bootstrap_town_snapshot() -> ProjectionSnapshot? {
  let text = load_bootstrap_town_snapshot_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_visual_projection() -> VisualProjectionSnapshot? {
  let text = load_bootstrap_visual_projection_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_module_projections() -> Array[BookProjectionFragment] {
  let text = load_bootstrap_module_projections_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let index : ModuleProjectionIndex = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(index.generated_at)
  index.projections
}

///|
fn parse_bootstrap_civic_status() -> CivicServicePortfolioSnapshot? {
  let text = load_bootstrap_civic_status_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_moondesk_handoff_artifacts(
) -> Array[MoondeskHandoffArtifact] {
  let text = load_bootstrap_moondesk_handoff_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let index : MoondeskHandoffIndex = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(index.version)
  ignore(index.description)
  index.artifacts
}

///|
fn parse_bootstrap_moondesk_bridge() -> MoondeskBridgeIndex? {
  let text = load_bootstrap_moondesk_bridge_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_daemon_snapshot() -> DaemonSnapshot? {
  let text = load_bootstrap_daemon_snapshot_json()
  if text == "" {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn parse_bootstrap_standing_goals() -> Array[StandingGoalSnapshot] {
  parse_standing_goals_json(load_bootstrap_standing_goals_json())
}

///|
fn parse_bootstrap_watcher_records() -> Array[WatcherRunRecordSnapshot] {
  parse_watcher_records_json(load_bootstrap_watcher_records_json())
}

///|
fn parse_bootstrap_operator_requests() -> Array[OperatorRequestSnapshot] {
  parse_operator_requests_json(load_bootstrap_operator_requests_json())
}

///|
fn parse_standing_goals_json(text : String) -> Array[StandingGoalSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}

///|
fn parse_watcher_records_json(text : String) -> Array[WatcherRunRecordSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}

///|
fn parse_operator_requests_json(
  text : String,
) -> Array[OperatorRequestSnapshot] {
  let parsed = @json.parse(text) catch { _ => return [] }
  @json.from_json(parsed) catch {
    _ => []
  }
}

///|
fn parse_bootstrap_wenyu_modules() -> Array[WenyuTownModule] {
  let text = load_bootstrap_wenyu_modules_json()
  if text == "" {
    return []
  }
  let parsed = @json.parse(text) catch { _ => return [] }
  let config : WenyuTownModuleConfig = @json.from_json(parsed) catch {
    _ => return []
  }
  ignore(config.version)
  ignore(config.description)
  config.modules.filter(civic => civic.enabled)
}

///|
fn wenyu_modules() -> Array[WenyuTownModule] {
  parse_bootstrap_wenyu_modules()
}

///|
fn wenyu_module_count() -> Int {
  wenyu_modules().length()
}

///|
fn find_wenyu_module(module_id : String) -> WenyuTownModule? {
  for civic in wenyu_modules() {
    if civic.id == module_id {
      return Some(civic)
    }
  }
  None
}

///|
fn strip_prefix_once(text : String, prefix : String) -> String {
  if text.length() >= prefix.length() &&
    text[:prefix.length()].to_string() == prefix {
    text[prefix.length():].to_string()
  } else {
    text
  }
}

///|
fn normalize_module_binding_key(text : String) -> String {
  strip_prefix_once(strip_prefix_once(text, "book-"), "wenyu-")
}

///|
fn module_book_matches(civic : WenyuTownModule, book_id : String) -> Bool {
  book_id == civic.book_id ||
  book_id == civic.id ||
  normalize_module_binding_key(book_id) ==
  normalize_module_binding_key(civic.book_id) ||
  normalize_module_binding_key(book_id) ==
  normalize_module_binding_key(civic.id)
}

///|
fn find_module_for_book(book_id : String) -> WenyuTownModule? {
  for civic in wenyu_modules() {
    if module_book_matches(civic, book_id) {
      return Some(civic)
    }
  }
  None
}

///|
fn find_module_book_projection(
  model : Model,
  civic : WenyuTownModule,
) -> BookProjectionFragment? {
  for projection in model.module_projections {
    if module_book_matches(civic, projection.book_id) {
      return Some(projection)
    }
  }
  None
}

///|
fn find_module_civic_health(
  model : Model,
  civic : WenyuTownModule,
) -> CivicServiceHealthSnapshot? {
  match model.civic_status {
    Some(status) => {
      for health in status.services {
        if module_book_matches(civic, health.book_id) ||
          normalize_module_binding_key(health.service_id) ==
          normalize_module_binding_key(civic.id) {
          return Some(health)
        }
      }
      None
    }
    None => None
  }
}

///|
fn parse_operator_request_submit_result(
  text : String,
) -> OperatorRequestSubmitResult {
  let parsed = @json.parse(text) catch {
    _ =>
      return {
        ok: false,
        request_id: None,
        standing_goal_id: None,
        status: None,
        error: Some("Request endpoint returned invalid JSON."),
      }
  }
  @json.from_json(parsed) catch {
    _ =>
      {
        ok: false,
        request_id: None,
        standing_goal_id: None,
        status: None,
        error: Some(
          "Request endpoint response did not match the expected contract.",
        ),
      }
  }
}

///|
fn initial_state_source(snapshot : ProjectionSnapshot?) -> StateSourceKind {
  match snapshot {
    Some(snapshot) =>
      if projection_snapshot_ready(snapshot) {
        StateSourceKind::SnapshotFile
      } else {
        StateSourceKind::DemoSimulation
      }
    None => StateSourceKind::DemoSimulation
  }
}

///|
fn projection_snapshot_ready(snapshot : ProjectionSnapshot) -> Bool {
  !snapshot.town.books.is_empty() ||
  !snapshot.town.workers.is_empty() ||
  !snapshot.town.tasks.is_empty() ||
  !snapshot.town.executions.is_empty() ||
  !snapshot.town.events.is_empty()
}

///|
fn projection_snapshot_is_ready(snapshot : ProjectionSnapshot?) -> Bool {
  match snapshot {
    Some(snapshot) => projection_snapshot_ready(snapshot)
    None => false
  }
}

///|
fn schedule_tick(dispatch : Dispatch[Msg]) -> Cmd {
  @rabbita.delay(dispatch(Tick), 1200)
}

///|
fn update(dispatch : Dispatch[Msg], msg : Msg, model : Model) -> (Cmd, Model) {
  match msg {
    ViewportControlNoop => (@rabbita.none, model)
    Tick => {
      let next = advance_model(model)
      let cmd = if next.paused {
        @rabbita.none
      } else {
        schedule_tick(dispatch)
      }
      (cmd, next)
    }
    TogglePause => {
      let next = { ..model, paused: !model.paused }
      let cmd = if next.paused {
        @rabbita.none
      } else {
        schedule_tick(dispatch)
      }
      (cmd, next)
    }
    Step =>
      if model.paused {
        (@rabbita.none, advance_model(model))
      } else {
        (@rabbita.none, model)
      }
    SelectWorker(worker_id) =>
      (@rabbita.none, { ..model, selection: Worker(worker_id) })
    SelectNode(node_key) =>
      (@rabbita.none, { ..model, selection: Node(node_key) })
    SelectOverview => (@rabbita.none, { ..model, selection: Overview })
    SetStrategy(strategy) => (@rabbita.none, { ..model, strategy, })
    SetViewportMode(viewport_mode) =>
      (
        @rabbita.none,
        { ..model, viewport_mode, selection: Selection::Overview },
      )
    ToggleStateSource =>
      (
        @rabbita.none,
        { ..model, state_source: next_state_source(model.state_source) },
      )
    InjectBudget =>
      (
        @rabbita.none,
        {
          ..model,
          budget: clamp_metric(model.budget + 14),
          pressure: clamp_metric(model.pressure - 6),
          energy: clamp_metric(model.energy + 3),
        },
      )
    RelieveQueue =>
      (
        @rabbita.none,
        {
          ..model,
          pressure: clamp_metric(model.pressure - 16),
          energy: clamp_metric(model.energy - 2),
          stability: clamp_metric(model.stability + 4),
        },
      )
    StabilityDrill =>
      (
        @rabbita.none,
        {
          ..model,
          stability: clamp_metric(model.stability + 15),
          energy: clamp_metric(model.energy + 5),
          budget: clamp_metric(model.budget - 7),
        },
      )
    SetRequestTitle(value) => (@rabbita.none, { ..model, request_title: value })
    SetRequestPrompt(value) =>
      (@rabbita.none, { ..model, request_prompt: value })
    SetRequestBookId(value) =>
      (@rabbita.none, { ..model, request_book_id: value })
    SetRequestCadence(value) =>
      (@rabbita.none, { ..model, request_cadence: value })
    SetRequestQualityThreshold(value) =>
      (@rabbita.none, { ..model, request_quality_threshold: value })
    SubmitOperatorRequest =>
      if model.request_title.trim().to_string().is_empty() ||
        model.request_prompt.trim().to_string().is_empty() {
        (
          @rabbita.none,
          {
            ..model,
            request_status: "Add both a title and a request before submitting.",
          },
        )
      } else {
        (
          submit_operator_request_cmd(dispatch, model),
          {
            ..model,
            request_submitting: true,
            request_status: "Submitting request to the local Moontown standing-goal inbox...",
          },
        )
      }
    OperatorRequestSubmitted(raw) => {
      let result = parse_operator_request_submit_result(raw)
      if result.ok {
        let goal_id = result.standing_goal_id.unwrap_or("standing-goal")
        let request_id = result.request_id.unwrap_or("operator-request")
        let status = result.status.unwrap_or("accepted")
        (
          @rabbita.none,
          {
            ..model,
            request_submitting: false,
            request_status: "Accepted as `\{goal_id}` via `\{request_id}` (`\{status}`). The daemon will pick it up on the next standing-goal dispatch tick.",
            standing_goals: parse_bootstrap_standing_goals(),
            standing_goals_version: standing_goals_version(),
            operator_requests: parse_bootstrap_operator_requests(),
            operator_requests_version: operator_requests_version(),
          },
        )
      } else {
        let error = result.error.unwrap_or("unknown error")
        (
          @rabbita.none,
          {
            ..model,
            request_submitting: false,
            request_status: "Request failed: \{error}",
          },
        )
      }
    }
  }
}

///|
fn submit_operator_request_cmd(dispatch : Dispatch[Msg], model : Model) -> Cmd {
  @rabbita.perform(fn(raw) { dispatch(OperatorRequestSubmitted(raw)) }, fn() noraise {
    submit_operator_request_json(
      model.request_title,
      model.request_prompt,
      model.request_book_id,
      model.request_cadence,
      model.request_quality_threshold,
    )
  })
}

///|
fn advance_model(model : Model) -> Model {
  let refreshed_version = town_snapshot_version()
  let refreshed_snapshot = if refreshed_version != model.snapshot_version {
    match parse_bootstrap_town_snapshot() {
      Some(snapshot) => Some(snapshot)
      None => model.projection_snapshot
    }
  } else {
    model.projection_snapshot
  }
  let refreshed_visual_projection_version = visual_projection_version()
  let refreshed_visual_projection = if refreshed_visual_projection_version !=
    model.visual_projection_version {
    match parse_bootstrap_visual_projection() {
      Some(snapshot) => Some(snapshot)
      None => model.visual_projection
    }
  } else {
    model.visual_projection
  }
  let refreshed_module_projections_version = module_projections_version()
  let refreshed_module_projections = if refreshed_module_projections_version !=
    model.module_projections_version {
    parse_bootstrap_module_projections()
  } else {
    model.module_projections
  }
  let refreshed_moondesk_handoff_version = moondesk_handoff_version()
  let refreshed_moondesk_handoff_artifacts = if
    refreshed_moondesk_handoff_version != model.moondesk_handoff_version {
    parse_bootstrap_moondesk_handoff_artifacts()
  } else {
    model.moondesk_handoff_artifacts
  }
  let refreshed_moondesk_bridge_version = moondesk_bridge_version()
  let refreshed_moondesk_bridge = if refreshed_moondesk_bridge_version !=
    model.moondesk_bridge_version {
    match parse_bootstrap_moondesk_bridge() {
      Some(snapshot) => Some(snapshot)
      None => model.moondesk_bridge
    }
  } else {
    model.moondesk_bridge
  }
  let refreshed_daemon_version = daemon_snapshot_version()
  let refreshed_daemon_snapshot = if refreshed_daemon_version !=
    model.daemon_snapshot_version {
    match parse_bootstrap_daemon_snapshot() {
      Some(snapshot) => Some(snapshot)
      None => model.daemon_snapshot
    }
  } else {
    model.daemon_snapshot
  }
  let refreshed_standing_goals_version = standing_goals_version()
  let refreshed_standing_goals = if refreshed_standing_goals_version !=
    model.standing_goals_version {
    parse_bootstrap_standing_goals()
  } else {
    model.standing_goals
  }
  let refreshed_watcher_records_version = watcher_records_version()
  let refreshed_watcher_records = if refreshed_watcher_records_version !=
    model.watcher_records_version {
    parse_bootstrap_watcher_records()
  } else {
    model.watcher_records
  }
  let refreshed_operator_requests_version = operator_requests_version()
  let refreshed_operator_requests = if refreshed_operator_requests_version !=
    model.operator_requests_version {
    parse_bootstrap_operator_requests()
  } else {
    model.operator_requests
  }
  let refreshed_source = if model.state_source == StateSourceKind::SnapshotFile {
    if projection_snapshot_is_ready(refreshed_snapshot) {
      StateSourceKind::SnapshotFile
    } else {
      model.state_source
    }
  } else if !projection_snapshot_is_ready(model.projection_snapshot) &&
    projection_snapshot_is_ready(refreshed_snapshot) {
    StateSourceKind::SnapshotFile
  } else {
    model.state_source
  }
  let recovery_active = mayor_recovery_active(model)
  let budget_delta = match model.strategy {
    Balanced => -2
    Throughput => -4
    Recovery => -1
  }
  let energy_delta = match model.strategy {
    Balanced => -1
    Throughput => -4
    Recovery => 2
  }
  let pressure_delta = match model.strategy {
    Balanced => 1
    Throughput => 5
    Recovery => -3
  }
  let stability_delta = match model.strategy {
    Balanced => 0
    Throughput => -3
    Recovery => 3
  }
  let overload_penalty = if model.pressure > 70 { 4 } else { 0 }
  let brittle_penalty = if model.stability < 35 { 3 } else { 0 }
  let budget_penalty = if model.budget < 24 { 2 } else { 0 }
  let energy_penalty = if model.energy < 28 { 3 } else { 0 }
  let budget_bonus = if model.tick % 6 == 0 { 2 } else { 0 }
  let energy_bonus = if model.tick % 5 == 0 { 1 } else { 0 }
  let pressure_relief = if model.tick % 4 == 0 { 1 } else { 0 }
  let stability_bonus = if model.tick % 5 == 0 { 1 } else { 0 }
  let supervision_budget = if recovery_active { 8 } else { 0 }
  let supervision_energy = if recovery_active { 10 } else { 0 }
  let supervision_pressure = if recovery_active { 14 } else { 0 }
  let supervision_stability = if recovery_active { 12 } else { 0 }
  let next_budget = clamp_metric(
    model.budget + budget_delta + budget_bonus + supervision_budget,
  )
  let next_energy = clamp_metric(
    model.energy +
    energy_delta -
    overload_penalty +
    energy_bonus +
    supervision_energy,
  )
  let next_pressure = clamp_metric(
    model.pressure +
    pressure_delta +
    brittle_penalty +
    energy_penalty -
    pressure_relief -
    supervision_pressure,
  )
  let next_stability = clamp_metric(
    model.stability +
    stability_delta -
    overload_penalty -
    budget_penalty +
    stability_bonus +
    supervision_stability,
  )
  {
    ..model,
    tick: model.tick + 1,
    state_source: refreshed_source,
    projection_snapshot: refreshed_snapshot,
    snapshot_version: refreshed_version,
    visual_projection: refreshed_visual_projection,
    visual_projection_version: refreshed_visual_projection_version,
    module_projections: refreshed_module_projections,
    module_projections_version: refreshed_module_projections_version,
    moondesk_handoff_artifacts: refreshed_moondesk_handoff_artifacts,
    moondesk_handoff_version: refreshed_moondesk_handoff_version,
    moondesk_bridge: refreshed_moondesk_bridge,
    moondesk_bridge_version: refreshed_moondesk_bridge_version,
    daemon_snapshot: refreshed_daemon_snapshot,
    daemon_snapshot_version: refreshed_daemon_version,
    standing_goals: refreshed_standing_goals,
    standing_goals_version: refreshed_standing_goals_version,
    watcher_records: refreshed_watcher_records,
    watcher_records_version: refreshed_watcher_records_version,
    operator_requests: refreshed_operator_requests,
    operator_requests_version: refreshed_operator_requests_version,
    budget: next_budget,
    energy: next_energy,
    pressure: next_pressure,
    stability: next_stability,
  }
}

///|
fn mayor_recovery_active(model : Model) -> Bool {
  model.pressure > 76 ||
  model.stability < 36 ||
  model.energy < 28 ||
  model.budget < 24
}

///|
fn clamp_metric(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 100 {
    100
  } else {
    value
  }
}

///|
fn town_scene(model : Model) -> @ui.SceneRenderModel {
  let state = state_for_model(model)
  let report = @health.inspect_town(state)
  @ui.build_scene_render(@ui.build_dashboard(state, report))
}

///|
fn state_for_model(model : Model) -> @core.TownState {
  match model.state_source {
    StateSourceKind::DemoSimulation => demo_state(model)
    StateSourceKind::SnapshotFile => projection_state(model)
  }
}

///|
fn projection_state(model : Model) -> @core.TownState {
  match model.projection_snapshot {
    Some(snapshot) =>
      if projection_snapshot_ready(snapshot) {
        snapshot.town
      } else {
        snapshot_placeholder_state(model)
      }
    None => snapshot_placeholder_state(model)
  }
}

///|
fn next_state_source(source : StateSourceKind) -> StateSourceKind {
  match source {
    StateSourceKind::DemoSimulation => StateSourceKind::SnapshotFile
    StateSourceKind::SnapshotFile => StateSourceKind::DemoSimulation
  }
}

///|
fn state_source_label(source : StateSourceKind) -> String {
  match source {
    StateSourceKind::DemoSimulation => "Demo Simulation"
    StateSourceKind::SnapshotFile => "Projection Snapshot"
  }
}

///|
fn state_source_detail(model : Model) -> String {
  match model.state_source {
    StateSourceKind::DemoSimulation =>
      "Live civic simulation: mayor supervision keeps services, agents, quests, and town health cycling 24/7 while Resident Twins stay limited to projection-safe summaries."
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) if projection_snapshot_ready(snapshot) =>
          "Projection snapshot mode is loaded from `.moontown/town.json` with \{snapshot.town.books.length()} books, \{snapshot.town.workers.length()} workers, \{snapshot.town.tasks.length()} queued tasks, and \{snapshot.event_count} events."
        Some(_) =>
          "Projection snapshot file was found but does not yet contain a usable town runtime projection, so the shell stays on demo supervision until the bridge publishes real books, workers, or tasks."
        None =>
          "Projection snapshot mode shows the MoonBook-to-browser bridge placeholder until the bundle can load `.moontown/town.json` or a generated runtime projection."
      }
  }
}

///|
fn state_source_options() -> Array[StateSourceKind] {
  [DemoSimulation, SnapshotFile]
}

///|
fn tasks_for_model(model : Model) -> Array[@core.TownTask] {
  match model.state_source {
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) =>
          if projection_snapshot_ready(snapshot) &&
            !snapshot.town.tasks.is_empty() {
            snapshot.town.tasks
          } else {
            task_specs(model)
          }
        _ => task_specs(model)
      }
    StateSourceKind::DemoSimulation => task_specs(model)
  }
}

///|
fn executions_for_model(model : Model) -> Array[@core.TaskExecutionRecord] {
  match model.state_source {
    StateSourceKind::SnapshotFile =>
      match model.projection_snapshot {
        Some(snapshot) =>
          if projection_snapshot_ready(snapshot) &&
            !snapshot.town.executions.is_empty() {
            snapshot.town.executions
          } else {
            execution_specs(model)
          }
        _ => execution_specs(model)
      }
    StateSourceKind::DemoSimulation => execution_specs(model)
  }
}

///|
fn demo_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(
      id="wenyu-valley",
      name="Wenyu Valley / AI Innovation Town",
      heartbeat_seconds=30,
      max_concurrent_tasks=24,
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-town-shell",
      name="Town Shell",
      purpose="Owns the live district shell, runtime projection contract, and operator-facing Wenyu map.",
      workspace_root="/town/wenyu-town-shell",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["projection", "ui", "shell"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-resident-twins",
      name="Resident Twins",
      purpose="Projects resident identity, memory summaries, reflection loops, privacy scope, and next actions into the town view.",
      workspace_root="/town/wenyu-resident-twins",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["resident-twins", "memory", "projection"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="policy-hall",
      name="Policy Release Hall",
      purpose="Turns policy documents into quest lines, advisor answers, and application checklists.",
      workspace_root="/town/policy-hall",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["policy", "quest", "advisor"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-contest-express",
      name="Contest Express",
      purpose="Turns contest participation into a nurturing lane with countdowns, readiness reviews, mock judging, and champion replay hooks.",
      workspace_root="/town/wenyu-contest-express",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["contest", "roadshow", "readiness"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="social-square",
      name="Social Square",
      purpose="Maintains weak-tie matching, activity initiation, and collaboration loops.",
      workspace_root="/town/social-square",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["matching", "events", "community"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="talent-avenue",
      name="Talent Star Avenue",
      purpose="Projects resident talent cards, skills heatmaps, and reception tours.",
      workspace_root="/town/talent-avenue",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["talent", "graph", "showcase"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="ai-garden",
      name="AI Science Garden",
      purpose="Runs AI learning tips, tool trials, creator workshops, and tutorial quests.",
      workspace_root="/town/ai-garden",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["learning", "tools", "workshop"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-physical-bridge",
      name="Physical Bridge",
      purpose="Bridges virtual requests into venue booking, proxy attendance, robot dispatch, and live district telemetry.",
      workspace_root="/town/wenyu-physical-bridge",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["physical-bridge", "robot", "telemetry"],
    ),
  )
  for worker in worker_sims(model) {
    state.register_worker(
      @core.WorkerRef::new(
        id=worker.id,
        name=worker.title,
        book_id=worker.book_id,
        role=worker_role_from_id(worker.id),
        capabilities=worker_capabilities(worker.id),
        status=worker.status,
      ),
    )
  }
  for task in task_specs(model) {
    state.enqueue_task(task)
  }
  for execution in execution_specs(model) {
    state.register_execution(execution)
  }
  state
}

///|
fn snapshot_placeholder_state(model : Model) -> @core.TownState {
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  state.register_book(
    @core.BookRef::new(
      id="wenyu-town-shell",
      name="Town Shell",
      purpose="Town Shell stays visible here while the browser bridge waits for a persisted projection feed.",
      workspace_root="/town/wenyu-town-shell",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["projection", "ui", "shell"],
    ),
  )
  state.register_book(
    @core.BookRef::new(
      id="snapshot",
      name="Persisted Town Snapshot",
      purpose="Browser snapshot bridge placeholder for `.moontown/town.json`.",
      workspace_root=".moontown",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["snapshot", "pending-bridge"],
    ),
  )
  state.register_worker(
    @core.WorkerRef::new(
      id="snapshot-bridge",
      name="Snapshot Bridge",
      book_id="snapshot",
      role=@core.WorkerRole::Watcher,
      capabilities=["state-source", "projection"],
      status=@core.WorkerStatus::Waiting,
    ),
  )
  state.enqueue_task(
    @core.TownTask::new(
      id="connect-snapshot-source",
      book_id="snapshot",
      title="Connect persisted town state",
      prompt="Load `.moontown/town.json` through a local endpoint or generated static JSON artifact.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["state-source"],
      status=@core.TownTaskStatus::Planned,
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="snapshot-source-\{model.tick}",
      kind="state-source",
      detail="Snapshot source selected; Rabbita browser bundle needs a state bridge before this reflects live town data.",
    ),
  )
  state
}

///|
fn worker_role_from_id(worker_id : String) -> @core.WorkerRole {
  match worker_id {
    "agent-town-shell" => @core.WorkerRole::Harness
    "agent-resident" => @core.WorkerRole::MemoryKeeper
    "agent-policy" => @core.WorkerRole::Specialist
    "agent-contest" => @core.WorkerRole::Planner
    "agent-social" => @core.WorkerRole::Operator
    "agent-talent" => @core.WorkerRole::MemoryKeeper
    "agent-garden" => @core.WorkerRole::Planner
    "agent-robot" => @core.WorkerRole::Watcher
    _ => @core.WorkerRole::MemoryKeeper
  }
}

///|
fn worker_capabilities(worker_id : String) -> Array[String] {
  match worker_id {
    "agent-town-shell" => ["projection", "ui-state", "build-records"]
    "agent-resident" => ["resident-memory", "reflection", "projection"]
    "agent-policy" => ["policy", "rag", "checklist"]
    "agent-contest" => ["contest", "mock-judge", "readiness"]
    "agent-social" => ["matching", "event-planning", "community"]
    "agent-talent" => ["talent-graph", "projection", "reception"]
    "agent-garden" => ["tutorial", "tool-trial", "workshop"]
    "agent-robot" => ["robot", "venue", "digital-twin"]
    _ => ["reporting", "planning"]
  }
}

///|
fn worker_sims(model : Model) -> Array[WorkerSim] {
  [
    build_worker_sim(
      model,
      id="agent-town-shell",
      title="Town Shell Foreman",
      role="Projection Harness",
      book_id="wenyu-town-shell",
      offset=0,
    ),
    build_worker_sim(
      model,
      id="agent-resident",
      title="Twin Keeper",
      role="Resident Memory Keeper",
      book_id="wenyu-resident-twins",
      offset=1,
    ),
    build_worker_sim(
      model,
      id="agent-policy",
      title="Policy Sprite",
      role="Policy Advisor",
      book_id="policy-hall",
      offset=2,
    ),
    build_worker_sim(
      model,
      id="agent-contest",
      title="Contest Conductor",
      role="Roadshow Planner",
      book_id="wenyu-contest-express",
      offset=3,
    ),
    build_worker_sim(
      model,
      id="agent-social",
      title="Cafe Matchmaker",
      role="Social Operator",
      book_id="social-square",
      offset=4,
    ),
    build_worker_sim(
      model,
      id="agent-talent",
      title="Talent Cartographer",
      role="Memory Keeper",
      book_id="talent-avenue",
      offset=5,
    ),
    build_worker_sim(
      model,
      id="agent-garden",
      title="AI Garden Tutor",
      role="Planner",
      book_id="ai-garden",
      offset=6,
    ),
    build_worker_sim(
      model,
      id="agent-robot",
      title="Physical Bridge Link",
      role="Watcher",
      book_id="wenyu-physical-bridge",
      offset=7,
    ),
  ]
}

///|
fn workers_for_model(model : Model) -> Array[WorkerSim] {
  match model.state_source {
    StateSourceKind::DemoSimulation => worker_sims(model)
    StateSourceKind::SnapshotFile => snapshot_worker_sims(model)
  }
}

///|
fn snapshot_worker_sims(model : Model) -> Array[WorkerSim] {
  match model.projection_snapshot {
    Some(snapshot) =>
      if snapshot.town.workers.is_empty() {
        fallback_snapshot_worker_sims()
      } else {
        snapshot.town.workers.map(worker => {
          let load = snapshot_worker_load(worker.status)
          {
            id: worker.id,
            title: worker.name,
            role: "\{worker.role}",
            book_id: worker.book_id,
            status: worker.status,
            zone_key: worker_zone_key(worker.book_id, worker.status),
            energy: snapshot_worker_energy(worker.status),
            load,
            summary: snapshot_worker_summary(worker),
          }
        })
      }
    None => fallback_snapshot_worker_sims()
  }
}

///|
fn fallback_snapshot_worker_sims() -> Array[WorkerSim] {
  [
    {
      id: "snapshot-bridge",
      title: "Snapshot Bridge",
      role: "Watcher",
      book_id: "snapshot",
      status: @core.WorkerStatus::Waiting,
      zone_key: "worker-yard",
      energy: 100,
      load: 12,
      summary: "Waiting for a static or local endpoint bridge into `.moontown/town.json`.",
    },
  ]
}

///|
fn snapshot_worker_load(status : @core.WorkerStatus) -> Int {
  match status {
    @core.WorkerStatus::Running => 74
    @core.WorkerStatus::Waiting => 28
    @core.WorkerStatus::Idle => 16
    @core.WorkerStatus::Blocked => 91
    @core.WorkerStatus::Offline => 0
  }
}

///|
fn snapshot_worker_energy(status : @core.WorkerStatus) -> Int {
  match status {
    @core.WorkerStatus::Running => 64
    @core.WorkerStatus::Waiting => 79
    @core.WorkerStatus::Idle => 88
    @core.WorkerStatus::Blocked => 38
    @core.WorkerStatus::Offline => 0
  }
}

///|
fn snapshot_worker_summary(worker : @core.WorkerRef) -> String {
  let capability_count = worker.capabilities.length()
  let capability_text = if capability_count == 0 {
    "no declared capabilities yet"
  } else if capability_count == 1 {
    "1 declared capability"
  } else {
    "\{capability_count} declared capabilities"
  }
  if worker.role.to_string() == "Watcher" &&
    worker.status == @core.WorkerStatus::Idle {
    return "\{worker.name} is on duty for the 30-minute standing-watch loop. Idle means waiting between checks, not offline; the mayor message feed shows the latest check result."
  }
  "\{worker.name} is projected from persisted town state with status \{worker.status}, role \{worker.role}, and \{capability_text}."
}

///|
fn build_worker_sim(
  model : Model,
  id~ : String,
  title~ : String,
  role~ : String,
  book_id~ : String,
  offset~ : Int,
) -> WorkerSim {
  let status = worker_status_for(model, offset)
  let zone_key = worker_zone_key(book_id, status)
  let load = worker_load(model, offset, status)
  let idle_bonus = if status == @core.WorkerStatus::Idle { 8 } else { 0 }
  let energy = clamp_metric(model.energy - offset * 5 + idle_bonus)
  {
    id,
    title,
    role,
    book_id,
    status,
    zone_key,
    energy,
    load,
    summary: worker_summary(status, load),
  }
}

///|
fn worker_status_for(model : Model, offset : Int) -> @core.WorkerStatus {
  let cycle = (model.tick + offset) % 9
  if mayor_recovery_active(model) {
    match cycle {
      0 => @core.WorkerStatus::Running
      1 => @core.WorkerStatus::Waiting
      2 => @core.WorkerStatus::Idle
      3 => @core.WorkerStatus::Running
      4 => @core.WorkerStatus::Waiting
      5 => @core.WorkerStatus::Idle
      6 => @core.WorkerStatus::Running
      7 => @core.WorkerStatus::Waiting
      _ => @core.WorkerStatus::Idle
    }
  } else if model.stability < 30 && (cycle == 2 || cycle == 6) {
    @core.WorkerStatus::Waiting
  } else if model.pressure > 76 && (cycle == 1 || cycle == 4 || cycle == 7) {
    @core.WorkerStatus::Waiting
  } else {
    match model.strategy {
      Strategy::Balanced =>
        match cycle {
          0 => @core.WorkerStatus::Running
          1 => @core.WorkerStatus::Waiting
          2 => @core.WorkerStatus::Idle
          3 => @core.WorkerStatus::Running
          4 => @core.WorkerStatus::Waiting
          5 => @core.WorkerStatus::Idle
          6 => @core.WorkerStatus::Running
          7 => @core.WorkerStatus::Waiting
          _ => @core.WorkerStatus::Idle
        }
      Strategy::Throughput =>
        match cycle {
          0 => @core.WorkerStatus::Running
          1 => @core.WorkerStatus::Running
          2 => @core.WorkerStatus::Waiting
          3 => @core.WorkerStatus::Running
          4 => @core.WorkerStatus::Running
          5 => @core.WorkerStatus::Waiting
          6 => @core.WorkerStatus::Running
          7 => @core.WorkerStatus::Idle
          _ => @core.WorkerStatus::Running
        }
      Strategy::Recovery =>
        match cycle {
          0 => @core.WorkerStatus::Idle
          1 => @core.WorkerStatus::Waiting
          2 => @core.WorkerStatus::Running
          3 => @core.WorkerStatus::Idle
          4 => @core.WorkerStatus::Waiting
          5 => @core.WorkerStatus::Running
          6 => @core.WorkerStatus::Idle
          7 => @core.WorkerStatus::Waiting
          _ => @core.WorkerStatus::Idle
        }
    }
  }
}

///|
fn worker_zone_key(book_id : String, status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Blocked => "anomaly-corner"
    @core.WorkerStatus::Idle => "book-\{book_id}"
    @core.WorkerStatus::Waiting => "book-\{book_id}"
    @core.WorkerStatus::Offline => "gate"
    @core.WorkerStatus::Running => "book-\{book_id}"
  }
}

///|
fn worker_load(model : Model, offset : Int, status : @core.WorkerStatus) -> Int {
  let baseline = model.pressure + offset * 6
  match status {
    @core.WorkerStatus::Running => clamp_metric(baseline + 16)
    @core.WorkerStatus::Waiting => clamp_metric(baseline - 8)
    @core.WorkerStatus::Idle => clamp_metric(baseline - 18)
    @core.WorkerStatus::Blocked => clamp_metric(baseline + 26)
    @core.WorkerStatus::Offline => 0
  }
}

///|
fn worker_summary(status : @core.WorkerStatus, load : Int) -> String {
  match status {
    @core.WorkerStatus::Running =>
      "Serving residents and town quests at load \{load}%."
    @core.WorkerStatus::Waiting =>
      "Waiting in the plaza for the mayor's next supervised handoff."
    @core.WorkerStatus::Idle =>
      "Resting in the yard while memory and social signals settle."
    @core.WorkerStatus::Blocked =>
      "Blocked by civic queue pressure or failed offline linkage."
    @core.WorkerStatus::Offline => "Offline and unavailable."
  }
}

///|
fn task_specs(model : Model) -> Array[@core.TownTask] {
  [
    @core.TownTask::new(
      id="task-town-shell-implementation-backlog",
      book_id="wenyu-town-shell",
      title="Materialize Town Shell implementation backlog",
      prompt="Turn the Wenyu Valley PRD and evidence lane into codex-ready files, acceptance checks, and projection tasks.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["planning", "projection"],
      status=task_status_for(model, 0),
    ),
    @core.TownTask::new(
      id="task-town-shell-code-patch",
      book_id="wenyu-town-shell",
      title="Patch Town Shell live district slice",
      prompt="Replace hardcoded module framing with live Town Shell projection signals and reviewable district status.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Harness),
      required_capabilities=["projection", "ui-state", "testing"],
      status=task_status_for(model, 1),
    ),
    @core.TownTask::new(
      id="task-town-shell-image-asset-pack",
      book_id="wenyu-town-shell",
      title="Generate Town Shell asset pack",
      prompt="Produce tile, icon, worker sprite, and vignette prompts that fit the warm civic Wenyu district style.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::Reviewer),
      required_capabilities=["asset-generation", "design", "projection"],
      status=task_status_for(model, 2),
    ),
    @core.TownTask::new(
      id="task-resident-twins-code-patch",
      book_id="wenyu-resident-twins",
      title="Project Resident Twins live district state",
      prompt="Replace generic Resident Twins framing with live worker, queue, health, and next-action status while keeping memory projection-safe.",
      domain=@core.WorkDomain::Coding,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["resident-memory", "reflection", "projection"],
      status=task_status_for(model, 3),
    ),
    @core.TownTask::new(
      id="task-policy-quest",
      book_id="policy-hall",
      title="Explain rental subsidy quest",
      prompt="Convert a policy into a scenario quest, checklist, and resident-facing reward path.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Specialist),
      required_capabilities=["policy", "checklist"],
      status=task_status_for(model, 4),
    ),
    @core.TownTask::new(
      id="task-contest-readiness",
      book_id="wenyu-contest-express",
      title="Coach resident contest readiness",
      prompt="Analyze contest rules, review the deck intro, score readiness gaps, and stage the next mock roadshow action.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["contest", "mock-judge", "readiness"],
      status=task_status_for(model, 5),
    ),
    @core.TownTask::new(
      id="task-cafe-match",
      book_id="social-square",
      title="Match two complementary OPCs",
      prompt="Detect business complementarity and stage a low-pressure cafe introduction.",
      domain=@core.WorkDomain::SocialExperiment,
      required_role=Some(@core.WorkerRole::Operator),
      required_capabilities=["matching", "community"],
      status=task_status_for(model, 6),
    ),
    @core.TownTask::new(
      id="task-talent-graph",
      book_id="talent-avenue",
      title="Refresh talent heatmap",
      prompt="Update resident skills, achievements, and tour-ready showcase cards.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::MemoryKeeper),
      required_capabilities=["talent-graph", "projection"],
      status=task_status_for(model, 7),
    ),
    @core.TownTask::new(
      id="task-ai-tip",
      book_id="ai-garden",
      title="Publish daily AI tool trial",
      prompt="Turn one practical AI workflow into a five-minute resident tutorial.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["tutorial", "tool-trial"],
      status=task_status_for(model, 8),
    ),
    @core.TownTask::new(
      id="task-physical-bridge-sync",
      book_id="wenyu-physical-bridge",
      title="Project Physical Bridge live district state",
      prompt="Bridge virtual requests into room availability, robot confirmation, proxy attendance, and live district telemetry.",
      domain=@core.WorkDomain::Operations,
      required_role=Some(@core.WorkerRole::Watcher),
      required_capabilities=["robot", "venue", "digital-twin"],
      status=task_status_for(model, 9),
    ),
  ]
}

///|
fn task_status_for(model : Model, offset : Int) -> @core.TownTaskStatus {
  let cycle = (model.tick + offset) % 8
  if mayor_recovery_active(model) {
    match cycle {
      0 => @core.TownTaskStatus::Assigned
      1 => @core.TownTaskStatus::Running
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Planned
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Running
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  } else if model.pressure > 80 && (cycle == 3 || cycle == 6) {
    @core.TownTaskStatus::Assigned
  } else {
    match cycle {
      0 => @core.TownTaskStatus::Pending
      1 => @core.TownTaskStatus::Assigned
      2 => @core.TownTaskStatus::Running
      3 => @core.TownTaskStatus::Running
      4 => @core.TownTaskStatus::Assigned
      5 => @core.TownTaskStatus::Planned
      6 => @core.TownTaskStatus::Pending
      _ => @core.TownTaskStatus::Running
    }
  }
}

///|
fn execution_status_for(
  model : Model,
  offset : Int,
) -> @core.TaskExecutionStatus {
  if mayor_recovery_active(model) && offset == 4 {
    @core.TaskExecutionStatus::RunConfirmed
  } else if model.stability < 26 && offset == 3 {
    @core.TaskExecutionStatus::ReviewQueued
  } else {
    match (model.tick + offset) % 7 {
      0 => @core.TaskExecutionStatus::PacketReady
      1 => @core.TaskExecutionStatus::ProposalImported
      2 => @core.TaskExecutionStatus::RunConfirmed
      3 => @core.TaskExecutionStatus::Running
      4 => @core.TaskExecutionStatus::AwaitingPersistence
      5 => @core.TaskExecutionStatus::ReviewQueued
      _ => @core.TaskExecutionStatus::Completed
    }
  }
}

///|
fn execution_specs(model : Model) -> Array[@core.TaskExecutionRecord] {
  [
    execution_spec(
      model, "task-town-shell-implementation-backlog", "wenyu-town-shell", 0,
    ),
    execution_spec(model, "task-town-shell-code-patch", "wenyu-town-shell", 1),
    execution_spec(
      model, "task-town-shell-image-asset-pack", "wenyu-town-shell", 2,
    ),
    execution_spec(
      model, "task-resident-twins-code-patch", "wenyu-resident-twins", 3,
    ),
    execution_spec(model, "task-policy-quest", "policy-hall", 4),
    execution_spec(model, "task-contest-readiness", "wenyu-contest-express", 5),
    execution_spec(model, "task-cafe-match", "social-square", 6),
    execution_spec(model, "task-talent-graph", "talent-avenue", 7),
    execution_spec(model, "task-ai-tip", "ai-garden", 8),
    execution_spec(
      model, "task-physical-bridge-sync", "wenyu-physical-bridge", 9,
    ),
  ]
}

///|
fn execution_spec(
  model : Model,
  task_id : String,
  book_id : String,
  offset : Int,
) -> @core.TaskExecutionRecord {
  let status = execution_status_for(model, offset)
  @core.TaskExecutionRecord::new(
    task_id~,
    book_id~,
    packet_id="packet-\{task_id}",
    packet_path=".moontown/packets/packet-\{task_id}.json",
    proposal_id=Some("proposal-packet-\{task_id}"),
    run_id=if status == @core.TaskExecutionStatus::PacketReady ||
      status == @core.TaskExecutionStatus::ProposalImported {
      None
    } else {
      Some("run-packet-\{task_id}")
    },
    status~,
    summary=execution_summary(status, task_id),
    output_contract="keeper.plan.packet.v1",
    context_pages=["wiki/index.md", "wiki/log.md"],
    skill_paths=["skills/wiki-maintainer/SKILL.md"],
    requires_review=status == @core.TaskExecutionStatus::AwaitingPersistence ||
      status == @core.TaskExecutionStatus::ReviewQueued,
    notify_town=true,
  )
}

///|
fn execution_summary(
  status : @core.TaskExecutionStatus,
  task_id : String,
) -> String {
  match status {
    @core.TaskExecutionStatus::PacketReady =>
      "Keeper packet prepared for \{task_id}."
    @core.TaskExecutionStatus::ProposalImported =>
      "Proposal imported and waiting for mayor confirmation."
    @core.TaskExecutionStatus::RunConfirmed =>
      "Mayor confirmed a live MoonClaw run."
    @core.TaskExecutionStatus::Running =>
      "MoonClaw run is executing book-local work."
    @core.TaskExecutionStatus::AwaitingPersistence =>
      "MoonBook persistence is waiting to absorb the result."
    @core.TaskExecutionStatus::ReviewQueued =>
      "Keeper review queued after persistence."
    @core.TaskExecutionStatus::Completed =>
      "Packet, run, and review loop completed."
    @core.TaskExecutionStatus::Stale =>
      "Mayor marked the execution stale and queued a recovery decision."
    @core.TaskExecutionStatus::Failed =>
      "Execution failed and the town should recover or retry."
  }
}

///|
fn status_chip(text : String, class_name : String) -> @rabbita.Html {
  span(class="chip \{class_name}", text)
}

///|
fn no_children() -> Array[@rabbita.Html] {
  []
}

///|
fn real_phase_label() -> String {
  let hour = real_local_hour()
  if hour < 6 {
    "Night patrol"
  } else if hour < 11 {
    "Morning onboarding"
  } else if hour < 15 {
    "Midday service"
  } else if hour < 19 {
    "Cafe matching"
  } else {
    "Evening reflection"
  }
}

///|
fn daemon_tick_count(model : Model) -> Int {
  match model.daemon_snapshot {
    Some(snapshot) => snapshot.tick_sequence
    None => 0
  }
}

///|
fn daemon_tick_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => "Daemon tick \{snapshot.tick_sequence}"
    None => "Daemon tick waiting"
  }
}

///|
fn daemon_heartbeat_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => "Heartbeat events \{snapshot.last_heartbeat_event_count}"
    None => "Heartbeat waiting"
  }
}

///|
fn daemon_cadence_label(model : Model) -> String {
  match model.daemon_snapshot {
    Some(snapshot) => {
      let mut cadence = 30
      let mut kind = "standing-goal"
      for job in snapshot.jobs {
        if job.id == "dispatch-standing-goals" {
          cadence = job.interval_seconds
          kind = job.kind
        }
      }
      "Daemon \{kind} cadence \{cadence}s"
    }
    None => "Daemon cadence waiting"
  }
}

///|
fn active_standing_goal(model : Model) -> StandingGoalSnapshot? {
  for goal in model.standing_goals {
    if goal.enabled {
      return Some(goal)
    }
  }
  None
}

///|
fn latest_watcher_record(model : Model) -> WatcherRunRecordSnapshot? {
  if model.watcher_records.is_empty() {
    None
  } else {
    Some(model.watcher_records[model.watcher_records.length() - 1])
  }
}

///|
fn latest_watcher_record_for_goal(
  model : Model,
  goal_id : String,
) -> WatcherRunRecordSnapshot? {
  let mut found : WatcherRunRecordSnapshot? = None
  for record in model.watcher_records {
    if record.goal_id == goal_id {
      found = Some(record)
    }
  }
  found
}

///|
fn latest_operator_request(model : Model) -> OperatorRequestSnapshot? {
  if model.operator_requests.is_empty() {
    None
  } else {
    Some(model.operator_requests[model.operator_requests.length() - 1])
  }
}

///|
fn watcher_decision_count(model : Model, decision : String) -> Int {
  let mut count = 0
  for record in model.watcher_records {
    if record.decision == decision {
      count += 1
    }
  }
  count
}

///|
fn watcher_decision_count_for_goal(
  model : Model,
  goal_id : String,
  decision : String,
) -> Int {
  let mut count = 0
  for record in model.watcher_records {
    if record.goal_id == goal_id && record.decision == decision {
      count += 1
    }
  }
  count
}

///|
fn watcher_record_count_for_goal(model : Model, goal_id : String) -> Int {
  let mut count = 0
  for record in model.watcher_records {
    if record.goal_id == goal_id {
      count += 1
    }
  }
  count
}

///|
fn watcher_metric_value(value : Int?) -> String {
  match value {
    Some(count) => count.to_string()
    None => "n/a"
  }
}

///|
fn watcher_book_changed_value(value : String?) -> String {
  match value {
    Some(flag) => flag
    None => "unknown"
  }
}

///|
fn ticks_until_next_goal_check(
  model : Model,
  goal : StandingGoalSnapshot,
) -> Int {
  let remaining = goal.next_due_tick - daemon_tick_count(model)
  if remaining < 0 {
    0
  } else {
    remaining
  }
}

///|
fn standing_goal_progress(model : Model, goal : StandingGoalSnapshot) -> Int {
  match goal.last_run_tick {
    Some(last_tick) => {
      let span = goal.next_due_tick - last_tick
      if span <= 0 {
        100
      } else {
        clamp_metric((daemon_tick_count(model) - last_tick) * 100 / span)
      }
    }
    None => if goal.next_due_tick <= daemon_tick_count(model) { 100 } else { 0 }
  }
}

///|
fn one_line(text : String) -> String {
  for line in text.split("\n") {
    return line.trim().to_string()
  }
  text
}

///|
fn request_status_tone(status : String) -> String {
  if status.contains("failed") || status.contains("Failed") {
    "alert"
  } else if status.contains("Accepted") || status.contains("Ready") {
    "calm"
  } else {
    "neutral"
  }
}

///|
fn resident_count(model : Model) -> Int {
  52 + model.tick % 19
}

///|
fn resident_joins_today(model : Model) -> Int {
  let strategy_lift = match model.strategy {
    Strategy::Balanced => 1
    Strategy::Throughput => 3
    Strategy::Recovery => 0
  }
  let recovery_drag = if mayor_recovery_active(model) { 2 } else { 0 }
  let joins = 4 + model.tick % 6 + strategy_lift - recovery_drag
  if joins < 1 {
    1
  } else {
    joins
  }
}

///|
fn active_quest_count(model : Model) -> Int {
  let mut count = 0
  for task in tasks_for_model(model) {
    if task.status == @core.TownTaskStatus::Assigned ||
      task.status == @core.TownTaskStatus::Running {
      count += 1
    }
  }
  count
}

///|
fn events_today(model : Model) -> Int {
  social_matches().length() + 1 + model.tick % 3
}

///|
fn valley_points_issued(model : Model) -> Int {
  valley_points_redeemed(model) +
  resident_joins_today(model) +
  events_today(model)
}

///|
fn valley_points_redeemed(model : Model) -> Int {
  12 + model.tick % 11
}

///|
fn achievement_broadcast_count(model : Model) -> Int {
  count_execution_status(
    executions_for_model(model),
    @core.TaskExecutionStatus::Completed,
  ) +
  model.tick % 3
}

///|
fn service_response_minutes(model : Model) -> Int {
  let recovery_delay = if mayor_recovery_active(model) { 2 } else { 0 }
  4 + model.pressure / 12 + recovery_delay
}

///|
fn agent_action_count(model : Model) -> Int {
  let running_workers = count_workers_by_status(
    workers_for_model(model),
    @core.WorkerStatus::Running,
  )
  18 + running_workers * 4 + model.tick % 9
}

///|
fn retention_signal(model : Model) -> Int {
  clamp_metric(
    (model.stability * 2 + model.energy + model.budget - model.pressure) / 3,
  )
}

///|
fn robot_service_count(model : Model) -> Int {
  8 + model.tick % 7
}

///|
fn strategy_label(strategy : Strategy) -> String {
  match strategy {
    Strategy::Balanced => "Balanced"
    Strategy::Throughput => "Throughput"
    Strategy::Recovery => "Recovery"
  }
}

///|
fn render_asset(asset_path : String, title : String) -> @rabbita.Html {
  let asset_class = "scene-asset " + scene_asset_class(asset_path)
  img(
    class=asset_class,
    src=asset_path,
    alt="\{title} asset",
    loading="lazy",
    no_children(),
  )
}

///|
fn scene_asset_class(asset_path : String) -> String {
  if asset_path.contains("actors/") || asset_path.contains("tilemap/actors/") {
    "scene-actor-asset"
  } else if asset_path.contains("effects/") {
    "scene-effect-asset"
  } else if asset_path.contains("props/") {
    "scene-prop-asset"
  } else if asset_path.contains("_roof") {
    "scene-roof-asset " + scene_asset_variant_class(asset_path)
  } else {
    "scene-building-asset " + scene_asset_variant_class(asset_path)
  }
}

///|
fn scene_asset_variant_class(asset_path : String) -> String {
  if asset_path.contains("variant=coding") {
    "scene-asset-coding"
  } else if asset_path.contains("variant=finance") {
    "scene-asset-finance"
  } else if asset_path.contains("city_hall") {
    "scene-asset-civic"
  } else if asset_path.contains("worker_yard") {
    "scene-asset-worker"
  } else if asset_path.contains("districts/") {
    "scene-asset-district"
  } else {
    ""
  }
}

///|
fn all_alerts(scene : @ui.SceneRenderModel, model : Model) -> Array[String] {
  let alerts : Array[String] = []
  if mayor_recovery_active(model) {
    alerts.push(
      "Mayor supervision is actively recovering the town loop before service collapse.",
    )
    return alerts
  }
  for alert in scene.alerts {
    alerts.push(alert)
  }
  if model.pressure > 72 {
    alerts.push("Queue pressure is above safe town thresholds.")
  }
  if model.stability < 38 {
    alerts.push("Town stability is degrading and blockers may spread.")
  }
  if model.budget < 24 {
    alerts.push("Budget reserve is thin; dispatch flexibility is shrinking.")
  }
  if alerts.is_empty() {
    alerts.push("No active alerts")
  }
  alerts
}

///|
fn render_alerts(alerts : Array[String]) -> @rabbita.Html {
  if alerts.length() == 1 && alerts[0] == "No active alerts" {
    div(class="alert-strip", [status_chip(alerts[0], "chip-calm")])
  } else if alerts.length() == 1 &&
    alerts[0] ==
    "Mayor supervision is actively recovering the town loop before service collapse." {
    div(class="alert-strip", [status_chip(alerts[0], "chip-recovery")])
  } else {
    div(
      class="alert-strip",
      alerts.map(alert => status_chip(alert, "chip-alert")),
    )
  }
}

///|
fn render_metric_card(metric : VitalityMetric) -> @rabbita.Html {
  let fill_style = ["width: \{metric.fill}%"]
  article(class="metric-card", [
    div(class="metric-head", [
      p(class="metric-label", metric.label),
      p(class="metric-value", metric.value),
    ]),
    div(class="metric-track", [
      div(class="metric-fill \{metric.tone}", style=fill_style, no_children()),
    ]),
    p(class="metric-detail", metric.detail),
  ])
}

///|
fn vitality_metrics(model : Model) -> Array[VitalityMetric] {
  let joins = resident_joins_today(model)
  let quests = active_quest_count(model)
  let events = events_today(model)
  let retention = retention_signal(model)
  [
    {
      label: "Resident joins",
      value: joins.to_string(),
      fill: clamp_metric(joins * 12),
      tone: "tone-budget",
      detail: "New founder or resident arrivals recorded in the current tick window.",
    },
    {
      label: "Active quests",
      value: quests.to_string(),
      fill: clamp_metric(quests * 11),
      tone: "tone-energy",
      detail: "Civic service and build lanes currently assigned or running.",
    },
    {
      label: "Events today",
      value: events.to_string(),
      fill: clamp_metric(events * 18),
      tone: "tone-pressure",
      detail: "Meetups, reviews, and district moments visible in the square.",
    },
    {
      label: "Return signal",
      value: "\{retention}%",
      fill: retention,
      tone: "tone-stability",
      detail: "Retention and repeat participation trend from the current town pulse.",
    },
  ]
}

///|
fn render_vitality_metric_grid(model : Model) -> Array[@rabbita.Html] {
  let cards : Array[@rabbita.Html] = []
  for metric in vitality_metrics(model) {
    cards.push(render_metric_card(metric))
  }
  cards
}

///|
fn render_civic_context(model : Model) -> @rabbita.Html {
  section(class="civic-context", [
    status_chip("Local time: \{real_time_label()}", "chip-clock"),
    status_chip("Date: \{real_calendar_label()}", "chip-book"),
    status_chip("Phase: \{real_phase_label()}", "chip-clock"),
    status_chip(daemon_cadence_label(model), "chip-neutral"),
    status_chip("Residents: \{resident_count(model)}", "chip-neutral"),
    status_chip(
      "Points flow: \{valley_points_issued(model)} issued / \{valley_points_redeemed(model)} redeemed",
      "chip-book",
    ),
    status_chip(
      "Broadcasts: \{achievement_broadcast_count(model)}",
      "chip-live",
    ),
    status_chip(
      "Response: \{service_response_minutes(model)} min",
      "chip-neutral",
    ),
    status_chip("Agent actions: \{agent_action_count(model)}", "chip-book"),
    status_chip("Return: \{retention_signal(model)}%", "chip-neutral"),
    status_chip("Robot calls: \{robot_service_count(model)}", "chip-neutral"),
  ])
}

///|
fn count_workers_by_status(
  workers : Array[WorkerSim],
  status : @core.WorkerStatus,
) -> Int {
  let mut count = 0
  for worker in workers {
    if worker.status == status {
      count += 1
    }
  }
  count
}

///|
fn runtime_stat_chip(
  label : String,
  value : Int,
  class_name : String,
) -> @rabbita.Html {
  article(class="runtime-stat \{class_name}", [
    p(class="metric-label", label),
    p(class="runtime-stat-value", value.to_string()),
  ])
}

///|
fn render_runtime_bar(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let running_workers = count_workers_by_status(
    workers,
    @core.WorkerStatus::Running,
  )
  let blocked_workers = count_workers_by_status(
    workers,
    @core.WorkerStatus::Blocked,
  )
  let review_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::ReviewQueued,
  )
  let persistence_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::AwaitingPersistence,
  )
  let completed_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::Completed,
  )
  section(class="runtime-bar", [
    div(class="runtime-head", [
      div(class="runtime-copy", [
        p(class="eyebrow", "Operator Surface"),
        h2("Town traffic, keeper queue, and review flow"),
        p(class="summary", state_source_detail(model)),
      ]),
      div(class="runtime-status", [
        status_chip(
          if model.state_source == StateSourceKind::SnapshotFile {
            "Snapshot bridge"
          } else if model.paused {
            "Simulation paused"
          } else {
            "Simulation live"
          },
          if model.state_source == StateSourceKind::SnapshotFile {
            "chip-neutral"
          } else if model.paused {
            "chip-alert"
          } else {
            "chip-live"
          },
        ),
        status_chip(
          "Source: \{state_source_label(model.state_source)}",
          "chip-book",
        ),
        status_chip("Workers online: \{workers.length()}", "chip-neutral"),
      ]),
    ]),
    div(class="runtime-grid", [
      runtime_stat_chip("Running", running_workers, "runtime-running"),
      runtime_stat_chip("Blocked", blocked_workers, "runtime-blocked"),
      runtime_stat_chip("Persisting", persistence_count, "runtime-persisting"),
      runtime_stat_chip("Review", review_count, "runtime-review"),
      runtime_stat_chip("Completed", completed_count, "runtime-completed"),
    ]),
  ])
}

///|
fn render_operator_stat(
  label : String,
  value : String,
  detail : String,
  tone : String,
) -> @rabbita.Html {
  article(class="operator-stat operator-stat-\{tone}", [
    p(class="metric-label", label),
    p(class="operator-stat-value", value),
    p(class="operator-stat-detail", detail),
  ])
}

///|
fn render_watcher_record(record : WatcherRunRecordSnapshot) -> @rabbita.Html {
  article(class="watch-timeline-item watch-decision-\{record.decision}", [
    div(class="watch-timeline-dot", no_children()),
    div(class="watch-timeline-copy", [
      h3("\{record.decision} at tick \{record.tick}"),
      p(one_line(record.detail)),
      div(class="watch-timeline-meta", [
        span("goal \{record.goal_id}"),
        span("book \{record.target_book_id}"),
        span("sources +\{record.new_source_count}"),
        span("checked \{watcher_metric_value(record.checked_sources_count)}"),
        span("found \{watcher_metric_value(record.new_sources_found)}"),
        span("accepted \{watcher_metric_value(record.accepted_facts_count)}"),
        span("rejected \{watcher_metric_value(record.rejected_facts_count)}"),
        span("wiki \{watcher_metric_value(record.wiki_pages_changed_count)}"),
        span("book changed \{watcher_book_changed_value(record.book_changed)}"),
        span("delta \{record.delta_score}"),
        span("next \{record.next_due_tick}"),
        match record.task_id {
          Some(task_id) => span("task \{task_id}")
          None => span("task pending")
        },
        match record.run_id {
          Some(run_id) => span("run \{run_id}")
          None => span("run pending")
        },
      ]),
    ]),
  ])
}

///|
fn render_watcher_timeline(model : Model) -> @rabbita.Html {
  let items : Array[@rabbita.Html] = []
  let count = if model.watcher_records.length() < 5 {
    model.watcher_records.length()
  } else {
    5
  }
  for offset in 0..<count {
    let record = model.watcher_records[model.watcher_records.length() -
      1 -
      offset]
    items.push(render_watcher_record(record))
  }
  if items.is_empty() {
    items.push(
      article(class="watch-timeline-empty", [
        h3("No watcher records yet"),
        p(
          "Start the daemon or submit a standing watch request to create a durable progress ledger.",
        ),
      ]),
    )
  }
  div(class="watch-timeline", items)
}

///|
fn watcher_decision_chip_class(decision : String) -> String {
  match decision {
    "Update" => "chip-live"
    "NeedsReview" => "chip-book"
    "Failed" => "chip-alert"
    "Deferred" => "chip-neutral"
    "NoChange" => "chip-calm"
    _ => "chip-neutral"
  }
}

///|
fn render_standing_goal_card(
  model : Model,
  goal : StandingGoalSnapshot,
) -> @rabbita.Html {
  let remaining = ticks_until_next_goal_check(model, goal)
  let progress = standing_goal_progress(model, goal)
  let target = goal.target_book_id.unwrap_or("mayor-selected-book")
  let latest = latest_watcher_record_for_goal(model, goal.id)
  let decision = match latest {
    Some(record) => record.decision
    None => "Waiting"
  }
  let detail = match latest {
    Some(record) => one_line(record.detail)
    None => "No ledger row has been recorded for this standing watch yet."
  }
  let latest_tick = match latest {
    Some(record) => "latest tick \{record.tick}"
    None => "no completed tick"
  }
  let checked_sources = match latest {
    Some(record) => watcher_metric_value(record.checked_sources_count)
    None => "n/a"
  }
  let accepted_facts = match latest {
    Some(record) => watcher_metric_value(record.accepted_facts_count)
    None => "n/a"
  }
  let new_sources_found = match latest {
    Some(record) => watcher_metric_value(record.new_sources_found)
    None => "n/a"
  }
  let rejected_facts = match latest {
    Some(record) => watcher_metric_value(record.rejected_facts_count)
    None => "n/a"
  }
  let changed_pages = match latest {
    Some(record) => watcher_metric_value(record.wiki_pages_changed_count)
    None => "n/a"
  }
  let book_changed = match latest {
    Some(record) => watcher_book_changed_value(record.book_changed)
    None => "unknown"
  }
  let update_count = watcher_decision_count_for_goal(model, goal.id, "Update")
  let review_count = watcher_decision_count_for_goal(
    model,
    goal.id,
    "NeedsReview",
  )
  let no_change_count = watcher_decision_count_for_goal(
    model,
    goal.id,
    "NoChange",
  )
  let failed_count = watcher_decision_count_for_goal(model, goal.id, "Failed")
  article(class="watch-goal-card watch-decision-\{decision}", [
    div(class="standing-progress-head", [
      div([p(class="eyebrow", "Standing Watch"), h3(goal.title)]),
      status_chip(decision, watcher_decision_chip_class(decision)),
    ]),
    p(class="standing-progress-copy", detail),
    p(class="watch-goal-prompt", one_line(goal.prompt)),
    div(class="standing-progress-track", [
      div(
        class="standing-progress-fill",
        style=["width: \{progress}%"],
        no_children(),
      ),
    ]),
    div(class="standing-progress-meta", [
      span("goal `\{goal.id}`"),
      span("book `\{target}`"),
      span(
        if remaining == 0 {
          "due now"
        } else {
          "next in \{remaining} ticks"
        },
      ),
      span(latest_tick),
      span("cadence \{goal.cadence_ticks} ticks"),
      span("quality \{goal.quality_threshold}%"),
      span(goal.source_policy),
      span("checked \{checked_sources}"),
      span("found \{new_sources_found}"),
      span("accepted \{accepted_facts}"),
      span("rejected \{rejected_facts}"),
      span("wiki \{changed_pages}"),
      span("book changed \{book_changed}"),
      span("records \{watcher_record_count_for_goal(model, goal.id)}"),
      span(
        "U\{update_count} / R\{review_count} / N\{no_change_count} / F\{failed_count}",
      ),
    ]),
  ])
}

///|
fn render_standing_goal_portfolio(model : Model) -> @rabbita.Html {
  let cards : Array[@rabbita.Html] = []
  for goal in model.standing_goals {
    if goal.enabled {
      cards.push(render_standing_goal_card(model, goal))
    }
  }
  if cards.is_empty() {
    cards.push(
      article(class="watch-goal-card", [
        div(class="standing-progress-head", [
          div([
            p(class="eyebrow", "Standing Watch Portfolio"),
            h3("No active standing goals"),
          ]),
          status_chip("Waiting", "chip-neutral"),
        ]),
        p(
          class="standing-progress-copy",
          "Add a standing goal in `.moontown/standing-goals.json` or submit one from the operator panel to start durable topic monitoring.",
        ),
      ]),
    )
  }
  section(class="watch-portfolio", [
    div(class="watch-portfolio-head", [
      div([p(class="eyebrow", "Watch Portfolio"), h3("Long-horizon topics")]),
      status_chip("\{cards.length()} configured", "chip-neutral"),
    ]),
    div(class="watch-portfolio-grid", cards),
  ])
}

///|
fn render_request_composer(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  let submit_label = if model.request_submitting {
    "Submitting..."
  } else {
    "Submit Standing Watch"
  }
  article(class="request-composer", [
    div(class="request-composer-head", [
      div([
        p(class="eyebrow", "New Request"),
        h3("Ask the town to keep watching"),
      ]),
      div(class="request-composer-actions-top", [
        status_chip("Writes standing-goals.json", "chip-book"),
        button(
          class="control-button request-submit",
          on_click=dispatch(SubmitOperatorRequest),
          submit_label,
        ),
      ]),
    ]),
    div(class="request-field-grid", [
      div(class="request-field request-field-wide", [
        p(class="request-label", "Title"),
        input(
          class="request-input",
          placeholder="Track AI tooling news",
          value=model.request_title,
          on_input=value => dispatch(SetRequestTitle(value)),
          "",
        ),
      ]),
      div(class="request-field", [
        p(class="request-label", "Target MoonBook"),
        input(
          class="request-input",
          placeholder="research-topic",
          value=model.request_book_id,
          on_input=value => dispatch(SetRequestBookId(value)),
          "",
        ),
      ]),
      div(class="request-field", [
        p(class="request-label", "Cadence ticks"),
        input(
          class="request-input",
          placeholder="60",
          value=model.request_cadence,
          on_input=value => dispatch(SetRequestCadence(value)),
          "",
        ),
      ]),
      div(class="request-field", [
        p(class="request-label", "Quality threshold"),
        input(
          class="request-input",
          placeholder="85",
          value=model.request_quality_threshold,
          on_input=value => dispatch(SetRequestQualityThreshold(value)),
          "",
        ),
      ]),
    ]),
    div(class="request-field", [
      p(class="request-label", "Request"),
      textarea(
        class="request-textarea",
        placeholder="Describe what the mayor should watch, what counts as a useful change, and what MoonBook should update.",
        value=model.request_prompt,
        on_input=value => dispatch(SetRequestPrompt(value)),
        no_children(),
      ),
    ]),
    div(class="request-actions", [
      p(
        class="request-status tone-\{request_status_tone(model.request_status)}",
        model.request_status,
      ),
    ]),
    match latest_operator_request(model) {
      Some(request) =>
        p(
          class="request-last",
          "Last accepted: `\{request.standing_goal_id}` (`\{request.id}`) for `\{request.target_book_id}` at \{request.created_at}. Status \{request.status}; title: \{request.title}; cadence \{request.cadence_ticks}; policy \{request.source_policy}; quality \{request.quality_threshold}%. Request: \{one_line(request.prompt)}",
        )
      None =>
        p(
          class="request-last",
          "No operator-submitted standing goals have been accepted in this browser session yet.",
        )
    },
  ])
}

///|
fn render_operator_command_center(
  dispatch : Dispatch[Msg],
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let running_workers = count_workers_by_status(
    workers,
    @core.WorkerStatus::Running,
  )
  let latest = latest_watcher_record(model)
  let latest_decision = match latest {
    Some(record) => record.decision
    None => "Waiting"
  }
  let latest_sources = match latest {
    Some(record) => record.new_source_count.to_string()
    None => "0"
  }
  let latest_checked = match latest {
    Some(record) => watcher_metric_value(record.checked_sources_count)
    None => "n/a"
  }
  let latest_accepted = match latest {
    Some(record) => watcher_metric_value(record.accepted_facts_count)
    None => "n/a"
  }
  let latest_wiki = match latest {
    Some(record) => watcher_metric_value(record.wiki_pages_changed_count)
    None => "n/a"
  }
  let latest_book_changed = match latest {
    Some(record) => watcher_book_changed_value(record.book_changed)
    None => "unknown"
  }
  let latest_detail = match latest {
    Some(record) => one_line(record.detail)
    None => "No durable watcher ledger has been published yet."
  }
  let progress_detail = match active_standing_goal(model) {
    Some(goal) =>
      "Next check in \{ticks_until_next_goal_check(model, goal)} ticks. Daemon tick \{daemon_tick_count(model)}."
    None => "No enabled standing goal found."
  }
  let update_count = watcher_decision_count(model, "Update")
  let review_count = watcher_decision_count(model, "NeedsReview")
  let no_change_count = watcher_decision_count(model, "NoChange")
  let failed_count = watcher_decision_count(model, "Failed")
  let daemon_identity = match model.daemon_snapshot {
    Some(snapshot) => "\{snapshot.daemon_id} / \{snapshot.lease_owner}"
    None => "daemon waiting"
  }
  let active_goal_count = match model.daemon_snapshot {
    Some(snapshot) => snapshot.active_goal_ids.length()
    None => 0
  }
  section(class="operator-console", [
    div(class="operator-console-head", [
      div([
        p(class="eyebrow", "Progress And Requests"),
        h2("Mayor command center"),
        p(
          class="summary",
          "This panel reads real runtime files: `town.json`, `daemon.json`, `standing-goals.json`, and the watcher ledger. It also lets you submit new standing-watch requests into the local daemon queue.",
        ),
      ]),
      div(class="operator-console-status", [
        status_chip(daemon_cadence_label(model), "chip-clock"),
        status_chip("Daemon \{daemon_identity}", "chip-neutral"),
        status_chip("Active due goals \{active_goal_count}", "chip-neutral"),
        status_chip(
          "Requests \{model.operator_requests.length()}",
          "chip-neutral",
        ),
        status_chip("Executions \{executions.length()}", "chip-neutral"),
      ]),
    ]),
    div(class="operator-console-grid", [
      div(class="operator-watch-column", [
        div(class="operator-stat-grid", [
          render_operator_stat(
            "Current workers",
            running_workers.to_string(),
            "Visible active workers in the current town projection.",
            "live",
          ),
          render_operator_stat(
            "Latest decision",
            latest_decision,
            latest_detail,
            if latest_decision == "Failed" {
              "alert"
            } else {
              "calm"
            },
          ),
          render_operator_stat(
            "New sources",
            latest_sources,
            "Latest digest: checked \{latest_checked}, accepted \{latest_accepted}, wiki pages \{latest_wiki}, book changed \{latest_book_changed}.",
            if latest_sources == "0" {
              "neutral"
            } else {
              "live"
            },
          ),
          render_operator_stat(
            "Decision mix",
            "U\{update_count} / R\{review_count} / N\{no_change_count} / F\{failed_count}",
            progress_detail,
            "neutral",
          ),
        ]),
        render_standing_goal_portfolio(model),
        render_watcher_timeline(model),
      ]),
      render_request_composer(dispatch, model),
    ]),
  ])
}

///|
fn render_module_metric(label : String, value : String) -> @rabbita.Html {
  div(class="module-metric", [
    span(class="module-metric-label", label),
    p(value),
  ])
}

///|
fn render_policy_hall_module_card(model : Model) -> @rabbita.Html {
  let worker = policy_hall_worker(model)
  let task = policy_hall_task(model)
  let execution = policy_hall_execution(model)
  let queue_pressure = policy_hall_queue_pressure(model, worker)
  let health = policy_hall_health(worker, execution)
  let confidence = policy_hall_confidence(model, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "South / services"),
    h3("Policy Hall"),
    p(policy_hall_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", policy_hall_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    div(class="module-detail-grid", [
      render_module_detail("Confidence", "\{confidence}%"),
      render_module_detail(
        "Checklist",
        policy_hall_checklist_label(model, execution),
      ),
      render_module_detail(
        "Evidence",
        policy_hall_evidence_label(model, execution),
      ),
    ]),
    p(
      class="module-next-action",
      "Next: \{policy_hall_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{policy_hall_signal_class(model, execution)}",
      policy_hall_signal(model, execution),
    ),
  ])
}

///|
fn render_resident_twins_module_card(model : Model) -> @rabbita.Html {
  let worker = find_book_worker(
    workers_for_model(model),
    "wenyu-resident-twins",
  )
  let task = find_book_task(task_specs(model), "wenyu-resident-twins")
  let execution = find_book_execution(
    execution_specs(model),
    "wenyu-resident-twins",
  )
  let queue_pressure = resident_twins_queue_pressure(model, worker)
  let health = resident_twins_health(worker, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "Central / lived layer"),
    h3("Resident Twins"),
    p(resident_twins_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", resident_twins_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    div(class="module-detail-grid", [
      render_module_detail(
        "Stage",
        resident_twins_build_stage(model, execution),
      ),
      render_module_detail(
        "Active twin",
        resident_twins_active_twin_label(model),
      ),
      render_module_detail("Privacy", resident_twins_privacy_label(model)),
    ]),
    p(
      class="module-next-action",
      "Next: \{resident_twins_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{resident_twins_signal_class(model, execution)}",
      resident_twins_signal(model, execution),
    ),
  ])
}

///|
fn render_social_square_module_card(model : Model) -> @rabbita.Html {
  let worker = social_square_worker(model)
  let task = social_square_task(model)
  let execution = social_square_execution(model)
  let lead_match = social_square_lead_match(model)
  let queue_pressure = social_square_queue_pressure(model, worker)
  let health = social_square_health(worker, execution)
  article(
    class="civic-module-card civic-module-card-featured civic-module-card-social-square",
    [
      p(class="scene-node-key", "Central / cafe"),
      h3("Social Square"),
      p(social_square_module_copy(model, worker, execution)),
      div(class="module-metric-grid", [
        render_module_metric("Worker", social_square_worker_label(worker)),
        render_module_metric("Queue", "\{queue_pressure}%"),
        render_module_metric("Health", "\{health}%"),
      ]),
      div(class="module-detail-grid", [
        render_module_detail("Stage", social_square_stage(model, execution)),
        render_module_detail("Lead pair", social_square_pair_label(lead_match)),
        render_module_detail(
          "Strongest match",
          "\{lead_match.confidence}% confidence",
        ),
      ]),
      p(
        class="module-next-action",
        "Next: \{social_square_next_action(model, task, execution)}",
      ),
      span(
        class="module-signal \{social_square_signal_class(model, execution)}",
        social_square_signal(model, execution),
      ),
    ],
  )
}

///|
fn render_talent_avenue_module_card(model : Model) -> @rabbita.Html {
  let worker = find_book_worker(workers_for_model(model), "talent-avenue")
  let task = find_book_task(task_specs(model), "talent-avenue")
  let execution = find_book_execution(execution_specs(model), "talent-avenue")
  let queue_pressure = talent_avenue_queue_pressure(model, worker)
  let health = talent_avenue_health(model, worker, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "Central / showcase"),
    h3("Talent Avenue"),
    p(talent_avenue_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", talent_avenue_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    p(
      class="module-next-action",
      "Next: \{talent_avenue_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{talent_avenue_signal_class(model, execution)}",
      talent_avenue_signal(model, execution),
    ),
  ])
}

///|
fn render_ai_garden_module_card(model : Model) -> @rabbita.Html {
  let worker = ai_garden_worker(model)
  let task = ai_garden_task(model)
  let execution = ai_garden_execution(model)
  let queue_pressure = ai_garden_queue_pressure(model, worker)
  let health = ai_garden_health(model, worker, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "North / eco"),
    h3("AI Garden"),
    p(ai_garden_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", ai_garden_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    div(class="module-detail-grid", [
      render_module_detail("Stage", ai_garden_stage(model, execution)),
      render_module_detail(
        "Tool trial",
        ai_garden_tool_trial_label(model, execution),
      ),
      render_module_detail("Workshop", ai_garden_workshop_label(model)),
    ]),
    p(
      class="module-next-action",
      "Next: \{ai_garden_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{ai_garden_signal_class(model, execution)}",
      ai_garden_signal(model, execution),
    ),
  ])
}

///|
fn render_town_shell_module_card(model : Model) -> @rabbita.Html {
  let tasks = tasks_for_model(model)
  let executions = executions_for_model(model)
  let worker = find_priority_book_worker(
    workers_for_model(model),
    "wenyu-town-shell",
  )
  let task = find_priority_book_task(tasks, "wenyu-town-shell")
  let execution = find_priority_book_execution(executions, "wenyu-town-shell")
  let queue_pressure = town_shell_queue_pressure(model, worker)
  let health = town_shell_health(worker, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "Town-wide / operator shell"),
    h3("Town Shell"),
    p(town_shell_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", town_shell_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    div(class="module-detail-grid", [
      render_module_detail("Runtime feed", town_shell_runtime_feed_label(model)),
      render_module_detail(
        "Activity",
        town_shell_activity_label(model, tasks, executions),
      ),
      render_module_detail("Stage", town_shell_build_stage(model, execution)),
    ]),
    p(
      class="module-next-action",
      "Next: \{town_shell_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{town_shell_signal_class(model, execution)}",
      town_shell_signal(model, execution),
    ),
  ])
}

///|
fn render_vitality_dashboard_module_card(model : Model) -> @rabbita.Html {
  let tasks = tasks_for_model(model)
  let executions = executions_for_model(model)
  let worker = find_priority_book_worker(
    workers_for_model(model),
    "wenyu-town-shell",
  )
  let task = find_priority_book_task(tasks, "wenyu-town-shell")
  let execution = find_priority_book_execution(executions, "wenyu-town-shell")
  let queue_pressure = vitality_dashboard_queue_pressure(model, worker)
  let health = vitality_dashboard_health(model, worker, execution)
  article(
    class="civic-module-card civic-module-card-featured civic-module-card-vitality-dashboard",
    [
      p(class="scene-node-key", "Central square / district pulse"),
      h3("Vitality Dashboard"),
      p(vitality_dashboard_module_copy(model, worker, execution)),
      div(class="module-metric-grid", [
        render_module_metric("Worker", vitality_dashboard_worker_label(worker)),
        render_module_metric("Queue", "\{queue_pressure}%"),
        render_module_metric("Health", "\{health}%"),
      ]),
      div(class="module-detail-grid", [
        render_module_detail(
          "Points",
          vitality_dashboard_points_flow_label(model),
        ),
        render_module_detail(
          "Broadcasts",
          vitality_dashboard_broadcast_label(model),
        ),
        render_module_detail(
          "Response",
          "\{service_response_minutes(model)} min",
        ),
      ]),
      p(
        class="module-next-action",
        "Next: \{vitality_dashboard_next_action(model, task, execution)}",
      ),
      span(
        class="module-signal \{vitality_dashboard_signal_class(model, execution)}",
        vitality_dashboard_signal(model, execution),
      ),
    ],
  )
}

///|
fn render_contest_express_module_card(model : Model) -> @rabbita.Html {
  let tasks = tasks_for_model(model)
  let executions = executions_for_model(model)
  let worker = find_priority_book_worker(
    workers_for_model(model),
    "wenyu-contest-express",
  )
  let task = find_priority_book_task(tasks, "wenyu-contest-express")
  let execution = find_priority_book_execution(
    executions, "wenyu-contest-express",
  )
  let queue_pressure = contest_express_queue_pressure(model, worker)
  let health = contest_express_health(worker, execution)
  article(class="civic-module-card civic-module-card-featured", [
    p(class="scene-node-key", "Future Harbor / roadshow lane"),
    h3("Contest Express"),
    p(contest_express_module_copy(model, worker, execution)),
    div(class="module-metric-grid", [
      render_module_metric("Worker", contest_express_worker_label(worker)),
      render_module_metric("Queue", "\{queue_pressure}%"),
      render_module_metric("Health", "\{health}%"),
    ]),
    div(class="module-detail-grid", [
      render_module_detail("Countdown", contest_express_countdown_label(model)),
      render_module_detail(
        "Readiness",
        contest_express_readiness_label(model, execution),
      ),
      render_module_detail(
        "Champion wall",
        contest_express_champion_label(model, execution),
      ),
    ]),
    p(
      class="module-next-action",
      "Next: \{contest_express_next_action(model, task, execution)}",
    ),
    span(
      class="module-signal \{contest_express_signal_class(model, execution)}",
      contest_express_signal(model, execution),
    ),
  ])
}

///|
fn render_civic_modules(model : Model) -> @rabbita.Html {
  section(class="civic-modules", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Wenyu Valley Modules"),
      h2("Town shell plus live civic systems"),
      p(
        class="summary",
        if mayor_recovery_active(model) {
          "Recovery patrol is active: the mayor is throttling queues, restoring worker energy, and keeping services online."
        } else {
          "The town stays alive through policy quests, social matching, talent projection, AI learning, and virtual-physical service loops."
        },
      ),
    ]),
    div(class="civic-module-grid", [
      render_town_shell_module_card(model),
      render_vitality_dashboard_module_card(model),
      render_resident_twins_module_card(model),
      render_policy_hall_module_card(model),
      render_contest_express_module_card(model),
      render_social_square_module_card(model),
      render_talent_avenue_module_card(model),
      render_ai_garden_module_card(model),
      render_physical_bridge_module_card(model),
    ]),
  ])
}

///|
fn resident_twins_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Memory awaiting persistence"
          @core.TaskExecutionStatus::ReviewQueued => "Needs review"
          @core.TaskExecutionStatus::Completed => "Twin live"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Reflection running"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Twin dispatch"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Recovery required"
        }
      None => "Twin queued"
    }
  }
}

///|
fn resident_twins_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed
          | @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn resident_twins_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let active_twin = resident_twins_active_twin_label(model)
  let private_count = resident_private_scope_count(model)
  let review_count = resident_review_queue_count(model)
  let worker_text = resident_twins_worker_label(worker)
  let build_stage = resident_twins_build_stage(model, execution)
  "Resident Twins now runs as a supervised district lane. \{worker_text} is carrying the memory-reflection-plan loop, \{active_twin} is the active twin in view, \{private_count} private scopes stay hidden from town view, \{review_count} records need keeper attention, and the current stage is \{build_stage}."
}

///|
fn resident_twins_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Twin Keeper / pending"
  }
}

///|
fn resident_twins_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  let review_weight = resident_review_queue_count(model) * 16
  match worker {
    Some(worker) =>
      clamp_metric((worker.load + model.pressure + review_weight) / 3)
    None => clamp_metric(model.pressure + review_weight)
  }
}

///|
fn resident_twins_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) => clamp_metric(worker.energy - worker.load / 4 + 22)
    None => 54
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 28)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 10)
        _ => base
      }
    None => base
  }
}

///|
fn resident_twins_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the reviewed resident summary and refresh the projection-safe handoff."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear keeper review before exposing the next reflection summary in town view."
        @core.TaskExecutionStatus::Completed =>
          "Publish the updated resident lane into the next runtime projection snapshot."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the current reflection cycle and keep the next resident plan visible."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm the district patch dispatch and keep resident memory projection-safe."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled resident lane before memory and plan cards drift."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None => resident_twins_resident_plan(model)
      }
  }
}

///|
fn resident_twins_build_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Patch packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Reflection loop running"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Memory awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "Projection updated"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.tick % 4 < 2 {
        "Projection wiring queued"
      } else {
        "Review loop visible"
      }
  }
}

///|
fn resident_twins_active_twin(model : Model) -> ResidentSim? {
  let residents = resident_sims(model)
  if residents.is_empty() {
    None
  } else {
    residents.get(model.tick % residents.length())
  }
}

///|
fn resident_twins_active_twin_label(model : Model) -> String {
  match resident_twins_active_twin(model) {
    Some(resident) => "\{resident.name} / \{resident.zone}"
    None => "Await first resident projection"
  }
}

///|
fn resident_twins_privacy_label(model : Model) -> String {
  let residents = resident_sims(model)
  let private_count = resident_private_scope_count(model)
  let visible_count = residents.length() - private_count
  if residents.is_empty() {
    "Projection pending"
  } else {
    "\{private_count} private / \{visible_count} shared"
  }
}

///|
fn town_shell_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Patch awaiting persistence"
          @core.TaskExecutionStatus::ReviewQueued => "Patch review queued"
          @core.TaskExecutionStatus::Completed => "Patch landed"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Build live"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Build dispatch"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Build queued"
    }
  }
}

///|
fn town_shell_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed
          | @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn town_shell_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = town_shell_queue_pressure(model, worker)
  let build_stage = town_shell_build_stage(model, execution)
  let worker_text = town_shell_worker_label(worker)
  let runtime_feed = town_shell_runtime_feed_label(model)
  "Town Shell now carries the Wenyu build lane as a visible district. \{worker_text} is driving the operator surface, queue pressure sits at \{queue_pressure}%, the runtime feed is \{runtime_feed}, and the current build stage is \{build_stage}."
}

///|
fn town_shell_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Town Shell Foreman / pending"
  }
}

///|
fn town_shell_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  match worker {
    Some(worker) => clamp_metric((worker.load + model.pressure) / 2)
    None => model.pressure
  }
}

///|
fn town_shell_runtime_feed_label(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    if projection_snapshot_is_ready(model.projection_snapshot) {
      "Projection live"
    } else {
      "Bridge waiting"
    }
  } else {
    "Demo supervision"
  }
}

///|
fn town_shell_activity_label(
  model : Model,
  tasks : Array[@core.TownTask],
  executions : Array[@core.TaskExecutionRecord],
) -> String {
  let running_workers = count_workers_by_status(
    workers_for_model(model),
    @core.WorkerStatus::Running,
  )
  let review_count = count_execution_status(
    executions,
    @core.TaskExecutionStatus::ReviewQueued,
  )
  "\{running_workers} workers / \{tasks.length()} tasks / \{review_count} review"
}

///|
fn town_shell_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) => clamp_metric(worker.energy - worker.load / 4 + 18)
    None => 48
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 6)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 16)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 28)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 10)
        _ => base
      }
    None => base
  }
}

///|
fn town_shell_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the validated patch and refresh the book's code-patch record."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear the queued review so the Town Shell lane can return to live build status."
        @core.TaskExecutionStatus::Completed =>
          "Roll the updated district card into the next runtime projection snapshot."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the focused UI slice and keep the shell readable while the build runs."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm the patch dispatch and keep the lane visible in the town dashboard."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled build run before the shell drifts back to placeholder state."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Connect the persisted browser bridge so Town Shell reads live projection state."
          } else {
            "Keep the live district card aligned with runtime projection data."
          }
      }
  }
}

///|
fn town_shell_build_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Patch packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Code patch running"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Patch awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "District card updated"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.tick % 4 < 2 {
        "Backlog materialized"
      } else {
        "Asset prompts queued"
      }
  }
}

///|
fn vitality_dashboard_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else if mayor_recovery_active(model) {
    "Recovery loop"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence => "Pulse persisting"
          @core.TaskExecutionStatus::ReviewQueued => "Pulse review"
          @core.TaskExecutionStatus::Completed => "Pulse live"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Pulse syncing"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Sync queued"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Pulse active"
    }
  }
}

///|
fn vitality_dashboard_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else if mayor_recovery_active(model) {
    "module-signal-alert"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed
          | @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn vitality_dashboard_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let joins = resident_joins_today(model)
  let quests = active_quest_count(model)
  let events = events_today(model)
  let return_signal = retention_signal(model)
  let response = service_response_minutes(model)
  let broadcasts = achievement_broadcast_count(model)
  let actions = agent_action_count(model)
  let build_stage = town_shell_build_stage(model, execution)
  let worker_text = vitality_dashboard_worker_label(worker)
  "Moontown now projects a real Vitality Dashboard lane: \{worker_text} is keeping the district pulse visible, \{joins} joins, \{quests} active quests, and \{events} events are on the board, \{broadcasts} achievement broadcasts are live, service response is \{response} minutes, agent actions total \{actions}, return signal is \{return_signal}%, and the current patch stage is \{build_stage}."
}

///|
fn vitality_dashboard_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Town Shell Foreman / pending"
  }
}

///|
fn vitality_dashboard_points_flow_label(model : Model) -> String {
  "\{valley_points_issued(model)} issued / \{valley_points_redeemed(model)} redeemed"
}

///|
fn vitality_dashboard_broadcast_label(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile &&
    !projection_snapshot_is_ready(model.projection_snapshot) {
    "Bridge waiting"
  } else {
    "\{achievement_broadcast_count(model)} live"
  }
}

///|
fn vitality_dashboard_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  let quest_load = active_quest_count(model) * 5
  match worker {
    Some(worker) =>
      clamp_metric((worker.load + model.pressure + quest_load) / 3)
    None => clamp_metric(model.pressure + quest_load / 2)
  }
}

///|
fn vitality_dashboard_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        (worker.energy + model.stability + retention_signal(model)) / 3,
      )
    None => clamp_metric((model.energy + model.stability) / 2)
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 30)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 8)
        _ => base
      }
    None => base
  }
}

///|
fn vitality_dashboard_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the validated vitality slice so Moontown can project it beyond demo simulation."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear keeper review and keep the district pulse visible while MoonBook absorbs the record."
        @core.TaskExecutionStatus::Completed =>
          "Wire the next projection snapshot so joins, quests, and retention stop depending on local simulation."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the UI slice while keeping queue pressure, health, and next action legible."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm the code-patch dispatch and keep the vitality lane visible in the town square."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled vitality run before the district pulse drifts out of sync."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Connect the projection bridge so the vitality lane reads persisted town state."
          } else {
            "Keep the district pulse aligned with Moontown projection, MoonBook counters, and MoonClaw events."
          }
      }
  }
}

///|
fn contest_express_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Replay under review"
          @core.TaskExecutionStatus::ReviewQueued => "Judge review queued"
          @core.TaskExecutionStatus::Completed => "Roadshow ready"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Mock judge live"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Dispatching"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Readiness live"
    }
  }
}

///|
fn contest_express_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn contest_express_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = contest_express_queue_pressure(model, worker)
  let stage = contest_express_stage(model, execution)
  let worker_text = contest_express_worker_label(worker)
  "Contest coaching stays visible in the mayor loop: \{worker_text} is advancing \{stage}, queue pressure sits at \{queue_pressure}%, and the next resident-facing handoff stays reviewable."
}

///|
fn contest_express_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Contest Conductor / pending"
  }
}

///|
fn contest_express_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  match worker {
    Some(worker) => worker.load
    None => clamp_metric(model.pressure + 8)
  }
}

///|
fn contest_express_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) => clamp_metric(worker.energy - worker.load / 4 + 4)
    None => 46
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          clamp_metric(base - 10)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 20)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 30)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 10)
        _ => base
      }
    None => base
  }
}

///|
fn contest_express_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  ignore(model)
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Keep the readiness score and replay link visible while MoonBook persists the reviewed packet."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Route the mock-judge notes through keeper review before broadcasting the next reminder."
        @core.TaskExecutionStatus::Completed =>
          "Publish the champion-wall summary, then schedule the next countdown checkpoint."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish mock judging and turn weak sections into a revision packet."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm dispatch and open the next contest-readiness step."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled contest lane before the next roadshow countdown slips."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None => "Open the contest calendar and score the next readiness gap."
      }
  }
}

///|
fn contest_express_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Readiness packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Mock judge scoring"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Replay awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "Champion-wall ready"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.tick % 4 < 2 {
        "Deck gap review"
      } else {
        "Reminder schedule"
      }
  }
}

///|
fn contest_express_countdown_label(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    if projection_snapshot_is_ready(model.projection_snapshot) {
      "Projection-controlled"
    } else {
      "Bridge waiting"
    }
  } else {
    let days_left = 9 - model.tick % 5
    "T-\{days_left} days"
  }
}

///|
fn contest_express_readiness_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let score = match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => 96
        @core.TaskExecutionStatus::AwaitingPersistence => 88
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => 74
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => 67
        @core.TaskExecutionStatus::ReviewQueued => 58
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          34
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        46
      } else {
        79
      }
  }
  "\{score}% ready"
}

///|
fn contest_express_champion_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => "Replay queued"
        @core.TaskExecutionStatus::AwaitingPersistence => "Summary persisting"
        @core.TaskExecutionStatus::ReviewQueued => "Review before broadcast"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "Waiting on judge notes"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Champion wall draft"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Broadcast blocked"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Projection pending"
      } else {
        "Ready after next win"
      }
  }
}

///|
fn ai_garden_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Tutorial under review"
          @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
          @core.TaskExecutionStatus::Completed => "Lesson published"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Tool trial live"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Dispatching"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Learning live"
    }
  }
}

///|
fn ai_garden_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn ai_garden_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let worker_text = ai_garden_worker_label(worker)
  let stage = ai_garden_stage(model, execution)
  let scenario_count = ai_garden_scenario_count(model)
  let queue_pressure = ai_garden_queue_pressure(model, worker)
  let tool_trial = ai_garden_tool_trial_label(model, execution)
  let workshop = ai_garden_workshop_label(model)
  "AI Garden now reads as a live learning district: \{worker_text} is carrying \{stage}, \{scenario_count} scenario lanes are visible in town view, \{tool_trial} is on deck, \{workshop} is active, and queue pressure sits at \{queue_pressure}%."
}

///|
fn ai_garden_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "AI Garden Tutor / pending"
  }
}

///|
fn ai_garden_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  let scenarios = ai_garden_scenario_count(model)
  match worker {
    Some(worker) =>
      clamp_metric((worker.load + model.pressure + scenarios * 6) / 3)
    None => clamp_metric(model.pressure + scenarios * 5)
  }
}

///|
fn ai_garden_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let scenario_bonus = ai_garden_scenario_count(model) * 5
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        scenario_bonus -
        ai_garden_queue_pressure(model, Some(worker)) / 4,
      )
    None => clamp_metric(50 + scenario_bonus)
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 30)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 10)
        _ => base
      }
    None => base
  }
}

///|
fn ai_garden_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the reviewed tutorial page and refresh the district-facing learning snapshot."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Resolve keeper review before promoting the next public-safe tool trial."
        @core.TaskExecutionStatus::Completed =>
          "Queue the next resident scenario and compare before-and-after output in town view."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the guided tool trial and keep the five-minute lesson visible to residents."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm dispatch and open the next AI adoption quest."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled tutorial run before the daily learning loop drifts."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Connect MoonBook learning projections so the district stops relying on synthetic examples."
          } else {
            "Keep AI Garden visible as a practical on-ramp to resident AI adoption."
          }
      }
  }
}

///|
fn ai_garden_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Tool trial packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Tutorial quest running"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Tutorial awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "Daily lesson published"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.tick % 4 < 2 {
        "Scenario drafting"
      } else {
        "Workshop rotation"
      }
  }
}

///|
fn ai_garden_tool_trial_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => "Before/after lesson published"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Reviewed lesson waiting for persist"
        @core.TaskExecutionStatus::ReviewQueued =>
          "Comparison draft in keeper review"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Email draft comparison live"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Scenario packet staged"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Tool trial recovery required"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Projection lesson pending"
      } else {
        "Client email tool trial"
      }
  }
}

///|
fn ai_garden_workshop_label(model : Model) -> String {
  if model.state_source == StateSourceKind::SnapshotFile &&
    !projection_snapshot_is_ready(model.projection_snapshot) {
    "Projection workshop waiting"
  } else {
    match model.tick % 3 {
      0 => "Creator workshop live"
      1 => "Template remix circle"
      _ => "Five-minute tutorial clinic"
    }
  }
}

///|
fn ai_garden_comparison_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => "Comparison proof published"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Comparison proof persisting"
        @core.TaskExecutionStatus::ReviewQueued =>
          "Comparison proof under review"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "Live before/after capture"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Comparison prompt staged"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Comparison proof blocked"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Projection proof pending"
      } else {
        "Before/after proof loop"
      }
  }
}

///|
fn ai_garden_scenario_count(model : Model) -> Int {
  let base = 3
  if mayor_recovery_active(model) {
    base - 1
  } else if model.tick % 4 == 0 {
    base + 1
  } else {
    base
  }
}

///|
fn render_physical_bridge_module_card(model : Model) -> @rabbita.Html {
  let worker = find_book_worker(
    workers_for_model(model),
    "wenyu-physical-bridge",
  )
  let task = find_book_task(task_specs(model), "wenyu-physical-bridge")
  let execution = find_book_execution(
    execution_specs(model),
    "wenyu-physical-bridge",
  )
  let queue_pressure = physical_bridge_queue_pressure(model, worker)
  let health = physical_bridge_health(model, worker, execution)
  article(
    class="civic-module-card civic-module-card-featured civic-module-card-physical-bridge",
    [
      p(class="scene-node-key", "South / virtual-physical connector"),
      h3("Physical Bridge"),
      p(physical_bridge_module_copy(model, worker, execution)),
      div(class="module-metric-grid", [
        render_module_metric("Worker", physical_bridge_worker_label(worker)),
        render_module_metric("Queue", "\{queue_pressure}%"),
        render_module_metric("Health", "\{health}%"),
      ]),
      div(class="module-detail-grid", [
        render_module_detail("Stage", physical_bridge_stage(model, execution)),
        render_module_detail(
          "Handoff",
          physical_bridge_handoff_label(model, execution),
        ),
        render_module_detail("Coverage", physical_bridge_coverage_label(model)),
      ]),
      p(
        class="module-next-action",
        "Next: \{physical_bridge_next_action(model, task, execution)}",
      ),
      span(
        class="module-signal \{physical_bridge_signal_class(model, execution)}",
        physical_bridge_signal(model, execution),
      ),
    ],
  )
}

///|
fn physical_bridge_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Telemetry awaiting persistence"
          @core.TaskExecutionStatus::ReviewQueued => "Bridge review queued"
          @core.TaskExecutionStatus::Completed => "District link live"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Bridge sync live"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Sync dispatch"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Bridge staged"
    }
  }
}

///|
fn physical_bridge_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed
          | @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn physical_bridge_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let worker_text = physical_bridge_worker_label(worker)
  let stage = physical_bridge_stage(model, execution)
  let robot_calls = robot_service_count(model)
  let telemetry_signals = physical_bridge_telemetry_signal_count(model)
  "Physical Bridge turns Wenyu's offline promise into a reviewable district lane. \{worker_text} is carrying \{stage}, \{robot_calls} robot or venue calls are visible in this window, and \{telemetry_signals} live telemetry signals are ready for projection-safe town view."
}

///|
fn physical_bridge_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Physical Bridge Link / pending"
  }
}

///|
fn physical_bridge_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  let load_bonus = robot_service_count(model) +
    physical_bridge_telemetry_signal_count(model) * 4
  match worker {
    Some(worker) =>
      clamp_metric((worker.load + model.pressure + load_bonus) / 2)
    None => clamp_metric(model.pressure + load_bonus)
  }
}

///|
fn physical_bridge_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let telemetry_bonus = physical_bridge_telemetry_signal_count(model) * 5
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        telemetry_bonus -
        physical_bridge_queue_pressure(model, Some(worker)) / 4,
      )
    None => clamp_metric(48 + telemetry_bonus)
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 28)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 12)
        _ => base
      }
    None => base
  }
}

///|
fn physical_bridge_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the reviewed telemetry and booking slice so Moontown can project a trustworthy district state."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear keeper review before exposing proxy attendance or room status beyond projection-safe summaries."
        @core.TaskExecutionStatus::Completed =>
          "Refresh the town tile with the latest room, robot, and telemetry counters instead of the generic bridge placeholder."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the room-and-robot sync and keep next action legible for the mayor loop."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm dispatch and open the next virtual-to-physical handoff."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled bridge run before offline status drifts away from the visible town."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Connect the projection bridge so Physical Bridge stops relying on demo-only telemetry."
          } else {
            "Keep robot calls, room holds, and district telemetry visible without leaking private execution state."
          }
      }
  }
}

///|
fn physical_bridge_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge pending"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported =>
            "Bridge packet prepared"
          @core.TaskExecutionStatus::RunConfirmed
          | @core.TaskExecutionStatus::Running => "Room and robot sync running"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Telemetry awaiting persistence"
          @core.TaskExecutionStatus::ReviewQueued => "Projection review queued"
          @core.TaskExecutionStatus::Completed => "District tile ready"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Recovery required"
        }
      None =>
        if mayor_recovery_active(model) {
          "Recovery patrol handoff"
        } else {
          "Live district sync"
        }
    }
  }
}

///|
fn physical_bridge_handoff_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection-safe room and robot feed"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Telemetry and booking slice persisting"
          @core.TaskExecutionStatus::ReviewQueued =>
            "Proxy attendance waiting for keeper review"
          @core.TaskExecutionStatus::Completed =>
            "Room, robot, and proxy counters ready"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed =>
            "Room hold and robot sync in motion"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported =>
            "Mayor dispatch opened for bridge run"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Offline bridge handoff stalled"
        }
      None => "Warm handoff between venue, robot, and telemetry lanes"
    }
  }
}

///|
fn physical_bridge_coverage_label(model : Model) -> String {
  "\{robot_service_count(model)} calls / \{physical_bridge_telemetry_signal_count(model)} signals"
}

///|
fn physical_bridge_telemetry_signal_count(model : Model) -> Int {
  3 + model.tick % 4
}

///|
fn talent_avenue_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Tour note under review"
          @core.TaskExecutionStatus::ReviewQueued => "Reception review queued"
          @core.TaskExecutionStatus::Completed => "Talent wall live"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Heatmap refreshing"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Dispatching"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Graph warm"
    }
  }
}

///|
fn talent_avenue_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn talent_avenue_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let worker_text = talent_avenue_worker_label(worker)
  let graph_entities = talent_signals(model).length()
  let verified_cards = talent_avenue_verified_card_count(model)
  let stage = talent_avenue_stage(model, execution)
  "Talent Avenue keeps the district legible for visitors and operators: \{worker_text} is carrying \{stage}, \{graph_entities} public-safe cards are live, and \{verified_cards} cards already carry reviewable evidence status."
}

///|
fn talent_avenue_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Talent Cartographer / pending"
  }
}

///|
fn talent_avenue_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  let activity = talent_avenue_activity_score(model)
  match worker {
    Some(worker) => clamp_metric((worker.load + activity) / 2)
    None => clamp_metric((model.pressure + activity) / 2)
  }
}

///|
fn talent_avenue_health(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) =>
      clamp_metric(
        worker.energy +
        talent_avenue_verified_card_count(model) * 8 -
        talent_avenue_queue_pressure(model, Some(worker)) / 4,
      )
    None => 44
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 28)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 10)
        _ => base
      }
    None => base
  }
}

///|
fn talent_avenue_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Keep the VIP route note visible while MoonBook persists the reviewed reception summary."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear the queued reception review before promoting the next public-safe card."
        @core.TaskExecutionStatus::Completed =>
          "Publish the refreshed tour cards and export the next talent graph snapshot."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Refresh achievements, evidence tags, and reception notes without leaking resident-private detail."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm dispatch and open the next showcase refresh for operators."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled talent graph before the reception route goes stale."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Bridge Talent Avenue to a persisted MoonBook projection before switching out of snapshot mode."
          } else {
            "Keep the talent wall aligned with the next reception-ready projection."
          }
      }
  }
}

///|
fn talent_avenue_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Showcase packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Talent heatmap refresh"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Reception summary awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "Tour cards ready"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.tick % 4 < 2 {
        "Achievement broadcast refresh"
      } else {
        "VIP route planning"
      }
  }
}

///|
fn talent_avenue_activity_score(model : Model) -> Int {
  let signals = talent_signals(model)
  let mut total = 0
  for signal in signals {
    total += signal.activity
  }
  total / signals.length()
}

///|
fn talent_avenue_verified_card_count(model : Model) -> Int {
  let mut count = 0
  for signal in talent_signals(model) {
    if signal.evidence_status == "Verified evidence" {
      count += 1
    }
  }
  count
}

///|
fn social_square_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "Follow-up persisting"
          @core.TaskExecutionStatus::ReviewQueued => "Review queued"
          @core.TaskExecutionStatus::Completed => "Follow-up landed"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "Match live"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Match queued"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Needs recovery"
        }
      None => "Matchmaking"
    }
  }
}

///|
fn social_square_worker(model : Model) -> WorkerSim? {
  find_book_worker_by_ids(workers_for_model(model), social_square_book_ids())
}

///|
fn social_square_task(model : Model) -> @core.TownTask? {
  find_book_task_by_ids(tasks_for_model(model), social_square_book_ids())
}

///|
fn social_square_execution(model : Model) -> @core.TaskExecutionRecord? {
  find_priority_book_execution_by_ids(
    executions_for_model(model),
    social_square_book_ids(),
  )
}

///|
fn social_square_book_ids() -> Array[String] {
  ["social-square", "wenyu-social-square"]
}

///|
fn social_square_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "module-signal-neutral"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::ReviewQueued
          | @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "module-signal-alert"
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "module-signal-review"
          @core.TaskExecutionStatus::Completed
          | @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
          _ => "module-signal-book"
        }
      None => "module-signal-book"
    }
  }
}

///|
fn social_square_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = social_square_queue_pressure(model, worker)
  let lead_match = social_square_lead_match(model)
  let confidence = lead_match.confidence
  let social_step = social_square_stage(model, execution)
  "Social Square now reads like a live district instead of a static networking tile. \{social_square_worker_label(worker)} is holding \{social_matches().length()} reasoned introductions, queue pressure sits at \{queue_pressure}%, strongest current confidence is \{confidence}%, and the active social step is \{social_step}."
}

///|
fn social_square_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Cafe Matchmaker / pending"
  }
}

///|
fn social_square_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  match worker {
    Some(worker) =>
      clamp_metric(
        (worker.load + model.pressure + social_matches().length() * 8) / 2,
      )
    None => clamp_metric(model.pressure + social_matches().length() * 4)
  }
}

///|
fn social_square_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) => clamp_metric(worker.energy - worker.load / 5 + 22)
    None => 54
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 4)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 14)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 24)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 8)
        _ => base
      }
    None => base
  }
}

///|
fn social_square_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Persist the reviewed intro outcome and follow-up note into MoonBook social records."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Clear the sensitive match review before the invite and reminder plan is sent."
        @core.TaskExecutionStatus::Completed =>
          "Project the latest follow-up back into the district card and resident-safe memory handoff."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the cafe intro proposal with RSVP timing and a low-pressure follow-up."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm the dispatch so the reason and confidence stay visible in the town loop."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled introduction run before the context for this weak tie goes cold."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Load projected social records so the district stops relying on demo-only matches."
          } else {
            "Keep the district card aligned with reviewed matches, event plans, and follow-up memory."
          }
      }
  }
}

///|
fn social_square_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  if model.state_source == StateSourceKind::SnapshotFile {
    "Projection bridge pending"
  } else {
    match execution {
      Some(execution) =>
        match execution.status {
          @core.TaskExecutionStatus::AwaitingPersistence =>
            "MoonBook follow-up persistence"
          @core.TaskExecutionStatus::ReviewQueued => "Sensitive match review"
          @core.TaskExecutionStatus::Completed => "Follow-up recorded"
          @core.TaskExecutionStatus::Running
          | @core.TaskExecutionStatus::RunConfirmed => "RSVP plan in flight"
          @core.TaskExecutionStatus::PacketReady
          | @core.TaskExecutionStatus::ProposalImported => "Match dispatch"
          @core.TaskExecutionStatus::Failed
          | @core.TaskExecutionStatus::Stale => "Recovery required"
        }
      None => "Reasoned introductions"
    }
  }
}

///|
fn social_square_lead_match(model : Model) -> SocialMatchSim {
  let matches = social_matches()
  matches[model.tick % matches.length()]
}

///|
fn social_square_pair_label(match_item : SocialMatchSim) -> String {
  "\{match_item.left} x \{match_item.right}"
}

///|
fn ai_garden_worker(model : Model) -> WorkerSim? {
  find_book_worker_by_ids(workers_for_model(model), ai_garden_book_ids())
}

///|
fn ai_garden_task(model : Model) -> @core.TownTask? {
  find_book_task_by_ids(tasks_for_model(model), ai_garden_book_ids())
}

///|
fn ai_garden_execution(model : Model) -> @core.TaskExecutionRecord? {
  find_priority_book_execution_by_ids(
    executions_for_model(model),
    ai_garden_book_ids(),
  )
}

///|
fn ai_garden_book_ids() -> Array[String] {
  ["wenyu-ai-garden", "ai-garden"]
}

///|
fn policy_hall_worker(model : Model) -> WorkerSim? {
  find_book_worker_by_ids(workers_for_model(model), policy_hall_book_ids())
}

///|
fn policy_hall_task(model : Model) -> @core.TownTask? {
  find_book_task_by_ids(tasks_for_model(model), policy_hall_book_ids())
}

///|
fn policy_hall_execution(model : Model) -> @core.TaskExecutionRecord? {
  find_priority_book_execution_by_ids(
    executions_for_model(model),
    policy_hall_book_ids(),
  )
}

///|
fn policy_hall_book_ids() -> Array[String] {
  ["wenyu-policy-hall", "policy-hall"]
}

///|
fn policy_hall_signal(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Checklist under review"
        @core.TaskExecutionStatus::ReviewQueued => "Escalated"
        @core.TaskExecutionStatus::Completed => "Checklist ready"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "Quest live"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Dispatching"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Needs recovery"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Projection bridge pending"
      } else {
        "Quest-ready"
      }
  }
}

///|
fn policy_hall_signal_class(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::ReviewQueued
        | @core.TaskExecutionStatus::Failed
        | @core.TaskExecutionStatus::Stale => "module-signal-alert"
        @core.TaskExecutionStatus::AwaitingPersistence => "module-signal-review"
        @core.TaskExecutionStatus::Completed
        | @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "module-signal-live"
        _ => "module-signal-book"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "module-signal-neutral"
      } else {
        "module-signal-book"
      }
  }
}

///|
fn policy_hall_module_copy(
  model : Model,
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  let queue_pressure = policy_hall_queue_pressure(model, worker)
  let quest_stage = policy_hall_quest_stage(model, execution)
  let worker_text = policy_hall_worker_label(worker)
  let confidence = policy_hall_confidence(model, execution)
  "Policy guidance stays inside the town loop: \{worker_text} is advancing the quest, queue pressure sits at \{queue_pressure}%, confidence is \{confidence}%, and the current resident-facing stage is \{quest_stage}."
}

///|
fn policy_hall_worker_label(worker : WorkerSim?) -> String {
  match worker {
    Some(worker) => "\{worker.title} / \{worker.status.to_string()}"
    None => "Policy Sprite / pending"
  }
}

///|
fn policy_hall_queue_pressure(model : Model, worker : WorkerSim?) -> Int {
  match worker {
    Some(worker) => worker.load
    None => model.pressure
  }
}

///|
fn policy_hall_health(
  worker : WorkerSim?,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  let base = match worker {
    Some(worker) => clamp_metric(worker.energy - worker.load / 3)
    None => 42
  }
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence => clamp_metric(base - 8)
        @core.TaskExecutionStatus::ReviewQueued => clamp_metric(base - 18)
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          clamp_metric(base - 28)
        @core.TaskExecutionStatus::Completed => clamp_metric(base + 12)
        _ => base
      }
    None => base
  }
}

///|
fn policy_hall_next_action(
  model : Model,
  task : @core.TownTask?,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Keep the checklist visible while MoonBook persists reviewed output."
        @core.TaskExecutionStatus::ReviewQueued =>
          "Escalate the low-confidence answer for keeper review before publishing."
        @core.TaskExecutionStatus::Completed =>
          "Hand the resident a reviewed checklist and packet summary."
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed =>
          "Finish the current clause walkthrough and prepare the checklist."
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Confirm dispatch and open the first policy quest step."
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recover the stalled run and replay the eligibility step."
      }
    None =>
      match task {
        Some(task) => task.prompt
        None =>
          if model.state_source == StateSourceKind::SnapshotFile {
            "Bridge the Policy Hall book projection so confidence, checklist readiness, and reviewed citations stop falling back to demo state."
          } else {
            resident_twins_resident_plan(model)
          }
      }
  }
}

///|
fn policy_hall_quest_stage(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Packet prepared"
        @core.TaskExecutionStatus::RunConfirmed
        | @core.TaskExecutionStatus::Running => "Advisor interpreting"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Checklist awaiting persistence"
        @core.TaskExecutionStatus::ReviewQueued => "Keeper review queued"
        @core.TaskExecutionStatus::Completed => "Checklist ready"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Projection bridge pending"
      } else if model.tick % 4 < 2 {
        "Advisor interpreting"
      } else {
        "Checklist ready"
      }
  }
}

///|
fn policy_hall_confidence(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> Int {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => 94
        @core.TaskExecutionStatus::AwaitingPersistence => 82
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => 74
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => 69
        @core.TaskExecutionStatus::ReviewQueued => 56
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          28
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        41
      } else {
        78
      }
  }
}

///|
fn policy_hall_checklist_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => "Ready for resident handoff"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Keeper persistence pending"
        @core.TaskExecutionStatus::ReviewQueued => "Escalated for review"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "Drafting checklist"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported => "Packet staged"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Recovery required"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Waiting for projection"
      } else {
        "Demo quest ready"
      }
  }
}

///|
fn policy_hall_evidence_label(
  model : Model,
  execution : @core.TaskExecutionRecord?,
) -> String {
  match execution {
    Some(execution) =>
      match execution.status {
        @core.TaskExecutionStatus::Completed => "Reviewed citations linked"
        @core.TaskExecutionStatus::AwaitingPersistence =>
          "Citations queued for persist"
        @core.TaskExecutionStatus::ReviewQueued => "Low-confidence review"
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::RunConfirmed => "Clause scan in flight"
        @core.TaskExecutionStatus::PacketReady
        | @core.TaskExecutionStatus::ProposalImported =>
          "Evidence packet staged"
        @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
          "Evidence needs recovery"
      }
    None =>
      if model.state_source == StateSourceKind::SnapshotFile {
        "Snapshot not wired yet"
      } else {
        "Demo citations assumed"
      }
  }
}

///|
fn resident_sims(model : Model) -> Array[ResidentSim] {
  [
    {
      name: "Li / Edge AI OPC",
      venture: "Low-power vision module studio",
      need: "Needs rental subsidy eligibility and contest prep.",
      mood: if model.pressure > 70 {
        "Focused"
      } else {
        "Curious"
      },
      agent_goal: "Ask Policy Sprite for subsidy checklist, then book a mock roadshow.",
      memory: "Remembered a past concern about compute vouchers and prototype demo timing.",
      reflection: "Confidence rises when policy advice turns into a concrete checklist and rehearsal slot.",
      plan: "09:00 policy quest, 14:00 cafe intro, 18:00 reflection note.",
      recent_action: "Policy Sprite drafted a subsidy checklist and queued a mock roadshow packet.",
      privacy_scope: "Operator summary",
      zone: "Policy Hall",
    },
    {
      name: "Chen / Design Automation OPC",
      venture: "AI UI prototyping service",
      need: "Looking for hardware founders who need interface design.",
      mood: "Open to weak-tie match",
      agent_goal: "Meet one robotics or edge-AI neighbor in Social Square.",
      memory: "Prefers low-pressure cafe intros before business collaboration.",
      reflection: "Warm introductions outperform cold outreach when social pressure stays low and goals are specific.",
      plan: "Browse Talent Avenue, accept cafe match, save follow-up memory.",
      recent_action: "Cafe Matchmaker proposed a founder intro with a shared demo-day preparation angle.",
      privacy_scope: "Shared town",
      zone: "Social Square",
    },
    {
      name: "Ma / Policy Ops Visitor",
      venture: "District operator evaluating settlement conversion.",
      need: "Needs tour-ready talent graph and daily vitality summary.",
      mood: "Observing",
      agent_goal: "Generate VIP reception route and verify achievement broadcasts.",
      memory: "Asked yesterday for warm-community evidence instead of raw traffic.",
      reflection: "Operator trust improves when the town shows story-rich resident progress instead of abstract metrics alone.",
      plan: "Review talent heatmap, export visit notes, flag missing service gaps.",
      recent_action: "Talent Avenue projected a tour summary while keeping resident-private notes out of the route brief.",
      privacy_scope: "Public-safe",
      zone: "Talent Avenue",
    },
  ]
}

///|
fn render_resident_card(resident : ResidentSim) -> @rabbita.Html {
  article(class="resident-card", [
    div(class="resident-head", [
      span(class="resident-avatar", resident_initials(resident.name)),
      div(class="resident-title", [h3(resident.name), p(resident.zone)]),
    ]),
    p(resident.venture),
    div(class="resident-chip-row", [
      span(class="resident-chip resident-chip-privacy", resident.privacy_scope),
      span(class="resident-chip resident-chip-action", "Recent action"),
    ]),
    p("Need: \{resident.need}"),
    p("Mood: \{resident.mood}"),
    p("Agent goal: \{resident.agent_goal}"),
    div(class="memory-strip", [span("Memory"), p(resident.memory)]),
    div(class="memory-strip", [span("Reflection"), p(resident.reflection)]),
    div(class="memory-strip", [span("Plan"), p(resident.plan)]),
    div(class="memory-strip", [
      span("Latest handoff"),
      p(resident.recent_action),
    ]),
  ])
}

///|
fn resident_initials(name : String) -> String {
  match name {
    "Li / Edge AI OPC" => "LI"
    "Chen / Design Automation OPC" => "CH"
    "Ma / Policy Ops Visitor" => "MA"
    _ => "AI"
  }
}

///|
fn render_resident_agents(model : Model) -> @rabbita.Html {
  section(class="resident-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Resident Agents"),
      h2("Digital twins with memory, reflection, and plans"),
      p(
        class="summary",
        "Each resident now has visible need state, remembered context, reflection, privacy scope, and a next plan. This is the UI contract for real Memory Stream + Reflection + Planning integration.",
      ),
    ]),
    div(class="resident-summary-grid", [
      runtime_stat_chip(
        "Visible twins",
        resident_count(model),
        "runtime-running",
      ),
      runtime_stat_chip(
        "Private scopes",
        resident_private_scope_count(model),
        "runtime-review",
      ),
      runtime_stat_chip(
        "Review queued",
        resident_review_queue_count(model),
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Projection mode",
        if model.state_source == StateSourceKind::SnapshotFile {
          1
        } else {
          0
        },
        "runtime-imported",
      ),
    ]),
    div(class="contract-list resident-contract-list", [
      p(
        "Resident memory stays durable in MoonBook; Moontown renders only projection-safe summaries and counters.",
      ),
      p(
        "Projection scope in this slice: public-safe, shared town, and operator summary.",
      ),
      p(
        "Recent actions show MoonClaw handoff results, not direct durable memory writes.",
      ),
    ]),
    div(
      class="resident-grid",
      resident_sims(model).map(resident => render_resident_card(resident)),
    ),
  ])
}

///|
fn resident_private_scope_count(model : Model) -> Int {
  let mut count = 0
  for resident in resident_sims(model) {
    if resident.privacy_scope == "Operator summary" {
      count += 1
    }
  }
  count
}

///|
fn resident_review_queue_count(model : Model) -> Int {
  let mut count = 0
  for execution in executions_for_model(model) {
    if execution.status == @core.TaskExecutionStatus::AwaitingPersistence ||
      execution.status == @core.TaskExecutionStatus::ReviewQueued {
      count += 1
    }
  }
  count
}

///|
fn resident_twins_resident_plan(model : Model) -> String {
  match resident_sims(model).get(model.tick % resident_sims(model).length()) {
    Some(resident) => resident.plan
    None => "Await first resident projection."
  }
}

///|
fn civic_quests(model : Model) -> Array[CivicQuestSim] {
  let policy_execution = policy_hall_execution(model)
  let policy_task = policy_hall_task(model)
  let ai_garden_task = ai_garden_task(model)
  let ai_garden_execution = ai_garden_execution(model)
  [
    {
      title: "Rental subsidy walkthrough",
      area: "Policy Hall",
      stage: policy_hall_quest_stage(model, policy_execution),
      reward: "80 Valley XP + application packet",
      status: policy_hall_signal(model, policy_execution),
      status_class: policy_hall_signal_class(model, policy_execution),
      detail: "Confidence \{policy_hall_confidence(model, policy_execution)}% · \{policy_hall_checklist_label(model, policy_execution)} · \{policy_hall_evidence_label(model, policy_execution)}",
      next_action: policy_hall_next_action(model, policy_task, policy_execution),
    },
    {
      title: "OPC roadshow preparation",
      area: "Contest Express",
      stage: if model.tick % 5 < 3 {
        "Mock judge scoring"
      } else {
        "Deck gap review"
      },
      reward: "Priority roadshow slot",
      status_class: "module-signal-book",
      status: "Nurturing",
      detail: "Checklist shaping in contest workspace with reviewable deck gaps.",
      next_action: "Keep the next mock judge round and reminder schedule visible.",
    },
    {
      title: "Cafe collaboration intro",
      area: "Social Square",
      stage: "Agent-mediated weak-tie match",
      reward: "Trial collaboration room",
      status_class: "module-signal-live",
      status: "Matching",
      detail: "Reasoned introduction stays lightweight until both sides accept.",
      next_action: "Project the latest follow-up into the resident-safe summary.",
    },
    {
      title: "Resident AI adoption sprint",
      area: "AI Garden",
      stage: ai_garden_stage(model, ai_garden_execution),
      reward: "Scenario template + before/after proof",
      status: ai_garden_signal(model, ai_garden_execution),
      status_class: ai_garden_signal_class(model, ai_garden_execution),
      detail: "Scenario lanes \{ai_garden_scenario_count(model)} · \{ai_garden_tool_trial_label(model, ai_garden_execution)} · \{ai_garden_comparison_label(model, ai_garden_execution)}",
      next_action: ai_garden_next_action(
        model, ai_garden_task, ai_garden_execution,
      ),
    },
    {
      title: "Physical bridge sync",
      area: "Physical Bridge",
      stage: if model.tick % 3 == 0 {
        "Robot confirmation"
      } else {
        "Room and telemetry sync"
      },
      reward: "Room hold + district signal",
      status_class: "module-signal-live",
      status: "Bridge live",
      detail: "Venue, robot, and telemetry handoffs stay visible in town view.",
      next_action: "Confirm the next offline sync before the district route changes.",
    },
  ]
}

///|
fn render_quest_card(quest : CivicQuestSim) -> @rabbita.Html {
  article(class="quest-card", [
    p(class="scene-node-key", quest.area),
    h3(quest.title),
    p("Stage: \{quest.stage}"),
    p("Reward: \{quest.reward}"),
    p(class="quest-detail", quest.detail),
    p(class="quest-next", "Next: \{quest.next_action}"),
    span(class="module-signal \{quest.status_class}", quest.status),
  ])
}

///|
fn render_civic_quests(model : Model) -> @rabbita.Html {
  section(class="quest-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Civic Quests"),
      h2("Policy, contest, social, and offline workflows as playable services"),
      p(
        class="summary",
        "This replaces static service text with quest-shaped state that agents can advance and the mayor can supervise.",
      ),
    ]),
    div(
      class="quest-grid",
      civic_quests(model).map(quest => render_quest_card(quest)),
    ),
  ])
}

///|
fn social_matches() -> Array[SocialMatchSim] {
  [
    {
      left: "Li / Edge AI OPC",
      right: "Chen / Design Automation OPC",
      reason: "Hardware prototype needs investor-facing UI and demo storytelling.",
      next_step: "Cafe intro at 15:30, then shared roadshow checklist.",
      confidence: 87,
    },
    {
      left: "AI Garden Tutor",
      right: "Policy Sprite",
      reason: "Daily AI tip can explain subsidy form filling with a practical demo.",
      next_step: "Publish tutorial quest after policy source review.",
      confidence: 79,
    },
  ]
}

///|
fn talent_signals(model : Model) -> Array[TalentSignalSim] {
  [
    {
      name: "Edge AI Studio",
      domain: "Robotics / edge vision",
      project: "Low-power orchard camera pilot",
      skills: "TinyML, camera modules, deployment",
      recent_achievement: "Verified a low-power orchard sensor demo for the district tour route.",
      evidence_status: "Verified evidence",
      reception_note: "Start the VIP route here to show shipping hardware and calm operator notes.",
      activity: clamp_metric(72 + model.tick % 16),
    },
    {
      name: "Design Automation Lab",
      domain: "AI design services",
      project: "Prompt-to-prototype studio sprint",
      skills: "UI generation, design systems, rapid prototypes",
      recent_achievement: "Published a reusable service blueprint for founder-facing UI demos.",
      evidence_status: "Review queued",
      reception_note: "Use as the second stop when the tour needs a fast software contrast.",
      activity: clamp_metric(66 + model.tick % 19),
    },
    {
      name: "Policy Ops Desk",
      domain: "District services",
      project: "Founder reception routing pilot",
      skills: "policy synthesis, reception routes, event ops",
      recent_achievement: "Turned yesterday's visitor questions into a public-safe route brief.",
      evidence_status: "Projection-safe summary",
      reception_note: "Close the route with this card to connect public talent signals to operator workflow.",
      activity: clamp_metric(58 + model.tick % 23),
    },
  ]
}

///|
fn render_match_card(match_item : SocialMatchSim) -> @rabbita.Html {
  article(class="match-card", [
    h3("\{match_item.left} x \{match_item.right}"),
    p(match_item.reason),
    p("Next: \{match_item.next_step}"),
    span(class="module-signal", "Confidence \{match_item.confidence}%"),
  ])
}

///|
fn render_talent_card(signal : TalentSignalSim) -> @rabbita.Html {
  let fill_style = ["width: \{signal.activity}%"]
  article(class="talent-card", [
    div(class="talent-card-head", [
      h3(signal.name),
      span(class="module-signal talent-card-signal", signal.evidence_status),
    ]),
    p(signal.domain),
    p("Project: \{signal.project}"),
    p("Skills: \{signal.skills}"),
    div(class="memory-strip talent-card-strip", [
      span("Recent win"),
      p(signal.recent_achievement),
    ]),
    div(class="memory-strip talent-card-strip", [
      span("Reception note"),
      p(signal.reception_note),
    ]),
    div(class="metric-track", [
      div(class="metric-fill tone-energy", style=fill_style, no_children()),
    ]),
    p("Activity brightness: \{signal.activity}%"),
  ])
}

///|
fn talent_route_stops(model : Model) -> Array[TalentRouteStopSim] {
  match talent_signals(model) {
    [hardware, software, operator, ..] =>
      [
        {
          order: 1,
          stop_title: "Arrival proof stop",
          signal_name: hardware.name,
          talking_point: "Open with a shipping artifact so visitors see real district output before hearing abstractions.",
          operator_note: hardware.reception_note,
          evidence_status: hardware.evidence_status,
          readiness: clamp_metric(hardware.activity + 10),
        },
        {
          order: 2,
          stop_title: "Software contrast stop",
          signal_name: software.name,
          talking_point: "Shift into rapid-service delivery to show that Wenyu talent spans more than one founder archetype.",
          operator_note: software.reception_note,
          evidence_status: software.evidence_status,
          readiness: clamp_metric(software.activity + 6),
        },
        {
          order: 3,
          stop_title: "Operator close-out",
          signal_name: operator.name,
          talking_point: "End on the district workflow layer so the route lands on matching, planning, and next-action evidence.",
          operator_note: operator.reception_note,
          evidence_status: operator.evidence_status,
          readiness: clamp_metric(operator.activity + 4),
        },
      ]
    _ => []
  }
}

///|
fn render_route_stop_card(stop : TalentRouteStopSim) -> @rabbita.Html {
  let fill_style = ["width: \{stop.readiness}%"]
  article(class="route-stop-card", [
    div(class="route-stop-head", [
      span(class="route-stop-order", stop.order.to_string()),
      div(class="route-stop-title", [h3(stop.stop_title), p(stop.signal_name)]),
      span(class="module-signal talent-card-signal", stop.evidence_status),
    ]),
    p(stop.talking_point),
    div(class="memory-strip route-stop-strip", [
      span("Operator note"),
      p(stop.operator_note),
    ]),
    div(class="metric-track", [
      div(class="metric-fill tone-energy", style=fill_style, no_children()),
    ]),
    p("Route readiness: \{stop.readiness}%"),
  ])
}

///|
fn render_social_talent(model : Model) -> @rabbita.Html {
  let route_stops = talent_route_stops(model)
  section(class="social-talent-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "Social Capital"),
      h2("Weak ties, talent graph, and reception-ready evidence"),
      p(
        class="summary",
        "The town should prove community warmth through visible matches, skill density, and operator-friendly talent projections.",
      ),
    ]),
    div(class="social-talent-grid", [
      div(class="subpanel", [
        h3("Agent Matches"),
        div(
          class="feed-list",
          social_matches().map(item => render_match_card(item)),
        ),
      ]),
      div(class="subpanel", [
        h3("Talent Star Avenue"),
        div(
          class="feed-list",
          talent_signals(model).map(signal => render_talent_card(signal)),
        ),
      ]),
      div(class="subpanel", [
        h3("Reception Route"),
        p(
          "Guide visitors through a proof-first route, keep operator notes projection-safe, and close with a clear next action.",
        ),
        div(
          class="route-stop-list",
          route_stops.map(stop => render_route_stop_card(stop)),
        ),
      ]),
    ]),
  ])
}

///|
fn render_bridge_contract(model : Model) -> @rabbita.Html {
  section(class="bridge-panel", [
    div(class="runtime-copy", [
      p(class="eyebrow", "24/7 Runtime Contract"),
      h2("From playable prototype to durable daemon town"),
      p(
        class="summary",
        "The UI now exposes the state objects the backend must keep alive: residents, memories, quests, matches, workers, health, and physical bridge events.",
      ),
    ]),
    div(class="bridge-grid", [
      runtime_stat_chip(
        "Daemon tick",
        daemon_tick_count(model),
        "runtime-running",
      ),
      runtime_stat_chip("Residents", resident_count(model), "runtime-packets"),
      runtime_stat_chip(
        "Memory streams",
        resident_sims(model).length(),
        "runtime-imported",
      ),
      runtime_stat_chip(
        "Open quests",
        civic_quests(model).length(),
        "runtime-persisting",
      ),
      runtime_stat_chip(
        "Robot calls",
        robot_service_count(model),
        "runtime-review",
      ),
    ]),
    div(class="contract-list", [
      p(
        "Persisted town state: `.moontown/town.json` should publish the same objects shown here.",
      ),
      p(
        "MoonBook state: each civic module owns durable wiki/memory pages for its domain.",
      ),
      p(
        "MoonClaw state: worker runs emit result packets and memory candidates, never raw global memory writes.",
      ),
      p(
        "Browser bridge: Rabbita should consume a generated `town-runtime.json` or local endpoint instead of synthetic state.",
      ),
    ]),
  ])
}

///|
fn execution_stage_cards(
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  [
    runtime_stat_chip(
      "Packets",
      count_execution_status(executions, @core.TaskExecutionStatus::PacketReady),
      "runtime-packets",
    ),
    runtime_stat_chip(
      "Imported",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::ProposalImported,
      ),
      "runtime-imported",
    ),
    runtime_stat_chip(
      "Running",
      count_execution_status(executions, @core.TaskExecutionStatus::Running) +
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::RunConfirmed,
      ),
      "runtime-running",
    ),
    runtime_stat_chip(
      "Persisting",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::AwaitingPersistence,
      ),
      "runtime-persisting",
    ),
    runtime_stat_chip(
      "Review",
      count_execution_status(
        executions,
        @core.TaskExecutionStatus::ReviewQueued,
      ),
      "runtime-review",
    ),
    runtime_stat_chip(
      "Done",
      count_execution_status(executions, @core.TaskExecutionStatus::Completed),
      "runtime-completed",
    ),
  ]
}

///|
fn render_strategy_button(
  dispatch : Dispatch[Msg],
  current : Strategy,
  strategy : Strategy,
) -> @rabbita.Html {
  let active = current == strategy
  let active_suffix = if active { " active" } else { "" }
  let class_name = "strategy-button" + active_suffix
  button(
    class=class_name,
    on_click=dispatch(SetStrategy(strategy)),
    strategy_label(strategy),
  )
}

///|
fn render_controls(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let status = if model.state_source == StateSourceKind::SnapshotFile {
    if projection_snapshot_is_ready(model.projection_snapshot) {
      if model.paused {
        "Bridge paused"
      } else {
        "Bridge ready"
      }
    } else {
      "Bridge waiting"
    }
  } else if model.paused {
    "Paused"
  } else {
    "Live"
  }
  let action_label = if model.paused { "Resume" } else { "Pause" }
  section(class="control-hub", [
    div(class="control-strip", [
      status_chip(status, if model.paused { "chip-alert" } else { "chip-live" }),
      status_chip("Local time \{real_time_label()}", "chip-clock"),
      status_chip(daemon_tick_label(model), "chip-neutral"),
      status_chip(daemon_heartbeat_label(model), "chip-neutral"),
      status_chip("Mode: \{strategy_label(model.strategy)}", "chip-book"),
      status_chip(
        "State sources: \{state_source_options().length()}",
        "chip-neutral",
      ),
      button(
        class="control-button",
        on_click=dispatch(ToggleStateSource),
        "Switch Source",
      ),
      button(
        class="control-button",
        on_click=dispatch(TogglePause),
        action_label,
      ),
      button(class="control-button", on_click=dispatch(Step), "Step"),
    ]),
    div(class="strategy-strip", [
      render_strategy_button(dispatch, model.strategy, Strategy::Balanced),
      render_strategy_button(dispatch, model.strategy, Strategy::Throughput),
      render_strategy_button(dispatch, model.strategy, Strategy::Recovery),
      button(
        class="action-button",
        on_click=dispatch(InjectBudget),
        "Inject Budget",
      ),
      button(
        class="action-button",
        on_click=dispatch(RelieveQueue),
        "Relieve Queue",
      ),
      button(
        class="action-button",
        on_click=dispatch(StabilityDrill),
        "Stability Drill",
      ),
    ]),
  ])
}

///|
fn render_node(
  dispatch : Dispatch[Msg],
  node : @ui.SceneRenderNode,
  selected : Bool,
) -> @rabbita.Html {
  let style = [
    "left: \{scene_node_left(node)}px",
    "top: \{scene_node_top(node)}px",
    "width: \{scene_node_width(node)}px",
    "height: \{scene_node_height(node)}px",
  ]
  let selected_suffix = if selected { " selected" } else { "" }
  let class_name = "scene-card-button" + selected_suffix
  article(class="scene-node \{node.class_name}", style~, [
    div(
      class="asset-stack",
      node.asset_paths.map(path => render_asset(path, node.title)),
    ),
    button(class=class_name, on_click=dispatch(SelectNode(node.key)), [
      h3(node.title),
      p(class="scene-node-key", node.key),
      div(class="scene-lines", node.lines.map(line => p(line))),
    ]),
  ])
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn min_int(left : Int, right : Int) -> Int {
  if left < right { left } else { right }
}

///|
fn max_int(left : Int, right : Int) -> Int {
  if left > right { left } else { right }
}

///|
fn in_rect(
  grid_x : Int,
  grid_y : Int,
  min_x : Int,
  min_y : Int,
  max_x : Int,
  max_y : Int,
) -> Bool {
  grid_x >= min_x && grid_x <= max_x && grid_y >= min_y && grid_y <= max_y
}

///|
fn in_ellipse(
  grid_x : Int,
  grid_y : Int,
  center_x : Int,
  center_y : Int,
  radius_x : Int,
  radius_y : Int,
) -> Bool {
  let dx = grid_x - center_x
  let dy = grid_y - center_y
  dx * dx * radius_y * radius_y + dy * dy * radius_x * radius_x <=
  radius_x * radius_x * radius_y * radius_y
}

///|
fn reference_node_grid_x(key : String) -> Int {
  match key {
    "city-hall" => 61
    "worker-yard" => 72
    "book-wenyu-town-shell" => 49
    "book-wenyu-resident-twins" => 25
    "book-wenyu-policy-hall" => 56
    "book-wenyu-contest-express" => 66
    "book-wenyu-social-square" => 51
    "book-wenyu-talent-avenue" => 78
    "book-wenyu-vitality-dashboard" => 103
    "book-wenyu-ai-garden" => 23
    "book-wenyu-physical-bridge" => 91
    "anomaly-corner" => 116
    "gate" => 18
    _ => 58
  }
}

///|
fn reference_node_grid_y(key : String) -> Int {
  match key {
    "city-hall" => 32
    "worker-yard" => 50
    "book-wenyu-town-shell" => 24
    "book-wenyu-resident-twins" => 47
    "book-wenyu-policy-hall" => 17
    "book-wenyu-contest-express" => 57
    "book-wenyu-social-square" => 43
    "book-wenyu-talent-avenue" => 54
    "book-wenyu-vitality-dashboard" => 42
    "book-wenyu-ai-garden" => 13
    "book-wenyu-physical-bridge" => 37
    "anomaly-corner" => 25
    "gate" => 60
    _ => 36
  }
}

///|
fn scene_node_width(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.width
  }
  match node.key {
    "city-hall" => 220
    "worker-yard" => 240
    "gate" => 140
    "anomaly-corner" => 150
    _ => 170
  }
}

///|
fn scene_node_height(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.height
  }
  match node.key {
    "worker-yard" => 100
    "gate" => 58
    _ => 128
  }
}

///|
fn scene_node_left(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.x
  }
  iso_tile_left(
    reference_node_grid_x(node.key),
    reference_node_grid_y(node.key),
  ) -
  scene_node_width(node) / 2 +
  22
}

///|
fn scene_node_top(node : @ui.SceneRenderNode) -> Int {
  if !standalone_viewport_requested() {
    return node.y
  }
  iso_tile_top(reference_node_grid_x(node.key), reference_node_grid_y(node.key)) -
  scene_node_height(node) +
  42
}

///|
fn tile_asset_for_kind(kind : String) -> String {
  match kind {
    "grass-light" => "tilemap/tiles/grass_light.png"
    "grass-dark" => "tilemap/tiles/grass_dark.png"
    "grass-flower-pink" => "tilemap/tiles/grass_flower_pink.png"
    "grass-flower-yellow" => "tilemap/tiles/grass_flower_yellow.png"
    "river" => "tilemap/tiles/river_straight.png"
    "lake" => "tilemap/tiles/river_straight.png"
    "pond" => "tilemap/tiles/river_straight.png"
    "river-bank" => "tilemap/tiles/river_bank.png"
    "wetland" => "tilemap/tiles/river_bank.png"
    "dirt-path" => "tilemap/tiles/dirt_path.png"
    "road" => "tilemap/tiles/dirt_path.png"
    "road-major" => "tilemap/tiles/dirt_path.png"
    "farm" => "tilemap/tiles/grass_flower_yellow.png"
    "field" => "tilemap/tiles/grass_light.png"
    "forest" => "tilemap/tiles/grass_dark.png"
    "urban" => "tilemap/tiles/plaza_stone.png"
    "urban-dense" => "tilemap/tiles/plaza_stone.png"
    "campus" => "tilemap/tiles/plaza_stone.png"
    "plaza-stone" => "tilemap/tiles/plaza_stone.png"
    "bridge" => "tilemap/tiles/wood_bridge.png"
    _ => "tilemap/tiles/grass_plain.png"
  }
}

///|
fn tilemap_grid_width() -> Int {
  256
}

///|
fn tilemap_grid_height() -> Int {
  144
}

///|
fn tilemap_step_x() -> Int {
  18
}

///|
fn tilemap_step_y() -> Int {
  9
}

///|
fn tilemap_origin_x() -> Int {
  1180
}

///|
fn tilemap_origin_y() -> Int {
  18
}

///|
fn tilemap_scene_width() -> Int {
  tilemap_origin_x() + (tilemap_grid_width() - 1) * tilemap_step_x() + 144
}

///|
fn tilemap_scene_height() -> Int {
  tilemap_origin_y() +
  (tilemap_grid_width() + tilemap_grid_height() - 2) * tilemap_step_y() +
  120
}

///|
fn river_center_x_at(grid_y : Int) -> Int {
  74 + grid_y / 3 + (if grid_y % 18 < 9 { -2 } else { 2 })
}

///|
fn reference_river_at(grid_x : Int, grid_y : Int) -> Bool {
  let center = river_center_x_at(grid_y)
  (grid_y >= 7 && abs_int(grid_x - center) <= (if grid_y > 50 { 4 } else { 2 })) ||
  (
    grid_y >= 2 &&
    grid_y <= 13 &&
    abs_int(grid_x - (8 + grid_y * 2 + grid_y / 3)) <= 1
  ) ||
  (
    grid_y >= 38 &&
    grid_y <= 50 &&
    abs_int(grid_x - (43 + (grid_y - 38) * 3)) <= 2
  ) ||
  (grid_y >= 49 && grid_x >= 108 && in_ellipse(grid_x, grid_y, 118, 56, 9, 12))
}

///|
fn reference_lake_at(grid_x : Int, grid_y : Int) -> Bool {
  in_ellipse(grid_x, grid_y, 44, 42, 8, 5) ||
  in_ellipse(grid_x, grid_y, 52, 44, 6, 4) ||
  in_ellipse(grid_x, grid_y, 80, 38, 6, 4) ||
  in_ellipse(grid_x, grid_y, 13, 8, 5, 3) ||
  in_ellipse(grid_x, grid_y, 27, 8, 4, 2) ||
  in_ellipse(grid_x, grid_y, 75, 8, 7, 3)
}

///|
fn reference_water_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_river_at(grid_x, grid_y) || reference_lake_at(grid_x, grid_y)
}

///|
fn reference_bridge_at(grid_x : Int, grid_y : Int) -> Bool {
  (
    grid_y >= 33 &&
    grid_y <= 36 &&
    abs_int(grid_x - river_center_x_at(grid_y)) <= 3
  ) ||
  (
    grid_y >= 54 &&
    grid_y <= 56 &&
    abs_int(grid_x - river_center_x_at(grid_y)) <= 4
  ) ||
  (grid_x >= 57 && grid_x <= 62 && grid_y >= 42 && grid_y <= 44) ||
  (grid_x >= 88 && grid_x <= 94 && grid_y >= 39 && grid_y <= 41) ||
  (grid_x >= 18 && grid_x <= 23 && grid_y >= 8 && grid_y <= 10)
}

///|
fn reference_wetland_at(grid_x : Int, grid_y : Int) -> Bool {
  let river_center = river_center_x_at(grid_y)
  (grid_y >= 7 && abs_int(grid_x - river_center) <= 5) ||
  in_ellipse(grid_x, grid_y, 47, 43, 13, 8) ||
  in_ellipse(grid_x, grid_y, 80, 39, 11, 7) ||
  in_ellipse(grid_x, grid_y, 20, 8, 12, 5) ||
  (
    grid_y >= 36 &&
    grid_y <= 52 &&
    abs_int(grid_x - (43 + (grid_y - 38) * 3)) <= 4
  )
}

///|
fn reference_major_road_at(grid_x : Int, grid_y : Int) -> Bool {
  abs_int(grid_y * 3 + grid_x * 2 - 142) <= 2 ||
  abs_int(grid_y * 2 - grid_x + 24) <= 1 ||
  (abs_int(grid_y - 35) <= 1 && grid_x < 100) ||
  (abs_int(grid_y - 55) <= 1 && grid_x > 20 && grid_x < 112) ||
  (abs_int(grid_x - 62) <= 1 && grid_y > 10 && grid_y < 58) ||
  (abs_int(grid_x - 94) <= 1 && grid_y > 20)
}

///|
fn reference_local_road_at(grid_x : Int, grid_y : Int) -> Bool {
  (
    in_rect(grid_x, grid_y, 7, 18, 38, 34) &&
    (grid_x % 7 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 31, 15, 69, 36) &&
    (grid_x % 6 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 14, 39, 43, 57) &&
    (grid_x % 5 == 0 || grid_y % 4 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 48, 49, 86, 63) &&
    (grid_x % 6 == 0 || grid_y % 4 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 92, 33, 118, 51) &&
    (grid_x % 5 == 0 || grid_y % 5 == 0)
  ) ||
  (
    in_rect(grid_x, grid_y, 88, 54, 123, 63) &&
    (grid_x % 6 == 0 || grid_y % 4 == 0)
  )
}

///|
fn reference_road_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_major_road_at(grid_x, grid_y) ||
  reference_local_road_at(grid_x, grid_y)
}

///|
fn reference_dense_urban_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 35, 16, 69, 34) ||
  in_rect(grid_x, grid_y, 88, 54, 123, 63) ||
  in_rect(grid_x, grid_y, 95, 35, 116, 48)
}

///|
fn reference_urban_at(grid_x : Int, grid_y : Int) -> Bool {
  reference_dense_urban_at(grid_x, grid_y) ||
  in_rect(grid_x, grid_y, 13, 39, 43, 57) ||
  in_rect(grid_x, grid_y, 48, 49, 86, 63) ||
  in_rect(grid_x, grid_y, 7, 8, 30, 18) ||
  in_rect(grid_x, grid_y, 70, 34, 84, 50)
}

///|
fn reference_campus_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 52, 37, 65, 47) ||
  in_rect(grid_x, grid_y, 79, 51, 91, 61) ||
  in_rect(grid_x, grid_y, 102, 27, 121, 33)
}

///|
fn reference_farm_at(grid_x : Int, grid_y : Int) -> Bool {
  in_rect(grid_x, grid_y, 70, 18, 88, 33) ||
  in_rect(grid_x, grid_y, 6, 20, 36, 34) ||
  in_rect(grid_x, grid_y, 2, 49, 18, 63) ||
  in_rect(grid_x, grid_y, 105, 8, 127, 25)
}

///|
fn reference_forest_at(grid_x : Int, grid_y : Int) -> Bool {
  grid_y < 7 ||
  (grid_x < 7 && grid_y > 36) ||
  (grid_y > 58 && grid_x < 48) ||
  (grid_x > 96 && grid_y < 30) ||
  in_ellipse(grid_x, grid_y, 9, 50, 11, 10) ||
  in_ellipse(grid_x, grid_y, 92, 13, 13, 9)
}

///|
fn tile_kind_for_reference_code(code : String) -> String {
  match code {
    "." => "grass"
    "g" => "grass-light"
    "G" => "forest"
    "p" => "grass-flower-pink"
    "y" => "grass-flower-yellow"
    "f" => "farm"
    "F" => "field"
    "r" => "river"
    "l" => "lake"
    "w" => "wetland"
    "b" => "bridge"
    "M" => "road-major"
    "R" => "road"
    "u" => "urban"
    "U" => "urban-dense"
    "c" => "campus"
    _ => ""
  }
}

///|
fn reference_tile_kind_at(grid_x : Int, grid_y : Int) -> String? {
  let kind = tile_kind_for_reference_code(
    reference_tile_code_at(grid_x, grid_y),
  )
  if kind == "" {
    None
  } else {
    Some(kind)
  }
}

///|
fn tile_kind_at(grid_x : Int, grid_y : Int) -> String {
  match reference_tile_kind_at(grid_x, grid_y) {
    Some(kind) => kind
    None =>
      if reference_water_at(grid_x, grid_y) {
        if reference_bridge_at(grid_x, grid_y) {
          "bridge"
        } else if reference_lake_at(grid_x, grid_y) {
          "lake"
        } else {
          "river"
        }
      } else if reference_road_at(grid_x, grid_y) {
        if reference_major_road_at(grid_x, grid_y) {
          "road-major"
        } else {
          "road"
        }
      } else if reference_wetland_at(grid_x, grid_y) {
        "wetland"
      } else if reference_campus_at(grid_x, grid_y) {
        "campus"
      } else if reference_dense_urban_at(grid_x, grid_y) {
        "urban-dense"
      } else if reference_urban_at(grid_x, grid_y) {
        "urban"
      } else if reference_farm_at(grid_x, grid_y) {
        if (grid_x + grid_y) % 4 == 0 {
          "field"
        } else {
          "farm"
        }
      } else if reference_forest_at(grid_x, grid_y) {
        "forest"
      } else if (grid_x + grid_y) % 11 == 0 {
        "grass-flower-pink"
      } else if (grid_x * 3 + grid_y) % 13 == 0 {
        "grass-flower-yellow"
      } else if (grid_x + grid_y) % 4 == 0 {
        "grass-light"
      } else if (grid_x * 2 + grid_y) % 5 == 0 {
        "grass-dark"
      } else {
        "grass"
      }
  }
}

///|
fn iso_tile_left(grid_x : Int, grid_y : Int) -> Int {
  tilemap_origin_x() + (grid_x - grid_y) * tilemap_step_x() - 22
}

///|
fn iso_tile_top(grid_x : Int, grid_y : Int) -> Int {
  tilemap_origin_y() + (grid_x + grid_y) * tilemap_step_y()
}

///|
fn render_iso_tile(grid_x : Int, grid_y : Int) -> @rabbita.Html {
  let kind = tile_kind_at(grid_x, grid_y)
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y)}px",
    "top: \{iso_tile_top(grid_x, grid_y)}px",
    "--tile-image: url('\{tile_asset_for_kind(kind)}')",
  ]
  div(class="iso-tile iso-tile-\{kind}", style~, no_children())
}

///|
fn tile_object_asset(kind : String) -> String {
  match kind {
    "tree-large" => "tilemap/objects/tree_large.png"
    "tree-small" => "tilemap/objects/tree_small.png"
    "bush" => "tilemap/objects/bush.png"
    "flower-patch" => "tilemap/objects/flower_patch.png"
    "lamp" => "tilemap/objects/lamp.png"
    _ => "tilemap/objects/bush.png"
  }
}

///|
fn render_tile_object(
  grid_x : Int,
  grid_y : Int,
  kind : String,
) -> @rabbita.Html {
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y)}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 22}px",
    "--object-image: url('\{tile_object_asset(kind)}')",
  ]
  div(class="tile-object tile-object-\{kind}", style~, no_children())
}

///|
fn should_place_tile_object(grid_x : Int, grid_y : Int) -> Bool {
  let kind = tile_kind_at(grid_x, grid_y)
  if kind == "river" ||
    kind == "river-bank" ||
    kind == "bridge" ||
    kind == "lake" ||
    kind == "road" ||
    kind == "road-major" ||
    kind == "urban" ||
    kind == "urban-dense" ||
    kind == "campus" ||
    kind == "farm" ||
    kind == "field" ||
    kind == "plaza-stone" {
    return false
  }
  (kind == "forest" && (grid_x * 17 + grid_y * 31) % 19 == 0) ||
  (kind == "wetland" && (grid_x * 7 + grid_y * 19) % 31 == 0) ||
  (grid_x * 17 + grid_y * 31) % 71 == 0 ||
  (grid_x + grid_y * 5) % 97 == 0
}

///|
fn tile_object_kind_at(grid_x : Int, grid_y : Int) -> String {
  if (grid_x * 17 + grid_y * 31) % 47 == 0 {
    if (grid_x + grid_y) % 3 == 0 {
      "tree-large"
    } else {
      "tree-small"
    }
  } else if (grid_x * 7 + grid_y * 19) % 61 == 0 {
    "bush"
  } else {
    "flower-patch"
  }
}

///|
fn should_place_reference_building(grid_x : Int, grid_y : Int) -> Bool {
  let kind = tile_kind_at(grid_x, grid_y)
  if kind != "urban" && kind != "urban-dense" && kind != "campus" {
    return false
  }
  if reference_road_at(grid_x, grid_y) || reference_water_at(grid_x, grid_y) {
    return false
  }
  if kind == "urban-dense" {
    (grid_x * 5 + grid_y * 7) % 3 != 0
  } else if kind == "campus" {
    (grid_x + grid_y) % 3 == 0
  } else {
    (grid_x * 11 + grid_y * 13) % 5 != 0
  }
}

///|
fn reference_building_kind_at(grid_x : Int, grid_y : Int) -> String {
  let tile = tile_kind_at(grid_x, grid_y)
  if tile == "campus" {
    if (grid_x + grid_y) % 2 == 0 {
      "campus"
    } else {
      "civic"
    }
  } else if reference_dense_urban_at(grid_x, grid_y) {
    if (grid_x * 3 + grid_y) % 11 == 0 {
      "tower"
    } else if (grid_x + grid_y) % 2 == 0 {
      "row"
    } else {
      "block"
    }
  } else if (grid_x + grid_y) % 4 == 0 {
    "courtyard"
  } else {
    "lowrise"
  }
}

///|
fn render_reference_building(
  grid_x : Int,
  grid_y : Int,
  kind : String,
) -> @rabbita.Html {
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 11}px",
    "top: \{iso_tile_top(grid_x, grid_y) + 10}px",
  ]
  div(class="reference-building reference-building-\{kind}", style~, [
    span(class="reference-building-roof", no_children()),
  ])
}

///|
fn render_reference_haze(
  class_suffix : String,
  left : Int,
  top : Int,
  width : Int,
  height : Int,
) -> @rabbita.Html {
  let style = [
    "left: \{left}px",
    "top: \{top}px",
    "width: \{width}px",
    "height: \{height}px",
  ]
  div(
    class="reference-haze reference-haze-\{class_suffix}",
    style~,
    no_children(),
  )
}

///|
fn render_tilemap_raster_layer() -> @rabbita.Html {
  img(
    class="tilemap-raster-layer",
    src="tilemap/wenyu_reference_tilemap_iso.png",
    alt="Wenyu Valley rendered tilemap",
    loading="eager",
    no_children(),
  )
}

///|
fn render_tilemap_layer() -> @rabbita.Html {
  if standalone_viewport_requested() {
    return render_tilemap_raster_layer()
  }
  let children : Array[@rabbita.Html] = []
  for y in 0..<tilemap_grid_height() {
    for x in 0..<tilemap_grid_width() {
      children.push(render_iso_tile(x, y))
    }
  }
  for y in 0..<tilemap_grid_height() {
    for x in 0..<tilemap_grid_width() {
      if should_place_tile_object(x, y) {
        children.push(render_tile_object(x, y, tile_object_kind_at(x, y)))
      }
    }
  }
  children.push(render_tile_object(122, 78, "lamp"))
  children.push(render_tile_object(149, 94, "lamp"))
  children.push(render_tile_object(182, 84, "lamp"))
  children.push(render_reference_haze("north-west", 120, 40, 3600, 760))
  children.push(render_reference_haze("north-east", 8800, 20, 3200, 940))
  children.push(render_reference_haze("south-west", 0, 6500, 3600, 980))
  children.push(render_reference_haze("east", 10300, 3100, 2500, 1200))
  div(class="tilemap-layer", children)
}

///|
fn render_water_effect_layer() -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(
      class="water-effect-layer water-effect-layer-empty",
      no_children(),
    )
  }
  div(class="water-effect-layer", [
    div(class="water-depth water-depth-main-river", no_children()),
    div(class="water-depth water-depth-central-lake", no_children()),
    div(class="water-depth water-depth-south-lake", no_children()),
    div(class="water-reflection water-reflection-north", no_children()),
    div(class="water-reflection water-reflection-center", no_children()),
    div(class="water-reflection water-reflection-south", no_children()),
    div(class="bridge-shadow bridge-shadow-north", no_children()),
    div(class="bridge-shadow bridge-shadow-center", no_children()),
    div(class="bridge-shadow bridge-shadow-south", no_children()),
  ])
}

///|
fn module_road_hub_x() -> Int {
  128
}

///|
fn module_road_hub_y() -> Int {
  82
}

///|
fn module_road_tile(
  grid_x : Int,
  grid_y : Int,
  class_suffix : String,
) -> @rabbita.Html {
  let style = [
    "left: \{iso_tile_left(clamp_visual_grid_x(grid_x), clamp_visual_grid_y(grid_y))}px",
    "top: \{iso_tile_top(clamp_visual_grid_x(grid_x), clamp_visual_grid_y(grid_y))}px",
  ]
  span(class="module-road-tile module-road-\{class_suffix}", style~, no_children())
}

///|
fn render_module_road_for(civic : WenyuTownModule) -> Array[@rabbita.Html] {
  let tiles : Array[@rabbita.Html] = []
  let hub_x = module_road_hub_x()
  let hub_y = module_road_hub_y()
  let x_start = min_int(civic.entrance_x, hub_x)
  let x_end = max_int(civic.entrance_x, hub_x)
  let y_start = min_int(civic.entrance_y, hub_y)
  let y_end = max_int(civic.entrance_y, hub_y)
  for x in x_start..=x_end {
    if (x - x_start) % 2 == 0 {
      tiles.push(module_road_tile(x, civic.entrance_y, "local"))
    }
  }
  for y in y_start..=y_end {
    if (y - y_start) % 2 == 0 {
      tiles.push(module_road_tile(hub_x, y, "local"))
    }
  }
  tiles.push(module_road_tile(civic.entrance_x, civic.entrance_y, "entrance"))
  tiles
}

///|
fn render_wenyu_module_road_layer() -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(class="wenyu-road-layer wenyu-road-layer-empty", no_children())
  }
  let children : Array[@rabbita.Html] = [
    module_road_tile(module_road_hub_x(), module_road_hub_y(), "hub"),
  ]
  for civic in wenyu_modules() {
    for tile in render_module_road_for(civic) {
      children.push(tile)
    }
  }
  div(class="wenyu-road-layer", children)
}

///|
fn find_module_execution(
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> @core.TaskExecutionRecord? {
  let mut matched : @core.TaskExecutionRecord? = None
  for execution in executions {
    if module_book_matches(civic, execution.book_id) {
      matched = Some(execution)
    }
  }
  matched
}

///|
fn find_module_visual_building(
  model : Model,
  civic : WenyuTownModule,
) -> VisualBuildingSnapshot? {
  match model.visual_projection {
    Some(projection) => {
      for building in projection.buildings {
        if module_book_matches(civic, building.book_id) {
          return Some(building)
        }
      }
      None
    }
    None => None
  }
}

///|
fn find_module_visual_module(
  model : Model,
  civic : WenyuTownModule,
) -> VisualModuleSnapshot? {
  match model.visual_projection {
    Some(projection) =>
      match projection.modules {
        Some(modules) => {
          for module_status in modules {
            if module_status.module_id == civic.id ||
              module_book_matches(civic, module_status.book_id) {
              return Some(module_status)
            }
          }
          None
        }
        None => None
      }
    None => None
  }
}

///|
fn module_visual_agents(
  model : Model,
  civic : WenyuTownModule,
) -> Array[VisualAgentSnapshot] {
  match model.visual_projection {
    Some(projection) =>
      projection.agents.filter(agent => {
        module_book_matches(civic, agent.book_id)
      })
    None => []
  }
}

///|
fn module_active_visual_agents(
  model : Model,
  civic : WenyuTownModule,
) -> Array[VisualAgentSnapshot] {
  module_visual_agents(model, civic).filter(agent => {
    agent.visible_on_overworld ||
    agent.phase == "running" ||
    agent.phase == "persisting" ||
    agent.phase == "review" ||
    agent.phase == "failed" ||
    agent.phase == "stale" ||
    agent.phase == "blocked"
  })
}

///|
fn module_allows_water_or_bridge(civic : WenyuTownModule) -> Bool {
  civic.building_kind == "physical-bridge" ||
  civic.district.contains("river") ||
  civic.district.contains("harbor")
}

///|
fn module_anchor_tile_kind(civic : WenyuTownModule) -> String {
  tile_kind_at(civic.grid_x, civic.grid_y)
}

///|
fn module_entrance_tile_kind(civic : WenyuTownModule) -> String {
  tile_kind_at(civic.entrance_x, civic.entrance_y)
}

///|
fn module_tile_blocks_building(kind : String, civic : WenyuTownModule) -> Bool {
  if module_allows_water_or_bridge(civic) {
    false
  } else {
    kind == "river" ||
    kind == "lake" ||
    kind == "wetland" ||
    kind == "bridge" ||
    kind == "road" ||
    kind == "road-major"
  }
}

///|
fn module_tile_blocks_entrance(kind : String, civic : WenyuTownModule) -> Bool {
  if module_allows_water_or_bridge(civic) {
    false
  } else {
    kind == "river" || kind == "lake" || kind == "wetland"
  }
}

///|
fn module_corner_tile_blocks(civic : WenyuTownModule) -> Array[String] {
  let blocked : Array[String] = []
  let corners = [
    (civic.grid_x, civic.grid_y),
    (civic.grid_x + civic.footprint_w - 1, civic.grid_y),
    (civic.grid_x, civic.grid_y + civic.footprint_h - 1),
    (civic.grid_x + civic.footprint_w - 1, civic.grid_y + civic.footprint_h - 1),
  ]
  for corner in corners {
    let kind = tile_kind_at(corner.0, corner.1)
    if module_tile_blocks_building(kind, civic) {
      blocked.push("\{corner.0},\{corner.1} on \{kind}")
    }
  }
  blocked
}

///|
fn module_validation_issues(civic : WenyuTownModule) -> Array[String] {
  let issues : Array[String] = []
  if civic.book_id == "" {
    issues.push("missing book_id")
  }
  if civic.asset_base == "" {
    issues.push("missing asset_base")
  }
  if civic.footprint_w <= 0 || civic.footprint_h <= 0 {
    issues.push("invalid footprint")
  }
  if civic.display_w <= 0 || civic.display_h <= 0 {
    issues.push("invalid display size")
  }
  if civic.style_family == "" {
    issues.push("missing style_family")
  }
  if civic.protocol_pattern == "" {
    issues.push("missing protocol_pattern")
  }
  let anchor_kind = module_anchor_tile_kind(civic)
  if module_tile_blocks_building(anchor_kind, civic) {
    issues.push("anchor on \{anchor_kind}")
  }
  let corner_blocks = module_corner_tile_blocks(civic)
  if !corner_blocks.is_empty() {
    issues.push("footprint overlap \{corner_blocks.join("; ")}")
  }
  let entrance_kind = module_entrance_tile_kind(civic)
  if module_tile_blocks_entrance(entrance_kind, civic) {
    issues.push("entrance on \{entrance_kind}")
  }
  issues
}

///|
fn wenyu_clean_module_count() -> Int {
  let mut count = 0
  for civic in wenyu_modules() {
    if module_validation_issues(civic).is_empty() {
      count += 1
    }
  }
  count
}

///|
fn module_projection_status_class(
  module_status : VisualModuleSnapshot,
) -> String {
  match module_status.status {
    "alert" => "module-status-alert"
    "review" => "module-status-review"
    "running" => "module-status-running"
    "waiting" => "module-status-waiting"
    "complete" => "module-status-complete"
    "projected" => "module-status-projected"
    _ =>
      if module_status.blocked_count > 0 {
        "module-status-alert"
      } else if module_status.review_count > 0 {
        "module-status-review"
      } else if module_status.running_count > 0 {
        "module-status-running"
      } else if module_status.waiting_count > 0 {
        "module-status-waiting"
      } else if module_status.completed_count > 0 {
        "module-status-complete"
      } else {
        "module-status-projected"
      }
  }
}

///|
fn module_projection_status_label(
  module_status : VisualModuleSnapshot,
) -> String {
  match module_status.status {
    "alert" => "Recovery"
    "review" => "Review"
    "running" => "Running"
    "waiting" => "Waiting"
    "complete" => "Quiet"
    "projected" => "Projected"
    _ => "Projected"
  }
}

///|
fn module_projection_source_label(source : String) -> String {
  match source {
    "runtime" => "Module"
    "projection" => "Module"
    "execution" => "Execution"
    "" => "Module"
    _ => source
  }
}

///|
fn wenyu_module_runtime_state(
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> WenyuModuleRuntimeState {
  let issue_count = module_validation_issues(civic).length()
  let active_agents = module_active_visual_agents(model, civic)
  match find_module_visual_module(model, civic) {
    Some(module_status) =>
      {
        status_class: module_projection_status_class(module_status),
        status_label: module_projection_status_label(module_status),
        source_label: module_projection_source_label(module_status.source),
        detail: module_status.message,
        running_count: module_status.running_count,
        waiting_count: module_status.waiting_count,
        review_count: module_status.review_count,
        blocked_count: module_status.blocked_count,
        completed_count: module_status.completed_count,
        visible_agent_count: module_status.active_agent_count,
        issue_count,
      }
    None =>
      match find_module_visual_building(model, civic) {
        Some(building) => {
          let status_class = if building.blocked_count > 0 {
            "module-status-alert"
          } else if building.review_count > 0 {
            "module-status-review"
          } else if building.running_count > 0 {
            "module-status-running"
          } else if building.waiting_count > 0 {
            "module-status-waiting"
          } else if building.completed_count > 0 {
            "module-status-complete"
          } else {
            "module-status-projected"
          }
          let label = if building.blocked_count > 0 {
            "Recovery"
          } else if building.review_count > 0 {
            "Review"
          } else if building.running_count > 0 {
            "Running"
          } else if building.waiting_count > 0 {
            "Waiting"
          } else if building.completed_count > 0 {
            "Quiet"
          } else {
            "Projected"
          }
          {
            status_class,
            status_label: label,
            source_label: "Projection",
            detail: building.message,
            running_count: building.running_count,
            waiting_count: building.waiting_count,
            review_count: building.review_count,
            blocked_count: building.blocked_count,
            completed_count: building.completed_count,
            visible_agent_count: active_agents.length(),
            issue_count,
          }
        }
        None =>
          match find_module_execution(civic, executions) {
            Some(execution) => {
              let status_class = match execution.status {
                @core.TaskExecutionStatus::Running
                | @core.TaskExecutionStatus::RunConfirmed =>
                  "module-status-running"
                @core.TaskExecutionStatus::AwaitingPersistence
                | @core.TaskExecutionStatus::ReviewQueued =>
                  "module-status-review"
                @core.TaskExecutionStatus::Failed
                | @core.TaskExecutionStatus::Stale => "module-status-alert"
                @core.TaskExecutionStatus::Completed => "module-status-complete"
                _ => "module-status-waiting"
              }
              {
                status_class,
                status_label: execution.status.to_string(),
                source_label: "Execution",
                detail: execution.summary,
                running_count: if status_class == "module-status-running" {
                  1
                } else {
                  0
                },
                waiting_count: if status_class == "module-status-waiting" {
                  1
                } else {
                  0
                },
                review_count: if status_class == "module-status-review" {
                  1
                } else {
                  0
                },
                blocked_count: if status_class == "module-status-alert" {
                  1
                } else {
                  0
                },
                completed_count: if status_class == "module-status-complete" {
                  1
                } else {
                  0
                },
                visible_agent_count: active_agents.length(),
                issue_count,
              }
            }
            None =>
              match find_module_civic_health(model, civic) {
                Some(health) => {
                  let status_class = civic_health_status_class(health.status)
                  {
                    status_class,
                    status_label: civic_health_status_label(health.status),
                    source_label: "Civic Doctor",
                    detail: civic_health_detail(health),
                    running_count: 0,
                    waiting_count: if health.status == "seeded" { 1 } else { 0 },
                    review_count: health.latest_review_items,
                    blocked_count: if health.status == "blocked" ||
                      health.status == "missing-workspace" ||
                      health.status == "incomplete" ||
                      health.status == "misconfigured" {
                      1
                    } else {
                      0
                    },
                    completed_count: if health.proven_by_result { 1 } else { 0 },
                    visible_agent_count: active_agents.length(),
                    issue_count: issue_count + health.missing_required_paths.length(),
                  }
                }
                None =>
                  {
                    status_class: if issue_count > 0 {
                      "module-status-unbound"
                    } else {
                      "module-status-calm"
                    },
                    status_label: if issue_count > 0 {
                      "Needs config"
                    } else {
                      "Configured"
                    },
                    source_label: "Config",
                    detail: civic.summary,
                    running_count: 0,
                    waiting_count: 0,
                    review_count: 0,
                    blocked_count: 0,
                    completed_count: 0,
                    visible_agent_count: active_agents.length(),
                    issue_count,
                  }
              }
          }
      }
  }
}

///|
fn civic_health_status_class(status : String) -> String {
  match status {
    "changed" | "no-change" => "module-status-complete"
    "needs-review" => "module-status-review"
    "seeded" => "module-status-waiting"
    "blocked" | "missing-workspace" | "incomplete" | "misconfigured" =>
      "module-status-alert"
    _ => "module-status-projected"
  }
}

///|
fn civic_health_status_label(status : String) -> String {
  match status {
    "missing-workspace" => "Missing workspace"
    "needs-review" => "Needs review"
    "no-change" => "No change"
    "result-unknown" => "Result unknown"
    "misconfigured" => "Misconfigured"
    _ => status
  }
}

///|
fn civic_health_detail(health : CivicServiceHealthSnapshot) -> String {
  let notes = if health.notes.is_empty() {
    "no detailed notes"
  } else {
    health.notes.join("; ")
  }
  "Civic status: \{health.status}. Protocol: \{health.protocol_status}; mode: \{health.module_mode}; skill: \{health.skill_mode}; MoonBook role: \{health.book_role}. Decision: \{health.latest_decision}; pages changed: \{health.latest_pages_changed}; accepted facts: \{health.latest_accepted_facts}; review items: \{health.latest_review_items}. \{notes}"
}

///|
fn civic_status_summary(model : Model) -> String {
  match model.civic_status {
    Some(status) => {
      let mut protocol_review_count = 0
      for service in status.services {
        protocol_review_count += service.protocol_review_count
      }
      "\{status.operable_count}/\{status.total} operable, \{status.proven_count} proven, \{protocol_review_count} protocol review"
    }
    None => "not loaded"
  }
}

///|
fn render_wenyu_module_building(
  _dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
) -> @rabbita.Html {
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  let width = civic.display_w
  let height = civic.display_h
  let selected_suffix = if selected_node_key == Some(civic.id) {
    " selected"
  } else {
    ""
  }
  let issue_suffix = if runtime.issue_count > 0 { " has-issues" } else { "" }
  let style = [
    "left: \{iso_tile_left(civic.grid_x, civic.grid_y)}px",
    "top: \{iso_tile_top(civic.grid_x, civic.grid_y)}px",
    "z-index: \{260 + civic.grid_x + civic.grid_y}",
    "--module-width: \{width}px",
    "--module-height: \{height}px",
    "--module-footprint-w: \{civic.footprint_w}",
    "--module-footprint-h: \{civic.footprint_h}",
    "--module-image: url('\{civic.asset_base}')",
    "--module-roof-image: url('\{civic.asset_roof}')",
  ]
  let children : Array[@rabbita.Html] = [
    span(class="wenyu-module-footprint", no_children()),
    span(class="wenyu-module-shadow", no_children()),
    span(class="wenyu-module-sprite", no_children()),
    span(class="wenyu-module-light", no_children()),
  ]
  if runtime.visible_agent_count > 0 {
    children.push(
      span(class="wenyu-module-agent-count", "\{runtime.visible_agent_count}"),
    )
  }
  if runtime.issue_count > 0 {
    children.push(
      span(class="wenyu-module-issue-count", "\{runtime.issue_count}"),
    )
  }
  children.push(
    span(class="wenyu-module-label", [
      span(class="wenyu-module-title", civic.title),
      span(class="wenyu-module-district", civic.district),
      span(class="wenyu-module-state", runtime.status_label),
      span(class="wenyu-module-state-source", runtime.source_label),
    ]),
  )
  a(
    href="./viewport.html?assets=generated&mode=view&module=\{civic.id}&v=module-\{civic.id}",
    class="wenyu-module-building wenyu-module-\{civic.building_kind} style-\{civic.style_family} \{runtime.status_class}\{selected_suffix}\{issue_suffix}",
    style~,
    title="\{civic.title}: \{runtime.status_label}. \{runtime.detail}",
    children,
  )
}

///|
fn render_wenyu_module_building_layer(
  dispatch : Dispatch[Msg],
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
) -> @rabbita.Html {
  if !standalone_viewport_requested() {
    return div(
      class="wenyu-module-layer wenyu-module-layer-empty",
      no_children(),
    )
  }
  let children : Array[@rabbita.Html] = []
  for civic in wenyu_modules() {
    children.push(
      render_wenyu_module_building(
        dispatch, model, civic, executions, selected_node_key,
      ),
    )
  }
  div(class="wenyu-module-layer", children)
}

///|
fn module_workers(
  civic : WenyuTownModule,
  workers : Array[WorkerSim],
) -> Array[WorkerSim] {
  workers.filter(worker => module_book_matches(civic, worker.book_id))
}

///|
fn module_interior_furniture(civic : WenyuTownModule) -> Array[@rabbita.Html] {
  match civic.interior_kind {
    "mayor" =>
      [
        div(class="furniture furniture-map-table", [span("Runtime Map")]),
        div(class="furniture furniture-radio", [span("Mayor Radio")]),
        div(class="furniture furniture-policy-board", [span("Patrol Board")]),
        div(class="furniture furniture-archive", [span("Town Ledger")]),
      ]
    "policy" =>
      [
        div(class="furniture furniture-policy-board", [span("Policy Wall")]),
        div(class="furniture furniture-desk", [span("Eligibility Desk")]),
        div(class="furniture furniture-archive", [span("Source Shelf")]),
        div(class="furniture furniture-review-table", [span("Checklist Table")]),
      ]
    "contest" =>
      [
        div(class="furniture furniture-stage", [span("Mock Stage")]),
        div(class="furniture furniture-scoreboard", [span("Judge Board")]),
        div(class="furniture furniture-desk", [span("Deck Clinic")]),
        div(class="furniture furniture-log-wall", [span("Countdown Wall")]),
      ]
    "social" =>
      [
        div(class="furniture furniture-cafe-table", [span("Cafe Table")]),
        div(class="furniture furniture-signal-post", [span("Match Board")]),
        div(class="furniture furniture-bench", [span("Intro Bench")]),
        div(class="furniture furniture-log-wall", [span("Follow Up")]),
      ]
    "talent" =>
      [
        div(class="furniture furniture-gallery", [span("Talent Wall")]),
        div(class="furniture furniture-scoreboard", [span("Skill Heatmap")]),
        div(class="furniture furniture-desk", [span("Tour Desk")]),
        div(class="furniture furniture-archive", [span("Evidence Shelf")]),
      ]
    "vitality" =>
      [
        div(class="furniture furniture-scoreboard", [span("Pulse Board")]),
        div(class="furniture furniture-map-table", [span("Heat Map")]),
        div(class="furniture furniture-radio", [span("Service Radio")]),
        div(class="furniture furniture-log-wall", [span("Metric Ledger")]),
      ]
    "garden" =>
      [
        div(class="furniture furniture-garden-bed", [span("Tool Trial")]),
        div(class="furniture furniture-bench", [span("Tutorial Bench")]),
        div(class="furniture furniture-signal-post", [span("Daily Tip")]),
        div(class="furniture furniture-review-table", [span("Before / After")]),
      ]
    "bridge" =>
      [
        div(class="furniture furniture-robot-bay", [span("Robot Bay")]),
        div(class="furniture furniture-radio", [span("Venue Link")]),
        div(class="furniture furniture-map-table", [span("Offline Map")]),
        div(class="furniture furniture-review-table", [span("Confirm Gate")]),
      ]
    "research" =>
      [
        div(class="furniture furniture-desk", [span("Research Desk")]),
        div(class="furniture furniture-bookshelf", [span("Source Wall")]),
        div(class="furniture furniture-map-table", [span("Synthesis Map")]),
        div(class="furniture furniture-review-table", [span("Review Gate")]),
      ]
    "market" =>
      [
        div(class="furniture furniture-market-stall", [span("Point Stall")]),
        div(class="furniture furniture-scoreboard", [span("Rewards")]),
        div(class="furniture furniture-desk", [span("Redeem Desk")]),
        div(class="furniture furniture-log-wall", [span("Benefit Ledger")]),
      ]
    "broadcast" =>
      [
        div(class="furniture furniture-radio", [span("Story Radar")]),
        div(class="furniture furniture-scoreboard", [span("Signal Board")]),
        div(class="furniture furniture-review-table", [span("Review Desk")]),
        div(class="furniture furniture-log-wall", [span("Broadcast Wall")]),
      ]
    _ =>
      [
        div(class="furniture furniture-desk", [span("Module Desk")]),
        div(class="furniture furniture-signal-post", [span("Signal Post")]),
        div(class="furniture furniture-review-table", [span("Review Table")]),
      ]
  }
}

///|
fn render_module_visual_agent(
  dispatch : Dispatch[Msg],
  agent : VisualAgentSnapshot,
) -> @rabbita.Html {
  button(
    class="interior-agent visual-interior-agent \{visual_agent_status_class(agent)}",
    title=agent.message,
    on_click=dispatch(SelectWorker(agent.worker_id)),
    [
      span(class="interior-agent-name", agent.worker_name),
      span(class="interior-agent-role", "\{agent.role} / \{agent.phase}"),
      span(class="interior-agent-summary", agent.message),
    ],
  )
}

///|
fn render_module_issue_list(civic : WenyuTownModule) -> @rabbita.Html {
  let issues = module_validation_issues(civic)
  if issues.is_empty() {
    div(class="module-issue-list module-issue-list-clean", [
      span("Config validated for current viewport placement."),
    ])
  } else {
    div(
      class="module-issue-list",
      issues.map(issue => span(class="module-issue-chip", issue)),
    )
  }
}

///|
fn render_module_runtime_counters(
  runtime : WenyuModuleRuntimeState,
) -> @rabbita.Html {
  div(class="module-runtime-counters", [
    span("Run \{runtime.running_count}"),
    span("Wait \{runtime.waiting_count}"),
    span("Review \{runtime.review_count}"),
    span("Blocked \{runtime.blocked_count}"),
    span("Done \{runtime.completed_count}"),
  ])
}

///|
fn render_module_protocol_card(civic : WenyuTownModule) -> @rabbita.Html {
  article(class="module-protocol-card", [
    div(class="module-civic-health-head", [
      span(class="module-book-chip projection-tone-info", "Building Protocol"),
      span(class="module-civic-status", civic.protocol_pattern),
    ]),
    p(class="module-book-summary", civic.use_case),
    div(class="module-book-metric-grid", [
      render_projection_metric(
        ProjectionMetricSnapshot::{
          label: "Footprint",
          value: "\{civic.footprint_w}x\{civic.footprint_h}",
          note: "tile occupancy",
          tone: "info",
        },
      ),
      render_projection_metric(
        ProjectionMetricSnapshot::{
          label: "Entrance",
          value: "\{civic.entrance_x},\{civic.entrance_y}",
          note: "road-facing tile",
          tone: "info",
        },
      ),
      render_projection_metric(
        ProjectionMetricSnapshot::{
          label: "Style",
          value: civic.style_family,
          note: civic.asset_base,
          tone: "info",
        },
      ),
    ]),
    div(class="module-agent-flow", [
      span(class="module-detail-label", "Agent Flow"),
      p(civic.agent_flow),
    ]),
  ])
}

///|
fn projection_tone_class(tone : String) -> String {
  match tone {
    "alert" => "projection-tone-alert"
    "review" => "projection-tone-review"
    "healthy" => "projection-tone-healthy"
    "success" => "projection-tone-healthy"
    "warning" => "projection-tone-review"
    "info" => "projection-tone-info"
    _ => "projection-tone-info"
  }
}

///|
fn render_projection_chips(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let chips : Array[@rabbita.Html] = []
  for chip in projection.status_chips {
    chips.push(
      span(
        class="module-book-chip \{projection_tone_class(chip.tone)}",
        chip.label,
      ),
    )
  }
  if chips.is_empty() {
    chips.push(span(class="module-book-chip projection-tone-info", "No chips"))
  }
  div(class="module-book-chip-row", chips)
}

///|
fn render_projection_metrics(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let cards : Array[@rabbita.Html] = []
  for metric in projection.metrics {
    cards.push(render_projection_metric(metric))
  }
  if cards.is_empty() {
    cards.push(
      article(class="module-book-metric projection-tone-info", [
        span(class="module-book-metric-label", "MoonBook"),
        span(class="module-book-metric-value", "waiting"),
        p("No generated UI metrics were published for this book yet."),
      ]),
    )
  }
  div(class="module-book-metric-grid", cards)
}

///|
fn render_projection_metric(metric : ProjectionMetricSnapshot) -> @rabbita.Html {
  article(class="module-book-metric \{projection_tone_class(metric.tone)}", [
    span(class="module-book-metric-label", metric.label),
    span(class="module-book-metric-value", metric.value),
    p(metric.note),
  ])
}

///|
fn render_projection_item(
  item : ProjectionItemSnapshot,
  kind : String,
) -> @rabbita.Html {
  article(class="module-book-item module-book-item-\{kind}", [
    h3(item.title),
    p(item.detail),
    span(item.meta),
  ])
}

///|
fn render_projection_item_group(
  title : String,
  empty : String,
  kind : String,
  items : Array[ProjectionItemSnapshot],
) -> @rabbita.Html {
  let children : Array[@rabbita.Html] = [h3(title)]
  if items.is_empty() {
    children.push(p(class="module-book-empty", empty))
  } else {
    for item in items {
      children.push(render_projection_item(item, kind))
    }
  }
  div(class="module-book-group", children)
}

///|
fn render_projection_journey(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let rows : Array[@rabbita.Html] = [h3("Latest Journey")]
  if projection.journey.is_empty() {
    rows.push(
      p(
        class="module-book-empty",
        "No MoonBook journey entries were published yet.",
      ),
    )
  } else {
    for step in projection.journey {
      let highlights = if step.highlights.is_empty() {
        ""
      } else {
        " / \{step.highlights.join(" / ")}"
      }
      rows.push(
        article(class="module-book-journey-item", [
          span(
            class="module-book-journey-status",
            "\{step.stage} / \{step.status}",
          ),
          h3(step.title),
          p("\{step.summary}\{highlights}"),
        ]),
      )
    }
  }
  div(class="module-book-group module-book-journey", rows)
}

///|
fn render_projection_links(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  let links : Array[@rabbita.Html] = [h3("Outputs")]
  if projection.links.is_empty() {
    links.push(
      p(
        class="module-book-empty",
        "No generated HTML outputs were found for this book.",
      ),
    )
  } else {
    for link in projection.links {
      links.push(
        a(
          href=link.url,
          class="module-book-link module-book-link-\{link.kind}",
          "\{link.label}",
        ),
      )
    }
  }
  div(class="module-book-group module-book-links", links)
}

///|
fn render_module_book_projection(
  model : Model,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  match find_module_book_projection(model, civic) {
    Some(projection) =>
      section(class="module-book-projection", [
        div(class="module-book-heading", [
          div([p(class="eyebrow", "MoonBook Projection"), h2(projection.title)]),
          span(class="module-book-id", projection.book_id),
        ]),
        p(class="module-book-summary", projection.summary),
        render_module_civic_health(model, civic),
        render_projection_chips(projection),
        render_projection_metrics(projection),
        div(class="module-book-grid", [
          render_projection_item_group(
            "Readiness",
            "MoonBook has not published readiness items for this module.",
            "readiness",
            projection.readiness,
          ),
          render_projection_item_group(
            "Review Queue",
            "No pending review items were published for this module.",
            "review",
            projection.review_queue,
          ),
          render_projection_item_group(
            "Page Families",
            "No generated page-family summary was published for this module.",
            "pages",
            projection.page_families,
          ),
          render_projection_links(projection),
        ]),
        render_projection_journey(projection),
      ])
    None =>
      section(class="module-book-projection module-book-projection-missing", [
        div(class="module-book-heading", [
          div([
            p(class="eyebrow", "MoonBook Projection"),
            h2("Projection Not Connected"),
          ]),
          span(class="module-book-id", civic.book_id),
        ]),
        p(
          class="module-book-summary",
          "This building is configured, but the UI did not find a generated MoonBook fragment for `.moontown/books/\{civic.book_id}/book/moonbook-ui-state.json`.",
        ),
        p(
          class="module-book-empty",
          "This is now a real integration gap, not a decorative fallback: create the bound civic book or publish its MoonBook UI state to make this interior useful.",
        ),
        render_module_civic_health(model, civic),
      ])
  }
}

///|
fn render_module_civic_health(
  model : Model,
  civic : WenyuTownModule,
) -> @rabbita.Html {
  match find_module_civic_health(model, civic) {
    Some(health) =>
      article(class="module-civic-health \{civic_health_status_class(health.status)}", [
        div(class="module-civic-health-head", [
          span(class="module-book-chip projection-tone-info", "Civic Doctor"),
          span(class="module-civic-status", civic_health_status_label(health.status)),
        ]),
        p(class="module-book-summary", civic_health_detail(health)),
        if health.latest_protocol_summary.is_empty() {
          span(class="module-book-empty", "No building protocol reduction has been recorded yet.")
        } else {
          p(class="module-book-summary", health.latest_protocol_summary)
        },
        div(class="module-book-metric-grid", [
          render_projection_metric(
            ProjectionMetricSnapshot::{
              label: "Operable",
              value: if health.operable { "yes" } else { "no" },
              note: "\{health.missing_required_paths.length()} missing paths",
              tone: if health.operable { "healthy" } else { "alert" },
            },
          ),
          render_projection_metric(
            ProjectionMetricSnapshot::{
              label: "Result Proof",
              value: if health.proven_by_result { "present" } else { "missing" },
              note: health.latest_decision,
              tone: if health.proven_by_result { "healthy" } else { "review" },
            },
          ),
          render_projection_metric(
            ProjectionMetricSnapshot::{
              label: "Mode",
              value: health.module_mode,
              note: health.skill_mode,
              tone: "info",
            },
          ),
          render_projection_metric(
            ProjectionMetricSnapshot::{
              label: "Protocol",
              value: health.protocol_status,
              note: "in \{health.protocol_inbox_count} / red \{health.protocol_reduction_count} / out \{health.protocol_outbox_count}",
              tone: if health.protocol_ready { "healthy" } else { "review" },
            },
          ),
          render_projection_metric(
            ProjectionMetricSnapshot::{
              label: "Review",
              value: "\{health.latest_review_items}",
              note: "items",
              tone: if health.latest_review_items > 0 { "review" } else { "info" },
            },
          ),
        ]),
      ])
    None =>
      article(class="module-civic-health module-status-unbound", [
        div(class="module-civic-health-head", [
          span(class="module-book-chip projection-tone-alert", "Civic Doctor"),
          span(class="module-civic-status", "No status"),
        ]),
        p(
          class="module-book-summary",
          "No civic status file was loaded. Run `moon run cmd/main -- civic doctor` to publish `.moontown/civic/status.json`.",
        ),
      ])
  }
}

///|
fn render_wenyu_module_interior(
  dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let residents = module_workers(civic, workers)
  let visual_agents = module_active_visual_agents(model, civic)
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  section(class="interior-shell module-interior-shell", [
    header(class="interior-header", [
      div([
        p(class="eyebrow", "Module Interior"),
        h2(civic.title),
        p(class="scene-node-key", "\{civic.id} / \{civic.book_id}"),
      ]),
      a(
        href="./viewport.html?assets=generated&mode=view&v=wenyu-modules",
        class="control-button viewport-back-town",
        "Back To Town",
      ),
    ]),
    div(class="interior-room module-interior-room", [
      div(class="module-interior-summary", [
        render_module_detail("District", civic.district),
        render_module_detail("Runtime", runtime.status_label),
        render_module_detail("Source", runtime.source_label),
        render_module_detail(
          "Workers",
          "\{runtime.visible_agent_count} active / \{residents.length()} bound",
        ),
        render_module_detail(
          "Entrance",
          "\{civic.entrance_x},\{civic.entrance_y}",
        ),
      ]),
      p(class="module-runtime-detail", runtime.detail),
      render_module_runtime_counters(runtime),
      render_module_issue_list(civic),
      render_module_protocol_card(civic),
      render_module_book_projection(model, civic),
      div(class="interior-floor", module_interior_furniture(civic)),
      div(
        class="interior-agent-grid",
        if !visual_agents.is_empty() {
          visual_agents.map(agent => render_module_visual_agent(dispatch, agent))
        } else if residents.is_empty() {
          [
            p(
              class="interior-empty",
              "No active workers are inside this module. Idle residents stay hidden until the module is opened by runtime projection.",
            ),
          ]
        } else {
          residents.map(worker => render_interior_agent(dispatch, worker))
        },
      ),
    ]),
  ])
}

///|
fn scene_node_by_key(
  scene : @ui.SceneRenderModel,
  key : String,
) -> @ui.SceneRenderNode {
  for node in scene.nodes {
    if node.key == key {
      return node
    }
  }
  scene.nodes[0]
}

///|
fn worker_avatar_left(zone : @ui.SceneRenderNode, index : Int) -> Int {
  let zone_x = scene_node_left(zone)
  let zone_width = scene_node_width(zone)
  match zone.key {
    "worker-yard" => zone_x + 72 + index % 5 * 38
    "city-hall" => zone_x + zone_width - 44
    _ => {
      let slot = index % 6
      match slot {
        0 => zone_x + 8
        1 => zone_x + zone_width - 42
        2 => zone_x + zone_width / 2 - 24
        3 => zone_x + 34
        4 => zone_x + zone_width - 76
        _ => zone_x + zone_width / 2 + 30
      }
    }
  }
}

///|
fn worker_avatar_top(zone : @ui.SceneRenderNode, index : Int) -> Int {
  let zone_y = scene_node_top(zone)
  let zone_height = scene_node_height(zone)
  match zone.key {
    "worker-yard" => zone_y + 20 + index / 5 * 34
    "city-hall" => zone_y + zone_height - 62
    _ => {
      let slot = index % 6
      match slot {
        0 => zone_y + zone_height - 46
        1 => zone_y + zone_height - 42
        2 => zone_y + zone_height - 74
        3 => zone_y + zone_height - 4
        4 => zone_y + zone_height - 2
        _ => zone_y + zone_height - 28
      }
    }
  }
}

///|
fn worker_avatar_initials(title : String) -> String {
  match title {
    "Harness Hound" => "HH"
    "Review Owl" => "RO"
    "Ledger Fox" => "LF"
    "Archive Cat" => "AC"
    "Snapshot Bridge" => "SB"
    "Town Shell Foreman" => "TS"
    "Policy Sprite" => "PS"
    "Cafe Matchmaker" => "CM"
    "Talent Cartographer" => "TC"
    "AI Garden Tutor" => "AG"
    "Physical Bridge Link" => "PB"
    _ => "??"
  }
}

///|
fn worker_status_class(status : @core.WorkerStatus) -> String {
  match status {
    @core.WorkerStatus::Running => "worker-running"
    @core.WorkerStatus::Waiting => "worker-waiting"
    @core.WorkerStatus::Idle => "worker-idle"
    @core.WorkerStatus::Blocked => "worker-blocked"
    @core.WorkerStatus::Offline => "worker-offline"
  }
}

///|
fn render_worker_avatar(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  worker : WorkerSim,
  index : Int,
  selected : Bool,
) -> @rabbita.Html {
  let zone = scene_node_by_key(scene, worker.zone_key)
  let style = [
    "left: \{worker_avatar_left(zone, index)}px",
    "top: \{worker_avatar_top(zone, index)}px",
    "--wander-x1: \{worker_wander_x1(index)}px",
    "--wander-y1: \{worker_wander_y1(index)}px",
    "--wander-x2: \{worker_wander_x2(index)}px",
    "--wander-y2: \{worker_wander_y2(index)}px",
    "--wander-x3: \{worker_wander_x3(index)}px",
    "--wander-y3: \{worker_wander_y3(index)}px",
    "--wander-duration: \{worker_wander_duration(index)}ms",
    "--worker-image: url('\{worker_roster_asset(index)}')",
  ]
  let selected_suffix = if selected { " selected" } else { "" }
  let class_name = "worker-avatar \{worker_status_class(worker.status)}" +
    " worker-sprite-roster" +
    selected_suffix
  button(class=class_name, style~, on_click=dispatch(SelectWorker(worker.id)), [
    span(class="worker-sprite", no_children()),
    span(class="worker-badge", worker_avatar_initials(worker.title)),
    span(class="worker-label", worker.title),
    span(class="worker-meta", "\{worker.role} / \{worker.status.to_string()}"),
  ])
}

///|
fn worker_wander_x1(index : Int) -> Int {
  match index % 6 {
    0 => 28
    1 => -24
    2 => 18
    3 => -30
    4 => 34
    _ => -18
  }
}

///|
fn worker_wander_y1(index : Int) -> Int {
  match index % 6 {
    0 => -12
    1 => -10
    2 => 14
    3 => 8
    4 => -4
    _ => 16
  }
}

///|
fn worker_wander_x2(index : Int) -> Int {
  match index % 6 {
    0 => 44
    1 => -42
    2 => 30
    3 => -48
    4 => 52
    _ => -28
  }
}

///|
fn worker_wander_y2(index : Int) -> Int {
  match index % 6 {
    0 => 18
    1 => 16
    2 => -18
    3 => -14
    4 => 20
    _ => -22
  }
}

///|
fn worker_wander_x3(index : Int) -> Int {
  match index % 6 {
    0 => -16
    1 => 22
    2 => -24
    3 => 26
    4 => -20
    _ => 18
  }
}

///|
fn worker_wander_y3(index : Int) -> Int {
  match index % 6 {
    0 => 24
    1 => -24
    2 => 22
    3 => -18
    4 => -26
    _ => 18
  }
}

///|
fn worker_wander_duration(index : Int) -> Int {
  5200 + index % 5 * 640
}

///|
fn worker_roster_asset(index : Int) -> String {
  "tilemap/actors/roster/resident_\{index % 64}_walk_strip.png"
}

///|
fn viewport_resident_grid_x(index : Int) -> Int {
  match index % 64 {
    0 => 34
    1 => 38
    2 => 44
    3 => 50
    4 => 56
    5 => 62
    6 => 28
    7 => 36
    8 => 72
    9 => 80
    10 => 88
    11 => 96
    12 => 104
    13 => 112
    14 => 120
    15 => 128
    16 => 82
    17 => 90
    18 => 100
    19 => 110
    20 => 120
    21 => 132
    22 => 142
    23 => 152
    24 => 162
    25 => 172
    26 => 182
    27 => 192
    28 => 202
    29 => 212
    30 => 222
    31 => 232
    32 => 126
    33 => 136
    34 => 146
    35 => 156
    36 => 166
    37 => 176
    38 => 186
    39 => 196
    40 => 54
    41 => 62
    42 => 70
    43 => 78
    44 => 86
    45 => 94
    46 => 102
    47 => 110
    48 => 22
    49 => 18
    50 => 26
    51 => 42
    52 => 58
    53 => 74
    54 => 150
    55 => 160
    56 => 176
    57 => 194
    58 => 210
    59 => 226
    60 => 116
    61 => 134
    62 => 150
    _ => 168
  }
}

///|
fn viewport_resident_grid_y(index : Int) -> Int {
  match index % 64 {
    0 => 32
    1 => 36
    2 => 40
    3 => 44
    4 => 48
    5 => 52
    6 => 54
    7 => 60
    8 => 24
    9 => 28
    10 => 32
    11 => 36
    12 => 40
    13 => 44
    14 => 48
    15 => 52
    16 => 60
    17 => 66
    18 => 70
    19 => 74
    20 => 78
    21 => 82
    22 => 86
    23 => 90
    24 => 62
    25 => 66
    26 => 70
    27 => 74
    28 => 78
    29 => 82
    30 => 86
    31 => 90
    32 => 102
    33 => 106
    34 => 110
    35 => 114
    36 => 118
    37 => 122
    38 => 126
    39 => 130
    40 => 82
    41 => 88
    42 => 94
    43 => 100
    44 => 106
    45 => 112
    46 => 118
    47 => 124
    48 => 30
    49 => 46
    50 => 62
    51 => 72
    52 => 72
    53 => 78
    54 => 36
    55 => 44
    56 => 50
    57 => 56
    58 => 58
    59 => 64
    60 => 58
    61 => 64
    62 => 72
    _ => 80
  }
}

///|
fn viewport_resident_avatar(index : Int) -> @rabbita.Html {
  let grid_x = viewport_resident_grid_x(index)
  let grid_y = viewport_resident_grid_y(index)
  let delay = index * 173 % 2400
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 9}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 31}px",
    "z-index: \{100 + grid_x + grid_y}",
    "--wander-x1: \{worker_wander_x1(index + 2)}px",
    "--wander-y1: \{worker_wander_y1(index + 2)}px",
    "--wander-x2: \{worker_wander_x2(index + 4)}px",
    "--wander-y2: \{worker_wander_y2(index + 4)}px",
    "--wander-x3: \{worker_wander_x3(index + 6)}px",
    "--wander-y3: \{worker_wander_y3(index + 6)}px",
    "--wander-duration: \{6200 + index % 8 * 360}ms",
    "--wander-delay: -\{delay}ms",
    "--worker-image: url('\{worker_roster_asset(index)}')",
  ]
  div(
    class="worker-avatar viewport-resident worker-running worker-sprite-roster",
    style~,
    [
      span(class="worker-sprite", no_children()),
      span(class="worker-badge", ""),
      span(class="worker-label", "Resident \{index + 1}"),
      span(class="worker-meta", "walking building district"),
    ],
  )
}

///|
fn render_viewport_residents() -> Array[@rabbita.Html] {
  let residents : Array[@rabbita.Html] = []
  for i in 0..<64 {
    residents.push(viewport_resident_avatar(i))
  }
  residents
}

///|
fn visual_overworld_agents(model : Model) -> Array[VisualAgentSnapshot] {
  match model.visual_projection {
    Some(projection) =>
      projection.agents.filter(fn(agent) { agent.visible_on_overworld })
    None => []
  }
}

///|
fn visual_agent_status_class(agent : VisualAgentSnapshot) -> String {
  match agent.status {
    "running" => "worker-running"
    "waiting" => "worker-waiting"
    "idle" => "worker-idle"
    "blocked" => "worker-blocked"
    "offline" => "worker-offline"
    _ =>
      if agent.phase == "failed" || agent.phase == "stale" {
        "worker-blocked"
      } else if agent.phase == "running" || agent.phase == "persisting" {
        "worker-running"
      } else if agent.phase == "packet" || agent.phase == "importing" {
        "worker-waiting"
      } else {
        "worker-idle"
      }
  }
}

///|
fn visual_agent_grid_x(agent : VisualAgentSnapshot) -> Int {
  match visual_agent_target_module(agent) {
    Some(civic) =>
      if visual_agent_should_route_to_module(agent) {
        clamp_visual_grid_x(civic.entrance_x + agent.z % 5 - 2)
      } else {
        clamp_visual_grid_x(agent.grid_x)
      }
    None => clamp_visual_grid_x(agent.grid_x)
  }
}

///|
fn visual_agent_grid_y(agent : VisualAgentSnapshot) -> Int {
  match visual_agent_target_module(agent) {
    Some(civic) =>
      if visual_agent_should_route_to_module(agent) {
        clamp_visual_grid_y(civic.entrance_y + agent.z / 5 % 5 - 2)
      } else {
        clamp_visual_grid_y(agent.grid_y)
      }
    None => clamp_visual_grid_y(agent.grid_y)
  }
}

///|
fn visual_agent_target_module(agent : VisualAgentSnapshot) -> WenyuTownModule? {
  find_module_for_book(agent.book_id)
}

///|
fn visual_agent_should_route_to_module(agent : VisualAgentSnapshot) -> Bool {
  agent.phase == "running" ||
  agent.phase == "persisting" ||
  agent.phase == "review"
}

///|
fn clamp_visual_grid_x(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 255 {
    255
  } else {
    value
  }
}

///|
fn clamp_visual_grid_y(value : Int) -> Int {
  if value < 0 {
    0
  } else if value > 143 {
    143
  } else {
    value
  }
}

///|
fn visual_agent_sprite_asset(
  agent : VisualAgentSnapshot,
  index : Int,
) -> String {
  if agent.sprite_key == "" {
    worker_roster_asset(index)
  } else {
    "tilemap/actors/roster/\{agent.sprite_key}_walk_strip.png"
  }
}

///|
fn render_visual_agent_avatar(
  dispatch : Dispatch[Msg],
  agent : VisualAgentSnapshot,
  index : Int,
  selected : Bool,
) -> @rabbita.Html {
  let grid_x = visual_agent_grid_x(agent)
  let grid_y = visual_agent_grid_y(agent)
  let delay = (index * 211 + agent.z * 17) % 2600
  let style = [
    "left: \{iso_tile_left(grid_x, grid_y) + 9}px",
    "top: \{iso_tile_top(grid_x, grid_y) - 31}px",
    "z-index: \{120 + agent.z}",
    "--wander-x1: \{worker_wander_x1(index + 3)}px",
    "--wander-y1: \{worker_wander_y1(index + 3)}px",
    "--wander-x2: \{worker_wander_x2(index + 5)}px",
    "--wander-y2: \{worker_wander_y2(index + 5)}px",
    "--wander-x3: \{worker_wander_x3(index + 7)}px",
    "--wander-y3: \{worker_wander_y3(index + 7)}px",
    "--wander-duration: \{5600 + index % 7 * 420}ms",
    "--wander-delay: -\{delay}ms",
    "--worker-image: url('\{visual_agent_sprite_asset(agent, index)}')",
  ]
  let selected_suffix = if selected { " selected" } else { "" }
  let class_name = "worker-avatar visual-agent \{visual_agent_status_class(agent)}" +
    " worker-sprite-roster" +
    " agent-phase-\{agent.phase}" +
    " agent-behavior-\{agent.behavior}" +
    " agent-effect-\{agent.effect}" +
    selected_suffix
  button(
    class=class_name,
    style~,
    title=agent.message,
    on_click=dispatch(SelectWorker(agent.worker_id)),
    [
      span(class="worker-sprite", no_children()),
      span(class="worker-badge", worker_avatar_initials(agent.worker_name)),
      span(class="worker-label", agent.worker_name),
      span(class="worker-meta", "\{agent.phase} / \{agent.book_title}"),
    ],
  )
}

///|
fn is_working_worker(worker : WorkerSim) -> Bool {
  match worker.status {
    @core.WorkerStatus::Running | @core.WorkerStatus::Blocked => true
    _ => false
  }
}

///|
fn is_on_duty_watcher(worker : WorkerSim) -> Bool {
  worker.role.contains("Watcher")
}

///|
fn visible_overworld_workers(workers : Array[WorkerSim]) -> Array[WorkerSim] {
  workers.filter(worker => {
    is_working_worker(worker) || is_on_duty_watcher(worker)
  })
}

///|
fn node_owns_worker(node : @ui.SceneRenderNode, worker : WorkerSim) -> Bool {
  worker.zone_key == node.key ||
  node.key == "book-\{worker.book_id}" ||
  node.key.contains(worker.book_id) ||
  (node.key == "worker-yard" && !is_working_worker(worker))
}

///|
fn workers_inside_node(
  node : @ui.SceneRenderNode,
  workers : Array[WorkerSim],
) -> Array[WorkerSim] {
  workers.filter(worker => node_owns_worker(node, worker))
}

///|
fn furniture_for_node(node : @ui.SceneRenderNode) -> Array[@rabbita.Html] {
  if node.key == "city-hall" {
    [
      div(class="furniture furniture-map-table", [span("Dispatch Map")]),
      div(class="furniture furniture-radio", [span("Mayor Radio")]),
      div(class="furniture furniture-policy-board", [span("Policy Board")]),
      div(class="furniture furniture-archive", [span("Town Ledger")]),
    ]
  } else if node.key == "worker-yard" {
    [
      div(class="furniture furniture-bench", [span("Ready Bench")]),
      div(class="furniture furniture-tool-rack", [span("Tool Rack")]),
      div(class="furniture furniture-queue-board", [span("Queue Board")]),
      div(class="furniture furniture-rest-mat", [span("Rest Mat")]),
    ]
  } else if node.key.contains("book") {
    [
      div(class="furniture furniture-desk", [span("Keeper Desk")]),
      div(class="furniture furniture-bookshelf", [span("Wiki Shelf")]),
      div(class="furniture furniture-memory-crystal", [span("Memory Core")]),
      div(class="furniture furniture-review-table", [span("Review Table")]),
    ]
  } else {
    [
      div(class="furniture furniture-signal-post", [span("Signal Post")]),
      div(class="furniture furniture-repair-box", [span("Repair Box")]),
      div(class="furniture furniture-log-wall", [span("Event Wall")]),
    ]
  }
}

///|
fn render_interior_agent(
  dispatch : Dispatch[Msg],
  worker : WorkerSim,
) -> @rabbita.Html {
  button(
    class="interior-agent \{worker_status_class(worker.status)}",
    on_click=dispatch(SelectWorker(worker.id)),
    [
      span(class="worker-badge", worker_avatar_initials(worker.title)),
      span(class="worker-label", worker.title),
      span(class="worker-meta", "\{worker.role} / \{worker.status.to_string()}"),
    ],
  )
}

///|
fn render_building_interior(
  dispatch : Dispatch[Msg],
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  node_key : String,
) -> @rabbita.Html {
  let node = scene_node_by_key(scene, node_key)
  let residents = workers_inside_node(node, workers)
  section(class="interior-shell", [
    header(class="interior-header", [
      div([
        p(class="eyebrow", "Interior View"),
        h2(node.title),
        p(class="scene-node-key", node.key),
      ]),
      button(
        class="control-button",
        on_click=dispatch(SelectOverview),
        "Back To Town",
      ),
    ]),
    div(class="interior-room", [
      div(class="interior-floor", furniture_for_node(node)),
      div(
        class="interior-agent-grid",
        if residents.is_empty() {
          [p(class="interior-empty", "No visible agents inside this room.")]
        } else {
          residents.map(worker => render_interior_agent(dispatch, worker))
        },
      ),
    ]),
  ])
}

///|
fn feed_event_title(event : @core.TownEvent) -> String {
  let suffix = match event.related_book_id {
    Some(book_id) => " / \{book_id}"
    None => ""
  }
  match event.kind {
    "standing-watch" => "Mayor watch update\{suffix}"
    "standing-goal" => "Watcher dispatched\{suffix}"
    "execution" => "Worker run changed\{suffix}"
    "persist" => "Bookkeeper saved memory\{suffix}"
    "projection" => "Website projection refreshed\{suffix}"
    "summary" => "Book health summary\{suffix}"
    "review" => "Keeper review needed\{suffix}"
    "daemon" => "Daemon heartbeat"
    "supervision" => "Mayor supervision"
    "civic-pattern" => "Civic pattern round"
    "civic-salon" => "Civic pattern round"
    _ => "Town message\{suffix}"
  }
}

///|
fn feed_event_tone(event : @core.TownEvent) -> String {
  if event.detail.contains("Failed") ||
    event.detail.contains("failed") ||
    event.detail.contains("not-ready") {
    "alert"
  } else if event.kind == "standing-watch" && event.detail.contains("NoChange") {
    "calm"
  } else if event.kind == "persist" || event.kind == "projection" {
    "calm"
  } else if event.kind == "review" ||
    event.kind == "supervision" ||
    event.kind == "civic-pattern" ||
    event.kind == "civic-salon" {
    "hot"
  } else {
    "neutral"
  }
}

///|
fn feed_event_visible(event : @core.TownEvent) -> Bool {
  event.kind == "standing-watch" ||
  event.kind == "standing-goal" ||
  event.kind == "execution" ||
  event.kind == "persist" ||
  event.kind == "projection" ||
  event.kind == "summary" ||
  event.kind == "review" ||
  event.kind == "daemon" ||
  event.kind == "supervision" ||
  event.kind == "civic-pattern" ||
  event.kind == "civic-salon"
}

///|
fn push_recent_event_messages(
  feed : Array[FeedItem],
  events : Array[@core.TownEvent],
) -> Unit {
  let mut pushed = 0
  let mut daemon_pushed = false
  for offset in 0..<events.length() {
    let event = events[events.length() - 1 - offset]
    if pushed >= 6 {
      break
    }
    if event.kind == "daemon" && daemon_pushed {
      continue
    }
    if feed_event_visible(event) {
      feed.push({
        title: feed_event_title(event),
        detail: event.detail,
        tone: feed_event_tone(event),
      })
      pushed += 1
      if event.kind == "daemon" {
        daemon_pushed = true
      }
    }
  }
}

///|
fn push_worker_alert_messages(
  feed : Array[FeedItem],
  workers : Array[WorkerSim],
  watcher_idle_detail : String,
) -> Unit {
  for worker in workers {
    if worker.status == @core.WorkerStatus::Blocked {
      feed.push({
        title: "\{worker.title} stalled",
        detail: "Mayor should recover this lane before the next 30-minute watcher cycle.",
        tone: "alert",
      })
    } else if is_on_duty_watcher(worker) &&
      worker.status == @core.WorkerStatus::Idle {
      feed.push({
        title: "\{worker.title} is on duty",
        detail: watcher_idle_detail,
        tone: "calm",
      })
    }
  }
}

///|
fn push_execution_messages(
  feed : Array[FeedItem],
  executions : Array[@core.TaskExecutionRecord],
) -> Unit {
  for execution in executions {
    match execution.status {
      @core.TaskExecutionStatus::Running
      | @core.TaskExecutionStatus::RunConfirmed =>
        feed.push({
          title: "\{execution.task_id} is running",
          detail: execution.summary,
          tone: "neutral",
        })
      @core.TaskExecutionStatus::AwaitingPersistence =>
        feed.push({
          title: "\{execution.task_id} awaits MoonBook persistence",
          detail: "The run is done; the next town action is keeper persistence and evidence capture.",
          tone: "hot",
        })
      @core.TaskExecutionStatus::Stale =>
        feed.push({
          title: "\{execution.task_id} went stale",
          detail: "Mayor supervision should recover the missed heartbeat or retry the lane.",
          tone: "alert",
        })
      @core.TaskExecutionStatus::Failed =>
        feed.push({
          title: "\{execution.task_id} failed",
          detail: "A proposal/run failure surfaced in the packet lifecycle.",
          tone: "alert",
        })
      _ => ()
    }
  }
}

///|
fn feed_items(
  model : Model,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  events : Array[@core.TownEvent],
) -> Array[FeedItem] {
  let feed : Array[FeedItem] = []
  feed.push({
    title: standing_watch_connected_title(model),
    detail: standing_watch_connected_detail(model),
    tone: "calm",
  })
  push_recent_event_messages(feed, events)
  push_worker_alert_messages(feed, workers, standing_watch_idle_detail(model))
  push_execution_messages(feed, executions)
  if feed.length() == 1 {
    feed.push({
      title: "No new town messages",
      detail: "The daemon is between checks. Leave this page open and the thread refreshes from `.moontown/town.json` every few seconds.",
      tone: "neutral",
    })
  }
  feed
}

///|
fn enabled_standing_goal_count(model : Model) -> Int {
  let mut count = 0
  for goal in model.standing_goals {
    if goal.enabled {
      count += 1
    }
  }
  count
}

///|
fn standing_watch_connected_title(model : Model) -> String {
  let count = enabled_standing_goal_count(model)
  if count == 0 {
    "No standing watcher connected"
  } else if count == 1 {
    match active_standing_goal(model) {
      Some(goal) => "\{goal.title} watcher is connected"
      None => "Standing watcher is connected"
    }
  } else {
    "\{count} standing watchers connected"
  }
}

///|
fn standing_watch_connected_detail(model : Model) -> String {
  let count = enabled_standing_goal_count(model)
  match active_standing_goal(model) {
    Some(goal) => {
      let target = goal.target_book_id.unwrap_or("mayor-selected-book")
      let prefix = if count > 1 {
        "Mayor keeps \{count} standing watches alive through the daemon."
      } else {
        "Mayor keeps this standing watch alive through the daemon."
      }
      "\{prefix} Next configured watch: `\{goal.id}` -> `\{target}` every \{goal.cadence_ticks} ticks."
    }
    None =>
      "Add a standing goal in `.moontown/standing-goals.json` or submit one from the operator panel to start durable topic monitoring."
  }
}

///|
fn standing_watch_idle_detail(model : Model) -> String {
  match active_standing_goal(model) {
    Some(goal) => {
      let remaining = goal.next_due_tick - daemon_tick_count(model)
      let wait = if remaining > 0 {
        "\{remaining} daemon ticks"
      } else {
        "the next daemon tick"
      }
      "Waiting until \{wait} for `\{goal.id}`. The next due check will move a watcher into an active run."
    }
    None =>
      "Waiting for a configured standing watch. Add one to `.moontown/standing-goals.json` to activate this worker."
  }
}

///|
fn render_feed(feed : Array[FeedItem]) -> @rabbita.Html {
  section(class="feed-panel phone-message-panel", [
    div(class="phone-topbar", [
      span(class="phone-status-dot", ""),
      div([
        h2("Mayor Messages"),
        p("Live town thread for standing-watch updates"),
      ]),
    ]),
    div(
      class="feed-list phone-thread",
      feed.map(item => {
        article(class="feed-item message-bubble tone-\{item.tone}", [
          h3(item.title),
          p(item.detail),
        ])
      }),
    ),
  ])
}

///|
fn selection_title(selection : Selection) -> String {
  match selection {
    Overview => "Town Overview"
    Node(_) => "Zone Inspector"
    Worker(_) => "Worker Inspector"
  }
}

///|
fn find_worker(workers : Array[WorkerSim], worker_id : String) -> WorkerSim? {
  for worker in workers {
    if worker.id == worker_id {
      return Some(worker)
    }
  }
  None
}

///|
fn render_worker_choice_button(
  dispatch : Dispatch[Msg],
  worker : WorkerSim,
) -> @rabbita.Html {
  button(
    class="inspector-action worker-choice",
    on_click=dispatch(SelectWorker(worker.id)),
    "\{worker.title} - \{worker.status.to_string()}",
  )
}

///|
fn render_worker_roster(
  dispatch : Dispatch[Msg],
  workers : Array[WorkerSim],
) -> @rabbita.Html {
  if workers.is_empty() {
    div(class="worker-roster", [p("No workers are visible in this scope.")])
  } else {
    let controls : Array[@rabbita.Html] = [
      p(class="worker-roster-title", "Workers"),
    ]
    for worker in workers {
      controls.push(render_worker_choice_button(dispatch, worker))
    }
    div(class="worker-roster", controls)
  }
}

///|
fn selection_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> Array[@rabbita.Html] {
  match model.selection {
    Overview =>
      [
        p(
          "Select a zone or worker to inspect live state. Use town actions to redirect the simulation.",
        ),
        p(
          "Packet-ready: \{count_execution_status(executions, @core.TaskExecutionStatus::PacketReady)}",
        ),
        p(
          "Imported proposals: \{count_execution_status(executions, @core.TaskExecutionStatus::ProposalImported)}",
        ),
        p("Active runs: \{running_execution_count(executions)}"),
        render_worker_roster(dispatch, workers),
        button(
          class="inspector-action",
          on_click=dispatch(InjectBudget),
          "Inspector Inject Budget",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(RelieveQueue),
          "Inspector Relieve Queue",
        ),
        button(
          class="inspector-action",
          on_click=dispatch(StabilityDrill),
          "Inspector Stability Drill",
        ),
      ]
    Node(node_key) => {
      let node = scene_node_by_key(scene, node_key)
      let related_workers = workers.filter(fn(worker) {
        worker.zone_key == node_key
      })
      let related_executions = executions.filter(fn(execution) {
        node_matches_execution(node_key, execution.book_id, execution.status)
      })
      [
        p("Zone: \{node.title}"),
        p("Footprint: \{node.width}x\{node.height}"),
        p("Assets: \{node.asset_paths.length()}"),
        p("Workers present: \{related_workers.length()}"),
        p("Execution records: \{related_executions.length()}"),
        render_worker_roster(dispatch, related_workers),
        button(
          class="inspector-action",
          on_click=dispatch(SelectOverview),
          "Back To Overview",
        ),
      ]
    }
    Worker(worker_id) =>
      match find_worker(workers, worker_id) {
        Some(worker) => {
          let book_execution = find_book_execution(executions, worker.book_id)
          let lifecycle = match book_execution {
            Some(execution) =>
              "Book lifecycle: \{execution.status.to_string()} / \{execution.summary}"
            None => "Book lifecycle: no execution record visible."
          }
          [
            p("Role: \{worker.role}"),
            p("Status: \{worker.status.to_string()}"),
            p("Zone: \{worker.zone_key}"),
            p("Energy: \{worker.energy}%"),
            p("Load: \{worker.load}%"),
            p(worker.summary),
            p(lifecycle),
            button(
              class="inspector-action",
              on_click=dispatch(RelieveQueue),
              "Worker Relieve Queue",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(StabilityDrill),
              "Worker Stability Drill",
            ),
            button(
              class="inspector-action",
              on_click=dispatch(SelectOverview),
              "Back To Overview",
            ),
          ]
        }
        None => [p("The selected worker is no longer visible in the scene.")]
      }
  }
}

///|
fn render_inspector(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  section(class="inspector-panel", [
    h2(selection_title(model.selection)),
    div(
      class="inspector-body",
      selection_body(dispatch, model, scene, workers, executions),
    ),
  ])
}

///|
fn render_town_viewport(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
  shell_class : String,
  frame_class : String,
) -> @rabbita.Html {
  let stage_width = if standalone_viewport_requested() {
    tilemap_scene_width()
  } else {
    scene.width
  }
  let stage_height = if standalone_viewport_requested() {
    tilemap_scene_height()
  } else {
    scene.height
  }
  let scene_style = ["width: \{stage_width}px", "height: \{stage_height}px"]
  let scene_frame_style = ["--scene-width: \{stage_width}px"]
  let worker_avatars : Array[@rabbita.Html] = []
  if standalone_viewport_requested() {
    match model.visual_projection {
      Some(_) => {
        let visual_agents = visual_overworld_agents(model)
        for i in 0..<visual_agents.length() {
          let agent = visual_agents[i]
          worker_avatars.push(
            render_visual_agent_avatar(
              dispatch,
              agent,
              i,
              selected_worker_id == Some(agent.worker_id),
            ),
          )
        }
      }
      None =>
        for resident in render_viewport_residents() {
          worker_avatars.push(resident)
        }
    }
  } else {
    for i in 0..<workers.length() {
      let worker = workers[i]
      worker_avatars.push(
        render_worker_avatar(
          dispatch,
          scene,
          worker,
          i,
          selected_worker_id == Some(worker.id),
        ),
      )
    }
  }
  let scene_nodes = if standalone_viewport_requested() {
    []
  } else {
    scene.nodes
    .filter(node => !is_mayor_scene_node(node))
    .map(node => {
      render_node(dispatch, node, selected_node_key == Some(node.key))
    })
  }
  section(class=shell_class, [
    div(class="scene-stage-rail", execution_stage_cards(executions)),
    p(
      class="scene-hint",
      "Scroll the viewport on smaller screens, then select a zone or worker to inspect the live pipeline state.",
    ),
    div(class=frame_class, style=scene_frame_style, [
      div(class="scene-stage", style=scene_style, [
        img(
          class="scene-background",
          src=scene.background_path,
          alt="\{scene.title} background",
          loading="eager",
          no_children(),
        ),
        render_tilemap_layer(),
        render_water_effect_layer(),
        render_wenyu_module_road_layer(),
        render_wenyu_module_building_layer(
          dispatch, model, executions, selected_node_key,
        ),
        div(class="scene-overlay", [
          div(class="scene-nodes-layer", scene_nodes),
          div(class="scene-workers-layer", worker_avatars),
        ]),
      ]),
    ]),
  ])
}

///|
fn render_wenyu_viewport_portal(
  model : Model,
  scene : @ui.SceneRenderModel,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let latest = latest_watcher_record(model)
  let latest_decision = match latest {
    Some(record) => record.decision
    None => "Waiting"
  }
  let latest_sources = match latest {
    Some(record) => record.new_source_count.to_string()
    None => "0"
  }
  let next_check = match active_standing_goal(model) {
    Some(goal) => "\{ticks_until_next_goal_check(model, goal)} ticks"
    None => "not scheduled"
  }
  section(class="viewport-portal-card", [
    div(class="viewport-portal-copy", [
      p(class="eyebrow", "Canonical Wenyu Viewport"),
      h2("Open the real Wenyu Valley tile map"),
      p(
        class="summary",
        "The dashboard no longer renders a second scaled-down town map. Click through to the standalone viewport so the operator view and the Wenyu Valley map stay consistent.",
      ),
      div(class="viewport-portal-stats", [
        status_chip("Scene: \{scene.title}", "chip-book"),
        status_chip("Latest: \{latest_decision}", "chip-neutral"),
        status_chip("New sources: \{latest_sources}", "chip-neutral"),
        status_chip("Next check: \{next_check}", "chip-clock"),
        status_chip("Executions: \{executions.length()}", "chip-neutral"),
      ]),
    ]),
    a(
      href="./viewport.html?assets=generated&v=wenyu",
      class="viewport-portal-button",
      "Open Wenyu Viewport",
    ),
  ])
}

///|
fn is_mayor_scene_node(node : @ui.SceneRenderNode) -> Bool {
  node.key == "book-town" ||
  node.key == "book-moontown" ||
  node.key == "book-mayor"
}

///|
fn viewport_mode_label(mode : ViewportMode) -> String {
  match mode {
    ViewMode => "View Mode"
    EditorMode => "Editor Mode"
    OutputMode => "Final Output"
  }
}

///|
fn viewport_mode_slug(mode : ViewportMode) -> String {
  match mode {
    ViewMode => "view"
    EditorMode => "editor"
    OutputMode => "output"
  }
}

///|
fn viewport_mode_summary(mode : ViewportMode) -> String {
  match mode {
    ViewMode =>
      "Clean town presentation. Click buildings to inspect live module interiors."
    EditorMode =>
      "Designer workspace. Validate module placement, runtime bindings, and output coverage without changing MoonBook state."
    OutputMode =>
      "Final retrieval surface. Browse generated MoonBook websites, reports, reviews, and page families from one place."
  }
}

///|
fn render_viewport_mode_button(
  dispatch : Dispatch[Msg],
  model : Model,
  mode : ViewportMode,
) -> @rabbita.Html {
  let active = if model.viewport_mode == mode { " is-active" } else { "" }
  button(
    class="control-button viewport-mode-button\{active}",
    on_click=dispatch(SetViewportMode(mode)),
    viewport_mode_label(mode),
  )
}

///|
fn render_viewport_mode_switch(
  dispatch : Dispatch[Msg],
  model : Model,
) -> @rabbita.Html {
  div(class="viewport-mode-switch", [
    span(class="viewport-mode-current", viewport_mode_label(model.viewport_mode)),
    render_viewport_mode_button(dispatch, model, ViewportMode::ViewMode),
    render_viewport_mode_button(dispatch, model, ViewportMode::EditorMode),
    render_viewport_mode_button(dispatch, model, ViewportMode::OutputMode),
    a(
      href="./viewport.html?assets=generated&mode=\{viewport_mode_slug(model.viewport_mode)}&v=wenyu",
      class="viewport-mode-link",
      "Copyable Mode URL",
    ),
  ])
}

///|
fn module_projection_count_for_configured_modules(model : Model) -> Int {
  let mut count = 0
  for civic in wenyu_modules() {
    match find_module_book_projection(model, civic) {
      Some(_) => count += 1
      None => ()
    }
  }
  count
}

///|
fn moondesk_bridge_records(model : Model) -> Array[MoondeskBridgeRecord] {
  match model.moondesk_bridge {
    Some(bridge) => bridge.records
    None => []
  }
}

///|
fn moondesk_root_status_label(model : Model) -> String {
  match model.moondesk_bridge {
    Some(bridge) =>
      if bridge.moondesk_root_available {
        "Moondesk checkout found"
      } else {
        "Moondesk checkout missing"
      }
    None => "Bridge not loaded"
  }
}

///|
fn moondesk_record_count(model : Model) -> Int {
  moondesk_bridge_records(model).length()
}

///|
fn artifact_status_class(status : String) -> String {
  match status {
    "ready" => "artifact-status-ready"
    "simple-only" => "artifact-status-simple"
    "reference-only" => "artifact-status-reference"
    "review" => "artifact-status-review"
    _ => "artifact-status-neutral"
  }
}

///|
fn bridge_record_status_class(status : String) -> String {
  match status {
    "ready" => "artifact-status-ready"
    "accepted" => "artifact-status-ready"
    "completed" => "artifact-status-ready"
    "review" => "artifact-status-review"
    "needs-review" => "artifact-status-review"
    "failed" => "artifact-status-alert"
    _ => "artifact-status-neutral"
  }
}

///|
fn render_handoff_contract_items(
  artifact : MoondeskHandoffArtifact,
) -> @rabbita.Html {
  let items : Array[@rabbita.Html] = []
  for contract in artifact.import_contract {
    items.push(span(class="handoff-contract-item", contract))
  }
  if items.is_empty() {
    items.push(
      span(class="handoff-contract-item", "No import contract declared."),
    )
  }
  div(class="handoff-contract-list", items)
}

///|
fn render_handoff_artifact_card(
  artifact : MoondeskHandoffArtifact,
) -> @rabbita.Html {
  article(
    class="handoff-artifact-card \{artifact_status_class(artifact.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", artifact.kind),
        span(class="handoff-status", artifact.status),
      ]),
      h3(artifact.title),
      p(artifact.summary),
      div(class="handoff-path-grid", [
        render_module_detail("Source", artifact.source_path),
        render_module_detail("Target", artifact.target_path),
      ]),
      p(class="handoff-scope", artifact.scope),
      render_handoff_contract_items(artifact),
    ],
  )
}

///|
fn render_moondesk_bridge_record(
  record : MoondeskBridgeRecord,
) -> @rabbita.Html {
  article(
    class="moondesk-bridge-record \{bridge_record_status_class(record.status)}",
    [
      div(class="handoff-artifact-heading", [
        span(class="handoff-kind", record.kind),
        span(class="handoff-status", record.status),
      ]),
      h3(record.title),
      p(record.summary),
      div(class="handoff-path-grid", [
        render_module_detail("Target", record.target),
        render_module_detail("Path", record.path),
      ]),
      span(class="bridge-record-time", record.created_at),
    ],
  )
}

///|
fn render_town_editor_boundary_panel(model : Model) -> @rabbita.Html {
  section(class="viewport-editor-boundary", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Town-Level Editor"),
      h2("Moontown / Moondesk Boundary"),
      p(
        "Moontown composes modules, books, worker lanes, resource envelopes, and output surfaces. Detailed file, prompt, skill, memory, and single-agent work stays in Moondesk and returns as portable artifacts.",
      ),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Edit Scope", "multi-agent town"),
      render_module_detail("Simple Agent Edit", "role, cadence, capacity"),
      render_module_detail("Deep Agent Edit", "Moondesk"),
      render_module_detail("Bridge", moondesk_root_status_label(model)),
    ]),
    div(class="handoff-link-row", [
      a(
        href="./tilemap/modules/wenyu-town-modules.json",
        class="module-book-link module-book-link-config",
        "Open Module Registry",
      ),
      a(
        href="./tilemap/modules/moondesk-handoff.json",
        class="module-book-link module-book-link-config",
        "Open Handoff Manifest",
      ),
      a(
        href="./moondesk-bridge.json",
        class="module-book-link module-book-link-config",
        "Open Bridge Ledger",
      ),
    ]),
  ])
}

///|
fn render_moondesk_handoff_panel(model : Model) -> @rabbita.Html {
  let artifacts : Array[@rabbita.Html] = []
  for artifact in model.moondesk_handoff_artifacts {
    artifacts.push(render_handoff_artifact_card(artifact))
  }
  section(class="moondesk-handoff-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Moondesk Import Contract"),
      h2("Portable Artifact Lanes"),
      p(
        "These are the data/config lanes Moondesk can export into Moontown. Adding new capability should add or update this manifest before changing viewport code.",
      ),
    ]),
    div(
      class="handoff-artifact-grid",
      if artifacts.is_empty() {
        [
          article(class="viewport-output-empty", [
            h2("No Handoff Artifacts"),
            p("`tilemap/modules/moondesk-handoff.json` did not load."),
          ]),
        ]
      } else {
        artifacts
      },
    ),
  ])
}

///|
fn render_moondesk_bridge_panel(model : Model) -> @rabbita.Html {
  let records : Array[@rabbita.Html] = []
  for record in moondesk_bridge_records(model) {
    records.push(render_moondesk_bridge_record(record))
  }
  section(class="moondesk-bridge-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Moondesk Bridge"),
      h2("Recent Portable Records"),
      p(
        "Real bridge records from `.moontown/moondesk-*` and `.moontown/book-results`. This is the evidence trail for work moving between Moondesk, MoonBook, MoonClaw, and Moontown.",
      ),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Bridge Records", "\{moondesk_record_count(model)}"),
      render_module_detail("Checkout", moondesk_root_status_label(model)),
    ]),
    div(
      class="moondesk-bridge-list",
      if records.is_empty() {
        [
          article(class="viewport-output-empty", [
            h2("No Bridge Records"),
            p("No Moondesk dispatch, request, or book-result records were found yet."),
          ]),
        ]
      } else {
        records
      },
    ),
  ])
}

///|
fn render_standalone_viewport_map(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  render_town_viewport(
    dispatch,
    model,
    scene,
    visible_overworld_workers(workers),
    executions,
    selected_node_key,
    selected_worker_id,
    "scene-frame-shell viewport-frame-shell",
    "scene-frame viewport-frame",
  )
}

///|
fn render_viewport_view_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  match model.selection {
    Node(node_key) =>
      match find_wenyu_module(node_key) {
        Some(civic) =>
          render_wenyu_module_interior(dispatch, model, civic, workers, executions)
        None => render_building_interior(dispatch, scene, workers, node_key)
      }
    _ =>
      section(class="viewport-view-mode", [
        p(class="viewport-mode-note", viewport_mode_summary(ViewportMode::ViewMode)),
        render_standalone_viewport_map(
          dispatch,
          model,
          scene,
          workers,
          executions,
          selected_node_key,
          selected_worker_id,
        ),
      ])
  }
}

///|
fn render_editor_module_row(
  dispatch : Dispatch[Msg],
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  let issues = module_validation_issues(civic)
  let projection_status = match find_module_book_projection(model, civic) {
    Some(_) => "MoonBook output connected"
    None => "Missing MoonBook output"
  }
  let issue_text = if issues.is_empty() {
    "placement clean"
  } else {
    issues.join(", ")
  }
  button(
    class="editor-module-row \{runtime.status_class}",
    on_click=dispatch(SelectNode(civic.id)),
    [
      span(class="editor-module-title", civic.title),
      span(class="editor-module-meta", "\{civic.id} / \{civic.book_id}"),
      span(
        class="editor-module-meta",
        "\{civic.grid_x},\{civic.grid_y} / \{civic.footprint_w}x\{civic.footprint_h} -> \{civic.entrance_x},\{civic.entrance_y}",
      ),
      span(class="editor-module-meta", "\{civic.style_family} / \{civic.protocol_pattern}"),
      span(class="editor-module-runtime", runtime.status_label),
      span(class="editor-module-meta", projection_status),
      span(class="editor-module-issues", issue_text),
    ],
  )
}

///|
fn render_viewport_editor_panel(
  dispatch : Dispatch[Msg],
  model : Model,
  executions : Array[@core.TaskExecutionRecord],
) -> @rabbita.Html {
  let module_rows : Array[@rabbita.Html] = []
  for civic in wenyu_modules() {
    module_rows.push(render_editor_module_row(dispatch, model, civic, executions))
  }
  aside(class="viewport-editor-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Editor Mode"),
      h2("Module Registry"),
      p(viewport_mode_summary(ViewportMode::EditorMode)),
    ]),
    div(class="viewport-editor-stats", [
      render_module_detail("Modules", "\{wenyu_module_count()} enabled"),
      render_module_detail("Placement", "\{wenyu_clean_module_count()} clean"),
      render_module_detail(
        "Book Outputs",
        "\{module_projection_count_for_configured_modules(model)} bound",
      ),
      render_module_detail("Config Version", "v\{wenyu_modules_version()}"),
    ]),
    render_town_editor_boundary_panel(model),
    render_moondesk_handoff_panel(model),
    render_moondesk_bridge_panel(model),
    div(class="editor-module-list", module_rows),
  ])
}

///|
fn render_viewport_editor_body(
  dispatch : Dispatch[Msg],
  model : Model,
  scene : @ui.SceneRenderModel,
  workers : Array[WorkerSim],
  executions : Array[@core.TaskExecutionRecord],
  selected_node_key : String?,
  selected_worker_id : String?,
) -> @rabbita.Html {
  section(class="viewport-editor-layout", [
    render_standalone_viewport_map(
      dispatch,
      model,
      scene,
      workers,
      executions,
      selected_node_key,
      selected_worker_id,
    ),
    render_viewport_editor_panel(dispatch, model, executions),
  ])
}

///|
fn render_final_output_book_card(
  projection : BookProjectionFragment,
) -> @rabbita.Html {
  article(class="viewport-output-book-card", [
    div(class="module-book-heading", [
      div([p(class="eyebrow", "MoonBook Output"), h2(projection.title)]),
      span(class="module-book-id", projection.book_id),
    ]),
    p(class="module-book-summary", projection.summary),
    render_projection_chips(projection),
    render_projection_metrics(projection),
    div(class="viewport-output-book-grid", [
      render_projection_item_group(
        "Readiness",
        "No readiness summary was published yet.",
        "readiness",
        projection.readiness,
      ),
      render_projection_item_group(
        "Review Queue",
        "No review queue was published yet.",
        "review",
        projection.review_queue,
      ),
      render_projection_item_group(
        "Page Families",
        "No page-family summary was published yet.",
        "pages",
        projection.page_families,
      ),
      render_projection_links(projection),
    ]),
    render_projection_journey(projection),
  ])
}

///|
fn render_final_output_empty_state() -> @rabbita.Html {
  article(class="viewport-output-empty", [
    h2("No MoonBook Outputs Connected"),
    p(
      "The final-output mode is working, but the browser bridge did not load any `moonbook-ui-state.json` fragments yet.",
    ),
    p(
      "Run a book projection or publish generated MoonBook UI state under `.moontown/books/<book>/book/` to populate this page.",
    ),
  ])
}

///|
fn render_viewport_output_body(model : Model) -> @rabbita.Html {
  let cards : Array[@rabbita.Html] = []
  for projection in model.module_projections {
    cards.push(render_final_output_book_card(projection))
  }
  section(class="viewport-output-panel", [
    div(class="viewport-panel-heading", [
      p(class="eyebrow", "Final Output Mode"),
      h2("Generated Book Outputs"),
      p(viewport_mode_summary(ViewportMode::OutputMode)),
    ]),
    div(class="viewport-output-stats", [
      render_module_detail("Book Fragments", "\{model.module_projections.length()}"),
      render_module_detail(
        "Bound Modules",
        "\{module_projection_count_for_configured_modules(model)}",
      ),
      render_module_detail("Daemon Tick", daemon_tick_label(model)),
      render_module_detail("Civic", civic_status_summary(model)),
      render_module_detail("Local Time", real_time_label()),
    ]),
    div(
      class="viewport-output-grid",
      if cards.is_empty() {
        [render_final_output_empty_state()]
      } else {
        cards
      },
    ),
    render_moondesk_handoff_panel(model),
    render_moondesk_bridge_panel(model),
  ])
}

///|
fn render_scene(dispatch : Dispatch[Msg], model : Model) -> @rabbita.Html {
  let state = state_for_model(model)
  let scene = town_scene(model)
  let workers = workers_for_model(model)
  let executions = state.executions
  let alerts = all_alerts(scene, model)
  let selected_node_key = match model.selection {
    Node(node_key) => Some(node_key)
    _ => None
  }
  let selected_worker_id = match model.selection {
    Worker(worker_id) => Some(worker_id)
    _ => None
  }
  if standalone_viewport_requested() {
    let viewport_body = match model.viewport_mode {
      ViewMode =>
        render_viewport_view_body(
          dispatch,
          model,
          scene,
          workers,
          executions,
          selected_node_key,
          selected_worker_id,
        )
      EditorMode =>
        render_viewport_editor_body(
          dispatch,
          model,
          scene,
          workers,
          executions,
          selected_node_key,
          selected_worker_id,
        )
      OutputMode => render_viewport_output_body(model)
    }
    return section(
      class="viewport-page viewport-mode-\{viewport_mode_slug(model.viewport_mode)}",
      [
      header(class="viewport-hud", [
        div(class="viewport-title", [
          p(class="eyebrow", "Moontown Viewport"),
          h1(scene.title),
          p(class="viewport-mode-subtitle", viewport_mode_summary(model.viewport_mode)),
        ]),
        div(class="viewport-actions", [
          render_viewport_mode_switch(dispatch, model),
          status_chip(if model.paused { "Paused" } else { "Live" }, "chip-live"),
          status_chip("Local time \{real_time_label()}", "chip-clock"),
          status_chip(daemon_tick_label(model), "chip-neutral"),
          status_chip(
            "Modules \{wenyu_module_count()} / clean \{wenyu_clean_module_count()} / civic \{civic_status_summary(model)} / v\{wenyu_modules_version()}",
            "chip-book",
          ),
          button(
            class="control-button viewport-zoom-button viewport-zoom-out",
            on_click=dispatch(ViewportControlNoop),
            "Zoom Out",
          ),
          button(
            class="control-button viewport-zoom-button viewport-zoom-in",
            on_click=dispatch(ViewportControlNoop),
            "Zoom In",
          ),
          button(
            class="control-button",
            on_click=dispatch(TogglePause),
            if model.paused {
              "Resume"
            } else {
              "Pause"
            },
          ),
          button(class="control-button", on_click=dispatch(Step), "Step"),
        ]),
      ]),
      viewport_body,
    ])
  }
  section(class="town-shell", [
    header(class="town-header", [
      div(class="title-block", [
        p(class="eyebrow", "Moontown"),
        h1(scene.title),
        p(
          class="summary",
          "A pixel-art always-on AI town: mayor supervision, resident agents, district services, and virtual-physical feedback loops.",
        ),
        render_controls(dispatch, model),
      ]),
      render_alerts(alerts),
    ]),
    render_operator_command_center(dispatch, model, workers, executions),
    main_(class="town-main", [
      div(class="scene-column", [
        render_wenyu_viewport_portal(model, scene, executions),
      ]),
      div(class="sidebar-column", [
        render_inspector(dispatch, model, scene, workers, executions),
        render_feed(feed_items(model, workers, executions, state.events)),
        aside(class="scene-legend", [
          h2("Legend"),
          p("City Hall is the mayor runtime and policy anchor."),
          p("Moonbook houses hold keeper-owned domain planning."),
          p(
            "Worker avatars now move between yard, hall, books, and anomaly response.",
          ),
          p(
            "Actions on the header feed directly back into queue pressure and town stability.",
          ),
        ]),
      ]),
    ]),
    section(class="metric-grid", render_vitality_metric_grid(model)),
    render_civic_context(model),
    render_runtime_bar(model, workers, executions),
    render_civic_modules(model),
    render_resident_agents(model),
    render_civic_quests(model),
    render_social_talent(model),
    render_bridge_contract(model),
  ])
}

///|
fn count_execution_status(
  executions : Array[@core.TaskExecutionRecord],
  status : @core.TaskExecutionStatus,
) -> Int {
  let mut count = 0
  for execution in executions {
    if execution.status == status {
      count += 1
    }
  }
  count
}

///|
fn running_execution_count(
  executions : Array[@core.TaskExecutionRecord],
) -> Int {
  let mut count = 0
  for execution in executions {
    match execution.status {
      @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running
      | @core.TaskExecutionStatus::AwaitingPersistence
      | @core.TaskExecutionStatus::ReviewQueued
      | @core.TaskExecutionStatus::Stale => count += 1
      _ => ()
    }
  }
  count
}

///|
fn node_matches_execution(
  node_key : String,
  book_id : String,
  status : @core.TaskExecutionStatus,
) -> Bool {
  match node_key {
    "city-hall" =>
      status == @core.TaskExecutionStatus::PacketReady ||
      status == @core.TaskExecutionStatus::ProposalImported ||
      status == @core.TaskExecutionStatus::RunConfirmed
    "anomaly-corner" =>
      status == @core.TaskExecutionStatus::Failed ||
      status == @core.TaskExecutionStatus::Stale ||
      status == @core.TaskExecutionStatus::ReviewQueued
    "book-coding" => book_id == "coding"
    "book-finance" => book_id == "finance"
    "worker-yard" =>
      status == @core.TaskExecutionStatus::AwaitingPersistence ||
      status == @core.TaskExecutionStatus::Completed
    _ => node_key == "book-\{book_id}"
  }
}

///|
fn find_book_execution(
  executions : Array[@core.TaskExecutionRecord],
  book_id : String,
) -> @core.TaskExecutionRecord? {
  for execution in executions {
    if execution.book_id == book_id {
      return Some(execution)
    }
  }
  None
}

///|
fn render_module_detail(label : String, value : String) -> @rabbita.Html {
  div(class="module-detail-card", [
    span(class="module-detail-label", label),
    p(value),
  ])
}

///|
fn find_book_worker(workers : Array[WorkerSim], book_id : String) -> WorkerSim? {
  for worker in workers {
    if worker.book_id == book_id {
      return Some(worker)
    }
  }
  None
}

///|
fn find_book_task(
  tasks : Array[@core.TownTask],
  book_id : String,
) -> @core.TownTask? {
  for task in tasks {
    if task.book_id == book_id {
      return Some(task)
    }
  }
  None
}

///|
fn priority_for_task_id(task_id : String) -> Int {
  if task_id.contains("code-patch") {
    0
  } else if task_id.contains("implementation-backlog") {
    1
  } else if task_id.contains("image-asset") || task_id.contains("asset-pack") {
    2
  } else {
    3
  }
}

///|
fn find_priority_book_worker(
  workers : Array[WorkerSim],
  book_id : String,
) -> WorkerSim? {
  find_book_worker(workers, book_id)
}

///|
fn find_priority_book_task(
  tasks : Array[@core.TownTask],
  book_id : String,
) -> @core.TownTask? {
  let mut best : @core.TownTask? = None
  let mut best_priority = 999
  for task in tasks {
    if task.book_id != book_id {
      continue
    }
    let priority = priority_for_task_id(task.id)
    if priority < best_priority {
      best_priority = priority
      best = Some(task)
    }
  }
  best
}

///|
fn find_priority_book_execution(
  executions : Array[@core.TaskExecutionRecord],
  book_id : String,
) -> @core.TaskExecutionRecord? {
  let mut best : @core.TaskExecutionRecord? = None
  let mut best_priority = 999
  for execution in executions {
    if execution.book_id != book_id {
      continue
    }
    let priority = priority_for_task_id(execution.task_id)
    if priority < best_priority {
      best_priority = priority
      best = Some(execution)
    }
  }
  best
}

///|
fn matches_any_book_id(book_id : String, candidates : Array[String]) -> Bool {
  for candidate in candidates {
    if book_id == candidate {
      return true
    }
  }
  false
}

///|
fn find_book_worker_by_ids(
  workers : Array[WorkerSim],
  book_ids : Array[String],
) -> WorkerSim? {
  for book_id in book_ids {
    match find_book_worker(workers, book_id) {
      Some(worker) => return Some(worker)
      None => ()
    }
  }
  None
}

///|
fn find_book_task_by_ids(
  tasks : Array[@core.TownTask],
  book_ids : Array[String],
) -> @core.TownTask? {
  for book_id in book_ids {
    match find_book_task(tasks, book_id) {
      Some(task) => return Some(task)
      None => ()
    }
  }
  None
}

///|
fn find_priority_book_execution_by_ids(
  executions : Array[@core.TaskExecutionRecord],
  book_ids : Array[String],
) -> @core.TaskExecutionRecord? {
  let mut best : @core.TaskExecutionRecord? = None
  let mut best_priority = 999
  for execution in executions {
    if !matches_any_book_id(execution.book_id, book_ids) {
      continue
    }
    let priority = priority_for_task_id(execution.task_id)
    if priority < best_priority {
      best_priority = priority
      best = Some(execution)
    }
  }
  best
}

///|
fn main {
  let (dispatch, app) = @rabbita.cell_with_dispatch(
    model=init_model(),
    update~,
    view=(dispatch, model) => render_scene(dispatch, model),
  )
  @rabbita.new(app)..with_init(schedule_tick(dispatch)).mount("app")
}
