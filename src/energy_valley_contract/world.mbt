///|
/// The sole renderer-neutral spatial result of the Energy Valley compiler.
/// All collections are read-only snapshots; runtime ledgers bind through IDs.
pub(all) struct CompiledTownWorld {
  schema_version : String
  blueprint_id : StableId
  blueprint_digest : String
  layout_seed : Int
  bounds : WorldBounds
  terrain_regions : ReadOnlyArray[TerrainRegion]
  road_network : RoadNetwork
  land_blocks : ReadOnlyArray[LandBlock]
  parcels : ReadOnlyArray[Parcel]
  parcel_programs : ReadOnlyArray[ParcelProgram]
  parcel_program_assignments : ReadOnlyArray[ParcelProgramAssignment]
  places : ReadOnlyArray[Place]
  place_relations : ReadOnlyArray[PlaceRelation]
  installations : ReadOnlyArray[Installation]
  attention_targets : ReadOnlyArray[AttentionTarget]
  diagnostics : ReadOnlyArray[WorldDiagnostic]
  rejected_placements : ReadOnlyArray[RejectedPlacement]
} derive(Debug, Eq)

///|
pub fn compiled_town_world(
  schema_version : String,
  blueprint_id : StableId,
  blueprint_digest : String,
  layout_seed : Int,
  bounds : WorldBounds,
  terrain_regions : ArrayView[TerrainRegion],
  road_network : RoadNetwork,
  land_blocks : ArrayView[LandBlock],
  parcels : ArrayView[Parcel],
  places : ArrayView[Place],
  attention_targets : ArrayView[AttentionTarget],
  parcel_programs? : ArrayView[ParcelProgram] = [],
  parcel_program_assignments? : ArrayView[ParcelProgramAssignment] = [],
  place_relations? : ArrayView[PlaceRelation] = [],
  installations? : ArrayView[Installation] = [],
  diagnostics? : ArrayView[WorldDiagnostic] = [],
  rejected_placements? : ArrayView[RejectedPlacement] = [],
) -> CompiledTownWorld {
  {
    schema_version,
    blueprint_id,
    blueprint_digest,
    layout_seed,
    bounds,
    terrain_regions: freeze(terrain_regions),
    road_network,
    land_blocks: freeze(land_blocks),
    parcels: freeze(parcels),
    parcel_programs: freeze(parcel_programs),
    parcel_program_assignments: freeze(parcel_program_assignments),
    places: freeze(places),
    place_relations: freeze(place_relations),
    installations: freeze(installations),
    attention_targets: freeze(attention_targets),
    diagnostics: freeze(diagnostics),
    rejected_placements: freeze(rejected_placements),
  }
}

///|
pub fn CompiledTownWorld::find_parcel_program(
  self : CompiledTownWorld,
  id : StableId,
) -> ParcelProgram? {
  self.parcel_programs
  .search_by(program => program.id == id)
  .map(index => self.parcel_programs[index])
}

///|
pub fn CompiledTownWorld::parcel_program_for(
  self : CompiledTownWorld,
  parcel_id : StableId,
) -> ParcelProgram? {
  match
    self.parcel_program_assignments.search_by(assignment => {
      assignment.parcel_id == parcel_id
    }) {
    None => None
    Some(index) =>
      self.find_parcel_program(
        self.parcel_program_assignments[index].program_id,
      )
  }
}

///|
pub fn CompiledTownWorld::find_block(
  self : CompiledTownWorld,
  id : StableId,
) -> LandBlock? {
  self.land_blocks
  .search_by(block => block.id == id)
  .map(index => self.land_blocks[index])
}

///|
pub fn CompiledTownWorld::find_parcel(
  self : CompiledTownWorld,
  id : StableId,
) -> Parcel? {
  self.parcels
  .search_by(parcel => parcel.id == id)
  .map(index => self.parcels[index])
}

///|
pub fn CompiledTownWorld::find_place(
  self : CompiledTownWorld,
  id : StableId,
) -> Place? {
  self.places
  .search_by(place => place.id == id)
  .map(index => self.places[index])
}

///|
pub fn CompiledTownWorld::relations_from(
  self : CompiledTownWorld,
  source_place_id : StableId,
) -> ReadOnlyArray[PlaceRelation] {
  self.place_relations.filter(relation => {
    relation.source_place_id == source_place_id
  })
}

///|
pub fn CompiledTownWorld::relations_for(
  self : CompiledTownWorld,
  place_id : StableId,
) -> ReadOnlyArray[PlaceRelation] {
  self.place_relations.filter(relation => {
    relation.source_place_id == place_id || relation.target_place_id == place_id
  })
}

