///|
fn test_principal(
  principal_id : String,
  roles : Array[String],
  interests? : Array[String] = [],
) -> MarketplacePrincipal {
  {
    principal_id,
    tenant_id: "town-a",
    display_name: principal_id,
    workspace_ids: ["workspace-a"],
    roles,
    interest_tags: interests,
    active: true,
    version: 1,
  }
}

///|
fn test_state_with_sessions() -> (
  MarketplaceState,
  MarketplacePrincipal,
  MarketplacePrincipal,
  MarketplacePrincipal,
) raise {
  let owner = test_principal("publisher-a", ["publisher", "advertiser"], interests=[
    "robotics",
  ])
  let reviewer = test_principal("reviewer-a", ["publisher", "moderator"])
  let reader = test_principal("reader-a", [], interests=["robotics"])
  let state0 = empty_marketplace_state()
  let state1 = marketplace_register_session(
    state0, owner, "session-owner", "opaque-owner-token", 10000UL,
  )
  let state2 = marketplace_register_session(
    state1, reviewer, "session-reviewer", "opaque-reviewer-token", 10000UL,
  )
  let state3 = marketplace_register_session(
    state2, reader, "session-reader", "opaque-reader-token", 10000UL,
  )
  (state3, owner, reviewer, reader)
}

///|
fn test_agent_draft() -> AgentListingDraft {
  {
    listing_id: "agent.robot-guide",
    title: "Robot Guide",
    summary: "A governed agent that helps teams understand robotics projects.",
    image_ref: "asset:robot-guide-avatar",
    capabilities: ["robotics", "research"],
    tags: ["robotics", "education"],
    action_ids: ["follow", "message", "try"],
    required_permissions: ["read:published-books"],
    pricing_summary: "Free preview; usage terms shown before install",
    authority_ceiling: "advice-only",
    license_class: "publisher-defined",
    rights_summary: "Publisher owns or licenses all public card material.",
    version_label: "1.0.0",
  }
}

///|
fn test_published_state() -> (
  MarketplaceState,
  MarketplacePrincipal,
  MarketplacePrincipal,
  MarketplacePrincipal,
) raise {
  let (state, owner, reviewer, reader) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let submitted = marketplace_transition_listing(
    drafted,
    owner,
    AgentListing,
    "agent.robot-guide",
    PublicationSubmitted,
    review_summary="ready for review",
    now_ms=110UL,
  )
  let published = marketplace_transition_listing(
    submitted,
    reviewer,
    AgentListing,
    "agent.robot-guide",
    PublicationPublished,
    review_summary="rights and public projection reviewed",
    now_ms=120UL,
  )
  (published, owner, reviewer, reader)
}

///|
test "session token resolves principal and expires without caller identity" {
  let (state, owner, _, reader) = test_state_with_sessions()
  assert_eq(
    marketplace_principal_for_session(state, "opaque-owner-token", now_ms=100UL).unwrap().principal_id,
    owner.principal_id,
  )
  assert_eq(
    marketplace_principal_for_session(
      state,
      "opaque-reader-token",
      now_ms=100UL,
    ).unwrap().principal_id,
    reader.principal_id,
  )
  assert_true(
    marketplace_principal_for_session(
      state,
      "opaque-owner-token",
      now_ms=11000UL,
    )
    is None,
  )
  assert_true(
    marketplace_principal_for_session(
      state,
      "forged-principal-id",
      now_ms=100UL,
    )
    is None,
  )
}

///|
test "publisher cannot self-publish and distinct reviewer can" {
  let (state, owner, reviewer, _) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let submitted = marketplace_transition_listing(
    drafted,
    owner,
    AgentListing,
    "agent.robot-guide",
    PublicationSubmitted,
    review_summary="submitted",
    now_ms=110UL,
  )
  try
    marketplace_transition_listing(
      submitted,
      owner,
      AgentListing,
      "agent.robot-guide",
      PublicationPublished,
      review_summary="self review",
      now_ms=120UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("self-publication must be denied")
  }
  let published = marketplace_transition_listing(
    submitted,
    reviewer,
    AgentListing,
    "agent.robot-guide",
    PublicationPublished,
    review_summary="independent review",
    now_ms=121UL,
  )
  assert_true(
    published.agent_listings[0].lifecycle.state == PublicationPublished,
  )
}

