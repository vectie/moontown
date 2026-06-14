///|
pub fn standing_watch_task_kind() -> String {
  "standing-watch"
}

///|
pub fn standing_watch_task_kind_matches(kind : String) -> Bool {
  kind == standing_watch_task_kind()
}

///|
pub fn standing_watch_skill_path() -> String {
  "skills/standing-watch/SKILL.md"
}

///|
pub fn standing_watch_skill_paths() -> Array[String] {
  [
    standing_watch_skill_path(),
    ..@research_policy.standing_watch_research_skill_paths(),
  ]
}

///|
pub fn standing_watch_context_pages() -> Array[String] {
  [
    "wiki/history/standing-watch.md", "wiki/history/journey.md", "wiki/sources/",
    "wiki/synthesis/overview.md", "wiki/synthesis/claims.md",
  ]
}

///|
pub fn standing_watch_output_contract_lines() -> Array[String] {
  [
    "standing_goal_decision: update | no_change | needs_review | failed", "delta_score: 0-100",
    "new_source_count: <integer>", "next_check_hint: normal | slower | faster | review",
    "checked_sources_count: <integer>", "new_sources_found: <integer>", "accepted_facts_count: <integer>",
    "rejected_facts_count: <integer>", "wiki_pages_changed_count: <integer>", "book_changed: yes | no",
  ]
}
