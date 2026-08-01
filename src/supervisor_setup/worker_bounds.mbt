///|
fn default_supervisor_worker_budget() -> SupervisorWorkerBudget {
  {
    max_cost_micro_usd: 2000000L,
    max_runtime_ms: 300000L,
    max_tokens: 12000L,
    max_artifacts: 3,
  }
}

///|
fn canonical_worker_expiry(value : String) -> Bool {
  value.length() == 20 &&
  value[4] == '-' &&
  value[7] == '-' &&
  value[10] == 'T' &&
  value[13] == ':' &&
  value[16] == ':' &&
  value[19] == 'Z'
}

///|
fn canonical_artifact_prefix(value : String, book_id : String) -> Bool {
  let base = "books/\{book_id}/artifacts"
  value == base &&
  !value.has_prefix("/") &&
  !value.contains("://") &&
  !value.contains("..")
}

///|
fn canonical_book_segment(value : String) -> Bool {
  if value.is_empty() || value.has_prefix("-") || value.has_suffix("-") {
    return false
  }
  for char in value {
    if !((char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '-') {
      return false
    }
  }
  true
}

///|
fn parse_supervisor_worker_assignment(
  fields : Map[String, Json],
) -> (SupervisorWorkerTask, SupervisorWorkerBounds, String) raise {
  let task_fields = json_object(fields, "task")
  let scope_fields = json_object(fields, "scope")
  let budget_fields = json_object(scope_fields, "budget")
  let defaults = default_supervisor_worker_budget()
  let task_id = json_string_alias(task_fields, "taskId", "task_id")
  let conversation_id = json_string_alias(
    task_fields, "conversationId", "conversation_id",
  )
  let title = json_string(task_fields, "title")
  let requested_cwd = json_string(task_fields, "cwd")
  let requested_model = json_string(task_fields, "model")
  let model = if requested_model.is_empty() {
    "gpt-5.6-sol"
  } else {
    requested_model
  }
  let web_search_explicit = task_fields.get("webSearch") is Some(True | False) ||
    task_fields.get("web_search") is Some(True | False)
  let metadata = task_fields.get("metadata").unwrap_or(Json::null())
  guard metadata is Object(metadata_fields) else {
    fail(
      "delegate task metadata must explicitly bind the Town profile and book",
    )
  }
  let book_id = json_string_alias(metadata_fields, "bookId", "book_id")
  let workspace_id = json_string_alias(
    metadata_fields, "workspaceId", "workspace_id",
  )
  let cwd = "workspace://\{workspace_id}/books/\{book_id}"
  let claim_ceiling = {
    let value = json_string_alias(scope_fields, "claimCeiling", "claim_ceiling")
    if value.is_empty() {
      "reviewable"
    } else {
      value
    }
  }
  let artifact_prefixes = json_strings_alias(
    scope_fields, "artifactPrefixes", "artifact_prefixes",
  )
  let expires_at = json_string_alias(scope_fields, "expiresAt", "expires_at")
  let task : SupervisorWorkerTask = {
    task_id,
    conversation_id,
    title,
    cwd,
    model,
    web_search: json_bool_alias(task_fields, "webSearch", "web_search"),
    metadata,
  }
  let bounds : SupervisorWorkerBounds = {
    claim_ceiling,
    budget: {
      max_cost_micro_usd: if json_alias_present(
          budget_fields, "maxCostMicroUsd", "max_cost_micro_usd",
        ) {
        json_int64_alias(budget_fields, "maxCostMicroUsd", "max_cost_micro_usd")
      } else {
        defaults.max_cost_micro_usd
      },
      max_runtime_ms: if json_alias_present(
          budget_fields, "maxRuntimeMs", "max_runtime_ms",
        ) {
        json_int64_alias(budget_fields, "maxRuntimeMs", "max_runtime_ms")
      } else {
        defaults.max_runtime_ms
      },
      max_tokens: if json_alias_present(
          budget_fields, "maxTokens", "max_tokens",
        ) {
        json_int64_alias(budget_fields, "maxTokens", "max_tokens")
      } else {
        defaults.max_tokens
      },
      max_artifacts: if json_alias_present(
          budget_fields, "maxArtifacts", "max_artifacts",
        ) {
        json_int_alias(budget_fields, "maxArtifacts", "max_artifacts")
      } else {
        defaults.max_artifacts
      },
    },
    artifact_prefixes,
    expires_at,
  }
  if task.task_id.is_empty() ||
    task.conversation_id.is_empty() ||
    task.title.is_empty() ||
    workspace_id.is_empty() ||
    task.model != "gpt-5.6-sol" ||
    !web_search_explicit ||
    !canonical_book_segment(book_id) ||
    (!requested_cwd.is_empty() && requested_cwd != cwd) {
    fail(
      "delegate task requires explicit taskId, conversationId, title, gpt-5.6-sol model, webSearch, and symbolic metadata.workspaceId/bookId; client absolute cwd is forbidden",
    )
  }
  if !(bounds.claim_ceiling == "evidence-only" ||
    bounds.claim_ceiling == "draft" ||
    bounds.claim_ceiling == "reviewable") ||
    bounds.budget.max_runtime_ms <= 0L ||
    bounds.budget.max_tokens <= 0L ||
    bounds.budget.max_artifacts <= 0 ||
    bounds.budget.max_cost_micro_usd <= 0L ||
    bounds.artifact_prefixes.is_empty() ||
    !canonical_worker_expiry(bounds.expires_at) {
    fail(
      "delegate scope requires finite task-scoped budget, artifactPrefixes, and expiresAt",
    )
  }
  for prefix in bounds.artifact_prefixes {
    if !canonical_artifact_prefix(prefix, book_id) {
      fail(
        "delegate artifactPrefixes must be canonical workspace-relative paths under the bound book",
      )
    }
  }
  let source = if requested_model.is_empty() ||
    !json_alias_present(budget_fields, "maxCostMicroUsd", "max_cost_micro_usd") ||
    !json_alias_present(budget_fields, "maxRuntimeMs", "max_runtime_ms") ||
    !json_alias_present(budget_fields, "maxTokens", "max_tokens") ||
    !json_alias_present(budget_fields, "maxArtifacts", "max_artifacts") {
    "safe_default_visible"
  } else {
    "user_supplied"
  }
  (task, bounds, source)
}

///|
fn execution_command_kind(action : String) -> String {
  if action == "delegate" {
    "bounded_worker_assignment"
  } else if action == "message" {
    "supervisor_message"
  } else if action == "steer" || action == "wake" {
    "supervisor_run_control"
  } else if action == "supervisor_stop" || action == "supervisor_resume" {
    "supervisor_lifecycle_control"
  } else {
    "child_run_control"
  }
}

///|
fn execution_action_allowed(action : String) -> Bool {
  action == "message" ||
  action == "steer" ||
  action == "delegate" ||
  action == "wake" ||
  action == "supervisor_stop" ||
  action == "supervisor_resume" ||
  action == "child_stop" ||
  action == "child_steer" ||
  action == "child_retry"
}
