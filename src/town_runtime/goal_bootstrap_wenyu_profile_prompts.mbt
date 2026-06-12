///|
fn wenyu_build_execute_prompt_template() -> String {
  [
    "Execute the imported Wenyu Valley build packet for ${proposal.title}.",
    "This is not a wiki query.",
    "Read \{wenyu_build_execute_inputs().join(", ")}.",
    wenyu_build_execute_task_rules().join(" "),
    "Always write the requested build/* artifacts in the book workspace.",
    "Return \{wenyu_build_execute_result_fields().join(", ")}.",
    "Do not claim success without either real file changes or an explicit blocker.",
  ].join(" ")
}

///|
fn wenyu_build_review_prompt_template() -> String {
  [
    "Review the build output for ${proposal.title}.",
    wenyu_build_review_workspace_rule(),
    "Verify artifacts in that source book workspace and verify repository paths under `/Users/kq/Workspace/moontown`.",
    wenyu_build_review_task_rules().join(" "),
    "Classify the outcome as implemented, prompt-ready, or blocked with exact reasons.",
    "Do not report missing artifacts until you checked the source book workspace and repository absolute paths.",
  ].join(" ")
}

///|
fn wenyu_build_execute_inputs() -> Array[String] {
  [
    "the packet request", "`context_pages`", "`skill_paths`", "`external_packet` metadata",
  ]
}

///|
fn wenyu_build_execute_task_rules() -> Array[String] {
  [
    "If the task asks for a code patch, inspect and edit the named repository paths when safe, then run the narrowest validation command.",
    "If the task asks for an asset pack, generate or write production-ready asset prompts and a manifest.",
    "If the task asks for a backlog, write implementation-grade backlog and acceptance tests.",
  ]
}

///|
fn wenyu_build_execute_result_fields() -> Array[String] {
  ["changed files", "artifacts", "blockers", "validation results"]
}

///|
fn wenyu_build_review_workspace_rule() -> String {
  "First read `.moonclaw/run.json` if present and use its `source_workspace` as the book workspace; do not assume the isolated run workspace is the source book."
}

///|
fn wenyu_build_review_task_rules() -> Array[String] {
  [
    "Code tasks must either show real repository changes plus `build/CODE_PATCH.md` and `build/TEST_RESULTS.md`, or write/identify `build/CODE_BLOCKERS.md`.",
    "Asset tasks must produce module-specific prompts/manifests.",
  ]
}
