///|
/// Spatial entity families persisted in the TownLife V3 event log.
priv enum TownLifeWorldKind {
  WorldBuilding
  WorldRoadCell
  WorldPark
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Typed payload carried by an add or move event. Road authority is one
/// event-addressable cell, never a whole connected component.
priv enum TownLifeWorldPayload {
  WorldBuildingPayload(GoldenValleyBuilding)
  WorldRoadCellPayload(SavedWorldDeltaGridPoint)
  WorldParkPayload(SavedWorldDeltaPark)
} derive(ToJson, FromJson)

///|
priv enum TownLifeWorldAction {
  WorldAdd(TownLifeWorldPayload)
  WorldMove(TownLifeWorldPayload)
  WorldDelete
} derive(ToJson, FromJson)

///|
/// Reset is a causal epoch/watermark. Events from older epochs can be dropped
/// permanently because a stale shard cannot win against this maximum epoch.
priv struct TownLifeWorldEpoch {
  id : String
  dot : TownLifeDot
  stamp : TownLifeCausalStamp
  base_budget : Int
  base_next_authored_sequence : Int
} derive(ToJson, FromJson)

///|
priv struct TownLifeWorldEvent {
  id : String
  dot : TownLifeDot
  stamp : TownLifeCausalStamp
  epoch_id : String
  kind : TownLifeWorldKind
  entity_id : String
  incarnation_id : String
  action : TownLifeWorldAction
  budget_delta : Int
} derive(ToJson, FromJson)

///|
/// One independently mergeable world history for an exact blueprint build.
/// A digest mismatch is a different state and is never rebound implicitly.
priv struct TownLifeWorldState {
  blueprint_id : String
  blueprint_digest : String
  epoch : TownLifeWorldEpoch
  events : Array[TownLifeWorldEvent]
} derive(ToJson, FromJson)

///|
priv struct TownLifeWorldRejectedEvent {
  event_id : String
  entity_id : String
  reason_code : String
  reason : String
} derive(Debug, Eq)

///|
priv struct TownLifeWorldResolvedIncarnation {
  kind : TownLifeWorldKind
  entity_id : String
  incarnation_id : String
  add : TownLifeWorldEvent
  movement : TownLifeWorldEvent?
  deletion : TownLifeWorldEvent?
}

///|
priv struct TownLifeWorldTransition {
  incarnation : TownLifeWorldResolvedIncarnation
  event : TownLifeWorldEvent
}

///|
priv struct TownLifeWorldProjection {
  ledger : EnergyValleyWorldDeltaLedger
  rejected : Array[TownLifeWorldRejectedEvent]
  active : Array[TownLifeWorldResolvedIncarnation]
  validation_passes : Int
}

///|
fn town_life_world_blueprint_id() -> String {
  "blueprint/wenyu-energy-valley"
}

///|
fn town_life_world_state_key(
  blueprint_id : String,
  blueprint_digest : String,
) -> String {
  "\{blueprint_id}\u{1f}\{blueprint_digest}"
}

///|
fn town_life_world_kind_key(kind : TownLifeWorldKind) -> String {
  match kind {
    WorldBuilding => "building"
    WorldRoadCell => "road-cell"
    WorldPark => "park"
  }
}

///|
fn town_life_world_event_identity(event : TownLifeWorldEvent) -> String {
  "\{event.dot.writer_id}:\{event.dot.sequence}"
}

///|
fn town_life_world_event_compare(
  left : TownLifeWorldEvent,
  right : TownLifeWorldEvent,
) -> Int {
  town_life_event_order(
    left.stamp,
    left.dot,
    left.id,
    right.stamp,
    right.dot,
    right.id,
  )
}

///|
fn town_life_world_epoch_compare(
  left : TownLifeWorldEpoch,
  right : TownLifeWorldEpoch,
) -> Int {
  let by_stamp = town_life_stamp_compare(left.stamp, right.stamp)
  if by_stamp != 0 {
    by_stamp
  } else {
    let by_dot = town_life_dot_compare(left.dot, right.dot)
    if by_dot != 0 {
      by_dot
    } else {
      left.id.compare(right.id)
    }
  }
}

///|
fn town_life_world_event_payload_key(event : TownLifeWorldEvent) -> String {
  ToJson::to_json(event).stringify()
}

///|
fn town_life_world_prefer_event(
  left : TownLifeWorldEvent,
  right : TownLifeWorldEvent,
) -> TownLifeWorldEvent {
  if town_life_world_event_payload_key(left).compare(
      town_life_world_event_payload_key(right),
    ) >=
    0 {
    left
  } else {
    right
  }
}

///|
fn town_life_world_normalize_state(
  state : TownLifeWorldState,
) -> TownLifeWorldState {
  let by_dot : Map[String, TownLifeWorldEvent] = Map([])
  for event in state.events {
    if event.epoch_id != state.epoch.id ||
      event.entity_id.is_empty() ||
      event.incarnation_id.is_empty() {
      continue
    }
    let key = town_life_world_event_identity(event)
    match by_dot.get(key) {
      None => by_dot[key] = event
      Some(current) =>
        by_dot[key] = town_life_world_prefer_event(current, event)
    }
  }
  let events = by_dot.values().to_array()
  events.sort_by(town_life_world_event_compare)
  { ..state, events, }
}

///|
fn town_life_world_merge_state(
  left_raw : TownLifeWorldState,
  right_raw : TownLifeWorldState,
) -> TownLifeWorldState {
  let left = town_life_world_normalize_state(left_raw)
  let right = town_life_world_normalize_state(right_raw)
  let epoch_order = town_life_world_epoch_compare(left.epoch, right.epoch)
  if epoch_order > 0 {
    left
  } else if epoch_order < 0 {
    right
  } else {
    let epoch = if ToJson::to_json(left.epoch)
      .stringify()
      .compare(ToJson::to_json(right.epoch).stringify()) >=
      0 {
      left.epoch
    } else {
      right.epoch
    }
    town_life_world_normalize_state({
      ..left,
      epoch,
      events: left.events + right.events,
    })
  }
}

///|
fn town_life_world_merge_states(
  left : ArrayView[TownLifeWorldState],
  right : ArrayView[TownLifeWorldState],
) -> Array[TownLifeWorldState] {
  let joined : Map[String, TownLifeWorldState] = Map([])
  for raw in left.to_array() + right.to_array() {
    let state = town_life_world_normalize_state(raw)
    if state.blueprint_id.is_empty() || state.blueprint_digest.is_empty() {
      continue
    }
    let key = town_life_world_state_key(
      state.blueprint_id,
      state.blueprint_digest,
    )
    match joined.get(key) {
      None => joined[key] = state
      Some(current) => joined[key] = town_life_world_merge_state(current, state)
    }
  }
  let result = joined.values().to_array()
  result.sort_by((a, b) => {
    town_life_world_state_key(a.blueprint_id, a.blueprint_digest).compare(
      town_life_world_state_key(b.blueprint_id, b.blueprint_digest),
    )
  })
  result
}

///|
fn town_life_world_genesis_epoch(
  blueprint_digest : String,
) -> TownLifeWorldEpoch {
  let writer = "world-genesis-\{ecosystem_stable_hash(blueprint_digest)}"
  {
    id: "\{writer}:epoch",
    dot: { writer_id: writer, sequence: 1 },
    stamp: { writer_id: writer, lamport: 1 },
    base_budget: 2400,
    base_next_authored_sequence: 1,
  }
}

///|
fn town_life_world_empty_state_for_seed(seed : Int) -> TownLifeWorldState {
  let digest = energy_valley_base_blueprint_digest_for_seed(seed)
  {
    blueprint_id: town_life_world_blueprint_id(),
    blueprint_digest: digest,
    epoch: town_life_world_genesis_epoch(digest),
    events: [],
  }
}

///|
fn town_life_world_has_state_for_seed(
  states : ArrayView[TownLifeWorldState],
  seed : Int,
) -> Bool {
  let blueprint_id = town_life_world_blueprint_id()
  let digest = energy_valley_base_blueprint_digest_for_seed(seed)
  states.any(state => {
    state.blueprint_id == blueprint_id && state.blueprint_digest == digest
  })
}

///|
fn town_life_world_import_legacy_ledger(
  ledger : EnergyValleyWorldDeltaLedger,
  seed : Int,
) -> TownLifeWorldState {
  let digest = energy_valley_base_blueprint_digest_for_seed(seed)
  let writer = "0-world-import-\{ecosystem_stable_hash(digest)}"
  let epoch : TownLifeWorldEpoch = {
    id: "\{writer}:epoch",
    dot: { writer_id: writer, sequence: 1 },
    // Strictly below the genesis epoch: if a real V3 edit races the one-time
    // import, the real authority wins and import events are discarded.
    stamp: { writer_id: writer, lamport: 0 },
    base_budget: ledger.budget.max(0),
    base_next_authored_sequence: ledger.next_authored_building_sequence.max(1),
  }
  let projected = energy_valley_world_delta_projection(ledger)
  let events : Array[TownLifeWorldEvent] = []
  let mut sequence = 2
  let append = fn(
    kind : TownLifeWorldKind,
    entity_id : String,
    payload : TownLifeWorldPayload,
  ) {
    let id = "\{writer}:\{sequence}:world-import"
    events.push({
      id,
      dot: { writer_id: writer, sequence },
      stamp: { writer_id: writer, lamport: sequence },
      epoch_id: epoch.id,
      kind,
      entity_id,
      incarnation_id: id,
      action: WorldAdd(payload),
      // The imported ledger's current balance becomes the epoch baseline;
      // geometry imports are therefore economically neutral.
      budget_delta: 0,
    })
    sequence += 1
  }
  for building in projected.buildings {
    let entity_id = golden_valley_nonempty_authored_id(building).unwrap_or(
      "legacy-building-\{building.x}-\{building.y}-\{ecosystem_stable_hash(building.name)}",
    )
    append(
      WorldBuilding,
      entity_id,
      WorldBuildingPayload({ ..building, authored_id: Some(entity_id) }),
    )
  }
  for encoded in projected.roads {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) =>
        append(
          WorldRoadCell,
          "road-cell-\{x}-\{y}",
          WorldRoadCellPayload({ x, y }),
        )
      None => ()
    }
  }
  for encoded in projected.parks {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) => {
        let entity_id = energy_valley_saved_park_id(x, y)
        append(WorldPark, entity_id, WorldParkPayload({ id: entity_id, x, y }))
      }
      None => ()
    }
  }
  town_life_world_normalize_state({
    blueprint_id: ledger.base_blueprint_id,
    blueprint_digest: digest,
    epoch,
    events,
  })
}

