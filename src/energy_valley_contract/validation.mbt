///|
pub(all) enum IssueSeverity {
  Warning
  Error
} derive(Debug, Eq)

///|
pub(all) enum ContractIssueCode {
  InvalidWorldMetadata
  InvalidBounds
  DuplicateId
  InvalidProvenance
  PositionOutsideBounds
  MissingRoadAnchor
  MissingRoadNode
  MissingRoadSegment
  InvalidRoadGeometry
  InvalidRoadWidth
  InvalidPolygon
  InvalidBuildableRegion
  MissingLandBlock
  MissingParcel
  MissingParcelProgram
  MissingParcelProgramAssignment
  DuplicateParcelProgramAssignment
  ParcelMembershipMismatch
  ParcelProgramMismatch
  ParcelOutsideLandBlock
  ParcelLandUseMismatch
  PlaceOutsideParcel
  MissingPrimaryEntrance
  MissingPortalRoadNode
  UnreachablePortal
  InvalidBuildingProfile
  InvalidRuntimeBinding
  InvalidInteractionSlot
  InvalidPlaceRelation
  InvalidInstallationGeometry
  MissingInstallationOwner
  InvalidDiagnostic
  InvalidRejectedPlacement
  InvalidAttentionRange
  MissingAttentionOwner
  MissingAttentionTarget
  InvalidSignalLifetime
  InvalidActorProfile
  MissingPresencePlace
  MissingPresencePortal
  MissingPresenceSlot
  InvalidPresenceLifetime
  InvalidActorRoutePosition
  DuplicateActivePresence
  InteractionSlotCapacityExceeded
  MissingExchangePlace
  InvalidExchangeRange
  InvalidExchangeLifetime
  InvalidSnapshotTick
  InvalidWorldDelta
  WorldDeltaBlueprintMismatch
  InvalidWorldDeltaOperation
} derive(Debug, Eq)

///|
pub(all) struct ContractIssue {
  severity : IssueSeverity
  code : ContractIssueCode
  entity_id : StableId?
  message : String
} derive(Debug, Eq)

///|
fn report(
  issues : Array[ContractIssue],
  severity : IssueSeverity,
  code : ContractIssueCode,
  entity_id : StableId?,
  message : String,
) -> Unit {
  issues.push({ severity, code, entity_id, message })
}

///|
fn register_id(
  seen : Map[StableId, String],
  issues : Array[ContractIssue],
  id : StableId,
  entity_kind : String,
) -> Unit {
  match seen.get(id) {
    Some(previous_kind) =>
      report(
        issues,
        Error,
        DuplicateId,
        Some(id),
        "identity is shared by \{previous_kind} and \{entity_kind}",
      )
    None => seen[id] = entity_kind
  }
}

///|
fn validate_provenance(
  issues : Array[ContractIssue],
  id : StableId,
  value : Provenance,
) -> Unit {
  if value.source_id.trim().is_empty() ||
    value.source_version.trim().is_empty() ||
    !value.has_valid_confidence() {
    report(
      issues,
      Error,
      InvalidProvenance,
      Some(id),
      "provenance requires source identity, version, and confidence in 0..1000",
    )
  }
}

///|
fn validate_point(
  issues : Array[ContractIssue],
  bounds : WorldBounds,
  id : StableId,
  point : WorldPoint,
) -> Unit {
  if !bounds.contains(point) {
    report(
      issues,
      Warning,
      PositionOutsideBounds,
      Some(id),
      "semantic position lies outside compiled world bounds",
    )
  }
}

///|
fn validate_frontages(
  issues : Array[ContractIssue],
  network : RoadNetwork,
  owner_id : StableId,
  segment_ids : ReadOnlyArray[StableId],
) -> Unit {
  for segment_id in segment_ids {
    if network.find_segment(segment_id) is None {
      report(
        issues,
        Error,
        MissingRoadSegment,
        Some(owner_id),
        "frontage references missing road segment \{segment_id.to_string()}",
      )
    }
  }
}

///|
fn polygon_vertices_are_contained(
  container : Polygon,
  candidate : Polygon,
) -> Bool {
  candidate.vertices.all(vertex => container.contains_point(vertex))
}

///|
fn validate_runtime_binding(
  issues : Array[ContractIssue],
  owner_id : StableId,
  binding : RuntimeBinding,
) -> Unit {
  if binding.resource_id.trim().is_empty() ||
    binding.capability.trim().is_empty() {
    report(
      issues,
      Error,
      InvalidRuntimeBinding,
      Some(owner_id),
      "runtime binding requires resource identity and capability",
    )
  }
}

///|
fn target_has_valid_owner(
  world : CompiledTownWorld,
  target : AttentionTarget,
) -> Bool {
  match target.kind {
    Place | Landmark =>
      match target.owner_id {
        Some(owner_id) => world.find_place(owner_id) is Some(_)
        None => false
      }
    AmbientDetail =>
      match target.owner_id {
        Some(owner_id) =>
          world.find_place(owner_id) is Some(_) ||
          world.find_installation(owner_id) is Some(_)
        None => false
      }
    InteractionSlot =>
      match target.owner_id {
        Some(owner_id) => world.find_interaction_slot(owner_id) is Some(_)
        None => false
      }
    Agent | Event | Custom(_) => true
  }
}

