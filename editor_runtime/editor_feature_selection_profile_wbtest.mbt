///|
test "editor feature selection request centralizes AI rating policy" {
  let text = editor_feature_selection_request_text(
    "/tmp/planbook/raw/editor-pipeline/next-feature.json",
  )
  assert_true(
    text.contains(
      "You are the AI feature rater for Moontown's Wenyu editor-mode pipeline.",
    ),
  )
  assert_true(
    text.contains("Read the absolute `skills/editor-feature-rater/SKILL.md`"),
  )
  assert_true(text.contains("Prefer `CURRENT_UI_EVIDENCE.md`"))
  assert_true(text.contains("Do not rely on a hardcoded candidate list"))
  assert_true(text.contains("FEATURE_SELECTION_CONTEXT.md"))
  assert_true(text.contains("Score each remaining candidate from 1 to 10"))
  assert_true(text.contains("Select the lowest-scoring remaining candidate"))
  assert_true(text.contains("Do not edit source code in this step."))
  assert_true(
    text.contains("/tmp/planbook/raw/editor-pipeline/next-feature.json"),
  )
}

///|
test "editor feature rater profile uses shared prompt and bounded metadata" {
  let profile = editor_feature_rater_profile_json("/tmp/planbook").stringify()
  assert_true(profile.contains("\"family\":\"editor_feature_rater\""))
  assert_true(profile.contains("\"prompt_template\""))
  assert_true(profile.contains("CURRENT_UI_EVIDENCE.md"))
  assert_true(profile.contains("FEATURE_SELECTION_CONTEXT.md"))
  assert_true(
    profile.contains(@editor_pipeline.feature_selection_result_contract()),
  )
  assert_true(profile.contains("\"runtime_mode\":\"bounded-selection\""))
  assert_true(profile.contains("\"planning_layer\":\"town-self-build\""))
  assert_true(profile.contains("\"editor-feature-rater\""))
}
