///|
/// Read-only listing for the supervised worker. Paths never enter UI snapshots.
pub async fn list_activities(root : String) -> Array[String] {
  let lock = registry_lock(root)
  defer lock.close()
  defer lock.unlock()
  read_registry(root).activities
  .filter(activity => {
    activity.published_ms > 0UL &&
    !["preparing", "failed"].contains(activity.status) &&
    valid_activity_id(activity.config_sha256)
  })
  .map(activity => activity.id)
}

///|
fn binding_for(
  activity : Activity,
  grant : Grant,
  now : UInt64,
  actor : String?,
  owner : Bool,
  root : String,
) -> Binding {
  let root_path = root + "/activities/" + activity.id
  {
    id: activity.id,
    application_id: activity.application_id,
    organizer_id: activity.organizer_id,
    root_path,
    state_path: root_path + "/state.json",
    config_path: root_path + "/config.json",
    status: activity.status,
    may_manage: owner ||
    (actor == Some(activity.organizer_id) && grant_live(grant, now)),
    allow_generation: activity.status == "published" && grant_live(grant, now),
    book_binding: clean_binding(activity.binding_json),
    public_blueprint: public_blueprint(activity),
  }
}

///|
async fn checked_binding(
  id : String,
  now : UInt64,
  actor : String?,
  owner : Bool,
  mode : String,
  root : String,
) -> Binding {
  let lock = registry_lock(root)
  defer lock.close()
  defer lock.unlock()
  let state = read_registry(root)
  let activity = find_activity(state, id)
  let grant = find_grant(state, activity.application_id)
  let binding = binding_for(activity, grant, now, actor, owner, root)
  let public = activity.published_ms > 0UL &&
    ["published", "paused", "revoked"].contains(activity.status)
  if ["snapshot", "public", "image", "worker"].contains(mode) {
    guard public ||
      (
        mode != "public" &&
        (owner || actor == Some(activity.organizer_id)) &&
        activity.status == "ready"
      ) else {
      raise Denied
    }
  } else if ["generate", "submit", "vote", "cancel-vote"].contains(mode) {
    guard actor is Some(_) && binding.allow_generation else { raise Denied }
  } else if mode == "withdraw" {
    guard public && actor is Some(_) else { raise Denied }
  } else if [
      "approve", "reject", "disqualify", "set-voting-url", "award", "publish-results",
      "resolve-failed", "settlement",
    ].contains(mode) {
    guard binding.may_manage && public else { raise Denied }
  } else {
    raise Invalid("活动路由操作不可用。")
  }
  guard @fs.exists(binding.config_path) &&
    @fs.kind(binding.config_path, follow_symlink=false) is Regular &&
    hash(@fs.read_file(binding.config_path).text()) == activity.config_sha256 else {
    raise Unavailable
  }
  binding
}

///|
/// The gate is linearized with revoke/pause and held during a trusted callback.
/// The short registry lock is released before model or image I/O begins.
pub async fn[T] with_activity(
  id : String,
  now : UInt64,
  actor : String?,
  owner : Bool,
  mode : String,
  root : String,
  body : async (Binding) -> T,
) -> T {
  guard valid_activity_id(id) else { raise Denied }
  if ["snapshot", "public", "image", "settlement"].contains(mode) {
    return body(checked_binding(id, now, actor, owner, mode, root))
  }
  let state = read_registry(root)
  let activity = find_activity(state, id)
  let started = @async.now()
  let gate = gate_lock(root, activity.application_id)
  defer gate.close()
  defer gate.unlock()
  let binding = checked_binding(
    id,
    clock_after(now, started),
    actor,
    owner,
    mode,
    root,
  )
  body(binding)
}

