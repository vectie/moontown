///|
priv struct EnergyValleyPoint {
  x : Int
  y : Int
}

///|
priv struct EnergyValleyFootprint {
  x : Int
  y : Int
  width : Int
  height : Int
}

///|
priv struct EnergyValleyPlacement {
  grid_x : Int
  grid_y : Int
  entrance_x : Int
  entrance_y : Int
}

///|
fn energy_valley_module_anchor_hash(
  seed : Int,
  civic : WenyuTownModule,
  index : Int,
) -> Int {
  let mut value = energy_valley_hash(
    seed,
    civic.grid_x + index,
    civic.grid_y,
    163,
  )
  for char in civic.id {
    value = energy_valley_mod(value * 37 + char.to_int(), 2147483629)
  }
  value
}

///|
fn energy_valley_footprint_in_bounds(
  grid_x : Int,
  grid_y : Int,
  width : Int,
  height : Int,
) -> Bool {
  grid_x >= 3 &&
  grid_y >= 3 &&
  grid_x + width < tilemap_grid_width() - 3 &&
  grid_y + height < tilemap_grid_height() - 3
}

///|
fn energy_valley_footprints_overlap(
  left : EnergyValleyFootprint,
  right : EnergyValleyFootprint,
) -> Bool {
  left.x < right.x + right.width + 2 &&
  left.x + left.width + 2 > right.x &&
  left.y < right.y + right.height + 2 &&
  left.y + left.height + 2 > right.y
}

///|
fn energy_valley_placement_overlaps(
  placed : Array[EnergyValleyFootprint],
  civic : WenyuTownModule,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  let candidate : EnergyValleyFootprint = {
    x: grid_x,
    y: grid_y,
    width: civic.footprint_w,
    height: civic.footprint_h,
  }
  for footprint in placed {
    if energy_valley_footprints_overlap(candidate, footprint) {
      return true
    }
  }
  false
}

///|
fn energy_valley_footprint_is_buildable(
  seed : Int,
  civic : WenyuTownModule,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  for y in grid_y..<(grid_y + civic.footprint_h) {
    for x in grid_x..<(grid_x + civic.footprint_w) {
      if !energy_valley_buildable_at(seed, x, y) {
        return false
      }
    }
  }
  true
}

///|
fn energy_valley_district_accepts(
  authored_district : String,
  seed : Int,
  grid_x : Int,
  grid_y : Int,
) -> Bool {
  let generated = energy_valley_district_at(seed, grid_x, grid_y)
  if authored_district == generated {
    true
  } else if authored_district.contains("north") {
    generated.contains("north")
  } else if authored_district.contains("lake") {
    generated.contains("lake") ||
    energy_valley_near_water(seed, grid_x, grid_y, 12)
  } else if authored_district.contains("south") {
    generated == "south-showcase"
  } else if authored_district.contains("east") {
    generated.contains("east")
  } else if authored_district.contains("west") {
    generated.contains("west")
  } else {
    false
  }
}

///|
fn energy_valley_perimeter_road_entrance(
  seed : Int,
  civic : WenyuTownModule,
  grid_x : Int,
  grid_y : Int,
  phase : Int,
) -> EnergyValleyPoint? {
  for offset in 0..<civic.footprint_w {
    let x = grid_x + energy_valley_mod(offset + phase, civic.footprint_w)
    if energy_valley_framework_road_at(seed, x, grid_y - 1) {
      return Some({ x, y: grid_y - 1 })
    }
    if energy_valley_framework_road_at(seed, x, grid_y + civic.footprint_h) {
      return Some({ x, y: grid_y + civic.footprint_h })
    }
  }
  for offset in 0..<civic.footprint_h {
    let y = grid_y + energy_valley_mod(offset + phase, civic.footprint_h)
    if energy_valley_framework_road_at(seed, grid_x - 1, y) {
      return Some({ x: grid_x - 1, y })
    }
    if energy_valley_framework_road_at(seed, grid_x + civic.footprint_w, y) {
      return Some({ x: grid_x + civic.footprint_w, y })
    }
  }
  None
}

