///|
pub(all) suberror ProgramError {
  Denied
  Invalid(String)
  Conflict(String)
  Unavailable
} derive(Debug)

///|
struct Application {
  id : String
  actor : String
  revision : Int32
  status : String
  title : String
  topic : String
  scope : String
  audience : String
  proposal : String
  prize_plan : String
  contact : String
  cash_budget_cny : Int32
  requested_instances : Int32
  requested_total_quota : Int32
  requested_participant_quota : Int32
  submitted_revision : Int32
  submitted_hash : String
  review_note : String
  created_ms : UInt64
  updated_ms : UInt64
} derive(ToJson, FromJson)

///|
struct Grant {
  id : String
  application_id : String
  organizer_id : String
  approved_revision : Int32
  approved_hash : String
  approved_by : String
  approved_ms : UInt64
  starts_ms : UInt64
  ends_ms : UInt64
  max_instances : Int32
  total_generation_quota : Int32
  per_event_quota : Int32
  participant_quota : Int32
  cash_budget_cny : Int32
  allow_publish : Bool
  template_id : String
  template_version : String
  template_hash : String
  status : String
  reason : String
} derive(ToJson, FromJson)

///|
struct Activity {
  id : String
  application_id : String
  organizer_id : String
  intent : String
  blueprint_hash : String
  status : String
  reason : String
  title : String
  topic : String
  scope : String
  first_person_solution : String
  prize_plan : String
  opens_ms : UInt64
  deadline_ms : UInt64
  voting_opens_ms : UInt64
  voting_closes_ms : UInt64
  awards_ms : UInt64
  event_quota : Int32
  participant_quota : Int32
  cash_budget_cny : Int32
  template_json : String
  dossier_json : String
  config_sha256 : String
  binding_json : String
  prepare_attempts : Int32
  published_ms : UInt64
  created_ms : UInt64
  updated_ms : UInt64
} derive(ToJson, FromJson)

///|
struct Audit {
  action : String
  actor : String
  target : String
  revision : Int32
  at_ms : UInt64
  detail : String
} derive(ToJson, FromJson)

///|
struct Registry {
  schema : String
  revision : Int32
  applications : Array[Application]
  grants : Array[Grant]
  activities : Array[Activity]
  audit : Array[Audit]
} derive(ToJson, FromJson)

///|
struct Template {
  raw : Json
  template_id : String
  template_version : String
  template_hash : String
  book_id : String
  book_version : String
  curator_profile : String
  workflow_id : String
  workflow_version : String
  max_instances : Int32
  max_total_quota : Int32
  max_event_quota : Int32
  max_participant_quota : Int32
  max_cash_budget_cny : Int32
  max_grants : Int32
  model : String
}

///|
/// A trusted route binding. Never serialize its private filesystem paths.
pub(all) struct Binding {
  id : String
  application_id : String
  organizer_id : String
  root_path : String
  state_path : String
  config_path : String
  status : String
  may_manage : Bool
  allow_generation : Bool
  book_binding : Json
  public_blueprint : Json
}

///|
fn empty_registry() -> Registry {
  {
    schema: "moontown.activity-program.v1",
    revision: 0,
    applications: [],
    grants: [],
    activities: [],
    audit: [],
  }
}

///|
fn hash(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))
}

///|
pub fn valid_activity_id(value : String) -> Bool {
  value.length() == 64 && value.all(c => c is ('0'..<='9' | 'a'..<='f'))
}

///|
fn fields(value : Json) -> Map[String, Json] {
  match value {
    Object(values) => values
    _ => Map([])
  }
}

///|
fn text(
  value : Json,
  key : String,
  limit : Int32,
  optional~ : Bool = false,
) -> String raise {
  let result = match fields(value).get(key) {
    Some(String(value)) => value.trim().to_owned()
    None if optional => ""
    _ => raise Invalid("请检查填写内容：" + key)
  }
  guard result.length() <= limit &&
    (optional || !result.is_empty()) &&
    !result.contains("\u0000") else {
    raise Invalid("请检查填写内容：" + key)
  }
  result
}

///|
fn integer(
  value : Json,
  key : String,
  minimum : Int32,
  maximum : Int32,
) -> Int32 raise {
  let parsed : Int32 = @json.from_json(
    fields(value).get(key).unwrap_or(Json::null()),
  ) catch {
    _ => raise Invalid("请检查数值：" + key)
  }
  guard parsed >= minimum && parsed <= maximum else {
    raise Invalid("数值超出允许范围：" + key)
  }
  parsed
}

///|
fn millis(value : Json, key : String) -> UInt64 raise {
  let parsed : UInt64 = @json.from_json(
    fields(value).get(key).unwrap_or(Json::null()),
  ) catch {
    _ => raise Invalid("请检查时间：" + key)
  }
  guard parsed > 0UL else { raise Invalid("请检查时间：" + key) }
  parsed
}

///|
fn bool(value : Json, key : String) -> Bool raise {
  match fields(value).get(key) {
    Some(True) => true
    Some(False) => false
    _ => raise Invalid("请确认选项：" + key)
  }
}

///|
fn proposal_hash(app : Application) -> String {
  hash(
    (
      {
        "id": app.id,
        "actor": app.actor,
        "submitted_revision": app.submitted_revision,
        "title": app.title,
        "topic": app.topic,
        "scope": app.scope,
        "audience": app.audience,
        "proposal": app.proposal,
        "prize_plan": app.prize_plan,
        "contact": app.contact,
        "cash_budget_cny": app.cash_budget_cny,
        "requested_instances": app.requested_instances,
        "requested_total_quota": app.requested_total_quota,
        "requested_participant_quota": app.requested_participant_quota,
      } : Json).stringify(),
  )
}

///|
fn clock_after(now : UInt64, started : Int64) -> UInt64 {
  now + (@async.now() - started).max(0L).reinterpret_as_uint64()
}
