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
  SetViewportMode(ViewportMode)
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
}