///|
fn town_life_world_migrate_initial_save(
  raw : TownLifeSave,
  seed : Int,
) -> TownLifeSave {
  let save = town_life_normalize_save(raw)
  // The fallback grammar has a different blueprint digest. Consuming the
  // global legacy source against it would make the later authoritative Wenyu
  // load permanently unable to import the user's map.
  if !browser_energy_valley_authoritative_reference_ready() {
    return save
  }
  let digest = energy_valley_base_blueprint_digest_for_seed(seed)
  // Durable V3 authority always wins a first-open race. Fence only after the
  // target state is observed through the same V3 enumeration used at reload.
  match town_life_aggregate_v3_saves(browser_town_life_v3_save_texts()) {
    Some(committed) if town_life_world_has_state_for_seed(
        committed.world_states.unwrap_or([]),
        seed,
      ) => {
      browser_fence_energy_world_town_life_migration(digest)
      return town_life_reconcile_save(save, committed)
    }
    _ => ()
  }
  if town_life_world_has_state_for_seed(save.world_states.unwrap_or([]), seed) {
    // A caller may supply an in-memory/uncommitted state. Keep it, but do not
    // destroy the only legacy source until that state is visible in V3.
    return save
  }
  if browser_energy_world_town_life_migration_fenced(digest) {
    return save
  }
  let imported = match legacy_energy_valley_world_delta_for_migration(seed) {
    Some(ledger) => town_life_world_import_legacy_ledger(ledger, seed)
    None => town_life_world_empty_state_for_seed(seed)
  }
  let migrated = town_life_normalize_save({
    ..save,
    world_states: Some(
      town_life_world_merge_states(save.world_states.unwrap_or([]), [imported]),
    ),
  })
  let installed = browser_install_energy_world_town_life_checkpoint(
    digest,
    ToJson::to_json(migrated).stringify(),
  )
  // A successful exact-key readback is necessary but not sufficient: verify
  // the checkpoint through the V3 transport/decoder too. When installation
  // loses a race, an independently committed winner may still be observed and
  // safely becomes authority. Otherwise retain the unfenced pre-import save.
  let observed = town_life_aggregate_v3_saves(browser_town_life_v3_save_texts())
  match (installed, observed) {
    (true, Some(committed)) | (false, Some(committed)) if town_life_world_has_state_for_seed(
        committed.world_states.unwrap_or([]),
        seed,
      ) => {
      browser_fence_energy_world_town_life_migration(digest)
      town_life_reconcile_save(save, committed)
    }
    _ => save
  }
}

///|
fn town_life_world_state_for_seed(
  states : ArrayView[TownLifeWorldState],
  seed : Int,
) -> TownLifeWorldState {
  let blueprint_id = town_life_world_blueprint_id()
  let digest = energy_valley_base_blueprint_digest_for_seed(seed)
  for state in states {
    if state.blueprint_id == blueprint_id && state.blueprint_digest == digest {
      return town_life_world_normalize_state(state)
    }
  }
  town_life_world_empty_state_for_seed(seed)
}

///|
fn town_life_world_replace_state(
  states : ArrayView[TownLifeWorldState],
  replacement : TownLifeWorldState,
) -> Array[TownLifeWorldState] {
  let result : Array[TownLifeWorldState] = []
  let key = town_life_world_state_key(
    replacement.blueprint_id,
    replacement.blueprint_digest,
  )
  for state in states {
    if town_life_world_state_key(state.blueprint_id, state.blueprint_digest) !=
      key {
      result.push(state)
    }
  }
  result.push(town_life_world_normalize_state(replacement))
  town_life_world_merge_states(result, [])
}

///|
fn town_life_world_action_payload(
  action : TownLifeWorldAction,
) -> TownLifeWorldPayload? {
  match action {
    WorldAdd(payload) | WorldMove(payload) => Some(payload)
    WorldDelete => None
  }
}

///|
fn town_life_world_payload_matches_kind(
  kind : TownLifeWorldKind,
  payload : TownLifeWorldPayload,
) -> Bool {
  match (kind, payload) {
    (WorldBuilding, WorldBuildingPayload(_))
    | (WorldRoadCell, WorldRoadCellPayload(_))
    | (WorldPark, WorldParkPayload(_)) => true
    _ => false
  }
}

///|
fn town_life_world_event_payload_valid(event : TownLifeWorldEvent) -> Bool {
  if event.action is WorldAdd(_) &&
    (
      event.id != event.incarnation_id ||
      !event.id.starts_with("\{event.dot.writer_id}:\{event.dot.sequence}:")
    ) {
    return false
  }
  match town_life_world_action_payload(event.action) {
    None => true
    Some(payload) =>
      if !town_life_world_payload_matches_kind(event.kind, payload) {
        false
      } else {
        match (event.kind, payload) {
          (WorldRoadCell, WorldRoadCellPayload(point)) =>
            event.entity_id == "road-cell-\{point.x}-\{point.y}"
          _ => true
        }
      }
  }
}

///|
fn town_life_world_resolve_incarnations(
  state : TownLifeWorldState,
) -> Array[TownLifeWorldResolvedIncarnation] {
  let resolved : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let events = town_life_world_normalize_state(state).events
  // Pass one discovers incarnations. A corrupt or adversarial shard may sort a
  // Move/Delete before Add; the second pass still resolves it deterministically.
  for event in events {
    let key = "\{town_life_world_kind_key(event.kind)}\u{1f}\{event.entity_id}\u{1f}\{event.incarnation_id}"
    match event.action {
      WorldAdd(_) if town_life_world_event_payload_valid(event) =>
        match resolved.get(key) {
          None =>
            resolved[key] = {
              kind: event.kind,
              entity_id: event.entity_id,
              incarnation_id: event.incarnation_id,
              add: event,
              movement: None,
              deletion: None,
            }
          Some(current) =>
            if town_life_world_event_compare(event, current.add) > 0 {
              resolved[key] = { ..current, add: event }
            }
        }
      WorldAdd(_) | WorldMove(_) | WorldDelete => ()
    }
  }
  for event in events {
    let key = "\{town_life_world_kind_key(event.kind)}\u{1f}\{event.entity_id}\u{1f}\{event.incarnation_id}"
    match (event.action, resolved.get(key)) {
      (WorldMove(_), Some(current)) if town_life_world_event_payload_valid(
          event,
        ) &&
        town_life_world_event_compare(event, current.add) > 0 =>
        match current.movement {
          None => resolved[key] = { ..current, movement: Some(event) }
          Some(previous) =>
            if town_life_world_event_compare(event, previous) > 0 {
              resolved[key] = { ..current, movement: Some(event) }
            }
        }
      (WorldDelete, Some(current)) if town_life_world_event_compare(
          event,
          current.add,
        ) >
        0 =>
        match current.deletion {
          None => resolved[key] = { ..current, deletion: Some(event) }
          Some(previous) =>
            if town_life_world_event_compare(event, previous) < 0 {
              resolved[key] = { ..current, deletion: Some(event) }
            }
        }
      _ => ()
    }
  }
  let result = resolved.values().to_array()
  result.sort_by((left, right) => {
    town_life_world_event_compare(left.add, right.add)
  })
  result
}

