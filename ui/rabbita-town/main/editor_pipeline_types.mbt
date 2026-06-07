///|
priv struct EditorPipelineStageSnapshot {
  id : String
  title : String
  status : String
  summary : String
  evidence : String
} derive(FromJson)

///|
priv struct EditorPipelineLifecycleSnapshot {
  change_id : String
  selected_feature : String
  title : String
  lifecycle_status : String
  summary : String
  course_ref : String
  plan_ref : String
  repair_ref : String
  output_ref : String
} derive(FromJson)

///|
priv struct EditorPipelineMovementLoopSnapshot {
  module_id : String
  module_title : String
  book_id : String
  status : String
  home_ref : String
  entrance_ref : String
  output_ref : String
  return_ref : String
  missing_reason : String
} derive(FromJson)

///|
priv struct EditorPipelinePlacementDiffSnapshot {
  module_id : String
  module_title : String
  change_kind : String
  status : String
  before_ref : String
  after_ref : String
  entrance_ref : String
  terrain_status : String
  reason : String
} derive(FromJson)

///|
priv struct EditorPipelineTerrainLayerSnapshot {
  layer_id : String
  title : String
  status : String
  evidence_ref : String
  summary : String
} derive(FromJson)

///|
priv struct EditorPipelineTerrainReasonSnapshot {
  module_id : String
  module_title : String
  terrain_layer : String
  status : String
  placement_ref : String
  reason : String
} derive(FromJson)

///|
priv struct EditorPipelineStyleCandidateSnapshot {
  style_id : String
  title : String
  status : String
  evidence_ref : String
  asset_ref : String
  rationale : String
  tradeoff : String
  selected : Bool
} derive(FromJson)

///|
priv struct EditorPipelineStyleSelectionSnapshot {
  target_module_id : String
  target_module_title : String
  selected_style_id : String
  selected_style_title : String
  status : String
  decision_ref : String
  critique : String
} derive(FromJson)

///|
priv struct EditorPipelineSnapshot {
  contract : String
  status : String
  source_course_book : String
  source_course_page : String
  planbook_id : String
  plan_id : String
  repair_status : String
  editor_mode_url : String
  output_mode_url : String
  stages : Array[EditorPipelineStageSnapshot]
  lifecycle : EditorPipelineLifecycleSnapshot
  movement_loops : Array[EditorPipelineMovementLoopSnapshot]
  placement_diffs : Array[EditorPipelinePlacementDiffSnapshot]
  terrain_layers : Array[EditorPipelineTerrainLayerSnapshot]
  terrain_reasons : Array[EditorPipelineTerrainReasonSnapshot]
  style_candidates : Array[EditorPipelineStyleCandidateSnapshot]
  style_selection : EditorPipelineStyleSelectionSnapshot
} derive(FromJson)
