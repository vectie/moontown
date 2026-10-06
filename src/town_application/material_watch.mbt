///|
fn material_setup_hash(value : String) -> String {
  @crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))
}

///|
async fn material_setup_write(
  path : String,
  value : Json,
  replace? : Bool = true,
) -> Unit {
  @support.ensure_parent_directory(path)
  let pending = path + ".pending-" + request_nonce()
  @fs.write_file(
    pending,
    value.stringify(indent=2),
    create_mode=CreateOrTruncate,
  )
  @fs.rename(pending, path, replace~)
}

///|
fn material_setup_sources(fields : Map[String, Json]) -> Array[String] raise {
  match fields.get("material_sources") {
    Some(String(text)) =>
      text
      .split("\n")
      .map(line => line.trim().to_owned())
      .filter(line => !line.is_empty())
      .collect()
    Some(Array(values)) =>
      values.map(value => {
        match value {
          String(path) if !path.trim().is_empty() => path.trim().to_owned()
          _ => fail("Every selected material source must be a nonempty path")
        }
      })
    _ => fail("Select material source paths, one per line")
  }
}

///|
/// All callers hold the shared request-submission lock. This writes no tasks,
/// baselines, provider calls or Book reviews; the existing cycle owns those.
async fn RequestApplication::submit_material_watch(
  self : RequestApplication,
  fields : Map[String, Json],
) -> Json {
  let title = json_string_field(fields, "title")
  let intent = json_string_field(fields, "prompt")
  let book_id = json_string_field(fields, "target_book_id")
  let acceptance = json_string_field(fields, "material_acceptance")
  let next_action = json_string_field(fields, "material_next_action")
  let sources = material_setup_sources(fields)
  guard !title.is_empty() &&
    !intent.is_empty() &&
    !book_id.is_empty() &&
    !acceptance.is_empty() &&
    !next_action.is_empty() &&
    !sources.is_empty() else {
    fail(
      "Local material watch needs a title, request, existing Book, sources, acceptance and next owner action",
    )
  }
  let catalog = @moonbook.load_catalog_file(self.catalog_path).unwrap_or([])
  guard @moonbook.find_catalog_entry(catalog, book_id) is Some(entry) else {
    fail("Choose an existing Book from the Town catalog: " + book_id)
  }
  let cadence_ticks = json_int_field(fields, "cadence_ticks", 60, 1, 2147483647)
  let quality_threshold = json_int_field(
    fields, "quality_threshold", 85, 1, 100,
  )
  let normalized_sources = sources.copy()
  normalized_sources.sort()
  // An ordered JSON tuple makes restart identity independent of object-map
  // iteration order. Source selection order is intentionally canonicalized.
  let identity : Array[Json] = [
    title.to_json(),
    intent.to_json(),
    book_id.to_json(),
    normalized_sources.to_json(),
    acceptance.to_json(),
    next_action.to_json(),
    cadence_ticks.to_json(),
    quality_threshold.to_json(),
  ]
  let requested_goal_id = json_string_field(fields, "goal_id")
  guard requested_goal_id.is_empty() ||
    safe_slug(requested_goal_id) == requested_goal_id else {
    fail("Explicit goal_id must be a safe lower-case identifier")
  }
  let goal_id = if requested_goal_id.is_empty() {
    "standing-local-" + material_setup_hash(identity.to_json().stringify())
  } else {
    requested_goal_id
  }
  let request_id = "operator-" + goal_id
  let relative_plan = ".moontown/material-watch-plans/" +
    material_setup_hash(goal_id) +
    ".json"
  guard !normalized_sources.contains(relative_plan) else {
    fail("A material watch cannot select its own plan as a source")
  }
  let source_policy = "local-material:" + relative_plan
  let goal = @core.StandingGoal::new(
    id=goal_id,
    title~,
    prompt=intent,
    target_book_id=Some(book_id),
    cadence_ticks~,
    next_due_tick=0,
    enabled=true,
    source_policy~,
    quality_threshold~,
  )
  let plan = @material_watch_plan.validate(
    {
      contract: "moontown.material_watch_plan.v1",
      goal_id,
      book_id,
      intent,
      acceptance,
      next_action,
      sources: normalized_sources,
    },
    entry,
    goal,
  )
  // Read every selected source through the exact runtime boundary before any
  // goal can become enabled. Missing, escaped or non-UTF-8 sources fail here.
  ignore(@material_watch_plan.read_sources(entry, plan))
  let goals_path = self.state_root + "/standing-goals.json"
  let goals : Array[Json] = if @fs.exists(goals_path) {
    match @json.parse(@fs.read_file(goals_path).text()) {
      Array(items) => items
      _ => fail("standing-goals.json must contain a JSON array")
    }
  } else {
    []
  }
  let mut found_goal = false
  for existing in goals {
    guard existing is Object(existing_fields) else { continue }
    if json_string_field(existing_fields, "id") == goal_id {
      let saved : @core.StandingGoal = @json.from_json(existing)
      guard saved.title == title &&
        saved.prompt == intent &&
        saved.target_book_id == Some(book_id) &&
        saved.source_policy == source_policy &&
        saved.cadence_ticks == cadence_ticks &&
        saved.quality_threshold == quality_threshold else {
        fail(
          "This goal ID already belongs to a different watch; keep it unchanged",
        )
      }
      found_goal = true
    }
  }
  let root = @fs.realpath(@moonbook.workspace_root(entry))
  let mut parent = root
  for directory in [".moontown", "material-watch-plans"] {
    let next = parent + "/" + directory
    if !@fs.exists(next) {
      @fs.mkdir(next)
    }
    let resolved = @fs.realpath(next)
    guard resolved.has_prefix(root + "/") && @fs.kind(resolved) == Directory else {
      fail("Material-watch plan directory must remain inside the owning Book")
    }
    parent = resolved
  }
  let plan_path = root + "/" + relative_plan
  if @fs.exists(plan_path) {
    guard @material_watch_plan.read_plan(entry, goal, relative_plan) == plan else {
      fail("Saved material-watch plan differs; original plan retained")
    }
  } else {
    material_setup_write(plan_path, plan.to_json(), replace=false)
  }
  guard @material_watch_plan.read_plan(entry, goal, relative_plan) == plan else {
    fail("Material-watch plan readback did not match")
  }
  let material : Json = {
    "plan_path": relative_plan,
    "intent": plan.intent,
    "acceptance": plan.acceptance,
    "next_action": plan.next_action,
    "sources": plan.sources.to_json(),
    "baseline_status": "pending_first_check",
  }
  let request_path = self.state_root +
    "/operator-requests/" +
    request_id +
    ".json"
  let created_at = match @support.read_optional_json_file(request_path) {
    Some(Object(saved)) => json_string_field(saved, "created_at")
    _ => iso_timestamp(@env.now())
  }
  let request : Json = {
    "id": request_id,
    "status": "accepted",
    "created_at": created_at,
    "title": title,
    "prompt": intent,
    "target_book_id": book_id,
    "cadence_ticks": cadence_ticks,
    "quality_threshold": quality_threshold,
    "source_policy": source_policy,
    "standing_goal_id": goal_id,
    "material_watch": material,
  }
  if !found_goal {
    goals.push(goal.to_json())
    material_setup_write(goals_path, goals.to_json())
  }
  // The durable plan + goal are the commit point. A receipt/ledger failure is
  // repairable by the identical request, without resetting the runtime tick.
  material_setup_write(request_path, request)
  let ledger_path = self.state_root + "/operator-requests/requests.jsonl"
  let mut recorded = false
  for line in @support.read_text_or_empty(ledger_path).split("\n") {
    let value = @json.parse(line) catch { _ => continue }
    if value is Object(saved) && json_string_field(saved, "id") == request_id {
      guard value == request else {
        fail("Accepted request ledger differs; retained for repair")
      }
      recorded = true
    }
  }
  if !recorded {
    self.append_operator_request(request)
  }
  {
    "ok": true,
    "request_id": request_id,
    "standing_goal_id": goal_id,
    "status": "accepted",
    "material_watch": material,
  }
}
