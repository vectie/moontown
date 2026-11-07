///|
fn action_application_id(
  state : Registry,
  action : String,
  payload : Json,
  actor : String,
) -> String raise {
  if action == "save-application" {
    let id = text(payload, "application_id", 64, optional=true)
    if id.is_empty() {
      return hash("application:" + actor + ":" + text(payload, "intent", 128))
    }
    return id
  }
  if ["publish-activity", "pause-activity", "resume-activity", "retry-activity"].contains(
      action,
    ) {
    return find_activity(state, text(payload, "activity_id", 64)).application_id
  }
  text(payload, "application_id", 64)
}

///|
/// Organizer workflow authority is supplied by the authenticated gateway.
/// It never changes the platform account's roles or accepts runtime paths from payloads.
pub async fn execute(
  action : String,
  payload : Json,
  now : UInt64,
  actor : String?,
  owner : Bool,
  root : String,
  template_path : String,
) -> Json {
  let started = @async.now()
  let template = load_template(template_path)
  if action == "snapshot" {
    let lock = registry_lock(root)
    defer lock.close()
    defer lock.unlock()
    return snapshot(read_registry(root), template, now, actor, owner)
  }
  guard actor is Some(who) && !who.is_empty() else { raise Denied }
  let initial = read_registry(root)
  let application_id = action_application_id(initial, action, payload, who)
  let gate = gate_lock(root, application_id)
  defer gate.close()
  defer gate.unlock()
  let lock = registry_lock(root)
  defer lock.close()
  defer lock.unlock()
  let state = read_registry(root)
  let now = clock_after(now, started)
  let (next, target) = match action {
    "save-application" => save_application(state, payload, who, now, template)
    "submit-application" => submit_application(state, payload, who, now)
    "review-application" =>
      review_application(state, payload, who, owner, now, template)
    "create-activity" => create_activity(state, payload, who, now, template)
    "publish-activity"
    | "pause-activity"
    | "resume-activity"
    | "retry-activity" =>
      control_activity(state, action, payload, who, owner, now)
    "revoke-grant" => revoke_grant(state, payload, who, owner, now)
    _ => raise Invalid("活动操作不存在。")
  }
  if next.revision != state.revision {
    save_registry(root, next)
  }
  let result = snapshot(next, template, now, actor, owner)
  fields(result)[if [
      "create-activity", "publish-activity", "pause-activity", "resume-activity",
      "retry-activity",
    ].contains(action) {
    "activity_id"
  } else {
    "application_id"
  }] = Json::string(target)
  result
}
