///|
fn packet_no_input_policy_fields() -> Map[String, Json] {
  let fields : Map[String, Json] = {}
  add_packet_no_input_policy(fields)
  fields
}

///|
fn packet_no_input_policy_json() -> Json {
  Json::object(packet_no_input_policy_fields())
}

///|
fn add_packet_no_input_policy(fields : Map[String, Json]) -> Unit {
  fields["disable_waiting_for_input"] = true.to_json()
  fields["best_effort_on_missing_input"] = true.to_json()
}
