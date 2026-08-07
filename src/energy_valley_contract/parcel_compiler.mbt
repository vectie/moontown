///|
/// The direction in which a block is divided into parcels. `LongestAxis`
/// keeps the authored outline authoritative while selecting the least narrow
/// subdivision for irregular Wenyu blocks.
pub(all) enum ParcelSplitAxis {
  LongestAxis
  VerticalBands
  HorizontalBands
} derive(Debug, Eq)

///|
/// The bounded grammar applied inside one authored land block.
pub(all) struct ParcelGrammar {
  target_count : Int
  split_axis : ParcelSplitAxis
  variation : PreservationLevel
  minimum_area_sqm : Double
} derive(Debug, Eq)

///|
pub fn parcel_grammar(
  target_count : Int,
  split_axis? : ParcelSplitAxis = LongestAxis,
  variation? : PreservationLevel = Bounded,
  minimum_area_sqm? : Double = 1.0,
) -> ParcelGrammar {
  { target_count, split_axis, variation, minimum_area_sqm }
}

///|
/// An authored block before parcel IDs and program assignments are compiled.
/// Its outer boundary and frontage list always survive compilation unchanged.
pub(all) struct LandBlockSeed {
  id : StableId
  boundary : Polygon
  land_use : LandUse
  frontage_segment_ids : ReadOnlyArray[StableId]
  preservation : PreservationLevel
  provenance : Provenance
  grammar : ParcelGrammar
  buildable_regions : ReadOnlyArray[BuildableRegion]
  parcelable : Bool
} derive(Debug, Eq)

///|
pub fn land_block_seed(
  id : StableId,
  boundary : Polygon,
  land_use : LandUse,
  frontage_segment_ids : ArrayView[StableId],
  preservation : PreservationLevel,
  provenance : Provenance,
  grammar : ParcelGrammar,
  buildable_regions? : ArrayView[BuildableRegion] = [],
  parcelable? : Bool = true,
) -> LandBlockSeed {
  {
    id,
    boundary,
    land_use,
    frontage_segment_ids: freeze(frontage_segment_ids),
    preservation,
    provenance,
    grammar,
    buildable_regions: freeze(buildable_regions),
    parcelable,
  }
}

///|
fn LandBlockSeed::effective_buildable_regions(
  self : LandBlockSeed,
) -> ReadOnlyArray[BuildableRegion] {
  if !self.parcelable {
    []
  } else if self.buildable_regions.is_empty() {
    [
      {
        id: self.id,
        boundary: self.boundary,
        land_use: self.land_use,
        provenance: self.provenance,
      },
    ]
  } else {
    self.buildable_regions
  }
}

///|
/// A semantic use that may be assigned to a compatible parcel. The catalog is
/// deliberately renderer-neutral: a later place compiler decides its visual
/// archetype from this stable program identity.
pub(all) struct ParcelProgram {
  id : StableId
  label : String
  compatible_land_uses : ReadOnlyArray[LandUse]
  minimum_area_sqm : Double
  maximum_area_sqm : Double?
  requires_frontage : Bool
  weight : Int
} derive(Debug, Eq)

///|
pub fn parcel_program(
  id : StableId,
  label : String,
  compatible_land_uses : ArrayView[LandUse],
  minimum_area_sqm? : Double = 0.0,
  maximum_area_sqm? : Double,
  requires_frontage? : Bool = false,
  weight? : Int = 100,
) -> ParcelProgram {
  {
    id,
    label,
    compatible_land_uses: freeze(compatible_land_uses),
    minimum_area_sqm,
    maximum_area_sqm,
    requires_frontage,
    weight,
  }
}

///|
/// The compiler-owned selection and placement seed for a parcel. A renderer or
/// place compiler can vary the building without inventing another land-use
/// decision or frontage relationship.
pub(all) struct ParcelProgramAssignment {
  id : StableId
  parcel_id : StableId
  program_id : StableId
  placement_anchor : WorldPoint
  frontage_segment_id : StableId?
  variant_seed : Int
  provenance : Provenance
} derive(Debug, Eq)

