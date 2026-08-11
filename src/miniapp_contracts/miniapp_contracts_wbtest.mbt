///|
test "miniapp contract ids preserve product vocabulary" {
  assert_eq(miniapp_owner_kind_id(UserOwner), "user")
  assert_eq(miniapp_owner_kind_id(OrganizationOwner), "organization")
  assert_eq(miniapp_owner_kind_id(SystemOwner), "system")
  assert_eq(miniapp_visibility_state_id(PrivateDraft), "private_draft")
  assert_eq(miniapp_visibility_state_id(SharedPrivate), "shared_private")
  assert_eq(
    miniapp_visibility_state_id(SubmittedForPublish),
    "submitted_for_publish",
  )
  assert_eq(miniapp_visibility_state_id(Published), "published")
  assert_eq(miniapp_scope_id(TownPublicScope), "town_public")
  assert_eq(miniapp_permission_role_id(PublisherRole), "publisher")
  assert_eq(miniapp_run_status_id(RunWaitingReview), "waiting_review")
  assert_eq(miniapp_building_kind_id(PolicyHall), "policy_hall")
}

///|
test "miniapp endpoint catalog covers identity building search and runs" {
  let endpoints = miniapp_contract_endpoints()
  assert_true(endpoints.length() >= 20)
  assert_true(miniapp_endpoint_by_id("auth-wechat-login") is None)
  assert_true(miniapp_endpoint_by_id("auth-dev-login") is None)
  assert_eq(
    miniapp_endpoint_by_id("auth-logout").unwrap().path,
    "/miniapp/auth/logout",
  )
  assert_true(miniapp_endpoint_by_id("auth-logout").unwrap().auth_required)
  assert_true(miniapp_endpoint_by_id("account-billing-change").unwrap().writes)
  assert_eq(
    miniapp_endpoint_by_id("town-snapshot").unwrap().path,
    "/town/snapshot",
  )
  assert_eq(
    miniapp_endpoint_by_id("buildings-search").unwrap().http_method,
    "GET",
  )
  assert_true(miniapp_endpoint_by_id("building-create").unwrap().writes)
  assert_true(miniapp_endpoint_by_id("building-publish").unwrap().writes)
  assert_eq(
    miniapp_endpoint_by_id("marketplace-review-queue").unwrap().path,
    "/miniapp/marketplace/review-queue",
  )
  assert_false(
    miniapp_endpoint_by_id("marketplace-review-queue").unwrap().writes,
  )
  assert_eq(
    miniapp_endpoint_by_id("building-place").unwrap().path,
    "/buildings/:id/place",
  )
  assert_eq(
    miniapp_endpoint_by_id("placement-delete").unwrap().http_method,
    "DELETE",
  )
  assert_true(miniapp_endpoint_by_id("chat-send").unwrap().writes)
  assert_eq(
    miniapp_endpoint_by_id("run-status").unwrap().path,
    "/runs/:id/status",
  )
  assert_true(miniapp_endpoint_by_id("review-decision").unwrap().writes)
  assert_eq(
    miniapp_endpoint_by_id("supervisor-message").unwrap().path,
    "/miniapp/messages",
  )
  assert_eq(
    miniapp_endpoint_by_id("run-delegate").unwrap().path,
    "/miniapp/runs/delegate",
  )
  assert_eq(
    miniapp_endpoint_by_id("child-run-steer").unwrap().path,
    "/miniapp/runs/child/steer",
  )
  assert_eq(
    miniapp_endpoint_by_id("supervisor-wake").unwrap().path,
    "/miniapp/runs/supervisor/wake",
  )
  assert_eq(
    miniapp_endpoint_by_id("supervisor-stop").unwrap().path,
    "/miniapp/runs/supervisor/stop",
  )
  assert_eq(
    miniapp_endpoint_by_id("supervisor-resume").unwrap().path,
    "/miniapp/runs/supervisor/resume",
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-channels-read").unwrap().http_method,
    "GET",
  )
  assert_false(
    miniapp_endpoint_by_id("marketplace-channels-read").unwrap().writes,
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-channels-create").unwrap().http_method,
    "POST",
  )
  assert_true(
    miniapp_endpoint_by_id("marketplace-channels-create").unwrap().writes,
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-messages-read").unwrap().http_method,
    "GET",
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-messages-send").unwrap().http_method,
    "POST",
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-shared-listings").unwrap().http_method,
    "GET",
  )
  assert_true(
    miniapp_endpoint_by_id("marketplace-share-grant-revoke").unwrap().writes,
  )
}

///|
test "miniapp fixture separates building identity from placement" {
  let snapshot = miniapp_fixture_snapshot()
  assert_eq(snapshot.user.id, "user-a")
  assert_eq(snapshot.buildings.length(), 1)
  assert_eq(snapshot.placements.length(), 1)
  let building = snapshot.buildings[0]
  let placement = snapshot.placements[0]
  assert_eq(building.id, placement.building_id)
  assert_true(placement.id.contains(building.id))
  assert_eq(building.primary_book_id, snapshot.books[0].id)
  assert_true(building.visibility == Published)
  assert_true(building.scope == TownPublicScope)
  assert_true(snapshot.agents[0].building_id == Some(building.id))
  assert_eq(snapshot.threads[0].building_id, building.id)
  assert_true(snapshot.runs[0].status == RunWaitingReview)
}

///|
test "marketplace execution closure exposes request decision and retry routes" {
  assert_eq(
    miniapp_endpoint_by_id("marketplace-action-requests").unwrap().http_method,
    "GET",
  )
  assert_eq(
    miniapp_endpoint_by_id("marketplace-action-decision").unwrap().path,
    "/miniapp/marketplace/action-requests/decision",
  )
  assert_true(
    miniapp_endpoint_by_id("marketplace-action-retry").unwrap().writes,
  )
}

///|
test "miniapp fixture round-trips through json" {
  let snapshot = miniapp_fixture_snapshot()
  let text = snapshot.to_json().stringify()
  assert_true(text.contains("snapshot-user-a-1"))
  assert_true(text.contains("policy-hall"))
  let parsed : MiniappTownSnapshot = @json.from_json(@json.parse(text)) catch {
    _ => fail("expected miniapp snapshot json to parse")
  }
  assert_true(parsed == snapshot)
}