///|
fn route_point_is_on_centerline(
  point : WorldPoint,
  centerline : ReadOnlyArray[WorldPoint],
) -> Bool {
  if centerline.length() < 2 {
    return false
  }
  for index in 1..<centerline.length() {
    let from = centerline[index - 1]
    let to = centerline[index]
    let dx = to.x - from.x
    let dy = to.y - from.y
    let length_squared = dx * dx + dy * dy
    if length_squared <= 0.0 {
      continue
    }
    let raw_ratio = ((point.x - from.x) * dx + (point.y - from.y) * dy) /
      length_squared
    let ratio = if raw_ratio < 0.0 {
      0.0
    } else if raw_ratio > 1.0 {
      1.0
    } else {
      raw_ratio
    }
    let projected_x = from.x + dx * ratio
    let projected_y = from.y + dy * ratio
    let distance_x = point.x - projected_x
    let distance_y = point.y - projected_y
    if distance_x * distance_x + distance_y * distance_y <= 0.0025 {
      return true
    }
  }
  false
}

///|
fn actor_route_matches_segment(
  route : ActorRoutePosition,
  segment : RoadSegment,
) -> Bool {
  guard route.origin_node_id is Some(origin) else { return false }
  guard route.destination_node_id is Some(destination) else { return false }
  let endpoints_match = (
      segment.from_node_id == origin && segment.to_node_id == destination
    ) ||
    (
      segment.bidirectional &&
      segment.from_node_id == destination &&
      segment.to_node_id == origin
    )
  endpoints_match &&
  route_point_is_on_centerline(route.position, segment.centerline)
}

