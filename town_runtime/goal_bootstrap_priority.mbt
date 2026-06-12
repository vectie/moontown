///|
fn prioritized_tasks(
  tasks : Array[@moonbook.BookTask],
  goal : String,
) -> Array[@moonbook.BookTask] {
  let ordered = tasks.copy()
  let research_goal = is_research_goal(goal)
  ordered.sort_by(fn(left, right) {
    task_priority_score(right, research_goal).compare(
      task_priority_score(left, research_goal),
    )
  })
  ordered
}

///|
fn task_priority_score(task : @moonbook.BookTask, research_goal : Bool) -> Int {
  let kind_score = match task.kind {
    "analysis" => 60
    "synthesis" => 50
    "planning" => if research_goal { 15 } else { 40 }
    "review" => if research_goal { 10 } else { 45 }
    "ingest" | "ingest-followup" => if research_goal { 35 } else { 25 }
    _ => 20
  }
  kind_score + task.priority
}
