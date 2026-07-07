///|
pub fn miniapp_create_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappBuildingDraft,
  now_ms~ : UInt64,
) -> MiniappBuildingChange {
  if miniapp_snapshot_has_building(snapshot, draft.id) {
    miniapp_building_reject(snapshot, draft.id, "building already exists")
  } else if !viewer.workspace_ids.contains(draft.workspace_id) {
    miniapp_building_reject(
      snapshot,
      draft.id,
      "workspace not visible to viewer",
    )
  } else {
    let building : @miniapp_contracts.MiniappBuilding = {
      id: draft.id,
      kind: draft.kind,
      title: draft.title,
      summary: draft.summary,
      owner_kind: @miniapp_contracts.UserOwner,
      owner_id: viewer.user_id,
      workspace_id: draft.workspace_id,
      visibility: @miniapp_contracts.PrivateDraft,
      scope: @miniapp_contracts.PersonalScope,
      tags: draft.tags,
      capabilities: draft.capabilities,
      primary_book_id: draft.primary_book_id,
      publication: {
        state: @miniapp_contracts.PrivateDraft,
        submitted_at_ms: None,
        published_at_ms: None,
        review_summary: "private draft",
      },
      version: 1,
      updated_at_ms: now_ms,
    }
    let book : @miniapp_contracts.MiniappBookSummary = {
      id: draft.primary_book_id,
      title: "\{draft.title} Book",
      summary: "Private building memory projection.",
      visibility: @miniapp_contracts.PrivateDraft,
      accepted_memory_count: 0,
      pending_review_count: 0,
      version: 1,
    }
    miniapp_building_accept(
      {
        ..snapshot,
        buildings: snapshot.buildings + [building],
        books: snapshot.books + [book],
        version: snapshot.version + 1,
      },
      draft.id,
      "building created",
    )
  }
}

///|
pub fn miniapp_update_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
  patch : MiniappBuildingPatch,
  now_ms~ : UInt64,
) -> MiniappBuildingChange {
  let buildings : Array[@miniapp_contracts.MiniappBuilding] = []
  let mut updated = false
  let mut rejected = ""
  for building in snapshot.buildings {
    if building.id == building_id {
      if @miniapp_projection.miniapp_can_edit_building(viewer, building) {
        buildings.push(miniapp_apply_building_patch(building, patch, now_ms~))
        updated = true
      } else {
        buildings.push(building)
        rejected = "viewer cannot edit building"
      }
    } else {
      buildings.push(building)
    }
  }
  if updated {
    miniapp_building_accept(
      { ..snapshot, buildings, version: snapshot.version + 1 },
      building_id,
      "building updated",
    )
  } else if rejected != "" {
    miniapp_building_reject(snapshot, building_id, rejected)
  } else {
    miniapp_building_reject(snapshot, building_id, "building not found")
  }
}

///|
fn miniapp_apply_building_patch(
  building : @miniapp_contracts.MiniappBuilding,
  patch : MiniappBuildingPatch,
  now_ms~ : UInt64,
) -> @miniapp_contracts.MiniappBuilding {
  {
    ..building,
    title: patch.title.unwrap_or(building.title),
    summary: patch.summary.unwrap_or(building.summary),
    tags: patch.tags.unwrap_or(building.tags),
    capabilities: patch.capabilities.unwrap_or(building.capabilities),
    version: building.version + 1,
    updated_at_ms: now_ms,
  }
}
