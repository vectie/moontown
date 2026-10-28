///|
let store_mutex : @async.Mutex = Mutex()

///|
pub fn default_neighborhood_path() -> String {
  @storage.moontown_product_state_dir() + "/neighborhood/state.json"
}

///|
async fn regular_or_missing(path : String) -> Unit {
  if @fs.exists(path) {
    guard @fs.kind(path, follow_symlink=false) is Regular else {
      fail("neighborhood store must use regular files")
    }
  }
}

///|
async fn store_lock(path : String) -> @fs.File {
  @support.ensure_parent_directory(path)
  regular_or_missing(path + ".lock")
  let file = @fs.open(
    path + ".lock",
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  file.lock(Exclusive)
  file
}

///|
async fn load_state(path : String) -> State {
  regular_or_missing(path)
  if !@fs.exists(path) {
    return empty_state()
  }
  let state : State = @json.from_json(@json.parse(@fs.read_file(path).text()))
  guard state.schema == "moontown.neighborhood-store.v1" && state.revision >= 0 else {
    fail("unsupported neighborhood state")
  }
  state
}

///|
async fn save_state(path : String, state : State) -> Unit {
  let temporary = path + ".next"
  regular_or_missing(temporary)
  @fs.write_file(
    temporary,
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temporary, path, replace=true)
}

///|
fn apply(
  state : State,
  operation : String,
  payload : Json,
  actor : String,
  can_host : Bool,
  now_ms : UInt64,
) -> State raise NeighborhoodError {
  let next = match operation {
    "save-story" => save_story(state, payload, actor, now_ms)
    "publish-story" => transition_story(state, payload, actor, now_ms, true)
    "withdraw-story" => transition_story(state, payload, actor, now_ms, false)
    "save-event" => save_event(state, payload, actor, now_ms, can_host)
    "publish-event" | "cancel-event" | "end-event" =>
      transition_event(state, payload, actor, now_ms, operation)
    "register" => register(state, payload, actor, now_ms)
    "cancel-registration" =>
      change_registration(state, payload, actor, now_ms, false)
    "check-in" => change_registration(state, payload, actor, now_ms, true)
    "request-follow-up" => request_followup(state, payload, actor, now_ms)
    "resolve-follow-up" => resolve_followup(state, payload, actor, now_ms)
    _ => raise InvalidRequest("unsupported operation")
  }
  { ..next, revision: state.revision + 1, }
}

///|
/// Durable neighborhood boundary. actor_id and can_host MUST be resolved
/// from the authenticated server session, never from a submitted JSON field.
/// path is server configuration, not an HTTP argument. No role is inferred
/// from an actor name. Existing resources always require their exact owner.
///
/// public is anonymous; mine and all writes require an authenticated actor.
/// Responses include a safe public snapshot plus only the caller's private
/// workspace. A successful mutation has been atomically persisted before return.
pub async fn execute(
  operation : String,
  payload : Json,
  now_ms : UInt64,
  actor_id : String?,
  path~ : String = default_neighborhood_path(),
  can_host~ : Bool = false,
) -> Json {
  let actor = if operation == "public" {
    None
  } else {
    Some(required_actor(actor_id))
  }
  store_mutex.acquire()
  defer store_mutex.release()
  let lock = store_lock(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_state(path)
  let next = match operation {
    "public" | "mine" => state
    _ => {
      let actor = required_actor(actor)
      let next = apply(state, operation, payload, actor, can_host, now_ms)
      save_state(path, next)
      next
    }
  }
  {
    "ok": true,
    "operation": operation,
    "payload": snapshot(next, actor, can_host),
  }
}
