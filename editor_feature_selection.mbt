///|
pub struct EditorFeatureSelectionTask {
  id : String
  status : String
  workspace_root : String
  packet_path : String
  result_path : String
  proposal_id : String?
  run_id : String?
  summary : String
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
struct EditorSelectedFeature {
  selected_feature : String
  title : String
  score : String
  implementation_hint : String
  current_gap : String
} derive(Debug, Eq)

///|
pub fn default_editor_feature_selection_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-feature-selection.json"
}

///|
pub fn default_editor_feature_selection_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/editor-feature-selection.md"
}

///|
fn editor_feature_selection_result_path(workspace_root : String) -> String {
  "\{workspace_root}/raw/editor-pipeline/next-feature.json"
}

///|
fn editor_selected_feature_implementation_path(
  workspace_root : String,
) -> String {
  "\{workspace_root}/raw/editor-pipeline/selected-feature-implementation.md"
}

///|
fn editor_implemented_features_ledger_path(workspace_root : String) -> String {
  "\{workspace_root}/raw/editor-pipeline/implemented-features.md"
}

///|
fn editor_implemented_feature_archive_path(
  workspace_root : String,
  feature_id : String,
  suffix : String,
) -> String {
  "\{workspace_root}/raw/editor-pipeline/implemented-features/\{feature_id}.\{suffix}"
}

///|
fn editor_workspace_root_from_result_path(result_path : String) -> String {
  let pipeline_dir = @path.Path::dirname(result_path).to_string()
  let raw_dir = @path.Path::dirname(pipeline_dir).to_string()
  @path.Path::dirname(raw_dir).to_string()
}

///|
fn editor_feature_absolute_path(path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    @path.Path(planbook_repair_source_root()).join(@path.Path(path)).to_string()
  }
}

///|
pub async fn write_editor_feature_selection_task(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  dispatch? : Bool = false,
) -> String {
  let task = materialize_editor_feature_selection_task(
    snapshot_path, workspace_root, dispatch,
  )
  write_editor_feature_selection_status(task, snapshot_path)
  "Editor feature selection task `\{task.id}` is \{task.status}: \{task.summary}"
}

///|
pub async fn render_editor_feature_selection_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  ignore(workspace_root)
  let task = match load_editor_feature_selection_task(snapshot_path) {
    Some(task) => task
    None =>
      return "No editor feature selection task exists. Run `moon run cmd/main -- editor-pipeline feature-select --dispatch`."
  }
  let refreshed = refresh_editor_feature_selection_task(task)
  write_editor_feature_selection_status(refreshed, snapshot_path)
  render_editor_feature_selection_markdown(refreshed)
}

///|
pub async fn editor_feature_selection_ready(
  workspace_root? : String = default_planbook_workspace_root(),
) -> Bool {
  editor_feature_selection_result_satisfies_contract(
    read_text_or_empty(editor_feature_selection_result_path(workspace_root)),
  )
}

///|
pub async fn editor_feature_selection_evidence(
  workspace_root? : String = default_planbook_workspace_root(),
) -> String {
  let result_path = editor_feature_selection_result_path(workspace_root)
  let text = read_text_or_empty(result_path)
  if editor_feature_selection_result_satisfies_contract(text) {
    "valid AI-rated feature selection exists at `\{result_path}`"
  } else if @fs.exists(result_path) {
    "feature selection result exists at `\{result_path}`, but it does not satisfy `moontown.editor_feature_selection.v1`"
  } else {
    "no AI-rated feature selection exists at `\{result_path}`"
  }
}

///|
async fn editor_selected_feature_summary(
  workspace_root : String,
) -> EditorSelectedFeature? {
  let text = read_text_or_empty(
    editor_feature_selection_result_path(workspace_root),
  )
  let parsed = @json.parse(text) catch { _ => return None }
  match parsed {
    Object(object) =>
      Some({
        selected_feature: json_object_string(object, "selected_feature").unwrap_or(
          "unknown-feature",
        ),
        title: json_object_string(object, "title").unwrap_or("Untitled feature"),
        score: json_object_field_summary(object, "score").unwrap_or("unknown"),
        implementation_hint: json_object_string(object, "implementation_hint").unwrap_or(
          "No implementation hint was provided.",
        ),
        current_gap: json_object_string(object, "current_gap").unwrap_or(
          "No current gap was provided.",
        ),
      })
    _ => None
  }
}

