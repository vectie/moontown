///|
/// The existing QR lands in the public neighborhood. Explicit spatial/work
/// links retain their destination; closing the panel makes refresh predictable.
fn neighborhood_route_requested(
  public_platform : Bool,
  community : String,
  layer : String,
  request : String,
  area : String,
  panel : String,
) -> Bool {
  if community == "0" {
    false
  } else if community == "1" {
    true
  } else {
    public_platform &&
    layer.is_empty() &&
    request.is_empty() &&
    area.is_empty() &&
    panel.is_empty()
  }
}

///|
fn initial_neighborhood_requested() -> Bool {
  neighborhood_route_requested(
    public_platform_enabled(),
    current_browser_query_param("community"),
    current_browser_query_param("layer"),
    current_browser_query_param("request"),
    current_browser_query_param("area"),
    current_browser_query_param("panel"),
  )
}
