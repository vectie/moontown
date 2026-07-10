///|
priv struct TickRefreshState {
  state_source : StateSourceKind
  projection_snapshot : ProjectionSnapshot?
  snapshot_version : Int
  visual_projection : VisualProjectionSnapshot?
  visual_projection_version : Int
  module_projections : Array[BookProjectionFragment]
  module_projections_version : Int
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
}

///|
priv struct TickRefreshVersions {
  snapshot : Int
  visual_projection : Int
  module_projections : Int
  moondesk_handoff : Int
  moondesk_bridge : Int
  daemon_snapshot : Int
  live_autonomy : Int
  editor_pipeline : Int
  standing_goals : Int
  watcher_records : Int
  operator_requests : Int
  book_template_requests : Int
}
