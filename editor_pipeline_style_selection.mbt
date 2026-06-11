///|
fn editor_pipeline_first_enabled_module(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> EditorPipelineModuleConfigEntry? {
  let placement = match
    @editor_pipeline.first_enabled_module(
      editor_pipeline_module_placements(modules),
    ) {
    Some(placement) => placement
    None => return None
  }
  for module_entry in modules {
    if module_entry.id == placement.id {
      return Some(module_entry)
    }
  }
  None
}

///|
fn editor_pipeline_selected_style_candidate(
  candidates : Array[EditorPipelineStyleCandidateRecord],
) -> EditorPipelineStyleCandidateRecord? {
  @editor_pipeline.selected_style_candidate(candidates)
}

///|
fn editor_pipeline_style_comparison_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  candidates : Array[EditorPipelineStyleCandidateRecord],
  selection : EditorPipelineStyleSelectionRecord,
) -> Bool {
  @editor_pipeline.style_comparison_ready(lifecycle, candidates, selection)
}
