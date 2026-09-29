///|
/// Return the four renderer-neutral architectural studies in stable UI order.
pub fn studies() -> Json {
  [future_center(), future_vision(), east_bridge(), arch_bridge()].to_json()
}
