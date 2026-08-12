///|
/// Map Lab is a read-only diagnostic lens over the accepted semantic world.
/// The entity inventory is intentionally flattened so every rendered mark can
/// be traced back to one StableId without teaching the panel renderer about
/// legacy scene types.
priv struct MapLabEntity {
  id : String
  category : String
  label : String
  provenance : String
  facts : Array[(String, String)]
}

///|
/// The browser needs only these three fields. Keeping rows separate from the
/// selected detail prevents a 15k-installation world from allocating facts and
/// provenance copy for entities that can never enter the 40-row viewport.
priv struct MapLabEntityRow {
  selection_key : String
  id : String
  category : String
  label : String
}

///|
priv struct MapLabEntityPage {
  rows : Array[MapLabEntityRow]
  scanned : Int
  detail_materializations : Int
}

///|
priv struct MapLabCounts {
  terrain : Int
  blocks : Int
  parcels : Int
  programs : Int
  road_nodes : Int
  road_segments : Int
  places : Int
  relations : Int
  installations : Int
  portals : Int
  slots : Int
  actor_profiles : Int
  attention_signals : Int
  attention_focuses : Int
  presences : Int
  exchanges : Int
  diagnostics : Int
  rejections : Int
  warnings : Int
  errors : Int
}

///|
/// Read-only UI state for the Map Lab shell. Page orchestration projects these
/// presentation fields from TEA application state. The diagnostic surface
/// therefore depends only on this view record and the accepted snapshot.
priv struct MapLabViewState {
  open : Bool
  layers : Array[MapLabLayer]
  selected_id : String
  query : String
}

///|
fn map_lab_layer_enabled(
  layers : Array[MapLabLayer],
  layer : MapLabLayer,
) -> Bool {
  layers.contains(layer)
}

///|
fn map_lab_toggle_layer(
  layers : Array[MapLabLayer],
  layer : MapLabLayer,
) -> Array[MapLabLayer] {
  if layers.contains(layer) {
    layers.filter(item => item != layer)
  } else {
    let next = layers.copy()
    next.push(layer)
    next
  }
}

///|
fn map_lab_layer_label(layer : MapLabLayer) -> String {
  match layer {
    MapLabSourceEvidence => "源证据"
    MapLabTerrain => "地形"
    MapLabLandBlocks => "精确地块"
    MapLabParcelsPrograms => "地籍 / 程序"
    MapLabRoadsNavigation => "道路 / 导航"
    MapLabPortalsSpurs => "入口 / 支路"
    MapLabPublicRealm => "公共空间 / 装置"
    MapLabActivity => "在场 / 交换"
    MapLabProvenance => "来源谱系"
    MapLabValidation => "校验 / 拒绝"
  }
}

///|
fn map_lab_layer_slug(layer : MapLabLayer) -> String {
  match layer {
    MapLabSourceEvidence => "source"
    MapLabTerrain => "terrain"
    MapLabLandBlocks => "blocks"
    MapLabParcelsPrograms => "parcels"
    MapLabRoadsNavigation => "roads"
    MapLabPortalsSpurs => "portals"
    MapLabPublicRealm => "public-realm"
    MapLabActivity => "activity"
    MapLabProvenance => "provenance"
    MapLabValidation => "validation"
  }
}

///|
fn map_lab_all_layers() -> Array[MapLabLayer] {
  [
    MapLabSourceEvidence,
    MapLabTerrain,
    MapLabLandBlocks,
    MapLabParcelsPrograms,
    MapLabRoadsNavigation,
    MapLabPortalsSpurs,
    MapLabPublicRealm,
    MapLabActivity,
    MapLabProvenance,
    MapLabValidation,
  ]
}

///|
fn map_lab_optional_id(id : @energy_valley_contract.StableId?) -> String {
  match id {
    Some(value) => value.to_string()
    None => "—"
  }
}

///|
fn map_lab_stable_ids(
  ids : ReadOnlyArray[@energy_valley_contract.StableId],
) -> String {
  let labels : Array[String] = []
  for id in ids {
    labels.push(id.to_string())
  }
  if labels.is_empty() {
    "—"
  } else {
    labels.join(", ")
  }
}

///|
fn map_lab_provenance_kind_label(
  kind : @energy_valley_contract.ProvenanceKind,
) -> String {
  match kind {
    WenyuReference => "WENYU_REFERENCE"
    Procedural => "PROCEDURAL"
    UserDelta => "USER_DELTA"
    RuntimeProjection => "RUNTIME_PROJECTION"
    Derived => "DERIVED"
  }
}

///|
fn map_lab_preservation_label(
  preservation : @energy_valley_contract.PreservationLevel,
) -> String {
  match preservation {
    Fixed => "FIXED"
    Bounded => "BOUNDED"
    Statistical => "STATISTICAL"
    Free => "FREE"
  }
}

///|
fn map_lab_provenance_copy(
  provenance : @energy_valley_contract.Provenance,
) -> String {
  "\{map_lab_provenance_kind_label(provenance.kind)} · \{provenance.source_id}@\{provenance.source_version} · \{map_lab_preservation_label(provenance.preservation)} · \{provenance.confidence_per_mille / 10}%"
}

///|
fn map_lab_terrain_label(kind : @energy_valley_contract.TerrainKind) -> String {
  match kind {
    Meadow => "meadow"
    Woodland => "woodland"
    Water => "water"
    Wetland => "wetland"
    Paving => "paving"
    Restricted => "restricted"
    Custom(label) => label
  }
}

///|
fn map_lab_land_use_label(kind : @energy_valley_contract.LandUse) -> String {
  match kind {
    Civic => "civic"
    Research => "research"
    Residential => "residential"
    MixedUse => "mixed-use"
    Park => "park"
    Waterfront => "waterfront"
    Transit => "transit"
    Utility => "utility"
    Custom(label) => label
  }
}

///|
fn map_lab_road_class_label(kind : @energy_valley_contract.RoadClass) -> String {
  match kind {
    Arterial => "arterial"
    Collector => "collector"
    Local => "local"
    Service => "service"
    Footpath => "footpath"
    Bridge => "bridge"
  }
}

