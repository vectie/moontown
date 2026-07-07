///|
pub fn miniapp_local_backend_routes() -> Array[MiniappLocalBackendRoute] {
  [
    miniapp_local_backend_route(
      "POST", "/miniapp/auth/dev-login", "dev-login", false,
    ),
    miniapp_local_backend_route(
      "GET", "/miniapp/town/snapshot", "snapshot", true,
    ),
    miniapp_local_backend_route(
      "GET", "/miniapp/buildings/search", "search-buildings", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings", "create-building", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings/place", "place-building", true,
    ),
    miniapp_local_backend_route("POST", "/miniapp/agents", "create-agent", true),
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings/query", "chat-send", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/cancel", "cancel-run", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/retry", "retry-run", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/reviews/accept", "accept-run", true,
    ),
  ]
}

///|
fn miniapp_local_backend_route(
  http_method : String,
  path : String,
  name : String,
  auth_required : Bool,
) -> MiniappLocalBackendRoute {
  { http_method, path, name, auth_required }
}
