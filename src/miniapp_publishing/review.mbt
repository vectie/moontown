///|
pub fn miniapp_submit_publication_request(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  request : MiniappPublicationRequest,
  now_ms~ : UInt64,
  policy? : MiniappPublicationPolicy = miniapp_default_publication_policy(),
) -> MiniappModerationChange {
  let validation = miniapp_validate_publication(
    snapshot,
    viewer,
    request,
    policy~,
  )
  if !validation.ok {
    miniapp_moderation_reject(
      snapshot,
      request.building_id,
      "publication validation failed",
      validation,
    )
  } else {
    let change = @miniapp_buildings.miniapp_publish_building(
      snapshot,
      viewer,
      request.building_id,
      @miniapp_buildings.SubmitForPublish,
      now_ms~,
    )
    miniapp_change_from_building_change(change, validation)
  }
}

///|
pub fn miniapp_review_publication_request(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  request : MiniappPublicationRequest,
  decision : MiniappModerationDecision,
  now_ms~ : UInt64,
  policy? : MiniappPublicationPolicy = miniapp_default_publication_policy(),
) -> MiniappModerationChange {
  let validation = miniapp_validate_publication(
    snapshot,
    viewer,
    request,
    policy~,
  )
  match decision {
    ApprovePublication =>
      if !validation.ok {
        miniapp_moderation_reject(
          snapshot,
          request.building_id,
          "publication validation failed",
          validation,
        )
      } else {
        let change = @miniapp_buildings.miniapp_publish_building(
          snapshot,
          viewer,
          request.building_id,
          @miniapp_buildings.ApprovePublish,
          now_ms~,
        )
        miniapp_change_from_building_change(change, validation)
      }
    RejectPublication(reason) =>
      if !@miniapp_projection.miniapp_viewer_can_publish(viewer) {
        miniapp_moderation_reject(
          snapshot,
          request.building_id,
          "viewer cannot reject publication",
          validation,
        )
      } else {
        let change = @miniapp_buildings.miniapp_publish_building(
          snapshot,
          viewer,
          request.building_id,
          @miniapp_buildings.RejectPublish(reason),
          now_ms~,
        )
        miniapp_change_from_building_change(change, validation)
      }
    HidePublished(reason) =>
      miniapp_hide_published_building(
        snapshot,
        viewer,
        request.building_id,
        reason,
        validation,
        now_ms~,
      )
  }
}

///|
fn miniapp_hide_published_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
  reason : String,
  validation : MiniappPublicationValidation,
  now_ms~ : UInt64,
) -> MiniappModerationChange {
  if !@miniapp_projection.miniapp_viewer_can_publish(viewer) {
    miniapp_moderation_reject(
      snapshot, building_id, "viewer cannot hide published building", validation,
    )
  } else {
    match miniapp_publishing_building_by_id(snapshot, building_id) {
      None =>
        miniapp_moderation_reject(
          snapshot, building_id, "building not found", validation,
        )
      Some(building) => {
        let hidden = {
          ..building,
          visibility: @miniapp_contracts.Archived,
          publication: {
            ..building.publication,
            state: @miniapp_contracts.Archived,
            review_summary: "hidden: \{reason}",
          },
          version: building.version + 1,
          updated_at_ms: now_ms,
        }
        {
          ok: true,
          snapshot: {
            ..snapshot,
            buildings: miniapp_publishing_replace_building(
              snapshot.buildings,
              hidden,
            ),
            version: snapshot.version + 1,
          },
          building_id,
          message: "published building hidden",
          validation,
        }
      }
    }
  }
}

///|
fn miniapp_change_from_building_change(
  change : @miniapp_buildings.MiniappBuildingChange,
  validation : MiniappPublicationValidation,
) -> MiniappModerationChange {
  {
    ok: change.ok,
    snapshot: change.snapshot,
    building_id: change.building_id,
    message: change.message,
    validation,
  }
}

///|
fn miniapp_moderation_reject(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  message : String,
  validation : MiniappPublicationValidation,
) -> MiniappModerationChange {
  { ok: false, snapshot, building_id, message, validation }
}
