///|
/// Errors safe for an HTTP adapter to map to 401/403/404/400/409.
pub(all) suberror NeighborhoodError {
  Unauthenticated
  Forbidden
  NotFound
  InvalidRequest(String)
  Conflict(String)
} derive(Debug, Eq)

///|
priv struct Story {
  id : String
  owner_id : String
  author_name : String?
  content_revision : Int32?
  title : String
  body : String
  state : String
  created_ms : UInt64
  updated_ms : UInt64
  published_ms : UInt64?
} derive(ToJson, FromJson)

///|
priv struct Event {
  id : String
  owner_id : String
  content_revision : Int32?
  title : String
  description : String
  location : String
  starts_ms : UInt64
  ends_ms : UInt64
  capacity : Int32
  state : String
  created_ms : UInt64
  updated_ms : UInt64
  published_ms : UInt64?
} derive(ToJson, FromJson)

///|
priv struct Registration {
  id : String
  event_id : String
  participant_id : String
  display_name : String
  contact : String
  state : String
  created_ms : UInt64
  updated_ms : UInt64
  checked_in_ms : UInt64?
} derive(ToJson, FromJson)

///|
priv struct Followup {
  id : String
  event_id : String
  participant_id : String
  message : String
  contact : String
  state : String
  next_step : String
  outcome : String
  created_ms : UInt64
  updated_ms : UInt64
  resolved_ms : UInt64?
} derive(ToJson, FromJson)

///|
priv struct State {
  schema : String
  revision : Int32
  stories : Array[Story]
  events : Array[Event]
  registrations : Array[Registration]
  followups : Array[Followup]
} derive(ToJson, FromJson)

///|
fn empty_state() -> State {
  {
    schema: "moontown.neighborhood-store.v1",
    revision: 0,
    stories: [],
    events: [],
    registrations: [],
    followups: [],
  }
}

///|
fn required_actor(actor_id : String?) -> String raise NeighborhoodError {
  match actor_id {
    Some(actor) if !actor.trim().is_empty() => actor
    _ => raise Unauthenticated
  }
}

///|
fn text_field(
  payload : Json,
  key : String,
  limit : Int32,
  optional~ : Bool = false,
) -> String raise NeighborhoodError {
  let text = match payload {
    Object(fields) =>
      match fields.get(key) {
        Some(String(value)) => value.trim().to_owned()
        None if optional => ""
        _ => raise InvalidRequest("invalid \{key}")
      }
    _ => raise InvalidRequest("expected an object")
  }
  guard text.length() <= limit && (optional || !text.is_empty()) else {
    raise InvalidRequest("invalid \{key}")
  }
  text
}

///|
fn consent(payload : Json) -> Unit raise NeighborhoodError {
  guard payload is { "consent": True, .. } else {
    raise InvalidRequest("explicit consent is required")
  }
}

///|
fn require_content_revision(
  payload : Json,
  current : Int32?,
) -> Unit raise NeighborhoodError {
  let expected : Int32 = number_field(payload, "expected_content_revision")
  guard expected == current.unwrap_or(0) else {
    raise Conflict("content changed; review the saved draft before publishing")
  }
}

///|
fn symbolic_id(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 80 &&
  value.iter().all(c => c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '-' | '_'))
}

///|
fn fresh_id(state : State, prefix : String) -> String {
  for serial = state.revision + 1; ; serial = serial + 1 {
    let candidate = "\{prefix}-\{serial}"
    if !state.stories.any(s => s.id == candidate) &&
      !state.events.any(e => e.id == candidate) &&
      !state.registrations.any(r => r.id == candidate) &&
      !state.followups.any(f => f.id == candidate) {
      return candidate
    }
  }
}

///|
fn object_id(
  payload : Json,
  key : String,
  fallback~ : String = "",
) -> String raise NeighborhoodError {
  let value = text_field(payload, key, 80, optional=!fallback.is_empty())
  let value = if value.is_empty() { fallback } else { value }
  guard symbolic_id(value) else { raise InvalidRequest("invalid \{key}") }
  value
}

///|
fn[T : @json.FromJson] number_field(
  payload : Json,
  key : String,
) -> T raise NeighborhoodError {
  let value = match payload {
    Object(fields) => fields.get(key).unwrap_or(Json::null())
    _ => Json::null()
  }
  @json.from_json(value) catch {
    _ => raise InvalidRequest("invalid \{key}")
  }
}

///|
fn timestamp_field(
  payload : Json,
  key : String,
) -> UInt64 raise NeighborhoodError {
  let value : Double = number_field(payload, key)
  guard value >= 0.0 && value <= 9007199254740991.0 && value.floor() == value else {
    raise InvalidRequest("invalid \{key}")
  }
  value.to_uint64()
}

///|
fn owner(actor : String, expected : String) -> Unit raise NeighborhoodError {
  guard actor == expected else { raise Forbidden }
}

///|
fn event_by_id(state : State, id : String) -> Event raise NeighborhoodError {
  state.events
  .iter()
  .find_first(e => e.id == id)
  .unwrap_or_else(() => raise NotFound)
}

///|
fn occupied(registration : Registration) -> Bool {
  registration.state == "confirmed" || registration.state == "checked_in"
}

///|
fn event_occupancy(state : State, event_id : String) -> Int32 {
  state.registrations
  .filter(r => r.event_id == event_id && occupied(r))
  .length()
}

///|
fn change_event(state : State, event : Event) -> State {
  {
    ..state,
    events: state.events.map(e => if e.id == event.id { event } else { e }),
  }
}
