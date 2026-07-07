///|
fn miniapp_building_accept(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  message : String,
) -> MiniappBuildingChange {
  { ok: true, snapshot, message, building_id, placement_id: None }
}

///|
fn miniapp_building_accept_with_placement(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  placement_id : String,
  message : String,
) -> MiniappBuildingChange {
  { ok: true, snapshot, message, building_id, placement_id: Some(placement_id) }
}

///|
fn miniapp_building_reject(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
  message : String,
) -> MiniappBuildingChange {
  { ok: false, snapshot, message, building_id, placement_id: None }
}

///|
fn miniapp_snapshot_has_building(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> Bool {
  miniapp_building_by_id(snapshot, building_id) is Some(_)
}

///|
fn miniapp_building_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building_id : String,
) -> @miniapp_contracts.MiniappBuilding? {
  for building in snapshot.buildings {
    if building.id == building_id {
      return Some(building)
    }
  }
  None
}

///|
fn miniapp_placement_by_id(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  placement_id : String,
) -> @miniapp_contracts.MiniappBuildingPlacement? {
  for placement in snapshot.placements {
    if placement.id == placement_id {
      return Some(placement)
    }
  }
  None
}

///|
fn miniapp_replace_building(
  buildings : Array[@miniapp_contracts.MiniappBuilding],
  next : @miniapp_contracts.MiniappBuilding,
) -> Array[@miniapp_contracts.MiniappBuilding] {
  buildings.map(building => if building.id == next.id { next } else { building })
}

///|
fn miniapp_replace_placement(
  placements : Array[@miniapp_contracts.MiniappBuildingPlacement],
  next : @miniapp_contracts.MiniappBuildingPlacement,
) -> Array[@miniapp_contracts.MiniappBuildingPlacement] {
  let replaced = placements.map(placement => {
    if placement.id == next.id {
      { ..next, version: placement.version + 1 }
    } else {
      placement
    }
  })
  for placement in placements {
    if placement.id == next.id {
      return replaced
    }
  }
  replaced + [next]
}