///|
async fn editor_selected_feature_implementation_ready(
  workspace_root : String,
) -> Bool {
  let feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None => return false
  }
  let text = read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  text.contains("contract: moontown.editor_selected_feature_implementation.v1") &&
  text.contains("selected_feature: \{feature.selected_feature}") &&
  text.contains("implementation_status: accepted")
}

///|
async fn editor_selected_feature_implementation_evidence(
  workspace_root : String,
) -> String {
  let proof_path = editor_selected_feature_implementation_path(workspace_root)
  let feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None =>
      return "no valid AI-selected feature exists; run `moon run cmd/main -- editor-pipeline feature-select --dispatch` first"
  }
  if editor_selected_feature_implementation_ready(workspace_root) {
    "AI-selected feature `\{feature.selected_feature}` is implemented with accepted proof at `\{proof_path}`"
  } else {
    "AI selected `\{feature.selected_feature}` (`\{feature.title}`) with score \{feature.score}; implementation proof is missing at `\{proof_path}`. Gap: \{feature.current_gap}"
  }
}

///|
async fn editor_selected_feature_implementation_next_action(
  workspace_root : String,
) -> String {
  match editor_selected_feature_summary(workspace_root) {
    Some(feature) =>
      "run `moon run cmd/main -- planbook repair --dispatch`; repair must read `raw/editor-pipeline/next-feature.json`, implement `\{feature.selected_feature}` using the AI acceptance criteria, and write `raw/editor-pipeline/selected-feature-implementation.md`"
    None =>
      "run `moon run cmd/main -- editor-pipeline feature-select --dispatch` before implementation repair"
  }
}

///|
async fn editor_feature_selection_stage_status(
  snapshot_path : String,
  workspace_root : String,
) -> String {
  if editor_feature_selection_ready(workspace_root~) {
    return "ready"
  }
  match load_editor_feature_selection_task(snapshot_path) {
    Some(task) => refresh_editor_feature_selection_task(task).status
    None => "not-started"
  }
}

///|
async fn editor_feature_selection_stage_summary(
  workspace_root : String,
) -> String {
  if editor_feature_selection_ready(workspace_root~) {
    "MoonClaw selected the next missing editor feature from course evidence."
  } else {
    "No valid AI-rated next-feature selection has been produced yet."
  }
}

///|
async fn materialize_editor_feature_selection_task(
  snapshot_path : String,
  workspace_root : String,
  dispatch : Bool,
) -> EditorFeatureSelectionTask {
  ignore(snapshot_path)
  let workspace_root = editor_feature_absolute_path(workspace_root)
  let task_id = "editor-feature-selection"
  let packet_path = "\{workspace_root}/raw/editor-pipeline/\{task_id}.packet.json"
  let result_path = editor_feature_selection_result_path(workspace_root)
  write_editor_feature_selection_workspace(workspace_root)
  let packet = editor_feature_selection_packet(task_id, result_path)
  let mut proposal_id : String? = None
  let mut run_id : String? = None
  let mut status = "queued"
  let mut summary = "Queued bounded MoonClaw selection packet. The AI must read the course book and choose the lowest-scoring missing editor feature; Moontown does not choose the feature name."
  if dispatch {
    let imported = @moonclaw.import_packet(
      packet,
      packet_path,
      home="\{workspace_root}/.moonclaw",
      cwd=workspace_root,
      confirm=true,
      run_inline=moontown_moonclaw_inline_enabled(),
    ) catch {
      error =>
        return {
          id: task_id,
          status: "blocked",
          workspace_root,
          packet_path,
          result_path,
          proposal_id: None,
          run_id: None,
          summary: "MoonClaw feature-selection dispatch failed: \{error}",
          generated_at_ms: @env.now(),
        }
    }
    proposal_id = Some(imported.proposal_id)
    run_id = imported.run_id
    let launch_command = match imported.run_id {
      Some(run_id) if !moontown_moonclaw_inline_enabled() =>
        Some(
          @moonclaw.run_confirmed_run(
            run_id,
            home="\{workspace_root}/.moonclaw",
            cwd=workspace_root,
          ),
        )
      _ => None
    }
    status = if imported.run_id is Some(_) { "dispatched" } else { "queued" }
    summary = match launch_command {
      Some(command) => "\{imported.summary} Detached runner: \{command}"
      None => imported.summary
    }
  } else {
    @moonclaw.save_packet_file(packet_path, packet)
  }
  {
    id: task_id,
    status,
    workspace_root,
    packet_path,
    result_path,
    proposal_id,
    run_id,
    summary,
    generated_at_ms: @env.now(),
  }
}

