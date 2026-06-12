///|
fn mayor_research_lane_topics(goal : String) -> Array[String] {
  let notes = goal.to_lower()
  let topics : Array[String] = []
  for topic in ["moontown", "moonbook", "moonclaw", "finance", "coding"] {
    if notes.contains(topic) {
      topics.push(topic)
    }
  }
  if notes.contains("opc") || notes.contains("one person company") {
    topics.push("opc")
  }
  topics
}

///|
fn mayor_should_parallelize_goal(goal : String, topics : Array[String]) -> Bool {
  let notes = goal.to_lower()
  let research_like = notes.contains("research") ||
    notes.contains("compare") ||
    notes.contains("survey") ||
    notes.contains("map")
  research_like && topics.length() > 1
}

///|
fn goal_lane(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  topic : String,
) -> MayorGoalLane {
  let objective = if @moonbook.should_parallelize_goal(goal) {
    "Own only the \{topic} research lane. Build durable source, entity, concept, and synthesis coverage for this lane. Cross-reference other lanes only through durable outputs. Global town goal: \{goal}"
  } else {
    goal
  }
  {
    entry,
    objective,
    rationale: if objective == goal {
      "single-lane book objective"
    } else {
      "parallel research lane for \{topic}"
    },
  }
}
