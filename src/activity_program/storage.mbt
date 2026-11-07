///|
async fn store_lock(path : String) -> @fs.File {
  @support.ensure_parent_directory(path)
  if @fs.exists(path) && !(@fs.kind(path, follow_symlink=false) is Regular) {
    raise Unavailable
  }
  let file = @fs.open(
    path,
    mode=ReadWrite,
    create_mode=OpenOrCreate,
    permission=0o600,
  )
  file.lock(Exclusive)
  file
}

///|
async fn registry_lock(root : String) -> @fs.File {
  ensure_root(root)
  store_lock(root + "/registry.lock")
}

///|
async fn gate_lock(root : String, application_id : String) -> @fs.File {
  guard valid_activity_id(application_id) else {
    raise Invalid("申请编号不可用。")
  }
  ensure_root(root)
  let gates = root + "/gates"
  if !@fs.exists(gates) {
    @fs.mkdir(gates, permission=0o700)
  }
  guard @fs.kind(gates, follow_symlink=false) is Directory else {
    raise Unavailable
  }
  store_lock(root + "/gates/" + application_id + ".lock")
}

///|
async fn ensure_root(root : String) -> Unit {
  guard root.has_prefix("/") &&
    !root.split("/").any(part => part == ".." || part == ".") else {
    raise Unavailable
  }
  if !@fs.exists(root) {
    @fs.mkdir(root, recursive=true, permission=0o700)
  }
  guard @fs.kind(root, follow_symlink=false) is Directory else {
    raise Unavailable
  }
}

///|
async fn read_registry(root : String) -> Registry {
  guard root.has_prefix("/") && !root.contains("/../") else {
    raise Unavailable
  }
  let path = root + "/registry.json"
  if !@fs.exists(path) {
    return empty_registry()
  }
  guard @fs.kind(path, follow_symlink=false) is Regular else {
    raise Unavailable
  }
  let state : Registry = @json.from_json(
    @json.parse(@fs.read_file(path).text()),
  )
  guard state.schema == "moontown.activity-program.v1" else {
    raise Unavailable
  }
  state
}

///|
async fn write_atomic(path : String, contents : String) -> Unit {
  @support.ensure_parent_directory(path)
  for name in [path, path + ".next"] {
    if @fs.exists(name) && !(@fs.kind(name, follow_symlink=false) is Regular) {
      raise Unavailable
    }
  }
  @fs.write_file(
    path + ".next",
    contents,
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(path + ".next", path, replace=true)
}

///|
async fn save_registry(root : String, state : Registry) -> Unit {
  write_atomic(root + "/registry.json", state.to_json().stringify())
}

///|
fn audit(
  state : Registry,
  action : String,
  actor : String,
  target : String,
  now : UInt64,
  detail : String,
) -> Registry {
  let revision = state.revision + 1
  {
    ..state,
    revision,
    audit: state.audit +
    [{ action, actor, target, revision, at_ms: now, detail, }],
  }
}

///|
async fn load_template(path : String) -> Template {
  guard path.has_prefix("/") && @fs.kind(path, follow_symlink=false) is Regular else {
    raise Unavailable
  }
  let raw = @json.parse(@fs.read_file(path).text())
  guard fields(raw).get("program_template") is Some(binding) else {
    raise Unavailable
  }
  let template_id = text(binding, "template_id", 80)
  guard template_id == "coffee-image-v1" else { raise Unavailable }
  let model = text(raw, "model", 128)
  guard !text(raw, "provider_origin", 512).is_empty() &&
    text(raw, "provider_key_file", 512).has_prefix("/") else {
    raise Unavailable
  }
  {
    raw,
    template_id,
    template_version: text(binding, "template_version", 80),
    template_hash: hash(raw.stringify()),
    book_id: text(binding, "book_id", 128),
    book_version: text(binding, "book_version", 80),
    curator_profile: text(binding, "curator_profile", 128),
    workflow_id: text(binding, "workflow_id", 128),
    workflow_version: text(binding, "workflow_version", 80),
    max_instances: integer(binding, "max_instances", 1, 52),
    max_total_quota: integer(binding, "max_total_quota", 1, 100000),
    max_event_quota: integer(binding, "max_event_quota", 1, 10000),
    max_participant_quota: integer(binding, "max_participant_quota", 1, 1000),
    max_cash_budget_cny: integer(binding, "max_cash_budget_cny", 0, 100000),
    max_grants: integer(binding, "max_grants", 1, 1000),
    model,
  }
}
