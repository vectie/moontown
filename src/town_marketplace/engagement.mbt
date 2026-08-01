///|
pub fn marketplace_set_subscription(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  subscription : Subscription,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if !valid_symbolic_id(subscription.subscription_id) ||
    subscription.principal_id != principal.principal_id ||
    !(subscription.topic_kind == "listing" ||
    subscription.topic_kind == "publisher" ||
    subscription.topic_kind == "tag" ||
    subscription.topic_kind == "town") ||
    !valid_symbolic_id(subscription.topic_id) {
    fail("invalid subscription")
  }
  let mut next_version = 1
  for current in state.subscriptions {
    if current.subscription_id == subscription.subscription_id {
      if current.principal_id != principal.principal_id {
        fail("subscription_id belongs to another principal")
      }
      next_version = current.version + 1
    }
  }
  let subscriptions = state.subscriptions.filter(current => {
    current.subscription_id != subscription.subscription_id
  })
  subscriptions.push({
    ..subscription,
    created_at_ms: now_ms,
    version: next_version,
  })
  { ..state, subscriptions, version: state.version + 1 }
}

///|
fn subscription_matches_card(subscription : Subscription, card : Json) -> Bool {
  if !subscription.enabled {
    return false
  }
  match subscription.topic_kind {
    "listing" => json_card_string(card, "listing_id") == subscription.topic_id
    "publisher" =>
      json_card_string(card, "publisher_id") == subscription.topic_id
    "tag" => json_card_strings(card, "tags").contains(subscription.topic_id)
    "town" => subscription.topic_id == "important-signals"
    _ => false
  }
}

///|
pub fn marketplace_emit_publication_notifications(
  state : MarketplaceState,
  kind : ListingKind,
  listing_id : String,
  now_ms~ : UInt64,
) -> MarketplaceState {
  let card = match public_listing_by_ref(state, kind, listing_id) {
    Some(value) => value
    None => return state
  }
  let notifications = state.notifications.copy()
  for subscription in state.subscriptions {
    if subscription_matches_card(subscription, card) {
      notifications.push({
        notification_id: "publication:\{listing_id}:\{subscription.principal_id}:\{state.version}",
        principal_id: subscription.principal_id,
        kind: "publication",
        title: "A followed listing was published",
        summary: json_card_string(card, "title"),
        object_kind: listing_kind_name(kind),
        object_id: listing_id,
        created_at_ms: now_ms,
        read_at_ms: None,
        version: 1,
      })
    }
  }
  { ..state, notifications, version: state.version + 1 }
}

///|
pub fn marketplace_notifications_for(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
) -> Json {
  let notifications : Array[Json] = []
  let mut unread = 0
  for notification in state.notifications {
    if notification.principal_id == principal.principal_id {
      if notification.read_at_ms is None {
        unread += 1
      }
      notifications.push({
        "notification_id": notification.notification_id,
        "kind": notification.kind,
        "title": notification.title,
        "summary": notification.summary,
        "object_kind": notification.object_kind,
        "object_id": notification.object_id,
        "created_at_ms": notification.created_at_ms.to_string(),
        "read_at_ms": match notification.read_at_ms {
          Some(value) => value.to_string().to_json()
          None => Json::null()
        },
      })
    }
  }
  {
    "contract_id": "moontown.notifications.v1",
    "notifications": notifications.to_json(),
    "unread_count": unread,
  }
}

///|
pub fn marketplace_mark_notification_read(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  notification_id : String,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let notifications : Array[TownNotification] = []
  let mut found = false
  for notification in state.notifications {
    if notification.notification_id == notification_id &&
      notification.principal_id == principal.principal_id {
      found = true
      notifications.push({
        ..notification,
        read_at_ms: Some(now_ms),
        version: notification.version + 1,
      })
    } else {
      notifications.push(notification)
    }
  }
  if !found {
    fail("notification not found for session principal")
  }
  { ..state, notifications, version: state.version + 1 }
}

