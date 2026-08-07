///|
/// Converts a compatibility bridge identity (`scope/key`) into the opaque,
/// target-neutral ID owned by the pure-MoonBit ecosystem contract.
fn ecosystem_contract_id(value : String) -> @energy_valley_contract.StableId {
  match value.split_once("/") {
    Some((scope, key)) =>
      @energy_valley_contract.stable_id(scope.to_owned(), key.to_owned()).unwrap()
    None => @energy_valley_contract.stable_id("legacy", value).unwrap()
  }
}

///|
fn ecosystem_contract_scoped_id(
  scope : String,
  key : String,
) -> @energy_valley_contract.StableId {
  @energy_valley_contract.stable_id(scope, key).unwrap()
}

///|
fn ecosystem_contract_provenance(
  is_local_delta : Bool,
) -> @energy_valley_contract.Provenance {
  if is_local_delta {
    @energy_valley_contract.provenance(
      "moontown-local-map-delta",
      "v1",
      @energy_valley_contract.UserDelta,
      @energy_valley_contract.Free,
    )
  } else {
    @energy_valley_contract.provenance(
      "wenyu-reference",
      "2026-07-27",
      @energy_valley_contract.WenyuReference,
      @energy_valley_contract.Bounded,
    )
  }
}

///|
fn ecosystem_contract_derived_provenance(
  is_local_delta : Bool,
) -> @energy_valley_contract.Provenance {
  if is_local_delta {
    ecosystem_contract_provenance(true)
  } else {
    @energy_valley_contract.provenance(
      "wenyu-ecosystem-compiler",
      "v1",
      @energy_valley_contract.Derived,
      @energy_valley_contract.Bounded,
    )
  }
}

///|
fn ecosystem_contract_point(
  point : EcosystemGridPoint,
) -> @energy_valley_contract.WorldPoint {
  @energy_valley_contract.world_point(point.x.to_double(), point.y.to_double())
}

///|
fn ecosystem_contract_footprint(
  footprint : EcosystemFootprint,
) -> @energy_valley_contract.Polygon {
  let left = footprint.x.to_double()
  let top = footprint.y.to_double()
  let right = (footprint.x + footprint.width.max(1)).to_double()
  let bottom = (footprint.y + footprint.depth.max(1)).to_double()
  @energy_valley_contract.polygon([
    @energy_valley_contract.world_point(left, top),
    @energy_valley_contract.world_point(right, top),
    @energy_valley_contract.world_point(right, bottom),
    @energy_valley_contract.world_point(left, bottom),
  ])
}

///|
fn ecosystem_contract_road_class(
  road : EcosystemRoadCell,
) -> @energy_valley_contract.RoadClass {
  if road.bridge {
    @energy_valley_contract.Bridge
  } else {
    match road.road_class {
      "major" | "M" => @energy_valley_contract.Arterial
      "service" => @energy_valley_contract.Service
      "footpath" | "boardwalk" => @energy_valley_contract.Footpath
      "custom" => @energy_valley_contract.Local
      _ => @energy_valley_contract.Collector
    }
  }
}

///|
fn ecosystem_contract_road_width(road : EcosystemRoadCell) -> Double {
  match ecosystem_contract_road_class(road) {
    @energy_valley_contract.Arterial => 18.0
    @energy_valley_contract.Collector => 12.0
    @energy_valley_contract.Local => 8.0
    @energy_valley_contract.Service => 6.0
    @energy_valley_contract.Footpath => 3.0
    @energy_valley_contract.Bridge => 12.0
  }
}

///|
/// A segment belongs to both endpoint cells. Preserve the stronger authored
/// class so a bridge or arterial cannot disappear merely because row-major
/// compilation visited its quieter neighbor first.
fn ecosystem_contract_segment_road_class(
  first : EcosystemRoadCell,
  second : EcosystemRoadCell,
) -> @energy_valley_contract.RoadClass {
  let first_class = ecosystem_contract_road_class(first)
  let second_class = ecosystem_contract_road_class(second)
  if first_class is @energy_valley_contract.Bridge ||
    second_class is @energy_valley_contract.Bridge {
    @energy_valley_contract.Bridge
  } else if first_class is @energy_valley_contract.Arterial ||
    second_class is @energy_valley_contract.Arterial {
    @energy_valley_contract.Arterial
  } else if first_class is @energy_valley_contract.Collector ||
    second_class is @energy_valley_contract.Collector {
    @energy_valley_contract.Collector
  } else if first_class is @energy_valley_contract.Local ||
    second_class is @energy_valley_contract.Local {
    @energy_valley_contract.Local
  } else if first_class is @energy_valley_contract.Service ||
    second_class is @energy_valley_contract.Service {
    @energy_valley_contract.Service
  } else {
    @energy_valley_contract.Footpath
  }
}

///|
fn ecosystem_contract_segment_road_width(
  first : EcosystemRoadCell,
  second : EcosystemRoadCell,
) -> Double {
  ecosystem_contract_road_width(first).max(
    ecosystem_contract_road_width(second),
  )
}

///|
/// Compile the authored/user road-cell collection once, before any entrance
/// candidate is discovered. The returned graph deliberately has no access
/// anchors or pedestrian spurs yet; those depend on the portals found against
/// this exact node set and are appended during final world compilation.
fn ecosystem_contract_base_road_network(
  roads : ArrayView[EcosystemRoadCell],
) -> @energy_valley_contract.RoadNetwork {
  let road_lookup : Map[String, EcosystemRoadCell] = Map([])
  let nodes : Array[@energy_valley_contract.RoadNode] = []
  let segments : Array[@energy_valley_contract.RoadSegment] = []
  for road in roads {
    road_lookup[golden_valley_tile_key(road.x, road.y)] = road
    nodes.push(
      @energy_valley_contract.road_node(
        ecosystem_contract_id(road.id),
        @energy_valley_contract.grid_position(road.x, road.y),
        @energy_valley_contract.world_point(
          road.x.to_double() + 0.5,
          road.y.to_double() + 0.5,
        ),
        ecosystem_contract_provenance(road.custom),
      ),
    )
  }
  for road in roads {
    for delta in [(1, 0), (0, 1)] {
      match
        road_lookup.get(
          golden_valley_tile_key(road.x + delta.0, road.y + delta.1),
        ) {
        None => ()
        Some(next) => {
          let is_local_delta = road.custom || next.custom
          segments.push(
            @energy_valley_contract.road_segment(
              ecosystem_contract_scoped_id(
                "road-segment",
                "\{road.x}-\{road.y}-\{next.x}-\{next.y}",
              ),
              ecosystem_contract_id(road.id),
              ecosystem_contract_id(next.id),
              [
                @energy_valley_contract.world_point(
                  road.x.to_double() + 0.5,
                  road.y.to_double() + 0.5,
                ),
                @energy_valley_contract.world_point(
                  next.x.to_double() + 0.5,
                  next.y.to_double() + 0.5,
                ),
              ],
              ecosystem_contract_segment_road_class(road, next),
              ecosystem_contract_segment_road_width(road, next),
              [
                @energy_valley_contract.Pedestrian,
                @energy_valley_contract.Bicycle,
                @energy_valley_contract.ServiceVehicle,
              ],
              ecosystem_contract_derived_provenance(is_local_delta),
            ),
          )
        }
      }
    }
  }
  @energy_valley_contract.road_network(nodes, segments, [])
}

