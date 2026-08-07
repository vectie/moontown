///|
/// Browser-only metadata around one serialized `TownLifeSave`. Domain merge
/// semantics stay in `town_life_persistence.mbt`; V3 transport shards are
/// immutable facts identified by `(writer_id, sequence)`.
priv struct TownLifeTransportEnvelope {
  transport_version : Int
  writer_id : String
  sequence : Int
  written_at_ms : Double
  payload : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// `localStorage` enumeration order is unspecified, so the JS boundary emits
/// encoded key/value entries and MoonBit sorts them before reconciliation.
priv struct TownLifeTransportEntry {
  key : String
  raw : String
} derive(Debug, Eq, ToJson, FromJson)

///|
priv struct TownLifeTransportWriterStamp {
  writer_id : String
  sequence : Int
} derive(Debug, Eq, FromJson)

///|
/// Testable projection of the mutable coordination lease. Leases contain no
/// domain state and may be removed only after their writer has no live shard.
priv struct TownLifeTransportLease {
  key : String
  writer_id : String
  released : Bool
  updated_at_ms : Double
} derive(Debug, Eq)

///|
let town_life_transport_version = 3

///|
let town_life_v3_checkpoint_prefix = "moontown-town-life-v3-checkpoint:"

///|
let town_life_v3_shard_prefix = "moontown-town-life-v3-shard:"

///|
fn town_life_transport_decode_entry(text : String) -> TownLifeTransportEntry? {
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
fn town_life_transport_decode_envelope(
  raw : String,
) -> TownLifeTransportEnvelope? {
  let parsed = @json.parse(raw) catch { _ => return None }
  let envelope : TownLifeTransportEnvelope = @json.from_json(parsed) catch {
    _ => return None
  }
  if envelope.transport_version != town_life_transport_version ||
    envelope.writer_id.is_empty() ||
    envelope.sequence < 1 ||
    envelope.payload.is_empty() {
    None
  } else {
    Some(envelope)
  }
}

///|
/// Migration checkpoints contain a save directly. V3 writer shards wrap the
/// save in a transport envelope. Unknown/legacy values remain raw so the
/// normal TownLife decoder can accept or reject them.
fn town_life_transport_payload(raw : String) -> String {
  match town_life_transport_decode_envelope(raw) {
    Some(envelope) => envelope.payload
    None => raw
  }
}

///|
fn town_life_transport_save_texts(
  encoded_entries : ArrayView[String],
) -> Array[String] {
  let entries : Array[TownLifeTransportEntry] = []
  for encoded in encoded_entries {
    match town_life_transport_decode_entry(encoded) {
      Some(entry) if !entry.raw.is_empty() => entries.push(entry)
      _ => ()
    }
  }
  entries.sort_by((left, right) => left.key.compare(right.key))
  entries.map(entry => town_life_transport_payload(entry.raw))
}

///|
/// Pure key derivation mirrors the browser transport and is kept testable.
fn town_life_v3_shard_key(writer_id : String, sequence : Int) -> String {
  let sequence_text = sequence.max(1).to_string()
  let padding = String::make(16 - sequence_text.length().min(16), '0')
  "\{town_life_v3_shard_prefix}\{writer_id}:\{padding}\{sequence_text}"
}

///|
/// Pure mirror of the destructive half of browser compaction. No captured key
/// is removable before the new cumulative shard is verified, and a changed or
/// unobserved immutable shard never appears in the result.
fn town_life_transport_exact_delete_keys(
  new_shard_key : String,
  new_shard_verified : Bool,
  captured : ArrayView[TownLifeTransportEntry],
  current : ArrayView[TownLifeTransportEntry],
) -> Array[String] {
  if !new_shard_verified {
    return []
  }
  let keys : Array[String] = []
  for candidate in captured {
    if candidate.key == new_shard_key ||
      !candidate.key.starts_with(town_life_v3_shard_prefix) {
      continue
    }
    if current.any(entry => {
        entry.key == candidate.key && entry.raw == candidate.raw
      }) &&
      !keys.contains(candidate.key) {
      keys.push(candidate.key)
    }
  }
  keys.sort_by((left, right) => left.compare(right))
  keys
}

///|
/// Pure mirror of the transport's phase boundary: asynchronous compaction is
/// eligible only after the exact immutable shard is already present. Keeping
/// this check separate makes the navigation/cancel safety invariant testable.
fn town_life_transport_verified_shard_present(
  shard : TownLifeTransportEntry,
  current : ArrayView[TownLifeTransportEntry],
) -> Bool {
  current.any(entry => entry.key == shard.key && entry.raw == shard.raw)
}

///|
fn town_life_transport_delete_keys_after_durable_append(
  new_shard : TownLifeTransportEntry,
  captured : ArrayView[TownLifeTransportEntry],
  current : ArrayView[TownLifeTransportEntry],
) -> Array[String] {
  town_life_transport_exact_delete_keys(
    new_shard.key,
    town_life_transport_verified_shard_present(new_shard, current),
    captured,
    current,
  )
}

///|
fn town_life_transport_reclaimable_lease_keys(
  now_ms : Double,
  own_writer_id : String,
  active_writer_ids : ArrayView[String],
  leases : ArrayView[TownLifeTransportLease],
) -> Array[String] {
  let abandoned_after_ms = 7.0 * 24.0 * 60.0 * 60.0 * 1000.0
  let keys : Array[String] = []
  for lease in leases {
    if lease.writer_id != own_writer_id &&
      !active_writer_ids.contains(lease.writer_id) &&
      (lease.released || now_ms - lease.updated_at_ms >= abandoned_after_ms) &&
      !keys.contains(lease.key) {
      keys.push(lease.key)
    }
  }
  keys.sort_by((left, right) => left.compare(right))
  keys
}

///|
/// V1 is migration input only. V3's permanent fence prevents this source from
/// being consulted again after the one-time import.
extern "js" fn browser_town_life_v1_migration_save_text() -> String =
  #| () => {
  #|   try {
  #|     return globalThis.localStorage?.getItem("moontown-town-life-v1") ?? "";
  #|   } catch (_) {
  #|     return "";
  #|   }
  #| }

///|
/// V2 is also migration input only. This reader deliberately has no runtime
/// subscription: old deployed V2 writers are ignored once the V3 fence lands.
extern "js" fn browser_town_life_v2_migration_raw_entries() -> Array[String] =
  #| () => {
  #|   const checkpointKey = "moontown-town-life-v2";
  #|   const writerPrefix = "moontown-town-life-v2-writer:";
  #|   const entries = [];
  #|   try {
  #|     const storage = globalThis.localStorage;
  #|     if (!storage) return entries;
  #|     const checkpoint = storage.getItem(checkpointKey) ?? "";
  #|     if (checkpoint) {
  #|       entries.push(JSON.stringify({ key: checkpointKey, raw: checkpoint }));
  #|     }
  #|     const writers = [];
  #|     for (let index = 0; index < storage.length; index += 1) {
  #|       const key = storage.key(index) ?? "";
  #|       if (!key.startsWith(writerPrefix)) continue;
  #|       const raw = storage.getItem(key) ?? "";
  #|       if (raw) writers.push({ key, raw });
  #|     }
  #|     writers.sort((left, right) => left.key.localeCompare(right.key));
  #|     for (const entry of writers) entries.push(JSON.stringify(entry));
  #|   } catch (_) {}
  #|   return entries;
  #| }

///|
fn browser_town_life_v2_migration_save_texts() -> Array[String] {
  town_life_transport_save_texts(browser_town_life_v2_migration_raw_entries())
}

///|
extern "js" fn browser_town_life_v3_migration_fenced() -> Bool =
  #| () => {
  #|   try {
  #|     return globalThis.localStorage?.getItem(
  #|       "moontown-town-life-v3-migrated",
  #|     ) === "1";
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| }

///|
/// A migration checkpoint is itself immutable. Concurrent first-open tabs use
/// distinct checkpoint keys, so neither can overwrite the other's cutoff
/// state; normal reconciliation safely joins both.
extern "js" fn browser_install_town_life_v3_migration_checkpoint(
  text : String,
) -> Unit =
  #| (text) => {
  #|   try {
  #|     const storage = globalThis.localStorage;
  #|     if (!storage || !text) return;
  #|     if (storage.getItem("moontown-town-life-v3-migrated") === "1") return;
  #|     const random = globalThis.crypto?.randomUUID?.() ??
  #|       `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  #|     const key = `moontown-town-life-v3-checkpoint:${random}`;
  #|     storage.setItem(key, text);
  #|     if (storage.getItem(key) === text) {
  #|       storage.setItem("moontown-town-life-v3-migrated", "1");
  #|     }
  #|   } catch (_) {}
  #| }

///|
extern "js" fn browser_fence_town_life_v3_migration() -> Unit =
  #| () => {
  #|   try {
  #|     globalThis.localStorage?.setItem("moontown-town-life-v3-migrated", "1");
  #|   } catch (_) {}
  #| }

///|
/// List V3 checkpoints and immutable shards. The exact raw shard set is kept
/// as a short-lived observed manifest for the next cumulative write. A
/// compactor can delete only byte-identical keys from that captured set.
extern "js" fn browser_town_life_v3_raw_entries() -> Array[String] =
  #| () => {
  #|   const checkpointPrefix = "moontown-town-life-v3-checkpoint:";
  #|   const shardPrefix = "moontown-town-life-v3-shard:";
  #|   const entries = [];
  #|   const observedShards = [];
  #|   try {
  #|     const storage = globalThis.localStorage;
  #|     if (!storage) return entries;
  #|     const found = [];
  #|     for (let index = 0; index < storage.length; index += 1) {
  #|       const key = storage.key(index) ?? "";
  #|       if (!key.startsWith(checkpointPrefix) &&
  #|           !key.startsWith(shardPrefix)) continue;
  #|       const raw = storage.getItem(key) ?? "";
  #|       if (raw) found.push({ key, raw });
  #|     }
  #|     found.sort((left, right) => left.key.localeCompare(right.key));
  #|     for (const entry of found) {
  #|       entries.push(JSON.stringify(entry));
  #|       if (entry.key.startsWith(shardPrefix)) observedShards.push(entry);
  #|     }
  #|     globalThis.__moontownTownLifeV3Observed = {
  #|       capturedAtMs: Date.now(),
  #|       entries: observedShards,
  #|     };
  #|   } catch (_) {}
  #|   return entries;
  #| }

///|
extern "js" fn browser_restrict_town_life_v3_observed_shards(
  accepted_keys : Array[String],
) -> Unit =
  #| (acceptedKeys) => {
  #|   const observed = globalThis.__moontownTownLifeV3Observed;
  #|   if (!observed) return;
  #|   const accepted = new Set(acceptedKeys);
  #|   observed.entries = observed.entries.filter(entry => accepted.has(entry.key));
  #| }

///|
/// A syntactically valid transport envelope is not automatically safe to
/// compact: its domain payload must decode too. Only successfully decoded V3
/// shards remain in the exact-observation deletion manifest; corrupt or future
/// payloads stay on disk for recovery.
fn browser_town_life_v3_save_texts() -> Array[String] {
  let entries : Array[TownLifeTransportEntry] = []
  for encoded in browser_town_life_v3_raw_entries() {
    match town_life_transport_decode_entry(encoded) {
      Some(entry) if !entry.raw.is_empty() => entries.push(entry)
      _ => ()
    }
  }
  entries.sort_by((left, right) => left.key.compare(right.key))
  let texts : Array[String] = []
  let accepted_shard_keys : Array[String] = []
  for entry in entries {
    let payload = town_life_transport_payload(entry.raw)
    match town_life_decode_save(payload) {
      Some(_) => {
        texts.push(payload)
        if entry.key.starts_with(town_life_v3_shard_prefix) &&
          town_life_transport_decode_envelope(entry.raw) is Some(_) {
          accepted_shard_keys.push(entry.key)
        }
      }
      None => ()
    }
  }
  browser_restrict_town_life_v3_observed_shards(accepted_shard_keys)
  texts
}

///|
/// Returns one sessionStorage-stable writer identity and an independently
/// monotonic shard sequence. The sequence is recovered from immutable V3 keys
/// as well as sessionStorage, so a reload never reuses an existing dot.
extern "js" fn browser_town_life_v3_writer_stamp_json(
  reserve_sequence : Bool,
) -> String =
  #| (reserveSequence) => {
  #|   const shardPrefix = "moontown-town-life-v3-shard:";
  #|   const leasePrefix = "moontown-town-life-v3-lease:";
  #|   const idKey = "moontown-town-life-v3-writer-id";
  #|   const sequenceKey = "moontown-town-life-v3-writer-sequence";
  #|   const randomId = () =>
  #|     globalThis.crypto?.randomUUID?.() ??
  #|       `${Date.now().toString(36)}-${Math.random().toString(36).slice(2)}`;
  #|   const session = (() => {
  #|     try { return globalThis.sessionStorage; } catch (_) { return null; }
  #|   })();
  #|   const storage = (() => {
  #|     try { return globalThis.localStorage; } catch (_) { return null; }
  #|   })();
  #|   let state = globalThis.__moontownTownLifeV3WriterState;
  #|   if (!state) {
  #|     let writerId = "";
  #|     try { writerId = session?.getItem(idKey) ?? ""; } catch (_) {}
  #|     if (!/^[A-Za-z0-9._-]{8,160}$/.test(writerId)) writerId = randomId();
  #|     const ownerToken = randomId();
  #|     const readLease = id => {
  #|       try { return JSON.parse(storage?.getItem(`${leasePrefix}${id}`) || "null"); }
  #|       catch (_) { return null; }
  #|     };
  #|     const existingLease = readLease(writerId);
  #|     let leaseSequence = Math.max(0, Number(existingLease?.last_sequence) || 0);
  #|     if (existingLease && existingLease.released !== true &&
  #|         existingLease.owner_token !== ownerToken) {
  #|       writerId = `${writerId}-${randomId().slice(0, 12)}`;
  #|       leaseSequence = 0;
  #|     }
  #|     let sequence = 0;
  #|     try {
  #|       sequence = Math.max(
  #|         0,
  #|         Number.parseInt(session?.getItem(sequenceKey) ?? "0", 10) || 0,
  #|         leaseSequence,
  #|       );
  #|       const ownPrefix = `${shardPrefix}${writerId}:`;
  #|       for (let index = 0; index < (storage?.length ?? 0); index += 1) {
  #|         const key = storage.key(index) ?? "";
  #|         if (!key.startsWith(ownPrefix)) continue;
  #|         const candidate = Number.parseInt(key.slice(ownPrefix.length), 10);
  #|         if (Number.isSafeInteger(candidate)) sequence = Math.max(sequence, candidate);
  #|       }
  #|     } catch (_) {}
  #|     state = { writerId, ownerToken, sequence };
  #|     globalThis.__moontownTownLifeV3WriterState = state;
  #|     try {
  #|       session?.setItem(idKey, writerId);
  #|       session?.setItem(sequenceKey, String(sequence));
  #|       storage?.setItem(`${leasePrefix}${writerId}`, JSON.stringify({
  #|         owner_token: ownerToken,
  #|         released: false,
  #|         updated_at_ms: Date.now(),
  #|         last_sequence: sequence,
  #|       }));
  #|     } catch (_) {}
  #|     if (typeof globalThis.addEventListener === "function") {
  #|       state.heartbeat = globalThis.setInterval(() => {
  #|         try {
  #|           const key = `${leasePrefix}${state.writerId}`;
  #|           const lease = JSON.parse(storage?.getItem(key) || "null");
  #|           if (lease?.owner_token !== state.ownerToken) return;
  #|           storage.setItem(key, JSON.stringify({
  #|             owner_token: state.ownerToken,
  #|             released: false,
  #|             updated_at_ms: Date.now(),
  #|             last_sequence: state.sequence,
  #|           }));
  #|         } catch (_) {}
  #|       }, 30000);
  #|       globalThis.addEventListener("pagehide", event => {
  #|         if (event.persisted) return;
  #|         globalThis.clearInterval(state.heartbeat);
  #|         try {
  #|           const key = `${leasePrefix}${state.writerId}`;
  #|           const lease = JSON.parse(storage?.getItem(key) || "null");
  #|           if (lease?.owner_token !== state.ownerToken) return;
  #|           storage.setItem(key, JSON.stringify({
  #|             owner_token: state.ownerToken,
  #|             released: true,
  #|             updated_at_ms: Date.now(),
  #|             last_sequence: state.sequence,
  #|           }));
  #|         } catch (_) {}
  #|       });
  #|     }
  #|   }
  #|   if (reserveSequence) {
  #|     state.sequence += 1;
  #|     try {
  #|       session?.setItem(sequenceKey, String(state.sequence));
  #|       const key = `${leasePrefix}${state.writerId}`;
  #|       const lease = JSON.parse(storage?.getItem(key) || "null");
  #|       if (lease?.owner_token === state.ownerToken) {
  #|         storage.setItem(key, JSON.stringify({
  #|           owner_token: state.ownerToken,
  #|           released: false,
  #|           updated_at_ms: Date.now(),
  #|           last_sequence: state.sequence,
  #|         }));
  #|       }
  #|     } catch (_) {}
  #|   }
  #|   return JSON.stringify({
  #|     writer_id: state.writerId,
  #|     sequence: state.sequence,
  #|   });
  #| }

///|
fn town_life_transport_writer_stamp(
  reserve_sequence : Bool,
) -> TownLifeTransportWriterStamp {
  let text = browser_town_life_v3_writer_stamp_json(reserve_sequence)
  let parsed = @json.parse(text) catch {
    _ => return { writer_id: "writer-unavailable", sequence: 0 }
  }
  @json.from_json(parsed) catch {
    _ => { writer_id: "writer-unavailable", sequence: 0 }
  }
}

///|
fn browser_town_life_v3_writer_id() -> String {
  town_life_transport_writer_stamp(false).writer_id
}

///|
fn browser_town_life_v3_next_writer_sequence() -> Int {
  town_life_transport_writer_stamp(true).sequence
}

///|
/// Installs and byte-for-byte verifies a new immutable cumulative shard
/// synchronously, before any broadcast or asynchronous Web-Lock work is
/// scheduled. Navigation may then cancel compaction without losing the new
/// state. Under Web Locks, exact captured older shard keys are removed. A
/// concurrent writer creates an unobserved key and is therefore retained.
/// Without Web Locks, on quota/write failure, or with a stale observation
/// manifest, deletion is disabled.
extern "js" fn browser_write_town_life_v3_writer_shard(
  text : String,
  sequence : Int,
) -> Bool =
  #| (text, sequence) => {
  #|   const shardPrefix = "moontown-town-life-v3-shard:";
  #|   const leasePrefix = "moontown-town-life-v3-lease:";
  #|   const lockName = "moontown-town-life-v3-compaction";
  #|   const abandonedLeaseMs = 7 * 24 * 60 * 60 * 1000;
  #|   const state = globalThis.__moontownTownLifeV3WriterState;
  #|   const storage = (() => {
  #|     try { return globalThis.localStorage; } catch (_) { return null; }
  #|   })();
  #|   if (!state || !storage || !text) return false;
  #|   const targetSequence = Math.max(1, Number(sequence) || 0);
  #|   const sequenceText = String(targetSequence).padStart(16, "0");
  #|   const key = `${shardPrefix}${state.writerId}:${sequenceText}`;
  #|   const raw = JSON.stringify({
  #|     transport_version: 3,
  #|     writer_id: state.writerId,
  #|     sequence: targetSequence,
  #|     written_at_ms: Date.now(),
  #|     payload: text,
  #|   });
  #|   // Freeze the manifest synchronously beside the cumulative payload.
  #|   // A later storage/focus read may replace the global observation while
  #|   // this writer is queued for the asynchronous Web Lock.
  #|   const observedState = globalThis.__moontownTownLifeV3Observed;
  #|   const observationFresh = observedState &&
  #|     Date.now() - Number(observedState.capturedAtMs) <= 5000;
  #|   const capturedEntries = observationFresh
  #|     ? observedState.entries.map(entry => ({ key: entry.key, raw: entry.raw }))
  #|     : [];
  #|   const writeAndVerify = () => {
  #|     try {
  #|       const existing = storage.getItem(key);
  #|       if (existing === null) storage.setItem(key, raw);
  #|       if (storage.getItem(key) !== raw) return false;
  #|       return true;
  #|     } catch (_) {
  #|       return false;
  #|     }
  #|   };
  #|   const broadcastDurableShard = () => {
  #|     try {
  #|       globalThis.__moontownTownLifeV3Channel ||=
  #|         typeof globalThis.BroadcastChannel === "function"
  #|           ? new BroadcastChannel("moontown-town-life-v3") : null;
  #|       globalThis.__moontownTownLifeV3Channel?.postMessage({
  #|         ownerToken: state.ownerToken,
  #|         sequence: targetSequence,
  #|       });
  #|     } catch (_) {}
  #|   };
  #|   // This append is intentionally synchronous. Reset/demolition callers
  #|   // may navigate immediately after this function returns, so the queued
  #|   // lock is allowed to disappear but the cumulative shard is not.
  #|   if (!writeAndVerify()) return false;
  #|   broadcastDurableShard();
  #|   const locks = globalThis.navigator?.locks;
  #|   if (typeof locks?.request !== "function") return true;
  #|   void locks.request(lockName, { mode: "exclusive" }, () => {
  #|     const captured = new Map(
  #|       capturedEntries.map(entry => [entry.key, entry.raw]),
  #|     );
  #|     if (storage.getItem(key) !== raw || !observationFresh) return;
  #|     for (const [candidateKey, expectedRaw] of captured) {
  #|       if (candidateKey === key || !candidateKey.startsWith(shardPrefix)) continue;
  #|       if (storage.getItem(candidateKey) === expectedRaw) {
  #|         storage.removeItem(candidateKey);
  #|       }
  #|     }
  #|     const activeWriters = new Set();
  #|     const leaseEntries = [];
  #|     for (let index = 0; index < storage.length; index += 1) {
  #|       const candidateKey = storage.key(index) ?? "";
  #|       if (candidateKey.startsWith(shardPrefix)) {
  #|         try {
  #|           const value = JSON.parse(storage.getItem(candidateKey) || "null");
  #|           if (value?.transport_version === 3 && value.writer_id) {
  #|             activeWriters.add(value.writer_id);
  #|           }
  #|         } catch (_) {}
  #|       } else if (candidateKey.startsWith(leasePrefix)) {
  #|         leaseEntries.push(candidateKey);
  #|       }
  #|     }
  #|     const now = Date.now();
  #|     for (const leaseKey of leaseEntries) {
  #|       const writerId = leaseKey.slice(leasePrefix.length);
  #|       if (writerId === state.writerId || activeWriters.has(writerId)) continue;
  #|       try {
  #|         const lease = JSON.parse(storage.getItem(leaseKey) || "null");
  #|         const abandoned = now - Number(lease?.updated_at_ms || 0) >=
  #|           abandonedLeaseMs;
  #|         if (lease?.released === true || abandoned) storage.removeItem(leaseKey);
  #|       } catch (_) {}
  #|     }
  #|   }).catch(() => {});
  #|   return true;
  #| }

///|
/// Storage events are the primary cross-tab signal. BroadcastChannel closes
/// browser-specific gaps, while a five-second content hash catches a missed
/// event after suspension. Every source debounces into one TEA callback.
extern "js" fn browser_install_town_life_v3_storage_subscription(
  callback : () -> Unit,
) -> Unit =
  #| (callback) => {
  #|   if (typeof globalThis.addEventListener !== "function") return;
  #|   const checkpointPrefix = "moontown-town-life-v3-checkpoint:";
  #|   const shardPrefix = "moontown-town-life-v3-shard:";
  #|   const relevant = key =>
  #|     (key ?? "").startsWith(checkpointPrefix) ||
  #|       (key ?? "").startsWith(shardPrefix);
  #|   const hash = raw => {
  #|     let value = 2166136261;
  #|     for (let offset = 0; offset < raw.length; offset += 1) {
  #|       value ^= raw.charCodeAt(offset);
  #|       value = Math.imul(value, 16777619);
  #|     }
  #|     return value >>> 0;
  #|   };
  #|   const signature = () => {
  #|     try {
  #|       const storage = globalThis.localStorage;
  #|       if (!storage) return "";
  #|       const parts = [];
  #|       for (let index = 0; index < storage.length; index += 1) {
  #|         const key = storage.key(index) ?? "";
  #|         if (!relevant(key)) continue;
  #|         const raw = storage.getItem(key) ?? "";
  #|         parts.push(`${key}:${raw.length}:${hash(raw)}`);
  #|       }
  #|       return parts.sort().join("|");
  #|     } catch (_) {
  #|       return "";
  #|     }
  #|   };
  #|   let bridge = globalThis.__moontownTownLifeV3StorageBridge;
  #|   if (bridge) {
  #|     bridge.callback = callback;
  #|     if (typeof bridge.notify === "function") bridge.notify();
  #|     else globalThis.setTimeout(callback, 60);
  #|     return;
  #|   }
  #|   bridge = {
  #|     callback,
  #|     timer: 0,
  #|     lastSignature: signature(),
  #|   };
  #|   globalThis.__moontownTownLifeV3StorageBridge = bridge;
  #|   const notify = () => {
  #|     globalThis.clearTimeout(bridge.timer);
  #|     bridge.timer = globalThis.setTimeout(() => {
  #|       bridge.lastSignature = signature();
  #|       try { bridge.callback(); } catch (_) {}
  #|     }, 60);
  #|   };
  #|   bridge.notify = notify;
  #|   const onStorage = event => {
  #|     if (relevant(event.key)) notify();
  #|   };
  #|   const onFocus = () => {
  #|     const next = signature();
  #|     if (next !== bridge.lastSignature) notify();
  #|   };
  #|   const onVisibilityChange = () => {
  #|     if (globalThis.document?.visibilityState === "visible") {
  #|       const next = signature();
  #|       if (next !== bridge.lastSignature) notify();
  #|     }
  #|   };
  #|   const onUnload = () => {
  #|     globalThis.clearTimeout(bridge.timer);
  #|     globalThis.clearInterval(bridge.poll);
  #|     globalThis.removeEventListener("storage", onStorage);
  #|     globalThis.removeEventListener("pageshow", notify);
  #|     globalThis.removeEventListener("focus", onFocus);
  #|     globalThis.removeEventListener("unload", onUnload);
  #|     globalThis.document?.removeEventListener(
  #|       "visibilitychange",
  #|       onVisibilityChange,
  #|     );
  #|     try { bridge.channel?.close(); } catch (_) {}
  #|     if (globalThis.__moontownTownLifeV3StorageBridge === bridge) {
  #|       delete globalThis.__moontownTownLifeV3StorageBridge;
  #|     }
  #|   };
  #|   globalThis.addEventListener("storage", onStorage);
  #|   globalThis.addEventListener("pageshow", notify);
  #|   globalThis.addEventListener("focus", onFocus);
  #|   globalThis.addEventListener("unload", onUnload);
  #|   globalThis.document?.addEventListener(
  #|     "visibilitychange",
  #|     onVisibilityChange,
  #|   );
  #|   try {
  #|     const channel = typeof globalThis.BroadcastChannel === "function"
  #|       ? new BroadcastChannel("moontown-town-life-v3") : null;
  #|     bridge.channel = channel;
  #|     channel?.addEventListener("message", event => {
  #|       const own = globalThis.__moontownTownLifeV3WriterState?.ownerToken;
  #|       if (event.data?.ownerToken !== own) notify();
  #|     });
  #|   } catch (_) {}
  #|   bridge.poll = globalThis.setInterval(() => {
  #|     const next = signature();
  #|     if (next !== bridge.lastSignature) notify();
  #|   }, 5000);
  #|   // Reconcile once after mount. The delay avoids enqueueing against the
  #|   // Rabbita scheduler while its initialization flush is still active.
  #|   notify();
  #| }

///|
/// Convert an external browser callback into a command queued by Rabbita.
/// `Dispatch` creates a deferred command; merely calling and discarding it does
/// not deliver the message to the TEA inbox.
fn town_life_storage_enqueued_callback(
  command : () -> Cmd,
  enqueue : (Cmd) -> Unit,
) -> () -> Unit {
  fn() { enqueue(command()) }
}

///|
/// Browser notifications never mutate the model directly. They enter through
/// the same Rabbita scheduler and dispatch as every other UI event, preserving
/// TEA ordering across storage, BroadcastChannel, focus, and polling signals.
fn install_town_life_storage_bridge(dispatch : Dispatch[Msg]) -> Cmd {
  @cmd.custom_cmd(scheduler => {
    browser_install_town_life_v3_storage_subscription(
      town_life_storage_enqueued_callback(
        fn() { dispatch(TownLifeStorageChanged) },
        fn(command) { scheduler.add(command) },
      ),
    )
  })
}

///|
/// Join durable V3 state with the current tab before projection. This is
/// intentionally read-only: a storage notification never echoes another
/// writer's event back into localStorage.
fn town_life_storage_changed_update(model : Model) -> (Cmd, Model) {
  match town_life_aggregate_v3_saves(browser_town_life_v3_save_texts()) {
    None => model_only_update(model)
    Some(disk) => {
      let joined = town_life_reconcile_save(
        disk,
        town_life_save_for_model(model),
      )
      model_only_update(town_life_model_with_save(model, joined))
    }
  }
}
