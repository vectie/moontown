///|
async fn retire_satisfied_book_quality_repair_goals(
  goals : Array[@core.StandingGoal],
  scores : Array[@book_quality.BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Array[String] {
  let retired : Array[String] = []
  for index in 0..<goals.length() {
    let goal = goals[index]
    if book_quality_should_retire_repair_goal(
        goal, scores, repairable_book_ids, result_dir,
      ) {
      goals[index] = @book_quality.disabled_repair_standing_goal(goal)
      retired.push(goal.id)
    }
  }
  retired
}

///|
async fn book_quality_repair_goal_retirement_decision(
  goal : @core.StandingGoal,
  scores : Array[@book_quality.BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> @book_quality.BookQualityRepairGoalRetirementDecision {
  match goal.target_book_id {
    None =>
      @book_quality.repair_goal_retirement_decision(
        goal.id,
        goal.enabled,
        has_target_book=false,
        score_exists=false,
        repairable_book=false,
        semantic_score=None,
      )
    Some(book_id) => {
      let result_text = @support.read_text_or_empty(
        @book_quality.review_result_path(result_dir, book_id),
      )
      @book_quality.repair_goal_retirement_decision(
        goal.id,
        goal.enabled,
        has_target_book=true,
        score_exists=@book_quality.score_exists(scores, book_id),
        repairable_book=repairable_book_ids.contains(book_id),
        semantic_score=@book_quality.parse_ai_quality_score(result_text),
      )
    }
  }
}

///|
async fn book_quality_should_retire_repair_goal(
  goal : @core.StandingGoal,
  scores : Array[@book_quality.BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Bool {
  @book_quality.repair_goal_retirement_decision_should_retire(
    book_quality_repair_goal_retirement_decision(
      goal, scores, repairable_book_ids, result_dir,
    ),
  )
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
  @policy.catalog_entry_active(entry.id, entry.name, entry.purpose, entry.tags)
}