///|
async fn prepare_activity(
  root : String,
  activity : Activity,
  now : UInt64,
  prepare : async (String, Json, String) -> Json,
) -> Bool {
  let started = @async.now()
  let directory = root + "/activities/" + activity.id
  if !@fs.exists(root + "/activities") {
    @fs.mkdir(root + "/activities", permission=0o700)
  }
  guard @fs.kind(root + "/activities", follow_symlink=false) is Directory else {
    raise Unavailable
  }
  if !@fs.exists(directory) {
    @fs.mkdir(directory, permission=0o700)
  }
  guard @fs.kind(directory, follow_symlink=false) is Directory else {
    raise Unavailable
  }
  let config = activity_config(activity)
  for
    (name, contents) in [
      ("config.json", config),
      ("launch.json", activity.dossier_json),
    ] {
    let path = directory + "/" + name
    if @fs.exists(path) {
      guard @fs.kind(path, follow_symlink=false) is Regular &&
        @fs.read_file(path).text() == contents else {
        raise Conflict("已准备的活动资料与批准版本不一致。")
      }
    } else {
      write_atomic(path, contents)
    }
  }
  let receipt = prepare(
    activity.id,
    @json.parse(activity.dossier_json),
    directory,
  )
  guard receipt is { "ready": True, .. } else { raise Unavailable }
  let dossier = @json.parse(activity.dossier_json)
  for
    key in [
      "book_version", "curator_profile", "workflow_id", "workflow_version",
    ] {
    guard text(receipt, key, 128) == text(dossier, key, 128) else {
      raise Unavailable
    }
  }
  guard text(receipt, "source_book_id", 128) == text(dossier, "book_id", 128) &&
    text(receipt, "agent_state", 80) == "configured-not-started" &&
    text(receipt, "book_id", 128).all(c => {
      c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9' | '-' | '_' | '.' | ':')
    }) else {
    raise Unavailable
  }
  for key in ["source_bundle_digest", "launch_digest", "profile_digest"] {
    let digest = text(receipt, key, 80)
    guard valid_activity_id(
      digest.strip_prefix("sha256:").unwrap_or(digest[:]).to_owned(),
    ) else {
      raise Unavailable
    }
  }
  let binding_json = receipt.stringify()
  write_atomic(
    directory + "/binding.json",
    clean_binding(binding_json).stringify(),
  )
  let lock = registry_lock(root)
  defer lock.close()
  defer lock.unlock()
  let state = read_registry(root)
  let current = find_activity(state, activity.id)
  let grant = find_grant(state, activity.application_id)
  let completed_ms = clock_after(now, started)
  guard current.status == "preparing" && grant_live(grant, completed_ms) else {
    raise Denied
  }
  let ready = {
    ..current,
    status: if grant.allow_publish {
      "published"
    } else {
      "ready"
    },
    reason: "",
    binding_json,
    config_sha256: hash(config),
    prepare_attempts: current.prepare_attempts + 1,
    published_ms: if grant.allow_publish {
      completed_ms
    } else {
      0UL
    },
    updated_ms: completed_ms,
  }
  let activities = state.activities.map(value => {
    if value.id == activity.id {
      ready
    } else {
      value
    }
  })
  save_registry(
    root,
    audit(
      { ..state, activities, },
      "prepare-activity",
      "system",
      activity.id,
      completed_ms,
      ready.status,
    ),
  )
  true
}

///|
/// Materialize one durable creation intent. A failed bridge never becomes published.
pub async fn process_next(
  root : String,
  template_path : String,
  now : UInt64,
  prepare : async (String, Json, String) -> Json,
) -> Bool {
  let started = @async.now()
  // Readiness requires an explicitly installed trusted template, even on restart.
  let _ = load_template(template_path)
  let pending = read_registry(root).activities
    .iter()
    .find_first(activity => activity.status == "preparing")
  guard pending is Some(activity) else { return false }
  let gate = gate_lock(root, activity.application_id)
  defer gate.close()
  defer gate.unlock()
  let current = read_registry(root)
  let activity = find_activity(current, activity.id)
  if activity.status != "preparing" {
    return false
  }
  let grant = find_grant(current, activity.application_id)
  let admitted_now = clock_after(now, started)
  let outcome = if grant_live(grant, admitted_now) {
    prepare_activity(root, activity, admitted_now, prepare) catch {
      _ => false
    }
  } else {
    false
  }
  if outcome {
    return true
  }
  let lock = registry_lock(root)
  defer lock.close()
  defer lock.unlock()
  let state = read_registry(root)
  let finished_now = clock_after(now, started)
  let failed = {
    ..find_activity(state, activity.id),
    status: "failed",
    reason: "活动资料或资源尚未就绪，请联系主办检查后重试。",
    prepare_attempts: activity.prepare_attempts + 1,
    updated_ms: finished_now,
  }
  let activities = state.activities.map(value => {
    if value.id == failed.id {
      failed
    } else {
      value
    }
  })
  save_registry(
    root,
    audit(
      { ..state, activities, },
      "prepare-activity-failed",
      "system",
      failed.id,
      finished_now,
      "readiness-not-confirmed",
    ),
  )
  true
}
