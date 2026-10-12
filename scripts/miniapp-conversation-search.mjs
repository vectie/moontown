import { createHash } from "node:crypto";

const hash = (value) => createHash("sha256").update(value).digest("hex");
const failure = (status, reason) => ({ status, body: { ok: false, kind: "conversation-search", reason } });
const visible = (building, user) => building.visibility !== "archived" &&
  (building.visibility === "published" || [user, "org-a", "system"].includes(building.ownerId));

// A read-only projection of existing development-service conversation records.
export function conversationSearch(state, userId, params) {
  const query = params.get("query") ?? "";
  const buildingId = params.get("buildingId");
  const actorId = params.get("actorId");
  const mode = params.get("case") || "sensitive";
  const integer = (name, fallback) => {
    const raw = params.get(name);
    return raw === null ? fallback : /^(0|[1-9][0-9]*)$/.test(raw) ? Number(raw) : NaN;
  };
  const offset = integer("offset", 0), limit = integer("limit", 50);
  if (!query.trim() || query.length > 256 || query.includes("\0")) return failure(400, "literal-query-required-max-256");
  if (!["sensitive", "insensitive"].includes(mode) || !Number.isSafeInteger(offset) || offset < 0 ||
      !Number.isSafeInteger(limit) || limit < 1 || limit > 100) return failure(400, "invalid-search-options");
  const scopes = ["buildings", "threads", "messages", "runs"];
  for (const key of scopes) {
    if (!Array.isArray(state[key]) || state[key].length > 20000) return failure(413, "search-record-limit");
    const ids = new Set();
    for (const row of state[key]) {
      if (!row || typeof row.id !== "string" || !row.id || ids.has(row.id)) return failure(409, "ambiguous-state-records");
      ids.add(row.id);
    }
  }
  const buildings = state.buildings.filter((item) => visible(item, userId) && (buildingId === null || item.id === buildingId));
  if (buildingId !== null && !buildings.length) return failure(404, "building-not-visible");
  const buildingMap = new Map(buildings.map((item) => [item.id, item]));
  const threads = state.threads.filter((item) => buildingMap.has(item.buildingId));
  const threadMap = new Map(threads.map((item) => [item.id, item]));
  const runs = state.runs.filter((item) => threadMap.has(item.threadId));
  if (runs.some((run) => run.buildingId !== threadMap.get(run.threadId).buildingId)) return failure(409, "inconsistent-conversation-links");
  const messages = state.messages.filter((item) => threadMap.has(item.threadId) && (actorId === null || item.actorId === actorId));
  if (messages.some((item) => typeof item.body !== "string" || !Number.isSafeInteger(item.createdAtMs))) return failure(409, "invalid-message-record");
  const source = {
    userId, query, case: mode, buildingId, actorId,
    buildings: buildings.map(({ id, title, version, visibility }) => ({ id, title, version, visibility })),
    threads: threads.map(({ id, buildingId, title, version }) => ({ id, buildingId, title, version })),
    messages: messages.map(({ id, threadId, actorId, actorLabel, body, createdAtMs, version }) => ({ id, threadId, actorId, actorLabel, body, createdAtMs, version })),
    runs: runs.map(({ id, threadId, status, version, updatedAtMs }) => ({ id, threadId, status, version, updatedAtMs })),
  };
  const serialized = JSON.stringify(source);
  if (Buffer.byteLength(serialized) > 4 * 1024 * 1024) return failure(413, "search-source-byte-limit");
  const sourceDigest = hash(serialized);
  const expected = params.get("expectedDigest");
  if (offset > 0 && !expected) return failure(400, "page-source-digest-required");
  if (expected !== null && expected !== sourceDigest) return failure(409, "search-source-changed");
  const pattern = new RegExp(query.replace(/[.*+?^${}()|[\]\\]/g, "\\$&"), mode === "insensitive" ? "iu" : "u");
  const matches = [];
  for (const message of source.messages) {
    const match = pattern.exec(message.body);
    if (match) matches.push({ message, index: match.index, length: match[0].length });
  }
  matches.sort((a, b) => b.message.createdAtMs - a.message.createdAtMs ||
    (a.message.id < b.message.id ? -1 : a.message.id > b.message.id ? 1 : 0));
  const runsByThread = new Map();
  for (const run of source.runs) {
    if (!runsByThread.has(run.threadId)) runsByThread.set(run.threadId, []);
    runsByThread.get(run.threadId).push(run);
  }
  const results = [];
  let resultBytes = 0;
  for (const match of matches.slice(offset, offset + limit)) {
    const message = match.message;
    const thread = threadMap.get(message.threadId), building = buildingMap.get(thread.buildingId);
    const start = Math.max(0, match.index - 80), end = Math.min(message.body.length, match.index + match.length + 160);
    const row = { messageId: message.id, threadId: message.threadId, threadTitle: thread.title,
      buildingId: building.id, buildingTitle: building.title, actorId: message.actorId, actorLabel: message.actorLabel,
      createdAtMs: message.createdAtMs, version: message.version, textDigest: hash(message.body),
      excerpt: message.body.slice(start, end), excerptStart: start, matchStart: match.index, matchLength: match.length,
      excerptTruncated: start > 0 || end < message.body.length,
      runs: runsByThread.get(thread.id) || [], inspectPath: "/miniapp/town/snapshot" };
    resultBytes += Buffer.byteLength(JSON.stringify(row));
    if (resultBytes > 4 * 1024 * 1024) return failure(413, "search-output-byte-limit");
    results.push(row);
  }
  const nextOffset = offset + limit < matches.length ? offset + limit : null;
  let nextPath = null;
  if (nextOffset !== null) {
    const next = new URLSearchParams(params);
    // Identity/session transport stays with the caller, never copied into links.
    next.delete("sessionId"); next.delete("userId");
    next.set("offset", String(nextOffset)); next.set("expectedDigest", sourceDigest);
    nextPath = `/miniapp/conversations/search?${next}`;
  }
  const body = { ok: true, kind: "conversation-search", schema: "moontown.miniapp-conversation-search.v1",
    query, case: mode, buildingId, actorId, sourceDigest, offset, limit, nextPath,
    totalMatches: matches.length, searchedMessages: messages.length, results,
    qualification: "Retained local development-service message records; run statuses are recorded, not live execution evidence. Excerpts are plain text; render without HTML interpretation." };
  if (Buffer.byteLength(JSON.stringify(body)) > 4 * 1024 * 1024) return failure(413, "search-output-byte-limit");
  return { status: 200, body, headers: { "cache-control": "no-store" } };
}