///|
test "publication requires a substantive review receipt" {
  let (state, owner, reviewer, _) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let submitted = marketplace_transition_listing(
    drafted,
    owner,
    AgentListing,
    "agent.robot-guide",
    PublicationSubmitted,
    review_summary="submitted",
    now_ms=110UL,
  )
  try
    marketplace_transition_listing(
      submitted,
      reviewer,
      AgentListing,
      "agent.robot-guide",
      PublicationPublished,
      review_summary="   ",
      now_ms=120UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("publication without a review receipt must be denied")
  }
}

///|
test "reviewer authority cannot rewrite another publisher's draft lifecycle" {
  let (state, owner, reviewer, _) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  try
    marketplace_transition_listing(
      drafted,
      reviewer,
      AgentListing,
      "agent.robot-guide",
      PublicationSubmitted,
      review_summary="reviewer tried to submit",
      now_ms=110UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("only the owner may submit its draft")
  }
}

///|
test "public listing IDs match the shared MoonFind grammar" {
  let (state, owner, reviewer, _) = test_state_with_sessions()
  for listing_id in ["agent.bad.", ":agent-bad", "agent-bad:"] {
    let drafted = marketplace_upsert_agent_draft(
      state,
      owner,
      { ..test_agent_draft(), listing_id, },
      now_ms=100UL,
    )
    let submitted = marketplace_transition_listing(
      drafted,
      owner,
      AgentListing,
      listing_id,
      PublicationSubmitted,
      review_summary="submitted",
      now_ms=110UL,
    )
    try
      marketplace_transition_listing(
        submitted,
        reviewer,
        AgentListing,
        listing_id,
        PublicationPublished,
        review_summary="independent review",
        now_ms=120UL,
      )
    catch {
      _ => ()
    } noraise {
      _ => fail("schema-invalid public IDs must be denied")
    }
  }
}

///|
test "public listing admission rejects credential and local-path material" {
  let (state, owner, _, _) = test_state_with_sessions()
  let rejected_credentials = {
    ..test_agent_draft(),
    summary: "Authorization: Bearer private-token",
  }
  try
    marketplace_upsert_agent_draft(
      state,
      owner,
      rejected_credentials,
      now_ms=100UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("credential-like public text must be rejected")
  }
  let unsafe_image = {
    ..test_agent_draft(),
    image_ref: "FILE:///Users/person/private-avatar.png",
  }
  try
    marketplace_upsert_agent_draft(state, owner, unsafe_image, now_ms=101UL)
  catch {
    _ => ()
  } noraise {
    _ => fail("local image path must be rejected")
  }
}

///|
test "public listing actions use the governed shared vocabulary" {
  let (state, owner, _, _) = test_state_with_sessions()
  try
    marketplace_upsert_agent_draft(
      state,
      owner,
      { ..test_agent_draft(), action_ids: ["follow", "run-shell"] },
      now_ms=100UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("arbitrary public action identifiers must be denied")
  }
}

///|
test "listing IDs are globally unique across agent and building kinds" {
  let (state, owner, _, _) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  try
    marketplace_upsert_building_draft(
      drafted,
      owner,
      {
        listing_id: "agent.robot-guide",
        title: "Conflicting building",
        summary: "This draft deliberately reuses an agent listing identifier.",
        image_ref: "asset:building",
        capabilities: ["research"],
        tags: ["robotics"],
        action_ids: ["follow"],
        pricing_summary: "Free",
        license_class: "publisher-defined",
        rights_summary: "Publisher-owned public material.",
        version_label: "1.0.0",
      },
      now_ms=101UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("cross-kind duplicate listing IDs must be denied")
  }
}

