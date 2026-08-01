///|
let supervisor_store_mutex : @async.Mutex = @async.Mutex()

///|
fn migrate_supervisor_store_json(value : Json) -> Json {
  guard value is Object(fields) else { return value }
  if fields.get("runtime_observations") is None {
    fields["runtime_observations"] = Json::array([])
  }
  match fields.get("profiles") {
    Some(Array(profiles)) =>
      for profile in profiles {
        guard profile is Object(profile_fields) &&
          profile_fields.get("bindings") is Some(Object(bindings)) else {
          continue
        }
        if bindings.get("max_active_workers") is None {
          bindings["max_active_workers"] = (3 : Int).to_json()
        }
      }
    _ => ()
  }
  match fields.get("execution_handoffs") {
    Some(Array(handoffs)) =>
      for handoff in handoffs {
        guard handoff is Object(handoff_fields) else { continue }
        let action = json_string(handoff_fields, "action")
        let legacy_run_id = json_string(handoff_fields, "run_id")
        if handoff_fields.get("parent_run_id") is None {
          handoff_fields["parent_run_id"] = legacy_run_id.to_json()
        }
        if handoff_fields.get("target_run_id") is None && action != "delegate" {
          handoff_fields["target_run_id"] = legacy_run_id.to_json()
        } else if handoff_fields.get("target_run_id") is Some(Null) {
          handoff_fields.remove("target_run_id")
        }
        if handoff_fields.get("command_kind") is None {
          handoff_fields["command_kind"] = execution_command_kind(action).to_json()
        }
        if handoff_fields.get("worker_bounds_source") is None {
          handoff_fields["worker_bounds_source"] = "legacy_unbounded".to_json()
        }
        for optional_field in [
          "worker_task", "worker_bounds", "transport_request_digest",
          "transport_endpoint", "transport_request", "runtime_command",
        ] {
          if handoff_fields.get(optional_field) is Some(Null) {
            handoff_fields.remove(optional_field)
          }
        }
      }
    _ => ()
  }
  match fields.get("activation_handoffs") {
    Some(Array(handoffs)) =>
      for handoff in handoffs {
        guard handoff is Object(handoff_fields) &&
          handoff_fields.get("payload") is Some(Object(payload_fields)) else {
          continue
        }
        match payload_fields.get("activated_at") {
          Some(Number(value, ..)) => {
            payload_fields["activated_at"] = value
              .to_uint64()
              .to_string()
              .to_json()
            let prior_status = json_string(handoff_fields, "status")
            if prior_status == "runtime_acknowledged" {
              handoff_fields["status"] = "runtime_acknowledged_legacy_timestamp".to_json()
            } else {
              handoff_fields["request_digest"] = sha256_json(
                Json::object(payload_fields),
              ).to_json()
              handoff_fields["status"] = "pending_transport".to_json()
              handoff_fields.remove("claimed_by")
              handoff_fields.remove("runtime_command")
              handoff_fields.remove("runtime_receipt")
            }
          }
          _ => ()
        }
      }
    _ => ()
  }
  match fields.get("review_requests") {
    Some(Array(requests)) =>
      for request in requests {
        guard request is Object(request_fields) else { continue }
        if request_fields.get("resume_state") is Some(Null) {
          request_fields.remove("resume_state")
        }
      }
    _ => ()
  }
  Json::object(fields)
}

///|
fn SupervisorSetupApplication::store_path(
  self : SupervisorSetupApplication,
) -> String {
  self.state_root + "/supervisor-setup/state.json"
}

///|
async fn SupervisorSetupApplication::load_store(
  self : SupervisorSetupApplication,
) -> SupervisorSetupStore {
  match @support.read_optional_json_file(self.store_path()) {
    None => empty_supervisor_setup_store()
    Some(value) => {
      let store : SupervisorSetupStore = @json.from_json(
        migrate_supervisor_store_json(value),
      ) catch {
        error =>
          fail(
            "supervisor setup state is not a valid versioned store: \{error}",
          )
      }
      if store.schema != supervisor_store_schema() {
        fail("unsupported supervisor setup store schema: \{store.schema}")
      }
      store
    }
  }
}

///|
async fn SupervisorSetupApplication::save_store(
  self : SupervisorSetupApplication,
  store : SupervisorSetupStore,
) -> Unit {
  let path = self.store_path()
  let temp = path + ".next"
  @support.ensure_parent_directory(path)
  @fs.write_file(
    temp,
    store.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temp, path, replace=true)
}

///|
fn idempotent_response(
  store : SupervisorSetupStore,
  actor_user_id : String,
  command_id : String,
  operation : String,
  request_digest : String,
) -> Json? raise {
  for record in store.idempotency {
    if record.command_id == command_id && record.actor_user_id == actor_user_id {
      if record.operation != operation ||
        record.request_digest != request_digest {
        fail("commandId already exists with different content")
      }
      return Some(record.response)
    }
  }
  None
}

///|
fn append_idempotency(
  store : SupervisorSetupStore,
  actor_user_id : String,
  command_id : String,
  operation : String,
  request_digest : String,
  response : Json,
) -> SupervisorSetupStore {
  {
    ..store,
    idempotency: store.idempotency +
    [{ command_id, actor_user_id, operation, request_digest, response }],
  }
}
