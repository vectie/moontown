///|
extern "js" fn world_migration_test_install_storage(mode : String) -> Unit =
  #| mode => {
  #|   const names = [
  #|     "localStorage",
  #|     "__wenyuReferenceLabels",
  #|     "__wenyuReferenceRoadGraph",
  #|     "__wenyuReferenceBuildings",
  #|     "__wenyuReferenceBuildingComponentRows",
  #|     "__moontownEnergyValleyTransport",
  #|     "__moontownTownLifeV3Observed",
  #|   ];
  #|   const descriptors = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
  #|   const rows = new Map();
  #|   const checkpointPrefix = "moontown-town-life-v3-checkpoint:world:";
  #|   const harness = {
  #|     descriptors,
  #|     rows,
  #|     mode,
  #|     checkpointReplacement: "",
  #|   };
  #|   globalThis.__moontownWorldMigrationDurabilityTest = harness;
  #|   const visibleKeys = () => [...rows.keys()];
  #|   Object.defineProperty(globalThis, "localStorage", {
  #|     configurable: true,
  #|     writable: true,
  #|     value: {
  #|       get length() { return visibleKeys().length; },
  #|       key(index) { return visibleKeys()[index] ?? null; },
  #|       getItem(key) { return rows.get(String(key)) ?? null; },
  #|       setItem(key, value) {
  #|         key = String(key);
  #|         value = String(value);
  #|         if (key.startsWith(checkpointPrefix)) {
  #|           if (harness.mode === "quota") {
  #|             throw new DOMException("quota", "QuotaExceededError");
  #|           }
  #|           if (harness.mode === "mismatch") {
  #|             rows.set(key, harness.checkpointReplacement);
  #|             return;
  #|           }
  #|         }
  #|         rows.set(key, value);
  #|       },
  #|       removeItem(key) { rows.delete(String(key)); },
  #|     },
  #|   });
  #| }

///|
extern "js" fn world_migration_test_set_legacy(text : String) -> Unit =
  #| text => globalThis.__moontownWorldMigrationDurabilityTest?.rows.set(
  #|   "moontown-energy-valley-world-delta-v3",
  #|   text,
  #| )

///|
extern "js" fn world_migration_test_set_checkpoint_replacement(
  text : String,
) -> Unit =
  #| text => {
  #|   const harness = globalThis.__moontownWorldMigrationDurabilityTest;
  #|   if (harness) harness.checkpointReplacement = text;
  #| }

///|
extern "js" fn world_migration_test_checkpoint_count() -> Int =
  #| () => {
  #|   const rows = globalThis.__moontownWorldMigrationDurabilityTest?.rows;
  #|   if (!rows) return 0;
  #|   return [...rows.keys()].filter(key =>
  #|     key.startsWith("moontown-town-life-v3-checkpoint:world:")).length;
  #| }

///|
extern "js" fn world_migration_test_install_reference_assets() -> Unit =
  #| () => {
  #|   const fs = require("node:fs");
  #|   const path = require("node:path");
  #|   const roots = [
  #|     path.resolve(process.cwd(), "../assets/tilemap"),
  #|     path.resolve(process.cwd(), "src/ui/assets/tilemap"),
  #|   ];
  #|   const read = name => {
  #|     for (const root of roots) {
  #|       const candidate = path.join(root, name);
  #|       if (fs.existsSync(candidate)) {
  #|         return JSON.parse(fs.readFileSync(candidate, "utf8"));
  #|       }
  #|     }
  #|     throw new Error("Wenyu migration test asset not found: " + name);
  #|   };
  #|   globalThis.__wenyuReferenceLabels = read("wenyu_reference_labels.json");
  #|   globalThis.__wenyuReferenceRoadGraph = read("wenyu_reference_roads.json");
  #|   globalThis.__wenyuReferenceBuildings = read("wenyu_reference_buildings.json");
  #|   globalThis.__moontownEnergyValleyTransport =
  #|     read("energy-valley-transport-v1.json");
  #| }

///|
extern "js" fn world_migration_test_clear_reference_assets() -> Unit =
  #| () => {
  #|   delete globalThis.__wenyuReferenceLabels;
  #|   delete globalThis.__wenyuReferenceRoadGraph;
  #|   delete globalThis.__wenyuReferenceBuildings;
  #|   delete globalThis.__wenyuReferenceBuildingComponentRows;
  #|   delete globalThis.__moontownEnergyValleyTransport;
  #| }