///|
test "MoonFind export has exactly the canonical 15 safe fields" {
  let (state, _, _, _) = test_published_state()
  let exported = public_listing_index_export(state)
  guard exported is Object(root) &&
    root.get("listings") is Some(Array([Object(card)])) else {
    fail("expected one canonical listing")
  }
  assert_eq(card.length(), 15)
  for
    key in [
      "contract_id", "listing_id", "listing_kind", "publisher_id", "title", "summary",
      "capabilities", "tags", "action_ids", "publication_state", "published_at",
      "version", "content_digest", "license_class", "rights_summary",
    ] {
    assert_true(card.contains(key))
  }
  assert_true(card.get("version") is Some(Number(_, ..)))
  let encoded = Json::object(card).stringify()
  for
    forbidden in [
      "raw_memory", "credentials", "/Users/", "authority_envelope", "consent", "private_evidence",
      "pricing_summary",
    ] {
    assert_false(encoded.contains(forbidden))
  }
}

///|
test "draft records cannot be projected through a public card API" {
  let (state, owner, _, _) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  assert_true(public_agent_listing_card(drafted.agent_listings[0]) is Null)
  assert_eq(
    public_listing_index_export(drafted).stringify(),
    (
      #|{"contract_id":"moontown.public-listing-export.v1","listings":[]}
    ),
  )
}

///|
test "organic search and recommendation never blend sponsored placement" {
  let (state, owner, _, reader) = test_published_state()
  let sponsored = marketplace_upsert_sponsored_placement(state, owner, {
    placement_id: "sponsor.robot-guide",
    sponsor_principal_id: owner.principal_id,
    listing_kind: AgentListing,
    listing_id: "agent.robot-guide",
    label: "Sponsored",
    why_shown: "You opted into robotics promotions",
    interest_tags: ["robotics"],
    starts_at_ms: 100UL,
    ends_at_ms: 1000UL,
    active: true,
    version: 1,
  })
  let organic = marketplace_organic_search(sponsored, "robotics")
  assert_eq(organic.length(), 1)
  assert_false(organic[0].stringify().contains("Sponsored"))
  let recommendations = marketplace_recommendations(sponsored, reader)
  assert_eq(recommendations.length(), 1)
  assert_true(recommendations[0].reason.contains("robotics"))
  let feed = marketplace_discovery_feed(sponsored, reader, "robotics", 200UL)
  assert_true(feed.stringify().contains("sponsored_placements"))
  assert_true(feed.stringify().contains("organic_and_sponsored_separated"))
}

///|
test "sponsored placement requires publisher consent and safe copy" {
  let (state, owner, _, reader) = test_published_state()
  let unauthorized = {
    placement_id: "sponsor.unapproved",
    sponsor_principal_id: reader.principal_id,
    listing_kind: AgentListing,
    listing_id: "agent.robot-guide",
    label: "Sponsored",
    why_shown: "Robotics promotion",
    interest_tags: ["robotics"],
    starts_at_ms: 100UL,
    ends_at_ms: 1000UL,
    active: true,
    version: 1,
  }
  let advertiser = { ..reader, roles: ["advertiser"] }
  try
    marketplace_upsert_sponsored_placement(state, advertiser, unauthorized)
  catch {
    _ => ()
  } noraise {
    _ => fail("an advertiser cannot promote another publisher without consent")
  }
  try
    marketplace_upsert_sponsored_placement(state, owner, {
      ..unauthorized,
      placement_id: "sponsor.unsafe",
      sponsor_principal_id: owner.principal_id,
      why_shown: "Authorization: Bearer private-token",
    })
  catch {
    _ => ()
  } noraise {
    _ => fail("sponsored copy must pass public-text admission")
  }
}

///|
test "unsupported channel subscription fails closed" {
  let (state, _, _, reader) = test_state_with_sessions()
  try
    marketplace_set_subscription(
      state,
      reader,
      {
        subscription_id: "subscription.channel-a",
        principal_id: reader.principal_id,
        topic_kind: "channel",
        topic_id: "channel-a",
        enabled: true,
        created_at_ms: 0UL,
        version: 1,
      },
      now_ms=100UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("unsupported notification topics must fail closed")
  }
}