///|
/// Deterministic land-block, parcel, and program output. Its first two arrays
/// can be passed directly to `compiled_town_world`.
pub(all) struct ParcelPlan {
  compiler_version : String
  layout_seed : Int
  land_blocks : ReadOnlyArray[LandBlock]
  parcels : ReadOnlyArray[Parcel]
  programs : ReadOnlyArray[ParcelProgram]
  assignments : ReadOnlyArray[ParcelProgramAssignment]
} derive(Debug, Eq)

///|
pub fn ParcelPlan::find_assignment(
  self : ParcelPlan,
  parcel_id : StableId,
) -> ParcelProgramAssignment? {
  self.assignments
  .search_by(assignment => assignment.parcel_id == parcel_id)
  .map(index => self.assignments[index])
}

///|
pub fn ParcelPlan::find_program(
  self : ParcelPlan,
  program_id : StableId,
) -> ParcelProgram? {
  self.programs
  .search_by(program => program.id == program_id)
  .map(index => self.programs[index])
}

///|
pub fn ParcelPlan::parcels_for(
  self : ParcelPlan,
  block_id : StableId,
) -> ReadOnlyArray[Parcel] {
  self.parcels.filter(parcel => parcel.block_id == block_id)
}

///|
pub(all) enum ParcelCompileError {
  InvalidCompilerVersion
  DuplicateBlockId(StableId)
  DuplicateBuildableRegionId(StableId)
  DuplicateProgramId(StableId)
  InvalidBlockBoundary(StableId)
  InvalidBuildableRegion(StableId)
  InvalidParcelGrammar(StableId)
  InvalidProgram(StableId)
  MissingFrontageSegment(block_id~ : StableId, segment_id~ : StableId)
  GeneratedParcelTooSmall(block_id~ : StableId, parcel_index~ : Int)
  NoCompatibleProgram(StableId)
} derive(Debug, Eq)

///|
priv enum ParcelClipBoundary {
  MinimumX(Double)
  MaximumX(Double)
  MinimumY(Double)
  MaximumY(Double)
}

///|
priv struct PolygonBounds {
  minimum_x : Double
  maximum_x : Double
  minimum_y : Double
  maximum_y : Double
}

///|
fn polygon_bounds(value : Polygon) -> PolygonBounds {
  let first = value.vertices[0]
  let mut minimum_x = first.x
  let mut maximum_x = first.x
  let mut minimum_y = first.y
  let mut maximum_y = first.y
  for point in value.vertices {
    minimum_x = minimum_x.min(point.x)
    maximum_x = maximum_x.max(point.x)
    minimum_y = minimum_y.min(point.y)
    maximum_y = maximum_y.max(point.y)
  }
  { minimum_x, maximum_x, minimum_y, maximum_y }
}

///|
pub fn Polygon::area(self : Polygon) -> Double {
  if self.vertices.length() < 3 {
    return 0.0
  }
  let mut twice_area = 0.0
  for index in 0..<self.vertices.length() {
    let next = (index + 1) % self.vertices.length()
    twice_area = twice_area +
      self.vertices[index].x * self.vertices[next].y -
      self.vertices[next].x * self.vertices[index].y
  }
  twice_area.abs() / 2.0
}

///|
fn polygon_centroid(value : Polygon) -> WorldPoint {
  let mut weighted_x = 0.0
  let mut weighted_y = 0.0
  let mut weighted_z = 0.0
  let mut twice_area = 0.0
  for index in 0..<value.vertices.length() {
    let next = (index + 1) % value.vertices.length()
    let cross = value.vertices[index].x * value.vertices[next].y -
      value.vertices[next].x * value.vertices[index].y
    twice_area = twice_area + cross
    weighted_x = weighted_x +
      (value.vertices[index].x + value.vertices[next].x) * cross
    weighted_y = weighted_y +
      (value.vertices[index].y + value.vertices[next].y) * cross
    weighted_z = weighted_z +
      (value.vertices[index].z + value.vertices[next].z) * cross
  }
  if twice_area.abs() < 0.000001 {
    let first = value.vertices[0]
    return first
  }
  world_point(
    weighted_x / (3.0 * twice_area),
    weighted_y / (3.0 * twice_area),
    z=weighted_z / (3.0 * twice_area),
  )
}