///|
/// Validates the compiled result rather than trusting compiler pass order.
/// Renderers and simulations can reject any world containing an `Error` issue.
pub fn validate_world(
  world : CompiledTownWorld,
) -> ReadOnlyArray[ContractIssue] {
  let issues : Array[ContractIssue] = []
  let seen : Map[StableId, String] = Map([])
  if world.schema_version.trim().is_empty() ||
    world.blueprint_digest.trim().is_empty() {
    report(
      issues,
      Error,
      InvalidWorldMetadata,
      Some(world.blueprint_id),
      "schema version and blueprint digest are required",
    )
  }
  if !world.bounds.is_well_formed() {
    report(
      issues,
      Error,
      InvalidBounds,
      Some(world.blueprint_id),
      "world bounds must have positive horizontal extent",
    )
  }
  register_id(seen, issues, world.blueprint_id, "blueprint")
  for region in world.terrain_regions {
    register_id(seen, issues, region.id, "terrain region")
    validate_provenance(issues, region.id, region.provenance)
    if !region.boundary.is_well_formed() {
      report(
        issues,
        Error,
        InvalidPolygon,
        Some(region.id),
        "terrain region boundary requires at least three vertices",
      )
    }
  }
  for node in world.road_network.nodes {
    register_id(seen, issues, node.id, "road node")
    validate_provenance(issues, node.id, node.provenance)
    validate_point(issues, world.bounds, node.id, node.position)
  }
  if !world.places.is_empty() &&
    world.road_network.access_anchor_node_ids.is_empty() {
    report(
      issues,
      Error,
      MissingRoadAnchor,
      Some(world.blueprint_id),
      "an inhabited world requires at least one road access anchor",
    )
  }
  for anchor in world.road_network.access_anchor_node_ids {
    if world.road_network.find_node(anchor) is None {
      report(
        issues,
        Error,
        MissingRoadNode,
        Some(anchor),
        "road access anchor does not reference a road node",
      )
    }
  }
  for segment in world.road_network.segments {
    register_id(seen, issues, segment.id, "road segment")
    validate_provenance(issues, segment.id, segment.provenance)
    if world.road_network.find_node(segment.from_node_id) is None ||
      world.road_network.find_node(segment.to_node_id) is None {
      report(
        issues,
        Error,
        MissingRoadNode,
        Some(segment.id),
        "road segment endpoint is absent from the road network",
      )
    }
    if segment.from_node_id == segment.to_node_id ||
      segment.centerline.length() < 2 ||
      segment.mobility.is_empty() {
      report(
        issues,
        Error,
        InvalidRoadGeometry,
        Some(segment.id),
        "road segment needs distinct endpoints, two centerline points, and mobility",
      )
    }
    if segment.width_meters <= 0.0 {
      report(
        issues,
        Error,
        InvalidRoadWidth,
        Some(segment.id),
        "road width must be positive",
      )
    }
  }
  for block in world.land_blocks {
    register_id(seen, issues, block.id, "land block")
    validate_provenance(issues, block.id, block.provenance)
    if !block.boundary.is_well_formed() {
      report(
        issues,
        Error,
        InvalidPolygon,
        Some(block.id),
        "land block boundary requires at least three vertices",
      )
    }
    for region in block.buildable_regions {
      register_id(seen, issues, region.id, "buildable region")
      validate_provenance(issues, region.id, region.provenance)
      if !region.boundary.is_well_formed() ||
        !polygon_vertices_are_contained(block.boundary, region.boundary) {
        report(
          issues,
          Error,
          InvalidBuildableRegion,
          Some(region.id),
          "buildable region must be a polygon contained by its land block",
        )
      }
    }
    validate_frontages(
      issues,
      world.road_network,
      block.id,
      block.frontage_segment_ids,
    )
    for parcel_id in block.parcel_ids {
      match world.find_parcel(parcel_id) {
        None =>
          report(
            issues,
            Error,
            MissingParcel,
            Some(block.id),
            "land block references missing parcel \{parcel_id.to_string()}",
          )
        Some(parcel) if parcel.block_id != block.id =>
          report(
            issues,
            Error,
            ParcelMembershipMismatch,
            Some(parcel_id),
            "parcel points to a different land block",
          )
        _ => ()
      }
    }
  }
  for parcel in world.parcels {
    register_id(seen, issues, parcel.id, "parcel")
    validate_provenance(issues, parcel.id, parcel.provenance)
    match world.find_block(parcel.block_id) {
      None =>
        report(
          issues,
          Error,
          MissingLandBlock,
          Some(parcel.id),
          "parcel references a missing land block",
        )
      Some(block) => {
        if !block.parcel_ids.contains(parcel.id) {
          report(
            issues,
            Error,
            ParcelMembershipMismatch,
            Some(parcel.id),
            "parcel is not declared by its land block",
          )
        }
        let containing_regions = block.buildable_regions.filter(region => {
          polygon_vertices_are_contained(region.boundary, parcel.boundary)
        })
        let matches_land_use = if !block.parcelable {
          false
        } else if block.buildable_regions.is_empty() {
          parcel.land_use == block.land_use
        } else {
          containing_regions.any(region => region.land_use == parcel.land_use)
        }
        if !matches_land_use {
          report(
            issues,
            Error,
            ParcelLandUseMismatch,
            Some(parcel.id),
            "parcel land use differs from its containing land block",
          )
        }
        let within_buildable_area = if !block.parcelable {
          false
        } else if block.buildable_regions.is_empty() {
          polygon_vertices_are_contained(block.boundary, parcel.boundary)
        } else {
          !containing_regions.is_empty()
        }
        if !within_buildable_area {
          report(
            issues,
            Error,
            ParcelOutsideLandBlock,
            Some(parcel.id),
            "parcel boundary extends beyond its containing land block",
          )
        }
      }
    }
    if !parcel.boundary.is_well_formed() {
      report(
        issues,
        Error,
        InvalidPolygon,
        Some(parcel.id),
        "parcel boundary requires at least three vertices",
      )
    }
    validate_frontages(
      issues,
      world.road_network,
      parcel.id,
      parcel.frontage_segment_ids,
    )
  }
  for program in world.parcel_programs {
    register_id(seen, issues, program.id, "parcel program")
  }
  let assigned_parcels : Map[StableId, StableId] = Map([])
  for assignment in world.parcel_program_assignments {
    register_id(seen, issues, assignment.id, "parcel program assignment")
    validate_provenance(issues, assignment.id, assignment.provenance)
    match assigned_parcels.get(assignment.parcel_id) {
      Some(previous_assignment_id) =>
        report(
          issues,
          Error,
          DuplicateParcelProgramAssignment,
          Some(assignment.id),
          "parcel already has program assignment \{previous_assignment_id.to_string()}",
        )
      None => assigned_parcels[assignment.parcel_id] = assignment.id
    }
    let parcel = world.find_parcel(assignment.parcel_id)
    let program = world.find_parcel_program(assignment.program_id)
    if parcel is None {
      report(
        issues,
        Error,
        MissingParcel,
        Some(assignment.id),
        "parcel program assignment references a missing parcel",
      )
    }
    if program is None {
      report(
        issues,
        Error,
        MissingParcelProgram,
        Some(assignment.id),
        "parcel program assignment references a missing program",
      )
    }
    match (parcel, program) {
      (Some(bound_parcel), Some(bound_program)) => {
        if !bound_program.compatible_land_uses.contains(bound_parcel.land_use) {
          report(
            issues,
            Error,
            ParcelProgramMismatch,
            Some(assignment.id),
            "assigned program is incompatible with parcel land use",
          )
        }
        if !bound_parcel.allowed_programs.contains(bound_program.id.to_string()) {
          report(
            issues,
            Error,
            ParcelProgramMismatch,
            Some(assignment.id),
            "assigned program is absent from the parcel allow-list",
          )
        }
        let area = bound_parcel.boundary.area()
        let exceeds_maximum = match bound_program.maximum_area_sqm {
          Some(maximum) => area > maximum
          None => false
        }
        if area < bound_program.minimum_area_sqm || exceeds_maximum {
          report(
            issues,
            Error,
            ParcelProgramMismatch,
            Some(assignment.id),
            "parcel area does not satisfy the assigned program constraints",
          )
        }
        let frontage_is_owned = match assignment.frontage_segment_id {
          Some(segment_id) =>
            bound_parcel.frontage_segment_ids.contains(segment_id)
          None => false
        }
        if (bound_program.requires_frontage && !frontage_is_owned) ||
          (assignment.frontage_segment_id is Some(_) && !frontage_is_owned) {
          report(
            issues,
            Error,
            ParcelProgramMismatch,
            Some(assignment.id),
            "program assignment frontage must belong to its parcel",
          )
        }
        if !bound_parcel.boundary.contains_point(assignment.placement_anchor) {
          report(
            issues,
            Error,
            ParcelProgramMismatch,
            Some(assignment.id),
            "program placement anchor lies outside its parcel boundary",
          )
        }
      }
      _ => ()
    }
  }
  if !world.parcel_program_assignments.is_empty() {
    for parcel in world.parcels {
      if !world.parcel_program_assignments.any(assignment => {
          assignment.parcel_id == parcel.id
        }) {
        report(
          issues,
          Error,
          MissingParcelProgramAssignment,
          Some(parcel.id),
          "compiled parcel has no program assignment",
        )
      }
    }
  }
  for place in world.places {
    register_id(seen, issues, place.id, "place")
    validate_provenance(issues, place.id, place.provenance)
    if !place.footprint.is_well_formed() {
      report(
        issues,
        Error,
        InvalidPolygon,
        Some(place.id),
        "place footprint requires at least three vertices",
      )
    }
    match place.parcel_id {
      Some(parcel_id) =>
        match world.find_parcel(parcel_id) {
          None =>
            report(
              issues,
              Error,
              MissingParcel,
              Some(place.id),
              "place references a missing parcel",
            )
          Some(parcel) =>
            if !polygon_vertices_are_contained(parcel.boundary, place.footprint) {
              report(
                issues,
                Error,
                PlaceOutsideParcel,
                Some(place.id),
                "place footprint extends beyond its referenced parcel",
              )
            }
        }
      None => ()
    }
    match place.program_id {
      Some(program_id) => {
        if world.find_parcel_program(program_id) is None {
          report(
            issues,
            Error,
            MissingParcelProgram,
            Some(place.id),
            "place references a missing parcel program",
          )
        }
        match place.parcel_id {
          Some(parcel_id) =>
            match world.parcel_program_for(parcel_id) {
              Some(program) if program.id == program_id => ()
              _ =>
                report(
                  issues,
                  Error,
                  ParcelProgramMismatch,
                  Some(place.id),
                  "place program differs from its parcel assignment",
                )
            }
          None =>
            report(
              issues,
              Error,
              ParcelProgramMismatch,
              Some(place.id),
              "place program requires a parcel relationship",
            )
        }
      }
      None => ()
    }
    match (place.kind, place.building) {
      (Building, None) =>
        report(
          issues,
          Error,
          InvalidBuildingProfile,
          Some(place.id),
          "building place requires a building profile",
        )
      (_, Some(profile)) if profile.floors <= 0 || profile.height_meters <= 0.0 =>
        report(
          issues,
          Error,
          InvalidBuildingProfile,
          Some(place.id),
          "building profile requires positive floors and height",
        )
      _ => ()
    }
    match place.runtime_binding {
      Some(binding) => validate_runtime_binding(issues, place.id, binding)
      None => ()
    }
    let mut primary_entrance_count = 0
    for portal in place.entrances {
      if portal.primary {
        primary_entrance_count += 1
      }
    }
    // A building may be a truthful, inspectable part of the authored map even
    // when a later user delta cuts off its frontage. `Accessible` is the
    // compiler's positive claim that people can enter; only then is a bound,
    // reachable primary portal mandatory. This lets migration preserve sealed
    // buildings without inventing a nearest-road teleport.
    let declared_accessible = place.traits.any(place_trait => {
      place_trait is Accessible
    })
    let requires_primary_entrance = match place.kind {
      Building => declared_accessible
      TransitStation => true
      _ => false
    }
    if requires_primary_entrance && primary_entrance_count == 0 {
      report(
        issues,
        Error,
        MissingPrimaryEntrance,
        Some(place.id),
        "enterable place requires one primary entrance portal",
      )
    } else if primary_entrance_count > 1 {
      report(
        issues,
        Error,
        MissingPrimaryEntrance,
        Some(place.id),
        "place must not declare more than one primary entrance portal",
      )
    }
    for portal in place.entrances {
      register_id(seen, issues, portal.id, "entrance portal")
      validate_point(issues, world.bounds, portal.id, portal.position)
      if portal.mobility.is_empty() {
        report(
          issues,
          Error,
          MissingPortalRoadNode,
          Some(portal.id),
          "entrance portal requires at least one mobility mode",
        )
      }
      match portal.road_node_id {
        None if portal.primary && requires_primary_entrance =>
          report(
            issues,
            Error,
            MissingPortalRoadNode,
            Some(portal.id),
            "primary entrance must bind to a road node",
          )
        Some(node_id) if world.road_network.find_node(node_id) is None =>
          report(
            issues,
            Error,
            MissingPortalRoadNode,
            Some(portal.id),
            "entrance references a missing road node",
          )
        Some(node_id) if portal.primary &&
          requires_primary_entrance &&
          !portal.mobility.any(mode => {
            world.road_network.is_reachable_from_anchor(node_id, mode~)
          }) =>
          report(
            issues,
            Error,
            UnreachablePortal,
            Some(portal.id),
            "primary entrance is unreachable from every world access anchor",
          )
        _ => ()
      }
    }
    for slot in place.interaction_slots {
      register_id(seen, issues, slot.id, "interaction slot")
      validate_point(issues, world.bounds, slot.id, slot.position)
      if slot.capacity <= 0 {
        report(
          issues,
          Error,
          InvalidInteractionSlot,
          Some(slot.id),
          "interaction slot capacity must be positive",
        )
      }
      match slot.runtime_binding {
        Some(binding) => validate_runtime_binding(issues, slot.id, binding)
        None => ()
      }
    }
  }
  for target in world.attention_targets {
    register_id(seen, issues, target.id, "attention target")
    validate_point(issues, world.bounds, target.id, target.position)
    if target.base_salience_per_mille < 0 ||
      target.base_salience_per_mille > 1000 {
      report(
        issues,
        Error,
        InvalidAttentionRange,
        Some(target.id),
        "attention target salience must be in 0..1000",
      )
    }
    if !target_has_valid_owner(world, target) {
      report(
        issues,
        Error,
        MissingAttentionOwner,
        Some(target.id),
        "static attention target owner cannot be resolved",
      )
    }
  }
  for relation in world.place_relations {
    register_id(seen, issues, relation.id, "place relation")
    validate_provenance(issues, relation.id, relation.provenance)
    if relation.source_place_id == relation.target_place_id ||
      relation.label.trim().is_empty() ||
      world.find_place(relation.source_place_id) is None ||
      world.find_place(relation.target_place_id) is None {
      report(
        issues,
        Error,
        InvalidPlaceRelation,
        Some(relation.id),
        "place relation requires two distinct accepted places and a label",
      )
    }
  }
  for value in world.installations {
    register_id(seen, issues, value.id, "installation")
    validate_provenance(issues, value.id, value.provenance)
    if value.label.trim().is_empty() {
      report(
        issues,
        Error,
        InvalidInstallationGeometry,
        Some(value.id),
        "installation label cannot be empty",
      )
    }
    match value.geometry {
      AtPoint(position) =>
        validate_point(issues, world.bounds, value.id, position)
      AlongPath(points) => {
        if points.length() < 2 {
          report(
            issues,
            Error,
            InvalidInstallationGeometry,
            Some(value.id),
            "linear installation requires at least two points",
          )
        }
        for point in points {
          validate_point(issues, world.bounds, value.id, point)
        }
      }
      WithinArea(boundary) => {
        if !boundary.is_well_formed() {
          report(
            issues,
            Error,
            InvalidInstallationGeometry,
            Some(value.id),
            "area installation requires a polygon",
          )
        }
        for point in boundary.vertices {
          validate_point(issues, world.bounds, value.id, point)
        }
      }
    }
    let geometry_matches_kind = match (value.kind, value.geometry) {
      (MetroAlignment, AlongPath(_)) => true
      (Boardwalk, AlongPath(_) | WithinArea(_)) => true
      (Tree | Light | Bench | TransitEntrance | Signage, AtPoint(_)) => true
      (Custom(_), _) => true
      _ => false
    }
    if !geometry_matches_kind {
      report(
        issues,
        Error,
        InvalidInstallationGeometry,
        Some(value.id),
        "installation geometry does not match its semantic kind",
      )
    }
    match value.owner_place_id {
      Some(owner_id) if world.find_place(owner_id) is None =>
        report(
          issues,
          Error,
          MissingInstallationOwner,
          Some(value.id),
          "installation references a missing owner place",
        )
      _ => ()
    }
    for segment_id in value.road_segment_ids {
      if world.road_network.find_segment(segment_id) is None {
        report(
          issues,
          Error,
          MissingRoadSegment,
          Some(value.id),
          "installation references a missing road segment",
        )
      }
    }
    match value.attention_target_id {
      Some(target_id) if world.find_attention_target(target_id) is None =>
        report(
          issues,
          Error,
          MissingAttentionTarget,
          Some(value.id),
          "installation references a missing attention target",
        )
      _ => ()
    }
  }
  for diagnostic in world.diagnostics {
    register_id(seen, issues, diagnostic.id, "world diagnostic")
    validate_provenance(issues, diagnostic.id, diagnostic.provenance)
    if diagnostic.message.trim().is_empty() {
      report(
        issues,
        Error,
        InvalidDiagnostic,
        Some(diagnostic.id),
        "world diagnostic requires a message",
      )
    }
    match diagnostic.position {
      Some(position) =>
        validate_point(issues, world.bounds, diagnostic.id, position)
      None => ()
    }
  }
  for rejection in world.rejected_placements {
    register_id(seen, issues, rejection.id, "rejected placement")
    validate_provenance(issues, rejection.id, rejection.provenance)
    if !rejection.footprint.is_well_formed() ||
      rejection.message.trim().is_empty() {
      report(
        issues,
        Error,
        InvalidRejectedPlacement,
        Some(rejection.id),
        "rejected placement requires a candidate footprint and reason",
      )
    }
    match rejection.parcel_id {
      Some(parcel_id) if world.find_parcel(parcel_id) is None =>
        report(
          issues,
          Error,
          MissingParcel,
          Some(rejection.id),
          "rejected placement references a missing parcel",
        )
      _ => ()
    }
  }
  for place in world.places {
    for slot in place.interaction_slots {
      match slot.attention_target_id {
        Some(target_id) if world.find_attention_target(target_id) is None =>
          report(
            issues,
            Error,
            MissingAttentionTarget,
            Some(slot.id),
            "interaction slot references a missing attention target",
          )
        _ => ()
      }
    }
  }
  freeze(issues)
}