///|
async fn write_editor_feature_selection_workspace(
  workspace_root : String,
) -> Unit {
  record_accepted_editor_feature_if_present(workspace_root)
  write_text_file(
    "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    planbook_editor_pipeline_plan_markdown(),
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/FEATURE_SELECTION_CONTEXT.md",
    editor_feature_selection_context_markdown(workspace_root),
  )
  write_text_file(
    "\{workspace_root}/raw/editor-pipeline/CURRENT_UI_EVIDENCE.md",
    editor_feature_selection_current_evidence_markdown(workspace_root),
  )
  write_text_file(
    "\{workspace_root}/skills/editor-feature-rater/SKILL.md",
    editor_feature_rater_skill_markdown(),
  )
  write_editor_feature_selection_moonclaw_profile(workspace_root)
}

///|
async fn record_accepted_editor_feature_if_present(
  workspace_root : String,
) -> Unit {
  let feature_id = match editor_current_accepted_feature_id(workspace_root) {
    Some(feature_id) => feature_id
    None => return
  }
  let ledger_path = editor_implemented_features_ledger_path(workspace_root)
  let current_ledger = read_text_or_empty(ledger_path)
  let entry = "- `\{feature_id}`"
  if !current_ledger.contains(entry) {
    let next_ledger = if current_ledger.trim().is_empty() {
      [
        "# Implemented Editor Features", "", "This file is Moontown's durable exclusion ledger for iterative AI feature selection. Features listed here must not be selected again by `editor-feature-rater`.",
        "", entry,
      ].join("\n")
    } else {
      "\{current_ledger.trim().to_owned()}\n\{entry}"
    }
    write_text_file(ledger_path, next_ledger)
  }
  let selection = read_text_or_empty(
    editor_feature_selection_result_path(workspace_root),
  )
  if !selection.trim().is_empty() {
    write_text_file(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "selection.json",
      ),
      selection,
    )
  }
  let proof = read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  if !proof.trim().is_empty() {
    write_text_file(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "implementation.md",
      ),
      proof,
    )
  }
}

///|
async fn editor_current_accepted_feature_id(workspace_root : String) -> String? {
  let text = read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  if !text.contains(
      "contract: moontown.editor_selected_feature_implementation.v1",
    ) ||
    !text.contains("implementation_status: accepted") {
    return None
  }
  markdown_field_value(text, "selected_feature")
}

///|
async fn editor_accepted_feature_ids(workspace_root : String) -> Array[String] {
  let ids : Array[String] = []
  let ledger = read_text_or_empty(
    editor_implemented_features_ledger_path(workspace_root),
  )
  for raw in ledger.split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix("- `") {
      let id = line.trim(chars="- `").to_owned()
      if !id.trim().is_empty() && !ids.contains(id) {
        ids.push(id)
      }
    }
  }
  match editor_current_accepted_feature_id(workspace_root) {
    Some(id) if !ids.contains(id) => ids.push(id)
    _ => ()
  }
  ids
}

///|
async fn editor_accepted_features_markdown(workspace_root : String) -> String {
  let ids = editor_accepted_feature_ids(workspace_root)
  if ids.length() == 0 {
    return "- none"
  }
  let lines : Array[String] = []
  for id in ids {
    lines.push("- `\{id}`")
  }
  lines.join("\n")
}

