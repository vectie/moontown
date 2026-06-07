///|
fn moonclaw_no_input_policy_json() -> Json {
  let fields : Map[String, Json] = {}
  add_moonclaw_no_input_policy(fields)
  Json::object(fields)
}

///|
fn add_moonclaw_no_input_policy(fields : Map[String, Json]) -> Unit {
  fields["disable_waiting_for_input"] = true.to_json()
  fields["best_effort_on_missing_input"] = true.to_json()
}

///|
fn moonclaw_execution_metadata_fields(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target? : String? = None,
  output_contract~ : String,
) -> Map[String, Json] {
  let fields : Map[String, Json] = {}
  fields["preferred_skills"] = preferred_skills.to_json()
  fields["execution_mode"] = execution_mode.to_json()
  match execution_target {
    Some(target) => fields["execution_target"] = target.to_json()
    None => ()
  }
  fields["output_contract"] = output_contract.to_json()
  add_moonclaw_no_input_policy(fields)
  fields
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
  let fields : Map[String, Json] = {}
  fields["preferred_skills"] = preferred_skills.to_json()
  fields["enable_tools"] = enable_tools.to_json()
  fields["web_search"] = web_search.to_json()
  fields["timeout_ms"] = timeout_ms.to_json()
  fields["board_lane"] = board_lane.to_json()
  fields["board_order"] = board_order.to_json()
  add_moonclaw_no_input_policy(fields)
  fields
}