///|
pub fn validate_snapshot_ledger(
  snapshot : TownSnapshot,
) -> ReadOnlyArray[ContractIssue] {
  let issues : Array[ContractIssue] = []
  if snapshot.tick < 0 {
    report(
      issues,
      Error,
      InvalidSnapshotTick,
      Some(snapshot.world.blueprint_id),
      "snapshot tick cannot be negative",
    )
  }
  let signal_ids : Map[StableId, String] = Map([])
  for signal in snapshot.attention_signals {
    register_id(signal_ids, issues, signal.id, "attention signal")
    if snapshot.world.find_attention_target(signal.target_id) is None {
      report(
        issues,
        Error,
        MissingAttentionTarget,
        Some(signal.id),
        "attention signal references a missing target",
      )
    }
    if signal.intensity_per_mille < 0 || signal.intensity_per_mille > 1000 {
      report(
        issues,
        Error,
        InvalidAttentionRange,
        Some(signal.id),
        "attention signal intensity must be in 0..1000",
      )
    }
    match signal.expires_tick {
      Some(expires) if expires <= signal.started_tick =>
        report(
          issues,
          Error,
          InvalidSignalLifetime,
          Some(signal.id),
          "attention signal must expire after it starts",
        )
      _ => ()
    }
  }
  for focus in snapshot.attention_focuses {
    if snapshot.world.find_attention_target(focus.target_id) is None {
      report(
        issues,
        Error,
        MissingAttentionTarget,
        Some(focus.actor_id),
        "attention focus references a missing target",
      )
    }
    if focus.strength_per_mille < 0 || focus.strength_per_mille > 1000 {
      report(
        issues,
        Error,
        InvalidAttentionRange,
        Some(focus.actor_id),
        "attention focus strength must be in 0..1000",
      )
    }
  }
  let actor_profile_ids : Map[StableId, String] = Map([])
  for profile in snapshot.actor_profiles {
    register_id(actor_profile_ids, issues, profile.actor_id, "actor profile")
    validate_provenance(issues, profile.actor_id, profile.provenance)
    let provenance_matches_source = match profile.source_kind {
      AmbientSimulation => profile.provenance.kind == Derived
      RuntimeEvidence => profile.provenance.kind == RuntimeProjection
      LocalEmbodiment => profile.provenance.kind == UserDelta
    }
    if profile.display_name.trim().is_empty() ||
      profile.role_label.trim().is_empty() ||
      profile.avatar_family.trim().is_empty() ||
      profile.avatar_variant < 0 ||
      profile.palette_variant < 0 ||
      !provenance_matches_source {
      report(
        issues,
        Error,
        InvalidActorProfile,
        Some(profile.actor_id),
        "actor profile requires names, non-negative theme variants, and matching provenance",
      )
    }
  }
  let active_presence_actors : Map[StableId, Unit] = Map([])
  let active_inside_slot_counts : Map[StableId, Int] = Map([])
  for presence in snapshot.actor_presences {
    if presence.is_active(snapshot.tick) {
      if active_presence_actors.contains(presence.actor_id) {
        report(
          issues,
          Error,
          DuplicateActivePresence,
          Some(presence.actor_id),
          "actor has more than one active place presence",
        )
      } else {
        active_presence_actors[presence.actor_id] = ()
      }
    }
    match snapshot.world.find_place(presence.place_id) {
      None =>
        report(
          issues,
          Error,
          MissingPresencePlace,
          Some(presence.actor_id),
          "actor presence references a missing place",
        )
      Some(place) => {
        match presence.portal_id {
          Some(portal_id) if !place.entrances.any(portal => {
              portal.id == portal_id
            }) =>
            report(
              issues,
              Error,
              MissingPresencePortal,
              Some(presence.actor_id),
              "actor presence references a portal outside its place",
            )
          _ => ()
        }
        match presence.interaction_slot_id {
          Some(slot_id) if place.find_slot(slot_id) is None =>
            report(
              issues,
              Error,
              MissingPresenceSlot,
              Some(presence.actor_id),
              "actor presence references an interaction slot outside its place",
            )
          _ => ()
        }
        if presence.phase is Inside && presence.is_active(snapshot.tick) {
          match presence.interaction_slot_id {
            Some(slot_id) if place.find_slot(slot_id) is Some(_) =>
              active_inside_slot_counts[slot_id] = active_inside_slot_counts
                .get(slot_id)
                .unwrap_or(0) +
                1
            _ => ()
          }
        }
      }
    }
    validate_provenance(issues, presence.actor_id, presence.provenance)
    match presence.route_position {
      Some(route) => {
        validate_point(
          issues,
          snapshot.world.bounds,
          presence.actor_id,
          route.position,
        )
        if route.progress_per_mille < 0 ||
          route.progress_per_mille > 1000 ||
          presence.phase is Inside ||
          presence.phase is Away ||
          route.heading_degrees
          .map(heading => heading < 0.0 || heading >= 360.0)
          .unwrap_or(false) {
          report(
            issues,
            Error,
            InvalidActorRoutePosition,
            Some(presence.actor_id),
            "actor route position must be outdoor with progress in 0..1000 and a normalized heading",
          )
        }
        match route.road_segment_id {
          Some(segment_id) =>
            match snapshot.world.road_network.find_segment(segment_id) {
              None =>
                report(
                  issues,
                  Error,
                  MissingRoadSegment,
                  Some(presence.actor_id),
                  "actor route position references a missing road segment",
                )
              Some(segment) if !actor_route_matches_segment(route, segment) =>
                report(
                  issues,
                  Error,
                  InvalidActorRoutePosition,
                  Some(presence.actor_id),
                  "actor route segment, directed node endpoints, and centerline position disagree",
                )
              _ => ()
            }
          _ => ()
        }
        for node_id in [route.origin_node_id, route.destination_node_id] {
          match node_id {
            Some(id) if snapshot.world.road_network.find_node(id) is None =>
              report(
                issues,
                Error,
                MissingRoadNode,
                Some(presence.actor_id),
                "actor route position references a missing road node",
              )
            _ => ()
          }
        }
      }
      None => ()
    }
    match presence.until_tick {
      Some(until) if until <= presence.since_tick =>
        report(
          issues,
          Error,
          InvalidPresenceLifetime,
          Some(presence.actor_id),
          "actor presence must end after it starts",
        )
      _ => ()
    }
  }
  for slot_id, occupancy in active_inside_slot_counts {
    match snapshot.world.find_interaction_slot(slot_id) {
      Some(slot) if occupancy > slot.capacity =>
        report(
          issues,
          Error,
          InteractionSlotCapacityExceeded,
          Some(slot_id),
          "active inside presence count exceeds interaction slot capacity",
        )
      _ => ()
    }
  }
  let exchange_ids : Map[StableId, String] = Map([])
  for exchange in snapshot.place_exchanges {
    register_id(exchange_ids, issues, exchange.id, "place exchange")
    if snapshot.world.find_place(exchange.source_place_id) is None ||
      snapshot.world.find_place(exchange.target_place_id) is None {
      report(
        issues,
        Error,
        MissingExchangePlace,
        Some(exchange.id),
        "place exchange references a missing endpoint",
      )
    }
    if exchange.intensity_per_mille < 0 || exchange.intensity_per_mille > 1000 {
      report(
        issues,
        Error,
        InvalidExchangeRange,
        Some(exchange.id),
        "place exchange intensity must be in 0..1000",
      )
    }
    validate_provenance(issues, exchange.id, exchange.provenance)
    match exchange.expires_tick {
      Some(expires) if expires <= exchange.started_tick =>
        report(
          issues,
          Error,
          InvalidExchangeLifetime,
          Some(exchange.id),
          "place exchange must expire after it starts",
        )
      _ => ()
    }
  }
  freeze(issues)
}

