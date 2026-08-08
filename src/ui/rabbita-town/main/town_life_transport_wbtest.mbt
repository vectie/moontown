///|
fn town_life_transport_test_entry(key : String, raw : String) -> String {
  ToJson::to_json(TownLifeTransportEntry::{ key, raw }).stringify()
}

///|
fn town_life_transport_test_envelope(
  writer_id : String,
  sequence : Int,
  payload : String,
) -> String {
  ToJson::to_json(TownLifeTransportEnvelope::{
    transport_version: town_life_transport_version,
    writer_id,
    sequence,
    written_at_ms: 1000.0 + sequence.to_double(),
    payload,
  }).stringify()
}

///|
/// Installs a tiny browser harness whose Web-Lock request never invokes its
/// callback, mirroring a tab that navigates immediately after saving.
extern "js" fn town_life_transport_test_install_delayed_lock(
  write_mode : String,
) -> Unit =
  #| writeMode => {
  #|   const names = [
  #|     "localStorage",
  #|     "navigator",
  #|     "__moontownTownLifeV3WriterState",
  #|     "__moontownTownLifeV3Observed",
  #|     "__moontownTownLifeV3Channel",
  #|     "__moontownTownLifeV3Compaction",
  #|   ];
  #|   const saved = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
  #|   const harness = {
  #|     saved,
  #|     rows: new Map(),
  #|     lockRequests: 0,
  #|     lockCallbacks: [],
  #|     broadcasts: 0,
  #|     observationSequence: 0,
  #|     writeMode,
  #|   };
  #|   globalThis.__moontownTownLifeDelayedLockTest = harness;
  #|   const install = (name, value) => Object.defineProperty(globalThis, name, {
  #|     value,
  #|     configurable: true,
  #|     writable: true,
  #|   });
  #|   install("localStorage", {
  #|     get length() { return harness.rows.size; },
  #|     key(index) { return [...harness.rows.keys()][index] ?? null; },
  #|     getItem(key) { return harness.rows.get(String(key)) ?? null; },
  #|     setItem(key, value) {
  #|       if (harness.writeMode === "quota") throw new Error("QuotaExceededError");
  #|       if (harness.writeMode === "mismatch") {
  #|         harness.rows.set(String(key), `mismatch:${String(value)}`);
  #|         return;
  #|       }
  #|       harness.rows.set(String(key), String(value));
  #|     },
  #|     removeItem(key) { harness.rows.delete(String(key)); },
  #|   });
  #|   install("navigator", {
  #|     locks: {
  #|       request(_name, _options, callback) {
  #|         harness.lockRequests += 1;
  #|         harness.lockCallbacks.push(callback);
  #|         return new Promise(() => {});
  #|       },
  #|     },
  #|   });
  #|   install("__moontownTownLifeV3WriterState", {
  #|     writerId: "delayed-lock-writer",
  #|     ownerToken: "delayed-lock-owner",
  #|     sequence: 1,
  #|   });
  #|   install("__moontownTownLifeV3Observed", {
  #|     capturedAtMs: Date.now(),
  #|     entries: [],
  #|   });
  #|   install("__moontownTownLifeV3Channel", {
  #|     postMessage() { harness.broadcasts += 1; },
  #|   });
  #|   delete globalThis.__moontownTownLifeV3Compaction;
  #| }

///|
extern "js" fn town_life_transport_test_delayed_lock_raw(
  key : String,
) -> String =
  #| key => globalThis.__moontownTownLifeDelayedLockTest?.rows.get(key) ?? ""

///|
extern "js" fn town_life_transport_test_delayed_lock_requests() -> Int =
  #| () => globalThis.__moontownTownLifeDelayedLockTest?.lockRequests ?? 0

///|
extern "js" fn town_life_transport_test_delayed_lock_broadcasts() -> Int =
  #| () => globalThis.__moontownTownLifeDelayedLockTest?.broadcasts ?? 0

///|
extern "js" fn town_life_transport_test_disable_locks() -> Unit =
  #| () => {
  #|   Object.defineProperty(globalThis, "navigator", {
  #|     value: {}, configurable: true, writable: true,
  #|   });
  #| }

///|
extern "js" fn town_life_transport_test_delayed_lock_row_count() -> Int =
  #| () => globalThis.__moontownTownLifeDelayedLockTest?.rows.size ?? 0

///|
extern "js" fn town_life_transport_test_delayed_lock_pending_callbacks() -> Int =
  #| () => globalThis.__moontownTownLifeDelayedLockTest?.lockCallbacks.length ?? 0

///|
extern "js" fn town_life_transport_test_delayed_lock_seed(
  key : String,
  raw : String,
) -> Unit =
  #| (key, raw) => {
  #|   globalThis.__moontownTownLifeDelayedLockTest?.rows.set(key, raw);
  #| }

///|
extern "js" fn town_life_transport_test_delayed_lock_observe_shards() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeDelayedLockTest;
  #|   if (!harness) return;
  #|   const prefix = "moontown-town-life-v3-shard:";
  #|   globalThis.__moontownTownLifeV3Observed = {
  #|     testId: ++harness.observationSequence,
  #|     capturedAtMs: Date.now(),
  #|     entries: [...harness.rows]
  #|       .filter(([key]) => key.startsWith(prefix))
  #|       .map(([key, raw]) => ({ key, raw })),
  #|   };
  #| }

