///|
pub fn wenyu_valley_goal_text(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("wenyu") ||
  notes.contains("wenyu valley") ||
  (notes.contains("innovation town") && notes.contains("prd"))
}

///|
pub fn research_goal_text(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("moontown") ||
  notes.contains("moonbook") ||
  notes.contains("moonclaw") ||
  wenyu_valley_goal_text(goal)
}

///|
pub fn research_request_goal_text(goal : String) -> Bool {
  let notes = goal.to_lower()
  research_goal_text(goal) ||
  notes.contains("compare") ||
  notes.contains("survey") ||
  notes.contains("map")
}
