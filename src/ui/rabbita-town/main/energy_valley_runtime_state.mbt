///|
fn energy_valley_runtime_schema() -> String {
  "moontown.energy-valley.runtime.v1"
}

///|
fn energy_valley_runtime_stale_after_ms() -> Double {
  75000.0
}

///|
fn energy_valley_runtime_loading_state() -> EnergyValleyRuntimeState {
  {
    phase: Loading,
    projection: None,
    version: 0,
    fresh_at_ms: -1.0,
    motion_started_at_ms: -1.0,
    error: "",
  }
}

///|
fn energy_valley_runtime_error_state(
  version : Int,
  message : String,
) -> EnergyValleyRuntimeState {
  {
    phase: Error,
    projection: None,
    version,
    fresh_at_ms: -1.0,
    motion_started_at_ms: -1.0,
    error: message,
  }
}

///|
fn energy_valley_runtime_work_status_is_valid(status : String) -> Bool {
  status == "queued" ||
  status == "assigned" ||
  status == "running" ||
  status == "waiting_review" ||
  status == "completed" ||
  status == "failed" ||
  status == "blocked"
}

///|
fn energy_valley_runtime_agent_status_is_valid(status : String) -> Bool {
  status == "idle" ||
  status == "assigned" ||
  status == "running" ||
  status == "waiting" ||
  status == "blocked" ||
  status == "offline"
}

///|
fn energy_valley_runtime_role_is_valid(role : String) -> Bool {
  role == "mayor" || role == "keeper" || role == "worker"
}

///|
fn energy_valley_runtime_source_is_valid(source : String) -> Bool {
  source == "town-runtime" ||
  source == "standing-goal" ||
  source == "watcher" ||
  source == "operator-request"
}

///|
fn energy_valley_runtime_activity_kind_is_valid(kind : String) -> Bool {
  match kind {
    "walking"
    | "researching"
    | "synthesizing"
    | "discussing"
    | "reviewing"
    | "revising"
    | "recovering"
    | "returning"
    | "idle" => true
    _ => false
  }
}

///|
fn energy_valley_runtime_optional_activity_label_is_valid(
  label : String?,
) -> Bool {
  match label {
    None => true
    Some(value) =>
      !value.is_empty() &&
      value.trim() == value &&
      value.length() <= 80 &&
      !value.contains("\n") &&
      !value.contains("\r") &&
      !value.contains("\t")
  }
}

///|
fn energy_valley_runtime_activity_metadata_is_valid(
  kind : String?,
  label : String?,
) -> Bool {
  match kind {
    None => label is None
    Some(value) =>
      energy_valley_runtime_activity_kind_is_valid(value) &&
      energy_valley_runtime_optional_activity_label_is_valid(label)
  }
}

///|
fn energy_valley_runtime_optional_identity_is_valid(identity : String?) -> Bool {
  match identity {
    None => true
    Some(value) => @domain_catalog.valid_catalog_identifier(value)
  }
}

///|
fn energy_valley_runtime_participant_status_is_valid(status : String) -> Bool {
  status == "unknown" || energy_valley_runtime_work_status_is_valid(status)
}

///|
fn energy_valley_runtime_collaboration_mode_is_valid(mode : String) -> Bool {
  mode == "sequential" || mode == "parallel" || mode == "unknown"
}

///|
fn energy_valley_runtime_result_kind_is_valid(kind : String) -> Bool {
  kind == "report" || kind == "evidence" || kind == "review" || kind == "site"
}

///|
fn energy_valley_runtime_result_url_is_safe(url : String) -> Bool {
  if !url.has_prefix("/book-output/") {
    return false
  }
  let lower = url.to_lower()
  if lower.contains("\\") ||
    lower.contains("..") ||
    lower.contains("%2e") ||
    lower.contains("%5c") ||
    lower.contains("%25") {
    return false
  }
  true
}

///|
fn energy_valley_runtime_sha256_digest_is_valid(value : String) -> Bool {
  if !value.has_prefix("sha256:") || value.length() != 71 {
    return false
  }
  for char in value[7:] {
    if !((char >= '0' && char <= '9') || (char >= 'a' && char <= 'f')) {
      return false
    }
  }
  true
}

///|
fn energy_valley_runtime_result_link_is_valid(
  link : EnergyValleyRuntimeResultLink,
) -> Bool {
  !link.label.trim().is_empty() &&
  energy_valley_runtime_result_kind_is_valid(link.kind) &&
  energy_valley_runtime_result_url_is_safe(link.url)
}

