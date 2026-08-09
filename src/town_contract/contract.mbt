///|
pub fn schema_version() -> String {
  "moontown.api.v1"
}

///|
pub fn desktop_contract_path() -> String {
  "/api/contract"
}

///|
pub fn desktop_standing_watch_path() -> String {
  "/api/operator-requests"
}

///|
pub fn desktop_standing_goals_path() -> String {
  "/api/standing-goals"
}

///|
pub fn desktop_evidence_book_path() -> String {
  "/api/book-template-requests"
}

///|
pub fn desktop_moonclaw_guide_path() -> String {
  "/api/agent/chat"
}

///|
pub fn desktop_book_registration_path() -> String {
  "/api/book-registrations"
}

///|
pub fn desktop_research_handoff_path() -> String {
  "/api/research-handoffs/inspect"
}

///|
pub fn desktop_research_handoff_start_path() -> String {
  "/api/research-handoffs/start"
}

///|
pub fn desktop_research_handoff_reconcile_path() -> String {
  "/api/research-handoffs/reconcile"
}

///|
pub fn desktop_moonflow_research_start_path() -> String {
  "/api/research-handoffs/moonflow/start"
}

///|
pub fn desktop_moonflow_research_reconcile_path() -> String {
  "/api/research-handoffs/moonflow/reconcile"
}

///|
pub fn miniapp_contract_path() -> String {
  "/miniapp/contract"
}

///|
pub fn miniapp_health_path() -> String {
  "/miniapp/health"
}

///|
pub fn miniapp_visitor_session_path() -> String {
  "/miniapp/auth/visitor"
}

///|
pub fn miniapp_account_context_path() -> String {
  "/miniapp/me"
}

///|
pub fn miniapp_account_tenant_switch_path() -> String {
  "/miniapp/account/tenant"
}

///|
pub fn miniapp_enterprise_management_path() -> String {
  "/miniapp/account/enterprise"
}

///|
pub fn miniapp_admin_management_path() -> String {
  "/miniapp/account/admin"
}

///|
pub fn miniapp_snapshot_path() -> String {
  "/miniapp/town/snapshot"
}

///|
pub fn miniapp_book_registration_path() -> String {
  "/miniapp/book-registrations"
}

///|
pub fn miniapp_standing_watch_path() -> String {
  "/miniapp/research/watches"
}

///|
pub fn miniapp_evidence_book_path() -> String {
  "/miniapp/research/evidence-books"
}

///|
pub fn miniapp_supervisor_path() -> String {
  "/miniapp/onboarding/supervisor"
}

///|
pub fn miniapp_supervisor_draft_path() -> String {
  "/miniapp/onboarding/supervisor/draft"
}

///|
pub fn miniapp_supervisor_activation_path() -> String {
  "/miniapp/onboarding/supervisor/activate"
}

///|
pub fn miniapp_supervisor_readiness_path() -> String {
  "/miniapp/onboarding/supervisor/readiness"
}

///|
pub fn miniapp_run_steer_path() -> String {
  "/miniapp/runs/steer"
}

///|
pub fn miniapp_run_delegate_path() -> String {
  "/miniapp/runs/delegate"
}

///|
pub fn miniapp_child_run_steer_path() -> String {
  "/miniapp/runs/child/steer"
}

///|
pub fn miniapp_supervisor_wake_path() -> String {
  "/miniapp/runs/supervisor/wake"
}

///|
pub fn miniapp_supervisor_stop_path() -> String {
  "/miniapp/runs/supervisor/stop"
}

///|
pub fn miniapp_supervisor_resume_path() -> String {
  "/miniapp/runs/supervisor/resume"
}

///|
pub fn miniapp_message_path() -> String {
  "/miniapp/messages"
}

///|
pub fn miniapp_run_cancel_path() -> String {
  "/miniapp/runs/cancel"
}

///|
pub fn miniapp_run_retry_path() -> String {
  "/miniapp/runs/retry"
}

///|
pub fn miniapp_review_decision_path() -> String {
  "/miniapp/reviews/decision"
}

///|
pub fn miniapp_runtime_outbox_path() -> String {
  "/miniapp/outbox/runtime"
}

