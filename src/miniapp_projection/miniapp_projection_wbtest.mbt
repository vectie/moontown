///|
test "projection keeps public own and organization buildings visible" {
  let source = miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_viewer_context(
    user_id="user-a",
    organization_ids=["org-a"],
    workspace_ids=["workspace-user-a"],
    roles=[@miniapp_contracts.OwnerRole, @miniapp_contracts.EditorRole],
  )
  let projected = miniapp_filter_snapshot_for_viewer(source, viewer)
  let summary = miniapp_projection_summary(source, projected)
  assert_eq(summary.visible_buildings, 3)
  assert_eq(summary.hidden_buildings, 1)
  assert_eq(summary.visible_placements, 3)
  assert_true(miniapp_projected_has_building(projected, "policy-hall"))
  assert_true(miniapp_projected_has_building(projected, "private-lab"))
  assert_true(miniapp_projected_has_building(projected, "team-studio"))
  assert_true(!miniapp_projected_has_building(projected, "other-private-lab"))
}

///|
test "projection hides public and system when viewer opts out" {
  let source = miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_viewer_context(
    user_id="user-a",
    include_public=false,
    include_system=false,
    roles=[@miniapp_contracts.OwnerRole],
  )
  let projected = miniapp_filter_snapshot_for_viewer(source, viewer)
  assert_true(!miniapp_projected_has_building(projected, "policy-hall"))
  assert_true(miniapp_projected_has_building(projected, "private-lab"))
}

///|
test "projection permissions distinguish edit place submit and approve" {
  let private_building = @miniapp_contracts.miniapp_fixture_building(
    id="private-lab",
    owner_id="user-a",
    owner_kind=@miniapp_contracts.UserOwner,
    visibility=@miniapp_contracts.PrivateDraft,
    scope=@miniapp_contracts.PersonalScope,
  )
  let submitted_building = @miniapp_contracts.miniapp_fixture_building(
    id="submitted-lab",
    owner_id="user-b",
    owner_kind=@miniapp_contracts.UserOwner,
    visibility=@miniapp_contracts.SubmittedForPublish,
    scope=@miniapp_contracts.PersonalScope,
  )
  let owner = miniapp_viewer_context(user_id="user-a", roles=[
    @miniapp_contracts.OwnerRole,
    @miniapp_contracts.EditorRole,
  ])
  let publisher = miniapp_viewer_context(user_id="reviewer", roles=[
    @miniapp_contracts.PublisherRole,
  ])
  assert_true(miniapp_can_view_building(owner, private_building))
  assert_true(miniapp_can_edit_building(owner, private_building))
  assert_true(miniapp_can_place_building(owner, private_building))
  assert_true(miniapp_can_submit_building_for_publish(owner, private_building))
  assert_true(
    !miniapp_can_approve_building_publication(owner, submitted_building),
  )
  assert_true(
    miniapp_can_approve_building_publication(publisher, submitted_building),
  )
}

///|
test "search returns only visible buildings with safe book projection" {
  let source = miniapp_projection_fixture_mixed_snapshot()
  let viewer = miniapp_viewer_context(
    user_id="user-a",
    organization_ids=["org-a"],
    roles=[@miniapp_contracts.OwnerRole],
  )
  let policy_results = miniapp_search_buildings(source, viewer, "policy")
  assert_eq(policy_results.length(), 1)
  assert_eq(policy_results[0].building.id, "policy-hall")
  assert_true(policy_results[0].placement is Some(_))
  assert_eq(policy_results[0].book.id, "book-policy-hall")
  assert_eq(policy_results[0].reason, "title match")

  let all_visible = miniapp_search_buildings(source, viewer, "")
  assert_eq(all_visible.length(), 3)
  for result in all_visible {
    assert_true(result.building.id != "other-private-lab")
  }
}

///|
fn miniapp_projected_has_building(
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
