///|
let town_bearing_density_target : Int = 176

///|
/// Scan every integer anchor, including the odd-coordinate pockets skipped by
/// the legacy two-tile lattice. Interleave districts before filling a second
/// slot in each district, so a bounded quota cannot crowd only one map edge.
fn town_bearing_density_site(index : Int) -> (Int, Int) {
  let district = index % 144 * 53 % 144
  let offset = index / 144
  (district % 16 * 16 + offset % 16, district / 16 * 16 + offset / 16)
}

///|
/// Add compact, individually reserved decorative lots. Existing lots stay
/// untouched; a density target never overrides water, woodland or road masks.
fn town_bearing_fill_density(
  buildings : Map[Int, Array[IntersectionRoadPreviewBuilding]],
  target : Int,
) -> Unit {
  if wenyu_scene_prefix.length() != 257 * 145 ||
    wenyu_scene_road_prefix.length() != 257 * 145 {
    return
  }
  let occupied : Array[IntersectionRoadPreviewBuilding] = []
  for _, items in buildings {
    for building in items {
      occupied.push(building)
    }
  }
  if occupied.length() >= target {
    return
  }
  // Build a conflict graph for compact lots, then select the least-connected
  // available anchor first. A simple first-fit scan wastes scarce road-front
  // pockets by cutting several compatible reservations in half.
  let candidates : Array[IntersectionRoadPreviewBuilding] = []
  let anchors = Array::make(256 * 144, -1)
  let span = 3
  for i in 0..<(256 * 144) {
    let (x, y) = town_bearing_density_site(i)
    if !wenyu_scene_region_clear(wenyu_scene_prefix, x, y, span, span) {
      continue
    }
    // Compact homes and market rows surround the preserved larger landmarks.
    // The same coordinates always choose the same design.
    let accent = energy_valley_mod(
      ecosystem_stable_hash("density:\{x}:\{y}"),
      12,
    )
    let style = if accent < 4 { "row" } else { "lowrise" }
    let candidate : IntersectionRoadPreviewBuilding = {
      id: "procedural-grid-density-\{x}-\{y}",
      style,
      asset_path: intersection_road_preview_building_asset_path(
        style,
        accent % 3,
      ).unwrap_or(""),
      x,
      y,
      width: span,
      depth: span,
      apron: 0,
      depth_key: x + y + span * 2,
    }
    if !intersection_road_preview_building_geometry_valid(candidate) ||
      !wenyu_scene_lot_valid(candidate) {
      continue
    }
    let mut conflict = false
    if !town_street_segments.is_empty() && town_street_lot_gap(candidate) > 1.25 {
      continue
    }
    for other in occupied {
      if intersection_road_preview_buildings_overlap(candidate, other) {
        conflict = true
        break
      }
    }
    if conflict {
      continue
    }
    anchors[y * 256 + x] = candidates.length()
    candidates.push(candidate)
  }
  let neighbors : Array[Array[Int]] = []
  for candidate in candidates {
    let adjacent : Array[Int] = []
    // Three-unit homes retain a shared one-unit landscaped gap.
    for y in (candidate.y - 3).max(0)..<=(candidate.y + 3).min(143) {
      for x in (candidate.x - 3).max(0)..<=(candidate.x + 3).min(255) {
        let index = anchors[y * 256 + x]
        if index >= 0 {
          adjacent.push(index)
        }
      }
    }
    neighbors.push(adjacent)
  }
  let degrees = neighbors.map(items => items.length())
  let active = Array::make(candidates.length(), true)
  for _ in 0..<target.max(0) {
    if occupied.length() >= target {
      break
    }
    let mut selected = -1
    let mut degree = 100
    for i in 0..<candidates.length() {
      if active[i] && degrees[i] < degree {
        selected = i
        degree = degrees[i]
      }
    }
    if selected < 0 {
      break
    }
    let candidate = candidates[selected]
    occupied.push(candidate)
    match buildings.get(candidate.depth_key) {
      Some(items) => items.push(candidate)
      None => buildings[candidate.depth_key] = [candidate]
    }
    for removed in neighbors[selected] {
      if active[removed] {
        active[removed] = false
        for neighbor in neighbors[removed] {
          degrees[neighbor] -= 1
        }
      }
    }
  }
}
