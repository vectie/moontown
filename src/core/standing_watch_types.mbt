///|
pub fn StandingGoal::new(
  id~ : String,
  title~ : String,
  prompt~ : String,
  target_book_id~ : String? = None,
  cadence_ticks~ : Int32 = 60,
  next_due_tick~ : Int32 = 0,
  last_run_tick~ : Int32? = None,
  enabled~ : Bool = true,
  source_policy~ : String = "",
  quality_threshold~ : Int32 = 80,
) -> StandingGoal {
  {
    id,
    title,
    prompt,
    target_book_id,
    cadence_ticks,
    next_due_tick,
    last_run_tick,
    enabled,
    source_policy,
    quality_threshold,
  }
}

///|
pub fn StandingGoal::is_due(self : StandingGoal, tick : Int32) -> Bool {
  self.enabled && tick >= self.next_due_tick
}

///|
pub fn StandingGoal::mark_dispatched(
  self : StandingGoal,
  tick : Int32,
) -> StandingGoal {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  { ..self, last_run_tick: Some(tick), next_due_tick: tick + cadence, }
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct WatcherRunRecord {
  goal_id : String
  tick : Int32
  target_book_id : String
  decision : WatcherDecisionKind
  delta_score : Int32
  new_source_count : Int32
  detail : String
  task_id : String?
  run_id : String?
  next_due_tick : Int32
}

///|
pub fn WatcherRunRecord::new(
  goal_id~ : String,
  tick~ : Int32,
  target_book_id~ : String,
  decision~ : WatcherDecisionKind,
  delta_score~ : Int32 = 0,
  new_source_count~ : Int32 = 0,
  detail~ : String = "",
  task_id~ : String? = None,
  run_id~ : String? = None,
  next_due_tick~ : Int32 = tick,
) -> WatcherRunRecord {
  {
    goal_id,
    tick,
    target_book_id,
    decision,
    delta_score,
    new_source_count,
    detail,
    task_id,
    run_id,
    next_due_tick,
  }
}

///|
pub fn StandingGoal::next_due_after_watcher_decision(
  self : StandingGoal,
  tick : Int32,
  decision : WatcherDecisionKind,
  no_change_streak~ : Int32 = 0,
) -> Int32 {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  let _ = no_change_streak
  match decision {
    Update => tick + cadence
    NoChange => tick + cadence
    NeedsReview => tick + max_int(1, cadence / 2)
    Failed => tick + max_int(1, cadence / 4)
    Deferred => tick + cadence
  }
}

///|
pub fn StandingGoal::mark_watcher_decision(
  self : StandingGoal,
  tick : Int32,
  decision : WatcherDecisionKind,
  no_change_streak~ : Int32 = 0,
) -> StandingGoal {
  {
    ..self,
    last_run_tick: Some(tick),
    next_due_tick: self.next_due_after_watcher_decision(
      tick,
      decision,
      no_change_streak~,
    ),
  }
}

///|
fn max_int(left : Int32, right : Int32) -> Int32 {
  if left > right {
    left
  } else {
    right
  }
}
