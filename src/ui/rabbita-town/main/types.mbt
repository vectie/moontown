///|
priv enum Selection {
  Overview
  Node(String)
  Worker(String)
  Agent(String)
}

///|
priv enum StateSourceKind {
  DemoSimulation
  SnapshotFile
} derive(Eq)

///|
priv enum EnergyWeather {
  Sunny
  Cloudy
  Rain
  Snow
} derive(Eq)

///|
priv enum EnergyTool {
  InspectTool
  RoadTool
  ParkTool
  DemolishTool
  ResearchTowerTool
  LaboratoryTool
  WorkshopTool
  TalentHomeTool
} derive(Eq)

///|
/// Diagnostic layers exposed by Map Lab. These are deliberately presentation
/// state only: toggling a layer never changes the compiled town or its ledger.
priv enum MapLabLayer {
  MapLabSourceEvidence
  MapLabTerrain
  MapLabLandBlocks
  MapLabParcelsPrograms
  MapLabRoadsNavigation
  MapLabPortalsSpurs
  MapLabPublicRealm
  MapLabActivity
  MapLabProvenance
  MapLabValidation
} derive(Eq)

///|
priv enum DashboardSection {
  DistrictSystems
  ResidentAgentsSection
  CivicQuestsSection
  SocialCapitalSection
} derive(Eq)

///|
priv enum RequestComposerFocus {
  RequestShortcuts
  StandingWatchComposer
  EvidenceBookComposer
} derive(Eq)

///|
/// A resident persona the player can talk to on the virtual phone.
priv struct PhoneContact {
  id : String
  name : String
  role : String
  avatar_glyph : String
  greeting : String
}

