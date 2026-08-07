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
  #|   ];
  #|   const saved = new Map(
  #|     names.map(name => [name, Object.getOwnPropertyDescriptor(globalThis, name)]),
  #|   );
  #|   const harness = {
  #|     saved,
  #|     rows: new Map(),
  #|     lockRequests: 0,
  #|     broadcasts: 0,
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
  #|       request() {
  #|         harness.lockRequests += 1;
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
test "quota and readback mismatch reject reset shard before effects" {
  for mode in ["quota", "mismatch"] {
    town_life_transport_test_install_delayed_lock(mode)
    let written = browser_write_town_life_v3_writer_shard("reset-save", 1)
    let lock_requests = town_life_transport_test_delayed_lock_requests()
    let broadcasts = town_life_transport_test_delayed_lock_broadcasts()
    town_life_transport_test_remove_delayed_lock()
    assert_false(written)
    assert_eq(lock_requests, 0)
    assert_eq(broadcasts, 0)
  }
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
