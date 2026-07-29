///|
async fn RequestApplication::operator_source_policy(
  self : RequestApplication,
) -> String {
  let parsed = @json.parse(
    @support.read_text_or_empty(self.operator_policy_path),
  )
  let fields = match parsed {
    Object(fields) => fields
    _ =>
      fail(
        "operator policy must be a JSON object: \{self.operator_policy_path}",
      )
  }
  let source_policy = json_string_field(fields, "standing_goal_source_policy")
  if source_policy.is_empty() {
    fail(
      "operator policy is missing standing_goal_source_policy: \{self.operator_policy_path}",
    )
  }
  source_policy
}

///|
async fn RequestApplication::append_operator_request(
  self : RequestApplication,
  request : Json,
) -> Unit {
  let path = self.state_root + "/operator-requests/requests.jsonl"
  @support.ensure_parent_directory(path)
  @fs.write_file(
    path,
    request.stringify() + "\n",
    create_mode=OpenOrCreate,
    append=true,
  )
}

///|
pub async fn RequestApplication::submit_standing_watch(
  self : RequestApplication,
  body : String,
) -> Json {
  let parsed = @json.parse(body)
  let fields = match parsed {
    Object(fields) => fields
    _ => fail("request body must be a JSON object")
  }
  let title = json_string_field(fields, "title")
  let prompt = json_string_field(fields, "prompt")
  if title.is_empty() || prompt.is_empty() {
    fail("title and prompt are required")
  }
  let target_book_id = {
    let value = json_string_field(fields, "target_book_id")
    if value.is_empty() {
      "research-opc"
    } else {
      safe_slug(value)
    }
  }
  let cadence_ticks = json_int_field(fields, "cadence_ticks", 60, 1, 2147483647)
  let quality_threshold = json_int_field(
    fields, "quality_threshold", 85, 1, 100,
  )
  let source_policy = self.operator_source_policy()
  let timestamp = @env.now()
  let slug = safe_slug(title)
  let nonce = request_nonce()
  let request_id = "operator-\{timestamp}-\{nonce}-\{slug}"
  let explicit_goal_id = json_string_field(fields, "goal_id")
  let goal_id = if explicit_goal_id.is_empty() {
    "standing-goal-\{timestamp}-\{nonce}-\{slug}"
  } else {
    safe_slug(explicit_goal_id)
  }
  let created_at = iso_timestamp(timestamp)
  let request : Json = {
    "id": request_id,
    "status": "accepted",
    "created_at": created_at,
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
    "standing_goal_id": goal_id,
  }
  let goal : Json = {
    "id": goal_id,
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "next_due_tick": 0,
    "enabled": true,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
  }
  let goals_path = self.state_root + "/standing-goals.json"
  let goals_text = @support.read_text_or_empty(goals_path)
  let goals_json = if goals_text.trim().is_empty() {
    ([] : Array[Json]).to_json()
  } else {
    @json.parse(goals_text)
  }
  let goals : Array[Json] = match goals_json {
    Array(items) => items
    _ => fail("standing-goals.json must contain a JSON array")
  }
  let mut replaced = false
  for index, existing in goals {
    guard existing is Object(existing_fields) else { continue }
    if json_string_field(existing_fields, "id") == goal_id {
      goals[index] = goal
      replaced = true
      break
    }
  }
  if !replaced {
    goals.push(goal)
  }
  let request_path = self.state_root +
    "/operator-requests/" +
    request_id +
    ".json"
  let preparing : Json = {
    "id": request_id,
    "status": "preparing",
    "created_at": created_at,
    "title": title,
    "prompt": prompt,
    "target_book_id": target_book_id,
    "cadence_ticks": cadence_ticks,
    "source_policy": source_policy,
    "quality_threshold": quality_threshold,
    "standing_goal_id": goal_id,
  }
  @support.write_text_file(request_path, preparing.stringify(indent=2))
  let mut goal_activated = false
  try {
    @support.write_text_file(goals_path, goals.to_json().stringify(indent=2))
    goal_activated = true
    @support.write_text_file(request_path, request.stringify(indent=2))
    self.append_operator_request(request)
  } catch {
    error => {
      if goal_activated {
        @support.write_text_file(
          goals_path,
          if goals_text.trim().is_empty() {
            "[]"
          } else {
            goals_text
          },
        ) catch {
          _ => ()
        }
      }
      let failed : Json = {
        "id": request_id,
        "status": "failed",
        "created_at": created_at,
        "title": title,
        "prompt": prompt,
        "target_book_id": target_book_id,
        "cadence_ticks": cadence_ticks,
        "source_policy": source_policy,
        "quality_threshold": quality_threshold,
        "standing_goal_id": goal_id,
        "error": "Operator request persistence did not complete.",
      }
      @support.write_text_file(request_path, failed.stringify(indent=2)) catch {
        _ => ()
      }
      raise error
    }
  }
  {
    "ok": true,
    "request_id": request_id,
    "standing_goal_id": goal_id,
    "status": "accepted",
  }
}