///|
fn town_life_world_orphan_rejections(
  state : TownLifeWorldState,
) -> Array[TownLifeWorldRejectedEvent] {
  let adds : Map[String, TownLifeWorldEvent] = Map([])
  let normalized = town_life_world_normalize_state(state)
  for event in normalized.events {
    if event.action is WorldAdd(_) {
      let key = "\{town_life_world_kind_key(event.kind)}\u{1f}\{event.entity_id}\u{1f}\{event.incarnation_id}"
      match adds.get(key) {
        None => adds[key] = event
        Some(current) =>
          if town_life_world_event_compare(event, current) > 0 {
            adds[key] = event
          }
      }
    }
  }
  let rejected : Array[TownLifeWorldRejectedEvent] = []
  for event in normalized.events {
    let key = "\{town_life_world_kind_key(event.kind)}\u{1f}\{event.entity_id}\u{1f}\{event.incarnation_id}"
    if !town_life_world_event_payload_valid(event) {
      rejected.push({
        event_id: event.id,
        entity_id: event.entity_id,
        reason_code: "invalid-payload",
        reason: "Payload kind or road-cell coordinate does not match its entity identity.",
      })
    } else if !(event.action is WorldAdd(_)) && !adds.contains(key) {
      rejected.push({
        event_id: event.id,
        entity_id: event.entity_id,
        reason_code: "missing-add",
        reason: "Move/Delete has no matching Add incarnation and has no effect.",
      })
    } else if !(event.action is WorldAdd(_)) &&
      town_life_world_event_compare(event, adds[key]) <= 0 {
      rejected.push({
        event_id: event.id,
        entity_id: event.entity_id,
        reason_code: "pre-add-transition",
        reason: "Move/Delete does not follow its Add and has no effect.",
      })
    }
  }
  rejected.sort_by((a, b) => a.event_id.compare(b.event_id))
  rejected
}

///|
fn town_life_world_logical_histories(
  state : TownLifeWorldState,
) -> (
  Array[TownLifeWorldResolvedIncarnation],
  Array[TownLifeWorldRejectedEvent],
) {
  let groups : Map[String, Array[TownLifeWorldResolvedIncarnation]] = Map([])
  for incarnation in town_life_world_resolve_incarnations(state) {
    let key = "\{town_life_world_kind_key(incarnation.kind)}\u{1f}\{incarnation.entity_id}"
    match groups.get(key) {
      Some(values) => values.push(incarnation)
      None => groups[key] = [incarnation]
    }
  }
  let accepted : Array[TownLifeWorldResolvedIncarnation] = []
  let rejected : Array[TownLifeWorldRejectedEvent] = []
  for _, values in groups {
    values.sort_by((a, b) => town_life_world_event_compare(a.add, b.add))
    let history : Array[TownLifeWorldResolvedIncarnation] = []
    for candidate in values {
      if history.is_empty() {
        history.push(candidate)
        continue
      }
      let last_index = history.length() - 1
      let current = history[last_index]
      match current.deletion {
        Some(deletion) =>
          if town_life_world_event_compare(candidate.add, deletion) > 0 {
            history.push(candidate)
          } else {
            rejected.push({
              event_id: candidate.add.id,
              entity_id: candidate.entity_id,
              reason_code: "stale-incarnation",
              reason: "The add did not causally follow deletion of the previous incarnation.",
            })
          }
        None => {
          // Concurrent incarnations represent one logical object. The newest
          // add wins deterministically and is charged exactly once.
          rejected.push({
            event_id: current.add.id,
            entity_id: current.entity_id,
            reason_code: "superseded-incarnation",
            reason: "A newer concurrent incarnation won the logical entity.",
          })
          history[last_index] = candidate
        }
      }
    }
    for incarnation in history {
      accepted.push(incarnation)
    }
  }
  accepted.sort_by((a, b) => town_life_world_event_compare(a.add, b.add))
  rejected.sort_by((a, b) => a.event_id.compare(b.event_id))
  (accepted, rejected)
}

///|
fn town_life_world_effective_payload(
  incarnation : TownLifeWorldResolvedIncarnation,
) -> TownLifeWorldPayload {
  match incarnation.movement {
    Some(event) => town_life_world_action_payload(event.action).unwrap()
    None => town_life_world_action_payload(incarnation.add.action).unwrap()
  }
}

///|
fn town_life_world_effective_event(
  incarnation : TownLifeWorldResolvedIncarnation,
) -> TownLifeWorldEvent {
  incarnation.movement.unwrap_or(incarnation.add)
}

///|
fn town_life_world_active_incarnations(
  histories : ArrayView[TownLifeWorldResolvedIncarnation],
) -> Array[TownLifeWorldResolvedIncarnation] {
  let result : Array[TownLifeWorldResolvedIncarnation] = []
  for incarnation in histories {
    if incarnation.deletion is None {
      result.push(incarnation)
    }
  }
  result
}

///|
fn town_life_world_operations_for_active(
  active : ArrayView[TownLifeWorldResolvedIncarnation],
) -> Array[SavedWorldDeltaOperation] {
  let operations : Array[SavedWorldDeltaOperation] = []
  let road_cells : Array[String] = []
  for incarnation in active {
    match (incarnation.kind, town_life_world_effective_payload(incarnation)) {
      (WorldBuilding, WorldBuildingPayload(raw)) => {
        let building = { ..raw, authored_id: Some(incarnation.entity_id) }
        operations.push(AddBuilding({ id: incarnation.entity_id, building }))
      }
      (WorldRoadCell, WorldRoadCellPayload(point)) => {
        let key = golden_valley_tile_key(point.x, point.y)
        if !road_cells.contains(key) {
          road_cells.push(key)
        }
      }
      (WorldPark, WorldParkPayload(park)) =>
        operations.push(AddPark({ ..park, id: incarnation.entity_id }))
      _ => ()
    }
  }
  for road in energy_valley_saved_road_components(road_cells) {
    operations.push(AddRoad(road))
  }
  // Operation order is canonical and independent of shard/merge order.
  operations.sort_by((left, right) => {
    ToJson::to_json(left)
    .stringify()
    .compare(ToJson::to_json(right).stringify())
  })
  operations
}

///|
fn town_life_world_revision(state : TownLifeWorldState) -> Int {
  let mut revision = state.epoch.stamp.lamport.max(1)
  for event in state.events {
    revision = revision.max(event.stamp.lamport)
  }
  revision
}

///|
fn town_life_world_ledger(
  state : TownLifeWorldState,
  active : ArrayView[TownLifeWorldResolvedIncarnation],
  budget : Int,
) -> EnergyValleyWorldDeltaLedger {
  let operations = town_life_world_operations_for_active(active)
  let mut next_sequence = state.epoch.base_next_authored_sequence.max(1)
  for event in state.events {
    if event.kind == WorldBuilding &&
      event.action is WorldAdd(_) &&
      !event.dot.writer_id.starts_with("0-world-import-") {
      next_sequence += 1
    }
  }
  {
    schema_version: energy_valley_world_delta_schema(),
    base_blueprint_id: state.blueprint_id,
    base_blueprint_digest: state.blueprint_digest,
    revision: town_life_world_revision(state),
    budget: budget.max(0),
    operations,
    content_digest: Some(energy_valley_saved_operations_digest(operations)),
    next_authored_building_sequence: next_sequence,
  }
}

///|
fn town_life_world_incarnation_key(
  incarnation : TownLifeWorldResolvedIncarnation,
) -> String {
  "\{town_life_world_kind_key(incarnation.kind)}\u{1f}\{incarnation.entity_id}\u{1f}\{incarnation.incarnation_id}"
}

///|
/// Anchor-reachable base-road cells are immutable for a blueprint digest. The
/// contract graph's public reachability API deliberately favors clarity over
/// bulk queries, so projection prepares this index once rather than running a
/// graph traversal for every custom cell and every merge.
let town_life_world_base_road_cells_cache : Map[String, Map[String, Bool]] = Map([],
)

///|
fn town_life_world_base_road_cells(
  world : @energy_valley_contract.CompiledTownWorld,
) -> Map[String, Bool] {
  match town_life_world_base_road_cells_cache.get(world.blueprint_digest) {
    Some(cells) => return cells
    None => ()
  }
  let adjacency : Map[
    @energy_valley_contract.StableId,
    Array[@energy_valley_contract.StableId],
  ] = Map([])
  let nodes : Map[
    @energy_valley_contract.StableId,
    @energy_valley_contract.RoadNode,
  ] = Map([])
  for node in world.road_network.nodes {
    adjacency[node.id] = []
    nodes[node.id] = node
  }
  for segment in world.road_network.segments {
    if !segment.supports(@energy_valley_contract.ServiceVehicle) {
      continue
    }
    match adjacency.get(segment.from_node_id) {
      Some(next) => next.push(segment.to_node_id)
      None => ()
    }
    if segment.bidirectional {
      match adjacency.get(segment.to_node_id) {
        Some(next) => next.push(segment.from_node_id)
        None => ()
      }
    }
  }
  let visited : Map[@energy_valley_contract.StableId, Bool] = Map([])
  let queue : Array[@energy_valley_contract.StableId] = []
  for anchor in world.road_network.access_anchor_node_ids {
    if nodes.contains(anchor) && !visited.contains(anchor) {
      visited[anchor] = true
      queue.push(anchor)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let current = queue[cursor]
    cursor += 1
    match adjacency.get(current) {
      Some(next_nodes) =>
        for next in next_nodes {
          if !visited.contains(next) {
            visited[next] = true
            queue.push(next)
          }
        }
      None => ()
    }
  }
  let cells : Map[String, Bool] = Map([])
  for node_id in queue {
    match nodes.get(node_id) {
      Some(node) =>
        cells[golden_valley_tile_key(node.grid.column, node.grid.row)] = true
      None => ()
    }
  }
  town_life_world_base_road_cells_cache[world.blueprint_digest] = cells
  cells
}

///|
fn town_life_world_road_point_allowed(
  world : @energy_valley_contract.CompiledTownWorld,
  base_roads : Map[String, Bool],
  x : Int,
  y : Int,
) -> Bool {
  let footprint = golden_valley_contract_tile_footprint(x, y)
  if !golden_valley_contract_polygon_in_bounds(world, footprint) {
    return false
  }
  let key = golden_valley_tile_key(x, y)
  if base_roads.contains(key) {
    return true
  }
  if golden_valley_contract_place_at(world, x, y) is Some(_) {
    return false
  }
  match ecosystem_contract_terrain_kind_at(world, x, y) {
    Some(@energy_valley_contract.Meadow)
    | Some(@energy_valley_contract.Woodland)
    | Some(@energy_valley_contract.Water)
    | Some(@energy_valley_contract.Custom(_)) => true
    _ => false
  }
}

///|
/// Compute the fixed point of custom cells connected cardinally to the base
/// service road. All cells are considered together, so a concurrent connector
/// and far extension survive regardless of their event order.
fn town_life_world_reachable_custom_road_subset(
  world : @energy_valley_contract.CompiledTownWorld,
  encoded_roads : ArrayView[String],
) -> Map[String, Bool] {
  let base_roads = town_life_world_base_road_cells(world)
  let points : Map[String, SavedWorldDeltaGridPoint] = Map([])
  for encoded in encoded_roads {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) =>
        if town_life_world_road_point_allowed(world, base_roads, x, y) {
          points[golden_valley_tile_key(x, y)] = { x, y }
        }
      None => ()
    }
  }
  let reachable : Map[String, Bool] = Map([])
  let queue : Array[SavedWorldDeltaGridPoint] = []
  for entry in points.to_array() {
    let (key, point) = entry
    let touches_base = base_roads.contains(key) ||
      [(0, -1), (1, 0), (0, 1), (-1, 0)].any(delta => {
        base_roads.contains(
          golden_valley_tile_key(point.x + delta.0, point.y + delta.1),
        )
      })
    if touches_base {
      reachable[key] = true
      queue.push(point)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let point = queue[cursor]
    cursor += 1
    for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let key = golden_valley_tile_key(point.x + delta.0, point.y + delta.1)
      match points.get(key) {
        Some(next) if !reachable.contains(key) => {
          reachable[key] = true
          queue.push(next)
        }
        _ => ()
      }
    }
  }
  reachable
}