///|
fn markdown_field_value(text : String, field : String) -> String? {
  let key_colon = "\{field}:"
  let key_equals = "\{field} ="
  for raw in text.split("\n") {
    let line = raw.trim().to_owned()
    if line.has_prefix(key_colon) {
      return Some(line[key_colon.length():].trim(chars=" `").to_owned())
    }
    if line.has_prefix(key_equals) {
      return Some(line[key_equals.length():].trim(chars=" `").to_owned())
    }
  }
  None
}

///|
async fn write_editor_feature_selection_moonclaw_profile(
  workspace_root : String,
) -> Unit {
  let path = "\{workspace_root}/moonclaw.jobs.json"
  let base = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  let root = json_object_copy(Some(base))
  let jobs = json_object_copy(root.get("jobs"))
  let profiles = json_object_copy(jobs.get("profiles"))
  profiles["editor_feature_rater"] = editor_feature_rater_profile_json(
    workspace_root,
  )
  jobs["profiles"] = Json::object(profiles)
  root["jobs"] = Json::object(jobs)
  write_text_file(path, Json::object(root).stringify(indent=2))
}

///|
fn editor_feature_rater_profile_json(workspace_root : String) -> Json {
  {
    "family": "editor_feature_rater",
    "role": "worker",
    "priority": 170,
    "tags": ["editor-pipeline", "course", "feature-selection"],
    "match": {
      "all": ["editor-pipeline", "feature-selection"],
      "any": ["course", "missing-feature", "rating"],
    },
    "steps": [
      {
        "id": "rate_missing_editor_feature",
        "title": "Rate missing editor features from the course book",
        "kind": "job.analysis",
        "prompt_template": "You are the AI feature rater for Moontown's Wenyu editor-mode pipeline. Read skill_paths and context_pages from step metadata, then read the exact target_files before any broader search. Prefer CURRENT_UI_EVIDENCE.md over large UI source files unless compact evidence is insufficient. Exclude already implemented features listed in FEATURE_SELECTION_CONTEXT.md. Choose the single lowest-scoring missing course-backed editor feature. Write the exact target_pages path with the moontown.editor_feature_selection.v1 contract.",
        "metadata": {
          "preferred_skills": [
            "editor-feature-rater", "course-builder", "code-plan",
          ],
          "enable_tools": true,
          "execution_mode": "local",
          "output_contract": "moontown.editor_feature_selection.v1",
          "source_root": planbook_repair_source_root(),
          "target_files": editor_feature_selection_target_files(),
          "target_pages": [editor_feature_selection_result_path(workspace_root)],
          "disable_waiting_for_input": true,
          "best_effort_on_missing_input": true,
          "best_effort_on_timeout": false,
          "timeout_ms": 600000,
          "role_runtime": {
            "planning_layer": "town-self-build",
            "runtime_mode": "bounded-selection",
            "tool_access": "workspace-and-repo",
            "memory_scope": "planbook",
            "allow_delegate": false,
            "allow_workspace_write": true,
            "allow_execution_tools": true,
            "output_contract": "moontown.editor_feature_selection.v1",
          },
        },
      },
    ],
    "metadata": {
      "owner": "moontown-planbook",
      "purpose": "Let MoonClaw choose the next editor-mode feature from course evidence instead of hardcoding the choice in Moontown.",
    },
  }
}

