///|
fn safe_profile_id(value : String) -> String {
  let builder = StringBuilder::new()
  for char in value.to_lower() {
    if (char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '-' {
      builder.write_char(char)
    } else {
      builder.write_char('-')
    }
  }
  builder.to_string().trim(chars="-").to_owned()
}

///|
fn profile_request_json(
  actor_user_id : String,
  draft : SupervisorProfileDraft,
) -> Json {
  {
    "actorUserId": actor_user_id,
    "commandId": draft.command_id,
    "expectedVersion": draft.expected_version,
    "expectedCursor": draft.expected_cursor,
    "profileId": draft.profile_id,
    "displayName": draft.display_name,
    "avatarUrl": wire_string_or_null(draft.avatar_url),
    "role": draft.role,
    "mission": draft.mission,
    "tone": draft.tone,
    "capabilities": draft.capabilities.to_json(),
    "workspaceId": draft.workspace_id,
    "buildingId": draft.building_id,
    "bookIds": draft.book_ids.to_json(),
    "maxActiveWorkers": draft.max_active_workers,
    "authorityCeiling": draft.authority_ceiling.id(),
    "consent": {
      "termsVersion": draft.consent.terms_version,
      "profileActivation": draft.consent.profile_activation,
      "runtimeDelegation": draft.consent.runtime_delegation,
      "bookkeeperReview": draft.consent.bookkeeper_review,
      "confirmedAtMs": wire_uint64_or_null(draft.consent.confirmed_at_ms),
    },
  }
}

///|
fn profile_id_owned_by_other(
  store : SupervisorSetupStore,
  profile_id : String,
  actor_user_id : String,
) -> Bool {
  store.profiles.any(profile => {
    profile.profile_id == profile_id && profile.owner_user_id != actor_user_id
  })
}

///|
fn supervisor_avatar_allowed(value : String?) -> Bool {
  value is None ||
  value == Some("avatar://otter-steward") ||
  value == Some("avatar://moon-lantern")
}

///|
fn supervisor_capabilities_allowed(values : Array[String]) -> Bool {
  if values.is_empty() || values.length() > 3 {
    return false
  }
  let seen : Array[String] = []
  for value in values {
    let id = value.trim().to_owned()
    if id.is_empty() || seen.contains(id) {
      return false
    }
    seen.push(id)
  }
  true
}

///|
pub async fn SupervisorSetupApplication::save_profile_draft(
  self : SupervisorSetupApplication,
  actor_user_id : String,
  draft : SupervisorProfileDraft,
  now_ms~ : UInt64,
) -> Json {
  if !supervisor_avatar_allowed(draft.avatar_url) ||
    !supervisor_capabilities_allowed(draft.capabilities) ||
    draft.max_active_workers <= 0 ||
    draft.max_active_workers > 3 {
    fail(
      "supervisor profile requires an allowlisted avatar, 1-3 unique capabilities, and a worker ceiling from 1 through 3",
    )
  }
  supervisor_store_mutex.acquire()
  defer supervisor_store_mutex.release()
  let store = self.load_store()
  let request_digest = sha256_json(profile_request_json(actor_user_id, draft))
  match
    idempotent_response(
      store,
      actor_user_id,
      draft.command_id,
      "profile.save",
      request_digest,
    ) {
    Some(response) => return response
    None => ()
  }
  if store.cursor != draft.expected_cursor {
    fail("supervisor setup cursor conflict")
  }
  let current = latest_profile_for_owner(store, actor_user_id)
  let current_revision = current.map(profile => profile.revision).unwrap_or(0)
  if current_revision != draft.expected_version {
    fail("supervisor profile version conflict")
  }
  let profile_id = if draft.profile_id.is_blank() {
    "supervisor-\{safe_profile_id(actor_user_id)}"
  } else {
    safe_profile_id(draft.profile_id)
  }
  if profile_id.is_blank() ||
    profile_id_owned_by_other(store, profile_id, actor_user_id) {
    fail("supervisor profile identity is invalid or owned by another user")
  }
  let consent = {
    ..draft.consent,
    confirmed_at_ms: if draft.consent.profile_activation &&
      (
        draft.authority_ceiling == SuggestOnly ||
        draft.consent.runtime_delegation
      ) &&
      (
        draft.authority_ceiling != RequestBookkeeperReview ||
        draft.consent.bookkeeper_review
      ) {
      Some(now_ms)
    } else {
      None
    },
  }
  let provisional : SupervisorProfile = {
    schema: supervisor_profile_schema(),
    profile_id,
    owner_user_id: actor_user_id,
    identity: { display_name: draft.display_name, avatar_url: draft.avatar_url },
    role: draft.role,
    mission: draft.mission,
    tone: draft.tone,
    capabilities: draft.capabilities,
    bindings: {
      workspace_id: draft.workspace_id,
      building_id: draft.building_id,
      book_ids: draft.book_ids,
      max_active_workers: draft.max_active_workers,
    },
    authority_ceiling: draft.authority_ceiling,
    revision: current_revision + 1,
    lifecycle: SupervisorDraft,
    consent,
    content_digest: "",
    created_at_ms: current
    .map(profile => profile.created_at_ms)
    .unwrap_or(now_ms),
    updated_at_ms: now_ms,
  }
  let with_readiness = {
    ..provisional,
    lifecycle: if provisional.ready() {
      SupervisorReady
    } else {
      SupervisorDraft
    },
  }
  let profile = {
    ..with_readiness,
    content_digest: supervisor_profile_digest(with_readiness),
  }
  let next_cursor = store.cursor + 1
  let updated = {
    ..store,
    cursor: next_cursor,
    profiles: store.profiles + [profile],
    audit_events: store.audit_events +
    [
      {
        event_id: "audit-\{draft.command_id}",
        command_id: draft.command_id,
        actor_user_id,
        action: if current is None {
          "supervisor.created"
        } else {
          "supervisor.updated"
        },
        object_id: profile.profile_id,
        from_revision: current_revision,
        to_revision: profile.revision,
        cursor: next_cursor,
        recorded_at_ms: now_ms,
      },
    ],
  }
  let response = profile_response(updated, Some(profile))
  self.save_store(
    append_idempotency(
      updated,
      actor_user_id,
      draft.command_id,
      "profile.save",
      request_digest,
      response,
    ),
  )
  response
}
