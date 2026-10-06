///|
fn reserve(
  work : Work,
  client : @native_code_control.Client,
  model : String,
  now : UInt64,
) -> Work {
  let request = work.request
  let command_id = work.id +
    (if request.kind == "book_quality_review" {
      "-review"
    } else if request.kind == "wenyu_build" {
      "-build"
    } else {
      "-repair"
    })
  let review = request.kind == "book_quality_review"
  let task_contract : Json = {
    "scope": clean_source_scopes(work.baseline),
    "preserve_unrelated_dirty_work": true,
  }
  if !review &&
    task_contract is Object(fields) &&
    field(request.acceptance_policy, "completion_policy") != Json::null() {
    fields["completion_policy"] = field(
      request.acceptance_policy,
      "completion_policy",
    )
  }
  if request.kind == "wenyu_build" && task_contract is Object(fields) {
    fields["owner_work_id"] = work.id.to_json()
    fields["owner_book_id"] = request.book_id.to_json()
    fields["owner_task_id"] = field(request.acceptance_policy, "task_id")
    fields["owner_goal_id"] = field(request.acceptance_policy, "goal_id")
    fields["output_contract"] = request.output_contract.to_json()
    // MoonCode preserves constraints in its compacted long-horizon context,
    // even when the original source/Book context exceeds its text budget.
    fields["constraints"] = [
      (if wenyu_no_change_enabled(request) {
        "Return exactly these nine finish JSON keys with your summary, behavior and residual_risks; preserve all owner identities. Choose outcome no_change for verified already-satisfied work or implemented for attested mutation: "
      } else {
        "Return exactly this finish JSON schema with your summary, behavior and residual_risks; preserve all owner identities: "
      }) +
      wenyu_finish_schema(work).stringify(),
      if wenyu_no_change_enabled(request) {
        wenyu_completion_guidance(work)
      } else {
        "Attested source mutation and every frozen validation command are required; no no-change completion, commit, push, or Book-root writes."
      },
      "Frozen validation commands (run each separately after the final source mutation): " +
      field(request.acceptance_policy, "required_validation_commands").stringify(),
    ].to_json()
  }
  if editor_spec(request) is Some(_) && task_contract is Object(fields) {
    fields["owner_work_id"] = work.id.to_json()
    fields["owner_book_id"] = request.book_id.to_json()
    fields["output_contract"] = request.output_contract.to_json()
    fields["constraints"] = [
      "Return the exact owner-issued finish JSON schema and preserve its identities: " +
      editor_finish_schema(work).stringify(),
      "Book/course inputs are captured read-only context. Only the frozen source execution root is writable. Never write owner outputs, commit or push. No-change is engineering-only and cannot accept a selected feature.",
      "Run each frozen validation command separately after the final source mutation: " +
      field(request.acceptance_policy, "required_validation_commands").stringify(),
    ].to_json()
  }
  let body : Json = {
    "protocol": "mooncode.v1",
    "session_id": work.id,
    "book_root": request.execution_root,
    "model_workspace": request.owner_workspace,
    "command": "prompt",
    "model": model,
    "text": if request.kind == "wenyu_build" {
      wenyu_reserved_prompt(work)
    } else if editor_spec(request) is Some(_) {
      editor_reserved_prompt(work)
    } else {
      request.prompt
    },
    "packet": { "command_id": command_id },
    "web_search": false,
    "payload": {
      "task_intent": if review {
        "read_only"
      } else {
        "workspace_change"
      },
      "planner_allowed_tools": if review {
        ["read", "view_image", "read_skill", "finish"]
      } else {
        [
          "checkpoint", "read", "read_skill", "moon_ide", "write", "edit", "apply_patch",
          "moon_cmd", "shell", "finish",
        ]
      },
      "task_contract": if review {
        Json::null()
      } else {
        task_contract
      },
    },
  }
  let body = body.stringify()
  {
    ..work,
    reservation: Some({
      session_id: work.id,
      command_id,
      model,
      model_workspace: request.owner_workspace,
      execution_root: request.execution_root,
      config_path: client.config_path,
      request_body: body,
      body_digest: digest(body),
      reserved_at_ms: now,
    }),
    observed_instances: [client.instance_id],
    state: "queued",
    blocked_reason: "",
  }
}