///|
fn map_lab_place_kind_label(kind : @energy_valley_contract.PlaceKind) -> String {
  match kind {
    Building => "building"
    Park => "park"
    Plaza => "plaza"
    TransitStation => "transit-station"
    Waterfront => "waterfront"
    Landmark => "landmark"
    Installation => "installation"
    Custom(label) => label
  }
}

///|
fn map_lab_installation_kind_label(
  kind : @energy_valley_contract.InstallationKind,
) -> String {
  match kind {
    MetroAlignment => "metro-alignment"
    Boardwalk => "boardwalk"
    Tree => "tree"
    Light => "light"
    Bench => "bench"
    TransitEntrance => "transit-entrance"
    Signage => "signage"
    Custom(label) => label
  }
}

///|
fn map_lab_installation_geometry_label(
  geometry : @energy_valley_contract.InstallationGeometry,
) -> String {
  match geometry {
    AtPoint(_) => "point"
    AlongPath(points) => "path · \{points.length()} points"
    WithinArea(boundary) => "area · \{boundary.vertices.length()} vertices"
  }
}

///|
fn map_lab_rejection_reason_label(
  reason : @energy_valley_contract.PlacementRejectionReason,
) -> String {
  match reason {
    OutsideWorld => "outside-world"
    OutsideParcel => "outside-parcel"
    IntersectsWater => "intersects-water"
    IntersectsRoad => "intersects-road"
    Occupied => "occupied"
    NoReachableEntrance => "no-reachable-entrance"
    ProgramMismatch => "program-mismatch"
    DeltaConflictReason => "delta-conflict"
    CustomReason(label) => label
  }
}

///|
fn map_lab_diagnostic_stage_label(
  stage : @energy_valley_contract.WorldCompileStage,
) -> String {
  match stage {
    ReferenceEvidence => "reference-evidence"
    TerrainCompilation => "terrain-compilation"
    RoadCompilation => "road-compilation"
    BlockCompilation => "block-compilation"
    ParcelCompilation => "parcel-compilation"
    PlacementCompilation => "placement-compilation"
    AccessCompilation => "access-compilation"
    DeltaApplication => "delta-application"
    RuntimeProjection => "runtime-projection"
    Custom(label) => label
  }
}

///|
fn map_lab_diagnostic_severity_label(
  severity : @energy_valley_contract.WorldDiagnosticSeverity,
) -> String {
  match severity {
    Information => "information"
    Caution => "caution"
    Failure => "failure"
  }
}

///|
fn map_lab_diagnostic_code_label(
  code : @energy_valley_contract.WorldDiagnosticCode,
) -> String {
  match code {
    EvidenceAccepted => "evidence-accepted"
    EvidenceMissing => "evidence-missing"
    GeometryAdjusted => "geometry-adjusted"
    GeometryConflict => "geometry-conflict"
    AccessAdjusted => "access-adjusted"
    AccessConflict => "access-conflict"
    DeltaConflict => "delta-conflict"
    UnsupportedSchema => "unsupported-schema"
    PlacementRejected => "placement-rejected"
    Custom(label) => label
  }
}

///|
fn map_lab_interaction_label(
  kind : @energy_valley_contract.InteractionKind,
) -> String {
  match kind {
    Workstation => "workstation"
    MeetingPoint => "meeting-point"
    ExchangeDesk => "exchange-desk"
    Exhibit => "exhibit"
    Bench => "bench"
    Stage => "stage"
    TransitGate => "transit-gate"
    ServicePoint => "service-point"
    Custom(label) => label
  }
}

///|
fn map_lab_presence_label(
  phase : @energy_valley_contract.PresencePhase,
) -> String {
  match phase {
    Approaching => "approaching"
    AtEntrance => "at-entrance"
    Inside => "inside"
    Departing => "departing"
    Away => "away"
  }
}

///|
fn map_lab_actor_source_label(
  source : @energy_valley_contract.ActorSourceKind,
) -> String {
  match source {
    AmbientSimulation => "ambient simulation"
    RuntimeEvidence => "runtime evidence"
    LocalEmbodiment => "local embodiment"
  }
}

///|
fn map_lab_actor_state_label(
  state : @energy_valley_contract.ActorStateKind,
) -> String {
  match state {
    ActorStateActive => "active"
    ActorStateWaitingReview => "waiting review"
    ActorStateBlocked => "blocked"
    ActorStateFailed => "failed"
    ActorStateCompleted => "completed"
    ActorStateAssigned => "assigned"
    ActorStateIdle => "idle"
  }
}

///|
fn map_lab_attention_signal_kind_label(
  kind : @energy_valley_contract.AttentionSignalKind,
) -> String {
  match kind {
    Motion => "motion"
    Sound => "sound"
    Social => "social"
    Work => "work"
    Novelty => "novelty"
    Need => "need"
    Reward => "reward"
    Ambient => "ambient"
    Custom(label) => label
  }
}

///|
fn map_lab_exchange_label(
  kind : @energy_valley_contract.ExchangeKind,
) -> String {
  match kind {
    Knowledge => "knowledge"
    Social => "social"
    Delivery => "delivery"
    Service => "service"
    Mobility => "mobility"
    Care => "care"
    Custom(label) => label
  }
}

///|
fn map_lab_place_relation_kind_label(
  kind : @energy_valley_contract.PlaceRelationKind,
) -> String {
  match kind {
    Collaboration => "collaboration"
    Dependency => "dependency"
    KnowledgeFlow => "knowledge flow"
    Custom(label) => label
  }
}

///|
fn map_lab_blueprint_entity(
  world : @energy_valley_contract.CompiledTownWorld,
) -> MapLabEntity {
  {
    id: world.blueprint_id.to_string(),
    category: "blueprint",
    label: "CompiledTownWorld",
    provenance: "schema \{world.schema_version}",
    facts: [
      ("digest", world.blueprint_digest),
      ("layout seed", world.layout_seed.to_string()),
      ("schema", world.schema_version),
    ],
  }
}