///|
extern "js" fn town_life_transport_test_delayed_lock_observation_id() -> Int =
  #| () => globalThis.__moontownTownLifeV3Observed?.testId ?? 0

///|
extern "js" fn town_life_transport_test_delayed_lock_fire() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeDelayedLockTest;
  #|   harness?.lockCallbacks.shift()?.();
  #| }

///|
extern "js" fn town_life_transport_test_remove_delayed_lock() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeDelayedLockTest;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.saved) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownTownLifeDelayedLockTest;
  #| }

///|
/// Browser harness for repeated writer-realm shutdown and adversarial writer
/// ownership interleavings.
extern "js" fn town_life_transport_test_install_writer_lease_churn() -> Unit =
  #| () => {
  #|   const names = [
  #|     "localStorage", "sessionStorage", "crypto", "addEventListener",
  #|     "setInterval", "clearInterval", "__moontownTownLifeV3WriterState",
  #|   ];
  #|   const saved = new Map(names.map(name => [
  #|     name, Object.getOwnPropertyDescriptor(globalThis, name),
  #|   ]));
  #|   const rows = new Map();
  #|   const sessionRows = new Map();
  #|   const listeners = new Map();
  #|   const bucket = name => {
  #|     if (!listeners.has(name)) listeners.set(name, new Set());
  #|     return listeners.get(name);
  #|   };
  #|   const harness = {
  #|     saved, rows, sessionRows, listeners, uuid: 0, interval: 0,
  #|     contendOnReadKey: "", contenderId: "", contenderSawActive: false,
  #|   };
  #|   globalThis.__moontownTownLifeWriterLeaseChurnTest = harness;
  #|   const install = (name, value) => Object.defineProperty(globalThis, name, {
  #|     value, configurable: true, writable: true,
  #|   });
  #|   install("localStorage", {
  #|     get length() { return rows.size; },
  #|     key(index) { return [...rows.keys()][index] ?? null; },
  #|     getItem(key) {
  #|       const normalized = String(key);
  #|       const current = rows.get(normalized) ?? null;
  #|       if (normalized === harness.contendOnReadKey) {
  #|         harness.contendOnReadKey = "";
  #|         try {
  #|           const lease = JSON.parse(current || "null");
  #|           harness.contenderSawActive = lease?.released === false;
  #|           if (harness.contenderSawActive) {
  #|             const prefix = "moontown-town-life-v3-lease:";
  #|             const writerId = normalized.slice(prefix.length);
  #|             harness.contenderId = `${writerId}-contender`;
  #|             rows.set(`${prefix}${harness.contenderId}`, JSON.stringify({
  #|               owner_token: "conforming-contender-owner",
  #|               released: false,
  #|               updated_at_ms: Date.now(),
  #|               last_sequence: 0,
  #|             }));
  #|           }
  #|         } catch (_) {}
  #|       }
  #|       return current;
  #|     },
  #|     setItem(key, value) { rows.set(String(key), String(value)); },
  #|     removeItem(key) { rows.delete(String(key)); },
  #|   });
  #|   install("sessionStorage", {
  #|     getItem(key) { return sessionRows.get(String(key)) ?? null; },
  #|     setItem(key, value) { sessionRows.set(String(key), String(value)); },
  #|     removeItem(key) { sessionRows.delete(String(key)); },
  #|     clear() { sessionRows.clear(); },
  #|   });
  #|   install("crypto", {
  #|     randomUUID() {
  #|       harness.uuid += 1;
  #|       return `lease-churn-${String(harness.uuid).padStart(8, "0")}`;
  #|     },
  #|   });
  #|   install("addEventListener", (name, callback) => {
  #|     bucket(name).add(callback);
  #|   });
  #|   install("setInterval", () => ++harness.interval);
  #|   install("clearInterval", () => {});
  #|   delete globalThis.__moontownTownLifeV3WriterState;
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_new_lifetime() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   harness?.sessionRows.clear();
  #|   delete globalThis.__moontownTownLifeV3WriterState;
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_select_session(
  writer_id : String,
) -> Unit =
  #| writerId => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   harness?.sessionRows.set("moontown-town-life-v3-writer-id", writerId);
  #|   delete globalThis.__moontownTownLifeV3WriterState;
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_contend_on_read(
  writer_id : String,
) -> Unit =
  #| writerId => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   if (harness) {
  #|     harness.contendOnReadKey =
  #|       `moontown-town-life-v3-lease:${writerId}`;
  #|   }
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_contender_id() -> String =
  #| () => globalThis.__moontownTownLifeWriterLeaseChurnTest?.contenderId ?? ""

///|
extern "js" fn town_life_transport_test_writer_lease_contender_saw_active() -> Bool =
  #| () => Boolean(
  #|   globalThis.__moontownTownLifeWriterLeaseChurnTest?.contenderSawActive,
  #| )