///|
fn point_on_segment(
  point : WorldPoint,
  start : WorldPoint,
  end : WorldPoint,
) -> Bool {
  let cross = (point.y - start.y) * (end.x - start.x) -
    (point.x - start.x) * (end.y - start.y)
  if cross.abs() > 0.000001 {
    return false
  }
  let dot = (point.x - start.x) * (end.x - start.x) +
    (point.y - start.y) * (end.y - start.y)
  if dot < -0.000001 {
    return false
  }
  let squared_length = (end.x - start.x) * (end.x - start.x) +
    (end.y - start.y) * (end.y - start.y)
  dot <= squared_length + 0.000001
}

///|
/// Reports whether a point lies inside or on the authored polygon boundary.
pub fn Polygon::contains_point(self : Polygon, point : WorldPoint) -> Bool {
  if self.vertices.length() < 3 {
    return false
  }
  let mut inside = false
  let mut previous = self.vertices.length() - 1
  for current in 0..<self.vertices.length() {
    let a = self.vertices[previous]
    let b = self.vertices[current]
    if point_on_segment(point, a, b) {
      return true
    }
    if (a.y > point.y) != (b.y > point.y) {
      let intersection_x = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
      if point.x < intersection_x {
        inside = !inside
      }
    }
    previous = current
  }
  inside
}

///|
fn point_inside_clip(point : WorldPoint, boundary : ParcelClipBoundary) -> Bool {
  match boundary {
    MinimumX(value) => point.x >= value - 0.000001
    MaximumX(value) => point.x <= value + 0.000001
    MinimumY(value) => point.y >= value - 0.000001
    MaximumY(value) => point.y <= value + 0.000001
  }
}

///|
fn clip_intersection(
  start : WorldPoint,
  end : WorldPoint,
  boundary : ParcelClipBoundary,
) -> WorldPoint {
  let (numerator, denominator) = match boundary {
    MinimumX(value) | MaximumX(value) => (value - start.x, end.x - start.x)
    MinimumY(value) | MaximumY(value) => (value - start.y, end.y - start.y)
  }
  let ratio = if denominator.abs() < 0.000001 {
    0.0
  } else {
    numerator / denominator
  }
  world_point(
    start.x + (end.x - start.x) * ratio,
    start.y + (end.y - start.y) * ratio,
    z=start.z + (end.z - start.z) * ratio,
  )
}

///|
fn push_distinct(points : Array[WorldPoint], point : WorldPoint) -> Unit {
  match points.last() {
    Some(previous) if previous == point => ()
    _ => points.push(point)
  }
}

///|
fn clip_polygon(
  vertices : ArrayView[WorldPoint],
  boundary : ParcelClipBoundary,
) -> Array[WorldPoint] {
  let result : Array[WorldPoint] = []
  if vertices.is_empty() {
    return result
  }
  let mut previous = vertices[vertices.length() - 1]
  let mut previous_inside = point_inside_clip(previous, boundary)
  for current in vertices {
    let current_inside = point_inside_clip(current, boundary)
    match (previous_inside, current_inside) {
      (true, true) => push_distinct(result, current)
      (true, false) =>
        push_distinct(result, clip_intersection(previous, current, boundary))
      (false, true) => {
        push_distinct(result, clip_intersection(previous, current, boundary))
        push_distinct(result, current)
      }
      (false, false) => ()
    }
    previous = current
    previous_inside = current_inside
  }
  if result.length() > 1 && result[0] == result[result.length() - 1] {
    ignore(result.pop())
  }
  result
}

///|
fn deterministic_number(seed : Int, key : String) -> Int {
  let modulus = 1000003
  let mut hash = seed % modulus
  if hash < 0 {
    hash = hash + modulus
  }
  for char in key {
    hash = (hash * 131 + char.to_int() + 17) % modulus
  }
  hash
}

///|
fn variation_amplitude(level : PreservationLevel) -> Double {
  match level {
    Fixed => 0.0
    Bounded => 0.04
    Statistical => 0.12
    Free => 0.22
  }
}

///|
fn effective_seed(seed : Int, level : PreservationLevel) -> Int {
  match level {
    Fixed => 0
    _ => seed
  }
}

