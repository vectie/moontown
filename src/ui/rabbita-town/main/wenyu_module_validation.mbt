///|
fn module_allows_water_or_bridge(civic : WenyuTownModule) -> Bool {
  civic.building_kind == "physical-bridge" ||
  civic.district.contains("river") ||
  civic.district.contains("harbor")
}

///|
fn module_anchor_tile_kind(civic : WenyuTownModule) -> String {
  tile_kind_at(civic.grid_x, civic.grid_y)
}

///|
fn module_entrance_tile_kind(civic : WenyuTownModule) -> String {
  tile_kind_at(civic.entrance_x, civic.entrance_y)
}

///|
fn module_tile_blocks_building(kind : String, civic : WenyuTownModule) -> Bool {
  if module_allows_water_or_bridge(civic) {
    false
  } else {
    kind == "river" ||
    kind == "lake" ||
    kind == "wetland" ||
    kind == "bridge" ||
    kind == "road" ||
    kind == "road-major"
  }
}

///|
fn module_tile_blocks_entrance(kind : String, civic : WenyuTownModule) -> Bool {
  if module_allows_water_or_bridge(civic) {
    false
  } else {
    kind == "river" || kind == "lake" || kind == "wetland"
  }
}

///|
fn module_corner_tile_blocks(civic : WenyuTownModule) -> Array[String] {
  let blocked : Array[String] = []
  let corners = [
    (civic.grid_x, civic.grid_y),
    (civic.grid_x + civic.footprint_w - 1, civic.grid_y),
    (civic.grid_x, civic.grid_y + civic.footprint_h - 1),
    (civic.grid_x + civic.footprint_w - 1, civic.grid_y + civic.footprint_h - 1),
  ]
  for corner in corners {
    let kind = tile_kind_at(corner.0, corner.1)
    if module_tile_blocks_building(kind, civic) {
      blocked.push("\{corner.0},\{corner.1} on \{kind}")
    }
  }
  blocked
}

///|
fn module_validation_issues(civic : WenyuTownModule) -> Array[String] {
  let issues : Array[String] = []
  if civic.book_id == "" {
    issues.push("missing book_id")
  }
  if civic.asset_base == "" {
    issues.push("missing asset_base")
  }
  if civic.footprint_w <= 0 || civic.footprint_h <= 0 {
    issues.push("invalid footprint")
  }
  if civic.display_w <= 0 || civic.display_h <= 0 {
    issues.push("invalid display size")
  }
  if civic.style_family == "" {
    issues.push("missing style_family")
  }
  if civic.protocol_pattern == "" {
    issues.push("missing protocol_pattern")
  }
  let anchor_kind = module_anchor_tile_kind(civic)
  if module_tile_blocks_building(anchor_kind, civic) {
    issues.push("anchor on \{anchor_kind}")
  }
  let corner_blocks = module_corner_tile_blocks(civic)
  if !corner_blocks.is_empty() {
    issues.push("footprint overlap \{corner_blocks.join("; ")}")
  }
  let entrance_kind = module_entrance_tile_kind(civic)
  if module_tile_blocks_entrance(entrance_kind, civic) {
    issues.push("entrance on \{entrance_kind}")
  }
  issues
}

///|
fn wenyu_clean_module_count() -> Int {
  let mut count = 0
  for civic in wenyu_modules() {
    if module_validation_issues(civic).is_empty() {
      count += 1
    }
  }
  count
}