///|
/// Full standalone validation for callers that have not already accepted the
/// compiled world at a compiler boundary.
pub fn validate_snapshot(
  snapshot : TownSnapshot,
) -> ReadOnlyArray[ContractIssue] {
  let issues : Array[ContractIssue] = []
  for issue in validate_world(snapshot.world) {
    issues.push(issue)
  }
  for issue in validate_snapshot_ledger(snapshot) {
    issues.push(issue)
  }
  freeze(issues)
}

///|
/// A saved road delta records only the cells authored by the player. A
/// one-cell addition is therefore a valid edge extension when that cell is
/// cardinally adjacent to the accepted base graph and the base node is
/// reachable for at least one of the addition's mobility modes.
fn single_cell_road_delta_attaches_to_base(
  path : ReadOnlyArray[GridPosition],
  mobility : ReadOnlyArray[MobilityMode],
  base_world : CompiledTownWorld?,
) -> Bool {
  if path.length() != 1 {
    return false
  }
  guard base_world is Some(world) else { return false }
  let point = path[0]
  for node in world.road_network.nodes {
    let distance = (node.grid.column - point.column).abs() +
      (node.grid.row - point.row).abs()
    if distance == 1 &&
      mobility.any(mode => {
        world.road_network.is_reachable_from_anchor(node.id, mode~)
      }) {
      return true
    }
  }
  false
}