///|
extern "js" fn town_life_transport_test_writer_lease_fire(
  event_name : String,
  persisted : Bool,
) -> Unit =
  #| (eventName, persisted) => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   for (const callback of harness?.listeners.get(eventName) ?? []) {
  #|     callback({ persisted });
  #|   }
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_fire_at(
  event_name : String,
  listener_index : Int,
  persisted : Bool,
) -> Unit =
  #| (eventName, listenerIndex, persisted) => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   const callback = [
  #|     ...(harness?.listeners.get(eventName) ?? []),
  #|   ][listenerIndex];
  #|   callback?.({ persisted });
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_count() -> Int =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   const prefix = "moontown-town-life-v3-lease:";
  #|   return [...(harness?.rows.keys() ?? [])]
  #|     .filter(key => key.startsWith(prefix)).length;
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_has(
  writer_id : String,
) -> Bool =
  #| writerId => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   return harness?.rows.has(
  #|     `moontown-town-life-v3-lease:${writerId}`,
  #|   ) ?? false;
  #| }

///|
extern "js" fn town_life_transport_test_writer_lease_raw(
  writer_id : String,
) -> String =
  #| writerId => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   return harness?.rows.get(
  #|     `moontown-town-life-v3-lease:${writerId}`,
  #|   ) ?? "";
  #| }

///|
extern "js" fn town_life_transport_test_remove_writer_lease_churn() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #|   if (!harness) return;
  #|   for (const [name, descriptor] of harness.saved) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownTownLifeWriterLeaseChurnTest;
  #| }

///|
/// A deterministic browser-event harness for the live TownLife V3 bridge. It
/// uses queued timers so the test can prove installation never dispatches into
/// Rabbita synchronously during `with_init`.
extern "js" fn town_life_transport_test_install_storage_bridge() -> Unit =
  #| () => {
  #|   const names = [
  #|     "localStorage",
  #|     "addEventListener",
  #|     "removeEventListener",
  #|     "setTimeout",
  #|     "clearTimeout",
  #|     "setInterval",
  #|     "clearInterval",
  #|     "BroadcastChannel",
  #|     "document",
  #|     "__moontownTownLifeV3StorageBridge",
  #|     "__moontownTownLifeV3Observed",
  #|   ];
  #|   const saved = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
  #|   const listeners = new Map();
  #|   const documentListeners = new Map();
  #|   const timers = new Map();
  #|   const intervals = new Map();
  #|   const rows = new Map();
  #|   let nextTimer = 0;
  #|   const bucket = (table, name) => {
  #|     if (!table.has(name)) table.set(name, new Set());
  #|     return table.get(name);
  #|   };
  #|   const harness = {
  #|     saved,
  #|     listeners,
  #|     documentListeners,
  #|     timers,
  #|     intervals,
  #|     rows,
  #|   };
  #|   globalThis.__moontownTownLifeStorageBridgeTest = harness;
  #|   const install = (name, value) => Object.defineProperty(globalThis, name, {
  #|     value,
  #|     configurable: true,
  #|     writable: true,
  #|   });
  #|   install("localStorage", {
  #|     get length() { return rows.size; },
  #|     key(index) { return [...rows.keys()][index] ?? null; },
  #|     getItem(key) { return rows.get(String(key)) ?? null; },
  #|     setItem(key, value) { rows.set(String(key), String(value)); },
  #|     removeItem(key) { rows.delete(String(key)); },
  #|   });
  #|   install("addEventListener", (name, callback) => {
  #|     bucket(listeners, name).add(callback);
  #|   });
  #|   install("removeEventListener", (name, callback) => {
  #|     bucket(listeners, name).delete(callback);
  #|   });
  #|   install("setTimeout", callback => {
  #|     nextTimer += 1;
  #|     timers.set(nextTimer, callback);
  #|     return nextTimer;
  #|   });
  #|   install("clearTimeout", id => timers.delete(id));
  #|   install("setInterval", callback => {
  #|     nextTimer += 1;
  #|     intervals.set(nextTimer, callback);
  #|     return nextTimer;
  #|   });
  #|   install("clearInterval", id => intervals.delete(id));
  #|   install("BroadcastChannel", class {
  #|     constructor() { this.listeners = new Set(); }
  #|     addEventListener(name, callback) {
  #|       if (name === "message") this.listeners.add(callback);
  #|     }
  #|     close() { this.listeners.clear(); }
  #|   });
  #|   install("document", {
  #|     visibilityState: "visible",
  #|     addEventListener(name, callback) {
  #|       bucket(documentListeners, name).add(callback);
  #|     },
  #|     removeEventListener(name, callback) {
  #|       bucket(documentListeners, name).delete(callback);
  #|     },
  #|   });
  #|   delete globalThis.__moontownTownLifeV3StorageBridge;
  #|   delete globalThis.__moontownTownLifeV3Observed;
  #| }

///|
extern "js" fn town_life_transport_test_storage_bridge_set(
  key : String,
  raw : String,
) -> Unit =
  #| (key, raw) => {
  #|   globalThis.__moontownTownLifeStorageBridgeTest?.rows.set(key, raw);
  #| }

///|
extern "js" fn town_life_transport_test_storage_bridge_fire(
  event_name : String,
  key : String,
) -> Unit =
  #| (eventName, key) => {
  #|   const harness = globalThis.__moontownTownLifeStorageBridgeTest;
  #|   if (!harness) return;
  #|   for (const callback of harness.listeners.get(eventName) ?? []) {
  #|     callback({ key });
  #|   }
  #| }

