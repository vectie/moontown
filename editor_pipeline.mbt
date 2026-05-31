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

///|
struct EditorPipelineModuleConfig {
  version : Int
  description : String
  modules : Array[EditorPipelineModuleConfigEntry]
} derive(Debug, Eq, FromJson)

///|
struct EditorPipelineModuleConfigEntry {
  id : String
  enabled : Bool
  title : String
  book_id : String
  district : String
  building_kind : String
  grid_x : Int
  grid_y : Int
  footprint_w : Int
  footprint_h : Int
  display_w : Int
  display_h : Int
  entrance_x : Int
  entrance_y : Int
  interior_kind : String
  style_family : String
  asset_base : String
  asset_roof : String
  protocol_pattern : String
  use_case : String
  agent_flow : String
  summary : String
} derive(Debug, Eq, FromJson)

///|
pub fn default_editor_pipeline_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-pipeline.json"
}

///|
pub fn default_editor_pipeline_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-pipeline.md"
}

///|
pub fn default_editor_placement_proposal_path(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  "\{workspace_root}/raw/editor-pipeline/placement-proposal.json"
}

///|
pub async fn write_editor_pipeline_state(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let state = inspect_editor_pipeline_state(snapshot_path, workspace_root)
  write_text_file(
    default_editor_pipeline_path(snapshot_path~),
    state.to_json().stringify(indent=2),
  )
  write_text_file(
    default_editor_pipeline_markdown_path(snapshot_path~),
    render_editor_pipeline_markdown(state),
  )
  default_editor_pipeline_path(snapshot_path~)
}

///|
pub async fn render_editor_pipeline_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  ignore(write_editor_pipeline_state(snapshot_path~, workspace_root~))
  render_editor_pipeline_markdown(
    inspect_editor_pipeline_state(snapshot_path, workspace_root),
  )
}

