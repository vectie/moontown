///|
pub struct PlanbookRepairTask {
  id : String
  criterion_id : String
  title : String
  status : String
  owner : String
  workspace_root : String
  packet_path : String
  proposal_id : String?
  run_id : String?
  summary : String
  validation_command : String
  generated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn default_planbook_repair_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.json"
}

///|
pub fn default_planbook_repair_markdown_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{planbook_autonomy_base_dir(snapshot_path)}/planbook/repair-task.md"
}

///|
pub async fn write_moontown_planbook_repair_task(
  snapshot_path? : String = @storage.default_snapshot_path(),
  workspace_root? : String = default_planbook_workspace_root(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  dispatch? : Bool = false,
  run_inline? : Bool = planbook_repair_run_inline_enabled(),
) -> String {
  let status = inspect_moontown_planbook_autonomy(
    snapshot_path~,
    workspace_root~,
    book_catalog_path~,
  )
  match first_planbook_open_criterion(status) {
    Some(criterion) => {
      let task = match
        existing_planbook_repair_handoff(
          criterion, snapshot_path, workspace_root,
        ) {
        Some(task) => task
        None =>
          match
            existing_planbook_repair_in_flight(
              criterion, snapshot_path, workspace_root,
            ) {
            Some(task) => task
            None =>
              materialize_planbook_repair_task(
                criterion, snapshot_path, workspace_root, book_catalog_path, dispatch,
                run_inline,
              )
          }
      }
      write_planbook_repair_status(task, workspace_root, snapshot_path)
      "PlanBook repair task `\{task.id}` is \{task.status}: \{task.summary}"
    }
    None => {
      let task = planbook_noop_repair_task(snapshot_path, workspace_root)
      write_planbook_repair_status(task, workspace_root, snapshot_path)
      "PlanBook has no open repair task."
    }
  }
}

///|
fn planbook_repair_run_inline_enabled() -> Bool {
  planbook_repair_run_inline_enabled_from_env(
    optional_env_text("MOONTOWN_PLANBOOK_REPAIR_INLINE"),
  )
}

///|
fn planbook_repair_run_inline_enabled_from_env(value : String?) -> Bool {
  match value {
    Some(value) => {
      let lower = value.to_lower()
      lower == "1" || lower == "true" || lower == "yes" || lower == "on"
    }
    None => true
  }
}

///|
pub async fn render_moontown_planbook_repair_status(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return "No PlanBook repair task exists at \{path}. Run `moon run cmd/main -- planbook repair`."
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch {
    _ =>
      return "PlanBook repair task exists at \{path}, but it is not valid JSON."
  }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ =>
      return "PlanBook repair task exists at \{path}, but it does not match the contract."
  }
  let status = inspect_moontown_planbook_autonomy(snapshot_path~)
  if planbook_repair_task_satisfied_by_status(task, status) {
    match first_planbook_open_criterion(status) {
      Some(criterion) if criterion.id != task.criterion_id =>
        match
          latest_planbook_repair_task_from_job_index(
            criterion,
            default_planbook_workspace_root(),
          ) {
          Some(index_task) => {
            let result_text = reconcile_planbook_repair_result(index_task)
            return render_planbook_repair_markdown(index_task, result_text~)
          }
          None =>
            return "PlanBook repair task at \{path} is stale: criterion `\{task.criterion_id}` is now satisfied and autonomy now has open gap `\{criterion.id}`. The next daemon tick will refresh and dispatch one bounded Codex ACP repair; run `moon run cmd/main -- planbook repair --dispatch` only for an explicit operator retry."
        }
      _ =>
        return "PlanBook repair task at \{path} is stale: criterion `\{task.criterion_id}` is now satisfied."
    }
  }
  if task.criterion_id == "none" {
    match first_planbook_open_criterion(status) {
      Some(criterion) =>
        match
          latest_planbook_repair_task_from_job_index(
            criterion,
            default_planbook_workspace_root(),
          ) {
          Some(index_task) => {
            let result_text = reconcile_planbook_repair_result(index_task)
            return render_planbook_repair_markdown(index_task, result_text~)
          }
          None =>
            return "PlanBook repair task at \{path} is stale: autonomy now has open gap `\{criterion.id}`. The next daemon tick will refresh and dispatch one bounded Codex ACP repair; run `moon run cmd/main -- planbook repair --dispatch` only for an explicit operator retry."
        }
      None => ()
    }
  }
  let refreshed = refresh_planbook_repair_task_from_run(task)
  let result_text = reconcile_planbook_repair_result(refreshed)
  render_planbook_repair_markdown(refreshed, result_text~)
}

///|
pub async fn planbook_repair_active_count(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> Int {
  let path = default_planbook_repair_path(snapshot_path~)
  if !@fs.exists(path) {
    return 0
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch { _ => return 0 }
  let task : PlanbookRepairTask = @json.from_json(parsed) catch {
    _ => return 0
  }
  if planbook_repair_criterion_now_satisfied(task, snapshot_path~) {
    return 0
  }
  if reconcile_planbook_repair_result(task) != "" {
    return 0
  }
  if planbook_repair_task_in_flight(task) {
    1
  } else {
    0
  }
}