///|
fn map_lab_terrain_entity(
  region : @energy_valley_contract.TerrainRegion,
) -> MapLabEntity {
  {
    id: region.id.to_string(),
    category: "terrain",
    label: map_lab_terrain_label(region.kind),
    provenance: map_lab_provenance_copy(region.provenance),
    facts: [
      ("walkable", if region.walkable { "yes" } else { "no" }),
      ("vertices", region.boundary.vertices.length().to_string()),
    ],
  }
}

///|
fn map_lab_land_block_entity(
  block : @energy_valley_contract.LandBlock,
) -> MapLabEntity {
  {
    id: block.id.to_string(),
    category: "land block",
    label: map_lab_land_use_label(block.land_use),
    provenance: map_lab_provenance_copy(block.provenance),
    facts: [
      ("parcels", block.parcel_ids.length().to_string()),
      ("buildable regions", block.buildable_regions.length().to_string()),
      ("parcelable", if block.parcelable { "yes" } else { "no" }),
      ("frontages", block.frontage_segment_ids.length().to_string()),
      ("preservation", map_lab_preservation_label(block.preservation)),
    ],
  }
}

///|
fn map_lab_parcel_entity(
  world : @energy_valley_contract.CompiledTownWorld,
  parcel : @energy_valley_contract.Parcel,
) -> MapLabEntity {
  let program = world.parcel_program_for(parcel.id)
  {
    id: parcel.id.to_string(),
    category: "parcel",
    label: map_lab_land_use_label(parcel.land_use),
    provenance: map_lab_provenance_copy(parcel.provenance),
    facts: [
      ("block", parcel.block_id.to_string()),
      (
        "program",
        match program {
          Some(value) => value.id.to_string()
          None => "—"
        },
      ),
      ("frontages", map_lab_stable_ids(parcel.frontage_segment_ids)),
    ],
  }
}

///|
fn map_lab_parcel_program_entity(
  program : @energy_valley_contract.ParcelProgram,
) -> MapLabEntity {
  {
    id: program.id.to_string(),
    category: "parcel program",
    label: program.label,
    provenance: "compiled program",
    facts: [
      ("weight", program.weight.to_string()),
      (
        "requires frontage",
        if program.requires_frontage {
          "yes"
        } else {
          "no"
        },
      ),
      ("minimum area", "\{program.minimum_area_sqm} m²"),
    ],
  }
}

///|
fn map_lab_program_assignment_entity(
  assignment : @energy_valley_contract.ParcelProgramAssignment,
) -> MapLabEntity {
  {
    id: assignment.id.to_string(),
    category: "program assignment",
    label: assignment.program_id.local_key(),
    provenance: map_lab_provenance_copy(assignment.provenance),
    facts: [
      ("parcel", assignment.parcel_id.to_string()),
      ("program", assignment.program_id.to_string()),
      ("frontage", map_lab_optional_id(assignment.frontage_segment_id)),
      ("variant seed", assignment.variant_seed.to_string()),
    ],
  }
}

///|
fn map_lab_road_node_entity(
  world : @energy_valley_contract.CompiledTownWorld,
  node : @energy_valley_contract.RoadNode,
) -> MapLabEntity {
  {
    id: node.id.to_string(),
    category: "road node",
    label: "\{node.grid.column}, \{node.grid.row}",
    provenance: map_lab_provenance_copy(node.provenance),
    facts: [
      ("world x", node.position.x.to_string()),
      ("world y", node.position.y.to_string()),
      (
        "access anchor",
        if world.road_network.access_anchor_node_ids.contains(node.id) {
          "yes"
        } else {
          "no"
        },
      ),
    ],
  }
}

///|
fn map_lab_road_segment_entity(
  segment : @energy_valley_contract.RoadSegment,
) -> MapLabEntity {
  {
    id: segment.id.to_string(),
    category: "road segment",
    label: map_lab_road_class_label(segment.road_class),
    provenance: map_lab_provenance_copy(segment.provenance),
    facts: [
      ("from", segment.from_node_id.to_string()),
      ("to", segment.to_node_id.to_string()),
      ("width", "\{segment.width_meters} m"),
      ("bidirectional", if segment.bidirectional { "yes" } else { "no" }),
    ],
  }
}

///|
fn map_lab_place_entity(place : @energy_valley_contract.Place) -> MapLabEntity {
  {
    id: place.id.to_string(),
    category: "place",
    label: place.name,
    provenance: map_lab_provenance_copy(place.provenance),
    facts: [
      ("kind", map_lab_place_kind_label(place.kind)),
      ("parcel", map_lab_optional_id(place.parcel_id)),
      ("program", map_lab_optional_id(place.program_id)),
      ("portals", place.entrances.length().to_string()),
      ("slots", place.interaction_slots.length().to_string()),
      (
        "runtime binding",
        match place.runtime_binding {
          Some(binding) => "\{binding.resource_id} · \{binding.capability}"
          None => "—"
        },
      ),
    ],
  }
}

///|
fn map_lab_portal_entity(
  place : @energy_valley_contract.Place,
  portal : @energy_valley_contract.EntrancePortal,
) -> MapLabEntity {
  {
    id: portal.id.to_string(),
    category: "portal",
    label: "\{place.name} · \{if portal.primary { "primary" } else { "secondary" }}",
    provenance: map_lab_provenance_copy(place.provenance),
    facts: [
      ("place", place.id.to_string()),
      ("road node", map_lab_optional_id(portal.road_node_id)),
      ("world x", portal.position.x.to_string()),
      ("world y", portal.position.y.to_string()),
    ],
  }
}

///|
fn map_lab_interaction_slot_entity(
  place : @energy_valley_contract.Place,
  slot : @energy_valley_contract.InteractionSlot,
) -> MapLabEntity {
  {
    id: slot.id.to_string(),
    category: "interaction slot",
    label: slot.label,
    provenance: map_lab_provenance_copy(place.provenance),
    facts: [
      ("place", place.id.to_string()),
      ("kind", map_lab_interaction_label(slot.kind)),
      ("capacity", slot.capacity.to_string()),
      ("attention target", map_lab_optional_id(slot.attention_target_id)),
    ],
  }
}

