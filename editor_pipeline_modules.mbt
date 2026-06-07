///|
async fn inspect_editor_pipeline_movement_loops() -> Array[
  EditorPipelineMovementLoopRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  ignore(config.version)
  ignore(config.description)
  let records : Array[EditorPipelineMovementLoopRecord] = []
  for module_entry in config.modules {
    if !module_entry.enabled {
      continue
    }
    records.push(editor_pipeline_movement_loop_for_module(module_entry))
    if records.length() >= 8 {
      break
    }
  }
  records
}

///|
fn editor_pipeline_movement_loop_for_module(
  module_entry : EditorPipelineModuleConfigEntry,
) -> EditorPipelineMovementLoopRecord {
  let home_ready = !module_entry.book_id.trim().is_empty()
  let entrance_ready = module_entry.entrance_x >= 0 &&
    module_entry.entrance_y >= 0 &&
    module_entry.footprint_w > 0 &&
    module_entry.footprint_h > 0
  let output_ready = !module_entry.id.trim().is_empty()
  let status = if home_ready && entrance_ready && output_ready {
    "ready"
  } else {
    "blocked"
  }
  let missing : Array[String] = []
  if !home_ready {
    missing.push("missing book/home binding")
  }
  if !entrance_ready {
    missing.push("missing valid entrance or footprint")
  }
  if !output_ready {
    missing.push("missing output surface binding")
  }
  let missing_reason = if missing.is_empty() {
    "complete route evidence from module config"
  } else {
    missing.join("; ")
  }
  {
    module_id: module_entry.id,
    module_title: module_entry.title,
    book_id: module_entry.book_id,
    status,
    home_ref: "book:\{module_entry.book_id}",
    entrance_ref: "tile:\{module_entry.entrance_x},\{module_entry.entrance_y}",
    output_ref: "viewport:output#\{module_entry.id}",
    return_ref: "book:\{module_entry.book_id}",
    missing_reason,
  }
}

///|
fn editor_pipeline_movement_loop_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelineMovementLoopRecord],
) -> Bool {
  if lifecycle.selected_feature != "movement-loop-evidence" {
    return true
  }
  records.any(fn(record) { record.status == "ready" })
}
