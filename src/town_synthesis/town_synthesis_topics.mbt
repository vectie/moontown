///|
fn lane_entry_for_topic(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> @moonbook.BookCatalogEntry? {
  let needle = "research-\{topic}"
  for lane in plan.lanes {
    if lane.entry.id == needle || lane.entry.id.contains(topic) {
      return Some(lane.entry)
    }
  }
  None
}

///|
fn display_topic_title(topic : String) -> String {
  match topic {
    "moonbook" => "MoonBook"
    "moonclaw" => "MoonClaw"
    "moontown" => "MoonTown"
    _ => topic
  }
}

///|
fn project_responsibility(topic : String) -> String {
  match topic {
    "moonbook" =>
      "documentation, wiki state, report projection, and durable memory"
    "moonclaw" =>
      "agent runtime, jobs, provider tasks, tools, memory, and artifacts"
    "moontown" =>
      "goal decomposition, routing, supervision, quality gates, and town synthesis"
    _ => "lane-specific responsibility"
  }
}

///|
fn project_town_interpretation(topic : String) -> String {
  match topic {
    "moonbook" =>
      "the book layer that decides what evidence becomes durable knowledge"
    "moonclaw" =>
      "the claw layer that performs bounded work and returns structured evidence"
    "moontown" =>
      "the town layer that coordinates many books and workers into one operator-visible goal"
    _ => "a supporting layer in the town goal"
  }
}