///|
fn editor_feature_selection_packet(
  task_id : String,
  result_path : String,
) -> @moonclaw.ExternalProposalPacket {
  let workspace_root = editor_workspace_root_from_result_path(result_path)
  @moonclaw.ExternalProposalPacket::new(
    packet_id=task_id,
    title="Select the next missing Wenyu editor-mode feature",
    summary="AI-rated feature selection from the existing Wenyu game-design course book.",
    request_text=editor_feature_selection_request_text(result_path),
    profile="editor_feature_rater",
    output_contract="moontown.editor_feature_selection.v1",
    context_pages=[
      "\{workspace_root}/raw/editor-pipeline/FEATURE_SELECTION_CONTEXT.md",
      "\{workspace_root}/raw/editor-pipeline/CURRENT_UI_EVIDENCE.md",
      "\{workspace_root}/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    ],
    skill_paths=["\{workspace_root}/skills/editor-feature-rater/SKILL.md"],
    notes=[
      "Do not implement code in this step; only choose the next missing feature.",
      "Do not use a pre-baked feature list from Moontown code. Extract candidates from the course and current UI evidence.",
      "Pick the lowest score after weighing importance, missingness, and proof value.",
    ],
    tags=["editor-pipeline", "feature-selection", "course-driven"],
    metadata={
      "producer": "moontown".to_json(),
      "book_id": default_planbook_book_id().to_json(),
      "course_book_id": default_wenyu_course_book_id().to_json(),
      "disable_waiting_for_input": true.to_json(),
      "best_effort_on_missing_input": true.to_json(),
      "best_effort_on_timeout": false.to_json(),
      "timeout_ms": planbook_repair_timeout_ms_json(),
      "step_metadata": {
        "kind": "editor_feature_selection".to_json(),
        "execution_mode": "local".to_json(),
        "output_contract": "moontown.editor_feature_selection.v1".to_json(),
        "preferred_skills": [
          "editor-feature-rater", "course-builder", "code-plan",
        ].to_json(),
        "source_root": planbook_repair_source_root().to_json(),
        "target_files": editor_feature_selection_target_files().to_json(),
        "target_pages": [result_path].to_json(),
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
        "best_effort_on_timeout": false.to_json(),
        "timeout_ms": planbook_repair_timeout_ms_json(),
      },
    },
  )
}

///|
fn editor_feature_selection_target_files() -> Array[String] {
  let root = planbook_repair_source_root()
  [
    "\{root}/.moontown/books/course-wenyu-game-design/wiki/course/beginner-course.md",
    "\{root}/.moontown/books/course-wenyu-game-design/wiki/course/exercises.md",
    "\{root}/.moontown/books/course-wenyu-game-design/wiki/course/progress-rubric.md",
    "\{root}/.moontown/books/plan-moontown-quality/plans/2026-05-31-editor-mode-real-pipeline/plan.md",
    "\{root}/.moontown/books/plan-moontown-quality/raw/editor-pipeline/implemented-features.md",
    "\{root}/.moontown/books/plan-moontown-quality/raw/editor-pipeline/selected-feature-implementation.md",
    "\{root}/.moontown/books/plan-moontown-quality/raw/editor-pipeline/CURRENT_UI_EVIDENCE.md",
    "\{root}/docs/WENYU_UI_MODULE_SYSTEM.md",
  ]
}

///|
fn editor_feature_selection_target_files_markdown() -> String {
  let lines : Array[String] = []
  for path in editor_feature_selection_target_files() {
    lines.push("- `\{path}`")
  }
  lines.join("\n")
}

///|
fn editor_feature_selection_request_text(result_path : String) -> String {
  [
    "You are the AI feature rater for Moontown's Wenyu editor-mode pipeline.",
    "",
    "Goal: choose the single most important missing editor-mode feature from the existing Wenyu game-design course book and current UI evidence.",
    "",
    "Rules:",
    "1. Read the absolute `skills/editor-feature-rater/SKILL.md` path from `skill_paths` first.",
    "2. Read the exact target files before any broad search. Prefer `CURRENT_UI_EVIDENCE.md` for current UI/runtime evidence instead of opening large UI source files unless compact evidence is insufficient.",
    "3. Extract candidate features from the course, exercises, rubric, and current editor/output UI evidence. Do not rely on a hardcoded candidate list from Moontown.",
    "4. Read the absolute `FEATURE_SELECTION_CONTEXT.md` path from `context_pages` and exclude every feature listed under `Already Implemented Features`; do not select those features again.",
    "5. Score each remaining candidate from 1 to 10, where 1 means critically missing and high leverage, and 10 means already strong enough.",
    "6. Select the lowest-scoring remaining candidate. Break ties by choosing the candidate that best proves the editor-mode pipeline can become real implementation work.",
    "7. Do not edit source code in this step.",
    "8. Write JSON to `\{result_path}`. Also return the same JSON as the final answer.",
    "",
    "Target files:",
    editor_feature_selection_target_files_markdown(),
  ].join("\n")
}

///|
async fn editor_feature_selection_context_markdown(
  workspace_root : String,
) -> String {
  [
    "# Editor Feature Selection Context",
    "",
    "- Owner: Moontown PlanBook",
    "- Course book: `\{default_wenyu_course_book_id()}`",
    "- Course root: `\{default_wenyu_course_workspace_root()}`",
    "- PlanBook root: `\{workspace_root}`",
    "- Output contract: `moontown.editor_feature_selection.v1`",
    "",
    "## Intent",
    "",
    "The town must prove that it can ask an AI worker to inspect existing course material, identify what editor-mode feature is most important and most missing, and produce a durable selection artifact. Moontown should not hardcode the feature choice.",
    "",
    "## Current Boundary",
    "",
    "This step selects the next feature only. A later PlanBook repair step may turn the selected feature into code.",
    "",
    "## Already Implemented Features",
    "",
    editor_accepted_features_markdown(workspace_root),
    "",
    "The feature rater must treat every listed feature as implemented evidence and exclude it from the next selection. If all obvious features are already implemented, it should identify the next weakest course-backed feature rather than repeating an accepted one.",
  ].join("\n")
}

///|
async fn editor_feature_selection_current_evidence_markdown(
  workspace_root : String,
) -> String {
  let ui_path = "ui/rabbita-town/main/main.mbt"
  let pipeline_path = "editor_pipeline.mbt"
  let docs_path = "docs/WENYU_UI_MODULE_SYSTEM.md"
  let pipeline_state = bool_label(
    text_file_contains(pipeline_path, "EditorPipelineState"),
  )
  let lifecycle_record = bool_label(
    text_file_contains(pipeline_path, "EditorPipelineLifecycleRecord"),
  )
  let movement_record = bool_label(
    text_file_contains(pipeline_path, "EditorPipelineMovementLoopRecord"),
  )
  let placement_record = bool_label(
    text_file_contains(pipeline_path, "EditorPipelinePlacementDiffRecord"),
  )
  let editor_panel = bool_label(
    text_file_contains(ui_path, "render_editor_pipeline_panel"),
  )
  let movement_panel = bool_label(
    text_file_contains(ui_path, "Movement Loop Evidence"),
  )
  let placement_panel = bool_label(
    text_file_contains(ui_path, "Placement Diff Preview"),
  )
  let module_validation = bool_label(
    text_file_contains(ui_path, "module_validation_issues"),
  )
  let style_family = bool_label(text_file_contains(ui_path, "style_family"))
  let output_lifecycle = bool_label(
    text_file_contains(ui_path, "render_output_lifecycle_panel"),
  )
  let docs_validation = bool_label(text_file_contains(docs_path, "validation"))
  let docs_placement_diff = bool_label(
    text_file_contains(docs_path, "placement diff"),
  )
  let docs_prompt = bool_label(text_file_contains(docs_path, "prompt"))
  [
    "# Current Editor UI Evidence",
    "",
    "- Generated by: `moontown`",
    "- PlanBook root: `\{workspace_root}`",
    "- Purpose: compact current-state evidence for AI feature selection. Use this before opening large UI source files.",
    "",
    "## Implemented Runtime Surfaces",
    "",
    "- command contract: `moon run cmd/main -- editor-pipeline refresh|status|feature-select`",
    "- state contract file: `.moontown/editor-pipeline.json`",
    "- accepted lifecycle proof: `selected-feature-implementation.md`",
    "- implemented-feature ledger: `implemented-features.md`",
    "",
    "## Code Evidence",
    "",
    "- editor pipeline state exists: `\{pipeline_state}`",
    "- lifecycle records exist: `\{lifecycle_record}`",
    "- movement-loop records exist: `\{movement_record}`",
    "- placement-diff records exist: `\{placement_record}`",
    "- viewport editor pipeline panel exists: `\{editor_panel}`",
    "- movement-loop panel exists: `\{movement_panel}`",
    "- placement-diff panel exists: `\{placement_panel}`",
    "- module validation issues exist: `\{module_validation}`",
    "- style family is visible in module config/runtime structs: `\{style_family}`",
    "- output mode lifecycle panel exists: `\{output_lifecycle}`",
    "",
    "## Course-Backed Remaining Candidate Areas",
    "",
    "- terrain-label evidence: course Lesson 1 expects a terrain label map with water, roads, districts, farms, forests, and future civic-module layers.",
    "- style comparison evidence: course exercises expect at least three building visual systems to be evaluated.",
    "- editor writeback/export: docs still describe designer preview and export/writeback as future stage work.",
    "- civic-service execution maturity: frontend docs say buildings still need repeated live service runs, accepted MoonBook updates, and structured review/change history.",
    "",
    "## Documentation Signals",
    "",
    "- Wenyu module docs mention validation: `\{docs_validation}`",
    "- Wenyu module docs mention placement diff/export: `\{docs_placement_diff}`",
    "- Wenyu module docs mention style prompts: `\{docs_prompt}`",
    "",
    "## Selection Guidance",
    "",
    "- Do not select any feature already listed in `FEATURE_SELECTION_CONTEXT.md`.",
    "- Prefer the weakest course-backed gap that can be implemented in one bounded repair packet.",
    "- The selected feature should improve the editor pipeline, not just add cosmetic polish.",
  ].join("\n")
}

///|
fn bool_label(value : Bool) -> String {
  if value {
    "yes"
  } else {
    "no"
  }
}

///|
fn editor_feature_rater_skill_markdown() -> String {
  [
    "---", "name: editor-feature-rater", "description: Read course material and current UI evidence, rate missing editor-mode features, and select the lowest-scoring/highest-priority next implementation target.",
    "---", "", "# Editor Feature Rater Skill", "", "You choose the next editor-mode implementation target from evidence, not from a fixed list.",
    "", "## Required Output", "", "Write `raw/editor-pipeline/next-feature.json` as JSON with this shape:",
    "", "```json", "{", "  \"contract\": \"moontown.editor_feature_selection.v1\",",
    "  \"selected_feature\": \"short kebab-case id\",", "  \"title\": \"human-readable feature title\",",
    "  \"score\": 1,", "  \"why_lowest\": \"why this is the weakest/highest-leverage missing feature\",",
    "  \"excluded_implemented_features\": [\"feature ids excluded because they are already accepted\"],",
    "  \"course_evidence\": [\"course page or exercise path plus short reason\"],",
    "  \"current_gap\": \"what current UI/pipeline lacks\",", "  \"implementation_hint\": \"smallest next code slice\",",
    "  \"acceptance\": [\"observable acceptance criterion\"],", "  \"rejected_candidates\": [",
    "    {\"feature\":\"candidate id\",\"score\":5,\"reason\":\"why not selected\"}",
    "  ]", "}", "```", "", "## Scoring Rubric", "", "- `1-2`: essential course requirement, visibly missing, and ideal for proving PlanBook-to-code execution.",
    "- `3-4`: important and partly missing, but not the best proof target.", "- `5-7`: useful but already partially represented or less central.",
    "- `8-10`: already strong enough or not relevant to editor mode.", "", "## Quality Rules",
    "", "- Use the existing course pages as source of truth.", "- Prefer features that make editor mode a real pipeline, not cosmetic UI polish.",
    "- Exclude features already listed in `FEATURE_SELECTION_CONTEXT.md`; repeating an accepted feature is an invalid selection.",
    "- Read `CURRENT_UI_EVIDENCE.md` before opening large UI source files. It is generated from current runtime/code evidence and should be sufficient for normal feature selection.",
    "- Prefer file-only completion: write `next-feature.json` first, then return the same concise JSON.",
    "- Name specific evidence paths.", "- Keep the implementation hint bounded enough for one repair packet.",
    "- If evidence is insufficient, still choose the best-supported candidate and state the uncertainty.",
  ].join("\n")
}

///|
async fn write_editor_feature_selection_status(
  task : EditorFeatureSelectionTask,
  snapshot_path : String,
) -> Unit {
  write_text_file(
    default_editor_feature_selection_path(snapshot_path~),
    task.to_json().stringify(indent=2),
  )
  write_text_file(
    default_editor_feature_selection_markdown_path(snapshot_path~),
    render_editor_feature_selection_markdown(task),
  )
}

///|
async fn load_editor_feature_selection_task(
  snapshot_path : String,
) -> EditorFeatureSelectionTask? {
  let path = default_editor_feature_selection_path(snapshot_path~)
  if !@fs.exists(path) {
    return None
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ => return None
  }
  match parsed {
    Object(object) =>
      Some({
        id: json_object_string(object, "id").unwrap_or(
          "editor-feature-selection",
        ),
        status: json_object_string(object, "status").unwrap_or("unknown"),
        workspace_root: json_object_string(object, "workspace_root").unwrap_or(
          default_planbook_workspace_root(),
        ),
        packet_path: json_object_string(object, "packet_path").unwrap_or(""),
        result_path: json_object_string(object, "result_path").unwrap_or(
          editor_feature_selection_result_path(
            default_planbook_workspace_root(),
          ),
        ),
        proposal_id: json_object_string(object, "proposal_id"),
        run_id: json_object_string(object, "run_id"),
        summary: json_object_string(object, "summary").unwrap_or(""),
        generated_at_ms: 0,
      })
    _ => None
  }
}

///|
fn json_object_field_summary(
  object : Map[String, Json],
  key : String,
) -> String? {
  match object.get(key) {
    Some(value) => Some(value.stringify())
    None => None
  }
}

///|
async fn refresh_editor_feature_selection_task(
  task : EditorFeatureSelectionTask,
) -> EditorFeatureSelectionTask {
  if @fs.exists(task.result_path) &&
    editor_feature_selection_result_satisfies_contract(
      read_text_or_empty(task.result_path),
    ) {
    return {
      ..task,
      status: "completed",
      summary: "MoonClaw wrote a valid editor feature selection result.",
    }
  }
  let run_id = match task.run_id {
    Some(run_id) => run_id
    None => return task
  }
  let content = editor_feature_selection_result_text_from_run(task, run_id)
  if editor_feature_selection_result_satisfies_contract(content) {
    write_text_file(task.result_path, content)
    return {
      ..task,
      status: "completed",
      summary: "Recovered valid editor feature selection from MoonClaw run `\{run_id}`.",
    }
  }
  task
}

///|
async fn editor_feature_selection_result_text_from_run(
  task : EditorFeatureSelectionTask,
  run_id : String,
) -> String {
  let workspace_dir = match
    @moonclaw.run_workspace_dir(run_id, cwd=task.workspace_root) {
    Some(workspace_dir) => workspace_dir
    None => return ""
  }
  let result_path = "\{workspace_dir}/result.json"
  if !@fs.exists(result_path) {
    return ""
  }
  let parsed = @json.parse(@fs.read_file(result_path).text()) catch {
    _ => return ""
  }
  json_string_field(parsed, "content").unwrap_or("")
}

///|
fn editor_feature_selection_result_satisfies_contract(text : String) -> Bool {
  text.contains("moontown.editor_feature_selection.v1") &&
  text.contains("selected_feature") &&
  text.contains("score") &&
  text.contains("implementation_hint") &&
  text.contains("acceptance")
}

///|
async fn editor_feature_selection_result_summary(
  result_path : String,
) -> String {
  let text = read_text_or_empty(result_path)
  if text == "" {
    return "No result has been written yet."
  }
  if editor_feature_selection_result_satisfies_contract(text) {
    "Valid selection contract exists at `\{result_path}`."
  } else {
    "Result exists at `\{result_path}`, but it does not satisfy `moontown.editor_feature_selection.v1`."
  }
}

///|
async fn render_editor_feature_selection_markdown(
  task : EditorFeatureSelectionTask,
) -> String {
  [
    "# Editor Feature Selection",
    "",
    "- contract: `moontown.editor_feature_selection.task.v1`",
    "- task: `\{task.id}`",
    "- status: `\{task.status}`",
    "- workspace: `\{task.workspace_root}`",
    "- packet: `\{task.packet_path}`",
    "- result: `\{task.result_path}`",
    "- proposal: `\{task.proposal_id.unwrap_or("none")}`",
    "- run: `\{task.run_id.unwrap_or("none")}`",
    "",
    "## Summary",
    "",
    task.summary,
    "",
    "## Result",
    "",
    editor_feature_selection_result_summary(task.result_path),
  ].join("\n")
}
