///|
test "publishing validates metadata permissions summary assets and duplicates" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let valid = miniapp_validate_publication(snapshot, context.viewer, {
    building_id: "private-lab",
    public_summary: "A safe public agent lab preview for creating agents.",
    category_id: "agent_lab",
    asset_refs: ["agent-lab"],
  })
  assert_true(valid.ok)
  assert_eq(valid.issues.length(), 0)

  let invalid = miniapp_validate_publication(snapshot, context.viewer, {
    building_id: "private-lab",
    public_summary: "secret token=/Users/kq/.moontown/private",
    category_id: "policy_hall",
    asset_refs: ["unapproved-asset"],
  })
  assert_true(!invalid.ok)
  assert_true(invalid.issues.contains("category-does-not-match-building-kind"))
  assert_true(
    invalid.issues.contains("summary-contains-private-or-secret-material"),
  )
  assert_true(invalid.issues.contains("asset-not-allowed:unapproved-asset"))
}

///|
test "publishing submission approval and rejection preserve review reasons" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let request : MiniappPublicationRequest = {
    building_id: "private-lab",
    public_summary: "A safe public agent lab preview for creating agents.",
    category_id: "agent_lab",
    asset_refs: ["agent-lab"],
  }
  let snapshot = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let submitted = miniapp_submit_publication_request(
    snapshot,
    context.viewer,
    request,
    now_ms=300UL,
  )
  assert_true(submitted.ok)
  assert_true(
    miniapp_test_visibility(submitted.snapshot, "private-lab") ==
    @miniapp_contracts.SubmittedForPublish,
  )

  let approved = miniapp_review_publication_request(
    submitted.snapshot,
    context.viewer,
    request,
    ApprovePublication,
    now_ms=400UL,
  )
  assert_true(approved.ok)
  assert_true(
    miniapp_test_visibility(approved.snapshot, "private-lab") ==
    @miniapp_contracts.Published,
  )

  let submitted_again = miniapp_submit_publication_request(
    snapshot,
    context.viewer,
    request,
    now_ms=500UL,
  )
  let rejected = miniapp_review_publication_request(
    submitted_again.snapshot,
    context.viewer,
    request,
    RejectPublication("summary needs clearer ownership"),
    now_ms=600UL,
  )
  assert_true(rejected.ok)
  assert_true(
    miniapp_test_visibility(rejected.snapshot, "private-lab") ==
    @miniapp_contracts.SharedPrivate,
  )
  assert_true(
    miniapp_test_review_summary(rejected.snapshot, "private-lab").contains(
      "summary needs clearer ownership",
    ),
  )
}

///|
test "public discovery ranks official results and filters category capability owner freshness" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = miniapp_test_snapshot_with_user_published()
  let results = miniapp_public_discovery(snapshot, context.viewer, {
    query: "agent",
    tag: Some("agent"),
    category_id: Some("agent_lab"),
    owner_id: None,
    capability: Some("query"),
    min_updated_at_ms: Some(200UL),
  })
  assert_eq(results.length(), 2)
  assert_eq(results[0].building_id, "official-agent-lab")
  assert_eq(results[1].building_id, "published-agent-lab")
  assert_true(results[0].can_place)

  let owner_results = miniapp_public_discovery(snapshot, context.viewer, {
    query: "",
    tag: None,
    category_id: Some("agent_lab"),
    owner_id: Some("user-b"),
    capability: None,
    min_updated_at_ms: None,
  })
  assert_eq(owner_results.length(), 1)
  assert_eq(owner_results[0].owner_label, "user:user-b")
}

///|
test "public previews hide private drafts and moderation can hide published items" {
  let identity = @miniapp_identity.miniapp_identity_fixture_state()
  let (state, login) = @miniapp_identity.miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = @miniapp_identity.miniapp_session_context(
    state,
    login.session.id,
    now_ms=200UL,
  ).unwrap()
  let snapshot = miniapp_test_snapshot_with_user_published()
  assert_true(
    miniapp_public_building_preview(snapshot, context.viewer, "private-lab")
    is None,
  )
  let preview = miniapp_public_building_preview(
    snapshot,
    context.viewer,
    "published-agent-lab",
  ).unwrap()
  assert_eq(preview.category_id, "agent_lab")
  assert_true(preview.summary.contains("Published user agent lab"))

  let hidden = miniapp_review_publication_request(
    snapshot,
    context.viewer,
    {
      building_id: "published-agent-lab",
      public_summary: "Published user agent lab for public discovery.",
      category_id: "agent_lab",
      asset_refs: ["agent-lab"],
    },
    HidePublished("reported stale public content"),
    now_ms=900UL,
  )
  assert_true(hidden.ok)
  assert_true(
    miniapp_test_visibility(hidden.snapshot, "published-agent-lab") ==
    @miniapp_contracts.Archived,
  )
  assert_eq(
    miniapp_public_discovery(hidden.snapshot, context.viewer, {
      query: "agent",
      tag: None,
      category_id: None,
      owner_id: None,
      capability: None,
      min_updated_at_ms: None,
    }).length(),
    1,
  )
}

///|
fn miniapp_test_snapshot_with_user_published() -> @miniapp_contracts.MiniappTownSnapshot {
  let base = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let user_public = {
    ..@miniapp_contracts.miniapp_fixture_building(
      id="published-agent-lab",
      owner_id="user-b",
      owner_kind=@miniapp_contracts.UserOwner,
      visibility=@miniapp_contracts.Published,
      scope=@miniapp_contracts.TownPublicScope,
    ),
    kind: @miniapp_contracts.AgentLab,
    title: "Published Agent Lab",
    summary: "Published user agent lab for public discovery.",
    tags: ["agent", "public"],
    capabilities: ["query", "create-agent"],
    primary_book_id: "book-published-agent-lab",
    updated_at_ms: 700UL,
  }
  let official = {
    ..@miniapp_contracts.miniapp_fixture_building(
      id="official-agent-lab",
      owner_id="system",
      owner_kind=@miniapp_contracts.SystemOwner,
      visibility=@miniapp_contracts.Published,
      scope=@miniapp_contracts.SystemPublicScope,
    ),
    kind: @miniapp_contracts.AgentLab,
    title: "Official Agent Lab",
    summary: "Official agent lab for public discovery.",
    tags: ["agent", "official"],
    capabilities: ["query", "create-agent"],
    primary_book_id: "book-official-agent-lab",
    updated_at_ms: 500UL,
  }
  {
    ..base,
    buildings: base.buildings + [user_public, official],
    books: base.books +
    [
      {
        ..@miniapp_contracts.miniapp_fixture_book(id="book-published-agent-lab"),
        summary: "Accepted public agent patterns.",
        accepted_memory_count: 2,
      },
      {
        ..@miniapp_contracts.miniapp_fixture_book(id="book-official-agent-lab"),
        summary: "Official accepted public agent patterns.",
        accepted_memory_count: 6,
      },
    ],
  }
}

///|
fn miniapp_test_visibility(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> @miniapp_contracts.MiniappVisibilityState {
  for building in snapshot.buildings {
    if building.id == building_id {
      return building.visibility
    }
  }
  @miniapp_contracts.Archived
}

///|
fn miniapp_test_review_summary(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> String {
  for building in snapshot.buildings {
    if building.id == building_id {
      return building.publication.review_summary
    }
  }
  ""
}
