///|
priv enum Selection {
  Overview
  Node(String)
  Worker(String)
  Agent(String)
}

///|
/// MoonTown's three spatial planes. An underground visit remembers the
/// building it came from so the secured lift can return to the same interior.
priv enum TownSpatialLayer {
  Outdoor
  Indoor(GoldenValleyBuilding)
  ReferenceInterior
  Underground(GoldenValleyBuilding?)
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
  CollaborationComposer
  ResultsComposer
  AttentionComposer
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
  tick : Int32
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The player's own embodied resident in the valley.
priv struct PlayerAvatar {
  name : String
  persona : String
  color : Int32
  sprite_index : Int32
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
  sequence : Int32
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Lamport timestamp used for causal ordering. writer_id deterministically
/// breaks ties between concurrent updates that observed the same logical time.
priv struct TownLifeCausalStamp {
  lamport : Int32
  writer_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifeWriterCounter {
  writer_id : String
  sequence : Int32
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Events at or below this per-writer sequence were deliberately pruned.
priv struct TownLifePruneWatermark {
  writer_id : String
  through_sequence : Int32
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
  count : Int32
  last_shown_tick : Int32
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
  spark : Int32
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
  amount : Int32
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
  spark : Int32
  spark_floor : Int32?
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
  last_report_tick : Int32
  checkin_day : Int32
  /// Per-blueprint spatial CRDT authority. Optional so TownLife V3 shards
  /// written before the unified world migration remain decodable.
  world_states : Array[TownLifeWorldState]?
  /// Deprecated migration-window fields. New saves use a reset stamp and
  /// per-incarnation tombstones, so rebuilding never reuses deletion identity.
  post_generation : Int32?
  deleted_post_ids : Array[String]?
} derive(ToJson, FromJson)

///|
priv struct Model {
  tick : Int32
  paused : Bool
  selection : Selection
  state_source : StateSourceKind
  dashboard_section : DashboardSection?
  request_composer : RequestComposerFocus
  collaboration : @collaboration.Client
  neighborhood : NeighborhoodState
  neighborhood_manage : NeighborhoodManageState
  projection_snapshot : ProjectionSnapshot?
  snapshot_version : Int32
  energy_valley_runtime : EnergyValleyRuntimeState
  energy_first_agent_open : Bool
  town_spatial_layer : TownSpatialLayer
  secret_compute_room_selected_id : String
  indoor_selected_slot_id : String
  spatial_scene_selections : Map[String, SpatialSceneSelection]
  spatial_compute_return_reference : Bool
  spatial_selected_work_id : String
  spatial_request_id : String
  visual_projection : VisualProjectionSnapshot?
  visual_projection_version : Int32
  module_projections : Array[BookProjectionFragment]
  module_projections_version : Int32
  knowledge_domain_catalog : KnowledgeDomainCatalog?
  knowledge_domain_catalog_version : Int32
  civic_status : CivicServicePortfolioSnapshot?
  civic_status_version : Int32
  moondesk_handoff_artifacts : Array[MoondeskHandoffArtifact]
  moondesk_handoff_version : Int32
  moondesk_bridge : MoondeskBridgeIndex?
  moondesk_bridge_version : Int32
  daemon_snapshot : DaemonSnapshot?
  daemon_snapshot_version : Int32
  live_autonomy : LiveAutonomySnapshot?
  live_autonomy_version : Int32
  editor_pipeline : EditorPipelineSnapshot?
  editor_pipeline_version : Int32
  standing_goals : Array[StandingGoalSnapshot]
  standing_goals_version : Int32
  watcher_records : Array[WatcherRunRecordSnapshot]
  watcher_records_version : Int32
  operator_requests : Array[OperatorRequestSnapshot]
  operator_requests_version : Int32
  book_template_requests : Array[BookTemplateRequestSnapshot]
  book_template_requests_version : Int32
  imported_outputs : ImportedOutputsState
  research_handoff : ResearchHandoffState
  moonflow_receiver : MoonFlowReceiverState
  request_title : String
  request_prompt : String
  request_book_id : String
  request_cadence : String
  request_quality_threshold : String
  request_watch_mode : WatchRequestMode
  request_material_sources : String
  request_material_acceptance : String
  request_material_next_action : String
  request_material_receipt : (String, String, String, MaterialWatchSnapshot)?
  request_submitting : Bool
  request_submission_id : Int32
  request_follow_result : Bool
  request_status : String
  book_request_title : String
  book_request_book_id : String
  book_request_purpose : String
  book_request_websites : String
  book_request_cadence : String
  book_request_analysis_method : String
  book_request_submitting : Bool
  book_request_status : String
  budget : Int32
  energy : Int32
  pressure : Int32
  stability : Int32
  energy_weather : EnergyWeather
  energy_weather_auto : Bool
  energy_time_scale : Int32
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
  avatar_wizard_step : Int32
  avatar_draft_name : String
  avatar_draft_persona : String
  avatar_draft_color : Int32
  phone_open : Bool
  phone_contact : String
  phone_draft : String
  phone_log : Array[PhoneMessage]
  town_life_phone_events : Array[TownLifePhoneEvent]
  town_life_phone_prune_watermarks : Array[TownLifePruneWatermark]
  phone_unread : Int32
  moonclaw_guide_pending : Bool
  moonclaw_guide_error : String
  town_life_writer_id : String
  town_life_writer_counters : Array[TownLifeWriterCounter]
  spark : Int32
  town_life_spark_floor : Int32
  town_life_spark_awards : Array[TownLifeSparkAward]
  quest_done : Array[String]
  life_toast : String
  life_toast_tick : Int32
  knowledge_dialog_open : Bool
  knowledge_draft_topic : String
  knowledge_target_building : String
  knowledge_target_site_id : String
  posts : Array[KnowledgePost]
  town_life_post_reset_stamp : TownLifeCausalStamp?
  town_life_post_tombstones : Array[TownLifePostTombstone]
  square_open : Bool
  ops_open : Bool
  ops_tab : Int32
  ops_reports : Array[String]
  town_life_ops_report_events : Array[TownLifeTextEvent]
  town_life_ops_report_prune_watermarks : Array[TownLifePruneWatermark]
  last_report_tick : Int32
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
  checkin_day : Int32
  map_lab_open : Bool
  map_lab_layers : Array[MapLabLayer]
  map_lab_selected_id : String
  map_lab_query : String
}

///|
priv enum Msg {
  NeighborhoodEvent(NeighborhoodMsg)
  NeighborhoodManageEvent(NeighborhoodManageMsg)
  ImportedOutputsEvent(ImportedOutputsMsg)
  ImportedDownloadReceived(
    Int32,
    Int32,
    @imported_output_contract.Selection,
    ImportedOutputDownload
  )
  Tick
  ViewportControlNoop
  TogglePause
  Step
  SelectWorker(String)
  SelectAgent(String)
  SelectNode(String)
  SelectOverview
  OpenSecretComputeRoom
  SpatialSceneEvent(String)
  OpenReferenceInterior
  CloseSecretComputeRoom
  SelectSecretComputeEndpoint(String)
  SelectIndoorSlot(String)
  SelectSpatialWork(String)
  StartIndoorWork
  ReviewSpatialWork
  EnterEnergyBuilding(String)
  ExitEnergyBuilding
  SetEnergyWeather(EnergyWeather)
  ToggleEnergyWeatherAuto
  SetEnergyTimeScale(Int32)
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
  EnergyCanvasClick(Int32, Int32)
  OpenEnergyBuilding(String)
  OpenEcosystemAttention(String, String)
  CloseEnergyInspector
  SetDashboardSection(DashboardSection)
  SetRequestComposer(RequestComposerFocus)
  OpenWorkWorkspace(RequestComposerFocus)
  OpenTownWorkspace
  CollaborationEdit(String, String)
  CollaborationParticipantEdit(String, String, String)
  CollaborationToggleBook(String)
  CollaborationBrowseSources(String)
  CollaborationToggleSource(String)
  CollaborationReset
  CollaborationAction(String)
  CollaborationOpen(String, String)
  CollaborationReviewOpen(String, String)
  CollaborationReply(Int32, String, String)
  CollaborationDownload(String)
  CollaborationOutcomeOpen(@collaboration.OutcomeKey)
  CollaborationOutcomeDownload
  CollaborationCancel
  CollaborationDownloaded(Int32, String)
  SetRequestTitle(String)
  SetRequestPrompt(String)
  SetRequestBookId(String)
  SetRequestCadence(String)
  SetRequestQualityThreshold(String)
  SetRequestWatchMode(WatchRequestMode)
  SetRequestMaterialSources(String)
  SetRequestMaterialAcceptance(String)
  SetRequestMaterialNextAction(String)
  SubmitOperatorRequest
  OperatorRequestSubmitted(Int32, String)
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
  AvatarDraftColor(Int32)
  AvatarWizardNext
  AvatarWizardBack
  AvatarCreate
  AvatarOpenEditor
  ToggleWalkMode
  TogglePlayerFollow
  PlayerStepDirection(Int32, Int32)
  PlayerStepTo(Int32, Int32)
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
  SetOpsTab(Int32)
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
