///|
pub fn first_enabled_module(
  modules : Array[EditorPipelineModulePlacement],
) -> EditorPipelineModulePlacement? {
  for module_entry in modules {
    if module_entry.enabled {
      return Some(module_entry)
    }
  }
  None
}

///|
pub fn selected_style_family(
  modules : Array[EditorPipelineModulePlacement],
) -> String {
  for module_entry in modules {
    if module_entry.enabled && !module_entry.style_family.trim().is_empty() {
      return module_entry.style_family
    }
  }
  "white-tech-pavilion"
}

///|
pub fn movement_loop_records(
  modules : Array[EditorPipelineModulePlacement],
  limit? : Int = 8,
) -> Array[EditorPipelineMovementLoopRecord] {
  let records : Array[EditorPipelineMovementLoopRecord] = []
  for module_entry in modules {
    if !module_entry.enabled {
      continue
    }
    records.push(movement_loop_record_for_module(module_entry))
    if records.length() >= limit {
      break
    }
  }
  records
}

///|
pub fn movement_loop_record_for_module(
  module_entry : EditorPipelineModulePlacement,
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
    entrance_ref: entrance_ref(module_entry),
    output_ref: "viewport:output#\{module_entry.id}",
    return_ref: "book:\{module_entry.book_id}",
    missing_reason,
  }
}

///|
pub fn placement_diff_records(
  current_modules : Array[EditorPipelineModulePlacement],
  proposed_modules : Array[EditorPipelineModulePlacement],
) -> Array[EditorPipelinePlacementDiffRecord] {
  let records : Array[EditorPipelinePlacementDiffRecord] = []
  for proposed in proposed_modules {
    if !proposed.enabled {
      continue
    }
    match find_module(current_modules, proposed.id) {
      Some(current) => records.push(placement_diff_for_pair(current, proposed))
      None => records.push(placement_diff_added(proposed))
    }
  }
  for current in current_modules {
    if !current.enabled {
      continue
    }
    match find_module(proposed_modules, current.id) {
      Some(_) => ()
      None => records.push(placement_diff_removed(current))
    }
  }
  if records.is_empty() {
    for current in current_modules {
      if !current.enabled {
        continue
      }
      records.push(placement_diff_for_pair(current, current))
      if records.length() >= 8 {
        break
      }
    }
  }
  records
}

///|
pub fn terrain_layers_for_modules(
  modules : Array[EditorPipelineModulePlacement],
) -> Array[EditorPipelineTerrainLayerRecord] {
  if !modules.any(fn(entry) { entry.enabled }) {
    return []
  }
  [
    terrain_layer_record(
      "water", "Water Network", "reference-map", "River, lake, canal, and waterfront constraints from the Wenyu valley base map.",
    ),
    terrain_layer_record(
      "roads", "Road and Bridge Network", "reference-map", "Road corridors, bridges, and walkable connection logic used by agent movement.",
    ),
    terrain_layer_record(
      "districts", "Civic and Innovation Districts", "module-config", "Enabled modules group into civic, innovation, community, exchange, and service districts.",
    ),
    terrain_layer_record(
      "farms", "Farms and Open Land", "reference-map", "Agriculture, market, and open development land preserved as terrain context.",
    ),
    terrain_layer_record(
      "forests", "Forest and Ecological Buffer", "reference-map", "Forest belts and river-edge buffers protect the valley identity and constrain dense building placement.",
    ),
    terrain_layer_record(
      "future-civic-module-land", "Future Civic Module Land", "module-config", "Remaining buildable terrain for new protocol buildings and PlanBook-driven extensions.",
    ),
  ]
}

///|
pub fn terrain_reason_records(
  modules : Array[EditorPipelineModulePlacement],
  limit? : Int = 12,
) -> Array[EditorPipelineTerrainReasonRecord] {
  let records : Array[EditorPipelineTerrainReasonRecord] = []
  for module_entry in modules {
    if !module_entry.enabled {
      continue
    }
    records.push(terrain_reason_for_module(module_entry))
    if records.length() >= limit {
      break
    }
  }
  records
}