///|
extern "js" fn town_life_transport_test_storage_bridge_flush() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeStorageBridgeTest;
  #|   if (!harness) return;
  #|   let passes = 0;
  #|   while (harness.timers.size > 0 && passes < 20) {
  #|     const pending = [...harness.timers.entries()]
  #|       .sort((left, right) => left[0] - right[0]);
  #|     harness.timers.clear();
  #|     for (const [, callback] of pending) callback();
  #|     passes += 1;
  #|   }
  #| }

///|
extern "js" fn town_life_transport_test_storage_bridge_listener_count(
  target : String,
  event_name : String,
) -> Int =
  #| (target, eventName) => {
  #|   const harness = globalThis.__moontownTownLifeStorageBridgeTest;
  #|   const table = target === "document"
  #|     ? harness?.documentListeners : harness?.listeners;
  #|   return table?.get(eventName)?.size ?? 0;
  #| }

///|
extern "js" fn town_life_transport_test_storage_bridge_row_count() -> Int =
  #| () => globalThis.__moontownTownLifeStorageBridgeTest?.rows.size ?? 0

///|
extern "js" fn town_life_transport_test_remove_storage_bridge() -> Unit =
  #| () => {
  #|   const harness = globalThis.__moontownTownLifeStorageBridgeTest;
  #|   if (!harness) return;
  #|   for (const callback of harness.listeners.get("unload") ?? []) {
  #|     callback({});
  #|   }
  #|   for (const [name, descriptor] of harness.saved) {
  #|     if (descriptor) Object.defineProperty(globalThis, name, descriptor);
  #|     else delete globalThis[name];
  #|   }
  #|   delete globalThis.__moontownTownLifeStorageBridgeTest;
  #| }

///|
test "storage bridge defers then enqueues relevant cross-tab signals" {
  let base = init_model()
  town_life_transport_test_install_storage_bridge()
  let dispatched = [0]
  let enqueued = [0]
  let dispatch : Dispatch[Msg] = Emit(fn(message) {
    if message is TownLifeStorageChanged {
      dispatched[0] = dispatched[0] + 1
    }
    @rabbita.none
  })
  browser_install_town_life_v3_storage_subscription(
    town_life_storage_enqueued_callback(
      fn() { dispatch(TownLifeStorageChanged) },
      fn(_command) { enqueued[0] = enqueued[0] + 1 },
    ),
  )
  let before_initial_flush = enqueued[0]
  town_life_transport_test_storage_bridge_flush()
  let after_initial_flush = enqueued[0]
  town_life_transport_test_storage_bridge_fire("storage", "unrelated-key")
  town_life_transport_test_storage_bridge_flush()
  let after_unrelated = enqueued[0]
  let remote : PlayerAvatar = {
    name: "Remote Tab Resident",
    persona: "researcher",
    color: 2,
    sprite_index: 3,
    title: "谷光新手",
  }
  let remote_save : TownLifeSave = {
    ..town_life_default_save(),
    player: Some(remote),
    player_stamp: Some({ lamport: 12, writer_id: "remote-tab" }),
    writer_counters: Some([{ writer_id: "remote-tab", sequence: 12 }]),
  }
  let remote_key = town_life_v3_checkpoint_prefix + "remote-tab"
  town_life_transport_test_storage_bridge_set(
    remote_key,
    ToJson::to_json(remote_save).stringify(),
  )
  town_life_transport_test_storage_bridge_fire("storage", remote_key)
  town_life_transport_test_storage_bridge_flush()
  let after_remote = enqueued[0]
  let global_visibility_listeners = town_life_transport_test_storage_bridge_listener_count(
    "global", "visibilitychange",
  )
  let document_visibility_listeners = town_life_transport_test_storage_bridge_listener_count(
    "document", "visibilitychange",
  )
  let local = {
    ..base,
    player: None,
    town_life_player_stamp: None,
    town_life_writer_counters: [],
  }
  let (_, updated) = update(dispatch, TownLifeStorageChanged, local)
  let updated_name = match updated.player {
    Some(player) => player.name
    None => ""
  }
  let rows_after_update = town_life_transport_test_storage_bridge_row_count()
  town_life_transport_test_remove_storage_bridge()
  assert_eq(before_initial_flush, 0)
  assert_eq(after_initial_flush, 1)
  assert_eq(after_unrelated, 1)
  assert_eq(after_remote, 2)
  assert_eq(dispatched[0], 2)
  assert_eq(global_visibility_listeners, 0)
  assert_eq(document_visibility_listeners, 1)
  assert_eq(updated_name, "Remote Tab Resident")
  // Storage-driven joins are read-only and must not echo another tab's shard.
  assert_eq(rows_after_update, 1)
}

