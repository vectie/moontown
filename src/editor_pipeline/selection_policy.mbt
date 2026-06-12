///|
pub fn selected_style_candidate(
  candidates : Array[EditorPipelineStyleCandidateRecord],
) -> EditorPipelineStyleCandidateRecord? {
  for candidate in candidates {
    if candidate.selected {
      return Some(candidate)
    }
  }
  None
}

///|
pub fn style_comparison_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  candidates : Array[EditorPipelineStyleCandidateRecord],
  selection : EditorPipelineStyleSelectionRecord,
) -> Bool {
  if lifecycle.selected_feature != "style-comparison-workbench" {
    return true
  }
  candidates.length() >= 3 &&
  candidates.any(fn(candidate) { candidate.selected }) &&
  selection.status == "selected"
}

///|
pub fn movement_loop_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelineMovementLoopRecord],
) -> Bool {
  if lifecycle.selected_feature != "movement-loop-evidence" {
    return true
  }
  records.any(fn(record) { record.status == "ready" })
}

///|
pub fn placement_diff_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelinePlacementDiffRecord],
) -> Bool {
  if lifecycle.selected_feature != "placement-diff-preview" {
    return true
  }
  !records.is_empty()
}

///|
pub fn terrain_label_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  layers : Array[EditorPipelineTerrainLayerRecord],
  reasons : Array[EditorPipelineTerrainReasonRecord],
) -> Bool {
  if lifecycle.selected_feature != "terrain-label-map" {
    return true
  }
  !layers.is_empty() && reasons.any(fn(record) { record.status == "labeled" })
}
