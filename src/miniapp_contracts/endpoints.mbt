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
      id="auth-visitor",
      http_method="POST",
      path="/miniapp/auth/visitor",
      writes=true,
      auth_required=false,
      summary="Create a bounded anonymous visitor session.",
    ),
    miniapp_endpoint(
      id="account-context",
      http_method="GET",
      path="/miniapp/me",
      summary="Return the server-derived plan, roles, tenant choices, entitlements, and home surface.",
    ),
    miniapp_endpoint(
      id="account-tenant-switch",
      http_method="POST",
      path="/miniapp/account/tenant",
      writes=true,
      summary="Switch only to an active tenant already assigned to the session principal.",
    ),
    miniapp_endpoint(
      id="account-enterprise-management",
      http_method="GET",
      path="/miniapp/account/enterprise",
      summary="Return the active enterprise workspace management surface when entitled.",
    ),
    miniapp_endpoint(
      id="account-admin-management",
      http_method="GET",
      path="/miniapp/account/admin",
      summary="Return the platform operations management surface for platform administrators.",
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
    miniapp_endpoint(
      id="supervisor-profile",
      http_method="GET",
      path="/miniapp/onboarding/supervisor",
      summary="Return the signed-in user's durable supervisor profile and readiness.",
    ),
    miniapp_endpoint(
      id="supervisor-draft",
      http_method="PUT",
      path="/miniapp/onboarding/supervisor/draft",
      writes=true,
      summary="Create or revise the signed-in user's supervisor profile draft.",
    ),
    miniapp_endpoint(
      id="supervisor-activate",
      http_method="POST",
      path="/miniapp/onboarding/supervisor/activate",
      writes=true,
      summary="Queue an opaque supervisor activation handoff for MoonClaw.",
    ),
    miniapp_endpoint(
      id="run-steer",
      http_method="POST",
      path="/miniapp/runs/steer",
      writes=true,
      summary="Queue a bounded MoonClaw run steering handoff.",
    ),
    miniapp_endpoint(
      id="run-delegate",
      http_method="POST",
      path="/miniapp/runs/delegate",
      writes=true,
      summary="Queue an explicit bounded worker assignment with visible task and scope ceilings.",
    ),
    miniapp_endpoint(
      id="child-run-steer",
      http_method="POST",
      path="/miniapp/runs/child/steer",
      writes=true,
      summary="Steer one receipt-backed child run without changing its supervisor parent identity.",
    ),
    miniapp_endpoint(
      id="supervisor-wake",
      http_method="POST",
      path="/miniapp/runs/supervisor/wake",
      writes=true,
      summary="Wake the exact receipt-backed active supervisor run.",
    ),
    miniapp_endpoint(
      id="supervisor-stop",
      http_method="POST",
      path="/miniapp/runs/supervisor/stop",
      writes=true,
      summary="Request a graceful stop for the exact receipt-backed active supervisor run.",
    ),
    miniapp_endpoint(
      id="supervisor-resume",
      http_method="POST",
      path="/miniapp/runs/supervisor/resume",
      writes=true,
      summary="Retry or resume the exact receipt-backed active supervisor run.",
    ),
    miniapp_endpoint(
      id="supervisor-message",
      http_method="POST",
      path="/miniapp/messages",
      writes=true,
      summary="Send a message to the active supervisor run without delegating a worker.",
    ),
    miniapp_endpoint(
      id="runtime-observation-reconcile",
      http_method="POST",
      path="/miniapp/runtime/observations/reconcile",
      writes=true,
      summary="Persist a digest-bound MoonClaw supervisor status and replay observation.",
    ),
    miniapp_endpoint(
      id="marketplace-search",
      http_method="GET",
      path="/miniapp/marketplace/discovery/search",
      summary="Search only sanitized published agent and building cards; sponsored placements are excluded.",
    ),
    miniapp_endpoint(
      id="marketplace-recommendations",
      http_method="GET",
      path="/miniapp/marketplace/discovery/recommendations",
      summary="Return deterministic recommendations with a human-readable reason.",
    ),
    miniapp_endpoint(
      id="marketplace-feed",
      http_method="GET",
      path="/miniapp/marketplace/discovery/feed",
      summary="Return structurally separate organic, recommended, and sponsored discovery lanes.",
    ),
    miniapp_endpoint(
      id="marketplace-public-index",
      http_method="GET",
      path="/miniapp/marketplace/public-index",
      summary="Export exact sanitized moonsuite.public-listing.v1 cards for MoonFind.",
    ),
    miniapp_endpoint(
      id="marketplace-review-queue",
      http_method="GET",
      path="/miniapp/marketplace/review-queue",
      summary="Return same-tenant submitted public cards to an independent publisher or moderator reviewer.",
    ),
    miniapp_endpoint(
      id="marketplace-agent-draft",
      http_method="POST",
      path="/miniapp/marketplace/listings/agent",
      writes=true,
      summary="Create or revise the session principal's publishable agent card.",
    ),
    miniapp_endpoint(
      id="marketplace-building-draft",
      http_method="POST",
      path="/miniapp/marketplace/listings/building",
      writes=true,
      summary="Create or revise the session principal's publishable building card.",
    ),
    miniapp_endpoint(
      id="marketplace-listing-transition",
      http_method="POST",
      path="/miniapp/marketplace/listings/transition",
      writes=true,
      summary="Advance an agent or building through the governed publication lifecycle.",
    ),
    miniapp_endpoint(
      id="marketplace-listing-action",
      http_method="POST",
      path="/miniapp/marketplace/listings/action",
      writes=true,
      summary="Request one action explicitly offered by a published listing.",
    ),
    miniapp_endpoint(
      id="marketplace-action-requests",
      http_method="GET",
      path="/miniapp/marketplace/action-requests",
      summary="List the session principal's requester and publisher action queue.",
    ),
    miniapp_endpoint(
      id="marketplace-action-decision",
      http_method="POST",
      path="/miniapp/marketplace/action-requests/decision",
      writes=true,
      summary="Approve or reject one request; approval queues the existing bounded MoonClaw handoff.",
    ),
    miniapp_endpoint(
      id="marketplace-action-retry",
      http_method="POST",
      path="/miniapp/marketplace/action-requests/retry-handoff",
      writes=true,
      summary="Retry only the handoff step for a previously approved request.",
    ),
    miniapp_endpoint(
      id="marketplace-channels-read",
      http_method="GET",
      path="/miniapp/marketplace/channels",
      summary="List the session principal's readable ACL-bound channels.",
    ),
    miniapp_endpoint(
      id="marketplace-channels-create",
      http_method="POST",
      path="/miniapp/marketplace/channels",
      writes=true,
      summary="Create an ACL-bound channel.",
    ),
    miniapp_endpoint(
      id="marketplace-messages-read",
      http_method="GET",
      path="/miniapp/marketplace/messages",
      summary="Read audience-filtered messages in an authorized channel.",
    ),
    miniapp_endpoint(
      id="marketplace-messages-send",
      http_method="POST",
      path="/miniapp/marketplace/messages",
      writes=true,
      summary="Send an audience-bound message inside an authorized channel.",
    ),
    miniapp_endpoint(
      id="marketplace-notifications",
      http_method="GET",
      path="/miniapp/marketplace/notifications",
      summary="Return only the session principal's notification inbox.",
    ),
    miniapp_endpoint(
      id="marketplace-notification-read",
      http_method="POST",
      path="/miniapp/marketplace/notifications/read",
      writes=true,
      summary="Mark one session-principal notification read.",
    ),
    miniapp_endpoint(
      id="marketplace-subscription",
      http_method="POST",
      path="/miniapp/marketplace/subscriptions",
      writes=true,
      summary="Follow or unfollow an allowed public topic.",
    ),
    miniapp_endpoint(
      id="marketplace-share-grant",
      http_method="POST",
      path="/miniapp/marketplace/share-grants",
      writes=true,
      summary="Create an explicit resource share grant.",
    ),
    miniapp_endpoint(
      id="marketplace-share-grant-revoke",
      http_method="POST",
      path="/miniapp/marketplace/share-grants/revoke",
      writes=true,
      summary="Revoke one owned grant without erasing its audit record.",
    ),
    miniapp_endpoint(
      id="marketplace-shared-listings",
      http_method="GET",
      path="/miniapp/marketplace/shared-listings",
      summary="List sanitized private/shared cards visible through active grants.",
    ),
    miniapp_endpoint(
      id="marketplace-share-preview",
      http_method="POST",
      path="/miniapp/marketplace/shares/preview",
      writes=true,
      summary="Preview the exact sanitized projection before sharing.",
    ),
    miniapp_endpoint(
      id="marketplace-sponsored",
      http_method="POST",
      path="/miniapp/marketplace/sponsored",
      writes=true,
      summary="Create a visibly labeled placement separate from organic rank.",
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