///|
test "V3 transport unwraps immutable envelopes in deterministic key order" {
  let first = town_life_transport_test_envelope("writer-a", 1, "save-a")
  let second = town_life_transport_test_envelope("writer-b", 2, "save-b")
  let texts = town_life_transport_save_texts([
    town_life_transport_test_entry(
      town_life_v3_shard_key("writer-b", 2),
      second,
    ),
    "not-an-entry",
    town_life_transport_test_entry(
      town_life_v3_checkpoint_prefix + "migration",
      "legacy-checkpoint",
    ),
    town_life_transport_test_entry(town_life_v3_shard_key("writer-a", 1), first),
  ])
  assert_eq(texts, ["legacy-checkpoint", "save-a", "save-b"])
  assert_eq(
    town_life_v3_shard_key("writer-a", 1),
    "moontown-town-life-v3-shard:writer-a:0000000000000001",
  )
  assert_true(
    town_life_v3_shard_key("writer-a", 2) !=
    town_life_v3_shard_key("writer-a", 1),
  )
}

///|
test "V3 reads keep only each writer's highest valid cumulative envelope" {
  let older = { ..town_life_default_save(), analytics: ["older-only"] }
  let latest = town_life_cumulative_save(
    { ..init_model(), analytics: ["latest-local"] },
    [ToJson::to_json(older).stringify()],
  )
  let remote = { ..town_life_default_save(), analytics: ["remote-only"] }
  let mismatched = {
    ..town_life_default_save(),
    analytics: ["mismatched-independent"],
  }
  let older_text = ToJson::to_json(older).stringify()
  let latest_text = ToJson::to_json(latest).stringify()
  let remote_text = ToJson::to_json(remote).stringify()
  let mismatched_text = ToJson::to_json(mismatched).stringify()
  let older_key = town_life_v3_shard_key("writer-a", 1)
  let latest_key = town_life_v3_shard_key("writer-a", 2)
  let corrupt_key = town_life_v3_shard_key("writer-a", 3)
  let remote_key = town_life_v3_shard_key("writer-b", 1)
  let mismatched_key = town_life_v3_shard_key("different-key-writer", 99)
  let readable = town_life_transport_latest_valid_v3_saves([
    {
      key: corrupt_key,
      raw: town_life_transport_test_envelope(
        "writer-a", 3, "not-a-town-life-save",
      ),
    },
    {
      key: remote_key,
      raw: town_life_transport_test_envelope("writer-b", 1, remote_text),
    },
    {
      key: older_key,
      raw: town_life_transport_test_envelope("writer-a", 1, older_text),
    },
    {
      key: latest_key,
      raw: town_life_transport_test_envelope("writer-a", 2, latest_text),
    },
    {
      key: mismatched_key,
      raw: town_life_transport_test_envelope("writer-a", 99, mismatched_text),
    },
  ])
  assert_eq(readable.texts.length(), 3)
  assert_false(readable.texts.contains(older_text))
  assert_true(readable.texts.contains(latest_text))
  assert_true(readable.texts.contains(remote_text))
  assert_true(readable.texts.contains(mismatched_text))
  assert_true(readable.accepted_shard_keys.contains(older_key))
  assert_true(readable.accepted_shard_keys.contains(latest_key))
  assert_true(readable.accepted_shard_keys.contains(remote_key))
  assert_false(readable.accepted_shard_keys.contains(corrupt_key))
  assert_false(readable.accepted_shard_keys.contains(mismatched_key))
  let aggregate = town_life_aggregate_v3_saves(readable.texts).unwrap()
  assert_true(aggregate.analytics.contains("older-only"))
  assert_true(aggregate.analytics.contains("latest-local"))
  assert_true(aggregate.analytics.contains("remote-only"))
  assert_true(aggregate.analytics.contains("mismatched-independent"))
}

///|
test "V3 compaction cannot delete before durable write or after raw changes" {
  let new_key = town_life_v3_shard_key("writer-c", 9)
  let old_a : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-a", 3),
    raw: "captured-a",
  }
  let old_b : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-b", 4),
    raw: "captured-b",
  }
  let checkpoint : TownLifeTransportEntry = {
    key: town_life_v3_checkpoint_prefix + "migration",
    raw: "checkpoint",
  }
  let current = [
    old_a,
    { ..old_b, raw: "changed-after-capture" },
    { key: town_life_v3_shard_key("writer-d", 1), raw: "unobserved" },
  ]
  assert_true(
    town_life_transport_exact_delete_keys(
      new_key,
      false,
      [old_a, old_b, checkpoint],
      current,
    ).is_empty(),
  )
  assert_eq(
    town_life_transport_exact_delete_keys(
      new_key,
      true,
      [old_a, old_b, checkpoint],
      current,
    ),
    [old_a.key],
  )
}

///|
test "queued A plus C compaction retains B discovered after its capture" {
  let shard_a : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-a", 1),
    raw: "state-a",
  }
  let shard_b : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-b", 1),
    raw: "state-b",
  }
  // The cumulative C payload was built from captured A. B appears while the
  // writer waits for Web Locks, so B is current but deliberately unobserved.
  assert_eq(
    town_life_transport_exact_delete_keys(
      town_life_v3_shard_key("writer-c", 1),
      true,
      [shard_a],
      [shard_a, shard_b],
    ),
    [shard_a.key],
  )
}