///|
async fn inspect_editor_pipeline_state(
  snapshot_path : String,
  workspace_root : String,
) -> EditorPipelineState {
  let plan_id = "2026-05-31-editor-mode-real-pipeline"
  let course_page = "\{default_wenyu_course_workspace_root()}/wiki/course/beginner-course.md"
  let plan_path = "\{workspace_root}/plans/\{plan_id}/plan.md"
  let plan_ready = @fs.exists(plan_path)
  let course_ready = @fs.exists(course_page)
  let command_ready = text_file_contains("cmd/main/main.mbt", "editor-pipeline")
  let ui_ready = text_file_contains(
      "ui/rabbita-town/main/main.mbt", "editor_pipeline",
    ) ||
    text_file_contains("ui/rabbita-town/main/main.mbt", "Editor Pipeline")
  let repair_status = current_editor_pipeline_repair_status(snapshot_path)
  let feature_selection_status = editor_feature_selection_stage_status(
    snapshot_path, workspace_root,
  )
  let feature_selection_summary = editor_feature_selection_stage_summary(
    workspace_root,
  )
  let lifecycle = inspect_editor_pipeline_lifecycle(
    snapshot_path, workspace_root, plan_id,
  )
  let feature_history_ready = editor_pipeline_feature_history_ready(
    workspace_root,
  )
  let movement_loops = inspect_editor_pipeline_movement_loops()
  let movement_loop_ready = editor_pipeline_movement_loop_ready(
    lifecycle, movement_loops,
  )
  let placement_diffs = inspect_editor_pipeline_placement_diffs(workspace_root)
  let placement_diff_ready = editor_pipeline_placement_diff_ready(
    lifecycle, placement_diffs,
  )
  let terrain_layers = inspect_editor_pipeline_terrain_layers()
  let terrain_reasons = inspect_editor_pipeline_terrain_reasons()
  let terrain_label_ready = editor_pipeline_terrain_label_ready(
    lifecycle, terrain_layers, terrain_reasons,
  )
  let style_candidates = inspect_editor_pipeline_style_candidates()
  let style_selection = inspect_editor_pipeline_style_selection(
    style_candidates,
  )
  let style_comparison_ready = editor_pipeline_style_comparison_ready(
    lifecycle, style_candidates, style_selection,
  )
  let stages = [
    editor_pipeline_stage(
      "course-source",
      "Course Source",
      if course_ready {
        "ready"
      } else {
        "missing"
      },
      "Wenyu game-design course teaches map labeling, mode separation, and module editing boundaries.",
      course_page,
    ),
    editor_pipeline_stage(
      "planbook-plan",
      "PlanBook Plan",
      if plan_ready {
        "ready"
      } else {
        "missing"
      },
      "Durable plan stores acceptance criteria and self-build evidence.",
      plan_path,
    ),
    editor_pipeline_stage(
      "feature-selection",
      "AI Feature Selection",
      feature_selection_status,
      feature_selection_summary,
      editor_feature_selection_result_path(workspace_root),
    ),
    editor_pipeline_stage(
      "command-contract",
      "Command Contract",
      if command_ready {
        "ready"
      } else {
        "missing"
      },
      "`moon run cmd/main -- editor-pipeline refresh|status` publishes runtime state.",
      "cmd/main/main.mbt",
    ),
    editor_pipeline_stage(
      "repair-loop",
      "Repair Loop",
      repair_status,
      "PlanBook repair packets dispatch bounded MoonClaw work and reconcile valid repair-result contracts only.",
      default_planbook_repair_path(snapshot_path~),
    ),
    editor_pipeline_stage(
      "viewport-binding",
      "Viewport Binding",
      if ui_ready {
        "ready"
      } else {
        "missing"
      },
      "Editor mode reads `editor-pipeline.json` and shows plan/source/repair/output readiness.",
      "ui/rabbita-town/main/main.mbt",
    ),
    editor_pipeline_stage(
      "building-protocol-history",
      "Building Protocol History",
      if feature_history_ready {
        "ready"
      } else {
        "missing"
      },
      "At least one module interior shows durable inbox/reduction/review/accepted-result/outbox history with building-specific evidence refs.",
      "ui/rabbita-town/main/main.mbt + .moontown/civic/protocols/<building-id>/*.jsonl",
    ),
    editor_pipeline_stage(
      "movement-loop-evidence",
      "Movement Loop Evidence",
      if movement_loop_ready {
        "ready"
      } else if lifecycle.selected_feature == "movement-loop-evidence" {
        "missing"
      } else {
        "idle"
      },
      "Editor pipeline publishes module-level home -> building entrance -> output surface -> home route proof from the Wenyu module config.",
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ),
    editor_pipeline_stage(
      "placement-diff-preview",
      "Placement Diff Preview",
      if placement_diff_ready {
        "ready"
      } else if lifecycle.selected_feature == "placement-diff-preview" {
        "missing"
      } else {
        "idle"
      },
      "Editor pipeline compares current and proposed module placements before output mode treats map edits as exportable.",
      default_editor_placement_proposal_path(workspace_root~),
    ),
    editor_pipeline_stage(
      "terrain-label-map",
      "Terrain Label Map Layers",
      if terrain_label_ready {
        "ready"
      } else if lifecycle.selected_feature == "terrain-label-map" {
        "missing"
      } else {
        "idle"
      },
      "Editor pipeline publishes terrain layers and module placement reasons from current Wenyu map/module data.",
      "ui/assets/tilemap/reference-map.json + ui/assets/tilemap/modules/wenyu-town-modules.json",
    ),
    editor_pipeline_stage(
      "style-comparison-workbench",
      "Building Style Comparison Workbench",
      if style_comparison_ready {
        "ready"
      } else if lifecycle.selected_feature == "style-comparison-workbench" {
        "missing"
      } else {
        "idle"
      },
      "Editor pipeline compares available building visual systems, records the selected style, and links the choice to durable style-sheet evidence.",
      "docs/WENYU_BUILDING_STYLE_SHEET.md + ui/assets/tilemap/buildings",
    ),
  ]
  let status = if plan_ready &&
    course_ready &&
    command_ready &&
    ui_ready &&
    feature_history_ready &&
    movement_loop_ready &&
    placement_diff_ready &&
    terrain_label_ready &&
    style_comparison_ready &&
    lifecycle.lifecycle_status == "ready-to-export" {
    "ready"
  } else {
    "needs-repair"
  }
  {
    contract: "moontown.editor_pipeline.v1",
    status,
    source_course_book: default_wenyu_course_book_id(),
    source_course_page: course_page,
    planbook_id: default_planbook_book_id(),
    plan_id,
    repair_status,
    editor_mode_url: "./viewport.html?assets=generated&mode=editor&v=editor-pipeline",
    output_mode_url: "./viewport.html?assets=generated&mode=output&v=editor-pipeline",
    generated_at_ms: @env.now(),
    stages,
    lifecycle,
    movement_loops,
    placement_diffs,
    terrain_layers,
    terrain_reasons,
    style_candidates,
    style_selection,
  }
}