///|
fn parcel_cuts(
  minimum : Double,
  maximum : Double,
  count : Int,
  seed : Int,
  key : String,
  variation : PreservationLevel,
) -> Array[Double] {
  let result : Array[Double] = [minimum]
  let span = maximum - minimum
  let amplitude = variation_amplitude(variation)
  for index in 1..<count {
    let roll = deterministic_number(seed, "\{key}/cut/\{index}").to_double() /
      1000002.0
    let jitter_in_cells = (roll * 2.0 - 1.0) * amplitude
    let ratio = (index.to_double() + jitter_in_cells) / count.to_double()
    result.push(minimum + span * ratio)
  }
  result.push(maximum)
  result
}

///|
fn parcel_geometries_for_region(
  block : LandBlockSeed,
  region : BuildableRegion,
  target_count : Int,
  seed : Int,
) -> Array[Polygon] {
  let bounds = polygon_bounds(region.boundary)
  let width = bounds.maximum_x - bounds.minimum_x
  let height = bounds.maximum_y - bounds.minimum_y
  let vertical = match block.grammar.split_axis {
    LongestAxis => width >= height
    VerticalBands => true
    HorizontalBands => false
  }
  let cuts = if vertical {
    parcel_cuts(
      bounds.minimum_x,
      bounds.maximum_x,
      target_count,
      seed,
      region.id.to_string(),
      block.grammar.variation,
    )
  } else {
    parcel_cuts(
      bounds.minimum_y,
      bounds.maximum_y,
      target_count,
      seed,
      region.id.to_string(),
      block.grammar.variation,
    )
  }
  let result : Array[Polygon] = []
  for index in 0..<target_count {
    let first_clip = if vertical {
      clip_polygon(region.boundary.vertices, MinimumX(cuts[index]))
    } else {
      clip_polygon(region.boundary.vertices, MinimumY(cuts[index]))
    }
    let second_clip = if vertical {
      clip_polygon(first_clip, MaximumX(cuts[index + 1]))
    } else {
      clip_polygon(first_clip, MaximumY(cuts[index + 1]))
    }
    result.push(polygon(second_clip))
  }
  result
}

///|
priv struct CompiledParcelGeometry {
  boundary : Polygon
  land_use : LandUse
  region_id : StableId
  index_in_region : Int
  legacy_single_region : Bool
}

///|
fn compiled_parcel_geometries(
  block : LandBlockSeed,
  seed : Int,
) -> Array[CompiledParcelGeometry] {
  let regions : Array[BuildableRegion] = []
  for region in block.effective_buildable_regions() {
    regions.push(region)
  }
  if regions.is_empty() {
    return []
  }
  regions.sort_by((left, right) => {
    left.id.to_string().compare(right.id.to_string())
  })
  let effective_target_count = block.grammar.target_count.max(regions.length())
  let counts = Array::make(regions.length(), 1)
  for extra in 0..<(effective_target_count - regions.length()) {
    let index = extra % regions.length()
    counts[index] = counts[index] + 1
  }
  let result : Array[CompiledParcelGeometry] = []
  for region_index, region in regions {
    let geometries = parcel_geometries_for_region(
      block,
      region,
      counts[region_index],
      seed,
    )
    for index, boundary in geometries {
      result.push({
        boundary,
        land_use: region.land_use,
        region_id: region.id,
        index_in_region: index,
        legacy_single_region: block.buildable_regions.is_empty(),
      })
    }
  }
  result
}

///|
fn segment_reference_point(segment : RoadSegment) -> WorldPoint {
  let first = segment.centerline[0]
  let last = segment.centerline[segment.centerline.length() - 1]
  world_point(
    (first.x + last.x) / 2.0,
    (first.y + last.y) / 2.0,
    z=(first.z + last.z) / 2.0,
  )
}

///|
fn squared_distance(first : WorldPoint, second : WorldPoint) -> Double {
  let dx = first.x - second.x
  let dy = first.y - second.y
  dx * dx + dy * dy
}