///|
fn energy_valley_candidate_placement(
  seed : Int,
  civic : WenyuTownModule,
  placed : Array[EnergyValleyFootprint],
  grid_x : Int,
  grid_y : Int,
  entrance : EnergyValleyPoint,
  require_district : Bool,
) -> EnergyValleyPlacement? {
  if !energy_valley_footprint_in_bounds(
      grid_x,
      grid_y,
      civic.footprint_w,
      civic.footprint_h,
    ) ||
    energy_valley_placement_overlaps(placed, civic, grid_x, grid_y) ||
    !energy_valley_footprint_is_buildable(seed, civic, grid_x, grid_y) ||
    (
      require_district &&
      !energy_valley_district_accepts(
        civic.district,
        seed,
        grid_x + civic.footprint_w / 2,
        grid_y + civic.footprint_h / 2,
      )
    ) {
    return None
  }
  Some({ grid_x, grid_y, entrance_x: entrance.x, entrance_y: entrance.y })
}

///|
fn energy_valley_placements_for_road(
  civic : WenyuTownModule,
  road_x : Int,
  road_y : Int,
  phase : Int,
) -> Array[(Int, Int, EnergyValleyPoint)] {
  let width_offset = energy_valley_mod(phase, civic.footprint_w)
  let height_offset = energy_valley_mod(phase, civic.footprint_h)
  [
    (road_x - width_offset, road_y + 1, { x: road_x, y: road_y }),
    (
      road_x - width_offset,
      road_y - civic.footprint_h,
      { x: road_x, y: road_y },
    ),
    (road_x + 1, road_y - height_offset, { x: road_x, y: road_y }),
    (
      road_x - civic.footprint_w,
      road_y - height_offset,
      { x: road_x, y: road_y },
    ),
  ]
}

///|
fn find_energy_valley_fallback_placement_near_anchor(
  seed : Int,
  civic : WenyuTownModule,
  placed : Array[EnergyValleyFootprint],
  anchor_x : Int,
  anchor_y : Int,
  phase : Int,
  flip_x : Bool,
  flip_y : Bool,
  require_district : Bool,
) -> EnergyValleyPlacement? {
  for radius in 0..<=42 {
    let span = radius * 2 + 1
    for y_index in 0..<span {
      for x_index in 0..<span {
        let raw_x = x_index - radius
        let raw_y = y_index - radius
        if radius > 0 && abs_int(raw_x) != radius && abs_int(raw_y) != radius {
          continue
        }
        let grid_x = anchor_x + (if flip_x { -raw_x } else { raw_x })
        let grid_y = anchor_y + (if flip_y { -raw_y } else { raw_y })
        match
          energy_valley_perimeter_road_entrance(
            seed, civic, grid_x, grid_y, phase,
          ) {
          Some(entrance) =>
            match
              energy_valley_candidate_placement(
                seed, civic, placed, grid_x, grid_y, entrance, require_district,
              ) {
              Some(placement) => return Some(placement)
              None => ()
            }
          None => ()
        }
      }
    }
  }
  None
}

