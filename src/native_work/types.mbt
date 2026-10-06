///|
/// Immutable owner-composed work. Book context, model owner, and execution root
/// deliberately have separate fields. Neither browser input nor cwd chooses roots.
pub(all) struct Request {
  kind : String
  work_key : String
  generation : Int
  owner_workspace : String
  book_id : String
  book_root : String
  book_type : String
  catalog_path : String
  execution_root : String
  source_binding : Json
  criterion_id : String
  model_request : String
  prompt : String
  input_blocker : String
  input_digest : String
  output_contract : String
  result_path : String
  acceptance_policy : Json
  created_at_ms : UInt64
} derive(ToJson, FromJson)

///|
pub(all) struct Reservation {
  session_id : String
  command_id : String
  model : String
  model_workspace : String
  execution_root : String
  config_path : String
  request_body : String
  body_digest : String
  reserved_at_ms : UInt64
} derive(ToJson, FromJson)

///|
pub(all) struct Work {
  id : String
  request : Request
  request_digest : String
  state : String
  blocked_reason : String
  reservation : Reservation?
  control : CancelControl?
  baseline : Json
  observed_instances : Array[String]
  last_attempt_at_ms : UInt64
  retry_after_ms : UInt64
  output : String
  receipt : Json
} derive(ToJson, FromJson)

///|
/// A separately durable exact-target control, never a replacement prompt.
pub(all) struct CancelControl {
  command_id : String
  target_command_id : String
  request_body : String
  body_digest : String
  status : String
  last_attempt_at_ms : UInt64
  evidence : Json
} derive(ToJson, FromJson)

///|
pub(all) struct State {
  schema : String
  revision : Int
  work : Array[Work]
} derive(ToJson, FromJson)

///|
pub fn digest(text : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(text)))
}

///|
pub fn default_path() -> String {
  @storage.moontown_product_state_dir() + "/native-work/state.json"
}

///|
pub fn path_for_snapshot(snapshot_path : String) -> String {
  @storage.snapshot_base_dir(snapshot_path) + "/native-work/state.json"
}

///|
pub fn summary(work : Work) -> String {
  "Native " +
  work.request.kind +
  " `" +
  work.id +
  "`: " +
  owner_status(work) +
  (if text(work.receipt, "engineering_status") == "applied_and_validated" {
    "; Applied and validated; uncommitted"
  } else if text(work.receipt, "engineering_status") == "no_change" {
    "; No net source change; required checks passed; original-task acceptance unevaluated"
  } else {
    ""
  }) +
  (if work.blocked_reason == "" {
    ""
  } else {
    " (" +
    public_blocker(work.blocked_reason) +
    ")" +
    (if blocker_help(work.blocked_reason, work.reservation is Some(_)) == "" {
      ""
    } else {
      "; " + blocker_help(work.blocked_reason, work.reservation is Some(_))
    })
  })
}

///|
pub async fn render_status(path? : String = default_path()) -> String {
  if !@fs.exists(path) {
    return "No native Town work"
  }
  let state = load(path~)
  if state.work.is_empty() {
    return "No native Town work"
  }
  state.work.map(work => summary(work)).join("\n")
}

///|
pub fn terminal(state : String) -> Bool {
  ["completed", "failed", "cancelled", "superseded"].contains(state)
}

///|
fn field(value : Json, key : String) -> Json {
  match value {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
}

///|
fn text(value : Json, key : String) -> String {
  match field(value, key) {
    String(value) => value
    _ => ""
  }
}

///|
fn rows(value : Json, key : String) -> Array[Json] {
  match field(value, key) {
    Array(value) => value
    _ => []
  }
}

///|
fn waiting(work : Work, state : String, reason : String, now : UInt64) -> Work {
  {
    ..work,
    state,
    blocked_reason: reason,
    last_attempt_at_ms: now,
    retry_after_ms: now + 30000UL,
  }
}
