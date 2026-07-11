///|
async fn write_editor_feature_selection_moonclaw_profile(
  workspace_root : String,
) -> Unit {
  let path = "\{workspace_root}/moonclaw.jobs.json"
  let base = @support.read_json_file_or_empty_object(path)
  @support.write_text_file(
    path,
    @support.upsert_moonclaw_job_profile_json(
      base,
      "editor_feature_rater",
      editor_feature_rater_profile_json(workspace_root),
    ).stringify(indent=2),
  )
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
        "prompt_template": editor_feature_selection_profile_prompt_template(),
        "metadata": planbook_bounded_step_metadata_json(
          preferred_skills=[
            "editor-feature-rater", "course-builder", "code-plan",
          ],
          execution_mode="local",
          output_contract=@editor_pipeline.feature_selection_result_contract(),
          source_root=planbook_repair_source_root(),
          target_files=editor_feature_selection_target_files(),
          target_pages=[editor_feature_selection_result_path(workspace_root)],
          planning_layer="town-self-build",
          runtime_mode="bounded-selection",
          tool_access="workspace-and-repo",
        ),
      },
    ],
    "metadata": {
      "owner": "moontown-planbook",
      "purpose": "Let MoonClaw choose the next editor-mode feature from course evidence instead of hardcoding the choice in MoonTown.",
    },
  }
}