///|
fn town_life_world_custom_road_distances(
  world : @energy_valley_contract.CompiledTownWorld,
  encoded_roads : ArrayView[String],
) -> Map[String, Int] {
  let base_roads = town_life_world_base_road_cells(world)
  let points : Map[String, SavedWorldDeltaGridPoint] = Map([])
  for encoded in encoded_roads {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) if town_life_world_road_point_allowed(
          world, base_roads, x, y,
        ) => points[golden_valley_tile_key(x, y)] = { x, y }
      _ => ()
    }
  }
  let distances : Map[String, Int] = Map([])
  let queue : Array[SavedWorldDeltaGridPoint] = []
  for entry in points.to_array() {
    let (key, point) = entry
    if base_roads.contains(key) ||
      [(0, -1), (1, 0), (0, 1), (-1, 0)].any(delta => {
        base_roads.contains(
          golden_valley_tile_key(point.x + delta.0, point.y + delta.1),
        )
      }) {
      distances[key] = 0
      queue.push(point)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let point = queue[cursor]
    cursor += 1
    let current = distances[golden_valley_tile_key(point.x, point.y)]
    for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let key = golden_valley_tile_key(point.x + delta.0, point.y + delta.1)
      match points.get(key) {
        Some(next) if !distances.contains(key) => {
          distances[key] = current + 1
          queue.push(next)
        }
        _ => ()
      }
    }
  }
  distances
}

///|
fn town_life_world_reachable_custom_roads(
  world : @energy_valley_contract.CompiledTownWorld,
  encoded_roads : ArrayView[String],
) -> Map[String, Bool]? {
  let reachable = town_life_world_reachable_custom_road_subset(
    world, encoded_roads,
  )
  let unique : Map[String, Bool] = Map([])
  for encoded in encoded_roads {
    match energy_valley_parse_saved_tile(encoded) {
      Some((x, y)) => {
        let key = golden_valley_tile_key(x, y)
        if !town_life_world_road_point_allowed(
            world,
            town_life_world_base_road_cells(world),
            x,
            y,
          ) {
          return None
        }
        unique[key] = true
      }
      None => return None
    }
  }
  if reachable.length() == unique.length() {
    Some(reachable)
  } else {
    None
  }
}

///|
fn town_life_world_building_has_access(
  building : GoldenValleyBuilding,
  base_roads : Map[String, Bool],
  custom_roads : Map[String, Bool],
) -> Bool {
  // A portal meets a side of the footprint. Diagonal corner cells do not
  // provide frontage and must not turn an otherwise detached site valid.
  for x in building.x..<(building.x + building.width) {
    for y in [building.y - 1, building.y + building.depth] {
      let key = golden_valley_tile_key(x, y)
      if base_roads.contains(key) || custom_roads.contains(key) {
        return true
      }
    }
  }
  for y in building.y..<(building.y + building.depth) {
    for x in [building.x - 1, building.x + building.width] {
      let key = golden_valley_tile_key(x, y)
      if base_roads.contains(key) || custom_roads.contains(key) {
        return true
      }
    }
  }
  false
}

///|
fn town_life_world_park_base_valid(
  world : @energy_valley_contract.CompiledTownWorld,
  park : SavedWorldDeltaPark,
) -> Bool {
  golden_valley_tile_placement_block_in_world(world, park.x, park.y) is None &&
  ecosystem_contract_terrain_kind_at(world, park.x, park.y) ==
  Some(@energy_valley_contract.Meadow) &&
  golden_valley_contract_buildable_parcel_for(
    world,
    golden_valley_contract_tile_footprint(park.x, park.y),
  )
  is Some(_)
}

///|
fn town_life_world_building_base_valid(
  world : @energy_valley_contract.CompiledTownWorld,
  base_roads : Map[String, Bool],
  custom_roads : Map[String, Bool],
  building : GoldenValleyBuilding,
) -> Bool {
  if building.name.trim().is_empty() ||
    building.floors <= 0 ||
    building.width <= 0 ||
    building.depth <= 0 ||
    golden_valley_contract_buildable_parcel_for(
      world,
      golden_valley_contract_building_footprint(building),
    )
    is None ||
    !town_life_world_building_has_access(building, base_roads, custom_roads) {
    return false
  }
  for y in building.y..<(building.y + building.depth) {
    for x in building.x..<(building.x + building.width) {
      if golden_valley_tile_placement_block_in_world(world, x, y) is Some(_) {
        return false
      }
    }
  }
  true
}

///|
fn town_life_world_payload_base_valid(
  world : @energy_valley_contract.CompiledTownWorld,
  base_roads : Map[String, Bool],
  custom_roads : Map[String, Bool],
  payload : TownLifeWorldPayload,
) -> Bool {
  match payload {
    WorldRoadCellPayload(point) =>
      custom_roads.contains(golden_valley_tile_key(point.x, point.y))
    WorldParkPayload(park) => town_life_world_park_base_valid(world, park)
    WorldBuildingPayload(building) =>
      town_life_world_building_base_valid(
        world, base_roads, custom_roads, building,
      )
  }
}

///|
/// Base-invalid candidates never reserve geometry. This preserves a valid
/// park/building that happens to overlap a malformed site, and preserves every
/// anchor-connected road component when an unrelated component is detached.
fn town_life_world_filter_base_truth(
  candidates : ArrayView[TownLifeWorldResolvedIncarnation],
  seed : Int,
) -> (
  Array[TownLifeWorldResolvedIncarnation],
  Array[TownLifeWorldRejectedEvent],
) {
  let world = energy_valley_base_contract_world_for_seed(seed)
  let encoded_roads : Array[String] = []
  for incarnation in candidates {
    if incarnation.kind == WorldRoadCell {
      match town_life_world_effective_payload(incarnation) {
        WorldRoadCellPayload(point) =>
          encoded_roads.push(golden_valley_tile_key(point.x, point.y))
        _ => ()
      }
    }
  }
  let reachable_roads = town_life_world_reachable_custom_road_subset(
    world, encoded_roads,
  )
  let base_roads = town_life_world_base_road_cells(world)
  let accepted : Array[TownLifeWorldResolvedIncarnation] = []
  let rejected : Array[TownLifeWorldRejectedEvent] = []
  for incarnation in candidates {
    let original = { ..incarnation, movement: None }
    let add_valid = town_life_world_payload_base_valid(
      world,
      base_roads,
      reachable_roads,
      town_life_world_effective_payload(original),
    )
    if !add_valid {
      rejected.push({
        event_id: incarnation.add.id,
        entity_id: incarnation.entity_id,
        reason_code: if incarnation.kind == WorldRoadCell {
          "detached-road-cell"
        } else {
          "contract-rejected"
        },
        reason: if incarnation.kind == WorldRoadCell {
          "This road cell is outside the anchor-connected canonical road subset."
        } else {
          "The original Add does not satisfy immutable base terrain, parcel, occupancy, or frontage truth."
        },
      })
    } else {
      match incarnation.movement {
        None => accepted.push(original)
        Some(move_event) =>
          if town_life_world_payload_base_valid(
              world,
              base_roads,
              reachable_roads,
              town_life_world_effective_payload(incarnation),
            ) {
            accepted.push(incarnation)
          } else {
            accepted.push(original)
            rejected.push({
              event_id: move_event.id,
              entity_id: incarnation.entity_id,
              reason_code: "move-rejected",
              reason: "The move violated base spatial truth; the valid Add remains active.",
            })
          }
      }
    }
  }
  (accepted, rejected)
}