///|
pub fn miniapp_runtime_outbox_claim_path() -> String {
  "/miniapp/outbox/runtime/claim"
}

///|
pub fn miniapp_runtime_outbox_reconcile_path() -> String {
  "/miniapp/outbox/runtime/reconcile"
}

///|
pub fn miniapp_runtime_outbox_release_path() -> String {
  "/miniapp/outbox/runtime/release"
}

///|
pub fn miniapp_runtime_observation_reconcile_path() -> String {
  "/miniapp/runtime/observations/reconcile"
}

///|
pub fn miniapp_bookkeeper_outbox_path() -> String {
  "/miniapp/outbox/bookkeeper"
}

///|
pub fn miniapp_bookkeeper_outbox_claim_path() -> String {
  "/miniapp/outbox/bookkeeper/claim"
}

///|
pub fn miniapp_bookkeeper_outbox_reconcile_path() -> String {
  "/miniapp/outbox/bookkeeper/reconcile"
}

///|
pub fn miniapp_bookkeeper_outbox_release_path() -> String {
  "/miniapp/outbox/bookkeeper/release"
}

///|
pub fn miniapp_marketplace_search_path() -> String {
  "/miniapp/marketplace/discovery/search"
}

///|
pub fn miniapp_marketplace_recommendations_path() -> String {
  "/miniapp/marketplace/discovery/recommendations"
}

///|
pub fn miniapp_marketplace_feed_path() -> String {
  "/miniapp/marketplace/discovery/feed"
}

///|
pub fn miniapp_marketplace_public_index_path() -> String {
  "/miniapp/marketplace/public-index"
}

///|
pub fn miniapp_marketplace_review_queue_path() -> String {
  "/miniapp/marketplace/review-queue"
}

///|
pub fn miniapp_marketplace_agent_listing_path() -> String {
  "/miniapp/marketplace/listings/agent"
}

///|
pub fn miniapp_marketplace_building_listing_path() -> String {
  "/miniapp/marketplace/listings/building"
}

///|
pub fn miniapp_marketplace_listing_transition_path() -> String {
  "/miniapp/marketplace/listings/transition"
}

///|
pub fn miniapp_marketplace_listing_action_path() -> String {
  "/miniapp/marketplace/listings/action"
}

///|
pub fn miniapp_marketplace_action_requests_path() -> String {
  "/miniapp/marketplace/action-requests"
}

///|
pub fn miniapp_marketplace_action_decision_path() -> String {
  "/miniapp/marketplace/action-requests/decision"
}

///|
pub fn miniapp_marketplace_action_retry_path() -> String {
  "/miniapp/marketplace/action-requests/retry-handoff"
}

///|
pub fn miniapp_marketplace_channels_path() -> String {
  "/miniapp/marketplace/channels"
}

///|
pub fn miniapp_marketplace_messages_path() -> String {
  "/miniapp/marketplace/messages"
}

///|
pub fn miniapp_marketplace_notifications_path() -> String {
  "/miniapp/marketplace/notifications"
}

///|
pub fn miniapp_marketplace_notifications_read_path() -> String {
  "/miniapp/marketplace/notifications/read"
}

///|
pub fn miniapp_marketplace_subscriptions_path() -> String {
  "/miniapp/marketplace/subscriptions"
}

///|
pub fn miniapp_marketplace_share_grants_path() -> String {
  "/miniapp/marketplace/share-grants"
}

///|
pub fn miniapp_marketplace_share_grants_revoke_path() -> String {
  "/miniapp/marketplace/share-grants/revoke"
}

///|
pub fn miniapp_marketplace_shared_listings_path() -> String {
  "/miniapp/marketplace/shared-listings"
}

///|
pub fn miniapp_marketplace_share_preview_path() -> String {
  "/miniapp/marketplace/shares/preview"
}

///|
pub fn miniapp_marketplace_sponsored_path() -> String {
  "/miniapp/marketplace/sponsored"
}

///|
fn endpoint(
  id : String,
  http_method : String,
  path : String,
  capability : String,
) -> Json {
  { "id": id, "method": http_method, "path": path, "capability": capability }
}

