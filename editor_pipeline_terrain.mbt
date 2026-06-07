///|
async fn inspect_editor_pipeline_terrain_layers() -> Array[
  EditorPipelineTerrainLayerRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  let layers : Array[EditorPipelineTerrainLayerRecord] = [
    editor_pipeline_terrain_layer_record(
      "water", "Water Network", "reference-map", "River, lake, canal, and waterfront constraints from the Wenyu valley base map.",
    ),
    editor_pipeline_terrain_layer_record(
      "roads", "Road and Bridge Network", "reference-map", "Road corridors, bridges, and walkable connection logic used by agent movement.",
    ),
    editor_pipeline_terrain_layer_record(
      "districts", "Civic and Innovation Districts", "module-config", "Enabled modules group into civic, innovation, community, exchange, and service districts.",
    ),
    editor_pipeline_terrain_layer_record(
      "farms", "Farms and Open Land", "reference-map", "Agriculture, market, and open development land preserved as terrain context.",
    ),
    editor_pipeline_terrain_layer_record(
      "forests", "Forest and Ecological Buffer", "reference-map", "Forest belts and river-edge buffers protect the valley identity and constrain dense building placement.",
    ),
    editor_pipeline_terrain_layer_record(
      "future-civic-module-land", "Future Civic Module Land", "module-config", "Remaining buildable terrain for new protocol buildings and PlanBook-driven extensions.",
    ),
  ]
  if config.modules.any(fn(entry) { entry.enabled }) {
    layers
  } else {
    []
  }
}

///|
fn editor_pipeline_terrain_layer_record(
  layer_id : String,
  title : String,
  source : String,
  summary : String,
) -> EditorPipelineTerrainLayerRecord {
  {
    layer_id,
    title,
    status: "labeled",
    evidence_ref: "\{source}:ui/assets/tilemap",
    summary,
  }
}

///|
async fn inspect_editor_pipeline_terrain_reasons() -> Array[
  EditorPipelineTerrainReasonRecord,
] {
  let config = match load_default_editor_pipeline_module_config() {
    Some(config) => config
    None => return []
  }
  ignore(config.version)
  ignore(config.description)
  let records : Array[EditorPipelineTerrainReasonRecord] = []
  for module_entry in config.modules {
    if !module_entry.enabled {
      continue
    }
    records.push(editor_pipeline_terrain_reason_for_module(module_entry))
    if records.length() >= 12 {
      break
    }
  }
  records
}

///|
fn editor_pipeline_terrain_reason_for_module(
  module_entry : EditorPipelineModuleConfigEntry,
) -> EditorPipelineTerrainReasonRecord {
  let terrain_layer = editor_pipeline_module_terrain_layer(module_entry)
  let footprint_ready = module_entry.footprint_w > 0 &&
    module_entry.footprint_h > 0
  let placement_ready = module_entry.grid_x >= 0 &&
    module_entry.grid_y >= 0 &&
    module_entry.entrance_x >= 0 &&
    module_entry.entrance_y >= 0
  let status = if footprint_ready && placement_ready {
    "labeled"
  } else {
    "blocked"
  }
  {
    module_id: module_entry.id,
    module_title: module_entry.title,
    terrain_layer,
    status,
    placement_ref: editor_pipeline_placement_ref(module_entry),
    reason: editor_pipeline_terrain_reason_text(module_entry, terrain_layer),
  }
}

///|
fn editor_pipeline_module_terrain_layer(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  let district = module_entry.district.to_lower()
  let kind = module_entry.building_kind.to_lower()
  if district.contains("water") ||
    district.contains("lake") ||
    district.contains("river") {
    "water"
  } else if district.contains("road") || kind.contains("bridge") {
    "roads"
  } else if district.contains("farm") || kind.contains("market") {
    "farms"
  } else if district.contains("forest") ||
    district.contains("eco") ||
    district.contains("park") {
    "forests"
  } else if district.contains("civic") ||
    district.contains("innovation") ||
    district.contains("community") ||
    district.contains("exchange") ||
    district.contains("service") {
    "districts"
  } else {
    "future-civic-module-land"
  }
}

///|
fn editor_pipeline_terrain_reason_text(
  module_entry : EditorPipelineModuleConfigEntry,
  terrain_layer : String,
) -> String {
  "Module district `\{module_entry.district}` and building kind `\{module_entry.building_kind}` map to terrain layer `\{terrain_layer}`; the editor can review this label before output export."
}

///|
fn editor_pipeline_terrain_label_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  layers : Array[EditorPipelineTerrainLayerRecord],
  reasons : Array[EditorPipelineTerrainReasonRecord],
) -> Bool {
  if lifecycle.selected_feature != "terrain-label-map" {
    return true
  }
  !layers.is_empty() && reasons.any(fn(record) { record.status == "labeled" })
}