///|
test "synchronous V3 append survives cancelled queued compaction" {
  let previous : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-old", 7),
    raw: "state-before-reset",
  }
  let reset : TownLifeTransportEntry = {
    key: town_life_v3_shard_key("writer-reset", 8),
    raw: "cumulative-state-after-reset",
  }
  // This is the state at the synchronous return/navigation boundary. The
  // asynchronous lock callback has not run and is free to be cancelled.
  let after_sync_append = [previous, reset]
  assert_true(
    town_life_transport_verified_shard_present(reset, after_sync_append),
  )
  assert_eq(
    town_life_transport_delete_keys_after_durable_append(
      reset,
      [previous],
      after_sync_append,
    ),
    [previous.key],
  )
  // If navigation cancels the callback, no deletion happens; the exact reset
  // shard nevertheless remains available for the next load.
  assert_true(
    town_life_transport_verified_shard_present(reset, after_sync_append),
  )
  assert_true(
    town_life_transport_delete_keys_after_durable_append(reset, [previous], [
      previous,
      { ..reset, raw: "torn-or-colliding-value" },
    ]).is_empty(),
  )
}

///|
test "browser V3 shard is durable before delayed Web Lock callback" {
  town_life_transport_test_install_delayed_lock("ok")
  let key = town_life_v3_shard_key("delayed-lock-writer", 1)
  let written = browser_write_town_life_v3_writer_shard("reset-save", 1)
  let raw = town_life_transport_test_delayed_lock_raw(key)
  let lock_requests = town_life_transport_test_delayed_lock_requests()
  let broadcasts = town_life_transport_test_delayed_lock_broadcasts()
  town_life_transport_test_remove_delayed_lock()
  assert_true(written)
  assert_eq(lock_requests, 1)
  assert_eq(broadcasts, 1)
  assert_true(!raw.is_empty())
  assert_eq(town_life_transport_payload(raw), "reset-save")
}

///|
test "rapid V3 commits queue one compaction with the latest manifest" {
  town_life_transport_test_install_delayed_lock("ok")
  let captured_key = town_life_v3_shard_key("captured-writer", 1)
  let first_key = town_life_v3_shard_key("delayed-lock-writer", 1)
  let latest_key = town_life_v3_shard_key("delayed-lock-writer", 2)
  let concurrent_key = town_life_v3_shard_key("concurrent-writer", 1)
  town_life_transport_test_delayed_lock_seed(
    captured_key, "captured-before-first-commit",
  )
  town_life_transport_test_delayed_lock_observe_shards()
  let first_written = browser_write_town_life_v3_writer_shard("save-one", 1)
  // A real persist rereads all durable shards before constructing the next
  // cumulative payload. Mirror that boundary so the latest queued manifest
  // includes the superseded first shard.
  town_life_transport_test_delayed_lock_observe_shards()
  let latest_written = browser_write_town_life_v3_writer_shard("save-two", 2)
  town_life_transport_test_delayed_lock_seed(
    concurrent_key, "unobserved-concurrent-shard",
  )
  let lock_requests = town_life_transport_test_delayed_lock_requests()
  let pending_callbacks = town_life_transport_test_delayed_lock_pending_callbacks()
  let broadcasts = town_life_transport_test_delayed_lock_broadcasts()
  town_life_transport_test_delayed_lock_fire()
  let captured_raw = town_life_transport_test_delayed_lock_raw(captured_key)
  let first_raw = town_life_transport_test_delayed_lock_raw(first_key)
  let latest_raw = town_life_transport_test_delayed_lock_raw(latest_key)
  let concurrent_raw = town_life_transport_test_delayed_lock_raw(concurrent_key)
  town_life_transport_test_remove_delayed_lock()
  assert_true(first_written)
  assert_true(latest_written)
  assert_eq(lock_requests, 1)
  assert_eq(pending_callbacks, 1)
  assert_eq(broadcasts, 2)
  assert_true(captured_raw.is_empty())
  assert_true(first_raw.is_empty())
  assert_eq(town_life_transport_payload(latest_raw), "save-two")
  assert_eq(concurrent_raw, "unobserved-concurrent-shard")
}