///|
async fn inspect_editor_pipeline_lifecycle(
  snapshot_path : String,
  workspace_root : String,
  plan_id : String,
) -> EditorPipelineLifecycleRecord {
  let selected_feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None => {
      let output_ref = "./viewport.html?assets=generated&mode=output&v=editor-pipeline"
      return {
        change_id: "editor-pipeline-change-not-started",
        selected_feature: "none",
        title: "No selected editor change yet",
        lifecycle_status: "planned",
        summary: "No editor-pipeline change has been started yet. Run AI feature selection, then dispatch PlanBook repair before treating output mode as proof.",
        course_ref: "\{default_wenyu_course_workspace_root()}/wiki/course/beginner-course.md",
        plan_ref: "\{workspace_root}/plans/\{plan_id}/plan.md",
        repair_ref: "\{workspace_root}/raw/repair/repair-result.md",
        output_ref,
      }
    }
  }
  let repair_path = "\{workspace_root}/raw/repair/repair-result.md"
  let implementation_path = "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md"
  let output_ref = "./viewport.html?assets=generated&mode=output&v=editor-pipeline"
  let repair_text = read_text_or_empty(repair_path)
  let implementation_text = read_text_or_empty(implementation_path)
  let change_id = "editor-pipeline-\{selected_feature.selected_feature}"
  let accepted_proof = implementation_text.contains(
      "contract: moontown.editor_selected_feature_implementation.v1",
    ) &&
    implementation_text.contains(
      "selected_feature: \{selected_feature.selected_feature}",
    ) &&
    implementation_text.contains("implementation_status: accepted")
  let lifecycle_status = if accepted_proof {
    "ready-to-export"
  } else if repair_text.contains(
      "criterion_id: editor-selected-feature-implementation",
    ) {
    if repair_text.contains("repair_decision: accepted") {
      "accepted"
    } else if repair_text.contains("repair_decision: needs_external_owner") ||
      repair_text.contains("repair_decision: blocked") {
      "blocked"
    } else if repair_text.contains("repair_decision: no_change") {
      "accepted"
    } else {
      current_editor_pipeline_repair_status(snapshot_path)
    }
  } else {
    current_editor_pipeline_repair_status(snapshot_path)
  }
  let summary = match lifecycle_status {
    "planned" =>
      "The selected change is still planned. No accepted implementation proof exists yet, so output mode must not imply success."
    "running" =>
      "PlanBook repair is running for the selected change. Wait for a validated repair result before treating the output as exportable."
    "accepted" =>
      "PlanBook repair accepted the change, but export readiness still depends on the durable selected-feature proof record."
    "blocked" =>
      "The selected change is blocked or owned externally. Output mode should show the blocker instead of implying completion."
    "ready-to-export" =>
      "The selected change has validated accepted proof, and output mode can present it as export-ready."
    _ =>
      "The selected change is in an intermediate repair state. Inspect the repair task and implementation proof for the next action."
  }
  {
    change_id,
    selected_feature: selected_feature.selected_feature,
    title: selected_feature.title,
    lifecycle_status,
    summary,
    course_ref: "\{default_wenyu_course_workspace_root()}/wiki/course/beginner-course.md",
    plan_ref: "\{workspace_root}/plans/\{plan_id}/plan.md",
    repair_ref: repair_path,
    output_ref,
  }
}

///|
fn editor_pipeline_stage(
  id : String,
  title : String,
  status : String,
  summary : String,
  evidence : String,
) -> EditorPipelineStage {
  { id, title, status, summary, evidence }
}

///|
async fn current_editor_pipeline_repair_status(
  snapshot_path : String,
) -> String {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return "not-started"
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return "invalid"
  }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ => return "invalid"
  }
  if task.criterion_id != "editor-mode-real-pipeline" {
    return task.status
  }
  let refreshed = refresh_planbook_repair_task_from_run(task)
  refreshed.status
}

