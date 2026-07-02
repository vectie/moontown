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
fn add_moonclaw_no_input_policy(fields : Map[String, Json]) -> Unit {
  @moonclaw_runtime.add_moonclaw_no_input_policy(fields)
}

///|
async fn moonclaw_run_result_payload_from_run(
  run_id : String,
  workspace_root : String,
) -> Json? {
  @moonclaw_runtime.moonclaw_run_result_payload_from_run(
    run_id,
    workspace_root,
    home=moonclaw_product_home_for_workspace(workspace_root),
  )
}

///|
fn moonclaw_product_home_for_workspace(workspace_root : String) -> String {
  @moonsuite.product_home_for_workspace_root(workspace_root, "moonclaw").state_path
}
