///|
struct RunsIndexFile {
  runs : Array[StoredRun]
} derive(Debug, Eq, ToJson, FromJson)

///|
struct StoredRun {
  id : String
  workspace_dir : String?
  status : String
  summary : String?
  error : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
fn run_store_root(home : String) -> String {
  @path.Path(home).join(@path.Path("jobs")).to_string()
}

///|
async fn load_run(run_id : String, home : String) -> StoredRun? {
  let path = @path.Path(run_store_root(home))
    .join(@path.Path("index/runs.json"))
    .to_string()
  let indexed = match moonclaw_read_optional_json_file(path) {
    Some(parsed) => {
      let index : RunsIndexFile = @json.from_json(parsed) catch {
        _ => { runs: [] }
      }
      index.runs.iter().find_first(fn(run) { run.id == run_id })
    }
    None => None
  }
  match load_run_meta(run_id, home) {
    Some(meta) => Some(meta)
    None => indexed
  }
}

///|
async fn load_run_meta(run_id : String, home : String) -> StoredRun? {
  let path = @path.Path(run_store_root(home))
    .join(@path.Path("runs"))
    .join(@path.Path(run_id))
    .join(@path.Path("meta.json"))
    .to_string()
  let parsed = match moonclaw_read_optional_json_file(path) {
    Some(json) => json
    None => return None
  }
  let meta : StoredRun = @json.from_json(parsed) catch { _ => return None }
  if meta.id == run_id {
    Some(meta)
  } else {
    None
  }
}

///|
async fn load_run_result_payload(workspace_dir : String) -> Json {
  let path = @path.Path(workspace_dir)
    .join(@path.Path("result.json"))
    .to_string()
  match moonclaw_read_optional_json_file(path) {
    Some(json) => json
    None => {}
  }
}

///|
fn town_status_for_run_status(status : String) -> @core.TaskExecutionStatus {
  match status {
    "Pending" => @core.TaskExecutionStatus::RunConfirmed
    "Running" => @core.TaskExecutionStatus::Running
    "WaitingForInput" => @core.TaskExecutionStatus::Running
    "Succeeded" => @core.TaskExecutionStatus::Completed
    "Failed" => @core.TaskExecutionStatus::Failed
    "Cancelled" => @core.TaskExecutionStatus::Failed
    _ => @core.TaskExecutionStatus::Running
  }
}

///|
fn run_summary(run : StoredRun, result_payload : Json) -> String {
  let detail = parse_json_string(result_payload, "summary").unwrap_or(
    run.summary.unwrap_or(""),
  )
  let workspace_suffix = match run.workspace_dir {
    Some(workspace_dir) => " workspace=\{workspace_dir}"
    None => ""
  }
  match run.status {
    "Succeeded" =>
      if detail.is_blank() {
        "MoonClaw run \{run.id} completed successfully.\{workspace_suffix}"
      } else {
        "MoonClaw run \{run.id} completed: \{detail}\{workspace_suffix}"
      }
    "Failed" | "Cancelled" =>
      "MoonClaw run \{run.id} failed: \{run.error.unwrap_or(detail).trim().to_owned()}\{workspace_suffix}"
    "WaitingForInput" =>
      "MoonClaw run \{run.id} is waiting for input.\{workspace_suffix}"
    _ =>
      if detail.is_blank() {
        "MoonClaw run \{run.id} is \{run.status}.\{workspace_suffix}"
      } else {
        "MoonClaw run \{run.id} is \{run.status}: \{detail}\{workspace_suffix}"
      }
  }
}
