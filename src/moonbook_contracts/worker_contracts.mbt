///|
pub fn wiki_maintainer_skill_path() -> String {
  "skills/wiki-maintainer/SKILL.md"
}

///|
pub fn default_keeper_skill_paths() -> Array[String] {
  [wiki_maintainer_skill_path()]
}

///|
pub fn default_keeper_context_pages() -> Array[String] {
  ["wiki/index.md", "wiki/log.md"]
}

///|
pub fn fallback_keeper_policy_lines() -> Array[String] {
  [
    "Keep all memory and durable artifacts inside this book unless the task explicitly names a repository patch.",
    "Return explicit blockers instead of fake completion when required tools or sources are missing.",
    "Preserve Moontown, MoonBook, and MoonClaw responsibility boundaries.",
  ]
}

///|
pub fn fallback_keeper_routine_lines() -> Array[String] {
  [
    "Read task context pages first.", "Create or update target pages listed in the task when applicable.",
    "Report changed files, artifacts, blockers, and validation results.",
  ]
}

///|
pub fn fallback_keeper_memory_summary(
  book_id : String,
  task_id : String,
) -> String {
  "Fallback MoonBook context for externally planned task `\{task_id}` in book `\{book_id}`."
}

///|
pub fn fallback_keeper_output_contract_lines() -> Array[String] {
  [
    "task_id", "summary", "artifacts", "memory_candidates", "requires_review", "notify_town",
  ]
}