///|
fn ecosystem_contract_place_kind(
  place : EcosystemPlace,
  accessible : Bool,
) -> @energy_valley_contract.PlaceKind {
  match place.kind {
    EcosystemCivicBuilding
    | EcosystemAmbientBuilding
    | EcosystemCustomBuilding => @energy_valley_contract.Building
    EcosystemMetroStation =>
      if accessible {
        @energy_valley_contract.TransitStation
      } else {
        @energy_valley_contract.Landmark
      }
    EcosystemPublicRealm =>
      if place.style.contains("park") || place.style.contains("garden") {
        @energy_valley_contract.Park
      } else {
        @energy_valley_contract.Plaza
      }
    EcosystemLandmark => @energy_valley_contract.Landmark
  }
}

///|
fn ecosystem_contract_building_floors(place : EcosystemPlace) -> Int {
  for item in place.traits {
    if item.key == "floors" {
      let mut parsed = 0
      let mut valid = !item.value.is_empty()
      for char in item.value {
        if char < '0' || char > '9' {
          valid = false
          break
        }
        parsed = parsed * 10 + char.to_int() - '0'.to_int()
      }
      if valid && parsed > 0 {
        return parsed
      }
    }
  }
  match place.style {
    "tower" | "custom-tower" => 6
    "block" | "civic" => 4
    "campus" | "industrial" | "custom-lab" => 3
    "row" | "courtyard" | "lowrise" | "home" | "custom-home" => 2
    _ => 1
  }
}

///|
fn ecosystem_contract_roof(
  place : EcosystemPlace,
) -> @energy_valley_contract.RoofKind {
  match place.style {
    "garden" | "campus" => @energy_valley_contract.Garden
    "home" | "row" | "courtyard" | "custom-home" =>
      @energy_valley_contract.Gabled
    "tower" | "radar" | "custom-tower" => @energy_valley_contract.Glass
    _ => @energy_valley_contract.Flat
  }
}

///|
fn ecosystem_contract_program_roof(
  place : EcosystemPlace,
  program : @energy_valley_contract.ParcelProgram?,
) -> @energy_valley_contract.RoofKind {
  match program {
    Some(selected) =>
      match selected.id.local_key() {
        "research-garden" | "park-commons" | "waterfront-walk" =>
          @energy_valley_contract.Garden
        "street-homes" | "residential-court" => @energy_valley_contract.Gabled
        "research-lab" | "transit-hall" => @energy_valley_contract.Glass
        "valley-market" | "waterfront-pavilion" =>
          @energy_valley_contract.Sculptural
        _ => ecosystem_contract_roof(place)
      }
    None => ecosystem_contract_roof(place)
  }
}

///|
fn ecosystem_contract_place_traits(
  place : EcosystemPlace,
  accessible : Bool,
) -> Array[@energy_valley_contract.PlaceTrait] {
  let result : Array[@energy_valley_contract.PlaceTrait] = []
  let program = ecosystem_program_trait(place.style, place.runtime.runtime_key)
  if accessible {
    result.push(@energy_valley_contract.Accessible)
  }
  if program == "social" ||
    program == "residential" ||
    place.kind is EcosystemPublicRealm {
    result.push(@energy_valley_contract.Social)
  }
  if place.style == "garden" ||
    place.style == "plaza" ||
    place.style == "market" ||
    place.style == "radar" {
    result.push(@energy_valley_contract.Playful)
  }
  if place.district.contains("water") || place.style.contains("water") {
    result.push(@energy_valley_contract.Waterfront)
  }
  if program == "research" || program == "workplace" {
    result.push(@energy_valley_contract.KnowledgeWork)
  }
  if place.runtime.runtime_key is Some(_) {
    result.push(@energy_valley_contract.RuntimeWork)
  }
  match place.kind {
    EcosystemLandmark | EcosystemMetroStation =>
      result.push(@energy_valley_contract.Landmark)
    _ => ()
  }
  result
}

///|
fn ecosystem_contract_interaction_kind(
  kind : EcosystemAffordanceKind,
) -> @energy_valley_contract.InteractionKind {
  match kind {
    EcosystemWork => @energy_valley_contract.Workstation
    EcosystemExchange => @energy_valley_contract.ExchangeDesk
    EcosystemRest => @energy_valley_contract.Bench
    EcosystemPublish | EcosystemObserve => @energy_valley_contract.Exhibit
    EcosystemTravel | EcosystemEnter => @energy_valley_contract.TransitGate
    EcosystemGather => @energy_valley_contract.MeetingPoint
    EcosystemInspect => @energy_valley_contract.ServicePoint
  }
}

///|
fn ecosystem_contract_runtime_binding(
  place : EcosystemPlace,
) -> @energy_valley_contract.RuntimeBinding? {
  match place.runtime.runtime_key {
    None => None
    Some(key) =>
      Some(
        @energy_valley_contract.runtime_binding(
          @energy_valley_contract.TownRuntime,
          key,
          "semantic-place",
        ),
      )
  }
}

///|
fn ecosystem_contract_place_attention_base(place : EcosystemPlace) -> Int {
  let kind_base = match place.kind {
    EcosystemCivicBuilding => 64
    EcosystemAmbientBuilding => 34
    EcosystemCustomBuilding => 56
    EcosystemMetroStation => 68
    EcosystemPublicRealm => 48
    EcosystemLandmark => 76
  }
  let style_boost = match place.style {
    "tower" | "radar" => 18
    "garden" | "plaza" | "waterway" => 14
    _ => 0
  }
  (kind_base + style_boost).clamp(min=0, max=100)
}

///|
fn ecosystem_contract_frontage_for_entrance(
  snapshot : EcosystemWorldSnapshot,
  entrance_id : String,
) -> EcosystemRoadFrontage? {
  for frontage in snapshot.road_frontages {
    if frontage.entrance_id == entrance_id {
      return Some(frontage)
    }
  }
  None
}

///|
fn ecosystem_contract_spur_node_id(
  spur : EcosystemPedestrianSpur,
  index : Int,
) -> @energy_valley_contract.StableId {
  ecosystem_contract_scoped_id("pedestrian-node", "\{spur.id}-\{index}")
}

