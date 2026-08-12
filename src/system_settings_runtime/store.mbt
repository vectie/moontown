///|
let system_settings_store_mutex : @async.Mutex = Mutex()

///|
pub fn default_system_settings_path() -> String {
  @storage.moontown_product_state_dir() + "/system-settings/state.json"
}

///|
/// Fill newly introduced v1 setting fields from authoritative defaults while
/// preserving every stored value, revision, and audit event. This makes
/// additive settings releases forward-compatible with existing state files.
fn migrate_system_settings_state_json(value : Json) -> Json {
  guard value is Object(fields) &&
    fields.get("schema") ==
    Some(@system_settings.system_settings_schema().to_json()) &&
    fields.get("settings") is Some(Object(setting_fields)) &&
    @system_settings.default_system_settings().to_json()
    is Object(default_fields) else {
    return value
  }
  for key, default_value in default_fields {
    if setting_fields.get(key) is None {
      setting_fields[key] = default_value
    }
  }
  fields["settings"] = Json::object(setting_fields)
  Json::object(fields)
}

///|
async fn load_system_settings_state_unlocked(
  path : String,
) -> @system_settings.SystemSettingsState {
  let state : @system_settings.SystemSettingsState = match
    @support.read_optional_json_file(path) {
    Some(value) =>
      @json.from_json(migrate_system_settings_state_json(value)) catch {
        error => fail("system settings state is invalid: \{error}")
      }
    None => @system_settings.empty_system_settings_state()
  }
  if state.schema != @system_settings.system_settings_schema() {
    fail("unsupported system settings schema")
  }
  @system_settings.validate_system_settings(state.settings)
  state
}

///|
async fn save_system_settings_state_unlocked(
  path : String,
  state : @system_settings.SystemSettingsState,
) -> Unit {
  let temp = path + ".next"
  @support.ensure_parent_directory(path)
  @fs.write_file(
    temp,
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temp, path, replace=true)
}

///|
pub async fn load_and_install_system_settings(
  path? : String = default_system_settings_path(),
) -> @system_settings.SystemSettings {
  system_settings_store_mutex.acquire()
  defer system_settings_store_mutex.release()
  let state = load_system_settings_state_unlocked(path)
  @system_settings.install_system_settings(state.settings)
  state.settings
}

///|
pub async fn system_settings_management_snapshot(
  path? : String = default_system_settings_path(),
) -> Json {
  system_settings_store_mutex.acquire()
  defer system_settings_store_mutex.release()
  let state = load_system_settings_state_unlocked(path)
  @system_settings.install_system_settings(state.settings)
  @system_settings.system_settings_projection(state)
}

///|
pub async fn public_system_settings_snapshot(
  path? : String = default_system_settings_path(),
) -> Json {
  system_settings_store_mutex.acquire()
  defer system_settings_store_mutex.release()
  let state = load_system_settings_state_unlocked(path)
  @system_settings.install_system_settings(state.settings)
  {
    "schema": @system_settings.system_settings_schema(),
    "revision": state.revision,
    "settings": state.settings.to_json(),
    "catalog": @system_settings.system_settings_catalog(state.settings).to_json(),
  }
}

///|
fn changed_system_setting_keys(
  before : @system_settings.SystemSettings,
  after : @system_settings.SystemSettings,
) -> Array[String] {
  let changed : Array[String] = []
  guard before.to_json() is Object(before_fields) &&
    after.to_json() is Object(after_fields) else {
    return changed
  }
  for key, value in after_fields {
    if before_fields.get(key) != Some(value) {
      changed.push(key)
    }
  }
  changed
}

///|
pub async fn update_system_settings(
  body : String,
  actor_id~ : String,
  now_ms~ : UInt64,
  path? : String = default_system_settings_path(),
) -> Json {
  let request = @json.parse(body) catch {
    error => fail("invalid system settings JSON: \{error}")
  }
  guard request is Object(fields) &&
    fields.get("values") is Some(values_json) &&
    fields.get("expected_revision") is Some(expected_revision_json) else {
    fail("system settings request requires values and expected_revision")
  }
  let proposed : @system_settings.SystemSettings = @json.from_json(values_json) catch {
    error => fail("invalid system settings values: \{error}")
  }
  let expected_revision : Int = @json.from_json(expected_revision_json) catch {
    error => fail("invalid expected_revision: \{error}")
  }
  @system_settings.validate_system_settings(proposed)
  system_settings_store_mutex.acquire()
  defer system_settings_store_mutex.release()
  let state = load_system_settings_state_unlocked(path)
  if state.revision != expected_revision {
    fail("system settings changed since this page loaded; refresh and retry")
  }
  let changed_keys = changed_system_setting_keys(state.settings, proposed)
  if changed_keys.is_empty() {
    @system_settings.install_system_settings(state.settings)
    return @system_settings.system_settings_projection(state)
  }
  let revision = state.revision + 1
  let audit_events = state.audit_events.copy()
  audit_events.push({ revision, actor_id, changed_keys, occurred_at_ms: now_ms })
  while audit_events.length() > proposed.account_audit_capacity {
    ignore(audit_events.remove(0))
  }
  let next : @system_settings.SystemSettingsState = {
    ..state,
    settings: proposed,
    revision,
    audit_events,
  }
  save_system_settings_state_unlocked(path, next)
  @system_settings.install_system_settings(proposed)
  @system_settings.system_settings_projection(next)
}
