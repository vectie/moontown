///|
test "building registry creates private building with book" {
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
  let change = miniapp_create_building(
    snapshot,
    context.viewer,
    {
      id: "new-agent-lab",
      kind: @miniapp_contracts.AgentLab,
      title: "New Agent Lab",
      summary: "Draft agent creation space.",
      workspace_id: "workspace-user-a",
      tags: ["agent", "draft"],
      capabilities: ["create-agent", "query"],
      primary_book_id: "book-new-agent-lab",
    },
    now_ms=300UL,
  )
  assert_true(change.ok)
  assert_true(miniapp_test_has_building(change.snapshot, "new-agent-lab"))
  assert_true(miniapp_test_has_book(change.snapshot, "book-new-agent-lab"))
  let projected = @miniapp_projection.miniapp_filter_snapshot_for_viewer(
    change.snapshot,
    context.viewer,
  )
  assert_true(miniapp_test_has_building(projected, "new-agent-lab"))
}

///|
test "building registry updates shares submits and publishes" {
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
  let updated = miniapp_update_building(
    snapshot,
    context.viewer,
    "private-lab",
    {
      title: Some("Agent Foundry"),
      summary: None,
      tags: None,
      capabilities: None,
    },
    now_ms=300UL,
  )
  assert_true(updated.ok)
  assert_eq(
    miniapp_test_building_title(updated.snapshot, "private-lab"),
    "Agent Foundry",
  )

  let shared = miniapp_share_building(
    updated.snapshot,
    context.viewer,
    "private-lab",
    [
      {
        subject_kind: "organization",
        subject_id: "org-a",
        role: @miniapp_contracts.EditorRole,
      },
    ],
    now_ms=400UL,
  )
  assert_true(shared.ok)
  assert_true(
    shared.snapshot.permissions.length() > updated.snapshot.permissions.length(),
  )
  assert_true(
    miniapp_test_building_visibility(shared.snapshot, "private-lab") ==
    @miniapp_contracts.SharedPrivate,
  )

  let submitted = miniapp_publish_building(
    shared.snapshot,
    context.viewer,
    "private-lab",
    SubmitForPublish,
    now_ms=500UL,
  )
  assert_true(submitted.ok)
  assert_true(
    miniapp_test_building_visibility(submitted.snapshot, "private-lab") ==
    @miniapp_contracts.SubmittedForPublish,
  )

  let approved = miniapp_publish_building(
    submitted.snapshot,
    context.viewer,
    "private-lab",
    ApprovePublish,
    now_ms=600UL,
  )
  assert_true(approved.ok)
  assert_true(
    miniapp_test_building_visibility(approved.snapshot, "private-lab") ==
    @miniapp_contracts.Published,
  )
}

///|
test "building placement is separate from building identity" {
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
  let before_count = snapshot.placements.length()
  let placed = miniapp_place_building(snapshot, context.viewer, {
    id: "placement-user-a-policy-copy",
    building_id: "policy-hall",
    layer_id: "layer-personal-user-a",
    x: 7,
    y: 9,
    region_id: "east-gate",
    pinned: false,
  })
  assert_true(placed.ok)
  assert_eq(placed.snapshot.buildings.length(), snapshot.buildings.length())
  assert_eq(placed.snapshot.placements.length(), before_count + 1)
  assert_true(
    miniapp_test_has_placement(placed.snapshot, "placement-user-a-policy-copy"),
  )

  let removed = miniapp_remove_placement(
    placed.snapshot,
    context.viewer,
    "placement-user-a-policy-copy",
  )
  assert_true(removed.ok)
  assert_eq(removed.snapshot.buildings.length(), snapshot.buildings.length())
  assert_eq(removed.snapshot.placements.length(), before_count)
}

///|
test "building search filters visible results by tag capability owner and layer" {
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
  let tag_results = miniapp_search_buildings_with_filter(
    snapshot,
    context.viewer,
    {
      query: "",
      tag: Some("team"),
      capability: None,
      owner_id: Some("org-a"),
      visibility: Some(@miniapp_contracts.SharedPrivate),
      layer_id: Some("layer-personal-user-a"),
    },
  )
  assert_eq(tag_results.length(), 1)
  assert_eq(tag_results[0].building.id, "team-studio")
  let hidden = miniapp_search_buildings_with_filter(snapshot, context.viewer, {
    query: "",
    tag: Some("hidden"),
    capability: None,
    owner_id: None,
    visibility: None,
    layer_id: None,
  })
  assert_eq(hidden.length(), 0)
}

///|
fn miniapp_test_has_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> Bool {
  for building in snapshot.buildings {
    if building.id == building_id {
      return true
    }
  }
  false
}

///|
fn miniapp_test_has_book(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  book_id : String,
) -> Bool {
  for book in snapshot.books {
    if book.id == book_id {
      return true
    }
  }
  false
}

///|
fn miniapp_test_has_placement(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  placement_id : String,
) -> Bool {
  for placement in snapshot.placements {
    if placement.id == placement_id {
      return true
    }
  }
  false
}

///|
fn miniapp_test_building_title(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> String {
  for building in snapshot.buildings {
    if building.id == building_id {
      return building.title
    }
  }
  ""
}

///|
fn miniapp_test_building_visibility(
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
