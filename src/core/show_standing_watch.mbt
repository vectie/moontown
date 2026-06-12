///|
pub impl Show for WatcherDecisionKind with fn output(
  self : WatcherDecisionKind,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    match self {
      Update => "Update"
      NoChange => "NoChange"
      NeedsReview => "NeedsReview"
      Failed => "Failed"
      Deferred => "Deferred"
    },
  )
}

///|
pub impl Show for StandingGoal with fn output(
  self : StandingGoal,
  logger : &Logger,
) -> Unit {
  let target_book_id = self.target_book_id.unwrap_or("none")
  logger.write_string(
    "StandingGoal(id=\{self.id}, target_book_id=\{target_book_id}, cadence_ticks=\{self.cadence_ticks}, next_due_tick=\{self.next_due_tick}, enabled=\{self.enabled})",
  )
}

///|
pub impl Show for WatcherRunRecord with fn output(
  self : WatcherRunRecord,
  logger : &Logger,
) -> Unit {
  logger.write_string(
    "WatcherRunRecord(goal_id=\{self.goal_id}, tick=\{self.tick}, decision=\{self.decision}, delta_score=\{self.delta_score}, new_source_count=\{self.new_source_count}, next_due_tick=\{self.next_due_tick})",
  )
}
