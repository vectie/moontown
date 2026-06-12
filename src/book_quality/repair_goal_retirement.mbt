///|
pub enum BookQualityRepairGoalRetirementDecision {
  NotRepairGoal
  MissingTargetBook
  MissingBookScore
  NoLongerRepairableBook
  ReadySemanticReview
  StillNeedsRepair
} derive(Eq, Debug)

///|
pub fn score_exists(scores : Array[BookQualityScore], book_id : String) -> Bool {
  for score in scores {
    if score.book_id == book_id {
      return true
    }
  }
  false
}

///|
pub fn repair_goal_retirement_decision(
  goal_id : String,
  enabled : Bool,
  has_target_book~ : Bool,
  score_exists~ : Bool,
  repairable_book~ : Bool,
  semantic_score~ : Int?,
) -> BookQualityRepairGoalRetirementDecision {
  if !enabled || !is_repair_goal_id(goal_id) {
    return NotRepairGoal
  }
  if !has_target_book {
    return MissingTargetBook
  }
  if !score_exists {
    return MissingBookScore
  }
  if !repairable_book {
    return NoLongerRepairableBook
  }
  match semantic_score {
    Some(value) if semantic_quality_allows_ready(Some(value)) =>
      ReadySemanticReview
    _ => StillNeedsRepair
  }
}

///|
pub fn repair_goal_retirement_decision_should_retire(
  decision : BookQualityRepairGoalRetirementDecision,
) -> Bool {
  match decision {
    MissingBookScore | NoLongerRepairableBook | ReadySemanticReview => true
    NotRepairGoal | MissingTargetBook | StillNeedsRepair => false
  }
}

///|
pub fn repair_goal_retirement_decision_label(
  decision : BookQualityRepairGoalRetirementDecision,
) -> String {
  match decision {
    NotRepairGoal => "not-repair-goal"
    MissingTargetBook => "missing-target-book"
    MissingBookScore => "missing-book-score"
    NoLongerRepairableBook => "no-longer-repairable-book"
    ReadySemanticReview => "ready-semantic-review"
    StillNeedsRepair => "still-needs-repair"
  }
}
