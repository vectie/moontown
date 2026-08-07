///|
/// Package-private compiler output cache. Keeping this authority outside the
/// Canvas implementation prevents rendering code from owning compilation or
/// invalidation policy.
let ecosystem_world_snapshot_cache : Map[String, EcosystemWorldSnapshot] = Map([])

///|
fn ecosystem_snapshot_digest_step(hash : Int, value : Int) -> Int {
  (hash * 131 + value.abs() % 1000003) % 2147483629
}

///|
fn ecosystem_contract_rejection_fingerprint(
  model : Model,
  seed : Int,
) -> (Int, Int) {
  let rejected = town_life_world_projection_for_states(
      model.town_life_world_states,
      seed,
    ).rejected
  let mut digest = 23
  for rejection in rejected {
    digest = ecosystem_snapshot_digest_step(
      digest,
      ecosystem_stable_hash(rejection.event_id),
    )
    digest = ecosystem_snapshot_digest_step(
      digest,
      ecosystem_stable_hash(rejection.entity_id),
    )
    digest = ecosystem_snapshot_digest_step(
      digest,
      ecosystem_stable_hash(rejection.reason_code),
    )
    digest = ecosystem_snapshot_digest_step(
      digest,
      ecosystem_stable_hash(rejection.reason),
    )
  }
  (rejected.length(), digest)
}

///|
fn ecosystem_snapshot_cache_key(model : Model, seed : Int) -> String {
  let ledger = model.energy_world_delta
  let digest = ecosystem_snapshot_digest_step(
    ecosystem_snapshot_digest_step(17, seed),
    ecosystem_snapshot_digest_step(
      ecosystem_stable_hash(ledger.base_blueprint_digest),
      energy_valley_saved_operations_digest(ledger.operations),
    ),
  )
  "\{seed}:\{ledger.revision}:\{ledger.operations.length()}:\{digest}"
}

///|
fn ecosystem_contract_world_cache_key(model : Model, seed : Int) -> String {
  // Rejected CRDT events are renderer-neutral Map Lab diagnostics attached to
  // CompiledTownWorld, but do not alter the geometry snapshot. Concurrent
  // rejected histories can have identical accepted operations and the same
  // maximum Lamport revision, so their full deterministic content—not merely
  // their count—extends only the contract-world cache identity.
  let (rejection_count, rejection_digest) = ecosystem_contract_rejection_fingerprint(
    model, seed,
  )
  "\{ecosystem_snapshot_cache_key(model, seed)}:rejected:\{rejection_count}:\{rejection_digest}"
}

///|
/// Compiling ambient footprints, road cells, portals, public-realm slots and
/// stable resource bindings is intentionally not animation-frame work. A
/// single-slot cache invalidates only for seed or local map changes; runtime
/// observations are projected separately through `TownSnapshot`.
fn ecosystem_cached_world_snapshot(
  model : Model,
  seed : Int,
) -> EcosystemWorldSnapshot {
  let key = ecosystem_snapshot_cache_key(model, seed)
  match ecosystem_world_snapshot_cache.get(key) {
    Some(snapshot) => snapshot
    None => {
      let snapshot = ecosystem_world_snapshot_for_model(model, seed)
      ecosystem_world_snapshot_cache.clear()
      ecosystem_world_snapshot_cache[key] = snapshot
      snapshot
    }
  }
}
