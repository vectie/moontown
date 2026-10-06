///|
async fn inspect_editor_pipeline_lifecycle(
  snapshot_path : String,
  workspace_root : String,
  plan_id : String,
) -> EditorPipelineLifecycleRecord {
  let selected_feature = match editor_selected_feature_summary(workspace_root) {
    Some(feature) => feature
    None => {
      let output_ref = "./index.html?seed=20260727&panel=dashboard"
      return {
        change_id: "editor-pipeline-change-not-started",
        selected_feature: "none",
        title: "No selected editor change yet",
        lifecycle_status: "planned",
        summary: "No editor-pipeline change has been started yet. Run AI feature selection, then dispatch PlanBook repair before treating output mode as proof.",
        course_ref: "\{default_wenyu_course_workspace_root()}/wiki/course/beginner-course.md",
        plan_ref: editor_pipeline_plan_path(workspace_root, plan_id),
        repair_ref: planbook_repair_result_path_for_workspace(workspace_root),
        output_ref,
      }
    }
  }
  let repair_path = planbook_repair_result_path_for_workspace(workspace_root)
  let implementation_path = editor_selected_feature_implementation_path(
    workspace_root,
  )
  let output_ref = "./index.html?seed=20260727&panel=dashboard"
  let repair_text = @support.read_text_or_empty(repair_path)
  let implementation_text = @support.read_text_or_empty(implementation_path)
  let change_id = "editor-pipeline-\{selected_feature.selected_feature}"
  let accepted_proof = editor_accepted_feature_from_proof(
      workspace_root, implementation_text,
    ) ==
    Some(selected_feature.selected_feature)
  let lifecycle_status = if accepted_proof {
    "ready-to-export"
  } else if planbook_repair_result_mentions_criterion(
      repair_text, "editor-selected-feature-implementation",
    ) {
    editor_pipeline_lifecycle_status_from_repair_result(
      repair_text, snapshot_path,
    )
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
    "no_change" =>
      "No net source change; required engineering checks passed. Original-task acceptance remains unevaluated, and export readiness still requires the selected-feature proof record."
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
    plan_ref: editor_pipeline_plan_path(workspace_root, plan_id),
    repair_ref: repair_path,
    output_ref,
  }
}

///|
async fn editor_pipeline_lifecycle_status_from_repair_result(
  repair_text : String,
  snapshot_path : String,
) -> String {
  if planbook_repair_result_has_no_change_decision(repair_text) &&
    repair_text
    .split("\n")
    .any(line => {
      line.trim() ==
      "native_receipt_contract: planbook.repair.native_no_change_receipt.v1"
    }) {
    return "no_change"
  }
  if planbook_repair_result_has_accepted_decision(repair_text) ||
    planbook_repair_result_has_no_change_decision(repair_text) {
    return "accepted"
  }
  if planbook_repair_result_has_handoff_decision(repair_text) {
    return "blocked"
  }
  current_editor_pipeline_repair_status(snapshot_path)
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
  task.status
}

///|
async fn editor_pipeline_feature_history_ready(workspace_root : String) -> Bool {
  let proof = @support.read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
  )
  let native_feature = if editor_proof_has_native_provenance(proof) {
    editor_accepted_feature_from_proof(workspace_root, proof)
  } else {
    None
  }
  editor_pipeline_history_evidence_ready(
    proof,
    native_feature,
    editor_pipeline_history_source_ready(),
  )
}

///|
fn editor_pipeline_history_evidence_ready(
  proof : String,
  native_feature : String?,
  source_ready : Bool,
) -> Bool {
  let proof_ready = if editor_proof_has_native_provenance(proof) {
    native_feature == Some("building-protocol-history")
  } else {
    proof.contains("selected_feature: building-protocol-history")
  }
  proof_ready || source_ready
}

///|
async fn editor_pipeline_history_source_ready() -> Bool {
  let civic_status_ready = text_file_contains(
    "src/civic_runtime/civic_status.mbt", "protocol_history",
  )
  let ui_ready = text_file_contains(
      "src/ui/rabbita-town/main/main.mbt", "Protocol History",
    ) &&
    text_file_contains(
      "src/ui/rabbita-town/main/main.mbt", "No protocol events yet.",
    )
  civic_status_ready && ui_ready
}
