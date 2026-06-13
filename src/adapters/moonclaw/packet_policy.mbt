///|
fn packet_no_input_policy_fields() -> Map[String, Json] {
  let fields : Map[String, Json] = {}
  @moonclaw_policy.add_no_input_policy(fields)
  fields
}

///|
fn packet_no_input_policy_json() -> Json {
  @moonclaw_policy.no_input_policy_json()
}
