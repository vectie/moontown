///|
pub fn parse_supervisor_profile_draft(
  body : String,
) -> SupervisorProfileDraft raise {
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("supervisor draft body must be a JSON object")
  }
  let persona = json_object(fields, "persona")
  let bindings = json_object(fields, "bindings")
  let consents = json_object(fields, "consents")
  let command_id = json_string_alias(fields, "commandId", "command_id")
  let profile_id = json_string_alias(fields, "profileId", "profile_id")
  let display_name = {
    let nested = json_string_alias(persona, "displayName", "display_name")
    if nested.is_empty() {
      let direct = json_string_alias(fields, "displayName", "display_name")
      if direct.is_empty() {
        json_string(fields, "name")
      } else {
        direct
      }
    } else {
      nested
    }
  }
  let role = if json_string(persona, "role").is_empty() {
    let direct = json_string(fields, "role")
    if direct.is_empty() {
      json_string_alias(fields, "archetypeId", "archetype_id")
    } else {
      direct
    }
  } else {
    json_string(persona, "role")
  }
  let requested_mission = if json_string(persona, "mission").is_empty() {
    json_string(fields, "mission")
  } else {
    json_string(persona, "mission")
  }
  let tone = if json_string(persona, "tone").is_empty() {
    let direct = json_string(fields, "tone")
    if direct.is_empty() {
      json_string_alias(fields, "toneId", "tone_id")
    } else {
      direct
    }
  } else {
    json_string(persona, "tone")
  }
  let capabilities = {
    let nested = json_strings_alias(persona, "capabilities", "capabilities")
    if nested.is_empty() {
      let direct = json_strings_alias(fields, "capabilities", "capabilities")
      if direct.is_empty() {
        json_strings_alias(fields, "capabilityIds", "capability_ids")
      } else {
        direct
      }
    } else {
      nested
    }
  }
  let requested_authority_id = {
    let nested = json_string_alias(
      persona, "authorityCeiling", "authority_ceiling",
    )
    if nested.is_empty() {
      json_string_alias(fields, "authorityCeiling", "authority_ceiling")
    } else {
      nested
    }
  }
  let expected_version = json_int_alias(
    fields, "expectedVersion", "expected_version",
  )
  let expected_cursor = json_int_alias(
    fields, "expectedCursor", "expected_cursor",
  )
  let workspace_id = {
    let nested = json_string_alias(bindings, "workspaceId", "workspace_id")
    if nested.is_empty() {
      json_string_alias(fields, "workspaceId", "workspace_id")
    } else {
      nested
    }
  }
  let building_id = {
    let nested = json_string_alias(bindings, "buildingId", "building_id")
    if nested.is_empty() {
      json_string_alias(fields, "buildingId", "building_id")
    } else {
      nested
    }
  }
  let book_ids = {
    let nested = json_strings_alias(bindings, "bookIds", "book_ids")
    if !nested.is_empty() {
      nested
    } else {
      let one = json_string_alias(fields, "bookId", "book_id")
      if one.is_empty() {
        []
      } else {
        [one]
      }
    }
  }
  let max_active_workers = {
    let nested = json_int_alias(
      bindings, "maxActiveWorkers", "max_active_workers",
    )
    let direct = json_int_alias(
      fields, "maxActiveWorkers", "max_active_workers",
    )
    if nested > 0 {
      nested
    } else if direct > 0 {
      direct
    } else {
      3
    }
  }
  let agent_control = json_bool_alias(
    fields, "consentAgentControl", "consent_agent_control",
  )
  let bookkeeper_consent = json_bool_alias(
    fields, "consentBookkeeperReview", "consent_bookkeeper_review",
  )
  let authority_id = if requested_authority_id.is_empty() {
    if bookkeeper_consent {
      "request_bookkeeper_review"
    } else if agent_control {
      "delegate_bounded_work"
    } else {
      "suggest_only"
    }
  } else {
    requested_authority_id
  }
  if command_id.is_empty() || expected_version < 0 || expected_cursor < 0 {
    fail("commandId, expectedVersion, and expectedCursor are required")
  }
  {
    command_id,
    expected_version,
    expected_cursor,
    profile_id,
    display_name,
    avatar_url: match persona.get("avatarUrl") {
      Some(String(value)) if !value.trim().is_empty() =>
        Some(value.trim().to_owned())
      _ => None
    },
    role,
    mission: if requested_mission.is_empty() && !book_ids.is_empty() {
      "Supervise bounded work for \{book_ids[0]}."
    } else {
      requested_mission
    },
    tone,
    capabilities,
    workspace_id,
    building_id,
    book_ids,
    max_active_workers,
    authority_ceiling: authority_from_id(authority_id),
    consent: {
      terms_version: {
        let value = json_string_alias(consents, "termsVersion", "terms_version")
        if value.is_empty() && (agent_control || bookkeeper_consent) {
          "bunnia-supervisor-onboarding.v1"
        } else {
          value
        }
      },
      profile_activation: json_bool_alias(
        consents, "profileActivation", "profile_activation",
      ) ||
      agent_control,
      runtime_delegation: json_bool_alias(
        consents, "runtimeDelegation", "runtime_delegation",
      ) ||
      agent_control,
      bookkeeper_review: json_bool_alias(
        consents, "bookkeeperReview", "bookkeeper_review",
      ) ||
      bookkeeper_consent,
      confirmed_at_ms: None,
    },
  }
}

///|
pub fn parse_supervisor_activation_draft(
  body : String,
) -> SupervisorActivationDraft raise {
  let parsed = @json.parse(body)
  guard parsed is Object(fields) else {
    fail("supervisor activation body must be a JSON object")
  }
  let draft = {
    command_id: json_string_alias(fields, "commandId", "command_id"),
    expected_version: json_int_alias(
      fields, "expectedVersion", "expected_version",
    ),
    expected_cursor: json_int_alias(fields, "expectedCursor", "expected_cursor"),
    runtime_expected_cursor: {
      let value = json_int_alias(
        fields, "runtimeExpectedCursor", "runtime_expected_cursor",
      )
      if value < 0 {
        None
      } else {
        Some(value)
      }
    },
  }
  if draft.command_id.is_empty() ||
    draft.expected_version < 1 ||
    draft.expected_cursor < 0 {
    fail("commandId, expectedVersion, and expectedCursor are required")
  }
  draft
}
