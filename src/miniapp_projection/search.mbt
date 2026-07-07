///|
pub fn miniapp_search_buildings(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : MiniappViewerContext,
  query : String,
) -> Array[@miniapp_contracts.MiniappSearchResult] {
  let projected = miniapp_filter_snapshot_for_viewer(snapshot, viewer)
  let needle = query.trim().to_owned().to_lower()
  let results : Array[@miniapp_contracts.MiniappSearchResult] = []
  for building in projected.buildings {
    let score = miniapp_search_score(building, needle)
    if score > 0 || needle == "" {
      results.push({
        building,
        placement: miniapp_search_placement_for_building(
          projected.placements,
          building.id,
        ),
        book: miniapp_search_book_for_building(projected.books, building),
        score,
        reason: miniapp_search_reason(building, needle, score),
      })
    }
  }
  results
}

///|
fn miniapp_search_score(
  building : @miniapp_contracts.MiniappBuilding,
  needle : String,
) -> Int {
  if needle == "" {
    1
  } else if building.title.to_lower().contains(needle) {
    100
  } else if building.id.to_lower().contains(needle) {
    80
  } else if building.summary.to_lower().contains(needle) {
    50
  } else if miniapp_array_contains_text(building.tags, needle) {
    40
  } else if miniapp_array_contains_text(building.capabilities, needle) {
    30
  } else {
    0
  }
}

///|
fn miniapp_search_reason(
  building : @miniapp_contracts.MiniappBuilding,
  needle : String,
  score : Int,
) -> String {
  if needle == "" {
    "visible building"
  } else if building.title.to_lower().contains(needle) {
    "title match"
  } else if building.id.to_lower().contains(needle) {
    "id match"
  } else if building.summary.to_lower().contains(needle) {
    "summary match"
  } else if miniapp_array_contains_text(building.tags, needle) {
    "tag match"
  } else if miniapp_array_contains_text(building.capabilities, needle) {
    "capability match"
  } else {
    "score=\{score}"
  }
}

///|
fn miniapp_array_contains_text(items : Array[String], needle : String) -> Bool {
  for item in items {
    if item.to_lower().contains(needle) {
      return true
    }
  }
  false
}

///|
fn miniapp_search_placement_for_building(
  placements : Array[@miniapp_contracts.MiniappBuildingPlacement],
  building_id : String,
) -> @miniapp_contracts.MiniappBuildingPlacement? {
  for placement in placements {
    if placement.building_id == building_id {
      return Some(placement)
    }
  }
  None
}

///|
fn miniapp_search_book_for_building(
  books : Array[@miniapp_contracts.MiniappBookSummary],
  building : @miniapp_contracts.MiniappBuilding,
) -> @miniapp_contracts.MiniappBookSummary {
  for book in books {
    if book.id == building.primary_book_id {
      return book
    }
  }
  {
    id: building.primary_book_id,
    title: "unavailable book",
    summary: "No safe book projection is visible for this building.",
    visibility: building.visibility,
    accepted_memory_count: 0,
    pending_review_count: 0,
    version: building.version,
  }
}
