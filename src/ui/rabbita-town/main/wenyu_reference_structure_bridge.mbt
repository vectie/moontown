///|
/// Presentation categories attached to Wenyu footprint or roof-anchor evidence.
priv enum WenyuReferenceBuildingKind {
  WenyuLowrise
  WenyuRow
  WenyuBlock
  WenyuTower
  WenyuCourtyard
  WenyuCampus
  WenyuCivic
  WenyuIndustrial
}

///|
/// Typed structure categories consumed by the new procedural renderer.
priv enum EnergyValleyStructureKind {
  StructureLowrise
  StructureRow
  StructureBlock
  StructureTower
  StructureCourtyard
  StructureCampus
  StructureCivic
  StructureIndustrial
}

///|
priv struct WenyuReferenceBuildingCell {
  source_kind : WenyuReferenceBuildingKind
  component_index : Int
  anchor_x : Int
  anchor_y : Int
}

///|
extern "js" fn reference_building_snapshot_ready() -> Bool =
  #| () => ["moontown.wenyu_reference_buildings.v4", "moontown.wenyu_reference_building_anchors.v1"].includes(globalThis.__wenyuReferenceBuildings?.schema) && globalThis.__wenyuReferenceBuildings?.tileGrid?.width === 256 && globalThis.__wenyuReferenceBuildings?.tileGrid?.height === 144

///|
extern "js" fn reference_building_code_at(grid_x : Int, grid_y : Int) -> String =
  #| (gridX, gridY) => globalThis.__wenyuReferenceBuildings?.labelRows?.[gridY]?.[gridX] || ""

///|
extern "js" fn reference_building_component_index_at(
  grid_x : Int,
  grid_y : Int,
) -> Int =
  #| (gridX, gridY) => globalThis.__wenyuReferenceBuildingComponentRows?.[gridY]?.[gridX]?.index ?? -1

///|
extern "js" fn reference_building_component_anchor_x_at(
  grid_x : Int,
  grid_y : Int,
) -> Int =
  #| (gridX, gridY) => globalThis.__wenyuReferenceBuildingComponentRows?.[gridY]?.[gridX]?.anchorX ?? gridX

///|
extern "js" fn reference_building_component_anchor_y_at(
  grid_x : Int,
  grid_y : Int,
) -> Int =
  #| (gridX, gridY) => globalThis.__wenyuReferenceBuildingComponentRows?.[gridY]?.[gridX]?.anchorY ?? gridY

///|
fn wenyu_reference_building_kind_from_code(
  code : String,
) -> WenyuReferenceBuildingKind? {
  match code {
    "l" => Some(WenyuLowrise)
    "r" => Some(WenyuRow)
    "b" => Some(WenyuBlock)
    "t" => Some(WenyuTower)
    "q" => Some(WenyuCourtyard)
    "c" => Some(WenyuCampus)
    "v" => Some(WenyuCivic)
    "i" => Some(WenyuIndustrial)
    _ => None
  }
}

///|
fn WenyuReferenceBuildingKind::new_system_kind(
  self : WenyuReferenceBuildingKind,
) -> EnergyValleyStructureKind {
  match self {
    WenyuLowrise => StructureLowrise
    WenyuRow => StructureRow
    WenyuBlock => StructureBlock
    WenyuTower => StructureTower
    WenyuCourtyard => StructureCourtyard
    WenyuCampus => StructureCampus
    WenyuCivic => StructureCivic
    WenyuIndustrial => StructureIndustrial
  }
}

///|
fn EnergyValleyStructureKind::runtime_name(
  self : EnergyValleyStructureKind,
) -> String {
  match self {
    StructureLowrise => "lowrise"
    StructureRow => "row"
    StructureBlock => "block"
    StructureTower => "tower"
    StructureCourtyard => "courtyard"
    StructureCampus => "campus"
    StructureCivic => "civic"
    StructureIndustrial => "industrial"
  }
}

///|
fn EnergyValleyStructureKind::floor_profile(
  self : EnergyValleyStructureKind,
) -> (Int, Int) {
  match self {
    StructureLowrise => (1, 2)
    StructureRow => (2, 2)
    StructureBlock => (2, 3)
    StructureTower => (5, 5)
    StructureCourtyard => (2, 2)
    StructureCampus => (1, 2)
    StructureCivic => (2, 2)
    StructureIndustrial => (1, 2)
  }
}