///|
/// Computes the pedestrian component reachable from all typed world gateways
/// once per compilation. Doorway validation can then use constant-time
/// membership instead of traversing the full Wenyu graph for every building.
fn ecosystem_contract_gateway_connected_nodes(
  road_network : @energy_valley_contract.RoadNetwork,
) -> Map[@energy_valley_contract.StableId, Bool] {
  let adjacency : Map[
    @energy_valley_contract.StableId,
    Array[@energy_valley_contract.StableId],
  ] = Map([])
  for node in road_network.nodes {
    adjacency[node.id] = []
  }
  for segment in road_network.segments {
    if !segment.mobility.any(mode => mode is @energy_valley_contract.Pedestrian) {
      continue
    }
    match adjacency.get(segment.from_node_id) {
      Some(neighbors) => neighbors.push(segment.to_node_id)
      None => ()
    }
    match adjacency.get(segment.to_node_id) {
      Some(neighbors) => neighbors.push(segment.from_node_id)
      None => ()
    }
  }
  let connected : Map[@energy_valley_contract.StableId, Bool] = Map([])
  let queue : Array[@energy_valley_contract.StableId] = []
  for anchor in road_network.access_anchor_node_ids {
    if adjacency.contains(anchor) && !connected.contains(anchor) {
      connected[anchor] = true
      queue.push(anchor)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let node_id = queue[cursor]
    cursor += 1
    match adjacency.get(node_id) {
      None => ()
      Some(neighbors) =>
        for neighbor in neighbors {
          if !connected.contains(neighbor) {
            connected[neighbor] = true
            queue.push(neighbor)
          }
        }
    }
  }
  connected
}

///|
fn ecosystem_contract_portals(
  snapshot : EcosystemWorldSnapshot,
  place : EcosystemPlace,
  gateway_connected_nodes : Map[@energy_valley_contract.StableId, Bool],
) -> Array[@energy_valley_contract.EntrancePortal] {
  let result : Array[@energy_valley_contract.EntrancePortal] = []
  let entrances = snapshot.entrances.filter(entrance => {
    entrance.place_id == place.id
  })
  let mut authored_primary_index = -1
  let mut first_reachable_index = -1
  let mut reachable_authored_primary_index = -1
  for index, entrance in entrances {
    let frontage = ecosystem_contract_frontage_for_entrance(
      snapshot,
      entrance.id,
    )
    let spur = ecosystem_pedestrian_spur_for_entrance(snapshot, entrance.id)
    let candidate_road_node_id = match spur {
      Some(path) if path.path.length() >= 2 =>
        Some(ecosystem_contract_spur_node_id(path, 0))
      _ =>
        match frontage {
          Some(link) => Some(ecosystem_contract_id(link.road_cell_id))
          None => None
        }
    }
    // A frontage cell is not proof of public access. Local edits can isolate a
    // formerly connected component, so publish a binding only when the same
    // graph used by navigation reaches a typed external/metro gateway.
    let road_node_id = match candidate_road_node_id {
      Some(node_id) if gateway_connected_nodes.contains(node_id) =>
        Some(node_id)
      _ => None
    }
    if entrance.primary && authored_primary_index < 0 {
      authored_primary_index = index
    }
    if road_node_id is Some(_) {
      if first_reachable_index < 0 {
        first_reachable_index = index
      }
      if entrance.primary && reachable_authored_primary_index < 0 {
        reachable_authored_primary_index = index
      }
    }
    result.push(
      @energy_valley_contract.entrance_portal(
        ecosystem_contract_id(entrance.id),
        ecosystem_contract_point(entrance.threshold),
        road_node_id,
        [@energy_valley_contract.Pedestrian],
        primary=false,
      ),
    )
  }
  if !result.is_empty() {
    // Prefer the authored main door while it remains usable. If a local delta
    // severs only that frontage, promote the first reachable secondary door so
    // `Accessible` and `primary_entrance()` cannot disagree. A fully sealed
    // place keeps one inspectable authored threshold, but no road binding.
    let primary_index = if reachable_authored_primary_index >= 0 {
      reachable_authored_primary_index
    } else if first_reachable_index >= 0 {
      first_reachable_index
    } else if authored_primary_index >= 0 {
      authored_primary_index
    } else {
      0
    }
    for index in 0..<result.length() {
      result[index] = { ..result[index], primary: index == primary_index }
    }
  }
  result
}

///|
fn ecosystem_contract_slots(
  snapshot : EcosystemWorldSnapshot,
  place : EcosystemPlace,
  accessible : Bool,
) -> Array[@energy_valley_contract.InteractionSlot] {
  let result : Array[@energy_valley_contract.InteractionSlot] = []
  let access_controlled = match place.kind {
    EcosystemCivicBuilding
    | EcosystemAmbientBuilding
    | EcosystemCustomBuilding
    | EcosystemMetroStation => true
    _ => false
  }
  for affordance in ecosystem_affordances_for_place(snapshot, place.id) {
    if !affordance.enabled ||
      (
        access_controlled &&
        !accessible &&
        !(affordance.kind is EcosystemInspect)
      ) {
      continue
    }
    result.push(
      @energy_valley_contract.interaction_slot(
        ecosystem_contract_id(affordance.id),
        ecosystem_contract_interaction_kind(affordance.kind),
        ecosystem_story_affordance_label(affordance.kind),
        ecosystem_contract_point(affordance.anchor),
        affordance.capacity.max(1),
        None,
        ecosystem_contract_runtime_binding(place),
      ),
    )
  }
  result
}

///|
fn ecosystem_contract_place_id_from_profile(
  profile_id : String,
) -> @energy_valley_contract.StableId {
  let normalized = ecosystem_story_relation_identity(profile_id)
  ecosystem_contract_scoped_id("place", "civic-\{normalized}")
}

///|
fn ecosystem_contract_attention_target_id(
  place_id : @energy_valley_contract.StableId,
) -> @energy_valley_contract.StableId {
  ecosystem_contract_scoped_id(
    "attention-target",
    "place-\{place_id.local_key()}",
  )
}

///|
/// Binds a rendered place only when its complete authored footprint is inside
/// one compiler-owned parcel. A center-point match is insufficient: it would
/// allow a building to straddle a road or neighboring program while still
/// validating as aligned.
fn ecosystem_contract_parcel_for_place(
  plan : @energy_valley_contract.ParcelPlan,
  place : EcosystemPlace,
) -> @energy_valley_contract.Parcel? {
  let footprint = ecosystem_contract_footprint(place.footprint)
  for parcel in plan.parcels {
    if footprint.vertices.all(vertex => parcel.boundary.contains_point(vertex)) {
      return Some(parcel)
    }
  }
  None
}

///|
fn ecosystem_contract_program_slot_kind(
  program : @energy_valley_contract.ParcelProgram,
) -> @energy_valley_contract.InteractionKind {
  match program.id.local_key() {
    "civic-hall" | "transit-hall" => @energy_valley_contract.ServicePoint
    "civic-court" | "residential-court" | "mixed-court" =>
      @energy_valley_contract.MeetingPoint
    "research-lab" => @energy_valley_contract.Workstation
    "research-garden" | "park-commons" | "waterfront-walk" =>
      @energy_valley_contract.Bench
    "street-homes" => @energy_valley_contract.ExchangeDesk
    "valley-market" | "waterfront-pavilion" =>
      @energy_valley_contract.ExchangeDesk
    "transit-court" => @energy_valley_contract.TransitGate
    _ => @energy_valley_contract.Exhibit
  }
}

///|
fn ecosystem_contract_append_program_slot(
  slots : Array[@energy_valley_contract.InteractionSlot],
  place : EcosystemPlace,
  program : @energy_valley_contract.ParcelProgram?,
  assignment : @energy_valley_contract.ParcelProgramAssignment?,
  accessible : Bool,
) -> Unit {
  if !accessible {
    return
  }
  match (program, assignment) {
    (Some(selected), Some(selection)) =>
      slots.push(
        @energy_valley_contract.interaction_slot(
          ecosystem_contract_scoped_id(
            "program-slot",
            "\{place.id}-\{selected.id.local_key()}",
          ),
          ecosystem_contract_program_slot_kind(selected),
          selected.label,
          ecosystem_contract_point(place.anchor),
          2 + selection.variant_seed.abs() % 5,
          None,
          ecosystem_contract_runtime_binding(place),
        ),
      )
    _ => ()
  }
}

///|
/// Content-sensitive digest over canonical spatial and program facts. Counts
/// alone cannot distinguish moving a road/building or selecting a different
/// parcel program, so every stable fact participates in sorted order.
fn ecosystem_contract_blueprint_digest(
  snapshot : EcosystemWorldSnapshot,
  plan : @energy_valley_contract.ParcelPlan,
) -> String {
  let facts : Array[String] = []
  for road in snapshot.roads {
    facts.push(
      "road|\{road.id}|\{road.x}|\{road.y}|\{road.road_class}|\{road.road_mask}|\{road.bridge}|\{road.custom}",
    )
  }
  for place in snapshot.places {
    facts.push(
      "place|\{place.id}|\{place.footprint.x}|\{place.footprint.y}|\{place.footprint.width}|\{place.footprint.depth}|\{place.style}|\{place.district}",
    )
  }
  for assignment in plan.assignments {
    facts.push(
      "program|\{assignment.parcel_id.to_string()}|\{assignment.program_id.to_string()}|\{assignment.variant_seed}",
    )
  }
  facts.sort_by((left, right) => left.compare(right))
  let mut digest = ecosystem_snapshot_digest_step(
    17,
    snapshot.seed.reinterpret_as_int(),
  )
  for fact in facts {
    digest = ecosystem_snapshot_digest_step(digest, ecosystem_stable_hash(fact))
  }
  "wenyu-v2-\{digest}"
}

///|
fn ecosystem_contract_world_from_snapshot(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> @energy_valley_contract.CompiledTownWorld {
  let road_lookup : Map[String, EcosystemRoadCell] = Map([])
  // Entrance discovery already consumed this exact base graph. Reuse its
  // nodes and segments verbatim, then append only portal spurs and gateways.
  let road_nodes : Array[@energy_valley_contract.RoadNode] = []
  for node in snapshot.road_network.nodes {
    road_nodes.push(node)
  }
  let road_segments : Array[@energy_valley_contract.RoadSegment] = []
  for segment in snapshot.road_network.segments {
    road_segments.push(segment)
  }
  let road_anchors : Array[@energy_valley_contract.StableId] = []
  let transit_gateway_roads : Map[String, Bool] = Map([])
  let mut road_min_x = snapshot.cols
  let mut road_min_y = snapshot.rows
  let mut road_max_x = -1
  let mut road_max_y = -1
  for road in snapshot.roads {
    road_min_x = road_min_x.min(road.x)
    road_min_y = road_min_y.min(road.y)
    road_max_x = road_max_x.max(road.x)
    road_max_y = road_max_y.max(road.y)
  }
  let generated_fallback_network = !reference_road_graph_snapshot_ready()
  let boundary_gateway_roads : Map[String, Bool] = Map([])
  let mut north_id = ""
  let mut south_id = ""
  let mut west_id = ""
  let mut east_id = ""
  let mut north_score = snapshot.cols + 1
  let mut south_score = snapshot.cols + 1
  let mut west_score = snapshot.rows + 1
  let mut east_score = snapshot.rows + 1
  let center_x = snapshot.cols / 2
  let center_y = snapshot.rows / 2
  for road in snapshot.roads {
    let northern = if generated_fallback_network {
      road.y == road_min_y
    } else {
      road.y <= 1
    }
    let southern = if generated_fallback_network {
      road.y == road_max_y
    } else {
      road.y >= snapshot.rows - 2
    }
    let western = if generated_fallback_network {
      road.x == road_min_x
    } else {
      road.x <= 1
    }
    let eastern = if generated_fallback_network {
      road.x == road_max_x
    } else {
      road.x >= snapshot.cols - 2
    }
    let horizontal_score = ecosystem_int_abs(road.x - center_x)
    let vertical_score = ecosystem_int_abs(road.y - center_y)
    if northern && horizontal_score < north_score {
      north_id = road.id
      north_score = horizontal_score
    }
    if southern && horizontal_score < south_score {
      south_id = road.id
      south_score = horizontal_score
    }
    if western && vertical_score < west_score {
      west_id = road.id
      west_score = vertical_score
    }
    if eastern && vertical_score < east_score {
      east_id = road.id
      east_score = vertical_score
    }
  }
  for gateway_id in [north_id, east_id, south_id, west_id] {
    if !gateway_id.is_empty() {
      boundary_gateway_roads[gateway_id] = true
    }
  }
  for place in snapshot.places {
    if place.kind is EcosystemMetroStation {
      for entrance in snapshot.entrances {
        if entrance.place_id == place.id && entrance.accessible {
          transit_gateway_roads[ecosystem_road_cell_id(
            entrance.access_point.x,
            entrance.access_point.y,
          )] = true
        }
      }
    }
  }
  for road in snapshot.roads {
    road_lookup[golden_valley_tile_key(road.x, road.y)] = road
    let id = ecosystem_contract_id(road.id)
    // Four deterministic boundary gateways plus typed metro frontages are
    // sufficient external evidence. Interior dead ends remain ordinary nodes,
    // and validation therefore still exposes disconnected components.
    if boundary_gateway_roads.contains(road.id) ||
      transit_gateway_roads.contains(road.id) {
      road_anchors.push(id)
    }
  }
  // Indirect doorways become first-class pedestrian graph branches. The
  // portal binds to node zero at the threshold, then cardinal Footpath
  // segments lead to the exact shared road cell recorded by the frontage.
  // Direct frontages keep their existing road-node binding and allocate no
  // redundant spur geometry.
  for spur in snapshot.pedestrian_spurs {
    if spur.path.length() < 2 {
      continue
    }
    let terminal = spur.path[spur.path.length() - 1]
    let is_local_delta = road_lookup
      .get(golden_valley_tile_key(terminal.x, terminal.y))
      .map(road => road.custom)
      .unwrap_or(false)
    for index in 0..<(spur.path.length() - 1) {
      let point = spur.path[index]
      road_nodes.push(
        @energy_valley_contract.road_node(
          ecosystem_contract_spur_node_id(spur, index),
          @energy_valley_contract.grid_position(point.x, point.y),
          @energy_valley_contract.world_point(
            point.x.to_double() + 0.5,
            point.y.to_double() + 0.5,
          ),
          ecosystem_contract_derived_provenance(is_local_delta),
        ),
      )
    }
    for index in 0..<(spur.path.length() - 1) {
      let from = spur.path[index]
      let to = spur.path[index + 1]
      let to_node_id = if index + 1 == spur.path.length() - 1 {
        ecosystem_contract_id(spur.road_cell_id)
      } else {
        ecosystem_contract_spur_node_id(spur, index + 1)
      }
      road_segments.push(
        @energy_valley_contract.road_segment(
          ecosystem_contract_scoped_id(
            "pedestrian-segment",
            "\{spur.id}-\{index}",
          ),
          ecosystem_contract_spur_node_id(spur, index),
          to_node_id,
          [
            @energy_valley_contract.world_point(
              from.x.to_double() + 0.5,
              from.y.to_double() + 0.5,
            ),
            @energy_valley_contract.world_point(
              to.x.to_double() + 0.5,
              to.y.to_double() + 0.5,
            ),
          ],
          @energy_valley_contract.Footpath,
          2.4,
          [@energy_valley_contract.Pedestrian],
          ecosystem_contract_derived_provenance(is_local_delta),
        ),
      )
    }
  }
  let road_network = @energy_valley_contract.road_network(
    road_nodes, road_segments, road_anchors,
  )
  let gateway_connected_nodes = ecosystem_contract_gateway_connected_nodes(
    road_network,
  )
  let parcel_plan = ecosystem_contract_parcel_plan(snapshot, road_network, seed)
  let places : Array[@energy_valley_contract.Place] = []
  let attention_targets : Array[@energy_valley_contract.AttentionTarget] = []
  for source in snapshot.places {
    if source.kind is EcosystemPublicRealm &&
      (source.style == "bench" || source.style == "planter") {
      continue
    }
    let id = ecosystem_contract_id(source.id)
    let portals = ecosystem_contract_portals(
      snapshot, source, gateway_connected_nodes,
    )
    let accessible = portals.any(portal => portal.road_node_id is Some(_))
    let kind = ecosystem_contract_place_kind(source, accessible)
    let parcel = ecosystem_contract_parcel_for_place(parcel_plan, source)
    let assignment = match parcel {
      Some(value) => parcel_plan.find_assignment(value.id)
      None => None
    }
    let program = match assignment {
      Some(value) => parcel_plan.find_program(value.program_id)
      None => None
    }
    let building = if kind is @energy_valley_contract.Building {
      let floors = ecosystem_contract_building_floors(source)
      Some(
        @energy_valley_contract.building_profile(
          source.style,
          floors,
          floors.to_double() * 4.2,
          ecosystem_contract_program_roof(source, program),
          assignment
          .map(value => value.variant_seed)
          .unwrap_or(ecosystem_stable_hash(source.id)),
        ),
      )
    } else {
      None
    }
    let traits = ecosystem_contract_place_traits(source, accessible)
    match program {
      Some(value) =>
        traits.push(@energy_valley_contract.Signature(value.id.local_key()))
      None => ()
    }
    let slots = ecosystem_contract_slots(snapshot, source, accessible)
    ecosystem_contract_append_program_slot(
      slots, source, program, assignment, accessible,
    )
    places.push(
      @energy_valley_contract.place(
        id,
        source.name,
        kind,
        parcel.map(value => value.id),
        ecosystem_contract_footprint(source.footprint),
        portals,
        traits,
        slots,
        building,
        ecosystem_contract_runtime_binding(source),
        ecosystem_contract_provenance(source.kind is EcosystemCustomBuilding),
        program_id=program.map(value => value.id),
      ),
    )
    attention_targets.push(
      @energy_valley_contract.attention_target(
        ecosystem_contract_attention_target_id(id),
        Some(id),
        if source.kind is EcosystemLandmark {
          @energy_valley_contract.Landmark
        } else {
          @energy_valley_contract.Place
        },
        source.name,
        ecosystem_contract_point(source.anchor),
        ecosystem_contract_place_attention_base(source) * 10,
        [source.district, source.style],
      ),
    )
  }
  let place_relations = ecosystem_contract_place_relations(places)
  let installations = ecosystem_contract_installations(
    snapshot, road_network, places, seed,
  )
  let rejections = ecosystem_contract_rejected_placements(snapshot, places)
  let diagnostics = ecosystem_contract_compilation_diagnostics(
    snapshot, road_network, parcel_plan, places,
  )
  for rejection in rejections {
    diagnostics.push(
      @energy_valley_contract.world_diagnostic(
        ecosystem_contract_scoped_id(
          "diagnostic",
          "rejection-\{rejection.id.to_string()}",
        ),
        @energy_valley_contract.PlacementCompilation,
        @energy_valley_contract.Caution,
        @energy_valley_contract.PlacementRejected,
        rejection.message,
        rejection.provenance,
        entity_id=Some(rejection.candidate_id),
        position=Some(
          @energy_valley_contract.world_point(
            rejection.grid_anchor.column.to_double() + 0.5,
            rejection.grid_anchor.row.to_double() + 0.5,
          ),
        ),
      ),
    )
  }
  @energy_valley_contract.compiled_town_world(
    "moontown.energy-valley.compiled.v2",
    ecosystem_contract_scoped_id("blueprint", "wenyu-energy-valley"),
    ecosystem_contract_blueprint_digest(snapshot, parcel_plan),
    seed,
    @energy_valley_contract.world_bounds(
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(
        snapshot.cols.to_double(),
        snapshot.rows.to_double(),
      ),
    ),
    ecosystem_contract_terrain_regions(snapshot, seed),
    road_network,
    parcel_plan.land_blocks,
    parcel_plan.parcels,
    places,
    attention_targets,
    parcel_programs=parcel_plan.programs,
    parcel_program_assignments=parcel_plan.assignments,
    place_relations~,
    installations~,
    diagnostics~,
    rejected_placements=rejections,
  )
}

///|
let ecosystem_contract_world_cache : Map[
  String,
  @energy_valley_contract.CompiledTownWorld,
] = Map([])

///|
let ecosystem_contract_world_validation_failed_cache : Map[String, Bool] = Map([])

///|
let ecosystem_contract_world_validation_summary_cache : Map[String, String] = Map([],
)

///|
/// Static contract validation is paid at the compiler/adoption boundary. Map
/// Lab and other read-only consumers use this accepted evidence instead of
/// walking every terrain/installations record again when a diagnostic surface
/// opens.
let ecosystem_contract_world_validation_issues_cache : Map[
  String,
  Array[@energy_valley_contract.ContractIssue],
] = Map([])

///|
fn ecosystem_contract_world_validation_identity(
  world : @energy_valley_contract.CompiledTownWorld,
) -> String {
  "\{world.schema_version}:\{world.blueprint_digest}:\{world.layout_seed}"
}

///|
fn ecosystem_contract_copy_issues(
  source : ArrayView[@energy_valley_contract.ContractIssue],
) -> Array[@energy_valley_contract.ContractIssue] {
  let copied : Array[@energy_valley_contract.ContractIssue] = []
  for issue in source {
    copied.push(issue)
  }
  copied
}

///|
/// Production worlds always hit this cache because adoption records the exact
/// `validate_world(candidate)` result. Synthetic white-box worlds fall back to
/// one validation and are cached by immutable world identity thereafter.
fn ecosystem_contract_world_validation_issues(
  world : @energy_valley_contract.CompiledTownWorld,
) -> Array[@energy_valley_contract.ContractIssue] {
  let identity = ecosystem_contract_world_validation_identity(world)
  match ecosystem_contract_world_validation_issues_cache.get(identity) {
    Some(issues) => issues
    None => {
      let issues = ecosystem_contract_copy_issues(
        @energy_valley_contract.validate_world(world),
      )
      ecosystem_contract_world_validation_issues_cache[identity] = issues
      issues
    }
  }
}

///|
fn ecosystem_contract_issue_summary(
  issues : ArrayView[@energy_valley_contract.ContractIssue],
) -> String {
  let messages : Array[String] = []
  for issue in issues {
    if issue.severity == @energy_valley_contract.Error && messages.length() < 3 {
      let owner = match issue.entity_id {
        Some(id) => " · \{id.to_string()}"
        None => ""
      }
      messages.push("\{issue.message}\{owner}")
    }
  }
  messages.join("；")
}

///|
fn ecosystem_contract_safe_empty_world(
  snapshot : EcosystemWorldSnapshot,
  seed : Int,
) -> @energy_valley_contract.CompiledTownWorld {
  @energy_valley_contract.compiled_town_world(
    "moontown.energy-valley.compiled.v2",
    ecosystem_contract_scoped_id("blueprint", "wenyu-\{seed}-safe-empty"),
    "validation-fallback-\{seed}",
    seed,
    @energy_valley_contract.world_bounds(
      @energy_valley_contract.world_point(0.0, 0.0),
      @energy_valley_contract.world_point(
        snapshot.cols.max(1).to_double(),
        snapshot.rows.max(1).to_double(),
      ),
    ),
    [],
    @energy_valley_contract.road_network([], [], []),
    [],
    [],
    [],
    [],
  )
}

///|
fn ecosystem_contract_world_delta_diagnostics(
  model : Model,
  seed : Int,
) -> Array[@energy_valley_contract.WorldDiagnostic] {
  let diagnostics : Array[@energy_valley_contract.WorldDiagnostic] = []
  let projection = town_life_world_projection_for_states(
    model.town_life_world_states,
    seed,
  )
  for index, rejection in projection.rejected {
    // External/corrupt shards may reuse the human event id across distinct
    // causal dots. The projection retains both rejections, so the contract ID
    // also includes its deterministic canonical ordinal and full content hash.
    let diagnostic_key = "\{rejection.event_id}\u{1f}\{rejection.entity_id}\u{1f}\{rejection.reason_code}\u{1f}\{rejection.reason}\u{1f}\{index}"
    diagnostics.push(
      @energy_valley_contract.world_diagnostic(
        ecosystem_contract_scoped_id(
          "diagnostic",
          "town-life-delta-\{ecosystem_stable_hash(diagnostic_key)}-\{index}",
        ),
        @energy_valley_contract.DeltaApplication,
        @energy_valley_contract.Caution,
        @energy_valley_contract.DeltaConflict,
        "\{rejection.reason_code}: \{rejection.reason}",
        energy_valley_world_delta_provenance(),
        entity_id=Some(
          ecosystem_contract_scoped_id(
            "world-delta-entity",
            ecosystem_id_fragment(rejection.entity_id),
          ),
        ),
        evidence_id=Some(rejection.event_id),
      ),
    )
  }
  diagnostics
}

///|
fn ecosystem_contract_world_for_model(
  model : Model,
  seed : Int,
) -> @energy_valley_contract.CompiledTownWorld {
  let key = ecosystem_contract_world_cache_key(model, seed)
  match ecosystem_contract_world_cache.get(key) {
    Some(world) => world
    None => {
      let snapshot = ecosystem_cached_world_snapshot(model, seed)
      let candidate = ecosystem_contract_world_from_snapshot(snapshot, seed)
      let issues = @energy_valley_contract.validate_world(candidate)
      let invalid = @energy_valley_contract.has_errors(issues)
      ecosystem_contract_world_validation_failed_cache[key] = invalid
      ecosystem_contract_world_validation_summary_cache[key] = ecosystem_contract_issue_summary(
        issues,
      )
      let accepted_world = if invalid {
        // Fail closed. Returning a previous world would mix its semantic routes
        // with the compatibility renderer's current geometry; returning the
        // rejected candidate would publish unvalidated access. A valid empty
        // semantic world keeps the base map visible while disabling all
        // evidence-backed interactions until the compiler recovers.
        ecosystem_contract_safe_empty_world(snapshot, seed)
      } else {
        candidate
      }
      // CRDT projection rejects malformed, conflicting, and unaffordable
      // events before they become physical geometry. Preserve those decisions
      // as renderer-neutral contract diagnostics so Map Lab can explain them
      // without Canvas learning about persistence internals.
      let delta_diagnostics = ecosystem_contract_world_delta_diagnostics(
        model, seed,
      )
      let diagnostics : Array[@energy_valley_contract.WorldDiagnostic] = []
      for diagnostic in accepted_world.diagnostics {
        diagnostics.push(diagnostic)
      }
      for diagnostic in delta_diagnostics {
        diagnostics.push(diagnostic)
      }
      let world = @energy_valley_contract.compiled_town_world(
        accepted_world.schema_version,
        accepted_world.blueprint_id,
        accepted_world.blueprint_digest,
        accepted_world.layout_seed,
        accepted_world.bounds,
        accepted_world.terrain_regions,
        accepted_world.road_network,
        accepted_world.land_blocks,
        accepted_world.parcels,
        accepted_world.places,
        accepted_world.attention_targets,
        parcel_programs=accepted_world.parcel_programs,
        parcel_program_assignments=accepted_world.parcel_program_assignments,
        place_relations=accepted_world.place_relations,
        installations=accepted_world.installations,
        diagnostics~,
        rejected_placements=accepted_world.rejected_placements,
      )
      // Diagnostics participate in the same StableId namespace as every
      // semantic object. Validate the reconstructed result rather than
      // trusting the pre-diagnostic candidate; fail closed on any adoption
      // bug instead of publishing an invalid world to Canvas or Map Lab.
      let adopted_issues = @energy_valley_contract.validate_world(world)
      let adoption_invalid = @energy_valley_contract.has_errors(adopted_issues)
      let published_world = if adoption_invalid {
        ecosystem_contract_safe_empty_world(snapshot, seed)
      } else {
        world
      }
      let reported_issues : Array[@energy_valley_contract.ContractIssue] = []
      for issue in issues {
        reported_issues.push(issue)
      }
      for issue in adopted_issues {
        reported_issues.push(issue)
      }
      ecosystem_contract_world_validation_failed_cache[key] = invalid ||
        adoption_invalid
      ecosystem_contract_world_validation_summary_cache[key] = ecosystem_contract_issue_summary(
        reported_issues,
      )
      ecosystem_contract_world_validation_issues_cache[ecosystem_contract_world_validation_identity(
        published_world,
      )] = reported_issues
      ecosystem_contract_world_cache.clear()
      ecosystem_contract_world_cache[key] = published_world
      published_world
    }
  }
}

///|
fn ecosystem_contract_world_validation_failed(
  model : Model,
  seed : Int,
) -> Bool {
  let key = ecosystem_contract_world_cache_key(model, seed)
  let _ = ecosystem_contract_world_for_model(model, seed)
  ecosystem_contract_world_validation_failed_cache.get(key).unwrap_or(false)
}

///|
fn ecosystem_contract_signal_kind(
  behavior : EcosystemBehavior,
) -> @energy_valley_contract.AttentionSignalKind {
  match behavior {
    Coordinate | Exchange => @energy_valley_contract.Social
    Research | Review | Learn => @energy_valley_contract.Work
    Observe | Browse => @energy_valley_contract.Novelty
    Walk | Deliver => @energy_valley_contract.Motion
    Rest => @energy_valley_contract.Ambient
    Celebrate => @energy_valley_contract.Reward
  }
}

///|
fn ecosystem_contract_ambient_provenance() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "moontown-ambient-resident-schedule",
    "v2",
    @energy_valley_contract.Derived,
    @energy_valley_contract.Bounded,
  )
}

