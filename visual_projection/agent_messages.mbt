///|
fn visual_agent_message(
  worker : @core.WorkerRef,
  book_title : String,
  task_title : String?,
  phase : String,
) -> String {
  let work = task_title.unwrap_or(book_title)
  match phase {
    "packet" => "\{worker.name} is receiving the town handoff for \{work}."
    "importing" => "\{worker.name} is importing the packet before work starts."
    "running" => "\{worker.name} is actively working on \{work}."
    "persisting" =>
      "\{worker.name} is carrying results back to MoonBook memory."
    "review" => "\{worker.name} is inside the book review room."
    "failed" => "\{worker.name} needs mayor recovery for \{work}."
    "stale" => "\{worker.name} is stale and should be recovered."
    "blocked" => "\{worker.name} is blocked and visible in anomaly triage."
    "waiting" => "\{worker.name} is queued for the next supervised handoff."
    "offline" => "\{worker.name} is offline."
    _ => "\{worker.name} is inside \{book_title}."
  }
}
