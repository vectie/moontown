///|
pub fn moonclaw_no_input_policy_json() -> Json {
  @moonclaw_policy.no_input_policy_json()
}

///|
pub fn add_moonclaw_no_input_policy(fields : Map[String, Json]) -> Unit {
  @moonclaw_policy.add_no_input_policy(fields)
}

///|
pub fn moonclaw_execution_metadata_fields(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target? : String? = None,
  output_contract~ : String,
) -> Map[String, Json] {
  @moonclaw_policy.execution_metadata_fields(
    preferred_skills~,
    execution_mode~,
    execution_target~,
    output_contract~,
  )
}

///|
pub fn moonclaw_step_metadata_fields(
  preferred_skills~ : Array[String],
  enable_tools~ : Bool,
  web_search~ : Bool,
  timeout_ms~ : Int,
  board_lane~ : String,
  board_order~ : Int,
) -> Map[String, Json] {
  @moonclaw_policy.step_metadata_fields(
    preferred_skills~,
    enable_tools~,
    web_search~,
    timeout_ms~,
    board_lane~,
    board_order~,
  )
}
