///|
fn upsert_book_quality_repair_standing_goal(
  goals : Array[@core.StandingGoal],
  item : BookQualityRepairBridgeItem,
  current_tick : Int,
) -> Unit {
  let replacement = new_book_quality_repair_standing_goal(item, current_tick)
  let mut replaced = false
  for index in 0..<goals.length() {
    if goals[index].id == replacement.id {
      goals[index] = refreshed_book_quality_repair_standing_goal(
        goals[index],
        item,
      )
      replaced = true
    }
  }
  if !replaced {
    goals.push(replacement)
  }
}

///|
fn new_book_quality_repair_standing_goal(
  item : BookQualityRepairBridgeItem,
  current_tick : Int,
) -> @core.StandingGoal {
  book_quality_repair_standing_goal(
    item,
    next_due_tick=current_tick + 1,
    last_run_tick=None,
  )
}

///|
fn refreshed_book_quality_repair_standing_goal(
  existing : @core.StandingGoal,
  item : BookQualityRepairBridgeItem,
) -> @core.StandingGoal {
  book_quality_repair_standing_goal(
    item,
    next_due_tick=existing.next_due_tick,
    last_run_tick=existing.last_run_tick,
  )
}

///|
fn book_quality_repair_standing_goal(
  item : BookQualityRepairBridgeItem,
  next_due_tick~ : Int,
  last_run_tick~ : Int?,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Repair book quality: \{item.book_id}",
    prompt=book_quality_repair_goal_prompt(item),
    target_book_id=Some(item.book_id),
    cadence_ticks=book_quality_repair_goal_cadence_ticks(),
    next_due_tick~,
    last_run_tick~,
    enabled=true,
    source_policy=book_quality_repair_source_policy(item.book_type),
    quality_threshold=semantic_quality_ready_threshold(),
  )
}

///|
fn book_quality_repair_goal_cadence_ticks() -> Int {
  60
}

///|
fn book_quality_repair_goal_prompt(
  item : BookQualityRepairBridgeItem,
) -> String {
  [
    "A semantic MoonBook quality review found that this book is not ready.",
    "",
    "Book id: `\{item.book_id}`",
    "Book type: `\{item.book_type}`",
    "AI quality: `\{item.semantic_score}` / `\{item.semantic_grade}`",
    "Repair owner: `\{item.repair_owner}`",
    "Review queue: `wiki/reviews/book-quality-repair.md`",
    "",
    "Repair task from the AI review:",
    item.next_repair_task,
    "",
    "Rules:",
    "- Repair the existing book in place; do not create v1/v2/v3/v4 alternates.",
    "- Follow the book's own contract and SKILL.md; do not force a research genre onto civic, course, planbook, cookbook, or operational books.",
    "- Separate operational logs from domain/service evidence.",
    "- If the repair needs web evidence and source policy allows it, search/fetch web sources before local fallback.",
    "- Return a strict standing-goal decision marker so Moontown can account for real growth.",
  ].join("\n")
}

///|
fn book_quality_repair_source_policy(book_type : String) -> String {
  book_quality_source_policy_for_type(book_type)
}

///|
fn book_quality_repair_goal_id(book_id : String) -> String {
  "book-quality-repair-\{book_id}"
}