///|
fn town_life_world_building_frontage_keys(
  building : GoldenValleyBuilding,
) -> Array[String] {
  let keys : Array[String] = []
  for x in building.x..<(building.x + building.width) {
    keys.push(golden_valley_tile_key(x, building.y - 1))
    keys.push(golden_valley_tile_key(x, building.y + building.depth))
  }
  for y in building.y..<(building.y + building.depth) {
    keys.push(golden_valley_tile_key(building.x - 1, y))
    keys.push(golden_valley_tile_key(building.x + building.width, y))
  }
  keys
}

///|
fn town_life_world_road_path_to_anchor(
  sources : ArrayView[String],
  points : Map[String, SavedWorldDeltaGridPoint],
  base_roads : Map[String, Bool],
  already_reachable : Map[String, Bool],
) -> Array[String]? {
  let queue : Array[String] = []
  let visited : Map[String, Bool] = Map([])
  let previous : Map[String, String] = Map([])
  for source in sources {
    if points.contains(source) && !visited.contains(source) {
      visited[source] = true
      queue.push(source)
    }
  }
  let mut cursor = 0
  while cursor < queue.length() {
    let key = queue[cursor]
    cursor += 1
    let point = points[key]
    let anchored = already_reachable.contains(key) ||
      base_roads.contains(key) ||
      [(0, -1), (1, 0), (0, 1), (-1, 0)].any(delta => {
        base_roads.contains(
          golden_valley_tile_key(point.x + delta.0, point.y + delta.1),
        )
      })
    if anchored {
      let path : Array[String] = [key]
      let mut step = key
      while previous.contains(step) {
        step = previous[step]
        path.push(step)
      }
      return Some(path)
    }
    for delta in [(0, -1), (1, 0), (0, 1), (-1, 0)] {
      let next = golden_valley_tile_key(point.x + delta.0, point.y + delta.1)
      if points.contains(next) && !visited.contains(next) {
        visited[next] = true
        previous[next] = key
        queue.push(next)
      }
    }
  }
  None
}

///|
/// Reject only deletions proven to sever a surviving road component or site
/// frontage. Shortest paths are traced through the active+deleted union, so an
/// unrelated deleted branch stays deleted.
fn town_life_world_restore_required_road_deletions(
  raw_active : ArrayView[TownLifeWorldResolvedIncarnation],
  deleted : Map[String, TownLifeWorldResolvedIncarnation],
  seed : Int,
) -> (
  Array[TownLifeWorldResolvedIncarnation],
  Array[TownLifeWorldRejectedEvent],
) {
  if deleted.is_empty() {
    return (raw_active.to_array(), [])
  }
  let world = energy_valley_base_contract_world_for_seed(seed)
  let base_roads = town_life_world_base_road_cells(world)
  let active = raw_active.to_array()
  let active_points : Map[String, SavedWorldDeltaGridPoint] = Map([])
  let active_by_tile : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let deleted_by_tile : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let all_points : Map[String, SavedWorldDeltaGridPoint] = Map([])
  for incarnation in active {
    if incarnation.kind == WorldRoadCell {
      match town_life_world_effective_payload(incarnation) {
        WorldRoadCellPayload(point) => {
          let key = golden_valley_tile_key(point.x, point.y)
          if town_life_world_road_point_allowed(
              world,
              base_roads,
              point.x,
              point.y,
            ) {
            active_points[key] = point
            active_by_tile[key] = incarnation
            all_points[key] = point
          }
        }
        _ => ()
      }
    }
  }
  for entry in deleted.to_array() {
    let incarnation = entry.1
    match town_life_world_effective_payload(incarnation) {
      WorldRoadCellPayload(point) => {
        let key = golden_valley_tile_key(point.x, point.y)
        if town_life_world_road_point_allowed(
            world,
            base_roads,
            point.x,
            point.y,
          ) {
          deleted_by_tile[key] = incarnation
          all_points[key] = point
        }
      }
      _ => ()
    }
  }
  let restored : Map[String, Bool] = Map([])
  let rejections : Array[TownLifeWorldRejectedEvent] = []
  let current_encoded = fn() {
    let values : Array[String] = []
    for entry in active_points.to_array() {
      values.push(entry.0)
    }
    values
  }
  let restore_path = fn(
    path : ArrayView[String],
    dependent_event : TownLifeWorldEvent,
  ) {
    // A later Add cannot resurrect a connector that was already deleted. Only
    // an entity that existed before every deletion on its path is a surviving
    // dependency whose connectivity may reject those deletes.
    for key in path {
      match deleted_by_tile.get(key) {
        Some(incarnation) =>
          match incarnation.deletion {
            Some(delete_event) if town_life_world_event_compare(
                dependent_event, delete_event,
              ) >=
              0 => return
            _ => ()
          }
        None => ()
      }
    }
    for key in path {
      match deleted_by_tile.get(key) {
        Some(incarnation) if !restored.contains(key) => {
          restored[key] = true
          match town_life_world_effective_payload(incarnation) {
            WorldRoadCellPayload(point) => active_points[key] = point
            _ => ()
          }
          active.push({ ..incarnation, deletion: None })
          match incarnation.deletion {
            Some(delete_event) =>
              rejections.push({
                event_id: delete_event.id,
                entity_id: incarnation.entity_id,
                reason_code: "road-delete-dependency",
                reason: "This exact road-cell deletion would sever a surviving component or building frontage.",
              })
            None => ()
          }
        }
        _ => ()
      }
    }
  }
  let road_targets = active_points.to_array()
  road_targets.sort_by((left, right) => left.0.compare(right.0))
  for target in road_targets {
    let reachable = town_life_world_reachable_custom_road_subset(
      world,
      current_encoded(),
    )
    if !reachable.contains(target.0) {
      match
        town_life_world_road_path_to_anchor(
          [target.0],
          all_points,
          base_roads,
          reachable,
        ) {
        Some(path) =>
          match active_by_tile.get(target.0) {
            Some(incarnation) =>
              restore_path(path, town_life_world_effective_event(incarnation))
            None => ()
          }
        None => ()
      }
    }
  }
  let buildings = active.filter(incarnation => incarnation.kind == WorldBuilding)
  buildings.sort_by((left, right) => {
    town_life_world_event_compare(left.add, right.add)
  })
  for incarnation in buildings {
    match town_life_world_effective_payload(incarnation) {
      WorldBuildingPayload(building) => {
        let reachable = town_life_world_reachable_custom_road_subset(
          world,
          current_encoded(),
        )
        if !town_life_world_building_has_access(building, base_roads, reachable) {
          match
            town_life_world_road_path_to_anchor(
              town_life_world_building_frontage_keys(building),
              all_points,
              base_roads,
              reachable,
            ) {
            Some(path) =>
              restore_path(path, town_life_world_effective_event(incarnation))
            None => ()
          }
        }
      }
      _ => ()
    }
  }
  (active, rejections)
}

///|
/// Synchronous CRDT projection validates against the cached immutable base
/// contract plus cheap delta-specific truth. The renderer's single cached
/// TownSnapshot compilation remains the semantic adoption authority; doing a
/// second 256x144 compilation here made every click block for seconds.
fn town_life_world_ledger_valid(
  ledger : EnergyValleyWorldDeltaLedger,
  seed : Int,
) -> Bool {
  if !energy_valley_world_delta_targets_seed(ledger, seed) ||
    !energy_valley_world_delta_valid_for_seed(ledger, seed) {
    return false
  }
  let world = energy_valley_base_contract_world_for_seed(seed)
  let projected = energy_valley_world_delta_projection(ledger)
  let custom_roads = match
    town_life_world_reachable_custom_roads(world, projected.roads) {
    Some(reachable) => reachable
    None => return false
  }
  let base_roads = town_life_world_base_road_cells(world)
  let occupied : Map[String, Bool] = Map([])
  for key in projected.roads {
    occupied[key] = true
  }
  for encoded in projected.parks {
    let (x, y) = match energy_valley_parse_saved_tile(encoded) {
      Some(point) => point
      None => return false
    }
    let key = golden_valley_tile_key(x, y)
    if occupied.contains(key) ||
      golden_valley_tile_placement_block_in_world(world, x, y) is Some(_) ||
      ecosystem_contract_terrain_kind_at(world, x, y) !=
      Some(@energy_valley_contract.Meadow) ||
      golden_valley_contract_buildable_parcel_for(
        world,
        golden_valley_contract_tile_footprint(x, y),
      )
      is None {
      return false
    }
    occupied[key] = true
  }
  for building in projected.buildings {
    if building.width <= 0 ||
      building.depth <= 0 ||
      golden_valley_contract_buildable_parcel_for(
        world,
        golden_valley_contract_building_footprint(building),
      )
      is None ||
      !town_life_world_building_has_access(building, base_roads, custom_roads) {
      return false
    }
    let cells : Array[String] = []
    for y in building.y..<(building.y + building.depth) {
      for x in building.x..<(building.x + building.width) {
        let key = golden_valley_tile_key(x, y)
        if occupied.contains(key) ||
          golden_valley_tile_placement_block_in_world(world, x, y) is Some(_) {
          return false
        }
        cells.push(key)
      }
    }
    for key in cells {
      occupied[key] = true
    }
  }
  true
}

