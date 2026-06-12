///|
fn moonclaw_no_input_policy_json() -> Json {
  @moonclaw_runtime.moonclaw_no_input_policy_json()
}

///|
fn add_moonclaw_no_input_policy(fields : Map[String, Json]) -> Unit {
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
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
fn moonclaw_step_metadata_fields(
  preferred_skills~ : Array[String],
  enable_tools~ : Bool,
  web_search~ : Bool,
  timeout_ms~ : Int,
  board_lane~ : String,
  board_order~ : Int,
) -> Map[String, Json] {
  @moonclaw_runtime.moonclaw_step_metadata_fields(
    preferred_skills~,
    enable_tools~,
    web_search~,
    timeout_ms~,
    board_lane~,
    board_order~,
  )
}

///|
async fn moonclaw_run_result_payload_from_run(
  run_id : String,
  cwd : String,
) -> Json? {
  @moonclaw_runtime.moonclaw_run_result_payload_from_run(run_id, cwd)
}

///|
async fn moonclaw_run_result_text_from_run(
  run_id : String,
  cwd : String,
  fallback_summary? : Bool = false,
) -> String {
  @moonclaw_runtime.moonclaw_run_result_text_from_run(
    run_id,
    cwd,
    fallback_summary~,
  )
}

///|
async fn compact_moonclaw_job_store_if_needed(
  workspace_root : String,
  tick : Int,
  max_store_bytes? : Int64 = 50_000_000,
) -> String {
  @moonclaw_runtime.compact_moonclaw_job_store_if_needed(
    workspace_root,
    tick,
    max_store_bytes~,
  )
}

///|
pub async fn compact_registered_moonclaw_job_stores(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  tick? : Int = 0,
  max_store_bytes? : Int64 = 50_000_000,
) -> String {
  @moonclaw_runtime.compact_registered_moonclaw_job_stores(
    book_catalog_path~,
    snapshot_path~,
    tick~,
    max_store_bytes~,
  )
}
