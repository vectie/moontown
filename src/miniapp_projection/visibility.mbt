///|
pub fn miniapp_viewer_is_admin(viewer : MiniappViewerContext) -> Bool {
  viewer.roles.contains(@miniapp_contracts.AdminRole)
}

///|
pub fn miniapp_viewer_can_publish(viewer : MiniappViewerContext) -> Bool {
  miniapp_viewer_is_admin(viewer) ||
  viewer.roles.contains(@miniapp_contracts.PublisherRole)
}

///|
pub fn miniapp_viewer_owns_owner(
  viewer : MiniappViewerContext,
  owner_kind : @miniapp_contracts.MiniappOwnerKind,
  owner_id : String,
) -> Bool {
  match owner_kind {
    @miniapp_contracts.UserOwner => owner_id == viewer.user_id
    @miniapp_contracts.OrganizationOwner =>
      viewer.organization_ids.contains(owner_id)
    @miniapp_contracts.SystemOwner => false
  }
}

///|
pub fn miniapp_building_owned_by_viewer(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  miniapp_viewer_owns_owner(viewer, building.owner_kind, building.owner_id) ||
  viewer.workspace_ids.contains(building.workspace_id)
}

///|
pub fn miniapp_building_is_public(
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  building.visibility == @miniapp_contracts.Published &&
  building.scope == @miniapp_contracts.TownPublicScope
}

///|
pub fn miniapp_building_is_system(
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  building.owner_kind == @miniapp_contracts.SystemOwner ||
  building.scope == @miniapp_contracts.SystemPublicScope
}

///|
pub fn miniapp_can_view_building(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  if miniapp_viewer_is_admin(viewer) {
    true
  } else if miniapp_building_owned_by_viewer(viewer, building) {
    building.visibility != @miniapp_contracts.Archived
  } else if miniapp_building_is_system(building) {
    viewer.include_system && building.visibility == @miniapp_contracts.Published
  } else if miniapp_building_is_public(building) {
    viewer.include_public
  } else {
    false
  }
}

///|
pub fn miniapp_can_edit_building(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  miniapp_viewer_is_admin(viewer) ||
  (
    miniapp_building_owned_by_viewer(viewer, building) &&
    (
      viewer.roles.contains(@miniapp_contracts.OwnerRole) ||
      viewer.roles.contains(@miniapp_contracts.EditorRole)
    ) &&
    building.visibility != @miniapp_contracts.Archived
  )
}

///|
pub fn miniapp_can_place_building(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  miniapp_can_view_building(viewer, building) &&
  (
    miniapp_building_owned_by_viewer(viewer, building) ||
    miniapp_building_is_public(building) ||
    miniapp_building_is_system(building)
  )
}

///|
pub fn miniapp_can_submit_building_for_publish(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  miniapp_can_edit_building(viewer, building) &&
  (
    building.visibility == @miniapp_contracts.PrivateDraft ||
    building.visibility == @miniapp_contracts.SharedPrivate
  )
}

///|
pub fn miniapp_can_approve_building_publication(
  viewer : MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  miniapp_viewer_can_publish(viewer) &&
  building.visibility == @miniapp_contracts.SubmittedForPublish
}