///|
fn town_life_world_incarnation_cells(
  incarnation : TownLifeWorldResolvedIncarnation,
) -> Array[String] {
  let cells : Array[String] = []
  match town_life_world_effective_payload(incarnation) {
    WorldRoadCellPayload(point) =>
      cells.push(golden_valley_tile_key(point.x, point.y))
    WorldParkPayload(park) => cells.push(golden_valley_tile_key(park.x, park.y))
    WorldBuildingPayload(building) =>
      for y in building.y..<(building.y + building.depth) {
        for x in building.x..<(building.x + building.width) {
          cells.push(golden_valley_tile_key(x, y))
        }
      }
  }
  cells
}

///|
/// Cheap deterministic conflict pass. Roads reserve first. Non-road Adds are
/// then accepted in Add order using their original footprints; Moves are a
/// second phase, so a conflicting Move cannot suppress another valid Add and
/// falls back to its own original footprint.
fn town_life_world_filter_geometry(
  candidates : ArrayView[TownLifeWorldResolvedIncarnation],
) -> (
  Array[TownLifeWorldResolvedIncarnation],
  Array[TownLifeWorldRejectedEvent],
) {
  let accepted_by_key : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let rejected : Array[TownLifeWorldRejectedEvent] = []
  let occupied : Map[String, String] = Map([])
  let ordered = candidates.to_array()
  ordered.sort_by((a, b) => town_life_world_event_compare(a.add, b.add))
  for incarnation in ordered {
    if incarnation.kind == WorldRoadCell {
      let owner = town_life_world_incarnation_key(incarnation)
      for cell in town_life_world_incarnation_cells(incarnation) {
        occupied[cell] = owner
      }
      accepted_by_key[owner] = incarnation
    }
  }
  for incarnation in ordered {
    if incarnation.kind == WorldRoadCell {
      continue
    }
    let original = { ..incarnation, movement: None }
    let owner = town_life_world_incarnation_key(original)
    let cells = town_life_world_incarnation_cells(original)
    if cells.any(cell => occupied.contains(cell)) {
      rejected.push({
        event_id: original.add.id,
        entity_id: original.entity_id,
        reason_code: "spatial-conflict",
        reason: "A canonical earlier edit already occupies this footprint.",
      })
    } else {
      for cell in cells {
        occupied[cell] = owner
      }
      accepted_by_key[owner] = original
    }
  }
  let moves = ordered.filter(incarnation => {
    incarnation.kind != WorldRoadCell && incarnation.movement is Some(_)
  })
  moves.sort_by((left, right) => {
    town_life_world_event_compare(
      left.movement.unwrap(),
      right.movement.unwrap(),
    )
  })
  for moved in moves {
    let owner = town_life_world_incarnation_key(moved)
    match accepted_by_key.get(owner) {
      None => ()
      Some(original) => {
        let moved_cells = town_life_world_incarnation_cells(moved)
        if moved_cells.any(cell => {
            match occupied.get(cell) {
              Some(other) => other != owner
              None => false
            }
          }) {
          rejected.push({
            event_id: moved.movement.unwrap().id,
            entity_id: moved.entity_id,
            reason_code: "move-rejected",
            reason: "The move conflicts with another accepted entity; the valid Add remains active.",
          })
        } else {
          for cell in town_life_world_incarnation_cells(original) {
            if occupied.get(cell) == Some(owner) {
              occupied.remove(cell)
            }
          }
          for cell in moved_cells {
            occupied[cell] = owner
          }
          accepted_by_key[owner] = moved
        }
      }
    }
  }
  let accepted = accepted_by_key.values().to_array()
  accepted.sort_by((a, b) => town_life_world_event_compare(a.add, b.add))
  (accepted, rejected)
}

///|
fn town_life_world_filter_budget(
  state : TownLifeWorldState,
  histories : ArrayView[TownLifeWorldResolvedIncarnation],
  accepted_adds : Map[String, Bool],
  eligible_active : ArrayView[TownLifeWorldResolvedIncarnation],
) -> (
  Array[TownLifeWorldResolvedIncarnation],
  Int,
  Array[TownLifeWorldRejectedEvent],
) {
  let active_keys : Map[String, Bool] = Map([])
  for incarnation in eligible_active {
    active_keys[town_life_world_incarnation_key(incarnation)] = true
  }
  let eligible_keys : Map[String, Bool] = Map([])
  for incarnation in eligible_active {
    eligible_keys[town_life_world_incarnation_key(incarnation)] = true
  }
  for incarnation in histories {
    let key = town_life_world_incarnation_key(incarnation)
    if incarnation.deletion is Some(_) && accepted_adds.get(key) == Some(true) {
      eligible_keys[key] = true
    }
  }
  let transitions : Array[TownLifeWorldTransition] = []
  for incarnation in histories {
    let key = town_life_world_incarnation_key(incarnation)
    if accepted_adds.get(key) != Some(true) || !eligible_keys.contains(key) {
      continue
    }
    transitions.push({ incarnation, event: incarnation.add })
    // A dependency-rejected delete leaves the incarnation active and has no
    // economic effect. Only a canonically absent incarnation receives its one
    // accepted delete transition/refund.
    if !active_keys.contains(key) {
      match incarnation.deletion {
        Some(event) => transitions.push({ incarnation, event })
        None => ()
      }
    }
  }
  transitions.sort_by((a, b) => town_life_world_event_compare(a.event, b.event))
  let mut budget = state.epoch.base_budget.max(0)
  let economically_accepted : Map[String, Bool] = Map([])
  let rejected : Array[TownLifeWorldRejectedEvent] = []
  for transition in transitions {
    let key = town_life_world_incarnation_key(transition.incarnation)
    match transition.event.action {
      WorldAdd(_) => {
        let delta = transition.event.budget_delta.min(0)
        if budget + delta >= 0 {
          economically_accepted[key] = true
          budget += delta
        } else {
          economically_accepted[key] = false
          rejected.push({
            event_id: transition.event.id,
            entity_id: transition.event.entity_id,
            reason_code: "budget-exhausted",
            reason: "An earlier canonical accepted transition consumed the remaining world budget.",
          })
        }
      }
      WorldDelete if transition.incarnation.kind == WorldBuilding &&
        economically_accepted.get(key) == Some(true) =>
        budget += transition.event.budget_delta
          .max(0)
          .min((-transition.incarnation.add.budget_delta.min(0) + 1) / 2)
      WorldMove(_) | WorldDelete => ()
    }
  }
  let active = eligible_active.filter(incarnation => {
    economically_accepted.get(town_life_world_incarnation_key(incarnation)) ==
    Some(true)
  })
  (active, budget.max(0), rejected)
}

