///|
fn add_planbook_bounded_wait_policy(fields : Map[String, Json]) -> Unit {
  add_moonclaw_no_input_policy(fields)
  fields["best_effort_on_timeout"] = false.to_json()
  fields["timeout_ms"] = planbook_repair_timeout_ms_json()
}

///|
fn planbook_bounded_wait_policy_json() -> Json {
  let fields : Map[String, Json] = {}
  add_planbook_bounded_wait_policy(fields)
  Json::object(fields)
}