///|
fn ecosystem_contract_runtime_provenance() -> @energy_valley_contract.Provenance {
  @energy_valley_contract.provenance(
    "moontown-runtime-projection",
    "v1",
    @energy_valley_contract.RuntimeProjection,
    @energy_valley_contract.Free,
  )
}

///|
fn ecosystem_contract_presence_phase(
  phase : EcosystemResidentPhase,
) -> @energy_valley_contract.PresencePhase {
  match phase {
    EcosystemTraveling => @energy_valley_contract.Approaching
    EcosystemArriving => @energy_valley_contract.AtEntrance
    EcosystemInside => @energy_valley_contract.Inside
    EcosystemUnreachable => @energy_valley_contract.Away
  }
}

///|
fn ecosystem_contract_exchange_kind(
  behavior : EcosystemBehavior,
) -> @energy_valley_contract.ExchangeKind {
  match behavior {
    Research | Review | Learn => @energy_valley_contract.Knowledge
    Coordinate | Exchange | Celebrate => @energy_valley_contract.Social
    Deliver => @energy_valley_contract.Delivery
    Walk => @energy_valley_contract.Mobility
    Rest => @energy_valley_contract.Care
    Observe | Browse => @energy_valley_contract.Service
  }
}

///|
fn ecosystem_contract_slot_for_activity(
  place : @energy_valley_contract.Place,
  behavior : EcosystemBehavior,
  occupancy : Map[@energy_valley_contract.StableId, Int],
) -> @energy_valley_contract.StableId? {
  for slot in place.interaction_slots {
    let compatible = match behavior {
      Research | Review | Learn =>
        slot.kind is @energy_valley_contract.Workstation ||
        slot.kind is @energy_valley_contract.Exhibit
      Coordinate | Exchange | Celebrate =>
        slot.kind is @energy_valley_contract.MeetingPoint ||
        slot.kind is @energy_valley_contract.ExchangeDesk ||
        slot.kind is @energy_valley_contract.Stage
      Deliver =>
        slot.kind is @energy_valley_contract.ExchangeDesk ||
        slot.kind is @energy_valley_contract.ServicePoint
      Walk => slot.kind is @energy_valley_contract.TransitGate
      Rest => slot.kind is @energy_valley_contract.Bench
      Observe | Browse =>
        slot.kind is @energy_valley_contract.Exhibit ||
        slot.kind is @energy_valley_contract.ServicePoint
    }
    if compatible {
      let occupied = occupancy.get(slot.id).unwrap_or(0)
      if occupied < slot.capacity {
        occupancy[slot.id] = occupied + 1
        return Some(slot.id)
      }
    }
  }
  for slot in place.interaction_slots {
    let occupied = occupancy.get(slot.id).unwrap_or(0)
    if occupied < slot.capacity {
      occupancy[slot.id] = occupied + 1
      return Some(slot.id)
    }
  }
  None
}