///|
fn parcel_frontages(
  block : LandBlockSeed,
  geometries : ArrayView[Polygon],
  network : RoadNetwork,
) -> Result[Array[Array[StableId]], ParcelCompileError] {
  let result : Array[Array[StableId]] = []
  for _ in 0..<geometries.length() {
    result.push([])
  }
  if geometries.is_empty() {
    return Ok(result)
  }
  for segment_id in block.frontage_segment_ids {
    let segment = match network.find_segment(segment_id) {
      Some(value) => value
      None => return Err(MissingFrontageSegment(block_id=block.id, segment_id~))
    }
    let reference = segment_reference_point(segment)
    let mut nearest_index = 0
    let mut nearest_distance = squared_distance(
      polygon_centroid(geometries[0]),
      reference,
    )
    for index in 1..<geometries.length() {
      let distance = squared_distance(
        polygon_centroid(geometries[index]),
        reference,
      )
      if distance < nearest_distance {
        nearest_index = index
        nearest_distance = distance
      }
    }
    result[nearest_index].push(segment_id)
  }
  Ok(result)
}

///|
fn program_is_valid(program : ParcelProgram) -> Bool {
  let maximum_is_valid = match program.maximum_area_sqm {
    Some(maximum) => maximum >= program.minimum_area_sqm
    None => true
  }
  !program.label.trim().is_empty() &&
  !program.compatible_land_uses.is_empty() &&
  program.minimum_area_sqm >= 0.0 &&
  maximum_is_valid &&
  program.weight > 0
}

///|
fn program_is_compatible(
  program : ParcelProgram,
  land_use : LandUse,
  area : Double,
  has_frontage : Bool,
) -> Bool {
  let below_maximum = match program.maximum_area_sqm {
    Some(maximum) => area <= maximum
    None => true
  }
  program.compatible_land_uses.contains(land_use) &&
  area >= program.minimum_area_sqm &&
  below_maximum &&
  (!program.requires_frontage || has_frontage)
}

///|
fn choose_program(
  candidates : ArrayView[ParcelProgram],
  seed : Int,
  parcel_id : StableId,
) -> ParcelProgram {
  let mut total_weight = 0
  for program in candidates {
    total_weight = total_weight + program.weight
  }
  let roll = deterministic_number(seed, "\{parcel_id.to_string()}/program") %
    total_weight
  let mut cumulative = 0
  for program in candidates {
    cumulative = cumulative + program.weight
    if roll < cumulative {
      return program
    }
  }
  candidates[candidates.length() - 1]
}

///|
fn generated_id(scope : String, key : String) -> StableId {
  stable_id(scope, key).unwrap()
}

///|
fn generated_provenance(
  compiler_version : String,
  preservation : PreservationLevel,
) -> Provenance {
  provenance(
    "energy-valley-parcel-compiler",
    compiler_version,
    Derived,
    preservation,
  )
}

