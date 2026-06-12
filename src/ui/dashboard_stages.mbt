///|
priv struct DashboardStageRule {
  label : String
  priority : Int
  tokens : Array[String]
}

///|
fn highest_priority_stage(current : String, candidate : String) -> String {
  if stage_priority(candidate) < stage_priority(current) {
    candidate
  } else {
    current
  }
}

///|
fn stage_priority(stage : String) -> Int {
  for rule in dashboard_stage_rules() {
    if stage == rule.label {
      return rule.priority
    }
  }
  if stage == "Planning" {
    5
  } else {
    6
  }
}

///|
fn execution_stage_label(
  town : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> String {
  match find_task_by_id(town, execution.task_id) {
    Some(task) => task_stage_label(task)
    None => stage_label_for_text(execution.task_id, execution.summary)
  }
}

///|
fn find_task_by_id(town : @core.TownState, task_id : String) -> @core.TownTask? {
  for task in town.tasks {
    if task.id == task_id {
      return Some(task)
    }
  }
  None
}

///|
fn task_stage_label(task : @core.TownTask) -> String {
  stage_label_for_text(task.id, "\{task.title} \{task.prompt}")
}

///|
fn stage_label_for_text(primary : String, secondary : String) -> String {
  let primary_lower = primary.to_lower()
  let secondary_lower = secondary.to_lower()
  for rule in dashboard_stage_rules() {
    if contains_stage_token(primary_lower, secondary_lower, rule.tokens) {
      return rule.label
    }
  }
  "Planning"
}

///|
fn dashboard_stage_rules() -> Array[DashboardStageRule] {
  [
    {
      label: "Watch",
      priority: 2,
      tokens: [
        "standing-watch", "standing watch", "standing_goal_decision", "watcher",
      ],
    },
    { label: "Bootstrap", priority: 0, tokens: ["bootstrap"] },
    {
      label: "Source Population",
      priority: 1,
      tokens: ["ingest", "source", "discover", "populate"],
    },
    {
      label: "Review",
      priority: 3,
      tokens: ["review", "approve", "promote", "lint"],
    },
    {
      label: "Synthesis",
      priority: 4,
      tokens: ["query", "synthesis", "answer", "research", "analysis"],
    },
  ]
}

///|
fn contains_stage_token(
  primary : String,
  secondary : String,
  tokens : Array[String],
) -> Bool {
  for token in tokens {
    if primary.contains(token) || secondary.contains(token) {
      return true
    }
  }
  false
}
