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
    output_contract=@editor_pipeline.feature_selection_result_contract(),
    context_pages=[
      editor_feature_selection_context_path(workspace_root),
      editor_feature_selection_current_evidence_path(workspace_root),
      editor_pipeline_plan_path(
        workspace_root, "2026-05-31-editor-mode-real-pipeline",
      ),
    ],
    skill_paths=["\{workspace_root}/skills/editor-feature-rater/SKILL.md"],
    notes=[
      "Do not implement code in this step; only choose the next missing feature.",
      "Do not use a pre-baked feature list from MoonTown code. Extract candidates from the course and current UI evidence.",
      "Pick the lowest score after weighing importance, missingness, and proof value.",
    ],
    tags=["editor-pipeline", "feature-selection", "course-driven"],
    metadata=editor_feature_selection_packet_metadata(result_path),
  )
}

///|
fn editor_feature_selection_packet_metadata(result_path : String) -> Json {
  let fields : Map[String, Json] = {}
  add_planbook_bounded_wait_policy(fields)
  fields["producer"] = "moontown".to_json()
  fields["book_id"] = default_planbook_book_id().to_json()
  fields["course_book_id"] = default_wenyu_course_book_id().to_json()
  fields["step_metadata"] = editor_feature_selection_step_metadata(result_path)
  Json::object(fields)
}

///|
fn editor_feature_selection_step_metadata(result_path : String) -> Json {
  let fields = moonclaw_execution_metadata_fields(
    preferred_skills=["editor-feature-rater", "course-builder", "code-plan"],
    execution_mode="local",
    output_contract=@editor_pipeline.feature_selection_result_contract(),
  )
  add_planbook_bounded_wait_policy(fields)
  fields["kind"] = "editor_feature_selection".to_json()
  fields["source_root"] = planbook_repair_source_root().to_json()
  fields["target_files"] = editor_feature_selection_target_files().to_json()
  fields["target_pages"] = [result_path].to_json()
  Json::object(fields)
}