///|
test "lockless V3 exact compaction preserves concurrent replacement DAG" {
  let save_a = { ..town_life_default_save(), analytics: ["state-a"] }
  let save_b = { ..town_life_default_save(), analytics: ["state-b"] }
  let cumulative_d = town_life_reconcile_save(save_a, save_b)
  let text_a = ToJson::to_json(save_a).stringify()
  let text_b = ToJson::to_json(save_b).stringify()
  let text_d = ToJson::to_json(cumulative_d).stringify()
  let key_a = town_life_v3_shard_key("writer-a", 1)
  let key_b = town_life_v3_shard_key("writer-b", 1)
  let key_c = town_life_v3_shard_key("delayed-lock-writer", 1)
  let key_d = town_life_v3_shard_key("delayed-lock-writer", 2)
  let corrupt_key = town_life_v3_shard_key("future-writer", 1)
  town_life_transport_test_install_delayed_lock("ok")
  town_life_transport_test_disable_locks()
  town_life_transport_test_delayed_lock_seed(
    key_a,
    town_life_transport_test_envelope("writer-a", 1, text_a),
  )
  town_life_transport_test_delayed_lock_observe_shards()
  // B and the future/corrupt shard arrive after A's observation. C may replace
  // A only; the unobserved branch must survive for the next cumulative join.
  town_life_transport_test_delayed_lock_seed(
    key_b,
    town_life_transport_test_envelope("writer-b", 1, text_b),
  )
  town_life_transport_test_delayed_lock_seed(
    corrupt_key, "future-or-corrupt-envelope",
  )
  assert_true(browser_write_town_life_v3_writer_shard(text_a, 1))
  let a_after_c = town_life_transport_test_delayed_lock_raw(key_a)
  let b_after_c = town_life_transport_test_delayed_lock_raw(key_b)
  let c_after_c = town_life_transport_test_delayed_lock_raw(key_c)
  let corrupt_after_c = town_life_transport_test_delayed_lock_raw(corrupt_key)
  let observation_after_c = town_life_transport_test_delayed_lock_observation_id()

  // The next read validates B and C but excludes the corrupt/future shard from
  // the exact deletion manifest. D then replaces both valid DAG parents.
  town_life_transport_test_delayed_lock_observe_shards()
  browser_restrict_town_life_v3_observed_shards([key_b, key_c])
  assert_true(browser_write_town_life_v3_writer_shard(text_d, 2))
  let b_after_d = town_life_transport_test_delayed_lock_raw(key_b)
  let c_after_d = town_life_transport_test_delayed_lock_raw(key_c)
  let d_after_d = town_life_transport_test_delayed_lock_raw(key_d)
  let corrupt_after_d = town_life_transport_test_delayed_lock_raw(corrupt_key)
  let observation_after_d = town_life_transport_test_delayed_lock_observation_id()
  let lock_requests = town_life_transport_test_delayed_lock_requests()
  let broadcasts = town_life_transport_test_delayed_lock_broadcasts()
  let row_count = town_life_transport_test_delayed_lock_row_count()
  town_life_transport_test_remove_delayed_lock()
  assert_true(a_after_c.is_empty())
  assert_true(!b_after_c.is_empty())
  assert_true(!c_after_c.is_empty())
  assert_eq(corrupt_after_c, "future-or-corrupt-envelope")
  assert_eq(observation_after_c, 0)
  assert_true(b_after_d.is_empty())
  assert_true(c_after_d.is_empty())
  assert_eq(town_life_transport_payload(d_after_d), text_d)
  assert_eq(corrupt_after_d, "future-or-corrupt-envelope")
  assert_eq(observation_after_d, 0)
  assert_eq(lock_requests, 0)
  assert_eq(broadcasts, 2)
  assert_eq(row_count, 2)
  let decoded_d = town_life_decode_save(town_life_transport_payload(d_after_d)).unwrap()
  assert_true(decoded_d.analytics.contains("state-a"))
  assert_true(decoded_d.analytics.contains("state-b"))
}

///|
test "V3 compaction releases only its exact observed manifest" {
  town_life_transport_test_install_delayed_lock("ok")
  town_life_transport_test_delayed_lock_seed(
    town_life_v3_shard_key("captured-writer", 1),
    "captured-observation",
  )
  town_life_transport_test_delayed_lock_observe_shards()
  let captured_id = town_life_transport_test_delayed_lock_observation_id()
  ignore(browser_write_town_life_v3_writer_shard("first-save", 1))

  // A read while the Web Lock is pending replaces the global observation.
  // Completing the older job must not erase this newer manifest.
  town_life_transport_test_delayed_lock_observe_shards()
  let newer_id = town_life_transport_test_delayed_lock_observation_id()
  town_life_transport_test_delayed_lock_fire()
  let surviving_id = town_life_transport_test_delayed_lock_observation_id()

  // The next job captures that exact newer object. With no intervening read,
  // its completion must release the now-obsolete raw-payload manifest.
  ignore(browser_write_town_life_v3_writer_shard("second-save", 2))
  let exact_id = town_life_transport_test_delayed_lock_observation_id()
  town_life_transport_test_delayed_lock_fire()
  let released_id = town_life_transport_test_delayed_lock_observation_id()
  town_life_transport_test_remove_delayed_lock()
  assert_true(captured_id > 0)
  assert_true(newer_id > captured_id)
  assert_eq(surviving_id, newer_id)
  assert_eq(exact_id, newer_id)
  assert_eq(released_id, 0)
}

///|
test "quota and readback mismatch reject reset shard before effects" {
  for mode in ["quota", "mismatch"] {
    let prior_key = town_life_v3_shard_key("prior-writer", 1)
    let prior_raw = "prior-must-survive-{mode}"
    town_life_transport_test_install_delayed_lock(mode)
    town_life_transport_test_disable_locks()
    town_life_transport_test_delayed_lock_seed(prior_key, prior_raw)
    town_life_transport_test_delayed_lock_observe_shards()
    let written = browser_write_town_life_v3_writer_shard("reset-save", 1)
    let surviving = town_life_transport_test_delayed_lock_raw(prior_key)
    let observation_id = town_life_transport_test_delayed_lock_observation_id()
    let lock_requests = town_life_transport_test_delayed_lock_requests()
    let broadcasts = town_life_transport_test_delayed_lock_broadcasts()
    town_life_transport_test_remove_delayed_lock()
    assert_false(written)
    assert_eq(surviving, prior_raw)
    assert_eq(observation_id, 0)
    assert_eq(lock_requests, 0)
    assert_eq(broadcasts, 0)
  }
}