///|
fn map_lab_place_relation_entity(
  relation : @energy_valley_contract.PlaceRelation,
) -> MapLabEntity {
  {
    id: relation.id.to_string(),
    category: "place relation",
    label: relation.label,
    provenance: map_lab_provenance_copy(relation.provenance),
    facts: [
      ("source", relation.source_place_id.to_string()),
      ("target", relation.target_place_id.to_string()),
      ("kind", map_lab_place_relation_kind_label(relation.kind)),
    ],
  }
}

///|
fn map_lab_attention_target_entity(
  target : @energy_valley_contract.AttentionTarget,
) -> MapLabEntity {
  {
    id: target.id.to_string(),
    category: "attention target",
    label: target.label,
    provenance: "semantic target",
    facts: [
      ("owner", map_lab_optional_id(target.owner_id)),
      ("salience", target.base_salience_per_mille.to_string()),
    ],
  }
}

///|
fn map_lab_installation_entity(
  installation : @energy_valley_contract.Installation,
) -> MapLabEntity {
  {
    id: installation.id.to_string(),
    category: "installation",
    label: installation.label,
    provenance: map_lab_provenance_copy(installation.provenance),
    facts: [
      ("kind", map_lab_installation_kind_label(installation.kind)),
      ("geometry", map_lab_installation_geometry_label(installation.geometry)),
      ("owner", map_lab_optional_id(installation.owner_place_id)),
      ("road segments", installation.road_segment_ids.length().to_string()),
      ("interactive", if installation.interactive { "yes" } else { "no" }),
    ],
  }
}

///|
fn map_lab_world_diagnostic_entity(
  diagnostic : @energy_valley_contract.WorldDiagnostic,
) -> MapLabEntity {
  {
    id: diagnostic.id.to_string(),
    category: "world diagnostic",
    label: diagnostic.message,
    provenance: map_lab_provenance_copy(diagnostic.provenance),
    facts: [
      ("stage", map_lab_diagnostic_stage_label(diagnostic.stage)),
      ("severity", map_lab_diagnostic_severity_label(diagnostic.severity)),
      ("code", map_lab_diagnostic_code_label(diagnostic.code)),
      ("entity", map_lab_optional_id(diagnostic.entity_id)),
      ("evidence", diagnostic.evidence_id.unwrap_or("—")),
    ],
  }
}

///|
fn map_lab_actor_profile_selection_key(
  actor_id : @energy_valley_contract.StableId,
) -> String {
  "actor-profile::\{actor_id.to_string()}"
}

///|
fn map_lab_actor_profile_entity(
  profile : @energy_valley_contract.ActorProfile,
) -> MapLabEntity {
  {
    id: profile.actor_id.to_string(),
    category: "actor profile",
    label: profile.display_name,
    provenance: map_lab_provenance_copy(profile.provenance),
    facts: [
      ("role", profile.role_label),
      ("avatar family", profile.avatar_family),
      ("avatar variant", profile.avatar_variant.to_string()),
      ("palette variant", profile.palette_variant.to_string()),
      ("source", map_lab_actor_source_label(profile.source_kind)),
      ("state", map_lab_actor_state_label(profile.state)),
    ],
  }
}

///|
fn map_lab_attention_signal_entity(
  signal : @energy_valley_contract.AttentionSignal,
  tick : Int,
) -> MapLabEntity {
  {
    id: signal.id.to_string(),
    category: "attention signal",
    label: map_lab_attention_signal_kind_label(signal.kind),
    provenance: "dynamic attention ledger",
    facts: [
      ("target", signal.target_id.to_string()),
      ("source", map_lab_optional_id(signal.source_id)),
      ("intensity", signal.intensity_per_mille.to_string()),
      ("started", signal.started_tick.to_string()),
      (
        "expires",
        signal.expires_tick.map(value => value.to_string()).unwrap_or("—"),
      ),
      ("active", if signal.is_active(tick) { "yes" } else { "no" }),
    ],
  }
}

///|
fn map_lab_attention_focus_selection_key(
  focus : @energy_valley_contract.AttentionFocus,
) -> String {
  "attention-focus::\{focus.actor_id.to_string()}::\{focus.target_id.to_string()}"
}

///|
fn map_lab_attention_focus_entity(
  focus : @energy_valley_contract.AttentionFocus,
) -> MapLabEntity {
  {
    id: focus.actor_id.to_string(),
    category: "attention focus",
    label: "tracking \{focus.target_id.local_key()}",
    provenance: "dynamic attention ledger",
    facts: [
      ("actor", focus.actor_id.to_string()),
      ("target", focus.target_id.to_string()),
      ("strength", focus.strength_per_mille.to_string()),
      ("since", focus.since_tick.to_string()),
    ],
  }
}

///|
fn map_lab_actor_presence_selection_key(
  actor_id : @energy_valley_contract.StableId,
) -> String {
  "actor-presence::\{actor_id.to_string()}"
}

///|
fn map_lab_actor_presence_entity(
  presence : @energy_valley_contract.ActorPresence,
) -> MapLabEntity {
  {
    id: presence.actor_id.to_string(),
    category: "actor presence",
    label: presence.intention,
    provenance: map_lab_provenance_copy(presence.provenance),
    facts: [
      ("place", presence.place_id.to_string()),
      ("portal", map_lab_optional_id(presence.portal_id)),
      ("slot", map_lab_optional_id(presence.interaction_slot_id)),
      ("phase", map_lab_presence_label(presence.phase)),
    ],
  }
}

///|
fn map_lab_place_exchange_entity(
  exchange : @energy_valley_contract.PlaceExchange,
) -> MapLabEntity {
  {
    id: exchange.id.to_string(),
    category: "place exchange",
    label: exchange.label,
    provenance: map_lab_provenance_copy(exchange.provenance),
    facts: [
      ("source", exchange.source_place_id.to_string()),
      ("target", exchange.target_place_id.to_string()),
      ("actor", map_lab_optional_id(exchange.actor_id)),
      ("kind", map_lab_exchange_label(exchange.kind)),
      ("intensity", exchange.intensity_per_mille.to_string()),
    ],
  }
}

