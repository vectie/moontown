///|
fn research_bootstrap_runtime_policy_fields() -> Map[String, Json] {
  let fields : Map[String, Json] = {}
  add_research_bootstrap_runtime_policy(fields)
  fields
}

///|
fn research_bootstrap_runtime_policy_json() -> Json {
  Json::object(research_bootstrap_runtime_policy_fields())
}

///|
fn add_research_bootstrap_runtime_policy(fields : Map[String, Json]) -> Unit {
  fields["disable_adaptive"] = true.to_json()
  @moonclaw_policy.add_no_input_policy(fields)
}
