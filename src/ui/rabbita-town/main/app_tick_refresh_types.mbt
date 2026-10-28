///|
priv struct TickRefreshState {
  state_source : StateSourceKind
  projection_snapshot : ProjectionSnapshot?
  snapshot_version : Int32
  energy_valley_runtime : EnergyValleyRuntimeState
  visual_projection : VisualProjectionSnapshot?
  visual_projection_version : Int32
  module_projections : Array[BookProjectionFragment]
  module_projections_version : Int32
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
}

///|
priv struct TickRefreshVersions {
  snapshot : Int32
  energy_valley_runtime : Int32
  visual_projection : Int32
  module_projections : Int32
  moondesk_handoff : Int32
  moondesk_bridge : Int32
  daemon_snapshot : Int32
  live_autonomy : Int32
  editor_pipeline : Int32
  standing_goals : Int32
  watcher_records : Int32
  operator_requests : Int32
  book_template_requests : Int32
}