///|
async fn validate_book(request : Request) -> Bool {
  let catalog = @moonbook.load_or_create_catalog(path=request.catalog_path)
  match @moonbook.find_catalog_entry(catalog, request.book_id) {
    Some(entry) =>
      entry.workspace_root == request.book_root &&
      @fs.kind(request.book_root, follow_symlink=false) is Directory &&
      @fs.realpath(request.book_root) == request.book_root
    None => false
  }
}

///|
/// Same owner path for daemon and explicit retry. Persist before network and
/// retain the lock through observation/resubmit so concurrent consumers cannot
/// rotate identities. HTTP calls have bounded timeouts; task lifetime does not.
/// Callers may require a saved revision; omitted revisions preserve CLI/daemon
/// behavior. Check it under the owner lock before applying even a saved result.
pub async fn sync(
  id : String,
  now : UInt64,
  path? : String = default_path(),
  client? : @native_code_control.Client,
  force? : Bool = false,
  expected_revision? : Int,
) -> Work {
  let lock = lock_state(path)
  defer lock.close()
  defer lock.unlock()
  let state = load_unlocked(path)
  if expected_revision is Some(revision) && revision != state.revision {
    fail("native_work_revision_conflict")
  }
  let mut selected : Work? = None
  for work in state.work {
    if work.id == id {
      selected = Some(work)
    }
  }
  guard selected is Some(original) else { fail("native_work_not_found") }
  if terminal(original.state) {
    let applied = apply_owner_result(original)
    if applied.to_json() != original.to_json() {
      save_unlocked(path, replace_work(state, applied))
    }
    return applied
  }
  if !force &&
    (
      now < original.retry_after_ms ||
      original.blocked_reason == "control_authority_denied"
    ) {
    return original
  }
  let mut work = original
  if work.control is Some(_) {
    work = cancel_with_saved_client(work, client, now, path)
  } else if work.request.input_blocker != "" {
    work = waiting(work, "waiting_input", work.request.input_blocker, now)
  } else if editor_owner_opted_in(work.request) &&
    editor_spec(work.request) is None {
    work = waiting(work, "waiting_input", "editor_owner_policy_invalid", now)
  } else if work.request.kind == "wenyu_build" &&
    !wenyu_policy_valid(work.request) {
    work = waiting(work, "waiting_input", "wenyu_native_policy_invalid", now)
  } else if work.request.kind == "wenyu_build" &&
    source_root(work.request.source_binding) != work.request.execution_root {
    work = waiting(
      work, "waiting_source_binding", "source_execution_root_mismatch", now,
    )
  } else if !validate_book(work.request) {
    work = waiting(work, "waiting_book", "book_binding_unavailable", now)
  } else if is_workspace_change(work.request.kind) &&
    !source_still_bound(
      work.request.source_binding,
      strict_digest=work.reservation is None,
    ) {
    work = waiting(
      work, "waiting_source_binding", "source_binding_stale_or_unavailable", now,
    )
  } else if work.request.kind == "planbook_repair" &&
    text(work.request.acceptance_policy, "commit_requirement") == "required" {
    work = waiting(
      work, "blocked_commit_capability", "selective_commit_receipt_unavailable: saved commit requirement preserved",
      now,
    )
  } else {
    let loaded = match client {
      Some(client) => Ok(client)
      None =>
        @native_code_control.load(
          path=work.reservation
            .map(item => item.config_path)
            .unwrap_or(@native_code_control.configured_path()),
          owner_workspace=work.request.owner_workspace,
        )
    }
    work = match loaded {
      Err(reason) => waiting(work, "waiting_control", reason, now)
      Ok(client) =>
        if client.owner_workspace != work.request.owner_workspace {
          waiting(work, "waiting_control", "control_owner_mismatch", now)
        } else {
          let result = sync_with_client(work, client, now, path, state)
          result
        }
    }
  }
  if work.to_json().stringify() != original.to_json().stringify() {
    save_unlocked(path, replace_work(load_unlocked(path), work))
  }
  let applied = apply_owner_result(work)
  if applied.to_json() != work.to_json() {
    save_unlocked(path, replace_work(load_unlocked(path), applied))
  }
  let work = applied
  work
}