///|
pub fn terrain_reason_for_module(
  module_entry : EditorPipelineModulePlacement,
) -> EditorPipelineTerrainReasonRecord {
  let terrain_layer = module_terrain_layer(module_entry)
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
    placement_ref: placement_ref(module_entry),
    reason: terrain_reason_text(module_entry, terrain_layer),
  }
}

///|
fn find_module(
  modules : Array[EditorPipelineModulePlacement],
  module_id : String,
) -> EditorPipelineModulePlacement? {
  for module_entry in modules {
    if module_entry.enabled && module_entry.id == module_id {
      return Some(module_entry)
    }
  }
  None
}

///|
fn placement_diff_for_pair(
  current : EditorPipelineModulePlacement,
  proposed : EditorPipelineModulePlacement,
) -> EditorPipelinePlacementDiffRecord {
  let moved = module_moved(current, proposed)
  let terrain_status = placement_terrain_status(proposed)
  let status = if terrain_status.has_prefix("blocked") {
    "blocked"
  } else {
    "reviewable"
  }
  {
    module_id: proposed.id,
    module_title: proposed.title,
    change_kind: if moved {
      "moved"
    } else {
      "unchanged"
    },
    status,
    before_ref: placement_ref(current),
    after_ref: placement_ref(proposed),
    entrance_ref: entrance_ref(proposed),
    terrain_status,
    reason: if moved {
      "proposed placement changes grid, footprint, or entrance and must be reviewed before export"
    } else {
      "no placement diff; current module placement is explicitly represented"
    },
  }
}

///|
fn placement_diff_added(
  proposed : EditorPipelineModulePlacement,
) -> EditorPipelinePlacementDiffRecord {
  let terrain_status = placement_terrain_status(proposed)
  {
    module_id: proposed.id,
    module_title: proposed.title,
    change_kind: "added",
    status: if terrain_status.has_prefix("blocked") {
      "blocked"
    } else {
      "reviewable"
    },
    before_ref: "none",
    after_ref: placement_ref(proposed),
    entrance_ref: entrance_ref(proposed),
    terrain_status,
    reason: "new proposed module placement must be reviewed before export",
  }
}

///|
fn placement_diff_removed(
  current : EditorPipelineModulePlacement,
) -> EditorPipelinePlacementDiffRecord {
  {
    module_id: current.id,
    module_title: current.title,
    change_kind: "removed",
    status: "reviewable",
    before_ref: placement_ref(current),
    after_ref: "none",
    entrance_ref: "none",
    terrain_status: "reviewable:removed-module",
    reason: "current module is absent from proposal and should be reviewed as a removal",
  }
}

///|
fn module_moved(
  current : EditorPipelineModulePlacement,
  proposed : EditorPipelineModulePlacement,
) -> Bool {
  current.grid_x != proposed.grid_x ||
  current.grid_y != proposed.grid_y ||
  current.footprint_w != proposed.footprint_w ||
  current.footprint_h != proposed.footprint_h ||
  current.entrance_x != proposed.entrance_x ||
  current.entrance_y != proposed.entrance_y
}

///|
fn placement_ref(module_entry : EditorPipelineModulePlacement) -> String {
  "tile:\{module_entry.grid_x},\{module_entry.grid_y}/\{module_entry.footprint_w}x\{module_entry.footprint_h}"
}

///|
fn entrance_ref(module_entry : EditorPipelineModulePlacement) -> String {
  "tile:\{module_entry.entrance_x},\{module_entry.entrance_y}"
}

///|
fn placement_terrain_status(
  module_entry : EditorPipelineModulePlacement,
) -> String {
  if module_entry.entrance_x < 0 || module_entry.entrance_y < 0 {
    return "blocked:missing-entrance"
  }
  if module_entry.footprint_w <= 0 || module_entry.footprint_h <= 0 {
    return "blocked:invalid-footprint"
  }
  "reviewable:entrance-and-footprint-present"
}

///|
fn terrain_layer_record(
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
fn module_terrain_layer(module_entry : EditorPipelineModulePlacement) -> String {
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
fn terrain_reason_text(
  module_entry : EditorPipelineModulePlacement,
  terrain_layer : String,
) -> String {
  "Module district `\{module_entry.district}` and building kind `\{module_entry.building_kind}` map to terrain layer `\{terrain_layer}`; the editor can review this label before output export."
}
