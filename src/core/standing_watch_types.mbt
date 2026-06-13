///|
pub fn StandingGoal::new(
  id~ : String,
  title~ : String,
  prompt~ : String,
  target_book_id? : String? = None,
  cadence_ticks? : Int = 60,
  next_due_tick? : Int = 0,
  last_run_tick? : Int? = None,
  enabled? : Bool = true,
  source_policy? : String = "",
  quality_threshold? : Int = 80,
) -> StandingGoal {
  StandingGoal::{
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
pub fn StandingGoal::is_due(self : StandingGoal, tick : Int) -> Bool {
  self.enabled && tick >= self.next_due_tick
}

///|
pub fn StandingGoal::mark_dispatched(
  self : StandingGoal,
  tick : Int,
) -> StandingGoal {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  { ..self, last_run_tick: Some(tick), next_due_tick: tick + cadence }
}

///|
pub struct WatcherRunRecord {
  goal_id : String
  tick : Int
  target_book_id : String
  decision : WatcherDecisionKind
  delta_score : Int
  new_source_count : Int
  detail : String
  task_id : String?
  run_id : String?
  next_due_tick : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn WatcherRunRecord::new(
  goal_id~ : String,
  tick~ : Int,
  target_book_id~ : String,
  decision~ : WatcherDecisionKind,
  delta_score? : Int = 0,
  new_source_count? : Int = 0,
  detail? : String = "",
  task_id? : String? = None,
  run_id? : String? = None,
  next_due_tick? : Int = tick,
) -> WatcherRunRecord {
  WatcherRunRecord::{
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
  tick : Int,
  decision : WatcherDecisionKind,
  no_change_streak? : Int = 0,
) -> Int {
  let cadence = if self.cadence_ticks < 1 { 1 } else { self.cadence_ticks }
  let _ = no_change_streak
  match decision {
    WatcherDecisionKind::Update => tick + cadence
    WatcherDecisionKind::NoChange => tick + cadence
    WatcherDecisionKind::NeedsReview => tick + max_int(1, cadence / 2)
    WatcherDecisionKind::Failed => tick + max_int(1, cadence / 4)
    WatcherDecisionKind::Deferred => tick + cadence
  }
}

///|
pub fn StandingGoal::mark_watcher_decision(
  self : StandingGoal,
  tick : Int,
  decision : WatcherDecisionKind,
  no_change_streak? : Int = 0,
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
fn max_int(left : Int, right : Int) -> Int {
  if left > right {
    left
  } else {
    right
  }
}