///|
fn render_editor_pipeline_markdown(state : EditorPipelineState) -> String {
  let lines = [
    "# Editor Pipeline Status",
    "",
    "- contract: `\{state.contract}`",
    "- status: `\{state.status}`",
    "- source_course_book: `\{state.source_course_book}`",
    "- source_course_page: `\{state.source_course_page}`",
    "- planbook_id: `\{state.planbook_id}`",
    "- plan_id: `\{state.plan_id}`",
    "- repair_status: `\{state.repair_status}`",
    "- editor_mode_url: `\{state.editor_mode_url}`",
    "- output_mode_url: `\{state.output_mode_url}`",
    "- lifecycle_status: `\{state.lifecycle.lifecycle_status}`",
    "- selected_feature: `\{state.lifecycle.selected_feature}`",
    "",
    "## Lifecycle",
    "",
    "- change_id: `\{state.lifecycle.change_id}`",
    "- title: \{state.lifecycle.title}",
    "- summary: \{state.lifecycle.summary}",
    "- course_ref: `\{state.lifecycle.course_ref}`",
    "- plan_ref: `\{state.lifecycle.plan_ref}`",
    "- repair_ref: `\{state.lifecycle.repair_ref}`",
    "- output_ref: `\{state.lifecycle.output_ref}`",
    "",
    "## Stages",
    "",
  ]
  for stage in state.stages {
    lines.push(
      "- `\{stage.id}` / `\{stage.status}`: \{stage.title} - \{stage.summary} Evidence: `\{stage.evidence}`",
    )
  }
  lines.push("")
  lines.push("## Movement Loop Evidence")
  lines.push("")
  if state.movement_loops.is_empty() {
    lines.push("- No Wenyu module movement loops are available.")
  } else {
    for loop_record in state.movement_loops {
      lines.push(
        "- `\{loop_record.module_id}` / `\{loop_record.status}`: home `\{loop_record.home_ref}` -> entrance `\{loop_record.entrance_ref}` -> output `\{loop_record.output_ref}` -> return `\{loop_record.return_ref}`. \{loop_record.missing_reason}",
      )
    }
  }
  lines.push("")
  lines.push("## Terrain Label Map")
  lines.push("")
  if state.terrain_layers.is_empty() {
    lines.push("- No terrain label layers are available.")
  } else {
    for layer_record in state.terrain_layers {
      lines.push(
        "- `\{layer_record.layer_id}` / `\{layer_record.status}`: \{layer_record.title}. \{layer_record.summary} Evidence: `\{layer_record.evidence_ref}`",
      )
    }
  }
  lines.push("")
  lines.push("### Module Terrain Reasons")
  lines.push("")
  if state.terrain_reasons.is_empty() {
    lines.push("- No module terrain reasons are available.")
  } else {
    for reason_record in state.terrain_reasons {
      lines.push(
        "- `\{reason_record.module_id}` / `\{reason_record.status}`: layer `\{reason_record.terrain_layer}` at `\{reason_record.placement_ref}`. \{reason_record.reason}",
      )
    }
  }
  lines.push("")
  lines.push("## Style Comparison Workbench")
  lines.push("")
  lines.push(
    "- target_module: `\{state.style_selection.target_module_id}` / \{state.style_selection.target_module_title}",
  )
  lines.push(
    "- selected_style: `\{state.style_selection.selected_style_id}` / \{state.style_selection.selected_style_title}",
  )
  lines.push("- status: `\{state.style_selection.status}`")
  lines.push("- critique: \{state.style_selection.critique}")
  lines.push("")
  if state.style_candidates.is_empty() {
    lines.push("- No style candidates are available.")
  } else {
    for candidate in state.style_candidates {
      lines.push(
        "- `\{candidate.style_id}` / `\{candidate.status}` / selected=`\{candidate.selected}`: \{candidate.title}. \{candidate.rationale} Tradeoff: \{candidate.tradeoff} Evidence: `\{candidate.evidence_ref}` Asset: `\{candidate.asset_ref}`",
      )
    }
  }
  lines.push("")
  lines.push("## Placement Diff Preview")
  lines.push("")
  if state.placement_diffs.is_empty() {
    lines.push("- No placement diff records are available.")
  } else {
    for diff_record in state.placement_diffs {
      lines.push(
        "- `\{diff_record.module_id}` / `\{diff_record.change_kind}` / `\{diff_record.status}`: before `\{diff_record.before_ref}` -> after `\{diff_record.after_ref}`; entrance `\{diff_record.entrance_ref}`; terrain `\{diff_record.terrain_status}`. \{diff_record.reason}",
      )
    }
  }
  lines.join("\n")
}

///|
async fn editor_pipeline_feature_history_ready(workspace_root : String) -> Bool {
  let proof_ready = read_text_or_empty(
    "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md",
  )
  let civic_status_ready = text_file_contains(
    "civic_status.mbt", "protocol_history",
  )
  let ui_ready = text_file_contains(
      "ui/rabbita-town/main/main.mbt", "Protocol History",
    ) &&
    text_file_contains(
      "ui/rabbita-town/main/main.mbt", "No protocol events yet.",
    )
  proof_ready.contains("selected_feature: building-protocol-history") ||
  (civic_status_ready && ui_ready)
}

