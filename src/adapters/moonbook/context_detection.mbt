///|
fn is_standing_watch_context_bundle(bundle : WorkerContextBundle) -> Bool {
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("standing-watch") ||
  combined.contains("standing watch") ||
  combined.contains("standing_goal_decision")
}

///|
fn is_research_bootstrap_context_bundle(bundle : WorkerContextBundle) -> Bool {
  guard !is_standing_watch_context_bundle(bundle) else { return false }
  guard !is_course_context_bundle(bundle) else { return false }
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("bootstrap") && combined.contains("research")
}

///|
fn is_course_context_bundle(bundle : WorkerContextBundle) -> Bool {
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("course") ||
  combined.contains("syllabus") ||
  combined.contains("learning path") ||
  combined.contains("beginner") ||
  combined.contains("workbook") ||
  combined.contains("lesson")
}

///|
fn is_wenyu_civic_context_bundle(bundle : WorkerContextBundle) -> Bool {
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("civic-service") ||
  combined.contains("civic service") ||
  bundle.context_pages.any(fn(path) {
    path.contains("CIVIC_SERVICE_CONTRACT.md") ||
    path.contains("wenyu-civic-service/SKILL.md")
  })
}

///|
fn skill_paths_from_context_pages(pages : Array[String]) -> Array[String] {
  let skill_paths : Array[String] = []
  for page in pages {
    if page.has_prefix("skills/") && page.has_suffix("/SKILL.md") {
      skill_paths.push(page)
    }
  }
  skill_paths
}