///|
pub fn desktop_contract() -> Json {
  {
    "schema": schema_version(),
    "audience": "trusted-local-operator",
    "transport": "localhost",
    "transportEndpointsOnOwnerService": true,
    "miniappAdapter": {
      "contractPath": miniapp_contract_path(),
      "defaultLocalUrl": "http://127.0.0.1:18191",
      "configuredBy": "MOONTOWN_MINIAPP_SERVICE_URL",
    },
    "endpoints": [
      endpoint("contract", "GET", desktop_contract_path(), "contract.read"),
      endpoint(
        "list-standing-watches",
        "GET",
        desktop_standing_watch_path(),
        "research.watch.read",
      ),
      endpoint(
        "submit-standing-watch",
        "POST",
        desktop_standing_watch_path(),
        "research.watch.submit",
      ),
      endpoint(
        "list-standing-goals",
        "GET",
        desktop_standing_goals_path(),
        "research.watch.read",
      ),
      endpoint(
        "queue-evidence-book",
        "POST",
        desktop_evidence_book_path(),
        "research.evidence-book.queue",
      ),
      endpoint(
        "chat-with-moontown-guide",
        "POST",
        desktop_moonclaw_guide_path(),
        "moonclaw.guide.chat",
      ),
      endpoint(
        "query-supervisor-profile",
        "GET",
        miniapp_supervisor_path(),
        "supervisor.profile.read",
      ),
      endpoint(
        "save-supervisor-draft",
        "PUT",
        miniapp_supervisor_draft_path(),
        "supervisor.profile.write",
      ),
      endpoint(
        "activate-supervisor",
        "POST",
        miniapp_supervisor_activation_path(),
        "supervisor.activation.request",
      ),
      endpoint(
        "query-supervisor-readiness",
        "GET",
        miniapp_supervisor_readiness_path(),
        "supervisor.readiness.read",
      ),
      endpoint(
        "steer-run",
        "POST",
        miniapp_run_steer_path(),
        "moonclaw.supervisor.steer.request",
      ),
      endpoint(
        "delegate-run",
        "POST",
        miniapp_run_delegate_path(),
        "moonclaw.worker.delegate.request",
      ),
      endpoint(
        "steer-child-run",
        "POST",
        miniapp_child_run_steer_path(),
        "moonclaw.worker.steer.request",
      ),
      endpoint(
        "wake-supervisor",
        "POST",
        miniapp_supervisor_wake_path(),
        "moonclaw.supervisor.wake.request",
      ),
      endpoint(
        "stop-supervisor",
        "POST",
        miniapp_supervisor_stop_path(),
        "moonclaw.supervisor.stop.request",
      ),
      endpoint(
        "resume-supervisor",
        "POST",
        miniapp_supervisor_resume_path(),
        "moonclaw.supervisor.resume.request",
      ),
      endpoint(
        "send-message",
        "POST",
        miniapp_message_path(),
        "moonclaw.supervisor.message.request",
      ),
      endpoint(
        "cancel-run",
        "POST",
        miniapp_run_cancel_path(),
        "moonclaw.run.cancel.request",
      ),
      endpoint(
        "retry-run",
        "POST",
        miniapp_run_retry_path(),
        "moonclaw.run.retry.request",
      ),
      endpoint(
        "request-bookkeeper-review",
        "POST",
        miniapp_review_decision_path(),
        "bookkeeper.outcome.submit",
      ),
      endpoint(
        "runtime-outbox",
        "GET",
        miniapp_runtime_outbox_path(),
        "runtime.handoff.read",
      ),
      endpoint(
        "claim-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_claim_path(),
        "runtime.handoff.claim",
      ),
      endpoint(
        "reconcile-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_reconcile_path(),
        "runtime.handoff.reconcile",
      ),
      endpoint(
        "reconcile-runtime-observation",
        "POST",
        miniapp_runtime_observation_reconcile_path(),
        "runtime.observation.reconcile",
      ),
      endpoint(
        "release-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_release_path(),
        "runtime.handoff.release",
      ),
      endpoint(
        "bookkeeper-outbox",
        "GET",
        miniapp_bookkeeper_outbox_path(),
        "bookkeeper.outcome.read",
      ),
      endpoint(
        "claim-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_claim_path(),
        "bookkeeper.outcome.claim",
      ),
      endpoint(
        "reconcile-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_reconcile_path(),
        "bookkeeper.outcome.reconcile",
      ),
      endpoint(
        "release-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_release_path(),
        "bookkeeper.outcome.release",
      ),
      endpoint(
        "list-book-registrations",
        "GET",
        desktop_book_registration_path(),
        "book.catalog.read",
      ),
      endpoint(
        "register-existing-book",
        "POST",
        desktop_book_registration_path(),
        "book.catalog.register",
      ),
      endpoint(
        "inspect-research-handoff",
        "POST",
        desktop_research_handoff_path(),
        "civic.communication.handoff.inspect",
      ),
      endpoint(
        "start-research-handoff",
        "POST",
        desktop_research_handoff_start_path(),
        "civic.communication.handoff.execute",
      ),
      endpoint(
        "reconcile-research-handoff",
        "POST",
        desktop_research_handoff_reconcile_path(),
        "civic.communication.handoff.reconcile",
      ),
      endpoint(
        "start-moonflow-research-handoff",
        "POST",
        desktop_moonflow_research_start_path(),
        "civic.communication.moonflow.execute",
      ),
      endpoint(
        "reconcile-moonflow-research-handoff",
        "POST",
        desktop_moonflow_research_reconcile_path(),
        "civic.communication.moonflow.reconcile",
      ),
      endpoint(
        "runtime-outbox",
        "GET",
        miniapp_runtime_outbox_path(),
        "runtime.handoff.read",
      ),
      endpoint(
        "claim-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_claim_path(),
        "runtime.handoff.claim",
      ),
      endpoint(
        "release-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_release_path(),
        "runtime.handoff.release",
      ),
      endpoint(
        "reconcile-runtime-handoff",
        "POST",
        miniapp_runtime_outbox_reconcile_path(),
        "runtime.handoff.reconcile",
      ),
      endpoint(
        "reconcile-runtime-observation",
        "POST",
        miniapp_runtime_observation_reconcile_path(),
        "runtime.observation.reconcile",
      ),
      endpoint(
        "bookkeeper-outbox",
        "GET",
        miniapp_bookkeeper_outbox_path(),
        "bookkeeper.outcome.read",
      ),
      endpoint(
        "claim-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_claim_path(),
        "bookkeeper.outcome.claim",
      ),
      endpoint(
        "release-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_release_path(),
        "bookkeeper.outcome.release",
      ),
      endpoint(
        "reconcile-bookkeeper-request",
        "POST",
        miniapp_bookkeeper_outbox_reconcile_path(),
        "bookkeeper.outcome.reconcile",
      ),
    ],
  }
}