///|
async fn inspect_editor_pipeline_movement_loops() -> Array[
  EditorPipelineMovementLoopRecord,
] {
  let config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
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
async fn load_editor_pipeline_module_config(
  path : String,
) -> EditorPipelineModuleConfig? {
  let text = read_text_or_empty(path)
  if text.trim().is_empty() {
    return None
  }
  let parsed = @json.parse(text) catch { _ => return None }
  let config : EditorPipelineModuleConfig = @json.from_json(parsed) catch {
    _ => return None
  }
  Some(config)
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

///|
async fn inspect_editor_pipeline_placement_diffs(
  workspace_root : String,
) -> Array[EditorPipelinePlacementDiffRecord] {
  let current_config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
    Some(config) => config
    None => return []
  }
  let proposal_path = default_editor_placement_proposal_path(workspace_root~)
  let proposed_config = match
    load_editor_pipeline_module_config(proposal_path) {
    Some(config) => config
    None => current_config
  }
  editor_pipeline_placement_diff_records(
    current_config.modules,
    proposed_config.modules,
  )
}

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

///|
fn editor_pipeline_module_moved(
  current : EditorPipelineModuleConfigEntry,
  proposed : EditorPipelineModuleConfigEntry,
) -> Bool {
  current.grid_x != proposed.grid_x ||
  current.grid_y != proposed.grid_y ||
  current.footprint_w != proposed.footprint_w ||
  current.footprint_h != proposed.footprint_h ||
  current.entrance_x != proposed.entrance_x ||
  current.entrance_y != proposed.entrance_y
}

///|
fn editor_pipeline_placement_ref(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  "tile:\{module_entry.grid_x},\{module_entry.grid_y}/\{module_entry.footprint_w}x\{module_entry.footprint_h}"
}

///|
fn editor_pipeline_entrance_ref(
  module_entry : EditorPipelineModuleConfigEntry,
) -> String {
  "tile:\{module_entry.entrance_x},\{module_entry.entrance_y}"
}

///|
fn editor_pipeline_placement_terrain_status(
  module_entry : EditorPipelineModuleConfigEntry,
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
fn editor_pipeline_placement_diff_ready(
  lifecycle : EditorPipelineLifecycleRecord,
  records : Array[EditorPipelinePlacementDiffRecord],
) -> Bool {
  if lifecycle.selected_feature != "placement-diff-preview" {
    return true
  }
  !records.is_empty()
}

///|
async fn inspect_editor_pipeline_terrain_layers() -> Array[
  EditorPipelineTerrainLayerRecord,
] {
  let config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
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
  let config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
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

///|
async fn inspect_editor_pipeline_style_candidates() -> Array[
  EditorPipelineStyleCandidateRecord,
] {
  let config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
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
fn editor_pipeline_selected_style_family(
  modules : Array[EditorPipelineModuleConfigEntry],
) -> String {
  for module_entry in modules {
    if module_entry.enabled && !module_entry.style_family.trim().is_empty() {
      return module_entry.style_family
    }
  }
  "white-tech-pavilion"
}

///|
fn editor_pipeline_style_title(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" => "White Tech Pavilion"
    "wenyu-pixel-backup" => "Wenyu Pixel Backup"
    "shape-label-workbench" => "Shape Label Workbench"
    _ => style_id
  }
}

///|
fn editor_pipeline_style_asset_ref(style_id : String) -> String {
  match style_id {
    "white-tech-pavilion" =>
      "ui/assets/tilemap/buildings/white-tech-pavilion/alpha"
    "wenyu-pixel-backup" => "ui/assets/tilemap/buildings/wenyu"
    "shape-label-workbench" => "ui/assets/tilemap/buildings/wenyu_shape"
    _ => "ui/assets/tilemap/buildings"
  }
}

///|
async fn inspect_editor_pipeline_style_selection(
  candidates : Array[EditorPipelineStyleCandidateRecord],
) -> EditorPipelineStyleSelectionRecord {
  let config = match
    load_editor_pipeline_module_config(
      "ui/assets/tilemap/modules/wenyu-town-modules.json",
    ) {
    Some(config) => config
    None =>
      return {
        target_module_id: "none",
        target_module_title: "No target module",
        selected_style_id: "none",
        selected_style_title: "No selected style",
        status: "missing",
        decision_ref: "ui/assets/tilemap/modules/wenyu-town-modules.json",
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
        decision_ref: "ui/assets/tilemap/modules/wenyu-town-modules.json",
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
