///|
pub fn miniapp_filter_snapshot_for_viewer(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : MiniappViewerContext,
) -> @miniapp_contracts.MiniappTownSnapshot {
  let buildings = snapshot.buildings.filter(building => {
    miniapp_can_view_building(viewer, building)
  })
  let placements = snapshot.placements.filter(placement => {
    miniapp_projection_has_building(buildings, placement.building_id)
  })
  let books = snapshot.books.filter(book => {
    miniapp_projection_has_book_building(buildings, book.id)
  })
  let agents = snapshot.agents.filter(agent => {
    match agent.building_id {
      Some(building_id) =>
        miniapp_projection_has_building(buildings, building_id)
      None =>
        miniapp_viewer_owns_owner(viewer, agent.owner_kind, agent.owner_id)
    }
  })
  let threads = snapshot.threads.filter(thread => {
    miniapp_projection_has_building(buildings, thread.building_id)
  })
  let runs = snapshot.runs.filter(run => {
    run.user_id == viewer.user_id ||
    miniapp_projection_has_building(buildings, run.building_id)
  })
  { ..snapshot, buildings, placements, books, agents, threads, runs }
}

///|
pub fn miniapp_projection_summary(
  source : @miniapp_contracts.MiniappTownSnapshot,
  projected : @miniapp_contracts.MiniappTownSnapshot,
) -> MiniappProjectionSummary {
  {
    user_id: projected.user.id,
    visible_buildings: projected.buildings.length(),
    visible_placements: projected.placements.length(),
    visible_books: projected.books.length(),
    visible_agents: projected.agents.length(),
    visible_threads: projected.threads.length(),
    visible_runs: projected.runs.length(),
    hidden_buildings: source.buildings.length() - projected.buildings.length(),
    hidden_placements: source.placements.length() -
    projected.placements.length(),
  }
}

///|
fn miniapp_projection_has_building(
  buildings : Array[@miniapp_contracts.MiniappBuilding],
  building_id : String,
) -> Bool {
  for building in buildings {
    if building.id == building_id {
      return true
    }
  }
  false
}

///|
fn miniapp_projection_has_book_building(
  buildings : Array[@miniapp_contracts.MiniappBuilding],
  book_id : String,
) -> Bool {
  for building in buildings {
    if building.primary_book_id == book_id {
      return true
    }
  }
  false
}
