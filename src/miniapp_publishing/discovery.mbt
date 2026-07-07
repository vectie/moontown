///|
pub fn miniapp_public_discovery(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  filter : MiniappDiscoveryFilter,
) -> Array[MiniappPublicBuildingPreview] {
  let output : Array[MiniappPublicBuildingPreview] = []
  for building in snapshot.buildings {
    if miniapp_public_discovery_matches(snapshot, viewer, building, filter) {
      output.push(
        miniapp_public_preview_for_building(snapshot, viewer, building, filter),
      )
    }
  }
  miniapp_sort_public_previews(output)
}

///|
pub fn miniapp_public_building_preview(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building_id : String,
) -> MiniappPublicBuildingPreview? {
  match miniapp_publishing_building_by_id(snapshot, building_id) {
    None => None
    Some(building) =>
      if miniapp_public_building_visible_for_discovery(viewer, building) {
        Some(
          miniapp_public_preview_for_building(snapshot, viewer, building, {
            query: "",
            tag: None,
            category_id: None,
            owner_id: None,
            capability: None,
            min_updated_at_ms: None,
          }),
        )
      } else {
        None
      }
  }
}

///|
fn miniapp_public_discovery_matches(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
  filter : MiniappDiscoveryFilter,
) -> Bool {
  miniapp_public_building_visible_for_discovery(viewer, building) &&
  miniapp_discovery_text_match(snapshot, building, filter.query) &&
  miniapp_optional_tag_match(filter.tag, building.tags) &&
  miniapp_optional_category_match(filter.category_id, building.kind) &&
  miniapp_optional_owner_match(filter.owner_id, building.owner_id) &&
  miniapp_optional_capability_match(filter.capability, building.capabilities) &&
  miniapp_optional_freshness_match(
    filter.min_updated_at_ms,
    building.updated_at_ms,
  )
}

///|
fn miniapp_public_building_visible_for_discovery(
  viewer : @miniapp_projection.MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
) -> Bool {
  @miniapp_projection.miniapp_can_place_building(viewer, building) &&
  building.visibility == @miniapp_contracts.Published &&
  (
    building.scope == @miniapp_contracts.TownPublicScope ||
    building.scope == @miniapp_contracts.SystemPublicScope
  )
}

///|
fn miniapp_public_preview_for_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  building : @miniapp_contracts.MiniappBuilding,
  filter : MiniappDiscoveryFilter,
) -> MiniappPublicBuildingPreview {
  let book = miniapp_publishing_book_by_id(snapshot, building.primary_book_id)
  let book_summary = match book {
    Some(value) => miniapp_safe_preview_summary(value.summary)
    None => "No public book preview is available."
  }
  {
    building_id: building.id,
    title: building.title,
    owner_id: building.owner_id,
    owner_label: miniapp_public_owner_label(building),
    category_id: miniapp_building_category_id(building.kind),
    summary: miniapp_safe_preview_summary(building.summary),
    tags: building.tags,
    capabilities: building.capabilities,
    book_summary,
    score: miniapp_public_discovery_score(building, book, filter.query),
    reason: miniapp_public_discovery_reason(building, book, filter.query),
    can_place: @miniapp_projection.miniapp_can_place_building(viewer, building),
  }
}

///|
fn miniapp_public_discovery_score(
  building : @miniapp_contracts.MiniappBuilding,
  book : @miniapp_contracts.MiniappBookSummary?,
  query : String,
) -> Int {
  let mut score = if building.owner_kind == @miniapp_contracts.SystemOwner {
    1000
  } else {
    500
  }
  score += miniapp_text_score(building.title, query, 120)
  score += miniapp_text_score(building.summary, query, 70)
  if miniapp_array_contains_text(building.tags, query) {
    score += 50
  }
  if miniapp_array_contains_text(building.capabilities, query) {
    score += 40
  }
  match book {
    Some(value) => {
      score += value.accepted_memory_count * 8
      score += miniapp_text_score(value.summary, query, 30)
    }
    None => ()
  }
  score += (building.updated_at_ms / 1000UL).to_int()
  score
}

///|
fn miniapp_public_discovery_reason(
  building : @miniapp_contracts.MiniappBuilding,
  book : @miniapp_contracts.MiniappBookSummary?,
  query : String,
) -> String {
  let needle = query.trim().to_owned().to_lower()
  if building.owner_kind == @miniapp_contracts.SystemOwner {
    "official/system building"
  } else if needle != "" && building.title.to_lower().contains(needle) {
    "title match"
  } else if needle != "" && building.summary.to_lower().contains(needle) {
    "summary match"
  } else if needle != "" && miniapp_array_contains_text(building.tags, needle) {
    "tag match"
  } else if needle != "" &&
    miniapp_array_contains_text(building.capabilities, needle) {
    "capability match"
  } else {
    match book {
      Some(value) =>
        if needle != "" && value.summary.to_lower().contains(needle) {
          "book summary match"
        } else {
          "public building"
        }
      None => "public building"
    }
  }
}

///|
fn miniapp_discovery_text_match(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
  query : String,
) -> Bool {
  let needle = query.trim().to_owned().to_lower()
  if needle == "" {
    true
  } else {
    let book_match = match
      miniapp_publishing_book_by_id(snapshot, building.primary_book_id) {
      Some(book) => book.summary.to_lower().contains(needle)
      None => false
    }
    building.title.to_lower().contains(needle) ||
    building.summary.to_lower().contains(needle) ||
    miniapp_array_contains_text(building.tags, needle) ||
    miniapp_array_contains_text(building.capabilities, needle) ||
    book_match
  }
}
