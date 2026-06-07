///|
pub async fn reconcile_book_quality_repair_bridge(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  result_dir? : String = default_book_quality_review_result_dir(),
  bridge_path? : String = default_book_quality_repair_bridge_path(),
) -> String {
  let context = load_book_quality_repair_bridge_context(
    book_catalog_path, snapshot_path,
  )
  let retired_goal_ids = retire_satisfied_book_quality_repair_goals(
    context.goals,
    context.audit.scores,
    context.repairable_book_ids,
    result_dir,
  )
  let repaired = apply_book_quality_repair_bridge_candidates(
    context.audit.scores,
    context.repairable_book_ids,
    result_dir,
    context.goals,
    context.current_tick,
  )
  persist_book_quality_repair_bridge(context, bridge_path, repaired)
  book_quality_repair_bridge_summary(repaired, retired_goal_ids)
}

///|
priv struct BookQualityRepairBridgeContext {
  repairable_book_ids : Array[String]
  audit : BookQualityAudit
  current_tick : Int
  goals_path : String
  goals : Array[@core.StandingGoal]
}

///|
async fn load_book_quality_repair_bridge_context(
  book_catalog_path : String,
  snapshot_path : String,
) -> BookQualityRepairBridgeContext {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  let repairable_book_ids = book_quality_repairable_book_ids(catalog)
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  let current_tick = book_quality_current_daemon_tick(snapshot_path)
  let goals_path = book_quality_standing_goal_path(snapshot_path)
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  { repairable_book_ids, audit, current_tick, goals_path, goals }
}

///|
async fn persist_book_quality_repair_bridge(
  context : BookQualityRepairBridgeContext,
  bridge_path : String,
  repaired : Array[BookQualityRepairBridgeItem],
) -> Unit {
  @storage.save_standing_goals_file(context.goals_path, context.goals)
  write_text_file(
    bridge_path,
    BookQualityRepairBridgeLedger::{ items: repaired }
    .to_json()
    .stringify(indent=2),
  )
}

///|
async fn apply_book_quality_repair_bridge_candidates(
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
  goals : Array[@core.StandingGoal],
  current_tick : Int,
) -> Array[BookQualityRepairBridgeItem] {
  let repaired : Array[BookQualityRepairBridgeItem] = []
  for score in scores {
    if !repairable_book_ids.contains(score.book_id) {
      continue
    }
    match book_quality_repair_bridge_candidate(score, result_dir) {
      Some(candidate) =>
        repaired.push(
          apply_book_quality_repair_bridge_candidate(
            goals, candidate, current_tick,
          ),
        )
      None => ()
    }
  }
  repaired
}

///|
async fn apply_book_quality_repair_bridge_candidate(
  goals : Array[@core.StandingGoal],
  candidate : BookQualityRepairBridgeCandidate,
  current_tick : Int,
) -> BookQualityRepairBridgeItem {
  let item = candidate.item
  write_book_quality_repair_review_page(item, candidate.result_text)
  upsert_book_quality_repair_standing_goal(goals, item, current_tick)
  item
}

///|
priv struct BookQualityRepairBridgeCandidate {
  item : BookQualityRepairBridgeItem
  result_text : String
}

///|
async fn book_quality_repair_bridge_candidate(
  score : BookQualityScore,
  result_dir : String,
) -> BookQualityRepairBridgeCandidate? {
  let result_path = book_quality_ai_review_result_path(
    result_dir,
    score.book_id,
  )
  let result_text = read_text_or_empty(result_path)
  if result_text.is_empty() {
    return None
  }
  match parse_ai_quality_score(result_text) {
    Some(value) if semantic_review_requires_repair(Some(value)) =>
      Some({
        item: book_quality_repair_bridge_item(
          score, result_path, result_text, value,
        ),
        result_text,
      })
    _ => None
  }
}

///|
fn book_quality_repair_bridge_summary(
  repaired : Array[BookQualityRepairBridgeItem],
  retired_goal_ids : Array[String],
) -> String {
  let repair_summary = if repaired.is_empty() {
    "No weak AI semantic book-quality review needed repair bridging."
  } else {
    let ids = repaired.map(fn(item) { item.book_id }).join(", ")
    "Bridged \{repaired.length()} weak AI semantic book-quality review(s) into MoonBook review queues and standing repair goals: \{ids}."
  }
  if retired_goal_ids.is_empty() {
    repair_summary
  } else {
    "\{repair_summary} Retired \{retired_goal_ids.length()} stale repair goal(s): \{retired_goal_ids.join(", ")}."
  }
}