///|
/// Project one state using historical acceptance facts supplied by the single
/// outer temporal replay. This core never recursively projects event prefixes.
fn town_life_world_projection_core(
  state_raw : TownLifeWorldState,
  seed : Int,
  historically_accepted : Map[String, Bool],
) -> TownLifeWorldProjection {
  let state = town_life_world_normalize_state(state_raw)
  let (histories, history_rejections) = town_life_world_logical_histories(state)
  let transitions : Array[TownLifeWorldTransition] = []
  for incarnation in histories {
    transitions.push({ incarnation, event: incarnation.add })
    match incarnation.movement {
      Some(event) => transitions.push({ incarnation, event })
      None => ()
    }
    match incarnation.deletion {
      Some(event) => transitions.push({ incarnation, event })
      None => ()
    }
  }
  transitions.sort_by((a, b) => town_life_world_event_compare(a.event, b.event))
  let accepted_adds : Map[String, Bool] = Map([])
  let rejected = town_life_world_orphan_rejections(state) + history_rejections
  let active_by_key : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let deleted_road_cells : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  let mut validation_passes = 0
  for transition in transitions {
    let key = town_life_world_incarnation_key(transition.incarnation)
    match transition.event.action {
      WorldAdd(_) => {
        let candidate = {
          ..transition.incarnation,
          movement: None,
          deletion: None,
        }
        let requires_history = transition.incarnation.deletion is Some(_) &&
          transition.incarnation.add.budget_delta < 0
        let valid = !requires_history ||
          historically_accepted.get(key) == Some(true)
        if valid {
          accepted_adds[key] = true
          active_by_key[key] = candidate
        } else {
          accepted_adds[key] = false
          rejected.push({
            event_id: transition.event.id,
            entity_id: transition.event.entity_id,
            reason_code: "historical-add-rejected",
            reason: "The deleted Add never satisfied spatial truth and has no economic effect.",
          })
        }
      }
      WorldMove(_) =>
        match active_by_key.get(key) {
          None =>
            rejected.push({
              event_id: transition.event.id,
              entity_id: transition.event.entity_id,
              reason_code: "inactive-transition",
              reason: "Move targets an incarnation that is not active.",
            })
          Some(current) => {
            let moved = { ..current, movement: Some(transition.event) }
            active_by_key[key] = moved
          }
        }
      WorldDelete =>
        match active_by_key.get(key) {
          None =>
            rejected.push({
              event_id: transition.event.id,
              entity_id: transition.event.entity_id,
              reason_code: "inactive-transition",
              reason: "Delete targets an incarnation that is not active.",
            })
          Some(current) => {
            active_by_key.remove(key)
            if transition.incarnation.kind == WorldRoadCell {
              deleted_road_cells[key] = transition.incarnation
            }
          }
        }
    }
  }
  // Validate the complete road union once. If concurrent deletions sever an
  // access dependency, restore those exact cells as one bounded fixed-point
  // step; additions are already an additive union and are never replayed one
  // full compilation at a time.
  let raw_active = active_by_key.values().to_array()
  let (dependency_active, dependency_rejections) = town_life_world_restore_required_road_deletions(
    raw_active, deleted_road_cells, seed,
  )
  for rejection in dependency_rejections {
    rejected.push(rejection)
  }
  let (base_valid_active, base_rejections) = town_life_world_filter_base_truth(
    dependency_active, seed,
  )
  for rejection in base_rejections {
    rejected.push(rejection)
  }
  // Budget and collision acceptance form a deterministic fixed point. A
  // base-invalid or conflicting early Add consumes no money, and a later valid
  // spender is retried with the released budget instead of being starved by
  // rejected intent.
  let eligible_by_key : Map[String, TownLifeWorldResolvedIncarnation] = Map([])
  for incarnation in base_valid_active {
    eligible_by_key[town_life_world_incarnation_key(incarnation)] = incarnation
  }
  let geometry_rejections_by_event : Map[String, TownLifeWorldRejectedEvent] = Map([],
  )
  let mut active : Array[TownLifeWorldResolvedIncarnation] = []
  let mut budget = state.epoch.base_budget.max(0)
  let mut final_budget_rejections : Array[TownLifeWorldRejectedEvent] = []
  let mut stable = false
  let mut attempt = 0
  while !stable && attempt <= base_valid_active.length() {
    attempt += 1
    let eligible = eligible_by_key.values().to_array()
    eligible.sort_by((left, right) => {
      town_life_world_event_compare(left.add, right.add)
    })
    let (budget_active, next_budget, budget_rejections) = town_life_world_filter_budget(
      state, histories, accepted_adds, eligible,
    )
    // Economics can remove a connector that made another accepted road/site
    // spatially valid in the all-candidate union. Re-run cheap base truth on
    // the economically accepted subset; permanently reject those now-invalid
    // spenders, then retry arbitration so a connector/later valid edit can use
    // the released budget.
    let (budget_base_active, budget_base_rejections) = town_life_world_filter_base_truth(
      budget_active, seed,
    )
    let budget_base_keys : Map[String, Bool] = Map([])
    for incarnation in budget_base_active {
      budget_base_keys[town_life_world_incarnation_key(incarnation)] = true
    }
    let missing : Array[TownLifeWorldResolvedIncarnation] = []
    for incarnation in budget_active {
      let key = town_life_world_incarnation_key(incarnation)
      if !budget_base_keys.contains(key) {
        missing.push(incarnation)
      }
    }
    if !missing.is_empty() {
      // Remove one dependency frontier at a time. Among road cells the farthest
      // cell in the full affordable candidate topology is the canonical loser;
      // this lets a connector and nearer dependent be retried together instead
      // of discarding an entire temporarily detached component.
      let encoded_eligible_roads : Array[String] = []
      for incarnation in eligible {
        if incarnation.kind == WorldRoadCell {
          match town_life_world_effective_payload(incarnation) {
            WorldRoadCellPayload(point) =>
              encoded_eligible_roads.push(
                golden_valley_tile_key(point.x, point.y),
              )
            _ => ()
          }
        }
      }
      let road_distances = town_life_world_custom_road_distances(
        energy_valley_base_contract_world_for_seed(seed),
        encoded_eligible_roads,
      )
      missing.sort_by((left, right) => {
        match
          (
            town_life_world_effective_payload(left),
            town_life_world_effective_payload(right),
          ) {
          (WorldRoadCellPayload(a), WorldRoadCellPayload(b)) => {
            let a_distance = road_distances
              .get(golden_valley_tile_key(a.x, a.y))
              .unwrap_or(-1)
            let b_distance = road_distances
              .get(golden_valley_tile_key(b.x, b.y))
              .unwrap_or(-1)
            let by_distance = b_distance.compare(a_distance)
            if by_distance != 0 {
              by_distance
            } else {
              town_life_world_event_compare(left.add, right.add)
            }
          }
          _ => town_life_world_event_compare(left.add, right.add)
        }
      })
      let removed = missing[0]
      eligible_by_key.remove(town_life_world_incarnation_key(removed))
      for rejection in budget_base_rejections {
        if rejection.event_id == removed.add.id {
          geometry_rejections_by_event[rejection.event_id] = rejection
        }
      }
      continue
    }
    let (geometry_active, geometry_rejections) = town_life_world_filter_geometry(
      budget_base_active,
    )
    let geometry_keys : Map[String, Bool] = Map([])
    for incarnation in geometry_active {
      geometry_keys[town_life_world_incarnation_key(incarnation)] = true
    }
    let mut geometry_removed = false
    for incarnation in budget_base_active {
      let key = town_life_world_incarnation_key(incarnation)
      if !geometry_keys.contains(key) {
        eligible_by_key.remove(key)
        geometry_removed = true
      }
    }
    for rejection in geometry_rejections {
      geometry_rejections_by_event[rejection.event_id] = rejection
    }
    if !geometry_removed {
      active = geometry_active
      budget = next_budget
      final_budget_rejections = budget_rejections
      stable = true
    }
  }
  for rejection in geometry_rejections_by_event.values() {
    rejected.push(rejection)
  }
  for rejection in final_budget_rejections {
    rejected.push(rejection)
  }
  let final_valid = town_life_world_ledger_valid(
    town_life_world_ledger(state, active, budget),
    seed,
  )
  validation_passes += 1
  if !final_valid {
    // Rare slow path: keep the maximal deterministic valid prefix instead of
    // sacrificing unrelated edits because one candidate violated base truth.
    let roads = active.filter(incarnation => incarnation.kind == WorldRoadCell)
    let non_roads = active.filter(incarnation => {
      incarnation.kind != WorldRoadCell
    })
    non_roads.sort_by((a, b) => town_life_world_event_compare(a.add, b.add))
    let prefix : Array[TownLifeWorldResolvedIncarnation] = []
    if !roads.is_empty() {
      validation_passes += 1
      if town_life_world_ledger_valid(
          town_life_world_ledger(state, roads, budget),
          seed,
        ) {
        for road in roads {
          prefix.push(road)
        }
      } else {
        for road in roads {
          rejected.push({
            event_id: road.add.id,
            entity_id: road.entity_id,
            reason_code: "detached-road-union",
            reason: "The joined road-cell union is not anchored to the authoritative network.",
          })
        }
      }
    }
    for incarnation in non_roads {
      let candidate = prefix + [incarnation]
      validation_passes += 1
      if town_life_world_ledger_valid(
          town_life_world_ledger(state, candidate, budget),
          seed,
        ) {
        prefix.push(incarnation)
      } else {
        match incarnation.movement {
          Some(move_event) => {
            let original = { ..incarnation, movement: None }
            validation_passes += 1
            if town_life_world_ledger_valid(
                town_life_world_ledger(state, prefix + [original], budget),
                seed,
              ) {
              prefix.push(original)
              rejected.push({
                event_id: move_event.id,
                entity_id: incarnation.entity_id,
                reason_code: "move-rejected",
                reason: "The move violated spatial truth; the valid Add remains active.",
              })
            } else {
              rejected.push({
                event_id: incarnation.add.id,
                entity_id: incarnation.entity_id,
                reason_code: "contract-rejected",
                reason: "The compiled world rejected this candidate while preserving the valid prefix.",
              })
            }
          }
          None =>
            rejected.push({
              event_id: incarnation.add.id,
              entity_id: incarnation.entity_id,
              reason_code: "contract-rejected",
              reason: "The compiled world rejected this candidate while preserving the valid prefix.",
            })
        }
      }
    }
    active = prefix
    let (economic_prefix, prefix_budget, prefix_budget_rejections) = town_life_world_filter_budget(
      state, histories, accepted_adds, active,
    )
    active = economic_prefix
    budget = prefix_budget
    for rejection in prefix_budget_rejections {
      rejected.push(rejection)
    }
  }
  rejected.sort_by((a, b) => a.event_id.compare(b.event_id))
  {
    ledger: town_life_world_ledger(state, active, budget),
    rejected,
    active,
    validation_passes,
  }
}

///|
/// Replay only destructive boundaries, recording paid incarnations immediately
/// before a Delete can remove or disconnect them. A long stroke followed by
/// many Deletes therefore needs one prefix projection; sequential Add/Delete
/// pairs need one each. The replay is iterative and never recursive.
fn town_life_world_projection(
  state_raw : TownLifeWorldState,
  seed : Int,
) -> TownLifeWorldProjection {
  let state = town_life_world_normalize_state(state_raw)
  let events = state.events.copy()
  events.sort_by(town_life_world_event_compare)
  let historically_accepted : Map[String, Bool] = Map([])
  let paid_deleted_keys : Map[String, Bool] = Map([])
  for incarnation in town_life_world_resolve_incarnations(state) {
    if incarnation.deletion is Some(_) && incarnation.add.budget_delta < 0 {
      paid_deleted_keys[town_life_world_incarnation_key(incarnation)] = true
    }
  }
  if paid_deleted_keys.is_empty() {
    return town_life_world_projection_core(state, seed, historically_accepted)
  }
  let prefix : Array[TownLifeWorldEvent] = []
  let active_unresolved : Map[String, Bool] = Map([])
  for event in events {
    let key = "\{town_life_world_kind_key(event.kind)}\u{1f}\{event.entity_id}\u{1f}\{event.incarnation_id}"
    match event.action {
      WorldAdd(_) => {
        prefix.push(event)
        if paid_deleted_keys.contains(key) {
          active_unresolved[key] = true
        }
      }
      WorldMove(_) => prefix.push(event)
      WorldDelete => {
        if active_unresolved
          .to_array()
          .any(entry => historically_accepted.get(entry.0) != Some(true)) {
          let before_delete = town_life_world_projection_core(
            { ..state, events: prefix.copy() },
            seed,
            historically_accepted,
          )
          for incarnation in before_delete.active {
            let active_key = town_life_world_incarnation_key(incarnation)
            if paid_deleted_keys.contains(active_key) &&
              incarnation.add.budget_delta < 0 {
              historically_accepted[active_key] = true
            }
          }
        }
        prefix.push(event)
        active_unresolved.remove(key)
      }
    }
  }
  town_life_world_projection_core(state, seed, historically_accepted)
}

