///|
fn editor_pipeline_placement_diff_records(
  current_modules : Array[EditorPipelineModuleConfigEntry],
  proposed_modules : Array[EditorPipelineModuleConfigEntry],
) -> Array[EditorPipelinePlacementDiffRecord] {
  let records : Array[EditorPipelinePlacementDiffRecord] = []
  for proposed in proposed_modules {
    if !proposed.enabled {
      continue
    }
    match editor_pipeline_find_module(current_modules, proposed.id) {
      Some(current) =>
        records.push(editor_pipeline_placement_diff_for_pair(current, proposed))
      None => records.push(editor_pipeline_placement_diff_added(proposed))
    }
  }
  for current in current_modules {
    if !current.enabled {
      continue
    }
    match editor_pipeline_find_module(proposed_modules, current.id) {
      Some(_) => ()
      None => records.push(editor_pipeline_placement_diff_removed(current))
    }
  }
  if records.is_empty() {
    for current in current_modules {
      if !current.enabled {
        continue
      }
      records.push(editor_pipeline_placement_diff_for_pair(current, current))
      if records.length() >= 8 {
        break
      }
    }
  }
  records
}

///|
fn editor_pipeline_find_module(
  modules : Array[EditorPipelineModuleConfigEntry],
  module_id : String,
) -> EditorPipelineModuleConfigEntry? {
  for module_entry in modules {
    if module_entry.enabled && module_entry.id == module_id {
      return Some(module_entry)
    }
  }
  None
}

///|
fn editor_pipeline_placement_diff_for_pair(
  current : EditorPipelineModuleConfigEntry,
  proposed : EditorPipelineModuleConfigEntry,
) -> EditorPipelinePlacementDiffRecord {
  let moved = editor_pipeline_module_moved(current, proposed)
  let terrain_status = editor_pipeline_placement_terrain_status(proposed)
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
    before_ref: editor_pipeline_placement_ref(current),
    after_ref: editor_pipeline_placement_ref(proposed),
    entrance_ref: editor_pipeline_entrance_ref(proposed),
    terrain_status,
    reason: if moved {
      "proposed placement changes grid, footprint, or entrance and must be reviewed before export"
    } else {
      "no placement diff; current module placement is explicitly represented"
    },
  }
}

///|
fn editor_pipeline_placement_diff_added(
  proposed : EditorPipelineModuleConfigEntry,
) -> EditorPipelinePlacementDiffRecord {
  let terrain_status = editor_pipeline_placement_terrain_status(proposed)
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
    after_ref: editor_pipeline_placement_ref(proposed),
    entrance_ref: editor_pipeline_entrance_ref(proposed),
    terrain_status,
    reason: "new proposed module placement must be reviewed before export",
  }
}

///|
fn editor_pipeline_placement_diff_removed(
  current : EditorPipelineModuleConfigEntry,
) -> EditorPipelinePlacementDiffRecord {
  {
    module_id: current.id,
    module_title: current.title,
    change_kind: "removed",
    status: "reviewable",
    before_ref: editor_pipeline_placement_ref(current),
    after_ref: "none",
    entrance_ref: "none",
    terrain_status: "reviewable:removed-module",
    reason: "current module is absent from proposal and should be reviewed as a removal",
  }
}