///|
fn find_energy_valley_placement_near_anchor(
  seed : Int,
  civic : WenyuTownModule,
  placed : Array[EnergyValleyFootprint],
  index : Int,
  require_district : Bool,
) -> EnergyValleyPlacement? {
  let hash = energy_valley_module_anchor_hash(seed, civic, index)
  let anchor_x = civic.grid_x +
    energy_valley_signed_variation(seed, hash % 97, index, 167, 6)
  let anchor_y = civic.grid_y +
    energy_valley_signed_variation(seed, hash % 89, index, 173, 5)
  let flip_x = hash % 2 == 0
  let flip_y = hash / 2 % 2 == 0
  let phase = hash % 11
  if !reference_tile_snapshot_ready() {
    return find_energy_valley_fallback_placement_near_anchor(
      seed, civic, placed, anchor_x, anchor_y, phase, flip_x, flip_y, require_district,
    )
  }
  // Search the reference graph first, then fit the building to a side of the
  // discovered corridor. This keeps placement proportional to road distance
  // instead of scanning every possible lot against a sparse authored network.
  for radius in 0..<=42 {
    let span = radius * 2 + 1
    for y_index in 0..<span {
      for x_index in 0..<span {
        let raw_x = x_index - radius
        let raw_y = y_index - radius
        if radius > 0 && abs_int(raw_x) != radius && abs_int(raw_y) != radius {
          continue
        }
        let x_offset = if flip_x { -raw_x } else { raw_x }
        let y_offset = if flip_y { -raw_y } else { raw_y }
        let road_x = anchor_x + x_offset
        let road_y = anchor_y + y_offset
        if energy_valley_framework_road_at(seed, road_x, road_y) {
          for
            candidate in energy_valley_placements_for_road(
              civic, road_x, road_y, phase,
            ) {
            match
              energy_valley_candidate_placement(
                seed,
                civic,
                placed,
                candidate.0,
                candidate.1,
                candidate.2,
                require_district,
              ) {
              Some(placement) => return Some(placement)
              None => ()
            }
          }
        }
      }
    }
  }
  None
}

///|
fn find_energy_valley_placement(
  seed : Int,
  civic : WenyuTownModule,
  placed : Array[EnergyValleyFootprint],
  index : Int,
) -> EnergyValleyPlacement? {
  match
    find_energy_valley_placement_near_anchor(seed, civic, placed, index, true) {
    Some(placement) => Some(placement)
    None =>
      find_energy_valley_placement_near_anchor(
        seed, civic, placed, index, false,
      )
  }
}

///|
fn procedural_energy_valley_modules(
  templates : Array[WenyuTownModule],
  seed : Int,
) -> Array[WenyuTownModule] {
  let normalized = normalized_energy_valley_seed(seed)
  let result : Array[WenyuTownModule] = []
  let placed : Array[EnergyValleyFootprint] = []
  for index in 0..<templates.length() {
    let civic = templates[index]
    match find_energy_valley_placement(normalized, civic, placed, index) {
      Some(placement) => {
        let generated = {
          ..civic,
          grid_x: placement.grid_x,
          grid_y: placement.grid_y,
          entrance_x: placement.entrance_x,
          entrance_y: placement.entrance_y,
        }
        result.push(generated)
        placed.push({
          x: placement.grid_x,
          y: placement.grid_y,
          width: civic.footprint_w,
          height: civic.footprint_h,
        })
      }
      None => result.push(civic)
    }
  }
  result
}

///|
fn energy_valley_modules_are_collision_free(
  modules : Array[WenyuTownModule],
) -> Bool {
  for left_index in 0..<modules.length() {
    let left = modules[left_index]
    let left_footprint : EnergyValleyFootprint = {
      x: left.grid_x,
      y: left.grid_y,
      width: left.footprint_w,
      height: left.footprint_h,
    }
    for right_index in (left_index + 1)..<modules.length() {
      let right = modules[right_index]
      let right_footprint : EnergyValleyFootprint = {
        x: right.grid_x,
        y: right.grid_y,
        width: right.footprint_w,
        height: right.footprint_h,
      }
      if energy_valley_footprints_overlap(left_footprint, right_footprint) {
        return false
      }
    }
  }
  true
}

///|
fn energy_valley_module_has_road_entrance(
  seed : Int,
  civic : WenyuTownModule,
) -> Bool {
  energy_valley_road_at(seed, civic.entrance_x, civic.entrance_y) &&
  (
    (
      civic.entrance_x >= civic.grid_x &&
      civic.entrance_x < civic.grid_x + civic.footprint_w &&
      (
        civic.entrance_y == civic.grid_y - 1 ||
        civic.entrance_y == civic.grid_y + civic.footprint_h
      )
    ) ||
    (
      civic.entrance_y >= civic.grid_y &&
      civic.entrance_y < civic.grid_y + civic.footprint_h &&
      (
        civic.entrance_x == civic.grid_x - 1 ||
        civic.entrance_x == civic.grid_x + civic.footprint_w
      )
    )
  )
}