///|
pub fn miniapp_contract() -> Json {
  {
    "schema": schema_version(),
    "audience": "authenticated-miniapp-user",
    "transport": "https-or-local-dev",
    "sessionHeader": "x-miniapp-session",
    "endpoints": [
      endpoint("health", "GET", miniapp_health_path(), "health.read"),
      endpoint("contract", "GET", miniapp_contract_path(), "contract.read"),
      endpoint(
        "create-visitor-session",
        "POST",
        miniapp_visitor_session_path(),
        "account.visitor.create",
      ),
      endpoint(
        "account-context",
        "GET",
        miniapp_account_context_path(),
        "account.context.read",
      ),
      endpoint(
        "switch-account-tenant",
        "POST",
        miniapp_account_tenant_switch_path(),
        "account.tenant.switch",
      ),
      endpoint(
        "enterprise-management",
        "GET",
        miniapp_enterprise_management_path(),
        "account.enterprise.manage",
      ),
      endpoint(
        "admin-management",
        "GET",
        miniapp_admin_management_path(),
        "account.platform.manage",
      ),
      endpoint(
        "load-town-snapshot",
        "GET",
        miniapp_snapshot_path(),
        "town.snapshot.read",
      ),
      endpoint(
        "list-installed-books",
        "GET",
        miniapp_book_registration_path(),
        "book.catalog.read",
      ),
      endpoint(
        "submit-standing-watch",
        "POST",
        miniapp_standing_watch_path(),
        "research.watch.submit",
      ),
      endpoint(
        "queue-evidence-book",
        "POST",
        miniapp_evidence_book_path(),
        "research.evidence-book.queue",
      ),
      endpoint(
        "marketplace-search",
        "GET",
        miniapp_marketplace_search_path(),
        "marketplace.search.organic",
      ),
      endpoint(
        "marketplace-recommendations",
        "GET",
        miniapp_marketplace_recommendations_path(),
        "marketplace.recommend.explainable",
      ),
      endpoint(
        "marketplace-feed",
        "GET",
        miniapp_marketplace_feed_path(),
        "marketplace.discovery.read",
      ),
      endpoint(
        "marketplace-public-index",
        "GET",
        miniapp_marketplace_public_index_path(),
        "marketplace.public-index.read",
      ),
      endpoint(
        "marketplace-agent-draft",
        "POST",
        miniapp_marketplace_agent_listing_path(),
        "marketplace.agent.write",
      ),
      endpoint(
        "marketplace-building-draft",
        "POST",
        miniapp_marketplace_building_listing_path(),
        "marketplace.building.write",
      ),
      endpoint(
        "marketplace-listing-transition",
        "POST",
        miniapp_marketplace_listing_transition_path(),
        "marketplace.publication.transition",
      ),
      endpoint(
        "marketplace-listing-action",
        "POST",
        miniapp_marketplace_listing_action_path(),
        "marketplace.listing.action",
      ),
      endpoint(
        "marketplace-action-requests",
        "GET",
        miniapp_marketplace_action_requests_path(),
        "marketplace.action-request.read",
      ),
      endpoint(
        "marketplace-action-decision",
        "POST",
        miniapp_marketplace_action_decision_path(),
        "marketplace.action-request.decide",
      ),
      endpoint(
        "marketplace-action-retry",
        "POST",
        miniapp_marketplace_action_retry_path(),
        "marketplace.action-request.retry-handoff",
      ),
      endpoint(
        "marketplace-channels-read",
        "GET",
        miniapp_marketplace_channels_path(),
        "marketplace.channel.read",
      ),
      endpoint(
        "marketplace-channels-create",
        "POST",
        miniapp_marketplace_channels_path(),
        "marketplace.channel.write",
      ),
      endpoint(
        "marketplace-messages-read",
        "GET",
        miniapp_marketplace_messages_path(),
        "marketplace.message.read",
      ),
      endpoint(
        "marketplace-messages-send",
        "POST",
        miniapp_marketplace_messages_path(),
        "marketplace.message.write",
      ),
      endpoint(
        "marketplace-notifications",
        "GET",
        miniapp_marketplace_notifications_path(),
        "marketplace.notification.read",
      ),
      endpoint(
        "marketplace-notification-read",
        "POST",
        miniapp_marketplace_notifications_read_path(),
        "marketplace.notification.ack",
      ),
      endpoint(
        "marketplace-subscription",
        "POST",
        miniapp_marketplace_subscriptions_path(),
        "marketplace.subscription.write",
      ),
      endpoint(
        "marketplace-share-grant",
        "POST",
        miniapp_marketplace_share_grants_path(),
        "marketplace.share.write",
      ),
      endpoint(
        "marketplace-share-grant-revoke",
        "POST",
        miniapp_marketplace_share_grants_revoke_path(),
        "marketplace.share.revoke",
      ),
      endpoint(
        "marketplace-shared-listings",
        "GET",
        miniapp_marketplace_shared_listings_path(),
        "marketplace.share.read",
      ),
      endpoint(
        "marketplace-share-preview",
        "POST",
        miniapp_marketplace_share_preview_path(),
        "marketplace.share.preview",
      ),
      endpoint(
        "marketplace-sponsored",
        "POST",
        miniapp_marketplace_sponsored_path(),
        "marketplace.sponsored.write",
      ),
    ],
  }
}
