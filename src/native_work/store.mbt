///|
async fn lock_state(path : String) -> @fs.File {
  @support.ensure_parent_directory(path + ".lock")
  let lock = @fs.open(
    path + ".lock",
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  lock.lock(Exclusive)
  lock
}

///|
async fn load_unlocked(path : String) -> State {
  if !@fs.exists(path) {
    return { schema: "moontown.native-work.v1", revision: 0, work: [], }
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    fail("native_work_state_invalid")
  }
  let state : State = @json.from_json(@json.parse(@fs.read_file(path).text()))
  guard state.schema == "moontown.native-work.v1" && state.revision >= 0 else {
    fail("native_work_schema_invalid")
  }
  let ids : Map[String, Bool] = Map([])
  for work in state.work {
    guard !ids.contains(work.id) &&
      work.request_digest == digest(work.request.to_json().stringify()) &&
      work.request.input_digest == digest(work.request.prompt) else {
      fail("native_work_identity_invalid")
    }
    ids[work.id] = true
    if work.reservation is Some(reservation) {
      guard reservation.body_digest == digest(reservation.request_body) &&
        reservation.model_workspace == work.request.owner_workspace &&
        reservation.execution_root == work.request.execution_root else {
        fail("native_work_reservation_invalid")
      }
    }
    if work.control is Some(control) {
      guard work.reservation is Some(reservation) &&
        control.command_id == work.id + "-cancel" &&
        control.target_command_id == reservation.command_id &&
        control.body_digest == digest(control.request_body) &&
        control.request_body == cancel_body(work, reservation) else {
        fail("native_work_control_invalid")
      }
    }
  }
  state
}

///|
async fn save_unlocked(path : String, state : State) -> Unit {
  @support.ensure_parent_directory(path)
  @fs.write_file(
    path + ".next",
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(path + ".next", path, replace=true)
  sync_state_directories(path)
}

///|
/// Persist the renamed reservation and recursively created parent entries
/// before permitting a network submission, including first-creation races.
#cfg(not(platform="windows"))
async fn sync_state_directories(path : String) -> Unit {
  let mut current = @pathx.dirname(path).to_owned()
  while true {
    let directory = @fs.open(current, mode=ReadOnly)
    defer directory.close()
    directory.sync()
    let parent = @pathx.dirname(current).to_owned()
    if parent == current {
      break
    }
    current = parent
  }
}

///|
/// Windows has no supported POSIX directory-fsync primitive; only the file
/// bytes are flushed there. Power-loss guarantees are limited accordingly.
#cfg(platform="windows")
async fn sync_state_directories(path : String) -> Unit {
  ignore(path)
}

///|
pub async fn load(path? : String = default_path()) -> State {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  load_unlocked(path)
}

///|
/// Reserve one logical generation before any runtime/model lookup. A changed
/// default or later producer input never changes pending work.
pub async fn enqueue(
  request : Request,
  path? : String = default_path(),
) -> Work {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_unlocked(path)
  let mut generation = if request.kind == "wenyu_build" {
    request.generation.max(1)
  } else {
    1
  }
  for existing in state.work {
    if request.kind != "wenyu_build" &&
      (!terminal(existing.state) || editor_owner_pending(existing)) &&
      existing.request.kind == request.kind &&
      (
        request.kind == "book_quality_review" ||
        existing.request.book_root == request.book_root
      ) {
      return existing
    }
    if existing.request.work_key != request.work_key {
      continue
    }
    if request.kind == "wenyu_build" &&
      (
        existing.request.kind != request.kind ||
        (
          request.generation > 0 &&
          existing.request.generation != request.generation
        )
      ) {
      continue
    }
    // Zero asks the owner to reuse or advance its logical generation. A
    // positive Wenyu generation names that exact saved attempt, even after
    // supersession; stale replay cannot allocate a duplicate successor.
    if request.kind == "wenyu_build" && request.generation > 0 {
      return existing
    }
    if existing.state != "superseded" {
      return existing
    }
    generation = generation.max(existing.request.generation + 1)
  }
  let request = { ..request, generation, }
  let hash = digest(request.to_json().stringify())
  let work : Work = {
    id: "town-work-" + hash[:32].to_owned(),
    request,
    request_digest: hash,
    state: "queued",
    blocked_reason: "",
    reservation: None,
    control: None,
    baseline: Json::null(),
    observed_instances: [],
    last_attempt_at_ms: 0UL,
    retry_after_ms: 0UL,
    output: "",
    receipt: Json::null(),
  }
  let work_items = state.work.copy()
  work_items.push(work)
  save_unlocked(path, {
    ..state,
    revision: state.revision + 1,
    work: work_items,
  })
  work
}

///|
fn replace_work(state : State, updated : Work) -> State {
  {
    ..state,
    revision: state.revision + 1,
    work: state.work.map(work => {
      if work.id == updated.id {
        updated
      } else {
        work
      }
    }),
  }
}

///|
/// Explicitly replace unsubmitted setup-blocked work after correcting inputs.
/// Accepted/uncertain native commands must first be cancelled at their native
/// control surface; supersession cannot silently abandon their late effects.
pub async fn supersede(
  id : String,
  expected_revision : Int,
  path? : String = default_path(),
) -> Work {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_unlocked(path)
  if state.revision != expected_revision {
    fail("native_work_revision_conflict")
  }
  for work in state.work {
    if work.id != id {
      continue
    }
    if work.reservation is Some(_) && !terminal(work.state) {
      fail("native_work_cancel_required_before_supersession")
    }
    let updated = {
      ..work,
      state: "superseded",
      blocked_reason: "explicit_owner_supersession",
    }
    save_unlocked(path, replace_work(state, updated))
    return updated
  }
  fail("native_work_not_found")
}
