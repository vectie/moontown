///|
fn is_research_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("moontown") ||
  notes.contains("moonbook") ||
  notes.contains("moonclaw") ||
  is_wenyu_valley_goal(goal)
}

///|
fn is_wenyu_valley_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("wenyu") ||
  notes.contains("wenyu valley") ||
  (notes.contains("innovation town") && notes.contains("prd"))
}