///|
/// Validates a persistence delta independently or against its intended base
/// world. Operation order is preserved; Move/Delete are valid history only
/// after Add, and Delete makes the stable identity terminal.
pub fn validate_world_delta(
  delta : WorldDelta,
  base_world? : CompiledTownWorld? = None,
) -> ReadOnlyArray[ContractIssue] {
  let issues : Array[ContractIssue] = []
  if delta.schema_version.trim().is_empty() ||
    delta.base_blueprint_digest.trim().is_empty() ||
    delta.revision < 0 {
    report(
      issues,
      Error,
      InvalidWorldDelta,
      Some(delta.base_blueprint_id),
      "world delta requires schema, base digest, and non-negative revision",
    )
  }
  match base_world {
    Some(world) if !delta.targets(world) =>
      report(
        issues,
        Error,
        WorldDeltaBlueprintMismatch,
        Some(delta.base_blueprint_id),
        "world delta blueprint identity or digest does not match its base",
      )
    _ => ()
  }
  let entity_kinds : Map[StableId, WorldDeltaEntityKind] = Map([])
  // 1 = active after Add, 2 = terminally deleted. A stable identity is never
  // implicitly created by Move/Delete and is not silently resurrected.
  let entity_lifecycle : Map[StableId, Int] = Map([])
  for operation in delta.operations {
    let entity_id = operation.entity_id()
    let entity_kind = operation.entity_kind()
    match entity_kinds.get(entity_id) {
      Some(previous) if previous != entity_kind =>
        report(
          issues,
          Error,
          InvalidWorldDeltaOperation,
          Some(entity_id),
          "one delta identity cannot be edited as multiple entity kinds",
        )
      None => entity_kinds[entity_id] = entity_kind
      _ => ()
    }
    match operation {
      AddBuilding(_) | AddRoad(_) | AddPark(_) =>
        match entity_lifecycle.get(entity_id) {
          None => entity_lifecycle[entity_id] = 1
          Some(_) =>
            report(
              issues,
              Error,
              InvalidWorldDeltaOperation,
              Some(entity_id),
              "delta Add must be the first and only Add for an entity identity",
            )
        }
      MoveBuilding(_) | MoveRoad(_) | MovePark(_) =>
        if entity_lifecycle.get(entity_id) != Some(1) {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(entity_id),
            "delta Move requires an active entity created by an earlier Add",
          )
        }
      DeleteBuilding(_) | DeleteRoad(_) | DeletePark(_) =>
        if entity_lifecycle.get(entity_id) == Some(1) {
          entity_lifecycle[entity_id] = 2
        } else {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(entity_id),
            "delta Delete requires an active entity and is terminal",
          )
        }
    }
    validate_provenance(issues, entity_id, operation.provenance())
    match operation {
      AddBuilding(value) =>
        if value.name.trim().is_empty() ||
          !value.footprint.is_well_formed() ||
          value.profile.floors <= 0 ||
          value.profile.height_meters <= 0.0 {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "building addition requires name, footprint, and valid profile",
          )
        }
      MoveBuilding(value) =>
        if !value.footprint.is_well_formed() {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "building movement requires a footprint",
          )
        }
      AddRoad(value) =>
        if (
            value.grid_path.length() < 2 &&
            !single_cell_road_delta_attaches_to_base(
              value.grid_path,
              value.mobility,
              base_world,
            )
          ) ||
          value.width_meters <= 0.0 ||
          value.mobility.is_empty() {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "road addition requires a path, positive width, and mobility",
          )
        }
      MoveRoad(value) =>
        if value.grid_path.is_empty() ||
          (
            value.grid_path.length() == 1 &&
            !single_cell_road_delta_attaches_to_base(
              value.grid_path,
              [Pedestrian, Bicycle, ServiceVehicle],
              base_world,
            )
          ) {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "road movement requires a path or a one-cell base-graph extension",
          )
        }
      AddPark(value) =>
        if value.label.trim().is_empty() || !value.boundary.is_well_formed() {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "park addition requires label and boundary",
          )
        }
      MovePark(value) =>
        if !value.boundary.is_well_formed() {
          report(
            issues,
            Error,
            InvalidWorldDeltaOperation,
            Some(value.id),
            "park movement requires a boundary",
          )
        }
      DeleteBuilding(_) | DeleteRoad(_) | DeletePark(_) => ()
    }
  }
  freeze(issues)
}

///|
pub fn has_errors(issues : ArrayView[ContractIssue]) -> Bool {
  issues.any(issue => issue.severity == Error)
}
