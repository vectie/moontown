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
extern "js" fn browser_energy_valley_save_text() -> String =
  #| () => {
  #|   try {
  #|     return globalThis.localStorage?.getItem(
  #|       "moontown-energy-valley-v2",
  #|     ) ?? "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
extern "js" fn browser_write_energy_valley_save(text : String) -> Unit =
  #| (text) => {
  #|   try {
  #|     globalThis.localStorage?.setItem("moontown-energy-valley-v2", text);
  #|   } catch (_) {}
  #| }

///|
fn initial_energy_valley_save() -> EnergyValleySave {
  let fallback : EnergyValleySave = {
    budget: 2400,
    buildings: [],
    roads: [],
    parks: [],
  }
  let text = browser_energy_valley_save_text()
  if text.is_empty() {
    return fallback
  }
  let parsed = @json.parse(text) catch { _ => return fallback }
  @json.from_json(parsed) catch {
    _ => fallback
  }
}

///|
fn persist_energy_valley_model(model : Model) -> Unit {
  let save : EnergyValleySave = {
    budget: model.energy_build_budget,
    buildings: model.energy_custom_buildings,
    roads: model.energy_roads,
    parks: model.energy_parks,
  }
  browser_write_energy_valley_save(ToJson::to_json(save).stringify())
}

///|
extern "js" fn browser_reset_energy_valley(regenerate : Bool) -> Unit =
  #| (regenerate) => {
  #|   try {
  #|     globalThis.localStorage?.removeItem("moontown-energy-valley-v2");
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
