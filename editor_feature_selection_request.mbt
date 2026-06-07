///|
fn editor_feature_selection_target_files() -> Array[String] {
  let root = planbook_repair_source_root()
  let planbook_root = planbook_workspace_root_for_source_root(root)
  let course_root = wenyu_course_workspace_root_for_source_root(root)
  [
    "\{course_root}/wiki/course/beginner-course.md",
    "\{course_root}/wiki/course/exercises.md",
    "\{course_root}/wiki/course/progress-rubric.md",
    editor_pipeline_plan_path(
      planbook_root, "2026-05-31-editor-mode-real-pipeline",
    ),
    editor_implemented_features_ledger_path(planbook_root),
    editor_selected_feature_implementation_path(planbook_root),
    editor_feature_selection_current_evidence_path(planbook_root),
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
    editor_feature_selection_role_prompt(),
    "",
    editor_feature_selection_goal_prompt(),
    "",
    "Rules:",
    editor_feature_selection_request_rules(result_path).join("\n"),
    "",
    "Target files:",
    editor_feature_selection_target_files_markdown(),
  ].join("\n")
}

///|
fn editor_feature_selection_role_prompt() -> String {
  "You are the AI feature rater for Moontown's Wenyu editor-mode pipeline."
}

///|
fn editor_feature_selection_goal_prompt() -> String {
  "Goal: choose the single most important missing editor-mode feature from the existing Wenyu game-design course book and current UI evidence."
}

///|
fn editor_feature_selection_request_rules(
  result_path : String,
) -> Array[String] {
  [
    "1. \{editor_feature_selection_skill_first_rule()}",
    "2. \{editor_feature_selection_target_files_rule()}",
    "3. \{editor_feature_selection_candidate_extraction_rule()}",
    "4. \{editor_feature_selection_exclusion_rule()}",
    "5. \{editor_feature_selection_score_rule()}",
    "6. \{editor_feature_selection_lowest_score_rule()}",
    "7. \{editor_feature_selection_no_code_edit_rule()}",
    "8. Write JSON to `\{result_path}`. Also return the same JSON as the final answer.",
  ]
}

///|
fn editor_feature_selection_profile_prompt_template() -> String {
  [
    editor_feature_selection_role_prompt(),
    "Read skill_paths and context_pages from step metadata.",
    editor_feature_selection_target_files_rule(),
    editor_feature_selection_candidate_extraction_rule(),
    editor_feature_selection_exclusion_rule(),
    editor_feature_selection_lowest_score_rule(),
    editor_feature_selection_no_code_edit_rule(),
    "Write the exact target_pages path with the \{editor_feature_selection_result_contract()} contract.",
  ].join(" ")
}

///|
fn editor_feature_selection_skill_first_rule() -> String {
  "Read the absolute `skills/editor-feature-rater/SKILL.md` path from `skill_paths` first."
}

///|
fn editor_feature_selection_target_files_rule() -> String {
  "Read the exact target files before any broad search. Prefer `CURRENT_UI_EVIDENCE.md` for current UI/runtime evidence instead of opening large UI source files unless compact evidence is insufficient."
}

///|
fn editor_feature_selection_candidate_extraction_rule() -> String {
  "Extract candidate features from the course, exercises, rubric, and current editor/output UI evidence. Do not rely on a hardcoded candidate list from Moontown."
}

///|
fn editor_feature_selection_exclusion_rule() -> String {
  "Read the absolute `FEATURE_SELECTION_CONTEXT.md` path from `context_pages` and exclude every feature listed under `Already Implemented Features`; do not select those features again."
}

///|
fn editor_feature_selection_score_rule() -> String {
  "Score each remaining candidate from 1 to 10, where 1 means critically missing and high leverage, and 10 means already strong enough."
}

///|
fn editor_feature_selection_lowest_score_rule() -> String {
  "Select the lowest-scoring remaining candidate. Break ties by choosing the candidate that best proves the editor-mode pipeline can become real implementation work."
}

///|
fn editor_feature_selection_no_code_edit_rule() -> String {
  "Do not edit source code in this step."
}