///|
fn map_lab_rejected_placement_entity(
  rejection : @energy_valley_contract.RejectedPlacement,
) -> MapLabEntity {
  {
    id: rejection.id.to_string(),
    category: "rejected placement",
    label: map_lab_rejection_reason_label(rejection.reason),
    provenance: map_lab_provenance_copy(rejection.provenance),
    facts: [
      ("candidate", rejection.candidate_id.to_string()),
      ("parcel", map_lab_optional_id(rejection.parcel_id)),
      (
        "footprint",
        "\{rejection.grid_anchor.column},\{rejection.grid_anchor.row} · \{rejection.footprint.vertices.length()} vertices",
      ),
      ("reason", rejection.message),
    ],
  }
}

///|
fn map_lab_text_matches(value : String, needle : String) -> Bool {
  value.to_lower().contains(needle)
}

///|
fn map_lab_provenance_matches(
  provenance : @energy_valley_contract.Provenance,
  needle : String,
) -> Bool {
  map_lab_text_matches(map_lab_provenance_kind_label(provenance.kind), needle) ||
  map_lab_text_matches(provenance.source_id, needle) ||
  map_lab_text_matches(provenance.source_version, needle) ||
  map_lab_text_matches(
    map_lab_preservation_label(provenance.preservation),
    needle,
  ) ||
  map_lab_text_matches("\{provenance.confidence_per_mille / 10}%", needle)
}

///|
fn map_lab_candidate_matches(
  id : @energy_valley_contract.StableId,
  category : String,
  label : String,
  provenance : @energy_valley_contract.Provenance?,
  extra_terms : String,
  needle : String,
) -> Bool {
  if needle.is_empty() {
    return true
  }
  if map_lab_text_matches(id.to_string(), needle) ||
    map_lab_text_matches(category, needle) ||
    map_lab_text_matches(label, needle) ||
    map_lab_text_matches(extra_terms, needle) {
    return true
  }
  match provenance {
    Some(value) => map_lab_provenance_matches(value, needle)
    None => false
  }
}

///|
let map_lab_entity_result_limit : Int = frontend_setting_int(
  "map_lab_entity_result_limit", 40,
)

///|
fn map_lab_add_candidate_row(
  rows : Array[MapLabEntityRow],
  id : @energy_valley_contract.StableId,
  category : String,
  label : String,
  provenance : @energy_valley_contract.Provenance?,
  extra_terms : String,
  needle : String,
  selection_key? : String = "",
) -> Bool {
  if map_lab_candidate_matches(
      id, category, label, provenance, extra_terms, needle,
    ) {
    let stable_id = id.to_string()
    rows.push({
      selection_key: if selection_key.is_empty() {
        stable_id
      } else {
        selection_key
      },
      id: stable_id,
      category,
      label,
    })
  }
  rows.length() >= map_lab_entity_result_limit
}

///|
fn map_lab_entity_page_result(
  rows : Array[MapLabEntityRow],
  scanned : Int,
) -> MapLabEntityPage {
  { rows, scanned, detail_materializations: 0 }
}