///|
fn wenyu_reference_building_cell_at(
  grid_x : Int,
  grid_y : Int,
) -> WenyuReferenceBuildingCell? {
  match
    wenyu_reference_building_kind_from_code(
      reference_building_code_at(grid_x, grid_y),
    ) {
    None => None
    Some(source_kind) =>
      Some({
        source_kind,
        component_index: reference_building_component_index_at(grid_x, grid_y),
        anchor_x: reference_building_component_anchor_x_at(grid_x, grid_y),
        anchor_y: reference_building_component_anchor_y_at(grid_x, grid_y),
      })
  }
}

///|
fn wenyu_reference_structure_for_cell(
  seed : Int,
  terrain_kind : String,
  cell : WenyuReferenceBuildingCell,
) -> (String, Int)? {
  if terrain_kind != "urban-dense" &&
    terrain_kind != "urban" &&
    terrain_kind != "campus" {
    return None
  }
  let normalized_seed = normalized_energy_valley_seed(seed)
  if normalized_seed != default_energy_valley_seed &&
    energy_valley_variation(
      normalized_seed,
      cell.anchor_x,
      cell.anchor_y,
      463 + energy_valley_mod(cell.component_index, 17),
      100,
    ) >=
    86 {
    return None
  }
  let target = cell.source_kind.new_system_kind()
  let (base_floors, floor_variants) = target.floor_profile()
  let floors = base_floors +
    energy_valley_variation(
      normalized_seed,
      cell.anchor_x,
      cell.anchor_y,
      467 + energy_valley_mod(cell.component_index, 19),
      floor_variants,
    )
  Some((target.runtime_name(), floors))
}

///|
fn wenyu_reference_structure_at(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
  terrain_kind : String,
) -> (String, Int)? {
  match wenyu_reference_building_cell_at(grid_x, grid_y) {
    None => None
    Some(cell) => wenyu_reference_structure_for_cell(seed, terrain_kind, cell)
  }
}

///|
/// Treat the Wenyu building raster as archetype evidence for one gameplay
/// parcel. The source components were authored as per-cell materials, so a
/// weighted vote is more stable than promoting every source cell to a runtime
/// building.
fn wenyu_reference_structure_for_parcel(
  seed : Int,
  grid_x : Int,
  grid_y : Int,
  width : Int,
  depth : Int,
  terrain_kind : String,
) -> (String, Int)? {
  if terrain_kind != "urban-dense" &&
    terrain_kind != "urban" &&
    terrain_kind != "campus" {
    return None
  }
  let counts = [0, 0, 0, 0, 0, 0, 0, 0]
  for y in grid_y..<(grid_y + depth) {
    for x in grid_x..<(grid_x + width) {
      let index = match reference_building_code_at(x, y) {
        "l" => 0
        "r" => 1
        "b" => 2
        "t" => 3
        "q" => 4
        "c" => 5
        "v" => 6
        "i" => 7
        _ => -1
      }
      if index >= 0 {
        counts[index] = counts[index] + 1
      }
    }
  }
  let mut best_index = -1
  let mut best_count = 0
  for index in 0..<counts.length() {
    if counts[index] > best_count {
      best_index = index
      best_count = counts[index]
    }
  }
  if best_index < 0 {
    return None
  }
  let source_code = ["l", "r", "b", "t", "q", "c", "v", "i"][best_index]
  let source_kind = match wenyu_reference_building_kind_from_code(source_code) {
    Some(value) => value
    None => return None
  }
  let normalized_seed = normalized_energy_valley_seed(seed)
  if normalized_seed != default_energy_valley_seed &&
    energy_valley_variation(
      normalized_seed,
      grid_x,
      grid_y,
      521 + best_index,
      100,
    ) >=
    86 {
    return None
  }
  let target = source_kind.new_system_kind()
  let (base_floors, floor_variants) = target.floor_profile()
  Some(
    (
      target.runtime_name(),
      base_floors +
      energy_valley_variation(
        normalized_seed,
        grid_x,
        grid_y,
        541 + best_index,
        floor_variants,
      ),
    ),
  )
}
