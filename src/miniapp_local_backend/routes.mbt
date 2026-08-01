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
      "GET", "/miniapp/book-registrations", "installed-books", true,
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
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings/share", "share-building", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings/publish", "publish-building", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/buildings/archive", "archive-building", true,
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
      "POST", "/miniapp/reviews/accept", "request-bookkeeper-review", true,
    ),
    miniapp_local_backend_route(
      "GET", "/miniapp/onboarding/supervisor", "supervisor-profile", true,
    ),
    miniapp_local_backend_route(
      "PUT", "/miniapp/onboarding/supervisor/draft", "supervisor-draft", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/onboarding/supervisor/activate", "supervisor-activate", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/steer", "run-steer", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/delegate", "run-delegate", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/child/steer", "child-run-steer", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/supervisor/wake", "supervisor-wake", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/supervisor/stop", "supervisor-stop", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runs/supervisor/resume", "supervisor-resume", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/messages", "supervisor-message", true,
    ),
    miniapp_local_backend_route(
      "POST", "/miniapp/runtime/observations/reconcile", "runtime-observation-reconcile",
      true,
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
