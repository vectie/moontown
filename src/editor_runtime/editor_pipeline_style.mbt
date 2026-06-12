///|
async fn inspect_editor_pipeline_style_candidates() -> Array[
  EditorPipelineStyleCandidateRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  let selected_style = editor_pipeline_selected_style_family(config.modules)
  [
    editor_pipeline_style_candidate(
      selected_style,
      editor_pipeline_style_title(selected_style),
      "docs/WENYU_BUILDING_STYLE_SHEET.md",
      editor_pipeline_style_asset_ref(selected_style),
      "Current module registry style; validates the actual visible town rather than a detached concept sheet.",
      "Best for immediate consistency, but it should still be critiqued against backup and schematic alternatives before future expansion.",
      selected_style,
    ),
    editor_pipeline_style_candidate(
      "wenyu-pixel-backup", "Wenyu Pixel Backup", "docs/WENYU_BUILDING_STYLE_SHEET.md",
      "ui/assets/tilemap/buildings/wenyu", "Existing simplified Wenyu building pack that can preserve readability if generated pavilion assets regress.",
      "Less premium and less aligned with the white-tech civic identity.", selected_style,
    ),
    editor_pipeline_style_candidate(
      "shape-label-workbench", "Shape Label Workbench", "ui/assets/tilemap/buildings/wenyu_shape",
      "ui/assets/tilemap/buildings/wenyu_shape", "Low-detail shape cells make footprint, district, and orientation comparison easy during editor-mode design review.",
      "Not suitable as final output art because it reads like a planning overlay rather than a finished town.",
      selected_style,
    ),
  ]
}

///|
async fn editor_pipeline_style_candidate(
  style_id : String,
  title : String,
  evidence_ref : String,
  asset_ref : String,
  rationale : String,
  tradeoff : String,
  selected_style : String,
) -> EditorPipelineStyleCandidateRecord {
  let status = if @fs.exists(asset_ref) || @fs.exists(evidence_ref) {
    "available"
  } else {
    "missing"
  }
  {
    style_id,
    title,
    status,
    evidence_ref,
    asset_ref,
    rationale,
    tradeoff,
    selected: style_id == selected_style,
  }
}

///|
async fn inspect_editor_pipeline_style_selection(
  candidates : Array[EditorPipelineStyleCandidateRecord],
) -> EditorPipelineStyleSelectionRecord {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None =>
      return {
        target_module_id: "none",
        target_module_title: "No target module",
        selected_style_id: "none",
        selected_style_title: "No selected style",
        status: "missing",
        decision_ref: default_editor_pipeline_module_config_ref(),
        critique: "No module config was available, so the style workbench cannot bind a decision to a civic module.",
      }
  }
  let target = match editor_pipeline_first_enabled_module(config.modules) {
    Some(module_entry) => module_entry
    None =>
      return {
        target_module_id: "none",
        target_module_title: "No enabled module",
        selected_style_id: "none",
        selected_style_title: "No selected style",
        status: "missing",
        decision_ref: default_editor_pipeline_module_config_ref(),
        critique: "No enabled Wenyu module was available for style comparison.",
      }
  }
  let selected = match editor_pipeline_selected_style_candidate(candidates) {
    Some(candidate) => candidate
    None =>
      return {
        target_module_id: target.id,
        target_module_title: target.title,
        selected_style_id: "none",
        selected_style_title: "No selected style",
        status: "missing",
        decision_ref: "docs/WENYU_BUILDING_STYLE_SHEET.md",
        critique: "Style candidates exist but none is selected by current module registry data.",
      }
  }
  {
    target_module_id: target.id,
    target_module_title: target.title,
    selected_style_id: selected.style_id,
    selected_style_title: selected.title,
    status: "selected",
    decision_ref: "docs/WENYU_BUILDING_STYLE_SHEET.md",
    critique: "Selected style matches current module config and is compared against backup pixel assets plus schematic shape cells before export.",
  }
}
