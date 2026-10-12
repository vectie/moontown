import { createHash } from "node:crypto";

const hash = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
const MAX_BYTES = 4 * 1024 * 1024;
const failure = (status, reason) => ({ status, body: { ok: false, kind: "run-inbox", reason } });
const visible = (building, user) => building.visibility !== "archived" &&
  (building.visibility === "published" || [user, "org-a", "system"].includes(building.ownerId));
const compareText = (a, b) => a < b ? -1 : a > b ? 1 : 0;
const pick = (record, fields) => Object.fromEntries(fields.filter(key => Object.hasOwn(record, key)).map(key => [key, record[key]]));
const runFields = ["id", "userId", "buildingId", "bookId", "agentId", "threadId", "status", "summary", "createdAtMs", "updatedAtMs", "version"];
const buildingFields = ["id", "title", "visibility", "version"];
const threadFields = ["id", "buildingId", "title", "version"];
const integer = (params, name, fallback) => {
  const raw = params.get(name);
  return raw === null ? fallback : /^(0|[1-9][0-9]*)$/.test(raw) && Number.isSafeInteger(Number(raw)) ? Number(raw) : NaN;
};
const validTime = (value) => Number.isSafeInteger(value) && value >= 0;
const qualification = "Retained local development-service records only. Age is time since the recorded update, not time in status, a live heartbeat or execution proof. Viewing never accepts knowledge, retries or cancels work. Render source strings as plain text.";

function indexState(state, keys) {
  const result = {};
  for (const key of keys) {
    if (!Array.isArray(state[key]) || state[key].length > 20000) throw { status: 413, reason: "inbox-state-scan-limit" };
    const records = new Map();
    for (const row of state[key]) {
      if (!row || typeof row.id !== "string" || !row.id || records.has(row.id)) throw { status: 409, reason: "ambiguous-state-records" };
      records.set(row.id, row);
    }
    result[key] = records;
  }
  return result;
}

function selectedSource(run, building, threads) {
  const thread = threads.get(run.threadId);
  if (thread && thread.buildingId !== building.id) throw { status: 409, reason: "inconsistent-conversation-links" };
  if (typeof run.status !== "string" || !run.status) throw { status: 409, reason: "invalid-run-status" };
  return {
    building: pick(building, buildingFields),
    run: pick(run, runFields),
    thread: thread ? pick(thread, threadFields) : null,
  };
}

function ageOf(run, asOfMs) {
  if (!validTime(run.updatedAtMs)) return { ageMs: null, timestampState: "unknown" };
  if (run.updatedAtMs > asOfMs) return { ageMs: null, timestampState: "after-as-of" };
  return { ageMs: asOfMs - run.updatedAtMs, timestampState: "known" };
}

function response(body) {
  if (Buffer.byteLength(JSON.stringify(body)) > MAX_BYTES) return failure(413, "inbox-output-byte-limit");
  return { status: 200, body, headers: { "cache-control": "no-store" } };
}

