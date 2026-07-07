///|
pub(all) struct MiniappEndpoint {
  id : String
  http_method : String
  path : String
  writes : Bool
  auth_required : Bool
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn miniapp_endpoint(
  id~ : String,
  http_method~ : String,
  path~ : String,
  writes? : Bool = false,
  auth_required? : Bool = true,
  summary~ : String,
) -> MiniappEndpoint {
  { id, http_method, path, writes, auth_required, summary }
}

///|
pub fn miniapp_contract_endpoints() -> Array[MiniappEndpoint] {
  [
    miniapp_endpoint(
      id="auth-wechat-login",
      http_method="POST",
      path="/auth/wechat/login",
      writes=true,
      auth_required=false,
      summary="Exchange a WeChat login code for a product session.",
    ),
    miniapp_endpoint(
      id="auth-dev-login",
      http_method="POST",
      path="/auth/dev/login",
      writes=true,
      auth_required=false,
      summary="Create a local development session for a fixture user.",
    ),
    miniapp_endpoint(
      id="auth-logout",
      http_method="POST",
      path="/auth/logout",
      writes=true,
      summary="Expire the current product session.",
    ),
    miniapp_endpoint(
      id="me",
      http_method="GET",
      path="/me",
      summary="Return the signed-in user and permission context.",
    ),
    miniapp_endpoint(
      id="workspaces",
      http_method="GET",
      path="/workspaces",
      summary="List personal and organization workspaces visible to the user.",
    ),
    miniapp_endpoint(
      id="town-snapshot",
      http_method="GET",
      path="/town/snapshot",
      summary="Return the user-scoped town snapshot for the mini-app map.",
    ),
    miniapp_endpoint(
      id="town-layers",
      http_method="GET",
      path="/town/layers",
      summary="List personal, team, public, and system map layers.",
    ),
    miniapp_endpoint(
      id="buildings-search",
      http_method="GET",
      path="/buildings/search",
      summary="Search published or otherwise visible buildings.",
    ),
    miniapp_endpoint(
      id="building-detail",
      http_method="GET",
      path="/buildings/:id",
      summary="Return a permission-filtered building detail.",
    ),
    miniapp_endpoint(
      id="building-create",
      http_method="POST",
      path="/buildings",
      writes=true,
      summary="Create a private building draft in a workspace.",
    ),
    miniapp_endpoint(
      id="building-update",
      http_method="PATCH",
      path="/buildings/:id",
      writes=true,
      summary="Update a building draft or editable shared building.",
    ),
    miniapp_endpoint(
      id="building-share",
      http_method="POST",
      path="/buildings/:id/share",
      writes=true,
      summary="Grant private building access to users or organizations.",
    ),
    miniapp_endpoint(
      id="building-publish",
      http_method="POST",
      path="/buildings/:id/publish",
      writes=true,
      summary="Submit, approve, reject, or publish a building.",
    ),
    miniapp_endpoint(
      id="building-place",
      http_method="POST",
      path="/buildings/:id/place",
      writes=true,
      summary="Place a visible building on a user, team, or public town layer.",
    ),
    miniapp_endpoint(
      id="placement-delete",
      http_method="DELETE",
      path="/placements/:id",
      writes=true,
      summary="Remove a building placement without deleting the building.",
    ),
    miniapp_endpoint(
      id="building-book",
      http_method="GET",
      path="/buildings/:id/book",
      summary="Return the safe book projection behind a building.",
    ),
    miniapp_endpoint(
      id="building-agents",
      http_method="GET",
      path="/buildings/:id/agents",
      summary="List agents attached to a building.",
    ),
    miniapp_endpoint(
      id="building-query",
      http_method="POST",
      path="/buildings/:id/query",
      writes=true,
      summary="Start a building-scoped query run.",
    ),
    miniapp_endpoint(
      id="agents",
      http_method="GET",
      path="/agents",
      summary="List agents visible to the signed-in user.",
    ),
    miniapp_endpoint(
      id="agent-create",
      http_method="POST",
      path="/agents",
      writes=true,
      summary="Create a user or building scoped agent profile.",
    ),
    miniapp_endpoint(
      id="agent-update",
      http_method="PATCH",
      path="/agents/:id",
      writes=true,
      summary="Update an editable agent profile.",
    ),
    miniapp_endpoint(
      id="chat-send",
      http_method="POST",
      path="/chat/send",
      writes=true,
      summary="Append a user message and optionally start an agent run.",
    ),
    miniapp_endpoint(
      id="thread-detail",
      http_method="GET",
      path="/threads/:id",
      summary="Return thread messages visible to the signed-in user.",
    ),
    miniapp_endpoint(
      id="run-status",
      http_method="GET",
      path="/runs/:id/status",
      summary="Return run status and review/cancel/retry affordances.",
    ),
    miniapp_endpoint(
      id="run-cancel",
      http_method="POST",
      path="/runs/:id/cancel",
      writes=true,
      summary="Cancel a running or pending agent run.",
    ),
    miniapp_endpoint(
      id="run-retry",
      http_method="POST",
      path="/runs/:id/retry",
      writes=true,
      summary="Retry a failed or cancelled run.",
    ),
    miniapp_endpoint(
      id="review-decision",
      http_method="POST",
      path="/reviews/:id/decision",
      writes=true,
      summary="Approve, reject, or request changes for a review item.",
    ),
  ]
}

///|
pub fn miniapp_endpoint_by_id(id : String) -> MiniappEndpoint? {
  for endpoint in miniapp_contract_endpoints() {
    if endpoint.id == id {
      return Some(endpoint)
    }
  }
  None
}
