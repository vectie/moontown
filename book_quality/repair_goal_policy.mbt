///|
pub fn repair_goal_cadence_ticks() -> Int {
  60
}

///|
pub fn repair_goal_id_prefix() -> String {
  "book-quality-repair-"
}

///|
pub fn repair_goal_id(book_id : String) -> String {
  "\{repair_goal_id_prefix()}\{book_id}"
}

///|
pub fn is_repair_goal_id(goal_id : String) -> Bool {
  goal_id.has_prefix(repair_goal_id_prefix())
}

///|
pub fn repair_goal_ids(goals : Array[@core.StandingGoal]) -> Array[String] {
  let ids : Array[String] = []
  for goal in goals {
    if is_repair_goal_id(goal.id) {
      ids.push(goal.id)
    }
  }
  ids
}

///|
pub fn repair_goal_source_policy(book_type : String) -> String {
  source_policy_for_type(book_type)
}

///|
pub fn repair_goal_prompt(item : BookQualityRepairBridgeItem) -> String {
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
pub fn upsert_repair_standing_goal(
  goals : Array[@core.StandingGoal],
  item : BookQualityRepairBridgeItem,
  current_tick : Int,
) -> Unit {
  let replacement = new_repair_standing_goal(item, current_tick)
  let mut replaced = false
  for index in 0..<goals.length() {
    if goals[index].id == replacement.id {
      goals[index] = refreshed_repair_standing_goal(goals[index], item)
      replaced = true
    }
  }
  if !replaced {
    goals.push(replacement)
  }
}

///|
pub fn new_repair_standing_goal(
  item : BookQualityRepairBridgeItem,
  current_tick : Int,
) -> @core.StandingGoal {
  repair_standing_goal(item, next_due_tick=current_tick + 1, last_run_tick=None)
}

///|
pub fn refreshed_repair_standing_goal(
  existing : @core.StandingGoal,
  item : BookQualityRepairBridgeItem,
) -> @core.StandingGoal {
  repair_standing_goal(
    item,
    next_due_tick=existing.next_due_tick,
    last_run_tick=existing.last_run_tick,
  )
}

///|
pub fn repair_standing_goal(
  item : BookQualityRepairBridgeItem,
  next_due_tick~ : Int,
  last_run_tick~ : Int?,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Repair book quality: \{item.book_id}",
    prompt=repair_goal_prompt(item),
    target_book_id=Some(item.book_id),
    cadence_ticks=repair_goal_cadence_ticks(),
    next_due_tick~,
    last_run_tick~,
    enabled=true,
    source_policy=repair_goal_source_policy(item.book_type),
    quality_threshold=semantic_ready_threshold(),
  )
}

///|
pub fn disabled_repair_standing_goal(
  goal : @core.StandingGoal,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled=false,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
pub fn repair_goal_standing_watch_appendix() -> String {
  let appendix =
    $|
    $|Book-quality repair mode:
    $|- This standing goal is not a passive latest-news watch. It exists because a semantic MoonBook quality review found a concrete gap.
    $|- Read `wiki/reviews/book-quality-repair.md` and execute the named repair task before deciding.
    $|- If the repair queue names missing artifacts, create or revise those artifacts using the book's own SKILL.md, contracts, local source hints, approved web/source tools, and current workspace state.
    $|- If web search/fetch is unavailable, record that blocker but still use approved local/source hints and existing book context to make bounded progress when possible.
    $|- Do not return ordinary `no_change` merely because no fresh source was found while the repair queue still names missing artifacts.
    $|- Return `no_change` only when the required artifacts already exist, the named gap is already satisfied, or the review queue is stale and no longer applies.
    $|- Return `needs_review` when source authority, policy, privacy, or evidence uncertainty prevents autonomous promotion after useful repair work.
    $|- Return `update` when durable book artifacts, accepted evidence, or review-gated repair artifacts were created or revised.
    $|- Keep the repair book-local. Do not create v1/v2/v3/v4 alternate books.
  appendix
}

///|
pub fn repair_goal_generic_empty_review_summary(summary : String) -> Bool {
  let lowered = summary.to_lower()
  let generic_completion = lowered.contains("inline run finished") ||
    lowered.contains("workflow completed")
  generic_completion &&
  !lowered.contains("standing_goal_decision") &&
  !lowered.contains("candidate insight") &&
  !lowered.contains("pending_review") &&
  !lowered.contains("book_watch_record_id")
}