///|
fn energy_valley_runtime_optional_count_is_valid(value : Int?) -> Bool {
  match value {
    Some(count) => count >= 0
    None => true
  }
}

///|
fn energy_valley_runtime_progress_is_valid(
  progress : EnergyValleyRuntimeProgress,
) -> Bool {
  energy_valley_runtime_optional_count_is_valid(progress.checkedSources) &&
  energy_valley_runtime_optional_count_is_valid(progress.newSources) &&
  energy_valley_runtime_optional_count_is_valid(progress.acceptedFacts) &&
  energy_valley_runtime_optional_count_is_valid(progress.rejectedFacts) &&
  energy_valley_runtime_optional_count_is_valid(progress.pagesChanged)
}

///|
fn energy_valley_runtime_participant_is_valid(
  participant : EnergyValleyRuntimeParticipant,
) -> Bool {
  !participant.runId.trim().is_empty() &&
  !participant.family.trim().is_empty() &&
  energy_valley_runtime_participant_status_is_valid(participant.status)
}

///|
fn energy_valley_runtime_collaboration_is_valid(
  collaboration : EnergyValleyRuntimeCollaboration,
) -> Bool {
  energy_valley_runtime_collaboration_mode_is_valid(collaboration.mode) &&
  collaboration.participants.all(energy_valley_runtime_participant_is_valid)
}

///|
fn energy_valley_runtime_work_item_is_valid(
  task : EnergyValleyRuntimeWorkItem,
) -> Bool {
  let role_is_valid = match task.role {
    Some(role) => energy_valley_runtime_role_is_valid(role)
    None => true
  }
  let links_are_valid = match task.resultLinks {
    Some(links) => links.all(energy_valley_runtime_result_link_is_valid)
    None => true
  }
  let collaboration_is_valid = match task.collaboration {
    Some(value) => energy_valley_runtime_collaboration_is_valid(value)
    None => true
  }
  let progress_is_valid = match task.progress {
    Some(value) => energy_valley_runtime_progress_is_valid(value)
    None => true
  }
  let activity_is_valid = energy_valley_runtime_activity_metadata_is_valid(
    task.activityKind,
    task.activityLabel,
  )
  let identities_are_valid = @domain_catalog.valid_catalog_identifier(
      task.buildingModuleKey,
    ) &&
    energy_valley_runtime_optional_identity_is_valid(task.bookId) &&
    energy_valley_runtime_optional_identity_is_valid(
      task.originBuildingModuleKey,
    ) &&
    energy_valley_runtime_optional_identity_is_valid(
      task.destinationBuildingModuleKey,
    )
  !task.id.trim().is_empty() &&
  !task.title.trim().is_empty() &&
  energy_valley_runtime_work_status_is_valid(task.status) &&
  energy_valley_runtime_source_is_valid(task.source) &&
  role_is_valid &&
  links_are_valid &&
  collaboration_is_valid &&
  progress_is_valid &&
  activity_is_valid &&
  identities_are_valid
}

///|
fn energy_valley_runtime_agent_is_valid(
  agent : EnergyValleyRuntimeAgent,
) -> Bool {
  let activity_is_valid = energy_valley_runtime_activity_metadata_is_valid(
    agent.activityKind,
    agent.activityLabel,
  )
  let identities_are_valid = energy_valley_runtime_optional_identity_is_valid(
      agent.buildingModuleKey,
    ) &&
    energy_valley_runtime_optional_identity_is_valid(agent.bookId) &&
    energy_valley_runtime_optional_identity_is_valid(
      agent.originBuildingModuleKey,
    ) &&
    energy_valley_runtime_optional_identity_is_valid(
      agent.destinationBuildingModuleKey,
    )
  !agent.id.trim().is_empty() &&
  !agent.name.trim().is_empty() &&
  (
    agent.avatarRef is None ||
    agent.avatarRef == Some("avatar://otter-steward") ||
    agent.avatarRef == Some("avatar://moon-lantern")
  ) &&
  energy_valley_runtime_role_is_valid(agent.role) &&
  energy_valley_runtime_agent_status_is_valid(agent.status) &&
  activity_is_valid &&
  identities_are_valid
}

