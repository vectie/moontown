///|
pub(all) enum RuntimeSystem {
  MoonBook
  MoonClaw
  TownRuntime
  External(String)
} derive(Debug, Eq)

///|
/// A semantic link only. Runtime state remains authoritative in its own ledger.
pub(all) struct RuntimeBinding {
  system : RuntimeSystem
  resource_id : String
  capability : String
} derive(Debug, Eq)

///|
pub fn runtime_binding(
  system : RuntimeSystem,
  resource_id : String,
  capability : String,
) -> RuntimeBinding {
  { system, resource_id, capability }
}

///|
pub(all) enum PlaceKind {
  Building
  Park
  Plaza
  TransitStation
  Waterfront
  Landmark
  Installation
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) enum PlaceTrait {
  Public
  Landmark
  Waterfront
  Social
  KnowledgeWork
  RuntimeWork
  Quiet
  Playful
  NightActive
  Accessible
  Signature(String)
} derive(Debug, Eq)

///|
pub(all) enum RoofKind {
  Flat
  Garden
  Gabled
  Glass
  Sculptural
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct BuildingProfile {
  archetype : String
  floors : Int
  height_meters : Double
  roof : RoofKind
  interior_seed : Int
} derive(Debug, Eq)

///|
pub fn building_profile(
  archetype : String,
  floors : Int,
  height_meters : Double,
  roof : RoofKind,
  interior_seed : Int,
) -> BuildingProfile {
  { archetype, floors, height_meters, roof, interior_seed }
}

///|
pub(all) enum InteractionKind {
  Workstation
  MeetingPoint
  ExchangeDesk
  Exhibit
  Bench
  Stage
  TransitGate
  ServicePoint
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct EntrancePortal {
  id : StableId
  position : WorldPoint
  road_node_id : StableId?
  mobility : ReadOnlyArray[MobilityMode]
  primary : Bool
} derive(Debug, Eq)

///|
pub fn entrance_portal(
  id : StableId,
  position : WorldPoint,
  road_node_id : StableId?,
  mobility : ArrayView[MobilityMode],
  primary? : Bool = false,
) -> EntrancePortal {
  { id, position, road_node_id, mobility: freeze(mobility), primary }
}

///|
pub(all) struct InteractionSlot {
  id : StableId
  kind : InteractionKind
  label : String
  position : WorldPoint
  capacity : Int
  attention_target_id : StableId?
  runtime_binding : RuntimeBinding?
} derive(Debug, Eq)

///|
pub fn interaction_slot(
  id : StableId,
  kind : InteractionKind,
  label : String,
  position : WorldPoint,
  capacity : Int,
  attention_target_id : StableId?,
  runtime_binding : RuntimeBinding?,
) -> InteractionSlot {
  { id, kind, label, position, capacity, attention_target_id, runtime_binding }
}

///|
/// A single spatial identity for buildings, parks, stations, and landmarks.
/// `building` adds massing/interior identity without creating a second ID.
pub(all) struct Place {
  id : StableId
  name : String
  kind : PlaceKind
  parcel_id : StableId?
  program_id : StableId?
  footprint : Polygon
  entrances : ReadOnlyArray[EntrancePortal]
  traits : ReadOnlyArray[PlaceTrait]
  interaction_slots : ReadOnlyArray[InteractionSlot]
  building : BuildingProfile?
  runtime_binding : RuntimeBinding?
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn place(
  id : StableId,
  name : String,
  kind : PlaceKind,
  parcel_id : StableId?,
  footprint : Polygon,
  entrances : ArrayView[EntrancePortal],
  traits : ArrayView[PlaceTrait],
  interaction_slots : ArrayView[InteractionSlot],
  building : BuildingProfile?,
  runtime_binding : RuntimeBinding?,
  provenance : Provenance,
  program_id? : StableId? = None,
) -> Place {
  {
    id,
    name,
    kind,
    parcel_id,
    program_id,
    footprint,
    entrances: freeze(entrances),
    traits: freeze(traits),
    interaction_slots: freeze(interaction_slots),
    building,
    runtime_binding,
    provenance,
  }
}

///|
pub fn Place::primary_entrance(self : Place) -> EntrancePortal? {
  self.entrances
  .search_by(portal => portal.primary)
  .map(index => self.entrances[index])
}

///|
pub fn Place::find_slot(self : Place, id : StableId) -> InteractionSlot? {
  self.interaction_slots
  .search_by(slot => slot.id == id)
  .map(index => self.interaction_slots[index])
}

///|
pub fn Place::supports_runtime_work(self : Place) -> Bool {
  self.runtime_binding is Some(_) ||
  self.interaction_slots.any(slot => slot.runtime_binding is Some(_))
}

///|
/// A renderer-neutral relationship between two accepted semantic places.
/// These links describe stable town structure; time-varying traffic belongs in
/// `PlaceExchange` on `TownSnapshot`.
pub(all) enum PlaceRelationKind {
  Collaboration
  Dependency
  KnowledgeFlow
  Custom(String)
} derive(Debug, Eq)

///|
pub(all) struct PlaceRelation {
  id : StableId
  source_place_id : StableId
  target_place_id : StableId
  kind : PlaceRelationKind
  label : String
  provenance : Provenance
} derive(Debug, Eq)

///|
pub fn place_relation(
  id : StableId,
  source_place_id : StableId,
  target_place_id : StableId,
  kind : PlaceRelationKind,
  label : String,
  provenance : Provenance,
) -> PlaceRelation {
  { id, source_place_id, target_place_id, kind, label, provenance }
}
