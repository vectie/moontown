///|
fn ecosystem_installation_source_provenance(
  custom : Bool,
) -> @energy_valley_contract.Provenance {
  if custom {
    energy_valley_world_delta_provenance()
  } else {
    @energy_valley_contract.provenance(
      "wenyu-public-realm-compiler",
      "v3",
      @energy_valley_contract.Derived,
      @energy_valley_contract.Bounded,
    )
  }
}

///|
fn ecosystem_installation_road_segments(
  network : @energy_valley_contract.RoadNetwork,
  node_id : @energy_valley_contract.StableId,
) -> Array[@energy_valley_contract.StableId] {
  let result : Array[@energy_valley_contract.StableId] = []
  for segment in network.segments {
    if segment.from_node_id == node_id || segment.to_node_id == node_id {
      result.push(segment.id)
    }
  }
  result
}

///|
fn ecosystem_installation_boardwalk_edge(
  x : Int,
  y : Int,
  bit : Int,
) -> Array[@energy_valley_contract.WorldPoint] {
  match bit {
    1 =>
      [
        @energy_valley_contract.world_point(x.to_double(), y.to_double()),
        @energy_valley_contract.world_point((x + 1).to_double(), y.to_double()),
      ]
    2 =>
      [
        @energy_valley_contract.world_point((x + 1).to_double(), y.to_double()),
        @energy_valley_contract.world_point(
          (x + 1).to_double(),
          (y + 1).to_double(),
        ),
      ]
    4 =>
      [
        @energy_valley_contract.world_point(
          (x + 1).to_double(),
          (y + 1).to_double(),
        ),
        @energy_valley_contract.world_point(x.to_double(), (y + 1).to_double()),
      ]
    _ =>
      [
        @energy_valley_contract.world_point(x.to_double(), (y + 1).to_double()),
        @energy_valley_contract.world_point(x.to_double(), y.to_double()),
      ]
  }
}

///|
fn ecosystem_installation_authored_terrain_at(
  world : ExactEnergyValleyWorld,
  x : Int,
  y : Int,
) -> String {
  if x < 0 || x >= world.cols || y < 0 || y >= world.rows {
    "void"
  } else {
    world.tiles[y][x].terrain
  }
}