///|
test "subscription identifiers cannot overwrite another principal" {
  let (state, owner, _, reader) = test_state_with_sessions()
  let reader_state = marketplace_set_subscription(
    state,
    reader,
    {
      subscription_id: "subscription.shared-id",
      principal_id: reader.principal_id,
      topic_kind: "town",
      topic_id: "important-signals",
      enabled: true,
      created_at_ms: 0UL,
      version: 1,
    },
    now_ms=100UL,
  )
  try
    marketplace_set_subscription(
      reader_state,
      owner,
      {
        subscription_id: "subscription.shared-id",
        principal_id: owner.principal_id,
        topic_kind: "town",
        topic_id: "important-signals",
        enabled: true,
        created_at_ms: 0UL,
        version: 1,
      },
      now_ms=101UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("one principal must not replace another principal's subscription")
  }
}

///|
fn test_channel(
  owner : MarketplacePrincipal,
  reader : MarketplacePrincipal,
  channel_id : String,
) -> Channel {
  {
    channel_id,
    tenant_id: owner.tenant_id,
    workspace_id: Some("workspace-a"),
    building_listing_id: None,
    agent_listing_id: None,
    owner_principal_id: owner.principal_id,
    title: "Project room \{channel_id}",
    visibility: PrivateChannel,
    sensitivity: "confidential",
    members: [
      {
        principal_id: owner.principal_id,
        role: ChannelOwner,
        joined_at_ms: 100UL,
        active: true,
        version: 1,
      },
      {
        principal_id: reader.principal_id,
        role: ChannelParticipant,
        joined_at_ms: 100UL,
        active: true,
        version: 1,
      },
    ],
    created_at_ms: 100UL,
    updated_at_ms: 100UL,
    version: 1,
  }
}

///|
test "channel ACL protects messages and notifications never copy body" {
  let (state, owner, reviewer, reader) = test_state_with_sessions()
  let with_channel = marketplace_create_channel(
    state,
    owner,
    test_channel(owner, reader, "channel-a"),
    now_ms=100UL,
  )
  assert_false(marketplace_can_read_channel(with_channel.channels[0], reviewer))
  let secret_body = "The confidential launch phrase is lunar-orchid."
  let messaged = marketplace_send_message(
    with_channel,
    owner,
    {
      message_id: "message-a",
      channel_id: "channel-a",
      sender_principal_id: owner.principal_id,
      body: secret_body,
      attachment_refs: [],
      mentions: [reader.principal_id],
      audience: NamedPrincipals([reader.principal_id]),
      reply_to_message_id: None,
      created_at_ms: 200UL,
      edited_at_ms: None,
      version: 1,
    },
    now_ms=200UL,
  )
  assert_eq(
    marketplace_visible_messages(messaged, reader, "channel-a").length(),
    1,
  )
  let inbox = marketplace_notifications_for(messaged, reader).stringify()
  assert_true(inbox.contains("mentioned you"))
  assert_false(inbox.contains("lunar-orchid"))
}

///|
test "agent channel binds a real published agent listing" {
  let (state, owner, _, reader) = test_published_state()
  let agent_room = {
    ..test_channel(owner, reader, "agent-room"),
    visibility: AgentChannel,
    agent_listing_id: Some("agent.robot-guide"),
  }
  let next = marketplace_create_channel(state, owner, agent_room, now_ms=200UL)
  let projection = marketplace_visible_channels(next, reader)
    .to_json()
    .stringify()
  assert_true(projection.contains("\"visibility\":\"agent\""))
  assert_true(projection.contains("agent.robot-guide"))
}

///|
test "untyped private channels cannot smuggle a listing binding" {
  let (state, owner, _, reader) = test_published_state()
  try
    marketplace_create_channel(
      state,
      owner,
      {
        ..test_channel(owner, reader, "misbound-room"),
        building_listing_id: Some("agent.robot-guide"),
      },
      now_ms=200UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("non-building channels must reject building bindings")
  }
}

