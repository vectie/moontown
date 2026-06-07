///|
fn editor_pipeline_first_enabled_module(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> EditorPipelineModuleConfigEntry? {
  for module_entry in modules {
    if module_entry.enabled {
      return Some(module_entry)
    }
  }
  None
}

///|
fn editor_pipeline_selected_style_candidate(
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
fn editor_pipeline_style_comparison_ready(
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
