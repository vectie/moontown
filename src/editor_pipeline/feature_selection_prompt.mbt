///|
pub fn feature_selection_target_files_markdown(
  target_files : Array[String],
) -> String {
  let lines : Array[String] = []
  for path in target_files {
    lines.push("- `\{path}`")
  }
  lines.join("\n")
}

///|
pub fn feature_selection_request_text(
  result_path : String,
  target_files : Array[String],
) -> String {
  [
    feature_selection_role_prompt(),
    "",
    feature_selection_goal_prompt(),
    "",
    "Rules:",
    feature_selection_request_rules(result_path).join("\n"),
    "",
    "Target files:",
    feature_selection_target_files_markdown(target_files),
  ].join("\n")
}

///|
pub fn feature_selection_role_prompt() -> String {
  "You are the AI feature rater for MoonTown's Wenyu editor-mode pipeline."
}

///|
pub fn feature_selection_goal_prompt() -> String {
  "Goal: choose the single most important missing editor-mode feature from the existing Wenyu game-design course book and current UI evidence."
}

///|
pub fn feature_selection_request_rules(result_path : String) -> Array[String] {
  [
    "1. \{feature_selection_skill_first_rule()}",
    "2. \{feature_selection_target_files_rule()}",
    "3. \{feature_selection_candidate_extraction_rule()}",
    "4. \{feature_selection_exclusion_rule()}",
    "5. \{feature_selection_score_rule()}",
    "6. \{feature_selection_lowest_score_rule()}",
    "7. \{feature_selection_no_code_edit_rule()}",
    "8. Write JSON to `\{result_path}`. Also return the same JSON as the final answer.",
  ]
}

///|
pub fn feature_selection_profile_prompt_template() -> String {
  [
    feature_selection_role_prompt(),
    "Read skill_paths and context_pages from step metadata.",
    feature_selection_target_files_rule(),
    feature_selection_candidate_extraction_rule(),
    feature_selection_exclusion_rule(),
    feature_selection_lowest_score_rule(),
    feature_selection_no_code_edit_rule(),
    "Write the exact target_pages path with the \{feature_selection_result_contract()} contract.",
  ].join(" ")
}

///|
pub fn feature_selection_skill_first_rule() -> String {
  "Read the absolute `skills/editor-feature-rater/SKILL.md` path from `skill_paths` first."
}

///|
pub fn feature_selection_target_files_rule() -> String {
  "Read the exact target files before any broad search. Prefer `CURRENT_UI_EVIDENCE.md` for current UI/runtime evidence instead of opening large UI source files unless compact evidence is insufficient."
}

///|
pub fn feature_selection_candidate_extraction_rule() -> String {
  "Extract candidate features from the course, exercises, rubric, and current editor/output UI evidence. Do not rely on a hardcoded candidate list from MoonTown."
}

///|
pub fn feature_selection_exclusion_rule() -> String {
  "Read the absolute `FEATURE_SELECTION_CONTEXT.md` path from `context_pages` and exclude every feature listed under `Already Implemented Features`; do not select those features again."
}

///|
pub fn feature_selection_score_rule() -> String {
  "Score each remaining candidate from 1 to 10, where 1 means critically missing and high leverage, and 10 means already strong enough."
}

///|
pub fn feature_selection_lowest_score_rule() -> String {
  "Select the lowest-scoring remaining candidate. Break ties by choosing the candidate that best proves the editor-mode pipeline can become real implementation work."
}

///|
pub fn feature_selection_no_code_edit_rule() -> String {
  "Do not edit source code in this step."
}