///|
test "reply target must exist in the same channel" {
  let (state, owner, _, reader) = test_state_with_sessions()
  let state1 = marketplace_create_channel(
    state,
    owner,
    test_channel(owner, reader, "channel-a"),
    now_ms=100UL,
  )
  let state2 = marketplace_create_channel(
    state1,
    owner,
    test_channel(owner, reader, "channel-b"),
    now_ms=101UL,
  )
  let state3 = marketplace_send_message(
    state2,
    owner,
    {
      message_id: "message-a",
      channel_id: "channel-a",
      sender_principal_id: owner.principal_id,
      body: "First channel message",
      attachment_refs: [],
      mentions: [],
      audience: EntireChannel,
      reply_to_message_id: None,
      created_at_ms: 110UL,
      edited_at_ms: None,
      version: 1,
    },
    now_ms=110UL,
  )
  try
    marketplace_send_message(
      state3,
      owner,
      {
        message_id: "message-b",
        channel_id: "channel-b",
        sender_principal_id: owner.principal_id,
        body: "Cross-channel reply attempt",
        attachment_refs: [],
        mentions: [],
        audience: EntireChannel,
        reply_to_message_id: Some("message-a"),
        created_at_ms: 120UL,
        edited_at_ms: None,
        version: 1,
      },
      now_ms=120UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("cross-channel reply must be denied")
  }
}

///|
test "follow action is idempotent and share preview is explicitly sanitized" {
  let (state, owner, _, reader) = test_published_state()
  let followed = marketplace_request_listing_action(
    state,
    reader,
    AgentListing,
    "agent.robot-guide",
    "follow",
    "Follow updates",
    now_ms=200UL,
  )
  let followed_again = marketplace_request_listing_action(
    followed,
    reader,
    AgentListing,
    "agent.robot-guide",
    "follow",
    "Follow updates",
    now_ms=201UL,
  )
  assert_eq(followed_again.subscriptions.length(), 1)
  let preview = marketplace_share_preview(
    followed_again,
    owner,
    "agent",
    "agent.robot-guide",
    reader.principal_id,
  ).stringify()
  assert_true(preview.contains("excluded_fields"))
  assert_true(preview.contains("moonsuite.public-listing.v1"))
  assert_false(preview.contains("opaque-owner-token"))
  try
    marketplace_create_share_grant(
      followed_again,
      owner,
      {
        grant_id: "grant-expired",
        tenant_id: owner.tenant_id,
        resource_kind: "agent",
        resource_id: "agent.robot-guide",
        grantor_principal_id: owner.principal_id,
        grantee_principal_id: reader.principal_id,
        permission: "view",
        created_at_ms: 0UL,
        expires_at_ms: Some(199UL),
        revoked_at_ms: None,
        version: 1,
      },
      now_ms=200UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("expired share grant must be denied")
  }
}

///|
test "owner can preview a sanitized private draft before granting access" {
  let (state, owner, _, reader) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let preview = marketplace_share_preview(
    drafted,
    owner,
    "agent",
    "agent.robot-guide",
    reader.principal_id,
  ).stringify()
  assert_true(preview.contains("moontown.private-listing-share-preview.v1"))
  assert_true(preview.contains("PublicationDraft") || preview.contains("draft"))
  assert_false(preview.contains("opaque-owner-token"))
  assert_false(preview.contains("workspace_ids"))
  let unbound_preview = marketplace_share_preview(
    drafted, owner, "agent", "agent.robot-guide", "",
  ).stringify()
  assert_true(unbound_preview.contains("\"grantee_principal_id\":null"))
}

///|
test "active grants expose only sanitized private listings and revocation closes access" {
  let (state, owner, reviewer, reader) = test_state_with_sessions()
  let drafted = marketplace_upsert_agent_draft(
    state,
    owner,
    test_agent_draft(),
    now_ms=100UL,
  )
  let granted = marketplace_create_share_grant(
    drafted,
    owner,
    {
      grant_id: "grant-agent-reader",
      tenant_id: owner.tenant_id,
      resource_kind: "agent",
      resource_id: "agent.robot-guide",
      grantor_principal_id: owner.principal_id,
      grantee_principal_id: reader.principal_id,
      permission: "view",
      created_at_ms: 0UL,
      expires_at_ms: Some(1000UL),
      revoked_at_ms: None,
      version: 1,
    },
    now_ms=200UL,
  )
  assert_true(granted.agent_listings[0].lifecycle.state == PublicationShared)
  let visible = marketplace_shared_listing_cards(granted, reader, now_ms=300UL)
  assert_eq(visible.length(), 1)
  let wire = visible.to_json().stringify()
  assert_true(wire.contains("moontown.private-listing-share-preview.v1"))
  assert_false(wire.contains("opaque-owner-token"))
  assert_eq(
    marketplace_shared_listing_cards(granted, reader, now_ms=1000UL).length(),
    0,
  )
  try
    marketplace_revoke_share_grant(
      granted,
      reviewer,
      "grant-agent-reader",
      now_ms=350UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("only the grantor may revoke a share grant")
  }
  let revoked = marketplace_revoke_share_grant(
    granted,
    owner,
    "grant-agent-reader",
    now_ms=400UL,
  )
  assert_eq(
    marketplace_shared_listing_cards(revoked, reader, now_ms=401UL).length(),
    0,
  )
  assert_true(revoked.agent_listings[0].lifecycle.state == PublicationDraft)
  assert_true(revoked.share_grants[0].revoked_at_ms == Some(400UL))
}