///|
/// One chat message inside a phone thread.
priv struct PhoneMessage {
  contact : String
  from_me : Bool
  text : String
  tick : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The player's own embodied resident in the valley.
priv struct PlayerAvatar {
  name : String
  persona : String
  color : Int
  sprite_index : Int
  title : String
} derive(ToJson, FromJson)

///|
/// Time-interpolated on-map motion for the player resident. Rendering is a
/// pure function of (from, to, started_seconds), so no per-frame model writes
/// are needed; the player simply stops at the destination.
priv struct PlayerMotion {
  from_x : Double
  from_y : Double
  to_x : Double
  to_y : Double
  started_seconds : Double
  path : Array[(Double, Double)]
} derive(ToJson, FromJson)

///|
/// Last accepted road position for the player's resident. Motion remains a
/// transient animation, while this endpoint is durable across reloads.
priv struct PlayerPosition {
  x : Double
  y : Double
} derive(ToJson, FromJson)

///|
/// Stable event identity allocated monotonically by one writer.
priv struct TownLifeDot {
  writer_id : String
  sequence : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Lamport timestamp used for causal ordering. writer_id deterministically
/// breaks ties between concurrent updates that observed the same logical time.
priv struct TownLifeCausalStamp {
  lamport : Int
  writer_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifeWriterCounter {
  writer_id : String
  sequence : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Events at or below this per-writer sequence were deliberately pruned.
priv struct TownLifePruneWatermark {
  writer_id : String
  through_sequence : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifePhoneEvent {
  id : String
  dot : TownLifeDot
  stamp : TownLifeCausalStamp
  value : PhoneMessage
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifeTextEvent {
  id : String
  dot : TownLifeDot
  /// All writer dots observed for this semantic event. Scheduled reports use
  /// one semantic id across tabs; aliases let pruning fence every duplicate.
  observed_dots : Array[TownLifeDot]?
  stamp : TownLifeCausalStamp
  value : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// One grow-only attention counter cell for one writer and cooldown key.
priv struct TownLifeAttentionCounter {
  writer_id : String
  cooldown_key : String
  count : Int
  last_shown_tick : Int
  dot : TownLifeDot
  stamp : TownLifeCausalStamp
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A knowledge building post that can be published and collected.
priv struct KnowledgePost {
  id : String
  building_id : String?
  incarnation_id : String?
  created_stamp : TownLifeCausalStamp?
  updated_stamp : TownLifeCausalStamp?
  reset_epoch : TownLifeCausalStamp?
  building_name : String
  topic : String
  author : String
  spark : Int
  published : Bool
  collected : Bool
  mine : Bool
} derive(ToJson, FromJson)

///|
/// An idempotent source of valley spark. IDs are semantic (for example a
/// quest id or one seed/day check-in), so concurrent tabs can union awards
/// without either losing distinct rewards or counting one reward twice.
priv struct TownLifeSparkAward {
  id : String
  amount : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifePostTombstone {
  post_id : String
  incarnation_id : String
  reset_epoch : TownLifeCausalStamp?
  dot : TownLifeDot
  stamp : TownLifeCausalStamp
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Persisted town-life slice: avatar, progression, phone log, knowledge
/// collection, and analytics day counters. A versioned checkpoint plus
/// per-document writer shards keep the social layer durable without a backend
/// or a cross-tab last-writer-wins race.
priv struct TownLifeSave {
  player : PlayerAvatar?
  player_position : PlayerPosition?
  player_stamp : TownLifeCausalStamp?
  player_position_stamp : TownLifeCausalStamp?
  writer_counters : Array[TownLifeWriterCounter]?
  spark : Int
  spark_floor : Int?
  spark_awards : Array[TownLifeSparkAward]?
  quest_done : Array[String]
  phone_log : Array[PhoneMessage]
  phone_events : Array[TownLifePhoneEvent]?
  phone_prune_watermarks : Array[TownLifePruneWatermark]?
  posts : Array[KnowledgePost]
  post_reset_stamp : TownLifeCausalStamp?
  post_tombstones : Array[TownLifePostTombstone]?
  analytics : Array[String]
  analytics_events : Array[TownLifeTextEvent]?
  analytics_prune_watermarks : Array[TownLifePruneWatermark]?
  /// Attention receipts are optional so saves written before the ecosystem
  /// migration continue to decode without a schema reset.
  ecosystem_attention_receipts : Array[EcosystemAttentionReceipt]?
  attention_counters : Array[TownLifeAttentionCounter]?
  attention_prune_watermarks : Array[TownLifePruneWatermark]?
  ops_reports : Array[String]?
  ops_report_events : Array[TownLifeTextEvent]?
  ops_report_prune_watermarks : Array[TownLifePruneWatermark]?
  last_report_tick : Int
  checkin_day : Int
  /// Per-blueprint spatial CRDT authority. Optional so TownLife V3 shards
  /// written before the unified world migration remain decodable.
  world_states : Array[TownLifeWorldState]?
  /// Deprecated migration-window fields. New saves use a reset stamp and
  /// per-incarnation tombstones, so rebuilding never reuses deletion identity.
  post_generation : Int?
  deleted_post_ids : Array[String]?
} derive(ToJson, FromJson)

///|
priv struct Model {
  tick : Int
  paused : Bool
  selection : Selection
  state_source : StateSourceKind
  dashboard_section : DashboardSection?
  request_composer : RequestComposerFocus
  projection_snapshot : ProjectionSnapshot?
  snapshot_version : Int
  energy_valley_runtime : EnergyValleyRuntimeState
  energy_first_agent_open : Bool
  visual_projection : VisualProjectionSnapshot?
  visual_projection_version : Int
  module_projections : Array[BookProjectionFragment]
  module_projections_version : Int
  knowledge_domain_catalog : KnowledgeDomainCatalog?
  knowledge_domain_catalog_version : Int
  civic_status : CivicServicePortfolioSnapshot?
  civic_status_version : Int
  moondesk_handoff_artifacts : Array[MoondeskHandoffArtifact]
  moondesk_handoff_version : Int
  moondesk_bridge : MoondeskBridgeIndex?
  moondesk_bridge_version : Int
  daemon_snapshot : DaemonSnapshot?
  daemon_snapshot_version : Int
  live_autonomy : LiveAutonomySnapshot?
  live_autonomy_version : Int
  editor_pipeline : EditorPipelineSnapshot?
  editor_pipeline_version : Int
  standing_goals : Array[StandingGoalSnapshot]
  standing_goals_version : Int
  watcher_records : Array[WatcherRunRecordSnapshot]
  watcher_records_version : Int
  operator_requests : Array[OperatorRequestSnapshot]
  operator_requests_version : Int
  book_template_requests : Array[BookTemplateRequestSnapshot]
  book_template_requests_version : Int
  research_handoff : ResearchHandoffState
  moonflow_receiver : MoonFlowReceiverState
  request_title : String
  request_prompt : String
  request_book_id : String
  request_cadence : String
  request_quality_threshold : String
  request_submitting : Bool
  request_status : String
  book_request_title : String
  book_request_book_id : String
  book_request_purpose : String
  book_request_websites : String
  book_request_cadence : String
  book_request_analysis_method : String
  book_request_submitting : Bool
  book_request_status : String
  budget : Int
  energy : Int
  pressure : Int
  stability : Int
  energy_weather : EnergyWeather
  energy_weather_auto : Bool
  energy_time_scale : Int
  energy_tool : EnergyTool
  energy_board_open : Bool
  energy_status_open : Bool
  energy_guide_open : Bool
  energy_reset_open : Bool
  energy_intro_open : Bool
  energy_request_open : Bool
  resident_explorer_open : Bool
  resident_query : String
  town_chronicle_open : Bool
  /// The only authoritative player-authored spatial state. Buildings, roads,
  /// and parks are derived views of this versioned, blueprint-bound ledger.
  energy_world_delta : EnergyValleyWorldDeltaLedger
  energy_selected_building : GoldenValleyBuilding?
  energy_toast : String
  player : PlayerAvatar?
  player_position : PlayerPosition?
  town_life_player_stamp : TownLifeCausalStamp?
  town_life_player_position_stamp : TownLifeCausalStamp?
  player_motion : PlayerMotion?
  player_follow : Bool
  walk_mode : Bool
  avatar_wizard_step : Int
  avatar_draft_name : String
  avatar_draft_persona : String
  avatar_draft_color : Int
  phone_open : Bool
  phone_contact : String
  phone_draft : String
  phone_log : Array[PhoneMessage]
  town_life_phone_events : Array[TownLifePhoneEvent]
  town_life_phone_prune_watermarks : Array[TownLifePruneWatermark]
  phone_unread : Int
  moonclaw_guide_pending : Bool
  moonclaw_guide_error : String
  town_life_writer_id : String
  town_life_writer_counters : Array[TownLifeWriterCounter]
  spark : Int
  town_life_spark_floor : Int
  town_life_spark_awards : Array[TownLifeSparkAward]
  quest_done : Array[String]
  life_toast : String
  life_toast_tick : Int
  knowledge_dialog_open : Bool
  knowledge_draft_topic : String
  knowledge_target_building : String
  knowledge_target_site_id : String
  posts : Array[KnowledgePost]
  town_life_post_reset_stamp : TownLifeCausalStamp?
  town_life_post_tombstones : Array[TownLifePostTombstone]
  square_open : Bool
  ops_open : Bool
  ops_tab : Int
  ops_reports : Array[String]
  town_life_ops_report_events : Array[TownLifeTextEvent]
  town_life_ops_report_prune_watermarks : Array[TownLifePruneWatermark]
  last_report_tick : Int
  analytics : Array[String]
  town_life_analytics_events : Array[TownLifeTextEvent]
  town_life_analytics_prune_watermarks : Array[TownLifePruneWatermark]
  ecosystem_attention_receipts : Array[EcosystemAttentionReceipt]
  town_life_attention_counters : Array[TownLifeAttentionCounter]
  town_life_attention_prune_watermarks : Array[TownLifePruneWatermark]
  /// Joined per-blueprint world histories. `energy_world_delta` above is only
  /// the compiler-facing canonical projection of this authority.
  town_life_world_states : Array[TownLifeWorldState]
  metro_visible : Bool
  checkin_day : Int
  map_lab_open : Bool
  map_lab_layers : Array[MapLabLayer]
  map_lab_selected_id : String
  map_lab_query : String
}

///|
priv enum Msg {
  Tick
  ViewportControlNoop
  TogglePause
  Step
  SelectWorker(String)
  SelectAgent(String)
  SelectNode(String)
  SelectOverview
  SetEnergyWeather(EnergyWeather)
  ToggleEnergyWeatherAuto
  SetEnergyTimeScale(Int)
  SetEnergyTool(EnergyTool)
  ToggleEnergyBoard
  ToggleEnergyStatus
  OpenEnergyGuide
  CloseEnergyGuide
  OpenEnergyReset
  CloseEnergyReset
  CloseEnergyIntro
  OpenEnergyRequest
  OpenEnergyRequestForAgent(String)
  CloseEnergyRequest
  ToggleResidentExplorer
  ResidentSearch(String)
  ToggleTownChronicle
  EnergyResetCurrent
  EnergyGenerateNew
  EnergyCanvasClick(Int, Int)
  OpenEnergyBuilding(String)
  OpenEcosystemAttention(String, String)
  CloseEnergyInspector
  SetDashboardSection(DashboardSection)
  SetRequestComposer(RequestComposerFocus)
  SetRequestTitle(String)
  SetRequestPrompt(String)
  SetRequestBookId(String)
  SetRequestCadence(String)
  SetRequestQualityThreshold(String)
  SubmitOperatorRequest
  OperatorRequestSubmitted(String)
  SetBookRequestTitle(String)
  SetBookRequestBookId(String)
  SetBookRequestPurpose(String)
  SetBookRequestWebsites(String)
  SetBookRequestCadence(String)
  SetBookRequestAnalysisMethod(String)
  SubmitBookTemplateRequest
  BookTemplateRequestSubmitted(String)
  ResearchHandoffInspected(String)
  StartResearchHandoff
  ReconcileResearchHandoff
  ResearchHandoffExecuted(String)
  MoonFlowReceiverInspected(String)
  StartMoonFlowReceiver
  ReconcileMoonFlowReceiver
  MoonFlowReceiverSettled(String)
  AvatarDraftName(String)
  AvatarDraftPersona(String)
  AvatarDraftColor(Int)
  AvatarWizardNext
  AvatarWizardBack
  AvatarCreate
  AvatarOpenEditor
  ToggleWalkMode
  TogglePlayerFollow
  PlayerStepDirection(Int, Int)
  PlayerStepTo(Int, Int)
  TogglePhone
  OpenMoonclawGuide
  PhoneSelectContact(String)
  PhoneDraft(String)
  PhoneSend
  MoonclawGuideAsk(String)
  MoonclawGuideReplied(String)
  ToggleSquare
  OpenKnowledgeDialog(String)
  CloseKnowledgeDialog
  KnowledgeDraftTopic(String)
  ConfirmKnowledgeTopic
  PublishBuilding(String)
  CollectBuilding(String)
  ToggleOps
  SetOpsTab(Int)
  OpsGenerateReport
  ToggleMetro
  DailyCheckin
  CloseLifeToast
  ToggleMapLab
  CloseMapLab
  ToggleMapLabLayer(MapLabLayer)
  SelectMapLabEntity(String)
  SetMapLabQuery(String)
  TownLifeStorageChanged
}