///|
pub fn marketplace_upsert_sponsored_placement(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  placement : SponsoredPlacement,
) -> MarketplaceState raise {
  let listing = public_listing_by_ref(
    state,
    placement.listing_kind,
    placement.listing_id,
  ).unwrap_or_else(() => fail("sponsored listing must already be published"))
  let why_shown = validate_public_text(
    "sponsored placement explanation",
    placement.why_shown,
    240,
  )
  if !principal_has_role(principal, "advertiser") ||
    placement.sponsor_principal_id != principal.principal_id ||
    json_card_string(listing, "publisher_id") != principal.principal_id ||
    !valid_symbolic_id(placement.placement_id) ||
    placement.starts_at_ms >= placement.ends_at_ms ||
    placement.label != "Sponsored" {
    fail("invalid or unauthorized sponsored placement")
  }
  let mut next_version = 1
  for current in state.sponsored_placements {
    if current.placement_id == placement.placement_id {
      if current.sponsor_principal_id != principal.principal_id {
        fail("placement_id belongs to another sponsor")
      }
      next_version = current.version + 1
    }
  }
  let placements = state.sponsored_placements.filter(current => {
    current.placement_id != placement.placement_id
  })
  placements.push({
    ..placement,
    why_shown,
    interest_tags: normalized_terms(placement.interest_tags),
    version: next_version,
  })
  { ..state, sponsored_placements: placements, version: state.version + 1 }
}

///|
pub fn marketplace_request_listing_action(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  kind : ListingKind,
  listing_id : String,
  action_id : String,
  message : String,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let card = public_listing_by_ref(state, kind, listing_id).unwrap_or_else(() => {
    fail("published listing not found")
  })
  if !json_card_strings(card, "action_ids").contains(action_id) {
    fail("listing does not offer this action")
  }
  if action_id == "follow" {
    return marketplace_set_subscription(
      state,
      principal,
      {
        subscription_id: "follow:\{principal.principal_id}:\{listing_id}",
        principal_id: principal.principal_id,
        topic_kind: "listing",
        topic_id: listing_id,
        enabled: true,
        created_at_ms: now_ms,
        version: 1,
      },
      now_ms~,
    )
  }
  let publisher_id = json_card_string(card, "publisher_id")
  if publisher_id == principal.principal_id {
    fail("publisher cannot request an action from their own listing")
  }
  let summary = validate_public_text(
    "listing action message",
    if message.trim().is_empty() {
      "Please review my \"\{action_id}\" request."
    } else {
      message
    },
    1000,
  )
  let execution_request = marketplace_action_requires_publisher_decision(
    action_id,
  )
  let request_id = "action:\{listing_id}:\{principal.principal_id}:\{state.version}"
  let action_requests = if execution_request {
    state.action_requests +
    [
      {
        request_id,
        listing_kind: kind,
        listing_id,
        action_id,
        requester_principal_id: principal.principal_id,
        publisher_principal_id: publisher_id,
        request_message: summary,
        state: ActionRequested,
        expected_version: 1,
        decision_summary: "",
        instruction: "",
        execution_bounds: None,
        execution_handoff_id: None,
        worker_run_id: None,
        runtime_status: "not_started",
        result_summary: "",
        result_evidence_refs: [],
        created_at_ms: now_ms,
        decided_at_ms: None,
        updated_at_ms: now_ms,
        version: 1,
      },
    ]
  } else {
    state.action_requests
  }
  let notification : TownNotification = {
    notification_id: "listing-action:\{listing_id}:\{principal.principal_id}:\{state.version}",
    principal_id: publisher_id,
    kind: "listing_action",
    title: "New \{action_id} request",
    summary,
    object_kind: if execution_request {
      "marketplace_action_request"
    } else {
      listing_kind_name(kind)
    },
    object_id: if execution_request {
      request_id
    } else {
      listing_id
    },
    created_at_ms: now_ms,
    read_at_ms: None,
    version: 1,
  }
  {
    ..state,
    action_requests,
    notifications: state.notifications + [notification],
    version: state.version + 1,
  }
}