///|
fn ecosystem_contract_runtime_presence_phase(
  phase : RuntimeAgentRoutePhase,
) -> @energy_valley_contract.PresencePhase {
  match phase {
    RuntimeRouteTraveling => @energy_valley_contract.Approaching
    RuntimeRouteArriving => @energy_valley_contract.AtEntrance
    RuntimeRouteInside => @energy_valley_contract.Inside
    RuntimeRouteUnreachable => @energy_valley_contract.Away
  }
}

///|
let ecosystem_contract_snapshot_validation_failed_cache : Map[String, Bool] = Map([],
)

///|
let ecosystem_contract_snapshot_validation_summary_cache : Map[String, String] = Map([],
)

///|
fn ecosystem_contract_validated_snapshot(
  candidate : @energy_valley_contract.TownSnapshot,
  cache_key : String,
) -> (@energy_valley_contract.TownSnapshot, Bool) {
  let issues = @energy_valley_contract.validate_snapshot_ledger(candidate)
  let invalid = @energy_valley_contract.has_errors(issues)
  ecosystem_contract_snapshot_validation_summary_cache.clear()
  ecosystem_contract_snapshot_validation_summary_cache[cache_key] = ecosystem_contract_issue_summary(
    issues,
  )
  if invalid {
    // Dynamic ledgers are an authority boundary too. If any presence, slot,
    // signal or exchange is inconsistent, keep the validated world but publish
    // no dynamic claims for this frame.
    (
      @energy_valley_contract.town_snapshot(
        candidate.world,
        candidate.tick.max(0),
        [],
        [],
      ),
      true,
    )
  } else {
    (candidate, false)
  }
}