///|
fn energy_valley_runtime_projection_validation_error(
  projection : EnergyValleyRuntimeProjection,
) -> String {
  if projection.schema != energy_valley_runtime_schema() {
    return "Runtime projection schema is not supported."
  }
  if projection.mode != "live" && projection.mode != "unavailable" {
    return "Runtime projection mode is not supported."
  }
  if projection.mode == "live" &&
    !energy_valley_runtime_sha256_digest_is_valid(
      projection.knowledgeCatalogDigest.unwrap_or(""),
    ) {
    return "Runtime projection has no valid knowledge catalog digest."
  }
  if browser_timestamp_ms(projection.observedAt) < 0.0 {
    return "Runtime projection observedAt is not a valid timestamp."
  }
  if !projection.tasks.all(energy_valley_runtime_work_item_is_valid) {
    return "Runtime projection contains an invalid work item."
  }
  if !projection.agents.all(energy_valley_runtime_agent_is_valid) {
    return "Runtime projection contains an invalid agent."
  }
  ""
}

///|
fn energy_valley_runtime_state_at(
  state : EnergyValleyRuntimeState,
  now_ms : Double,
) -> EnergyValleyRuntimeState {
  let can_become_stale = state.phase == Live ||
    state.phase == Stale ||
    state.phase == Error
  if can_become_stale &&
    state.fresh_at_ms >= 0.0 &&
    now_ms - state.fresh_at_ms >= energy_valley_runtime_stale_after_ms() {
    { ..state, phase: Stale }
  } else {
    state
  }
}

///|
fn energy_valley_runtime_state_from_text(
  text : String,
  version : Int,
  now_ms : Double,
) -> EnergyValleyRuntimeState {
  if text.trim().is_empty() {
    if version == 0 {
      return energy_valley_runtime_loading_state()
    }
    return energy_valley_runtime_error_state(
      version, "The runtime endpoint returned an empty response.",
    )
  }
  let json = @json.parse(text) catch {
    _ =>
      return energy_valley_runtime_error_state(
        version, "The runtime endpoint returned malformed JSON.",
      )
  }
  let projection : EnergyValleyRuntimeProjection = @json.from_json(json) catch {
    _ =>
      return energy_valley_runtime_error_state(
        version, "The runtime projection does not match the expected contract.",
      )
  }
  if projection.mode == "error" {
    return energy_valley_runtime_error_state(
      version,
      projection.message.unwrap_or("Unable to read the MoonTown runtime."),
    )
  }
  let validation_error = energy_valley_runtime_projection_validation_error(
    projection,
  )
  if !validation_error.is_empty() {
    return energy_valley_runtime_error_state(version, validation_error)
  }
  if projection.mode == "unavailable" {
    return {
      phase: Unavailable,
      projection: Some(projection),
      version,
      fresh_at_ms: -1.0,
      motion_started_at_ms: -1.0,
      error: "",
    }
  }
  let observed_at_ms = browser_timestamp_ms(projection.observedAt)
  let fresh_at_ms = if observed_at_ms > now_ms {
    now_ms
  } else {
    observed_at_ms
  }
  energy_valley_runtime_state_at(
    {
      phase: Live,
      projection: Some(projection),
      version,
      fresh_at_ms,
      motion_started_at_ms: now_ms,
      error: "",
    },
    now_ms,
  )
}

///|
fn initial_energy_valley_runtime_state() -> EnergyValleyRuntimeState {
  energy_valley_runtime_state_from_text(
    load_bootstrap_energy_valley_runtime_json(),
    energy_valley_runtime_version(),
    browser_now_ms(),
  )
}

///|
fn refresh_energy_valley_runtime_state(
  version : Int,
  previous : EnergyValleyRuntimeState,
  now_ms : Double,
) -> EnergyValleyRuntimeState {
  if version == previous.version {
    return energy_valley_runtime_state_at(previous, now_ms)
  }
  let next = energy_valley_runtime_state_from_text(
    load_bootstrap_energy_valley_runtime_json(),
    version,
    now_ms,
  )
  if next.phase != Error {
    return next
  }
  match previous.projection {
    Some(projection) =>
      energy_valley_runtime_state_at(
        {
          phase: Error,
          projection: Some(projection),
          version,
          fresh_at_ms: previous.fresh_at_ms,
          motion_started_at_ms: previous.motion_started_at_ms,
          error: next.error,
        },
        now_ms,
      )
    None => next
  }
}

///|
fn energy_valley_runtime_can_claim_active_work(
  state : EnergyValleyRuntimeState,
) -> Bool {
  state.phase == Live
}