// Read-only triage over retained runs. The snapshot embeds the same first page.
export function runInbox(state, userId, params = new URLSearchParams(), nowMs = Date.now()) {
  const status = params.get("status") || "attention";
  const owner = params.get("owner") || "all";
  const buildingId = params.get("buildingId");
  const asOfMs = integer(params, "asOfMs", nowMs);
  const minAgeMs = integer(params, "minAgeMs", null);
  const offset = integer(params, "offset", 0), limit = integer(params, "limit", 50);
  if (!["attention", "waiting_review", "failed", "pending", "running", "done", "cancelled", "all"].includes(status) ||
      !["all", "mine"].includes(owner) || !validTime(asOfMs) ||
      (minAgeMs !== null && !validTime(minAgeMs)) || !validTime(offset) || !validTime(limit) || limit < 1 || limit > 100) {
    return failure(400, "invalid-inbox-options");
  }
  if (offset > 0 && (!params.has("expectedDigest") || !params.has("asOfMs"))) return failure(400, "page-source-digest-and-as-of-required");
  try {
    const indexes = indexState(state, ["buildings", "threads", "runs"]);
    const buildings = state.buildings.filter(item => visible(item, userId) && (buildingId === null || item.id === buildingId));
    if (buildingId !== null && !buildings.length) return failure(404, "building-not-visible");
    const buildingMap = new Map(buildings.map(item => [item.id, item]));
    const sources = state.runs.filter(run => buildingMap.has(run.buildingId) && (owner === "all" || run.userId === userId))
      .map(run => selectedSource(run, buildingMap.get(run.buildingId), indexes.threads));
    // Retained array order is not a triage priority or a source identity.
    sources.sort((a, b) => compareText(a.run.id, b.run.id));
    const filters = { status, owner, buildingId, asOfMs, minAgeMs };
    const source = { userId, filters, sources };
    if (Buffer.byteLength(JSON.stringify(source)) > MAX_BYTES) return failure(413, "inbox-source-byte-limit");
    const sourceDigest = hash(source);
    if (params.has("expectedDigest") && params.get("expectedDigest") !== sourceDigest) return failure(409, "inbox-source-changed");
    const candidates = sources.map(source => ({ ...source, ...ageOf(source.run, asOfMs) }));
    const matches = candidates.filter(item =>
      (status === "all" || (status === "attention" ? ["waiting_review", "failed"].includes(item.run.status) : item.run.status === status)) &&
      (minAgeMs === null || (item.ageMs !== null && item.ageMs >= minAgeMs)));
    matches.sort((a, b) => (a.ageMs === null) - (b.ageMs === null) ||
      (a.ageMs !== null && b.ageMs !== null ? b.ageMs - a.ageMs : 0) || compareText(a.run.id, b.run.id));
    const counts = new Map(), groups = new Map();
    for (const item of candidates) counts.set(item.run.status, (counts.get(item.run.status) || 0) + 1);
    for (const item of matches) {
      if (!groups.has(item.building.id)) groups.set(item.building.id, { buildingId: item.building.id, buildingTitle: item.building.title,
        count: 0, oldestAgeMs: null, unknownTimestampCount: 0, afterAsOfCount: 0 });
      const group = groups.get(item.building.id); group.count++;
      if (item.ageMs !== null) group.oldestAgeMs = Math.max(group.oldestAgeMs ?? 0, item.ageMs);
      if (item.timestampState === "unknown") group.unknownTimestampCount++;
      if (item.timestampState === "after-as-of") group.afterAsOfCount++;
    }
    const results = matches.slice(offset, offset + limit).map(({ building, run, thread, ageMs, timestampState }) => {
      const runDigest = hash({ building, run, thread });
      return { run, building, thread, ageMs, timestampState, runDigest,
        inspectPath: `/miniapp/runs/inspect?${new URLSearchParams({ runId: run.id, expectedRunDigest: runDigest })}` };
    });
    const nextOffset = offset + results.length < matches.length ? offset + results.length : null;
    // Construct allowed arguments only: neither sessions nor arbitrary caller data enter links.
    const next = new URLSearchParams({ status, owner, asOfMs: String(asOfMs), limit: String(limit), expectedDigest: sourceDigest });
    if (buildingId !== null) next.set("buildingId", buildingId);
    if (minAgeMs !== null) next.set("minAgeMs", String(minAgeMs));
    if (nextOffset !== null) next.set("offset", String(nextOffset));
    return response({ ok: true, kind: "run-inbox", schema: "moontown.miniapp-run-inbox.v1", filters, sourceDigest,
      offset, limit, totalMatches: matches.length, consideredRuns: candidates.length,
      statusCounts: [...counts].sort((a, b) => compareText(a[0], b[0])).map(([status, count]) => ({ status, count })),
      groups: [...groups.values()], results, nextPath: nextOffset === null ? null : `/miniapp/runs/inbox?${next}`, qualification });
  } catch (error) { return failure(error.status || 409, error.reason || "invalid-inbox-source"); }
}

// Inspect only one still-visible run. Conversation records are thread context,
// not attributed to that run, because the fixture has no message-to-run key.
export function inspectRun(state, userId, params) {
  const runId = params.get("runId"), expected = params.get("expectedRunDigest");
  if (!runId || !/^[a-f0-9]{64}$/.test(expected || "")) return failure(400, "run-id-and-inspected-digest-required");
  try {
    const indexes = indexState(state, ["buildings", "threads", "runs", "messages", "auditEvents"]);
    const run = indexes.runs.get(runId), building = run && indexes.buildings.get(run.buildingId);
    if (!building || !visible(building, userId)) return failure(404, "run-not-visible");
    const source = selectedSource(run, building, indexes.threads);
    if (hash(source) !== expected) return failure(409, "run-source-changed");
    const messages = source.thread ? state.messages.filter(message => message.threadId === source.thread.id)
      .map(item => pick(item, ["id", "threadId", "actorId", "actorLabel", "body", "createdAtMs", "version"])) : [];
    const auditEvents = state.auditEvents.filter(item => item.objectKind === "run" && item.objectId === runId)
      .map(item => pick(item, ["id", "actorUserId", "objectKind", "objectId", "action", "summary", "createdAtMs"]));
    const detail = { ...source, messages, auditEvents };
    if (Buffer.byteLength(JSON.stringify(detail)) > MAX_BYTES) return failure(413, "inbox-source-byte-limit");
    return response({ ok: true, kind: "run-inspection", schema: "moontown.miniapp-run-inspection.v1", runDigest: expected,
      sourceDigest: hash(detail), source: detail, gaps: source.thread ? [] : ["thread-not-retained"],
      contextMeaning: "All retained messages in the linked thread, in saved order; not a run-specific transcript. Audit events refer exactly to this run. Context is captured at inspection time.", qualification });
  } catch (error) { return failure(error.status || 409, error.reason || "invalid-inbox-source"); }
}
