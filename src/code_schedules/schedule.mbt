///|
/// MoonTown owns the cadence and dispatch identity. MoonClaw owns the session
/// and every resulting Code turn.
pub struct CodeSchedule {
  id : String
  book_id : String
  book_root : String
  session_id : String
  prompt : String
  model : String
  interval_seconds : Int
  enabled : Bool
  next_due_at : Int64
  pending_command_id : String
  last_command_id : String
  last_status : String
  last_finished_at : Int64
  last_attempt_at : Int64?
} derive(Debug, ToJson, FromJson)

///|
pub struct CodeDispatchIntent {
  schedule_id : String
  command_id : String
  book_id : String
  book_root : String
  session_id : String
  prompt : String
  model : String
  due_at : Int64
} derive(Debug, ToJson, FromJson)

///|
fn valid_schedule_id(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 64 &&
  value.all(char => {
    (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') || char == '-'
  })
}

///|
pub fn CodeSchedule::new(
  id~ : String,
  book_id~ : String,
  book_root~ : String,
  session_id~ : String,
  prompt~ : String,
  model~ : String,
  interval_seconds~ : Int,
  now~ : Int64,
) -> Result[CodeSchedule, String] {
  if !valid_schedule_id(id) ||
    book_id.is_empty() ||
    book_root.is_empty() ||
    session_id.is_empty() ||
    prompt.trim().is_empty() ||
    prompt.length() > 4000 ||
    model.trim().is_empty() ||
    interval_seconds < 60 ||
    interval_seconds > 30 * 24 * 60 * 60 ||
    now < 0L {
    return Err("invalid Code schedule")
  }
  Ok({
    id,
    book_id,
    book_root,
    session_id,
    prompt,
    model,
    interval_seconds,
    enabled: true,
    next_due_at: now + interval_seconds.to_int64(),
    pending_command_id: "",
    last_command_id: "",
    last_status: "never-run",
    last_finished_at: 0L,
    last_attempt_at: Some(0L),
  })
}

///|
pub fn CodeSchedule::prepare_due(
  self : CodeSchedule,
  now : Int64,
) -> (CodeSchedule, CodeDispatchIntent)? {
  if !self.enabled || self.pending_command_id != "" || now < self.next_due_at {
    return None
  }
  let command_id = "code-schedule-\{self.id}-\{self.next_due_at}"
  let intent : CodeDispatchIntent = {
    schedule_id: self.id,
    command_id,
    book_id: self.book_id,
    book_root: self.book_root,
    session_id: self.session_id,
    prompt: self.prompt,
    model: self.model,
    due_at: self.next_due_at,
  }
  Some(
    (
      { ..self, pending_command_id: command_id, last_status: "dispatching", },
      intent,
    ),
  )
}

///|
pub fn CodeSchedule::mark_accepted(
  self : CodeSchedule,
  command_id : String,
) -> CodeSchedule? {
  if self.pending_command_id != command_id || command_id == "" {
    return None
  }
  Some({ ..self, last_command_id: command_id, last_status: "accepted", })
}

///|
pub fn CodeSchedule::mark_uncertain(
  self : CodeSchedule,
  command_id : String,
) -> CodeSchedule? {
  if self.pending_command_id != command_id || command_id == "" {
    return None
  }
  Some({ ..self, last_status: "uncertain", })
}

///|
pub fn CodeSchedule::mark_waiting(
  self : CodeSchedule,
  command_id : String,
  status : String,
) -> CodeSchedule? {
  if self.pending_command_id != command_id ||
    command_id == "" ||
    (status != "waiting-control" && status != "book-unavailable") {
    return None
  }
  Some({ ..self, last_status: status, })
}

///|
pub fn CodeSchedule::mark_terminal(
  self : CodeSchedule,
  command_id : String,
  status : String,
  now : Int64,
) -> CodeSchedule? {
  if self.pending_command_id != command_id ||
    command_id == "" ||
    (status != "done" && status != "failed" && status != "cancelled") ||
    now < 0L {
    return None
  }
  Some({
    ..self,
    pending_command_id: "",
    last_command_id: command_id,
    last_status: status,
    last_finished_at: now,
    next_due_at: now + self.interval_seconds.to_int64(),
  })
}

///|
pub fn CodeSchedule::pause(self : CodeSchedule) -> CodeSchedule {
  { ..self, enabled: false, }
}

///|
pub fn CodeSchedule::reactivate(
  self : CodeSchedule,
  now : Int64,
) -> CodeSchedule {
  {
    ..self,
    enabled: true,
    next_due_at: if self.pending_command_id == "" && self.next_due_at < now {
      now
    } else {
      self.next_due_at
    },
  }
}