///|
async fn sync_with_client(
  original : Work,
  client : @native_code_control.Client,
  now : UInt64,
  path : String,
  state : State,
) -> Work {
  let mut work = original
  if work.reservation is None {
    let blocker = workspace_reservation_blocker(state, work)
    if blocker != "" {
      return waiting(work, "queued", blocker, now)
    }
    if is_workspace_change(work.request.kind) {
      let baseline = source_snapshot(work.request.execution_root) catch {
        _ =>
          return waiting(
            work, "waiting_source_binding", "source_baseline_unavailable", now,
          )
      }
      if clean_source_scopes(baseline).is_empty() {
        return waiting(
          work, "waiting_source_binding", "no_safe_clean_source_scope", now,
        )
      }
      work = { ..work, baseline, }
    }
    let capabilities = match
      client.request("GET", "/v1/code/capabilities", "") {
      Ok(value) => value
      Err(reason) => return waiting(work, "waiting_control", reason, now)
    }
    if work.request.kind == "book_quality_review" &&
      text(capabilities, "read_only_execution_contract") !=
      "mooncode.read-only-execution.v1" {
      return waiting(
        work, "waiting_native_capability", "read_only_execution_unavailable", now,
      )
    }
    if text(capabilities, "model_workspace_contract") !=
      "mooncode.model-workspace.v1" {
      return waiting(
        work, "waiting_native_capability", "model_workspace_binding_unavailable",
        now,
      )
    }
    if field(work.request.acceptance_policy, "completion_policy") !=
      Json::null() &&
      text(capabilities, "completion_outcome_contract") !=
      "mooncode.completion-outcome.v1" {
      return waiting(
        work, "waiting_native_capability", "completion_outcome_unavailable", now,
      )
    }
    let route = match client.request("GET", "/v1/moongate-route", "") {
      Ok(route) => route
      Err(reason) => return waiting(work, "waiting_model", reason, now)
    }
    let model = match
      @native_code_control.select_model(route, work.request.model_request) {
      Ok(model) => model
      Err(reason) => return waiting(work, "waiting_model", reason, now)
    }
    work = reserve(work, client, model, now)
    save_unlocked(path, replace_work(state, work))
  }
  let reservation = work.reservation.unwrap()
  if client.config_path != reservation.config_path {
    return waiting(work, "waiting_control", "control_reference_changed", now)
  }
  let base = "/v1/code/sessions/" +
    @native_code_control.url_component(reservation.session_id)
  let query = "?book_root=" +
    @native_code_control.url_component(reservation.execution_root)
  let claims = client.request("GET", base + "/runtime-claim" + query, "")
  match claims {
    Ok(claim) => {
      let events = match
        client.request("GET", base + "/runtime-events" + query, "") {
        Ok(value) => value
        Err(reason) => return waiting(work, "dispatch_uncertain", reason, now)
      }
      let service = match
        client.request("GET", base + "/runtime-service" + query, "") {
        Ok(value) => value
        Err(reason) => return waiting(work, "dispatch_uncertain", reason, now)
      }
      let observed = observe(
        work,
        claim,
        events,
        service,
        client.instance_id,
        now,
      )
      if terminal(observed.state) ||
        observed.state == "awaiting_approval" ||
        observed.blocked_reason != "" {
        return observed
      }
      work = observed
    }
    Err(reason) if reason == "native_not_found" =>
      if !work.observed_instances.contains(client.instance_id) {
        return waiting(
          work, "dispatch_uncertain", "runtime_continuity_unverified", now,
        )
      }
    Err(reason) => return waiting(work, "dispatch_uncertain", reason, now)
  }
  // Reuse exact saved bytes even after uncertainty or a default change. Native
  // duplicate handling starts/reuses the existing durable command service.
  match client.request("POST", base + "/turns", reservation.request_body) {
    Ok(reply) if field(reply, "accepted") == true.to_json() &&
      text(reply, "session_id") == reservation.session_id &&
      text(reply, "command_id") == reservation.command_id &&
      text(reply, "book_root") == reservation.execution_root =>
      waiting(work, "running", "", now)
    Ok(_) =>
      waiting(
        work, "dispatch_uncertain", "native_acceptance_identity_mismatch", now,
      )
    Err(reason) => waiting(work, "dispatch_uncertain", reason, now)
  }
}