///|
fn ecosystem_contract_installations(
  snapshot : EcosystemWorldSnapshot,
  network : @energy_valley_contract.RoadNetwork,
  places : ArrayView[@energy_valley_contract.Place],
  seed : Int,
) -> Array[@energy_valley_contract.Installation] {
  let result : Array[@energy_valley_contract.Installation] = []
  let reference = ecosystem_installation_source_provenance(false)
  let metro_path : Array[@energy_valley_contract.WorldPoint] = []
  for point in metro_line17_path() {
    metro_path.push(@energy_valley_contract.world_point(point.0, point.1))
  }
  result.push(
    @energy_valley_contract.installation(
      ecosystem_contract_scoped_id("installation", "metro-line17-alignment"),
      "地铁 17 号线",
      @energy_valley_contract.MetroAlignment,
      @energy_valley_contract.installation_path(metro_path),
      reference,
      tags=["line:17", "layer:underlay"],
    ),
  )
  for place in places {
    if place.kind is @energy_valley_contract.TransitStation {
      for index, portal in place.entrances {
        let exit_label = snapshot.entrances
          .search_by(source => ecosystem_contract_id(source.id) == portal.id)
          .map(source_index => snapshot.entrances[source_index].label)
          .unwrap_or((index + 1).to_string())
        result.push(
          @energy_valley_contract.installation(
            ecosystem_contract_scoped_id(
              "installation",
              "transit-entrance-\{portal.id.to_string()}",
            ),
            "\{place.name} \{exit_label} 口",
            @energy_valley_contract.TransitEntrance,
            @energy_valley_contract.installation_point(portal.position),
            reference,
            owner_place_id=Some(place.id),
            interactive=true,
            tags=[
              "line:17",
              "exit:\{exit_label}",
              "portal:\{portal.id.to_string()}",
            ],
          ),
        )
      }
    }
  }
  for road in snapshot.roads {
    let node_id = ecosystem_contract_id(road.id)
    let segment_ids = ecosystem_installation_road_segments(network, node_id)
    let position = @energy_valley_contract.world_point(
      road.x.to_double() + 0.5,
      road.y.to_double() + 0.5,
    )
    let provenance = ecosystem_installation_source_provenance(road.custom)
    let side = golden_public_realm_side(seed, road.x, road.y, 733)
    if road.street_tree {
      result.push(
        @energy_valley_contract.installation(
          ecosystem_contract_scoped_id(
            "installation",
            "street-tree-\{road.x}-\{road.y}",
          ),
          "行道树",
          @energy_valley_contract.Tree,
          @energy_valley_contract.installation_point(position),
          provenance,
          road_segment_ids=segment_ids,
          tags=["road-mask:\{road.road_mask}", "side:\{side}"],
        ),
      )
    }
    if road.streetlight {
      result.push(
        @energy_valley_contract.installation(
          ecosystem_contract_scoped_id(
            "installation",
            "street-light-\{road.x}-\{road.y}",
          ),
          "街灯",
          @energy_valley_contract.Light,
          @energy_valley_contract.installation_point(position),
          provenance,
          road_segment_ids=segment_ids,
          tags=["road-mask:\{road.road_mask}", "side:\{side}"],
        ),
      )
    }
  }
  let authored_world = golden_valley_world(seed)
  for affordance in snapshot.affordances {
    if affordance.evidence != "wenyu-water-edge" {
      continue
    }
    let x = affordance.anchor.x
    let y = affordance.anchor.y
    if x < 0 || x >= authored_world.cols || y < 0 || y >= authored_world.rows {
      continue
    }
    let mask = golden_public_realm_boardwalk_mask(
      authored_world.tiles[y][x].terrain,
      authored_world.tiles[y][x].district,
      ecosystem_installation_authored_terrain_at(authored_world, x, y - 1),
      ecosystem_installation_authored_terrain_at(authored_world, x + 1, y),
      ecosystem_installation_authored_terrain_at(authored_world, x, y + 1),
      ecosystem_installation_authored_terrain_at(authored_world, x - 1, y),
    )
    for bit in [1, 2, 4, 8] {
      if (mask & bit) != 0 {
        result.push(
          @energy_valley_contract.installation(
            ecosystem_contract_scoped_id(
              "installation",
              "boardwalk-\{x}-\{y}-\{bit}",
            ),
            "温榆河滨水栈道",
            @energy_valley_contract.Boardwalk,
            @energy_valley_contract.installation_path(
              ecosystem_installation_boardwalk_edge(x, y, bit),
            ),
            reference,
            interactive=true,
            tags=["edge:\{bit}", "tile-x:\{x}", "tile-y:\{y}"],
          ),
        )
      }
    }
  }
  let road_lookup = ecosystem_parcel_road_lookup(snapshot)
  let park_lookup = ecosystem_parcel_park_lookup(snapshot)
  let custom_sites = ecosystem_terrain_custom_site_lookup(snapshot)
  for y in 0..<authored_world.rows {
    for x in 0..<authored_world.cols {
      let terrain = ecosystem_terrain_cell_class(
        authored_world, road_lookup, park_lookup, custom_sites, x, y,
      )
      if terrain.kind is @energy_valley_contract.Woodland ||
        park_lookup.contains(golden_valley_tile_key(x, y)) {
        result.push(
          @energy_valley_contract.installation(
            ecosystem_contract_scoped_id(
              "installation",
              "terrain-tree-\{x}-\{y}",
            ),
            if terrain.custom {
              "共建树木"
            } else {
              "温榆林木"
            },
            @energy_valley_contract.Tree,
            @energy_valley_contract.installation_point(
              @energy_valley_contract.world_point(
                x.to_double() + 0.5,
                y.to_double() + 0.5,
              ),
            ),
            ecosystem_installation_source_provenance(terrain.custom),
            tags=["kind:woodland"],
          ),
        )
      }
    }
  }
  // Benches and planters were previously tiny pseudo-Places. They now have
  // one semantic identity in the public-realm installation collection.
  for source in snapshot.places {
    if source.kind is EcosystemPublicRealm &&
      (source.style == "bench" || source.style == "planter") {
      result.push(
        @energy_valley_contract.installation(
          ecosystem_contract_id(source.id),
          source.name,
          if source.style == "bench" {
            @energy_valley_contract.Bench
          } else {
            @energy_valley_contract.Custom("planter")
          },
          @energy_valley_contract.installation_point(
            @energy_valley_contract.world_point(
              source.footprint.x.to_double() + 0.5,
              source.footprint.y.to_double() + 0.5,
            ),
          ),
          ecosystem_installation_source_provenance(
            source.source_id == "player-delta",
          ),
          interactive=source.style == "bench",
          tags=["district:\{source.district}", "style:\{source.style}"],
        ),
      )
    }
  }
  result
}

