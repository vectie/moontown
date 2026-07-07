///|
pub fn miniapp_share_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
  grants : Array[MiniappBuildingShareGrant],
  now_ms~ : UInt64,
) -> MiniappBuildingChange {
  match miniapp_building_by_id(snapshot, building_id) {
    Some(building) =>
      if !@miniapp_projection.miniapp_can_edit_building(viewer, building) {
        miniapp_building_reject(
          snapshot, building_id, "viewer cannot share building",
        )
      } else {
        let permissions = miniapp_merge_permissions(
          snapshot.permissions,
          grants,
        )
        let shared = {
          ..building,
          visibility: @miniapp_contracts.SharedPrivate,
          scope: @miniapp_contracts.TeamScope,
          publication: {
            ..building.publication,
            state: @miniapp_contracts.SharedPrivate,
          },
          version: building.version + 1,
          updated_at_ms: now_ms,
        }
        miniapp_building_accept(
          {
            ..snapshot,
            buildings: miniapp_replace_building(snapshot.buildings, shared),
            permissions,
            version: snapshot.version + 1,
          },
          building_id,
          "building shared",
        )
      }
    None => miniapp_building_reject(snapshot, building_id, "building not found")
  }
}

///|
pub fn miniapp_publish_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
  action : MiniappPublishAction,
  now_ms~ : UInt64,
) -> MiniappBuildingChange {
  match miniapp_building_by_id(snapshot, building_id) {
    Some(building) =>
      match action {
        SubmitForPublish =>
          if @miniapp_projection.miniapp_can_submit_building_for_publish(
              viewer, building,
            ) {
            miniapp_publish_replace(
              snapshot,
              building,
              @miniapp_contracts.SubmittedForPublish,
              @miniapp_contracts.TeamScope,
              "submitted for publication",
              submitted_at_ms=Some(now_ms),
              published_at_ms=None,
              now_ms~,
            )
          } else {
            miniapp_building_reject(
              snapshot, building_id, "viewer cannot submit building",
            )
          }
        ApprovePublish =>
          if @miniapp_projection.miniapp_can_approve_building_publication(
              viewer, building,
            ) {
            miniapp_publish_replace(
              snapshot,
              building,
              @miniapp_contracts.Published,
              @miniapp_contracts.TownPublicScope,
              "published to town",
              submitted_at_ms=building.publication.submitted_at_ms,
              published_at_ms=Some(now_ms),
              now_ms~,
            )
          } else {
            miniapp_building_reject(
              snapshot, building_id, "viewer cannot approve publication",
            )
          }
        RejectPublish(reason) =>
          if @miniapp_projection.miniapp_viewer_can_publish(viewer) {
            miniapp_publish_replace(
              snapshot,
              building,
              @miniapp_contracts.SharedPrivate,
              @miniapp_contracts.TeamScope,
              "publication rejected: \{reason}",
              submitted_at_ms=building.publication.submitted_at_ms,
              published_at_ms=None,
              now_ms~,
            )
          } else {
            miniapp_building_reject(
              snapshot, building_id, "viewer cannot reject publication",
            )
          }
        ArchiveBuilding =>
          if @miniapp_projection.miniapp_can_edit_building(viewer, building) {
            miniapp_publish_replace(
              snapshot,
              building,
              @miniapp_contracts.Archived,
              building.scope,
              "building archived",
              submitted_at_ms=building.publication.submitted_at_ms,
              published_at_ms=building.publication.published_at_ms,
              now_ms~,
            )
          } else {
            miniapp_building_reject(
              snapshot, building_id, "viewer cannot archive building",
            )
          }
      }
    None => miniapp_building_reject(snapshot, building_id, "building not found")
  }
}

///|
fn miniapp_publish_replace(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
  visibility : @miniapp_contracts.MiniappVisibilityState,
  scope : @miniapp_contracts.MiniappScope,
  review_summary : String,
  submitted_at_ms~ : UInt64?,
  published_at_ms~ : UInt64?,
  now_ms~ : UInt64,
) -> MiniappBuildingChange {
  let next = {
    ..building,
    visibility,
    scope,
    publication: {
      state: visibility,
      submitted_at_ms,
      published_at_ms,
      review_summary,
    },
    version: building.version + 1,
    updated_at_ms: now_ms,
  }
  miniapp_building_accept(
    {
      ..snapshot,
      buildings: miniapp_replace_building(snapshot.buildings, next),
      version: snapshot.version + 1,
    },
    building.id,
    review_summary,
  )
}

///|
fn miniapp_merge_permissions(
  current : Array[@miniapp_contracts.MiniappPermission],
  grants : Array[MiniappBuildingShareGrant],
) -> Array[@miniapp_contracts.MiniappPermission] {
  let permissions = current.copy()
  for grant in grants {
    if !miniapp_permission_exists(permissions, grant) {
      permissions.push({
        subject_kind: grant.subject_kind,
        subject_id: grant.subject_id,
        role: grant.role,
      })
    }
  }
  permissions
}

///|
fn miniapp_permission_exists(
  permissions : Array[@miniapp_contracts.MiniappPermission],
  grant : MiniappBuildingShareGrant,
) -> Bool {
  for permission in permissions {
    if permission.subject_kind == grant.subject_kind &&
      permission.subject_id == grant.subject_id &&
      permission.role == grant.role {
      return true
    }
  }
  false
}