///|
/// Structural performance guard: road-cell count never increases cheap spatial
/// validation passes. Full TownSnapshot compilation is outside CRDT projection.
fn town_life_world_fast_path_validation_pass_bound(
  state : TownLifeWorldState,
) -> Int {
  ignore(state)
  2
}

///|
fn town_life_world_projection_for_states(
  states : ArrayView[TownLifeWorldState],
  seed : Int,
) -> TownLifeWorldProjection {
  town_life_world_projection(town_life_world_state_for_seed(states, seed), seed)
}

///|
fn town_life_world_apply_projection(
  model : Model,
  projected : TownLifeWorldProjection,
) -> Model {
  let active_building_ids : Map[String, Bool] = Map([])
  for
    building in energy_valley_world_delta_projection(projected.ledger).buildings {
    match golden_valley_nonempty_authored_id(building) {
      Some(id) => active_building_ids[id] = true
      None => ()
    }
  }
  // Cross-domain atomic view: a collected/authored knowledge post with an
  // exact building identity is visible only when that physical incarnation
  // survived canonical world replay. The durable post event is retained in
  // shards, so a later non-conflicting epoch can reconcile without guessing.
  let posts = model.posts.filter(post => {
    if !town_life_post_is_map_bound(post) {
      true
    } else {
      match post.building_id {
        Some(id) => active_building_ids.contains(id)
        // Preserve legacy/offline entries that predate stable spatial IDs;
        // new collect/publish flows always carry the exact writer/dot ID.
        None => true
      }
    }
  })
  { ..model, energy_world_delta: projected.ledger, posts }
}

///|
fn town_life_world_reproject_model(model : Model, seed : Int) -> Model {
  town_life_world_apply_projection(
    model,
    town_life_world_projection_for_states(model.town_life_world_states, seed),
  )
}

///|
/// Materialize the synthesized genesis epoch before allocating a local world
/// event. Projection can derive this state lazily, but Lamport allocation must
/// observe its stamp so the first Add/Move/Delete/Reset is strictly later than
/// the epoch even when authoritative reference loading deferred persistence.
fn town_life_world_ensure_seed_state(model : Model, seed : Int) -> Model {
  if town_life_world_has_state_for_seed(model.town_life_world_states, seed) {
    model
  } else {
    {
      ..model,
      town_life_world_states: town_life_world_replace_state(
        model.town_life_world_states,
        town_life_world_empty_state_for_seed(seed),
      ),
    }
  }
}

///|
fn town_life_world_store_event(
  model : Model,
  event : TownLifeWorldEvent,
  seed : Int,
) -> Model {
  let state = town_life_world_state_for_seed(model.town_life_world_states, seed)
  let states = town_life_world_replace_state(model.town_life_world_states, {
    ..state,
    events: state.events + [event],
  })
  town_life_world_reproject_model(
    { ..model, town_life_world_states: states },
    seed,
  )
}

///|
fn town_life_world_building_id(dot : TownLifeDot) -> String {
  "authored-building-v3-\{dot.writer_id}-\{dot.sequence}"
}

///|
fn town_life_world_add_building(
  model : Model,
  raw : GoldenValleyBuilding,
  budget_delta : Int,
) -> (Model, GoldenValleyBuilding) {
  let seed = active_energy_valley_seed()
  let current = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let state = town_life_world_state_for_seed(
    current.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current, "world-building-add",
  )
  let entity_id = town_life_world_building_id(dot)
  let building = { ..raw, authored_id: Some(entity_id) }
  let event : TownLifeWorldEvent = {
    id: event_id,
    dot,
    stamp,
    epoch_id: state.epoch.id,
    kind: WorldBuilding,
    entity_id,
    incarnation_id: event_id,
    action: WorldAdd(WorldBuildingPayload(building)),
    budget_delta: budget_delta.min(0),
  }
  (town_life_world_store_event(stamped, event, seed), building)
}

///|
fn town_life_world_add_road_cell(
  model : Model,
  point : SavedWorldDeltaGridPoint,
  budget_delta : Int,
) -> Model {
  let seed = active_energy_valley_seed()
  let current = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let state = town_life_world_state_for_seed(
    current.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current, "world-road-add",
  )
  let entity_id = "road-cell-\{point.x}-\{point.y}"
  town_life_world_store_event(
    stamped,
    {
      id: event_id,
      dot,
      stamp,
      epoch_id: state.epoch.id,
      kind: WorldRoadCell,
      entity_id,
      incarnation_id: event_id,
      action: WorldAdd(WorldRoadCellPayload(point)),
      budget_delta: budget_delta.min(0),
    },
    seed,
  )
}

///|
fn town_life_world_add_park(
  model : Model,
  x : Int,
  y : Int,
  budget_delta : Int,
) -> Model {
  let seed = active_energy_valley_seed()
  let current = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let state = town_life_world_state_for_seed(
    current.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current, "world-park-add",
  )
  let entity_id = energy_valley_saved_park_id(x, y)
  town_life_world_store_event(
    stamped,
    {
      id: event_id,
      dot,
      stamp,
      epoch_id: state.epoch.id,
      kind: WorldPark,
      entity_id,
      incarnation_id: event_id,
      action: WorldAdd(WorldParkPayload({ id: entity_id, x, y })),
      budget_delta: budget_delta.min(0),
    },
    seed,
  )
}

///|
fn town_life_world_current_incarnation(
  model : Model,
  kind : TownLifeWorldKind,
  entity_id : String,
) -> TownLifeWorldResolvedIncarnation? {
  let projection = town_life_world_projection_for_states(
    model.town_life_world_states,
    active_energy_valley_seed(),
  )
  for incarnation in projection.active {
    if incarnation.kind == kind && incarnation.entity_id == entity_id {
      return Some(incarnation)
    }
  }
  None
}

///|
fn town_life_world_delete_entity(
  model : Model,
  kind : TownLifeWorldKind,
  entity_id : String,
  budget_delta : Int,
) -> Model {
  let seed = active_energy_valley_seed()
  let current = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let incarnation = match
    town_life_world_current_incarnation(current, kind, entity_id) {
    Some(value) => value
    None => return model
  }
  let state = town_life_world_state_for_seed(
    current.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current, "world-delete",
  )
  town_life_world_store_event(
    stamped,
    {
      id: event_id,
      dot,
      stamp,
      epoch_id: state.epoch.id,
      kind,
      entity_id,
      incarnation_id: incarnation.incarnation_id,
      action: WorldDelete,
      budget_delta: if kind == WorldBuilding {
        budget_delta.max(0)
      } else {
        0
      },
    },
    seed,
  )
}

///|
fn town_life_world_move_entity(
  model : Model,
  kind : TownLifeWorldKind,
  entity_id : String,
  payload : TownLifeWorldPayload,
) -> Model {
  if kind == WorldRoadCell ||
    !town_life_world_payload_matches_kind(kind, payload) {
    return model
  }
  let seed = active_energy_valley_seed()
  let current = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let incarnation = match
    town_life_world_current_incarnation(current, kind, entity_id) {
    Some(value) => value
    None => return model
  }
  let state = town_life_world_state_for_seed(
    current.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current, "world-move",
  )
  town_life_world_store_event(
    stamped,
    {
      id: event_id,
      dot,
      stamp,
      epoch_id: state.epoch.id,
      kind,
      entity_id,
      incarnation_id: incarnation.incarnation_id,
      action: WorldMove(payload),
      budget_delta: 0,
    },
    seed,
  )
}

///|
fn town_life_world_reset(model : Model) -> Model {
  let seed = active_energy_valley_seed()
  let current_model = town_life_world_ensure_seed_state(
    town_life_refresh_model_from_storage(model),
    seed,
  )
  let current = town_life_world_state_for_seed(
    current_model.town_life_world_states,
    seed,
  )
  let (dot, stamp, event_id, stamped) = town_life_next_event(
    current_model, "world-reset",
  )
  let epoch : TownLifeWorldEpoch = {
    id: event_id,
    dot,
    stamp,
    base_budget: 2400,
    base_next_authored_sequence: 1,
  }
  let states = town_life_world_replace_state(stamped.town_life_world_states, {
    ..current,
    epoch,
    events: [],
  })
  town_life_world_reproject_model(
    { ..stamped, town_life_world_states: states },
    seed,
  )
}
