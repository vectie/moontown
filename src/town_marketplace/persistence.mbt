///|
let marketplace_store_mutex : @async.Mutex = Mutex()

///|
fn migrate_marketplace_state_json(value : Json) -> Json {
  guard value is Object(fields) else { return value }
  let schema = api_string(fields, "schema")
  if schema == "moontown.marketplace-store.v1" {
    fields["schema"] = marketplace_schema().to_json()
  }
  if fields.get("action_requests") is None {
    fields["action_requests"] = Json::array([])
  }
  Json::object(fields)
}

///|
pub fn marketplace_application(
  state_path : String,
  bootstrap_principal : MarketplacePrincipal,
  bootstrap_session_id : String,
  bootstrap_opaque_token : String,
) -> MarketplaceApplication raise {
  if bootstrap_opaque_token.length() < 12 ||
    !valid_symbolic_id(bootstrap_principal.principal_id) ||
    !valid_symbolic_id(bootstrap_session_id) {
    fail(
      "marketplace bootstrap requires a strong opaque session and symbolic identity",
    )
  }
  {
    state_path,
    bootstrap_principal,
    bootstrap_session_id,
    bootstrap_token_digest: marketplace_token_digest(bootstrap_opaque_token),
  }
}

///|
fn MarketplaceApplication::ensure_bootstrap(
  self : MarketplaceApplication,
  state : MarketplaceState,
) -> MarketplaceState {
  let principals = state.principals.filter(principal => {
    principal.principal_id != self.bootstrap_principal.principal_id
  })
  principals.push(self.bootstrap_principal)
  let sessions = state.sessions.filter(session => {
    session.session_id != self.bootstrap_session_id &&
    session.token_digest != self.bootstrap_token_digest
  })
  sessions.push({
    session_id: self.bootstrap_session_id,
    token_digest: self.bootstrap_token_digest,
    principal_id: self.bootstrap_principal.principal_id,
    expires_at_ms: 18446744073709551615UL,
    revoked: false,
    version: 1,
  })
  { ..state, principals, sessions }
}

///|
async fn MarketplaceApplication::load_state(
  self : MarketplaceApplication,
) -> MarketplaceState {
  let state = match @support.read_optional_json_file(self.state_path) {
    Some(value) => {
      let decoded : MarketplaceState = @json.from_json(
        migrate_marketplace_state_json(value),
      ) catch {
        error => fail("marketplace state is invalid: \{error}")
      }
      if decoded.schema != marketplace_schema() {
        fail("unsupported marketplace state schema")
      }
      decoded
    }
    None => empty_marketplace_state()
  }
  self.ensure_bootstrap(state)
}

///|
async fn MarketplaceApplication::save_state(
  self : MarketplaceApplication,
  state : MarketplaceState,
) -> Unit {
  let temp = self.state_path + ".next"
  @support.ensure_parent_directory(self.state_path)
  @fs.write_file(
    temp,
    state.to_json().stringify(indent=2) + "\n",
    create_mode=CreateOrTruncate,
    permission=0o600,
    sync=Full,
  )
  @fs.rename(temp, self.state_path, replace=true)
}

///|
fn require_session_principal(
  state : MarketplaceState,
  opaque_token : String,
  now_ms : UInt64,
) -> MarketplacePrincipal raise {
  marketplace_principal_for_session(state, opaque_token, now_ms~).unwrap_or_else(() => {
      fail("missing, expired, or revoked marketplace session")
    },
  )
}

///|
fn application_ok(operation : String, payload : Json) -> Json {
  { "ok": true, "operation": operation, "payload": payload }
}

///| Single durable feature boundary used by the HTTP adapter. Identity always

