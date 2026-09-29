///|
pub struct CodeScheduleState {
  schema : String
  revision : Int
  schedules : Array[CodeSchedule]
} derive(Debug, ToJson, FromJson)

///|
pub fn code_schedule_schema() -> String {
  "moontown.code-schedules.v1"
}

///|
pub fn default_code_schedule_path() -> String {
  @storage.moontown_product_state_dir() + "/code-schedules/state.json"
}

///|
fn empty_code_schedule_state() -> CodeScheduleState {
  { schema: code_schedule_schema(), revision: 0, schedules: [], }
}

///|
async fn load_code_schedule_state_unlocked(path : String) -> CodeScheduleState {
  if !@fs.exists(path) {
    return empty_code_schedule_state()
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    fail("Code schedule state is not a regular file")
  }
  let text = @fs.read_file(path).text() catch {
    error => fail("Code schedule state cannot be read: \{error}")
  }
  let state : CodeScheduleState = @json.from_json(@json.parse(text)) catch {
    error => fail("Code schedule state is invalid: \{error}")
  }
  guard state.schema == code_schedule_schema() && state.revision >= 0 else {
    fail("unsupported Code schedule state")
  }
  let ids : Map[String, Bool] = Map([])
  for schedule in state.schedules {
    if ids.contains(schedule.id) {
      fail("Code schedule state has duplicate IDs")
    }
    ids[schedule.id] = true
  }
  state
}

///|
async fn save_code_schedule_state_unlocked(
  path : String,
  state : CodeScheduleState,
) -> Unit {
  @support.ensure_parent_directory(path)
  let temporary = path + ".next"
  @fs.write_file(
    temporary,
    ToJson::to_json(state).stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temporary, path, replace=true)
}

///|
async fn code_schedule_lock(path : String) -> @fs.File {
  let lock_path = path + ".lock"
  @support.ensure_parent_directory(lock_path)
  let file = @fs.open(
    lock_path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  file.lock(Exclusive)
  file
}

///|
pub async fn load_code_schedule_state(
  path? : String = default_code_schedule_path(),
) -> CodeScheduleState {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  load_code_schedule_state_unlocked(path)
}

///|
pub async fn create_code_schedule(
  schedule : CodeSchedule,
  path? : String = default_code_schedule_path(),
) -> CodeScheduleState {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  if state.schedules.any(existing => {
      existing.id == schedule.id || existing.session_id == schedule.session_id
    }) {
    fail("Code schedule or session identity already exists")
  }
  let schedules = state.schedules.copy()
  schedules.push(schedule)
  let updated = { ..state, revision: state.revision + 1, schedules, }
  save_code_schedule_state_unlocked(path, updated)
  updated
}

///|
pub async fn reserve_due_code_schedule(
  now : Int64,
  path? : String = default_code_schedule_path(),
) -> CodeDispatchIntent? {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    match schedules[index].prepare_due(now) {
      Some((reserved, intent)) => {
        schedules[index] = reserved
        save_code_schedule_state_unlocked(path, {
          ..state,
          revision: state.revision + 1,
          schedules,
        })
        return Some(intent)
      }
      None => ()
    }
  }
  None
}

///|
/// Recover reservations after a daemon restart. The command identity and due
/// time remain unchanged until MoonClaw reports a terminal receipt.
pub async fn pending_code_schedule_intents(
  limit? : Int = 4,
  path? : String = default_code_schedule_path(),
) -> Array[CodeDispatchIntent] {
  let state = load_code_schedule_state(path~)
  let intents : Array[CodeDispatchIntent] = []
  for _ in 0..<limit {
    let mut oldest : CodeSchedule? = None
    for schedule in state.schedules {
      if schedule.pending_command_id == "" ||
        intents.any(intent => intent.schedule_id == schedule.id) {
        continue
      }
      match oldest {
        None => oldest = Some(schedule)
        Some(previous) if schedule.last_attempt_at.unwrap_or(0L) <
          previous.last_attempt_at.unwrap_or(0L) => oldest = Some(schedule)
        _ => ()
      }
    }
    match oldest {
      Some(schedule) =>
        intents.push({
          schedule_id: schedule.id,
          command_id: schedule.pending_command_id,
          book_id: schedule.book_id,
          book_root: schedule.book_root,
          session_id: schedule.session_id,
          prompt: schedule.prompt,
          model: schedule.model,
          due_at: schedule.next_due_at,
        })
      None => break
    }
  }
  intents
}

///|
pub async fn record_code_schedule_attempt(
  schedule_id : String,
  command_id : String,
  now : Int64,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id ||
      schedules[index].pending_command_id != command_id {
      continue
    }
    schedules[index] = { ..schedules[index], last_attempt_at: Some(now), }
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}

///|
pub async fn record_code_schedule_acceptance(
  schedule_id : String,
  command_id : String,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    guard schedules[index].mark_accepted(command_id) is Some(updated) else {
      return false
    }
    if schedules[index].last_status == "accepted" {
      return true
    }
    schedules[index] = updated
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}

///|
pub async fn record_code_schedule_uncertain(
  schedule_id : String,
  command_id : String,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    guard schedules[index].mark_uncertain(command_id) is Some(updated) else {
      return false
    }
    if schedules[index].last_status == "uncertain" {
      return true
    }
    schedules[index] = updated
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}

///|
pub async fn record_code_schedule_waiting(
  schedule_id : String,
  command_id : String,
  status : String,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    guard schedules[index].mark_waiting(command_id, status) is Some(updated) else {
      return false
    }
    if schedules[index].last_status == status {
      return true
    }
    schedules[index] = updated
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}

///|
pub async fn record_code_schedule_terminal(
  schedule_id : String,
  command_id : String,
  status : String,
  now : Int64,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    guard schedules[index].mark_terminal(command_id, status, now)
      is Some(updated) else {
      return false
    }
    schedules[index] = updated
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}

///|
pub async fn set_code_schedule_enabled(
  schedule_id : String,
  enabled : Bool,
  now : Int64,
  path? : String = default_code_schedule_path(),
) -> Bool {
  let lock = code_schedule_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_code_schedule_state_unlocked(path)
  let schedules = state.schedules.copy()
  for index in 0..<schedules.length() {
    if schedules[index].id != schedule_id {
      continue
    }
    let original = schedules[index]
    if original.enabled == enabled {
      return true
    }
    schedules[index] = if enabled {
      original.reactivate(now)
    } else {
      original.pause()
    }
    save_code_schedule_state_unlocked(path, {
      ..state,
      revision: state.revision + 1,
      schedules,
    })
    return true
  }
  false
}