///|
test "workspace and listing channels require real membership and binding authority" {
  let (state, owner, _, reader) = test_published_state()
  try
    marketplace_create_channel(
      state,
      owner,
      {
        ..test_channel(owner, reader, "workspace-missing"),
        visibility: WorkspaceChannel,
        workspace_id: None,
      },
      now_ms=200UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("workspace channels require a workspace binding")
  }
  let outsider = {
    ..reader,
    principal_id: "reader-b",
    workspace_ids: ["workspace-b"],
  }
  let with_outsider = { ..state, principals: state.principals + [outsider] }
  try
    marketplace_create_channel(
      with_outsider,
      owner,
      {
        ..test_channel(owner, outsider, "workspace-outsider"),
        visibility: WorkspaceChannel,
      },
      now_ms=201UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("workspace channels may contain only workspace members")
  }
  let reader_room = {
    ..test_channel(reader, owner, "reader-agent-room"),
    visibility: AgentChannel,
    agent_listing_id: Some("agent.robot-guide"),
  }
  try
    marketplace_create_channel(state, reader, reader_room, now_ms=202UL)
  catch {
    _ => ()
  } noraise {
    _ => fail("a reader cannot bind somebody else's listing without a grant")
  }
  let granted = marketplace_create_share_grant(
    state,
    owner,
    {
      grant_id: "grant-agent-messaging",
      tenant_id: owner.tenant_id,
      resource_kind: "agent",
      resource_id: "agent.robot-guide",
      grantor_principal_id: owner.principal_id,
      grantee_principal_id: reader.principal_id,
      permission: "message",
      created_at_ms: 0UL,
      expires_at_ms: None,
      revoked_at_ms: None,
      version: 1,
    },
    now_ms=203UL,
  )
  let next = marketplace_create_channel(
    granted,
    reader,
    reader_room,
    now_ms=204UL,
  )
  assert_eq(next.channels.length(), 1)
  assert_true(next.channels[0].agent_listing_id == Some("agent.robot-guide"))
}