///|
extern "js" fn world_migration_test_remove_harness() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownWorldMigrationDurabilityTest;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.descriptors) {
  #|     if (descriptor) {
  #|       Object.defineProperty(globalThis, name, descriptor);
  #|     } else {
  #|       delete globalThis[name];
  #|     }
  #|   }
  #|   delete globalThis.__moontownWorldMigrationDurabilityTest;
  #| }

///|
fn world_migration_test_clear_caches() -> Unit {
  golden_valley_world_cache.clear()
  energy_valley_base_contract_world_cache.clear()
  town_life_world_base_road_cells_cache.clear()
  ecosystem_world_snapshot_cache.clear()
  ecosystem_contract_world_cache.clear()
  ecosystem_contract_world_validation_failed_cache.clear()
  ecosystem_contract_world_validation_summary_cache.clear()
  ecosystem_contract_world_validation_issues_cache.clear()
  ecosystem_contract_snapshot_validation_failed_cache.clear()
  ecosystem_contract_snapshot_validation_summary_cache.clear()
  ecosystem_contract_terrain_kind_lookup_cache.clear()
  ecosystem_contract_terrain_walkable_lookup_cache.clear()
}

///|
fn world_migration_test_install_ready_world() -> Int {
  world_migration_test_install_reference_assets()
  world_migration_test_clear_caches()
  active_energy_valley_seed()
}

///|
fn world_migration_test_cleanup() -> Unit {
  world_migration_test_remove_harness()
  world_migration_test_clear_caches()
}

///|
test "legacy world source stays unfenced when checkpoint quota fails" {
  world_migration_test_install_storage("quota")
  let seed = world_migration_test_install_ready_world()
  let ledger = energy_valley_empty_world_delta_for_seed(seed)
  world_migration_test_set_legacy(ToJson::to_json(ledger).stringify())
  let migrated = town_life_world_migrate_initial_save(
    town_life_default_save(),
    seed,
  )
  let has_world = town_life_world_has_state_for_seed(
    migrated.world_states.unwrap_or([]),
    seed,
  )
  let fenced = browser_energy_world_town_life_migration_fenced(
    ledger.base_blueprint_digest,
  )
  let checkpoint_count = world_migration_test_checkpoint_count()
  world_migration_test_cleanup()
  assert_false(has_world)
  assert_false(fenced)
  assert_eq(checkpoint_count, 0)
}

///|
test "legacy world source stays unfenced when checkpoint readback mismatches" {
  world_migration_test_install_storage("mismatch")
  let seed = world_migration_test_install_ready_world()
  let ledger = energy_valley_empty_world_delta_for_seed(seed)
  world_migration_test_set_legacy(ToJson::to_json(ledger).stringify())
  world_migration_test_set_checkpoint_replacement(
    ToJson::to_json(town_life_default_save()).stringify(),
  )
  let migrated = town_life_world_migrate_initial_save(
    town_life_default_save(),
    seed,
  )
  let has_world = town_life_world_has_state_for_seed(
    migrated.world_states.unwrap_or([]),
    seed,
  )
  let fenced = browser_energy_world_town_life_migration_fenced(
    ledger.base_blueprint_digest,
  )
  let checkpoint_count = world_migration_test_checkpoint_count()
  world_migration_test_cleanup()
  assert_false(has_world)
  assert_false(fenced)
  assert_eq(checkpoint_count, 1)
}

///|
test "migration loser adopts and fences an observed V3 winner" {
  world_migration_test_install_storage("mismatch")
  let seed = world_migration_test_install_ready_world()
  let ledger = energy_valley_empty_world_delta_for_seed(seed)
  world_migration_test_set_legacy(ToJson::to_json(ledger).stringify())
  let winner : TownLifeSave = {
    ..town_life_default_save(),
    spark: 77,
    spark_floor: Some(77),
    world_states: Some([town_life_world_empty_state_for_seed(seed)]),
  }
  world_migration_test_set_checkpoint_replacement(
    ToJson::to_json(winner).stringify(),
  )
  let migrated = town_life_world_migrate_initial_save(
    town_life_default_save(),
    seed,
  )
  let has_world = town_life_world_has_state_for_seed(
    migrated.world_states.unwrap_or([]),
    seed,
  )
  let fenced = browser_energy_world_town_life_migration_fenced(
    ledger.base_blueprint_digest,
  )
  let spark = migrated.spark
  world_migration_test_cleanup()
  assert_true(has_world)
  assert_true(fenced)
  assert_eq(spark, 77)
}

///|
test "fallback geography defers migration until reference and transport inputs are ready" {
  world_migration_test_install_storage("normal")
  let seed = world_migration_test_install_ready_world()
  let ledger = energy_valley_empty_world_delta_for_seed(seed)
  world_migration_test_set_legacy(ToJson::to_json(ledger).stringify())

  world_migration_test_clear_reference_assets()
  world_migration_test_clear_caches()
  let deferred = town_life_world_migrate_initial_save(
    town_life_default_save(),
    seed,
  )
  let deferred_world = deferred.world_states.unwrap_or([]).is_empty()
  let deferred_fence = browser_energy_world_town_life_migration_fenced(
    ledger.base_blueprint_digest,
  )
  let deferred_checkpoints = world_migration_test_checkpoint_count()

  world_migration_test_install_reference_assets()
  world_migration_test_clear_caches()
  let committed = town_life_world_migrate_initial_save(
    town_life_default_save(),
    seed,
  )
  let committed_world = town_life_world_has_state_for_seed(
    committed.world_states.unwrap_or([]),
    seed,
  )
  let committed_fence = browser_energy_world_town_life_migration_fenced(
    ledger.base_blueprint_digest,
  )
  let committed_checkpoints = world_migration_test_checkpoint_count()
  world_migration_test_cleanup()

  assert_true(deferred_world)
  assert_false(deferred_fence)
  assert_eq(deferred_checkpoints, 0)
  assert_true(committed_world)
  assert_true(committed_fence)
  assert_eq(committed_checkpoints, 1)
}
