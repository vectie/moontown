///|
test "dev login creates isolated sessions for local users" {
  let state = miniapp_identity_fixture_state()
  let (state_a, login_a) = miniapp_dev_login(state, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let (state_b, login_b) = miniapp_dev_login(state_a, {
    login_id: "user-b",
    now_ms: 200UL,
    ttl_ms: 1000UL,
  }).unwrap()
  assert_eq(login_a.user.id, "user-a")
  assert_eq(login_b.user.id, "user-b")
  assert_true(login_a.session.id != login_b.session.id)
  assert_eq(state_b.sessions.length(), 2)
  assert_true(
    miniapp_session_context(state_b, login_a.session.id, now_ms=500UL)
    is Some(_),
  )
  assert_true(
    miniapp_session_context(state_b, login_a.session.id, now_ms=2000UL) is None,
  )
}

///|
test "identity context carries organization workspace and roles" {
  let state = miniapp_identity_fixture_state()
  let (next, login) = miniapp_dev_login(state, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let context = miniapp_session_context(next, login.session.id, now_ms=200UL).unwrap()
  assert_eq(context.user.id, "user-a")
  assert_eq(context.organizations.length(), 1)
  assert_eq(context.organizations[0].id, "org-a")
  assert_eq(context.workspaces.length(), 2)
  assert_true(context.viewer.organization_ids.contains("org-a"))
  assert_true(context.viewer.workspace_ids.contains("workspace-user-a"))
  assert_true(context.viewer.workspace_ids.contains("workspace-org-a"))
  assert_true(context.viewer.roles.contains(@miniapp_contracts.OwnerRole))
  assert_true(context.viewer.roles.contains(@miniapp_contracts.PublisherRole))
}

///|
test "session snapshot applies viewer projection" {
  let identity = miniapp_identity_fixture_state()
  let source = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let (state_a, login_a) = miniapp_dev_login(identity, {
    login_id: "user-a",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let projected_a = miniapp_snapshot_for_session(
    state_a,
    source,
    login_a.session.id,
    now_ms=200UL,
  ).unwrap()
  assert_true(miniapp_identity_test_has_building(projected_a, "private-lab"))
  assert_true(miniapp_identity_test_has_building(projected_a, "team-studio"))
  assert_true(
    !miniapp_identity_test_has_building(projected_a, "other-private-lab"),
  )

  let (state_b, login_b) = miniapp_dev_login(state_a, {
    login_id: "user-b",
    now_ms: 300UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let projected_b = miniapp_snapshot_for_session(
    state_b,
    source,
    login_b.session.id,
    now_ms=400UL,
  ).unwrap()
  assert_true(!miniapp_identity_test_has_building(projected_b, "private-lab"))
  assert_true(!miniapp_identity_test_has_building(projected_b, "team-studio"))
  assert_true(
    miniapp_identity_test_has_building(projected_b, "other-private-lab"),
  )
  assert_true(miniapp_identity_test_has_building(projected_b, "policy-hall"))
}

///|
test "session search never returns invisible private buildings" {
  let identity = miniapp_identity_fixture_state()
  let source = @miniapp_projection.miniapp_projection_fixture_mixed_snapshot()
  let (state, login) = miniapp_dev_login(identity, {
    login_id: "user-b",
    now_ms: 100UL,
    ttl_ms: 1000UL,
  }).unwrap()
  let private_results = miniapp_search_for_session(
    state,
    source,
    login.session.id,
    now_ms=200UL,
    "private",
  )
  assert_eq(private_results.length(), 1)
  assert_eq(private_results[0].building.id, "other-private-lab")
}

///|
fn miniapp_identity_test_has_building(
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
