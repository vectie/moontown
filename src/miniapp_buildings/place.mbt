///|
pub fn miniapp_place_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  draft : MiniappPlacementDraft,
) -> MiniappBuildingChange {
  match miniapp_building_by_id(snapshot, draft.building_id) {
    Some(building) =>
      if !@miniapp_projection.miniapp_can_place_building(viewer, building) {
        miniapp_building_reject(
          snapshot,
          draft.building_id,
          "viewer cannot place building",
        )
      } else if !viewer.workspace_ids.contains(
          miniapp_layer_owner_workspace(draft.layer_id),
        ) &&
        !@miniapp_projection.miniapp_viewer_is_admin(viewer) {
        miniapp_building_reject(
          snapshot,
          draft.building_id,
          "layer not visible to viewer",
        )
      } else {
        let placement : @miniapp_contracts.MiniappBuildingPlacement = {
          id: draft.id,
          building_id: draft.building_id,
          layer_id: draft.layer_id,
          x: draft.x,
          y: draft.y,
          region_id: draft.region_id,
          pinned: draft.pinned,
          version: 1,
        }
        miniapp_building_accept_with_placement(
          {
            ..snapshot,
            placements: miniapp_replace_placement(
              snapshot.placements,
              placement,
            ),
            version: snapshot.version + 1,
          },
          draft.building_id,
          draft.id,
          "building placed",
        )
      }
    None =>
      miniapp_building_reject(snapshot, draft.building_id, "building not found")
  }
}

///|
pub fn miniapp_remove_placement(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  placement_id : String,
) -> MiniappBuildingChange {
  match miniapp_placement_by_id(snapshot, placement_id) {
    Some(placement) =>
      if !viewer.workspace_ids.contains(
          miniapp_layer_owner_workspace(placement.layer_id),
        ) &&
        !@miniapp_projection.miniapp_viewer_is_admin(viewer) {
        miniapp_building_reject(
          snapshot,
          placement.building_id,
          "viewer cannot remove placement",
        )
      } else {
        miniapp_building_accept_with_placement(
          {
            ..snapshot,
            placements: snapshot.placements.filter(current => {
              current.id != placement_id
            }),
            version: snapshot.version + 1,
          },
          placement.building_id,
          placement_id,
          "placement removed",
        )
      }
    None => miniapp_building_reject(snapshot, "", "placement not found")
  }
}

///|
fn miniapp_layer_owner_workspace(layer_id : String) -> String {
  if layer_id.has_prefix("layer-personal-") {
    "workspace-\{layer_id[15:].to_owned()}"
  } else if layer_id.has_prefix("layer-team-") {
    "workspace-\{layer_id[11:].to_owned()}"
  } else {
    layer_id
  }
}
