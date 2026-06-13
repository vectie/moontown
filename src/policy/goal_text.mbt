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

///|
pub fn research_topic_from_goal(goal : String) -> String? {
  let trimmed = goal.trim().trim(chars=" .:;!?\"'`").to_owned()
  if trimmed.is_empty() {
    return None
  }
  let lower = trimmed.to_lower()
  let prefixes = [
    "research about ", "research on ", "research the ", "research ", "study about ",
    "study on ", "study the ", "study ", "survey about ", "survey on ", "survey the ",
    "survey ", "compare about ", "compare on ", "compare the ", "compare ",
  ]
  for prefix in prefixes {
    if lower.has_prefix(prefix) {
      let topic = trimmed[prefix.length():]
        .trim()
        .trim(chars=" .:;!?\"'`")
        .to_owned()
      if !topic.is_empty() {
        return Some(topic)
      }
    }
  }
  Some(trimmed)
}
