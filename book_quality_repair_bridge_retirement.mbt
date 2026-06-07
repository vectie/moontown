///|
async fn retire_satisfied_book_quality_repair_goals(
  goals : Array[@core.StandingGoal],
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Array[String] {
  let retired : Array[String] = []
  for index in 0..<goals.length() {
    let goal = goals[index]
    if book_quality_should_retire_repair_goal(
        goal, scores, repairable_book_ids, result_dir,
      ) {
      goals[index] = disabled_book_quality_repair_goal(goal)
      retired.push(goal.id)
    }
  }
  retired
}

///|
priv enum BookQualityRepairGoalRetirementDecision {
  NotRepairGoal
  MissingTargetBook
  MissingBookScore
  NoLongerRepairableBook
  ReadySemanticReview
  StillNeedsRepair
}

///|
fn BookQualityRepairGoalRetirementDecision::should_retire(
  self : BookQualityRepairGoalRetirementDecision,
) -> Bool {
  match self {
    MissingBookScore | NoLongerRepairableBook | ReadySemanticReview => true
    NotRepairGoal | MissingTargetBook | StillNeedsRepair => false
  }
}

///|
async fn book_quality_repair_goal_retirement_decision(
  goal : @core.StandingGoal,
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> BookQualityRepairGoalRetirementDecision {
  if !goal.enabled || !goal.id.has_prefix("book-quality-repair-") {
    return NotRepairGoal
  }
  match goal.target_book_id {
    None => MissingTargetBook
    Some(book_id) => {
      if !book_quality_score_exists(scores, book_id) {
        return MissingBookScore
      }
      if !repairable_book_ids.contains(book_id) {
        return NoLongerRepairableBook
      }
      let result_text = read_text_or_empty(
        book_quality_ai_review_result_path(result_dir, book_id),
      )
      match parse_ai_quality_score(result_text) {
        Some(value) if semantic_quality_allows_ready(Some(value)) =>
          ReadySemanticReview
        _ => StillNeedsRepair
      }
    }
  }
}

///|
async fn book_quality_should_retire_repair_goal(
  goal : @core.StandingGoal,
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Bool {
  book_quality_repair_goal_retirement_decision(
    goal, scores, repairable_book_ids, result_dir,
  ).should_retire()
}

///|
fn book_quality_score_exists(
  scores : Array[BookQualityScore],
  book_id : String,
) -> Bool {
  for score in scores {
    if score.book_id == book_id {
      return true
    }
  }
  false
}

///|
fn disabled_book_quality_repair_goal(
  goal : @core.StandingGoal,
) -> @core.StandingGoal {
  standing_goal_registry_with_enabled(goal, false)
}

///|
fn book_quality_repairable_book_ids(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Array[String] {
  let ids : Array[String] = []
  for entry in catalog {
    if book_quality_repairable_catalog_entry(entry) {
      ids.push(entry.id)
    }
  }
  ids
}

///|
fn book_quality_repairable_catalog_entry(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  book_quality_active_catalog_entry(entry)
}
