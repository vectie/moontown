///|
pub fn no_input_policy_json() -> Json {
  let fields : Map[String, Json] = Map([])
  add_no_input_policy(fields)
  Json::object(fields)
}

///|
pub fn add_no_input_policy(fields : Map[String, Json]) -> Unit {
  fields["disable_waiting_for_input"] = ToJson::to_json(true)
  fields["best_effort_on_missing_input"] = ToJson::to_json(true)
}

///|
pub fn non_adaptive_no_input_policy_fields() -> Map[String, Json] {
  let fields : Map[String, Json] = Map([])
  add_non_adaptive_no_input_policy(fields)
  fields
}

///|
pub fn non_adaptive_no_input_policy_json() -> Json {
  Json::object(non_adaptive_no_input_policy_fields())
}

///|
pub fn add_non_adaptive_no_input_policy(fields : Map[String, Json]) -> Unit {
  fields["disable_adaptive"] = ToJson::to_json(true)
  add_no_input_policy(fields)
}

///|
pub fn execution_metadata_fields(
  preferred_skills~ : Array[String],
  execution_mode~ : String,
  execution_target~ : String? = None,
  output_contract~ : String,
) -> Map[String, Json] {
  let fields : Map[String, Json] = Map([])
  fields["preferred_skills"] = ToJson::to_json(preferred_skills)
  fields["execution_mode"] = ToJson::to_json(execution_mode)
  match execution_target {
    Some(target) => fields["execution_target"] = ToJson::to_json(target)
    None => ()
  }
  fields["output_contract"] = ToJson::to_json(output_contract)
  add_no_input_policy(fields)
  fields
}

///|
pub fn step_metadata_fields(
  preferred_skills~ : Array[String],
  enable_tools~ : Bool,
  web_search~ : Bool,
  timeout_ms~ : Int32,
  board_lane~ : String,
  board_order~ : Int32,
) -> Map[String, Json] {
  let fields : Map[String, Json] = Map([])
  fields["preferred_skills"] = ToJson::to_json(preferred_skills)
  fields["enable_tools"] = ToJson::to_json(enable_tools)
  fields["web_search"] = ToJson::to_json(web_search)
  fields["timeout_ms"] = ToJson::to_json(timeout_ms)
  fields["board_lane"] = ToJson::to_json(board_lane)
  fields["board_order"] = ToJson::to_json(board_order)
  add_no_input_policy(fields)
  fields
}
