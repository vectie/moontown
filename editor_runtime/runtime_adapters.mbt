///|
type PlanbookRepairTask = @planbook_policy.PlanbookRepairTask

///|
fn default_planbook_book_id() -> String {
  "plan-moontown-quality"
}

///|
fn default_planbook_workspace_root() -> String {
  ".moontown/books/\{default_planbook_book_id()}"
}

///|
fn default_wenyu_course_book_id() -> String {
  @course_book.default_wenyu_course_book_id()
}

///|
fn default_wenyu_course_workspace_root() -> String {
  @course_book.default_wenyu_course_workspace_root()
}

///|
fn planbook_repair_source_root() -> String {
  match @env.current_dir() {
    Some(dir) => dir
    None => "."
  }
}

///|
fn planbook_autonomy_base_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown"
  } else {
    base
  }
}

///|
fn default_planbook_repair_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.json"
}

///|
fn planbook_repair_result_path_for_workspace(workspace_root : String) -> String {
  @planbook_policy.repair_result_path_for_workspace(workspace_root)
}

///|
fn planbook_repair_result_mentions_criterion(
  text : String,
  criterion_id : String,
) -> Bool {
  @planbook_policy.repair_result_mentions_criterion(text, criterion_id)
}

///|
fn planbook_repair_result_has_accepted_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_accepted_decision(text)
}

///|
fn planbook_repair_result_has_no_change_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_no_change_decision(text)
}

///|
fn planbook_repair_result_has_handoff_decision(text : String) -> Bool {
  @planbook_policy.repair_result_has_handoff_decision(text)
}

///|
fn moontown_moonclaw_inline_enabled() -> Bool {
  match optional_env_text("MOONTOWN_MOONCLAW_INLINE") {
    Some(value) => {
      let lower = value.to_lower()
      lower == "1" || lower == "true" || lower == "yes" || lower == "on"
    }
    None => false
  }
}

///|
fn optional_env_text(key : String) -> String? {
  match @sys.get_env_var(key) {
    Some(value) => {
      let trimmed = value.trim().to_owned()
      if trimmed.is_empty() {
        None
      } else {
        Some(trimmed)
      }
    }
    None => None
  }
}

///|
fn add_planbook_bounded_wait_policy(fields : Map[String, Json]) -> Unit {
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
  fields["best_effort_on_timeout"] = false.to_json()
  fields["timeout_ms"] = (600000).to_json()
}

///|
fn moonclaw_execution_metadata_fields(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target? : String? = None,
  output_contract~ : String,
) -> Map[String, Json] {
  @moonclaw_runtime.moonclaw_execution_metadata_fields(
    preferred_skills~,
    execution_mode~,
    execution_target~,
    output_contract~,
  )
}

///|
fn planbook_bounded_step_metadata_json(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target? : String? = None,
  output_contract~ : String,
  source_root~ : String,
  target_files~ : Array[String],
  target_pages~ : Array[String],
  planning_layer~ : String,
  runtime_mode~ : String,
  tool_access~ : String,
) -> Json {
  let fields = moonclaw_execution_metadata_fields(
    preferred_skills~,
    execution_mode~,
    execution_target~,
    output_contract~,
  )
  fields["enable_tools"] = true.to_json()
  fields["source_root"] = source_root.to_json()
  fields["target_files"] = target_files.to_json()
  fields["target_pages"] = target_pages.to_json()
  fields["best_effort_on_timeout"] = false.to_json()
  fields["timeout_ms"] = (600000).to_json()
  fields["role_runtime"] = {
    "planning_layer": planning_layer,
    "runtime_mode": runtime_mode,
    "tool_access": tool_access,
    "memory_scope": "planbook",
    "allow_delegate": false,
    "allow_workspace_write": true,
    "allow_execution_tools": true,
    "output_contract": output_contract,
  }
  Json::object(fields)
}

///|
async fn moonclaw_run_result_text_from_run(
  run_id : String,
  workspace_root : String,
) -> String {
  @moonclaw_runtime.moonclaw_run_result_text_from_run(run_id, workspace_root)
}

///|
async fn text_file_contains(path : String, needle : String) -> Bool {
  if !@fs.exists(path) {
    false
  } else {
    @fs.read_file(path).text().contains(needle)
  }
}