///|
/// The dynamic snapshot joins runtime/ambient attention to the same static
/// world. Signals whose compatibility target has not yet migrated are omitted
/// rather than allowed to dangle or fabricate an owner.
fn ecosystem_contract_town_snapshot(
  model : Model,
  seed : Int,
) -> @energy_valley_contract.TownSnapshot {
  let world = ecosystem_contract_world_for_model(model, seed)
  let signals : Array[@energy_valley_contract.AttentionSignal] = []
  let signal_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  for
    signal in ecosystem_attention_candidates(
      model,
      seed,
      ecosystem_focused_place_id(model),
    ) {
    let place_id = ecosystem_contract_place_id_from_profile(signal.place_id)
    let target_id = ecosystem_contract_attention_target_id(place_id)
    if world.find_attention_target(target_id) is None {
      continue
    }
    let signal_id = ecosystem_contract_scoped_id("attention-signal", signal.id)
    // Runtime projections are append-only evidence streams and may contain a
    // repeated agent/task record. The accepted ledger is identity keyed: one
    // source fact becomes one semantic signal, regardless of transport
    // repetition.
    if signal_ids.contains(signal_id) {
      continue
    }
    signal_ids[signal_id] = true
    signals.push(
      @energy_valley_contract.attention_signal(
        signal_id,
        target_id,
        Some(ecosystem_contract_scoped_id("subject", signal.subject_id)),
        ecosystem_contract_signal_kind(signal.behavior),
        (signal.urgency * 3 +
        signal.novelty * 2 +
        signal.proximity * 2 +
        signal.affinity).clamp(min=0, max=800) *
        1000 /
        800,
        signal.happened_tick,
        if signal.expires_after_ticks < 0 {
          None
        } else {
          Some(signal.happened_tick + signal.expires_after_ticks)
        },
      ),
    )
  }
  let focuses : Array[@energy_valley_contract.AttentionFocus] = []
  let focus_actor_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  for index, profile in ecosystem_preview_resident_profiles() {
    let intention = ecosystem_preview_canvas_intention(model, index)
    let actor_id = ecosystem_contract_scoped_id("resident", profile.id)
    let target = ecosystem_contract_attention_target_id(
      ecosystem_contract_place_id_from_profile(intention.place_id),
    )
    if world.find_attention_target(target) is Some(_) &&
      !focus_actor_ids.contains(actor_id) {
      focus_actor_ids[actor_id] = true
      focuses.push(
        @energy_valley_contract.attention_focus(
          actor_id,
          target,
          (profile.focus * 7 + profile.curiosity * 3).clamp(min=0, max=1000),
          intention.started_tick,
        ),
      )
    }
  }
  let profiles : Array[@energy_valley_contract.ActorProfile] = []
  let presences : Array[@energy_valley_contract.ActorPresence] = []
  let exchanges : Array[@energy_valley_contract.PlaceExchange] = []
  let presence_actor_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  let exchange_ids : Map[@energy_valley_contract.StableId, Bool] = Map([])
  let slot_occupancy : Map[@energy_valley_contract.StableId, Int] = Map([])
  for activity in ecosystem_resident_activities(model, seed) {
    let place_id = ecosystem_contract_place_id_from_profile(activity.place_id)
    match world.find_place(place_id) {
      None => ()
      Some(place) => {
        let portal_id = place.primary_entrance().map(portal => portal.id)
        let actor_id = ecosystem_contract_scoped_id(
          "resident",
          activity.resident_id,
        )
        if !presence_actor_ids.contains(actor_id) {
          presence_actor_ids[actor_id] = true
          profiles.push(ecosystem_contract_ambient_actor_profile(activity))
          let route_position = match (activity.phase, activity.position) {
            (EcosystemTraveling | EcosystemArriving, Some(position)) =>
              Some(
                ecosystem_contract_actor_route_position(
                  world,
                  activity.route,
                  position,
                  activity.progress_per_mille,
                ),
              )
            _ => None
          }
          presences.push(
            @energy_valley_contract.actor_presence(
              actor_id,
              place_id,
              portal_id,
              if activity.phase is EcosystemInside {
                ecosystem_contract_slot_for_activity(
                  place,
                  activity.behavior,
                  slot_occupancy,
                )
              } else {
                None
              },
              ecosystem_contract_presence_phase(activity.phase),
              activity.short_label,
              activity.started_tick,
              Some(activity.transition_tick),
              ecosystem_contract_ambient_provenance(),
              route_position~,
              activity_kind=ecosystem_contract_actor_activity_kind(
                activity.behavior,
              ),
            ),
          )
        }
        let source_id = ecosystem_contract_place_id_from_profile(
          activity.source_place_id,
        )
        if source_id != place_id &&
          world.find_place(source_id) is Some(_) &&
          !(activity.phase is EcosystemUnreachable) {
          let exchange_id = ecosystem_contract_scoped_id(
            "place-exchange",
            "\{activity.resident_id}-\{activity.started_tick}-\{activity.source_place_id}-\{activity.place_id}",
          )
          if !exchange_ids.contains(exchange_id) {
            exchange_ids[exchange_id] = true
            exchanges.push(
              @energy_valley_contract.place_exchange(
                exchange_id,
                source_id,
                place_id,
                Some(actor_id),
                ecosystem_contract_exchange_kind(activity.behavior),
                "\{activity.resident_name} · \{activity.short_label}",
                (480 + activity.progress_per_mille / 2).min(980),
                activity.started_tick,
                Some(activity.transition_tick),
                ecosystem_contract_ambient_provenance(),
              ),
            )
          }
        }
      }
    }
  }
  if energy_valley_runtime_can_claim_active_work(model.energy_valley_runtime) {
    for
      agent_index, agent in energy_valley_runtime_active_agents(
        model.energy_valley_runtime,
      ) {
      match
        energy_valley_runtime_active_task_for_agent(
          model.energy_valley_runtime,
          agent,
        ) {
        None => ()
        Some(work) => {
          let place_id = ecosystem_contract_place_id_from_profile(
            ecosystem_runtime_place_id(agent, Some(work)),
          )
          match world.find_place(place_id) {
            None => ()
            Some(place) =>
              match golden_valley_runtime_agent_journey(model, seed, agent) {
                None => ()
                Some(journey) => {
                  let actor_id = ecosystem_contract_scoped_id(
                    "runtime-agent",
                    agent.id,
                  )
                  if !presence_actor_ids.contains(actor_id) {
                    presence_actor_ids[actor_id] = true
                    profiles.push(
                      ecosystem_contract_runtime_actor_profile(
                        agent, work, agent_index,
                      ),
                    )
                    let route_position = journey.position.map(position => {
                      ecosystem_contract_actor_route_position(
                        world,
                        journey.path,
                        position,
                        journey.progress_per_mille,
                      )
                    })
                    presences.push(
                      @energy_valley_contract.actor_presence(
                        actor_id,
                        place_id,
                        place.primary_entrance().map(portal => portal.id),
                        if journey.phase is RuntimeRouteInside {
                          ecosystem_contract_slot_for_activity(
                            place,
                            ecosystem_runtime_behavior(work.status),
                            slot_occupancy,
                          )
                        } else {
                          None
                        },
                        ecosystem_contract_runtime_presence_phase(journey.phase),
                        energy_valley_safe_runtime_copy(
                          work.activityLabel.unwrap_or(work.title),
                          "运行时活动",
                          100,
                        ),
                        journey.since_tick,
                        None,
                        ecosystem_contract_runtime_provenance(),
                        route_position~,
                        activity_kind=ecosystem_contract_runtime_activity_kind(
                          agent, work,
                        ),
                      ),
                    )
                  }
                }
              }
          }
        }
      }
    }
  }
  ecosystem_contract_append_player_actor(
    model, world, profiles, presences, presence_actor_ids,
  )
  let candidate = @energy_valley_contract.town_snapshot(
    world,
    model.tick,
    signals,
    focuses,
    actor_profiles=profiles,
    actor_presences=presences,
    place_exchanges=exchanges,
  )
  let key = ecosystem_snapshot_cache_key(model, seed)
  let (snapshot, invalid) = ecosystem_contract_validated_snapshot(
    candidate, key,
  )
  ecosystem_contract_snapshot_validation_failed_cache.clear()
  ecosystem_contract_snapshot_validation_failed_cache[key] = invalid
  snapshot
}

///|
fn ecosystem_contract_snapshot_validation_failed(
  model : Model,
  seed : Int,
) -> Bool {
  ecosystem_contract_snapshot_validation_failed_cache
  .get(ecosystem_snapshot_cache_key(model, seed))
  .unwrap_or(false)
}

///|
fn ecosystem_contract_validation_summary(model : Model, seed : Int) -> String {
  let world_key = ecosystem_contract_world_cache_key(model, seed)
  let snapshot_key = ecosystem_snapshot_cache_key(model, seed)
  let summaries : Array[String] = []
  let world = ecosystem_contract_world_validation_summary_cache
    .get(world_key)
    .unwrap_or("")
  let ledger = ecosystem_contract_snapshot_validation_summary_cache
    .get(snapshot_key)
    .unwrap_or("")
  if !world.is_empty() {
    summaries.push("静态世界：\{world}")
  }
  if !ledger.is_empty() {
    summaries.push("动态账本：\{ledger}")
  }
  summaries.join("；")
}