///|
fn ecosystem_contract_compilation_diagnostics(
  snapshot : EcosystemWorldSnapshot,
  road_network : @energy_valley_contract.RoadNetwork,
  parcel_plan : @energy_valley_contract.ParcelPlan,
  places : ArrayView[@energy_valley_contract.Place],
) -> Array[@energy_valley_contract.WorldDiagnostic] {
  let source = ecosystem_installation_source_provenance(false)
  [
    @energy_valley_contract.world_diagnostic(
      ecosystem_contract_scoped_id("diagnostic", "wenyu-evidence-accepted"),
      @energy_valley_contract.ReferenceEvidence,
      @energy_valley_contract.Information,
      @energy_valley_contract.EvidenceAccepted,
      "Wenyu typed evidence accepted: \{snapshot.cols}×\{snapshot.rows}",
      source,
      evidence_id=Some("wenyu_reference_labels.json"),
    ),
    @energy_valley_contract.world_diagnostic(
      ecosystem_contract_scoped_id("diagnostic", "road-graph-compiled"),
      @energy_valley_contract.RoadCompilation,
      @energy_valley_contract.Information,
      @energy_valley_contract.EvidenceAccepted,
      "Authoritative road graph: \{road_network.nodes.length()} nodes / \{road_network.segments.length()} segments",
      source,
      evidence_id=Some("wenyu_reference_roads.json"),
    ),
    @energy_valley_contract.world_diagnostic(
      ecosystem_contract_scoped_id("diagnostic", "land-blocks-compiled"),
      @energy_valley_contract.BlockCompilation,
      if parcel_plan.land_blocks.length() == 75 {
        @energy_valley_contract.Information
      } else {
        @energy_valley_contract.Failure
      },
      if parcel_plan.land_blocks.length() == 75 {
        @energy_valley_contract.EvidenceAccepted
      } else {
        @energy_valley_contract.GeometryConflict
      },
      "Road-enclosed blocks: \{parcel_plan.land_blocks.length()} / 75",
      source,
      evidence_id=Some("wenyu_reference_roads.json#enclosedLandBlocks"),
    ),
    @energy_valley_contract.world_diagnostic(
      ecosystem_contract_scoped_id("diagnostic", "places-compiled"),
      @energy_valley_contract.PlacementCompilation,
      @energy_valley_contract.Information,
      @energy_valley_contract.EvidenceAccepted,
      "Unified Place contract accepted \{places.length()} sites",
      source,
    ),
  ]
}

///|
fn ecosystem_contract_rejected_placements(
  snapshot : EcosystemWorldSnapshot,
  places : ArrayView[@energy_valley_contract.Place],
) -> Array[@energy_valley_contract.RejectedPlacement] {
  let result : Array[@energy_valley_contract.RejectedPlacement] = []
  for source in snapshot.places {
    if !(source.kind is EcosystemCustomBuilding) {
      continue
    }
    let id = ecosystem_contract_id(source.id)
    match
      places.search_by(place => place.id == id).map(index => places[index]) {
      None =>
        result.push(
          @energy_valley_contract.rejected_placement(
            ecosystem_contract_scoped_id(
              "rejected-placement",
              "missing-\{id.to_string()}",
            ),
            id,
            @energy_valley_contract.BuildingPlacement,
            @energy_valley_contract.grid_position(
              source.footprint.x,
              source.footprint.y,
            ),
            ecosystem_contract_footprint(source.footprint),
            @energy_valley_contract.OutsideParcel,
            "Player building was not accepted into the unified Place contract",
            energy_valley_world_delta_provenance(),
          ),
        )
      Some(place) => {
        if place.parcel_id is None {
          result.push(
            @energy_valley_contract.rejected_placement(
              ecosystem_contract_scoped_id(
                "rejected-placement",
                "parcel-\{id.to_string()}",
              ),
              id,
              @energy_valley_contract.BuildingPlacement,
              @energy_valley_contract.grid_position(
                source.footprint.x,
                source.footprint.y,
              ),
              ecosystem_contract_footprint(source.footprint),
              @energy_valley_contract.OutsideParcel,
              "Building is retained for inspection but lies outside every accepted buildable parcel",
              energy_valley_world_delta_provenance(),
            ),
          )
        }
        if !place.traits.contains(@energy_valley_contract.Accessible) {
          result.push(
            @energy_valley_contract.rejected_placement(
              ecosystem_contract_scoped_id(
                "rejected-placement",
                "access-\{id.to_string()}",
              ),
              id,
              @energy_valley_contract.BuildingPlacement,
              @energy_valley_contract.grid_position(
                source.footprint.x,
                source.footprint.y,
              ),
              ecosystem_contract_footprint(source.footprint),
              @energy_valley_contract.NoReachableEntrance,
              "Building is retained for inspection but has no reachable road portal",
              energy_valley_world_delta_provenance(),
              parcel_id=place.parcel_id,
            ),
          )
        }
      }
    }
  }
  result
}