///|
fn map_lab_visible_entities(
  snapshot : @energy_valley_contract.TownSnapshot,
  query : String,
) -> MapLabEntityPage {
  let world = snapshot.world
  let rows : Array[MapLabEntityRow] = []
  let needle = query.trim().to_owned().to_lower()
  let mut scanned = 1
  if map_lab_add_candidate_row(
      rows,
      world.blueprint_id,
      "blueprint",
      "CompiledTownWorld",
      None,
      "schema \{world.schema_version}",
      needle,
    ) {
    return map_lab_entity_page_result(rows, scanned)
  }
  for region in world.terrain_regions {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        region.id,
        "terrain",
        map_lab_terrain_label(region.kind),
        Some(region.provenance),
        "",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for block in world.land_blocks {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        block.id,
        "land block",
        map_lab_land_use_label(block.land_use),
        Some(block.provenance),
        map_lab_preservation_label(block.preservation),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for parcel in world.parcels {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        parcel.id,
        "parcel",
        map_lab_land_use_label(parcel.land_use),
        Some(parcel.provenance),
        "",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for program in world.parcel_programs {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        program.id,
        "parcel program",
        program.label,
        None,
        "compiled program",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for assignment in world.parcel_program_assignments {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        assignment.id,
        "program assignment",
        assignment.program_id.local_key(),
        Some(assignment.provenance),
        assignment.program_id.to_string(),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for node in world.road_network.nodes {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        node.id,
        "road node",
        "\{node.grid.column}, \{node.grid.row}",
        Some(node.provenance),
        "",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for segment in world.road_network.segments {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        segment.id,
        "road segment",
        map_lab_road_class_label(segment.road_class),
        Some(segment.provenance),
        "",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for place in world.places {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        place.id,
        "place",
        place.name,
        Some(place.provenance),
        map_lab_place_kind_label(place.kind),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
    for portal in place.entrances {
      scanned += 1
      if map_lab_add_candidate_row(
          rows,
          portal.id,
          "portal",
          "\{place.name} · \{if portal.primary { "primary" } else { "secondary" }}",
          Some(place.provenance),
          "",
          needle,
        ) {
        return map_lab_entity_page_result(rows, scanned)
      }
    }
    for slot in place.interaction_slots {
      scanned += 1
      if map_lab_add_candidate_row(
          rows,
          slot.id,
          "interaction slot",
          slot.label,
          Some(place.provenance),
          map_lab_interaction_label(slot.kind),
          needle,
        ) {
        return map_lab_entity_page_result(rows, scanned)
      }
    }
  }
  for relation in world.place_relations {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        relation.id,
        "place relation",
        relation.label,
        Some(relation.provenance),
        map_lab_place_relation_kind_label(relation.kind),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for target in world.attention_targets {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        target.id,
        "attention target",
        target.label,
        None,
        "semantic target",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for installation in world.installations {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        installation.id,
        "installation",
        installation.label,
        Some(installation.provenance),
        map_lab_installation_kind_label(installation.kind),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for diagnostic in world.diagnostics {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        diagnostic.id,
        "world diagnostic",
        diagnostic.message,
        Some(diagnostic.provenance),
        "\{map_lab_diagnostic_stage_label(diagnostic.stage)} \{map_lab_diagnostic_severity_label(diagnostic.severity)} \{map_lab_diagnostic_code_label(diagnostic.code)}",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for profile in snapshot.actor_profiles {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        profile.actor_id,
        "actor profile",
        profile.display_name,
        Some(profile.provenance),
        "\{profile.role_label} \{profile.avatar_family} \{map_lab_actor_source_label(profile.source_kind)} \{map_lab_actor_state_label(profile.state)}",
        needle,
        selection_key=map_lab_actor_profile_selection_key(profile.actor_id),
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for signal in snapshot.attention_signals {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        signal.id,
        "attention signal",
        map_lab_attention_signal_kind_label(signal.kind),
        None,
        "dynamic attention ledger \{signal.target_id.to_string()} \{map_lab_optional_id(signal.source_id)}",
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for focus in snapshot.attention_focuses {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        focus.actor_id,
        "attention focus",
        "tracking \{focus.target_id.local_key()}",
        None,
        "dynamic attention ledger \{focus.target_id.to_string()}",
        needle,
        selection_key=map_lab_attention_focus_selection_key(focus),
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for presence in snapshot.actor_presences {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        presence.actor_id,
        "actor presence",
        presence.intention,
        Some(presence.provenance),
        map_lab_presence_label(presence.phase),
        needle,
        selection_key=map_lab_actor_presence_selection_key(presence.actor_id),
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for exchange in snapshot.place_exchanges {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        exchange.id,
        "place exchange",
        exchange.label,
        Some(exchange.provenance),
        map_lab_exchange_label(exchange.kind),
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  for rejection in world.rejected_placements {
    scanned += 1
    if map_lab_add_candidate_row(
        rows,
        rejection.id,
        "rejected placement",
        map_lab_rejection_reason_label(rejection.reason),
        Some(rejection.provenance),
        rejection.message,
        needle,
      ) {
      return map_lab_entity_page_result(rows, scanned)
    }
  }
  map_lab_entity_page_result(rows, scanned)
}

///|
fn map_lab_selected_entity(
  snapshot : @energy_valley_contract.TownSnapshot,
  selected_id : String,
) -> MapLabEntity {
  let world = snapshot.world
  for profile in snapshot.actor_profiles {
    if map_lab_actor_profile_selection_key(profile.actor_id) == selected_id {
      return map_lab_actor_profile_entity(profile)
    }
  }
  for focus in snapshot.attention_focuses {
    if map_lab_attention_focus_selection_key(focus) == selected_id {
      return map_lab_attention_focus_entity(focus)
    }
  }
  for presence in snapshot.actor_presences {
    if map_lab_actor_presence_selection_key(presence.actor_id) == selected_id {
      return map_lab_actor_presence_entity(presence)
    }
  }
  if selected_id.is_empty() || world.blueprint_id.to_string() == selected_id {
    return map_lab_blueprint_entity(world)
  }
  for region in world.terrain_regions {
    if region.id.to_string() == selected_id {
      return map_lab_terrain_entity(region)
    }
  }
  for block in world.land_blocks {
    if block.id.to_string() == selected_id {
      return map_lab_land_block_entity(block)
    }
  }
  for parcel in world.parcels {
    if parcel.id.to_string() == selected_id {
      return map_lab_parcel_entity(world, parcel)
    }
  }
  for program in world.parcel_programs {
    if program.id.to_string() == selected_id {
      return map_lab_parcel_program_entity(program)
    }
  }
  for assignment in world.parcel_program_assignments {
    if assignment.id.to_string() == selected_id {
      return map_lab_program_assignment_entity(assignment)
    }
  }
  for node in world.road_network.nodes {
    if node.id.to_string() == selected_id {
      return map_lab_road_node_entity(world, node)
    }
  }
  for segment in world.road_network.segments {
    if segment.id.to_string() == selected_id {
      return map_lab_road_segment_entity(segment)
    }
  }
  for place in world.places {
    if place.id.to_string() == selected_id {
      return map_lab_place_entity(place)
    }
    for portal in place.entrances {
      if portal.id.to_string() == selected_id {
        return map_lab_portal_entity(place, portal)
      }
    }
    for slot in place.interaction_slots {
      if slot.id.to_string() == selected_id {
        return map_lab_interaction_slot_entity(place, slot)
      }
    }
  }
  for relation in world.place_relations {
    if relation.id.to_string() == selected_id {
      return map_lab_place_relation_entity(relation)
    }
  }
  for target in world.attention_targets {
    if target.id.to_string() == selected_id {
      return map_lab_attention_target_entity(target)
    }
  }
  for installation in world.installations {
    if installation.id.to_string() == selected_id {
      return map_lab_installation_entity(installation)
    }
  }
  for diagnostic in world.diagnostics {
    if diagnostic.id.to_string() == selected_id {
      return map_lab_world_diagnostic_entity(diagnostic)
    }
  }
  for signal in snapshot.attention_signals {
    if signal.id.to_string() == selected_id {
      return map_lab_attention_signal_entity(signal, snapshot.tick)
    }
  }
  for presence in snapshot.actor_presences {
    if presence.actor_id.to_string() == selected_id {
      return map_lab_actor_presence_entity(presence)
    }
  }
  for exchange in snapshot.place_exchanges {
    if exchange.id.to_string() == selected_id {
      return map_lab_place_exchange_entity(exchange)
    }
  }
  for rejection in world.rejected_placements {
    if rejection.id.to_string() == selected_id {
      return map_lab_rejected_placement_entity(rejection)
    }
  }
  map_lab_blueprint_entity(world)
}

///|
fn map_lab_validation_issues(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> Array[@energy_valley_contract.ContractIssue] {
  let issues = ecosystem_contract_world_validation_issues(snapshot.world).copy()
  // Dynamic ledgers are small and mutable at a tick boundary. Validate their
  // actual contents every time instead of using a length/tick cache that can
  // return stale results for two different ledgers.
  for issue in @energy_valley_contract.validate_snapshot_ledger(snapshot) {
    issues.push(issue)
  }
  issues
}

///|
fn map_lab_counts(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> MapLabCounts {
  let world = snapshot.world
  let mut portals = 0
  let mut slots = 0
  for place in world.places {
    portals += place.entrances.length()
    slots += place.interaction_slots.length()
  }
  let issues = map_lab_validation_issues(snapshot)
  let mut warnings = 0
  let mut errors = 0
  for issue in issues {
    match issue.severity {
      Warning => warnings += 1
      Error => errors += 1
    }
  }
  {
    terrain: world.terrain_regions.length(),
    blocks: world.land_blocks.length(),
    parcels: world.parcels.length(),
    programs: world.parcel_programs.length(),
    road_nodes: world.road_network.nodes.length(),
    road_segments: world.road_network.segments.length(),
    places: world.places.length(),
    relations: world.place_relations.length(),
    installations: world.installations.length(),
    portals,
    slots,
    actor_profiles: snapshot.actor_profiles.length(),
    attention_signals: snapshot.attention_signals.length(),
    attention_focuses: snapshot.attention_focuses.length(),
    presences: snapshot.active_presences().length(),
    exchanges: snapshot.active_exchanges().length(),
    diagnostics: world.diagnostics.length(),
    rejections: world.rejected_placements.length(),
    warnings,
    errors,
  }
}

///|
fn render_map_lab_layer_toggle(
  dispatch : Dispatch[Msg],
  view : MapLabViewState,
  layer : MapLabLayer,
) -> @rabbita.Html {
  let enabled = map_lab_layer_enabled(view.layers, layer)
  button(
    class="map-lab-layer map-lab-layer-\{map_lab_layer_slug(layer)}" +
      (if enabled { " is-active" } else { "" }),
    on_click=dispatch(ToggleMapLabLayer(layer)),
    attrs=@html.Attrs::build()
      .aria_label("地图实验室图层：\{map_lab_layer_label(layer)}")
      .aria_pressed(if enabled { "true" } else { "false" }),
    [
      span(class="map-lab-layer-mark", no_children()),
      span(map_lab_layer_label(layer)),
    ],
  )
}

///|
fn render_map_lab_counts(counts : MapLabCounts) -> @rabbita.Html {
  div(class="map-lab-counts", [
    span([
      span(class="map-lab-count-value", counts.terrain.to_string()),
      span(" 地形"),
    ]),
    span([
      span(class="map-lab-count-value", counts.blocks.to_string()),
      span(" 地块"),
    ]),
    span([
      span(class="map-lab-count-value", counts.parcels.to_string()),
      span(" 地籍"),
    ]),
    span([
      span(class="map-lab-count-value", counts.programs.to_string()),
      span(" 程序"),
    ]),
    span([
      span(
        class="map-lab-count-value",
        "\{counts.road_nodes}/\{counts.road_segments}",
      ),
      span(" 节点/道路"),
    ]),
    span([
      span(class="map-lab-count-value", counts.places.to_string()),
      span(" 场所"),
    ]),
    span([
      span(class="map-lab-count-value", counts.relations.to_string()),
      span(" 关系"),
    ]),
    span([
      span(class="map-lab-count-value", counts.installations.to_string()),
      span(" 公共装置"),
    ]),
    span([
      span(class="map-lab-count-value", counts.portals.to_string()),
      span(" 入口"),
    ]),
    span([
      span(class="map-lab-count-value", counts.slots.to_string()),
      span(" 交互位"),
    ]),
    span([
      span(class="map-lab-count-value", counts.actor_profiles.to_string()),
      span(" 角色档案"),
    ]),
    span([
      span(class="map-lab-count-value", counts.attention_signals.to_string()),
      span(" 注意信号"),
    ]),
    span([
      span(class="map-lab-count-value", counts.attention_focuses.to_string()),
      span(" 注意焦点"),
    ]),
    span([
      span(class="map-lab-count-value", counts.presences.to_string()),
      span(" 在场"),
    ]),
    span([
      span(class="map-lab-count-value", counts.exchanges.to_string()),
      span(" 交换"),
    ]),
    span([
      span(class="map-lab-count-value", counts.diagnostics.to_string()),
      span(" 编译诊断"),
    ]),
    span([
      span(class="map-lab-count-value", "\{counts.warnings}/\{counts.errors}"),
      span(" 警告/错误"),
    ]),
    span([
      span(class="map-lab-count-value", counts.rejections.to_string()),
      span(" 拒绝放置"),
    ]),
  ])
}

///|
fn render_map_lab_selected(entity : MapLabEntity) -> @rabbita.Html {
  let facts : Array[@rabbita.Html] = []
  for fact in entity.facts {
    let (key, value) = fact
    facts.push(
      div(class="map-lab-fact", [
        span(class="map-lab-fact-key", key),
        span(class="map-lab-fact-value", value),
      ]),
    )
  }
  section(class="map-lab-selection", [
    div(class="map-lab-selection-head", [
      span(class="map-lab-entity-kind", entity.category),
      span(class="map-lab-provenance", entity.provenance),
    ]),
    span(class="map-lab-stable-id", entity.id),
    h3(entity.label),
    div(class="map-lab-facts", facts),
  ])
}

///|
fn render_map_lab_entity_browser(
  dispatch : Dispatch[Msg],
  view : MapLabViewState,
  page : MapLabEntityPage,
) -> @rabbita.Html {
  let rows : Array[@rabbita.Html] = []
  for entity in page.rows {
    rows.push(
      button(
        class="map-lab-entity-row" +
          (if entity.selection_key == view.selected_id {
            " is-selected"
          } else {
            ""
          }),
        on_click=dispatch(SelectMapLabEntity(entity.selection_key)),
        attrs=@html.Attrs::build()
          .aria_label("检查 \{entity.category} \{entity.id}")
          .aria_pressed(
            if entity.selection_key == view.selected_id {
              "true"
            } else {
              "false"
            },
          ),
        [
          span(class="map-lab-entity-row-kind", entity.category),
          span(class="map-lab-entity-id", entity.id),
          span(class="map-lab-entity-row-label", entity.label),
        ],
      ),
    )
  }
  let list_content : Array[@rabbita.Html] = if rows.is_empty() {
    [p(class="map-lab-empty", "没有匹配的语义实体")]
  } else {
    rows
  }
  div(class="map-lab-browser", [
    div(class="map-lab-search", [
      span("查找 StableId"),
      input(
        id="map-lab-search",
        class="map-lab-search-input",
        value=view.query,
        placeholder="place/… road-segment/…",
        on_input=value => dispatch(SetMapLabQuery(value)),
        attrs=@html.Attrs::build().aria_label("查找地图实体 StableId"),
      ),
    ]),
    div(
      class="map-lab-entity-list",
      attrs=@html.Attrs::build().role("list"),
      list_content,
    ),
  ])
}

///|
fn render_map_lab_validation(
  snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let issues = map_lab_validation_issues(snapshot)
  let rejections = snapshot.world.rejected_placements
  if issues.is_empty() && rejections.is_empty() {
    div(class="map-lab-validation is-valid", [
      span(class="map-lab-validation-mark", "OK"),
      span("世界与动态账本通过契约校验"),
    ])
  } else {
    let rows : Array[@rabbita.Html] = []
    for issue in issues {
      if rows.length() < 12 {
        let tone = match issue.severity {
          Warning => "WARN"
          Error => "ERROR"
        }
        rows.push(
          div(class="map-lab-issue", [
            span(class="map-lab-issue-tone", "\{tone} · \{Repr(issue.code)}"),
            span(class="map-lab-issue-id", map_lab_optional_id(issue.entity_id)),
            span(issue.message),
          ]),
        )
      }
    }
    for rejection in rejections {
      if rows.length() < 12 {
        rows.push(
          div(class="map-lab-issue is-rejection", [
            span(
              class="map-lab-issue-tone",
              "REJECT · \{map_lab_rejection_reason_label(rejection.reason)}",
            ),
            span(class="map-lab-issue-id", rejection.id.to_string()),
            span(rejection.message),
          ]),
        )
      }
    }
    div(class="map-lab-validation is-invalid", [
      span(
        class="map-lab-validation-mark",
        (issues.length() + rejections.length()).to_string(),
      ),
      div(class="map-lab-issue-list", rows),
    ])
  }
}

///|
fn render_map_lab_panel(
  dispatch : Dispatch[Msg],
  view : MapLabViewState,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  let selected = map_lab_selected_entity(snapshot, view.selected_id)
  let page = map_lab_visible_entities(snapshot, view.query)
  let selected_key = if view.selected_id.is_empty() {
    snapshot.world.blueprint_id.to_string()
  } else {
    view.selected_id
  }
  let toggles : Array[@rabbita.Html] = []
  for layer in map_lab_all_layers() {
    toggles.push(render_map_lab_layer_toggle(dispatch, view, layer))
  }
  aside(
    id="map-lab-panel",
    class="map-lab-panel pointer-events-auto",
    attrs=@html.Attrs::build()
      .role("dialog")
      .aria_modal("false")
      .aria_labelledby("map-lab-title"),
    [
      header(class="map-lab-head", [
        div([
          p(class="map-lab-eyebrow", "ADVANCED · READ ONLY"),
          h2(id="map-lab-title", "Map Lab"),
        ]),
        button(
          class="map-lab-close",
          on_click=dispatch(CloseMapLab),
          attrs=@html.Attrs::build().aria_label("关闭地图实验室"),
          "关闭",
        ),
      ]),
      p(
        class="map-lab-intro",
        "同一份 CompiledTownWorld / TownSnapshot 的证据、编译与运行透视。这里的操作只改变诊断图层。",
      ),
      render_map_lab_counts(map_lab_counts(snapshot)),
      div(
        class="map-lab-layers",
        attrs=@html.Attrs::build().aria_label("地图实验室图层"),
        toggles,
      ),
      render_map_lab_validation(snapshot),
      render_map_lab_selected(selected),
      render_map_lab_entity_browser(
        dispatch,
        { ..view, selected_id: selected_key },
        page,
      ),
      div(class="map-lab-foot", [
        span("Shift+M 开关 · Esc 关闭"),
        span(class="map-lab-foot-digest", snapshot.world.blueprint_digest),
      ]),
    ],
  )
}

///|
fn render_map_lab(
  dispatch : Dispatch[Msg],
  view : MapLabViewState,
  snapshot : @energy_valley_contract.TownSnapshot,
) -> @rabbita.Html {
  install_map_lab_shortcuts()
  div(class="map-lab-shell", [
    button(
      class="map-lab-launcher pointer-events-auto" +
        (if view.open { " is-open" } else { "" }),
      title="高级地图诊断 · Shift+M",
      on_click=dispatch(ToggleMapLab),
      attrs=@html.Attrs::build()
        .aria_label(
          if view.open {
            "关闭地图实验室"
          } else {
            "打开地图实验室，快捷键 Shift+M"
          },
        )
        .aria_controls("map-lab-panel")
        .aria_expanded(if view.open { "true" } else { "false" }),
      [span(class="map-lab-launcher-mark", "ML"), span("地图诊断")],
    ),
    if view.open {
      render_map_lab_panel(dispatch, view, snapshot)
    } else {
      @html.nothing
    },
  ])
}

///|
/// Keyboard handling clicks the same accessible controls as pointer input, so
/// all state transitions remain inside the Rabbita update loop.
extern "js" fn install_map_lab_shortcuts() -> Unit =
  #| () => {
  #|   if (typeof globalThis.addEventListener !== "function") return;
  #|   if (globalThis.__moontownMapLabShortcuts) return;
  #|   globalThis.__moontownMapLabShortcuts = true;
  #|   globalThis.addEventListener("keydown", event => {
  #|     const target = event.target;
  #|     if (target?.matches?.("input, textarea, select") ||
  #|         target?.isContentEditable) return;
  #|     if (event.shiftKey && event.key?.toLowerCase?.() === "m") {
  #|       const button = globalThis.document?.querySelector(
  #|         'button[aria-controls="map-lab-panel"]',
  #|       );
  #|       if (button) {
  #|         event.preventDefault();
  #|         button.click();
  #|       }
  #|     } else if (event.key === "Escape") {
  #|       globalThis.document?.querySelector(
  #|         'button[aria-label="关闭地图实验室"]',
  #|       )?.click();
  #|     }
  #|   });
  #| }
