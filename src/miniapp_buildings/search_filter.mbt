///|
pub fn miniapp_search_buildings_with_filter(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  filter : MiniappBuildingSearchFilter,
) -> Array[@miniapp_contracts.MiniappSearchResult] {
  @miniapp_projection.miniapp_search_buildings(snapshot, viewer, filter.query).filter(result => {
      miniapp_search_result_matches_filter(result, filter)
    },
  )
}

///|
fn miniapp_search_result_matches_filter(
  result : @miniapp_contracts.MiniappSearchResult,
  filter : MiniappBuildingSearchFilter,
) -> Bool {
  miniapp_optional_text_match(filter.tag, result.building.tags) &&
  miniapp_optional_text_match(filter.capability, result.building.capabilities) &&
  miniapp_optional_owner_match(filter.owner_id, result.building.owner_id) &&
  miniapp_optional_visibility_match(
    filter.visibility,
    result.building.visibility,
  ) &&
  miniapp_optional_layer_match(filter.layer_id, result.placement)
}

///|
fn miniapp_optional_text_match(
  needle : String?,
  values : Array[String],
) -> Bool {
  match needle {
    Some(value) => values.contains(value)
    None => true
  }
}

///|
fn miniapp_optional_owner_match(needle : String?, owner_id : String) -> Bool {
  match needle {
    Some(value) => owner_id == value
    None => true
  }
}

///|
fn miniapp_optional_visibility_match(
  visibility : @miniapp_contracts.MiniappVisibilityState?,
  actual : @miniapp_contracts.MiniappVisibilityState,
) -> Bool {
  match visibility {
    Some(value) => value == actual
    None => true
  }
}

///|
fn miniapp_optional_layer_match(
  layer_id : String?,
  placement : @miniapp_contracts.MiniappBuildingPlacement?,
) -> Bool {
  match layer_id {
    Some(value) =>
      match placement {
        Some(actual) => actual.layer_id == value
        None => false
      }
    None => true
  }
}
