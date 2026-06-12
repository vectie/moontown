///|
struct VisualBuildingActivity {
  running_count : Int
  waiting_count : Int
  review_count : Int
  blocked_count : Int
  completed_count : Int
} derive(Debug, Eq)

///|
fn VisualBuildingActivity::for_book(
  state : @core.TownState,
  book_id : String,
) -> VisualBuildingActivity {
  {
    running_count: visual_count_book_phases(state, book_id, fn(phase) {
      visual_phase_is_working(phase) || phase == "persisting"
    }),
    waiting_count: visual_count_book_phases(state, book_id, fn(phase) {
      visual_phase_is_handoff(phase) || phase == "waiting"
    }),
    review_count: visual_count_book_phases(state, book_id, fn(phase) {
      phase == "review"
    }),
    blocked_count: visual_count_book_phases(
      state, book_id, visual_phase_is_recovery,
    ),
    completed_count: visual_count_book_phases(
      state, book_id, visual_phase_is_completed_or_idle,
    ),
  }
}

///|
fn VisualBuildingActivity::effect(self : VisualBuildingActivity) -> String {
  if self.blocked_count > 0 {
    "alert-pulse"
  } else if self.review_count > 0 {
    "review-glow"
  } else if self.running_count > 0 {
    "work-particles"
  } else if self.waiting_count > 0 {
    "packet-pulse"
  } else {
    "none"
  }
}

///|
fn VisualBuildingActivity::module_status(
  self : VisualBuildingActivity,
) -> String {
  if self.blocked_count > 0 {
    "alert"
  } else if self.review_count > 0 {
    "review"
  } else if self.running_count > 0 {
    "running"
  } else if self.waiting_count > 0 {
    "waiting"
  } else if self.completed_count > 0 {
    "complete"
  } else {
    "calm"
  }
}

///|
fn VisualBuildingActivity::message(
  self : VisualBuildingActivity,
  book : @core.BookRef,
) -> String {
  if self.blocked_count > 0 {
    "\{book.name} needs recovery for \{self.blocked_count} blocked or failed worker(s)."
  } else if self.review_count > 0 {
    "\{book.name} has \{self.review_count} worker(s) in review."
  } else if self.running_count > 0 {
    "\{book.name} has \{self.running_count} active worker(s)."
  } else if self.waiting_count > 0 {
    "\{book.name} has \{self.waiting_count} worker(s) waiting for handoff."
  } else {
    "\{book.name} is quiet; idle workers stay inside until selected."
  }
}
