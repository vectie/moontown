///|
fn latest_runtime_observation(
  store : SupervisorSetupStore,
  supervisor_profile_id : String,
) -> SupervisorRuntimeObservation? {
  let mut latest : SupervisorRuntimeObservation? = None
  for observation in store.runtime_observations {
    if observation.supervisor_profile_id == supervisor_profile_id &&
      latest
      .map(item => item.runtime_cursor < observation.runtime_cursor)
      .unwrap_or(true) {
      latest = Some(observation)
    }
  }
  latest
}

///|
fn latest_profile_by_id(
  store : SupervisorSetupStore,
  profile_id : String,
) -> SupervisorProfile? {
  let mut latest : SupervisorProfile? = None
  for profile in store.profiles {
    if profile.profile_id == profile_id &&
      latest.map(item => item.revision < profile.revision).unwrap_or(true) {
      latest = Some(profile)
    }
  }
  latest
}

///|
fn json_array(fields : Map[String, Json], key : String) -> Array[Json] {
  match fields.get(key) {
    Some(Array(values)) => values
    _ => []
  }
}

///|
fn validate_observed_workers(
  status_fields : Map[String, Json],
  supervisor_id : String,
  parent_run_id : String,
) -> Unit raise {
  for worker in json_array(status_fields, "workers") {
    guard worker is Object(worker_fields) else {
      fail("MoonClaw worker observation must be an object")
    }
    if json_string(worker_fields, "contract_id") !=
      "moonclaw.supervisor-worker-status.v1" ||
      json_string(worker_fields, "supervisor_id") != supervisor_id ||
      json_string(worker_fields, "parent_run_id") != parent_run_id ||
      json_string(worker_fields, "worker_run_id").is_empty() ||
      json_string(worker_fields, "worker_job_id").is_empty() ||
      !worker_execution_status_allowed(
        json_string(worker_fields, "execution_status"),
      ) {
      fail(
        "MoonClaw worker observation has invalid identity, lineage, or status",
      )
    }
  }
}

///|
pub async fn SupervisorSetupApplication::reconcile_runtime_observation(
  self : SupervisorSetupApplication,
  transport_id : String,
  body : String,
  now_ms~ : UInt64,
) -> Json {
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("runtime observation body must be an object")
  }
  let supervisor_id = json_string_alias(fields, "supervisorId", "supervisor_id")
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  guard fields.get("observation") is Some(Object(observation_fields)) else {
    fail("runtime observation envelope is required")
  }
  let observation_supervisor_id = json_string(
    observation_fields, "supervisor_id",
  )
  let runtime_cursor = json_int_alias(
    observation_fields, "runtimeCursor", "runtime_cursor",
  )
  let observation_digest = json_string(observation_fields, "observation_digest")
  let status_projection = observation_fields
    .get("status_projection")
    .unwrap_or(Json::null())
  let event_replay = observation_fields
    .get("event_replay")
    .unwrap_or(Json::null())
  guard status_projection is Object(status_fields) &&
    event_replay is Object(replay_fields) else {
    fail(
      "runtime observation requires exact status_projection and event_replay",
    )
  }
  let state = json_object(status_fields, "state")
  let state_profile = json_object(state, "profile")
  let parent_run_id = json_string(state, "active_run_id")
  let canonical_observation : Json = {
    "supervisor_id": observation_supervisor_id,
    "runtime_cursor": runtime_cursor,
    "status_projection": status_projection,
    "event_replay": event_replay,
  }
  if supervisor_id.is_empty() ||
    supervisor_id != observation_supervisor_id ||
    expected_cursor < 0 ||
    runtime_cursor < 0 ||
    json_string(observation_fields, "contract_id") !=
    "moonsuite.supervisor-runtime-observation.v1" ||
    observation_digest != sha256_json(canonical_observation) ||
    json_string(status_fields, "contract_id") != "moonclaw.supervisor-status.v1" ||
    json_string(state, "contract_id") != "moonclaw.supervisor-state.v1" ||
    json_string(state, "supervisor_id") != supervisor_id ||
    json_string_alias(state_profile, "profileId", "profile_id") != supervisor_id ||
    json_int_alias(state, "cursor", "cursor") != runtime_cursor ||
    parent_run_id.is_empty() ||
    json_string(replay_fields, "contract_id") != "moonclaw.supervisor-replay.v1" ||
    json_string(replay_fields, "supervisor_id") != supervisor_id ||
    json_int_alias(replay_fields, "nextCursor", "next_cursor") != runtime_cursor {
    fail("runtime observation contract, digest, identity, or cursor is invalid")
  }
  validate_observed_workers(status_fields, supervisor_id, parent_run_id)
  let store = self.load_store()
  let profile = latest_profile_by_id(store, supervisor_id).unwrap_or_else(() => {
    fail("runtime observation supervisor profile does not exist")
  })
  let activation = latest_activation_for_profile(store, profile.profile_id)
  if activation_runtime_run_id(activation) != Some(parent_run_id) {
    fail(
      "runtime observation parent run is not the acknowledged supervisor run",
    )
  }
  match activation_runtime_cursor(activation) {
    Some(cursor) if runtime_cursor < cursor =>
      fail(
        "runtime observation cursor cannot precede activation acknowledgement",
      )
    _ => ()
  }
  match latest_runtime_observation(store, supervisor_id) {
    Some(previous) if previous.runtime_cursor == runtime_cursor &&
      previous.request_digest == observation_digest =>
      return {
        "ok": true,
        "cursor": store.cursor,
        "supervisorId": supervisor_id,
        "runtimeCursor": runtime_cursor,
        "observationDigest": observation_digest,
        "status": "reconciled",
      }
    Some(previous) if runtime_cursor <= previous.runtime_cursor =>
      fail("runtime observation cursor must advance monotonically")
    _ => ()
  }
  if store.cursor != expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  let observation : SupervisorRuntimeObservation = {
    schema: "moonsuite.supervisor-runtime-observation.v1",
    observation_id: "supervisor-observation-\{supervisor_id}-\{runtime_cursor}",
    request_digest: observation_digest,
    supervisor_profile_id: supervisor_id,
    parent_run_id,
    runtime_cursor,
    status_projection,
    event_replay,
    received_from: transport_id,
    received_at_ms: now_ms,
  }
  let next = {
    ..store,
    cursor: store.cursor + 1,
    runtime_observations: store.runtime_observations + [observation],
  }
  self.save_store(next)
  {
    "ok": true,
    "cursor": next.cursor,
    "supervisorId": supervisor_id,
    "runtimeCursor": runtime_cursor,
    "observationDigest": observation_digest,
    "status": "reconciled",
  }
}
