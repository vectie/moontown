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
  let output_ref = "./viewport.html?assets=generated&mode=output&v=editor-pipeline"
  let repair_text = @support.read_text_or_empty(repair_path)
  let implementation_text = @support.read_text_or_empty(implementation_path)
  let change_id = "editor-pipeline-\{selected_feature.selected_feature}"
  let accepted_proof = implementation_text.contains(
      "contract: \{@editor_pipeline.selected_feature_implementation_contract()}",
    ) &&
    implementation_text.contains(
      "selected_feature: \{selected_feature.selected_feature}",
    ) &&
    implementation_text.contains("implementation_status: accepted")
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
  let proof_ready = @support.read_text_or_empty(
    editor_selected_feature_implementation_path(workspace_root),
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