///|
pub fn CompiledTownWorld::find_installation(
  self : CompiledTownWorld,
  id : StableId,
) -> Installation? {
  self.installations
  .search_by(installation => installation.id == id)
  .map(index => self.installations[index])
}

///|
pub fn CompiledTownWorld::diagnostics_for(
  self : CompiledTownWorld,
  entity_id : StableId,
) -> ReadOnlyArray[WorldDiagnostic] {
  self.diagnostics.filter(diagnostic => diagnostic.entity_id == Some(entity_id))
}

///|
pub fn CompiledTownWorld::rejections_for(
  self : CompiledTownWorld,
  candidate_id : StableId,
) -> ReadOnlyArray[RejectedPlacement] {
  self.rejected_placements.filter(rejection => {
    rejection.candidate_id == candidate_id
  })
}

///|
pub fn CompiledTownWorld::find_attention_target(
  self : CompiledTownWorld,
  id : StableId,
) -> AttentionTarget? {
  self.attention_targets
  .search_by(target => target.id == id)
  .map(index => self.attention_targets[index])
}

///|
pub fn CompiledTownWorld::find_interaction_slot(
  self : CompiledTownWorld,
  id : StableId,
) -> InteractionSlot? {
  for place in self.places {
    match place.find_slot(id) {
      Some(slot) => return Some(slot)
      None => ()
    }
  }
  None
}

///|
pub(all) struct TownSnapshot {
  world : CompiledTownWorld
  tick : Int
  attention_signals : ReadOnlyArray[AttentionSignal]
  attention_focuses : ReadOnlyArray[AttentionFocus]
  actor_profiles : ReadOnlyArray[ActorProfile]
  actor_presences : ReadOnlyArray[ActorPresence]
  place_exchanges : ReadOnlyArray[PlaceExchange]
} derive(Debug, Eq)

///|
pub fn town_snapshot(
  world : CompiledTownWorld,
  tick : Int,
  attention_signals : ArrayView[AttentionSignal],
  attention_focuses : ArrayView[AttentionFocus],
  actor_profiles? : ArrayView[ActorProfile] = [],
  actor_presences? : ArrayView[ActorPresence] = [],
  place_exchanges? : ArrayView[PlaceExchange] = [],
) -> TownSnapshot {
  {
    world,
    tick,
    attention_signals: freeze(attention_signals),
    attention_focuses: freeze(attention_focuses),
    actor_profiles: freeze(actor_profiles),
    actor_presences: freeze(actor_presences),
    place_exchanges: freeze(place_exchanges),
  }
}

///|
pub fn TownSnapshot::find_actor_profile(
  self : TownSnapshot,
  actor_id : StableId,
) -> ActorProfile? {
  self.actor_profiles
  .search_by(profile => profile.actor_id == actor_id)
  .map(index => self.actor_profiles[index])
}

///|
pub fn TownSnapshot::active_signals(
  self : TownSnapshot,
) -> ReadOnlyArray[AttentionSignal] {
  self.attention_signals.filter(signal => signal.is_active(self.tick))
}

///|
pub fn TownSnapshot::signals_for(
  self : TownSnapshot,
  target_id : StableId,
) -> ReadOnlyArray[AttentionSignal] {
  self.attention_signals.filter(signal => {
    signal.target_id == target_id && signal.is_active(self.tick)
  })
}

///|
pub fn TownSnapshot::active_presences(
  self : TownSnapshot,
) -> ReadOnlyArray[ActorPresence] {
  self.actor_presences.filter(presence => presence.is_active(self.tick))
}

///|
pub fn TownSnapshot::presences_at(
  self : TownSnapshot,
  place_id : StableId,
) -> ReadOnlyArray[ActorPresence] {
  self.actor_presences.filter(presence => {
    presence.place_id == place_id && presence.is_active(self.tick)
  })
}

///|
/// Active actors whose semantic position can be rendered in the public realm
/// without consulting a renderer-local activity model.
pub fn TownSnapshot::outdoor_presences(
  self : TownSnapshot,
) -> ReadOnlyArray[ActorPresence] {
  self.actor_presences.filter(presence => {
    presence.is_active(self.tick) && presence.is_outdoor()
  })
}

///|
pub fn TownSnapshot::active_exchanges(
  self : TownSnapshot,
) -> ReadOnlyArray[PlaceExchange] {
  self.place_exchanges.filter(exchange => exchange.is_active(self.tick))
}

///|
pub fn TownSnapshot::exchanges_for(
  self : TownSnapshot,
  place_id : StableId,
) -> ReadOnlyArray[PlaceExchange] {
  self.place_exchanges.filter(exchange => {
    (
      exchange.source_place_id == place_id ||
      exchange.target_place_id == place_id
    ) &&
    exchange.is_active(self.tick)
  })
}