///|
/// comes from `opaque_session`, never from a caller-selected principal field.
pub async fn MarketplaceApplication::execute(
  self : MarketplaceApplication,
  opaque_session : String,
  operation : String,
  payload_text : String,
  query : String,
  now_ms~ : UInt64,
) -> Json {
  marketplace_store_mutex.acquire()
  defer marketplace_store_mutex.release()
  let state = self.load_state()
  let principal = require_session_principal(state, opaque_session, now_ms)
  let payload = if payload_text.trim().is_empty() {
    Json::empty_object()
  } else {
    @json.parse(payload_text)
  }
  match operation {
    "search" =>
      application_ok(operation, {
        "contract_id": "moontown.discovery-search.v1",
        "query": query,
        "organic_results": marketplace_organic_search(state, query).to_json(),
        "result_count": marketplace_organic_search(state, query).length(),
      })
    "recommendations" =>
      application_ok(operation, {
        "contract_id": "moontown.recommendations.v1",
        "recommendations": marketplace_recommendations(state, principal).to_json(),
      })
    "feed" =>
      application_ok(
        operation,
        marketplace_discovery_feed(state, principal, query, now_ms),
      )
    "public-index" =>
      application_ok(operation, public_listing_index_export(state))
    "review-queue" =>
      application_ok(
        operation,
        marketplace_listing_review_queue(state, principal),
      )
    "list-channels" =>
      application_ok(operation, {
        "contract_id": "moontown.channels.v1",
        "channels": marketplace_visible_channels(state, principal).to_json(),
      })
    "list-messages" =>
      application_ok(operation, {
        "contract_id": "moontown.channel-messages.v1",
        "channel_id": query,
        "messages": marketplace_visible_messages(state, principal, query).to_json(),
      })
    "notifications" =>
      application_ok(operation, marketplace_notifications_for(state, principal))
    "action-requests" =>
      application_ok(
        operation,
        marketplace_visible_action_requests(state, principal),
      )
    "prepare-action-handoff" => {
      let draft : ActionRequestResumeDraft = @json.from_json(payload)
      application_ok(operation, {
        "action_request": marketplace_prepare_action_handoff(
          state, principal, draft,
        ),
      })
    }
    "shared-listings" =>
      application_ok(operation, {
        "contract_id": "moontown.shared-listings.v1",
        "listings": marketplace_shared_listing_cards(state, principal, now_ms~).to_json(),
      })
    "share-preview" => {
      let draft = parse_share_preview_draft(payload)
      application_ok(
        operation,
        marketplace_share_preview(
          state,
          principal,
          draft.resource_kind,
          draft.resource_id,
          draft.grantee_principal_id,
        ),
      )
    }
    "upsert-agent" => {
      let draft : AgentListingDraft = @json.from_json(payload)
      let next = marketplace_upsert_agent_draft(
        state,
        principal,
        draft,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, {
        "listing_id": draft.listing_id,
        "publication_state": "draft",
      })
    }
    "upsert-building" => {
      let draft : BuildingListingDraft = @json.from_json(payload)
      let next = marketplace_upsert_building_draft(
        state,
        principal,
        draft,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, {
        "listing_id": draft.listing_id,
        "publication_state": "draft",
      })
    }
    "transition-listing" => {
      let draft : ListingTransitionDraft = @json.from_json(payload)
      let kind = parse_listing_kind(draft.listing_kind)
      let target = parse_publication_state(draft.target_state)
      let transitioned = marketplace_transition_listing(
        state,
        principal,
        kind,
        draft.listing_id,
        target,
        review_summary=draft.review_summary,
        now_ms~,
      )
      let next = if target == PublicationPublished {
        marketplace_emit_publication_notifications(
          transitioned,
          kind,
          draft.listing_id,
          now_ms~,
        )
      } else {
        transitioned
      }
      self.save_state(next)
      application_ok(operation, {
        "listing_id": draft.listing_id,
        "listing_kind": draft.listing_kind,
        "publication_state": draft.target_state,
      })
    }
    "listing-action" => {
      let draft : ListingActionDraft = @json.from_json(payload)
      let action_request_id = if marketplace_action_requires_publisher_decision(
          draft.action_id,
        ) {
        Some(
          "action:\{draft.listing_id}:\{principal.principal_id}:\{state.version}",
        )
      } else {
        None
      }
      let next = marketplace_request_listing_action(
        state,
        principal,
        parse_listing_kind(draft.listing_kind),
        draft.listing_id,
        draft.action_id,
        draft.message,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, {
        "requested": true,
        "action_request_id": optional_string_wire(action_request_id),
      })
    }
    "decide-action-request" => {
      let draft : ActionRequestDecisionDraft = @json.from_json(payload)
      let next = marketplace_decide_action_request(
        state,
        principal,
        draft,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, {
        "action_request": marketplace_action_request_projection(
          next,
          principal,
          draft.request_id,
        ),
      })
    }
    "bind-action-handoff" => {
      let draft : ActionRequestHandoffDraft = @json.from_json(payload)
      let next = marketplace_bind_action_handoff(
        state,
        principal,
        draft,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, {
        "action_request": marketplace_action_request_projection(
          next,
          principal,
          draft.request_id,
        ),
      })
    }
    "create-channel" => {
      let draft = parse_channel_draft(payload)
      let members : Array[ChannelMember] = [
        {
          principal_id: principal.principal_id,
          role: ChannelOwner,
          joined_at_ms: now_ms,
          active: true,
          version: 1,
        },
      ]
      for member_id in draft.member_principal_ids {
        if member_id != principal.principal_id {
          members.push({
            principal_id: member_id,
            role: ChannelParticipant,
            joined_at_ms: now_ms,
            active: true,
            version: 1,
          })
        }
      }
      let next = marketplace_create_channel(
        state,
        principal,
        {
          channel_id: draft.channel_id,
          tenant_id: principal.tenant_id,
          workspace_id: draft.workspace_id,
          building_listing_id: draft.building_listing_id,
          agent_listing_id: draft.agent_listing_id,
          owner_principal_id: principal.principal_id,
          title: draft.title,
          visibility: parse_channel_visibility(draft.visibility),
          sensitivity: draft.sensitivity,
          members,
          created_at_ms: now_ms,
          updated_at_ms: now_ms,
          version: 1,
        },
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "channel_id": draft.channel_id })
    }
    "send-message" => {
      let draft = parse_message_draft(payload)
      let audience = if draft.public_audience {
        PublicAudience
      } else if draft.audience_principal_ids.is_empty() {
        EntireChannel
      } else {
        NamedPrincipals(draft.audience_principal_ids)
      }
      let next = marketplace_send_message(
        state,
        principal,
        {
          message_id: draft.message_id,
          channel_id: draft.channel_id,
          sender_principal_id: principal.principal_id,
          body: draft.body,
          attachment_refs: draft.attachment_refs,
          mentions: draft.mentions,
          audience,
          reply_to_message_id: draft.reply_to_message_id,
          created_at_ms: now_ms,
          edited_at_ms: None,
          version: 1,
        },
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "message_id": draft.message_id })
    }
    "read-notification" => {
      let draft : NotificationReadDraft = @json.from_json(payload)
      let next = marketplace_mark_notification_read(
        state,
        principal,
        draft.notification_id,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "notification_id": draft.notification_id })
    }
    "subscribe" => {
      let draft : SubscriptionDraft = @json.from_json(payload)
      let next = marketplace_set_subscription(
        state,
        principal,
        {
          subscription_id: draft.subscription_id,
          principal_id: principal.principal_id,
          topic_kind: draft.topic_kind,
          topic_id: draft.topic_id,
          enabled: draft.enabled,
          created_at_ms: now_ms,
          version: 1,
        },
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "subscription_id": draft.subscription_id })
    }
    "share-grant" => {
      let draft = parse_share_grant_draft(payload)
      let next = marketplace_create_share_grant(
        state,
        principal,
        {
          grant_id: draft.grant_id,
          tenant_id: principal.tenant_id,
          resource_kind: draft.resource_kind,
          resource_id: draft.resource_id,
          grantor_principal_id: principal.principal_id,
          grantee_principal_id: draft.grantee_principal_id,
          permission: draft.permission,
          created_at_ms: now_ms,
          expires_at_ms: draft.expires_at_ms,
          revoked_at_ms: None,
          version: 1,
        },
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "grant_id": draft.grant_id })
    }
    "revoke-share-grant" => {
      let draft : ShareGrantRevokeDraft = @json.from_json(payload)
      let next = marketplace_revoke_share_grant(
        state,
        principal,
        draft.grant_id,
        now_ms~,
      )
      self.save_state(next)
      application_ok(operation, { "grant_id": draft.grant_id, "revoked": true })
    }
    "sponsor" => {
      let draft : SponsoredPlacementDraft = @json.from_json(payload)
      let next = marketplace_upsert_sponsored_placement(state, principal, {
        placement_id: draft.placement_id,
        sponsor_principal_id: principal.principal_id,
        listing_kind: parse_listing_kind(draft.listing_kind),
        listing_id: draft.listing_id,
        label: "Sponsored",
        why_shown: draft.why_shown,
        interest_tags: draft.interest_tags,
        starts_at_ms: draft.starts_at_ms,
        ends_at_ms: draft.ends_at_ms,
        active: draft.active,
        version: 1,
      })
      self.save_state(next)
      application_ok(operation, { "placement_id": draft.placement_id })
    }
    _ => fail("unknown marketplace operation")
  }
}

///| Reconcile a receipt already validated by the supervisor/MoonClaw bridge.

///| This package-local application entrypoint is intentionally absent from the

///|
/// public marketplace HTTP operation table.
pub async fn MarketplaceApplication::reconcile_runtime_handoff(
  self : MarketplaceApplication,
  draft : ActionRequestRuntimeDraft,
  now_ms~ : UInt64,
) -> Json {
  marketplace_store_mutex.acquire()
  defer marketplace_store_mutex.release()
  let state = self.load_state()
  let next = marketplace_reconcile_action_request_runtime(state, draft, now_ms~)
  self.save_state(next)
  application_ok("reconcile-action-runtime", {
    "handoff_id": draft.handoff_id,
    "runtime_status": draft.runtime_status,
  })
}
