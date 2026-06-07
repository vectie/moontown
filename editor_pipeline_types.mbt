///|
pub struct EditorPipelineStage {
  id : String
  title : String
  status : String
  summary : String
  evidence : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineLifecycleRecord {
  change_id : String
  selected_feature : String
  title : String
  lifecycle_status : String
  summary : String
  course_ref : String
  plan_ref : String
  repair_ref : String
  output_ref : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineMovementLoopRecord {
  module_id : String
  module_title : String
  book_id : String
  status : String
  home_ref : String
  entrance_ref : String
  output_ref : String
  return_ref : String
  missing_reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelinePlacementDiffRecord {
  module_id : String
  module_title : String
  change_kind : String
  status : String
  before_ref : String
  after_ref : String
  entrance_ref : String
  terrain_status : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineTerrainLayerRecord {
  layer_id : String
  title : String
  status : String
  evidence_ref : String
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineTerrainReasonRecord {
  module_id : String
  module_title : String
  terrain_layer : String
  status : String
  placement_ref : String
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineStyleCandidateRecord {
  style_id : String
  title : String
  status : String
  evidence_ref : String
  asset_ref : String
  rationale : String
  tradeoff : String
  selected : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineStyleSelectionRecord {
  target_module_id : String
  target_module_title : String
  selected_style_id : String
  selected_style_title : String
  status : String
  decision_ref : String
  critique : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct EditorPipelineState {
  contract : String
  status : String
  source_course_book : String
  source_course_page : String
  planbook_id : String
  plan_id : String
  repair_status : String
  editor_mode_url : String
  output_mode_url : String
  generated_at_ms : UInt64
  stages : Array[EditorPipelineStage]
  lifecycle : EditorPipelineLifecycleRecord
  movement_loops : Array[EditorPipelineMovementLoopRecord]
  placement_diffs : Array[EditorPipelinePlacementDiffRecord]
  terrain_layers : Array[EditorPipelineTerrainLayerRecord]
  terrain_reasons : Array[EditorPipelineTerrainReasonRecord]
  style_candidates : Array[EditorPipelineStyleCandidateRecord]
  style_selection : EditorPipelineStyleSelectionRecord
} derive(Debug, Eq, ToJson, FromJson)
