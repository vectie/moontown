///|
pub async fn edit_code_schedule(
  schedule_id : String,
  prompt~ : String,
  model~ : String,
  title~ : String,
  interval_seconds~ : Int,
  next_due_at~ : Int64,
  repeat~ : Bool,
  recurrence? : String = "interval",
  timezone? : String = "UTC",
  path? : String = default_code_schedule_path(),
) -> CodeScheduleState {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    let rescheduled = match
      schedules[index].reschedule(
        prompt~,
        model~,
        title~,
        interval_seconds~,
        next_due_at~,
        repeat~,
      ) {
      Ok(value) => value
      Err(error) => fail(error)
    }
    schedules[index] = rescheduled.with_calendar(recurrence, timezone)
    let updated = { ..state, revision: state.revision + 1, schedules, }
    save_code_schedule_state_unlocked(path, updated)
    return updated
  }
  fail("Code schedule ID was not found")
}

///|
pub async fn run_code_schedule_now(
  schedule_id : String,
  now : Int64,
  path? : String = default_code_schedule_path(),
) -> CodeScheduleState {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    if schedules[index].pending_command_id != "" {
      return state
    }
    schedules[index] = { ..schedules[index], next_due_at: now, enabled: true, }
    let updated = { ..state, revision: state.revision + 1, schedules, }
    save_code_schedule_state_unlocked(path, updated)
    return updated
  }
  fail("Code schedule ID was not found")
}

///|
pub async fn delete_code_schedule(
  schedule_id : String,
  path? : String = default_code_schedule_path(),
) -> CodeScheduleState {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  if state.schedules.any(schedule => {
      schedule.id == schedule_id && schedule.pending_command_id != ""
    }) {
    fail("Code schedule is running; delete after this run finishes")
  }
  let schedules = state.schedules.filter(schedule => schedule.id != schedule_id)
  if schedules.length() == state.schedules.length() {
    fail("Code schedule ID was not found")
  }
  let updated = { ..state, revision: state.revision + 1, schedules, }
  save_code_schedule_state_unlocked(path, updated)
  updated
}