///|
test "writer lease churn removes its active owner lease on shutdown" {
  town_life_transport_test_install_writer_lease_churn()
  let mut max_lease_rows = 0
  for _ in 0..<24 {
    town_life_transport_test_writer_lease_new_lifetime()
    let writer_id = browser_town_life_v3_writer_id()
    assert_true(writer_id != "writer-unavailable")
    let active = town_life_transport_test_writer_lease_count()
    max_lease_rows = max_lease_rows.max(active)
    assert_eq(active, 1)
    town_life_transport_test_writer_lease_fire("pagehide", true)
    assert_eq(town_life_transport_test_writer_lease_count(), 1)
    town_life_transport_test_writer_lease_fire("pagehide", false)
    assert_eq(town_life_transport_test_writer_lease_count(), 0)
  }
  town_life_transport_test_remove_writer_lease_churn()
  assert_eq(max_lease_rows, 1)
}

///|
test "writer shutdown preserves contenders and a later same-key owner" {
  town_life_transport_test_install_writer_lease_churn()
  let owner_id = browser_town_life_v3_writer_id()

  // A conforming realm that observes O's still-active lease must take a
  // suffixed identity. The storage read seam runs that contender during O's
  // final ownership read, before O removes its own key.
  town_life_transport_test_writer_lease_contend_on_read(owner_id)
  town_life_transport_test_writer_lease_fire_at("pagehide", 0, false)
  let contender_id = town_life_transport_test_writer_lease_contender_id()
  let contender_saw_active = town_life_transport_test_writer_lease_contender_saw_active()
  let owner_removed = !town_life_transport_test_writer_lease_has(owner_id)
  let contender_survived = town_life_transport_test_writer_lease_has(
    contender_id,
  )
  let count_after_release = town_life_transport_test_writer_lease_count()

  // Once O has removed its key, a later realm may claim that exact identity.
  // O's subsequent unload callback must observe the new owner token and leave
  // the replacement untouched.
  town_life_transport_test_writer_lease_select_session(owner_id)
  let replacement_id = browser_town_life_v3_writer_id()
  let replacement_before = town_life_transport_test_writer_lease_raw(owner_id)
  town_life_transport_test_writer_lease_fire_at("unload", 0, false)
  let replacement_after = town_life_transport_test_writer_lease_raw(owner_id)
  let contender_after = town_life_transport_test_writer_lease_has(contender_id)
  let final_count = town_life_transport_test_writer_lease_count()
  town_life_transport_test_remove_writer_lease_churn()
  assert_true(contender_saw_active)
  assert_true(contender_id != owner_id)
  assert_true(owner_removed)
  assert_true(contender_survived)
  assert_eq(count_after_release, 1)
  assert_eq(replacement_id, owner_id)
  assert_true(!replacement_before.is_empty())
  assert_eq(replacement_after, replacement_before)
  assert_true(contender_after)
  assert_eq(final_count, 2)
}

///|
test "successful cumulative compaction bounds immutable shards and leases" {
  let captured : Array[TownLifeTransportEntry] = []
  let current : Array[TownLifeTransportEntry] = []
  let leases : Array[TownLifeTransportLease] = []
  for index in 1..<=40 {
    let writer = "closed-writer-\{index}"
    let entry : TownLifeTransportEntry = {
      key: town_life_v3_shard_key(writer, index),
      raw: "raw-\{index}",
    }
    captured.push(entry)
    current.push(entry)
    leases.push({
      key: "moontown-town-life-v3-lease:\{writer}",
      writer_id: writer,
      released: true,
      updated_at_ms: 1000.0,
    })
  }
  let new_key = town_life_v3_shard_key("current-writer", 41)
  let deleted = town_life_transport_exact_delete_keys(
    new_key, true, captured, current,
  )
  assert_eq(deleted.length(), 40)
  // The verified cumulative shard is written before these forty exact keys;
  // after deletion exactly that one authoritative shard remains.
  assert_eq(current.length() + 1 - deleted.length(), 1)
  leases.push({
    key: "moontown-town-life-v3-lease:current-writer",
    writer_id: "current-writer",
    released: false,
    updated_at_ms: 1000.0,
  })
  leases.push({
    key: "moontown-town-life-v3-lease:active-writer",
    writer_id: "active-writer",
    released: false,
    updated_at_ms: 1000.0,
  })
  let reclaimed = town_life_transport_reclaimable_lease_keys(
    2000.0,
    "current-writer",
    ["active-writer"],
    leases,
  )
  assert_eq(reclaimed.length(), 40)
  assert_eq(leases.length() - reclaimed.length(), 2)
}

///|
test "abandoned lease is reclaimed only without a live immutable shard" {
  let week_ms = 7.0 * 24.0 * 60.0 * 60.0 * 1000.0
  let stale : TownLifeTransportLease = {
    key: "moontown-town-life-v3-lease:stale",
    writer_id: "stale",
    released: false,
    updated_at_ms: 1.0,
  }
  assert_true(
    town_life_transport_reclaimable_lease_keys(week_ms + 2.0, "current", [], [
      stale,
    ]).contains(stale.key),
  )
  assert_true(
    town_life_transport_reclaimable_lease_keys(
      week_ms + 2.0,
      "current",
      ["stale"],
      [stale],
    ).is_empty(),
  )
}
