///|
extern "js" fn browser_energy_valley_intro_seen() -> Bool =
  #| () => {
  #|   try {
  #|     return globalThis.localStorage?.getItem("moontown-intro-seen-v1") === "1";
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn browser_mark_energy_valley_intro_seen() -> Unit =
  #| () => {
  #|   try {
  #|     globalThis.localStorage?.setItem("moontown-intro-seen-v1", "1");
  #|   } catch (_) {}
  #| }

///|
extern "js" fn browser_energy_valley_legacy_migration_save_text() -> String =
  #| () => {
  #|   try {
  #|     return globalThis.localStorage?.getItem(
  #|       "moontown-energy-valley-world-delta-v3",
  #|     ) ?? globalThis.localStorage?.getItem("moontown-energy-valley-v2") ?? "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn browser_energy_world_town_life_migration_fenced(
  digest : String,
) -> Bool =
  #| (digest) => {
  #|   try {
  #|     void digest;
  #|     return globalThis.localStorage?.getItem(
  #|       "moontown-town-life-v3-world-source-migrated",
  #|     ) !== null;
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
/// Installs one immutable TownLife checkpoint before fencing the legacy map.
/// A concurrent first-open loser re-reads the joined V3 authority in MoonBit.
extern "js" fn browser_install_energy_world_town_life_checkpoint(
  digest : String,
  text : String,
) -> Bool =
  #| (digest, text) => {
  #|   try {
  #|     const storage = globalThis.localStorage;
  #|     if (!storage || !text) return false;
  #|     const fence = "moontown-town-life-v3-world-source-migrated";
  #|     if (storage.getItem(fence) !== null) return false;
  #|     const random = globalThis.crypto?.randomUUID?.() ??
  #|       `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  #|     const key = `moontown-town-life-v3-checkpoint:world:${digest}:${random}`;
  #|     storage.setItem(key, text);
  #|     if (storage.getItem(key) !== text) return false;
  #|     // MoonBit re-reads the joined V3 authority before setting the fence.
  #|     // Keeping installation and fencing separate closes first-open races.
  #|     void digest;
  #|     return true;
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
extern "js" fn browser_fence_energy_world_town_life_migration(
  digest : String,
) -> Unit =
  #| (digest) => {
  #|   try {
  #|     globalThis.localStorage?.setItem(
  #|       "moontown-town-life-v3-world-source-migrated",
  #|       digest,
  #|     );
  #|   } catch (_) {}
  #| }

///|
/// The Wenyu source is one typed geography: labels, roads, and authored
/// building evidence must all be present before a one-way legacy import can
/// bind coordinates to its digest. A fallback world remains renderable, but
/// it must never consume or fence the migration source.
fn browser_energy_valley_authoritative_reference_ready() -> Bool {
  reference_tile_snapshot_ready() &&
  reference_road_graph_snapshot_ready() &&
  reference_building_snapshot_ready()
}

///|
fn decode_legacy_energy_valley_v2(
  text : String,
  seed : Int,
) -> EnergyValleyWorldDeltaLedger? {
  let parsed = @json.parse(text) catch { _ => return None }
  let decoded : EnergyValleySave = @json.from_json(parsed) catch {
    _ => return None
  }
  let migrated = golden_valley_migrate_energy_save(decoded)
  Some(
    energy_valley_world_delta_from_projection(
      migrated,
      1,
      energy_valley_base_blueprint_digest_for_seed(seed),
    ),
  )
}

///|
fn legacy_energy_valley_world_delta_for_migration(
  seed : Int,
) -> EnergyValleyWorldDeltaLedger? {
  let text = browser_energy_valley_legacy_migration_save_text()
  if text.is_empty() {
    return None
  }
  match decode_energy_valley_world_delta_save(text) {
    Some(delta) if energy_valley_world_delta_valid_for_seed(delta, seed) =>
      return Some(delta)
    Some(_) => return None
    None => ()
  }
  match decode_legacy_energy_valley_v2(text, seed) {
    Some(migrated) if energy_valley_world_delta_valid_for_seed(migrated, seed) =>
      Some(migrated)
    _ => None
  }
}

///|
extern "js" fn browser_reset_energy_valley(regenerate : Bool) -> Unit =
  #| (regenerate) => {
  #|   try {
  #|     if (regenerate) {
  #|       const buffer = new Uint32Array(1);
  #|       globalThis.crypto?.getRandomValues(buffer);
  #|       const seed = buffer[0] || 20260727;
  #|       globalThis.localStorage?.setItem(
  #|         "moontown-energy-valley-seed-v2",
  #|         String(seed),
  #|       );
  #|       const url = new URL(globalThis.location?.href || "http://local/");
  #|       url.searchParams.set("seed", String(seed));
  #|       globalThis.location?.assign(url.toString());
  #|       return;
  #|     }
  #|     globalThis.location?.reload();
  #|   } catch (_) {}
  #| }