///|
/// Compiles Wenyu-authored land blocks into deterministic semantic parcels and
/// program assignments. Input order never affects output order or selection.
/// The authored block boundary is retained byte-for-byte; generated parcel
/// polygons are clipped to that boundary and can never extend beyond it.
pub fn compile_parcel_plan(
  compiler_version : String,
  layout_seed : Int,
  road_network : RoadNetwork,
  block_seeds : ArrayView[LandBlockSeed],
  programs : ArrayView[ParcelProgram],
) -> Result[ParcelPlan, ParcelCompileError] {
  if compiler_version.trim().is_empty() {
    return Err(InvalidCompilerVersion)
  }
  let sorted_blocks = block_seeds.to_owned()
  sorted_blocks.sort_by((left, right) => {
    left.id.to_string().compare(right.id.to_string())
  })
  let sorted_programs = programs.to_owned()
  sorted_programs.sort_by((left, right) => {
    left.id.to_string().compare(right.id.to_string())
  })
  let seen_blocks : Map[StableId, Unit] = Map([])
  let seen_regions : Map[StableId, Unit] = Map([])
  for block in sorted_blocks {
    if seen_blocks.contains(block.id) {
      return Err(DuplicateBlockId(block.id))
    }
    seen_blocks[block.id] = ()
    if !block.boundary.is_well_formed() || block.boundary.area() <= 0.0 {
      return Err(InvalidBlockBoundary(block.id))
    }
    for region in block.buildable_regions {
      if seen_regions.contains(region.id) {
        return Err(DuplicateBuildableRegionId(region.id))
      }
      seen_regions[region.id] = ()
      if !region.boundary.is_well_formed() ||
        region.boundary.area() <= 0.0 ||
        !region.boundary.vertices.all(point => {
          block.boundary.contains_point(point)
        }) {
        return Err(InvalidBuildableRegion(region.id))
      }
    }
    if block.parcelable &&
      (block.grammar.target_count <= 0 || block.grammar.minimum_area_sqm <= 0.0) {
      return Err(InvalidParcelGrammar(block.id))
    }
  }
  let seen_programs : Map[StableId, Unit] = Map([])
  for program in sorted_programs {
    if seen_programs.contains(program.id) {
      return Err(DuplicateProgramId(program.id))
    }
    seen_programs[program.id] = ()
    if !program_is_valid(program) {
      return Err(InvalidProgram(program.id))
    }
  }
  let compiled_blocks : Array[LandBlock] = []
  let compiled_parcels : Array[Parcel] = []
  let assignments : Array[ParcelProgramAssignment] = []
  for block in sorted_blocks {
    let grammar_seed = effective_seed(layout_seed, block.grammar.variation)
    let geometries = compiled_parcel_geometries(block, grammar_seed)
    for index, geometry in geometries {
      if !geometry.boundary.is_well_formed() ||
        geometry.boundary.area() < block.grammar.minimum_area_sqm {
        return Err(
          GeneratedParcelTooSmall(block_id=block.id, parcel_index=index),
        )
      }
    }
    let boundaries = geometries.map(geometry => geometry.boundary)
    let frontages = match parcel_frontages(block, boundaries, road_network) {
      Ok(value) => value
      Err(error) => return Err(error)
    }
    let parcel_ids : Array[StableId] = []
    for index, geometry in geometries {
      let key = if geometry.legacy_single_region {
        "\{block.id.to_string()}/\{index + 1}"
      } else {
        "\{block.id.to_string()}/\{geometry.region_id.local_key()}/\{geometry.index_in_region + 1}"
      }
      parcel_ids.push(generated_id("parcel", key))
    }
    compiled_blocks.push(
      land_block(
        block.id,
        block.boundary,
        block.land_use,
        parcel_ids,
        block.frontage_segment_ids,
        block.preservation,
        block.provenance,
        buildable_regions=block.buildable_regions,
        parcelable=block.parcelable,
      ),
    )
    let parcel_source = generated_provenance(
      compiler_version,
      block.grammar.variation,
    )
    for index, geometry in geometries {
      let parcel_id = parcel_ids[index]
      let area = geometry.boundary.area()
      let compatible_programs = sorted_programs.filter(program => {
        program_is_compatible(
          program,
          geometry.land_use,
          area,
          !frontages[index].is_empty(),
        )
      })
      if compatible_programs.is_empty() {
        return Err(NoCompatibleProgram(parcel_id))
      }
      let allowed_programs = compatible_programs.map(program => {
        program.id.to_string()
      })
      let compiled_parcel = parcel(
        parcel_id,
        block.id,
        geometry.boundary,
        geometry.land_use,
        frontages[index],
        allowed_programs,
        block.grammar.variation,
        parcel_source,
      )
      compiled_parcels.push(compiled_parcel)
      let selected = choose_program(
        compatible_programs, grammar_seed, parcel_id,
      )
      let assignment_id = generated_id(
        "program-assignment",
        parcel_id.to_string(),
      )
      assignments.push({
        id: assignment_id,
        parcel_id,
        program_id: selected.id,
        placement_anchor: polygon_centroid(geometry.boundary),
        frontage_segment_id: frontages[index].get(0),
        variant_seed: deterministic_number(
          grammar_seed,
          "\{parcel_id.to_string()}/variant",
        ),
        provenance: parcel_source,
      })
    }
  }
  Ok({
    compiler_version,
    layout_seed,
    land_blocks: freeze(compiled_blocks),
    parcels: freeze(compiled_parcels),
    programs: freeze(sorted_programs),
    assignments: freeze(assignments),
  })
}