///|
test "message attachments require ownership and recipient grants" {
  let (state, owner, _, reader) = test_state_with_sessions()
  let with_channel = marketplace_create_channel(
    state,
    owner,
    test_channel(owner, reader, "channel-attachments"),
    now_ms=100UL,
  )
  let artifact_ref = "artifact:publisher-a:accepted-brief"
  try
    marketplace_send_message(
      with_channel,
      owner,
      {
        message_id: "message-ungranted",
        channel_id: "channel-attachments",
        sender_principal_id: owner.principal_id,
        body: "Review the brief",
        attachment_refs: [artifact_ref],
        mentions: [],
        audience: EntireChannel,
        reply_to_message_id: None,
        created_at_ms: 0UL,
        edited_at_ms: None,
        version: 1,
      },
      now_ms=200UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("attachments must not leak to recipients without a grant")
  }
  let granted = marketplace_create_share_grant(
    with_channel,
    owner,
    {
      grant_id: "grant-artifact-reader",
      tenant_id: owner.tenant_id,
      resource_kind: "artifact",
      resource_id: artifact_ref,
      grantor_principal_id: owner.principal_id,
      grantee_principal_id: reader.principal_id,
      permission: "view",
      created_at_ms: 0UL,
      expires_at_ms: None,
      revoked_at_ms: None,
      version: 1,
    },
    now_ms=201UL,
  )
  let sent = marketplace_send_message(
    granted,
    owner,
    {
      message_id: "message-granted",
      channel_id: "channel-attachments",
      sender_principal_id: owner.principal_id,
      body: "Review the brief",
      attachment_refs: [artifact_ref],
      mentions: [],
      audience: EntireChannel,
      reply_to_message_id: None,
      created_at_ms: 0UL,
      edited_at_ms: None,
      version: 1,
    },
    now_ms=202UL,
  )
  assert_eq(sent.messages.length(), 1)
  try
    marketplace_send_message(
      sent,
      owner,
      {
        message_id: "message-forged-owner",
        channel_id: "channel-attachments",
        sender_principal_id: owner.principal_id,
        body: "Forged attachment",
        attachment_refs: ["artifact:reviewer-a:foreign"],
        mentions: [],
        audience: NamedPrincipals([reader.principal_id]),
        reply_to_message_id: None,
        created_at_ms: 0UL,
        edited_at_ms: None,
        version: 1,
      },
      now_ms=203UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("a sender cannot forge artifact ownership")
  }
  try
    marketplace_send_message(
      sent,
      owner,
      {
        message_id: "message-unknown-attachment",
        channel_id: "channel-attachments",
        sender_principal_id: owner.principal_id,
        body: "Unknown attachment",
        attachment_refs: ["blob:untyped-resource"],
        mentions: [],
        audience: NamedPrincipals([reader.principal_id]),
        reply_to_message_id: None,
        created_at_ms: 0UL,
        edited_at_ms: None,
        version: 1,
      },
      now_ms=204UL,
    )
  catch {
    _ => ()
  } noraise {
    _ => fail("unknown attachment reference types must fail closed")
  }
}

///|
test "wire intake accepts direct scalar null and missing option fields" {
  let channel = parse_channel_draft(
    @json.parse(
      (
        #|{"channel_id":"channel-a","title":"Room","visibility":"private","sensitivity":"confidential","workspace_id":"workspace-a","building_listing_id":null,"member_principal_ids":["reader-a"]}
      ),
    ),
  )
  assert_true(channel.workspace_id == Some("workspace-a"))
  assert_true(channel.building_listing_id is None)
  assert_true(channel.agent_listing_id is None)
  let message = parse_message_draft(
    @json.parse(
      (
        #|{"message_id":"message-a","channel_id":"channel-a","body":"Hello","reply_to_message_id":null}
      ),
    ),
  )
  assert_true(message.reply_to_message_id is None)
  assert_eq(message.mentions.length(), 0)
  let share = parse_share_grant_draft(
    @json.parse(
      (
        #|{"grant_id":"grant-a","resource_kind":"agent","resource_id":"agent.robot-guide","grantee_principal_id":"reader-a","permission":"view","expires_at_ms":null}
      ),
    ),
  )
  assert_true(share.expires_at_ms is None)
}

///|
async test "application persists drafts across restart" {
  let path = "/tmp/moontown-marketplace-wbtest/state.json"
  if @fs.exists(path) {
    @fs.remove(path)
  }
  let owner = test_principal("publisher-a", ["publisher"])
  let app = marketplace_application(
    path, owner, "session-bootstrap", "opaque-bootstrap-token",
  )
  ignore(
    app.execute(
      "opaque-bootstrap-token",
      "upsert-agent",
      test_agent_draft().to_json().stringify(),
      "",
      now_ms=100UL,
    ),
  )
  let restarted = marketplace_application(
    path, owner, "session-bootstrap", "opaque-bootstrap-token",
  )
  let response = restarted.execute(
    "opaque-bootstrap-token",
    "search",
    "",
    "robotics",
    now_ms=200UL,
  )
  assert_true(response.stringify().contains("result_count"))
  let stored = @fs.read_file(path).text()
  assert_true(stored.contains("agent.robot-guide"))
  assert_false(stored.contains("opaque-bootstrap-token"))
}
