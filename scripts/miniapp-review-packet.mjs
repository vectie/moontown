import { createHash } from "node:crypto";

const SCHEMA = "moontown.miniapp-building-review.v1";
const MAX_RECORDS = 5000;
const MAX_SOURCE_BYTES = 2 * 1024 * 1024;
const MAX_OUTPUT_BYTES = 4 * 1024 * 1024;
const fields = {
  buildings: ["id", "title", "visibility", "ownerId", "primaryBookId", "kind", "summary", "tags", "capabilities", "version", "updatedAtMs"],
  placements: ["id", "buildingId", "layerId", "x", "y", "regionId", "pinned", "version"],
  agents: ["id", "displayName", "ownerId", "buildingId", "capabilities", "version"],
  threads: ["id", "buildingId", "title", "messageCount", "unreadCount", "version"],
  messages: ["id", "threadId", "actorId", "actorLabel", "body", "createdAtMs", "version"],
  runs: ["id", "userId", "buildingId", "bookId", "agentId", "threadId", "status", "summary", "createdAtMs", "updatedAtMs", "version"],
  auditEvents: ["id", "actorUserId", "objectKind", "objectId", "action", "summary", "createdAtMs"],
};
const hash = (text) => createHash("sha256").update(text, "utf8").digest("hex");
const editable = (building, userId) => building.ownerId === userId || building.ownerId === "org-a";
const failure = (status, reason) => ({ status, body: { ok: false, kind: "building-review-packet", reason } });

export function reviewPacketAction(building, userId) {
  if (!editable(building, userId)) return null;
  return { buildingId: building.id, previewPath: `/miniapp/buildings/review-packet?buildingId=${encodeURIComponent(building.id)}`, formats: ["json", "markdown"] };
}

// Selection and rendering run synchronously against the same in-memory records.
// Only documented fixture fields enter the portable source projection.
function collectSource(state, building) {
  for (const key of Object.keys(fields)) {
    if (!Array.isArray(state[key]) || state[key].length > 20000) throw { status: 413, reason: "state-scan-limit" };
    const index = new Map();
    for (const item of state[key]) {
      if (!item || typeof item.id !== "string" || !item.id || index.has(item.id)) throw { status: 409, reason: "ambiguous-state-records" };
      index.set(item.id, item);
    }
  }
  const belongs = (key) => state[key].filter((item) => item.buildingId === building.id);
  const threads = belongs("threads");
  const threadIds = new Set(threads.map((item) => item.id));
  const runs = belongs("runs");
  // Refuse crossed conversation links rather than including another building's
  // messages or presenting an incomplete linked run as a complete review.
  if (runs.some((run) => !threadIds.has(run.threadId)) ||
      state.runs.some((run) => run.buildingId !== building.id && threadIds.has(run.threadId))) {
    throw { status: 409, reason: "inconsistent-conversation-links" };
  }
  const agents = belongs("agents");
  const objectIds = {
    building: new Set([building.id]),
    agent: new Set(agents.map((item) => item.id)),
    thread: threadIds,
    run: new Set(runs.map((item) => item.id)),
  };
  const selected = {
    buildings: [building], placements: belongs("placements"), agents, threads,
    messages: state.messages.filter((item) => threadIds.has(item.threadId)), runs,
    auditEvents: state.auditEvents.filter((item) => Object.hasOwn(objectIds, item.objectKind) && objectIds[item.objectKind].has(item.objectId)),
  };
  let count = 0;
  let bytes = 0;
  const source = { schema: SCHEMA, origin: "moontown-miniapp-local-development-service" };
  for (const [key, records] of Object.entries(selected)) {
    count += records.length;
    if (count > MAX_RECORDS) throw { status: 413, reason: "packet-record-limit" };
    const projected = records.map((record) => {
      const value = Object.fromEntries(fields[key].filter((field) => Object.hasOwn(record, field)).map((field) => [field, record[field]]));
      const serialized = JSON.stringify(value);
      bytes += Buffer.byteLength(serialized);
      if (bytes > MAX_SOURCE_BYTES) throw { status: 413, reason: "packet-source-byte-limit" };
      return JSON.parse(serialized);
    });
    // Original record order is retained, including conversational and audit order.
    if (key === "buildings") source.building = projected[0];
    else source[key] = projected;
  }
  const serialized = JSON.stringify(source);
  if (Buffer.byteLength(serialized) > MAX_SOURCE_BYTES) throw { status: 413, reason: "packet-source-byte-limit" };
  return { source, sourceDigest: hash(serialized) };
}

// JSON text in indented code blocks never interprets source strings as Markdown,
// HTML, links, headings or fences. Preserve embedded newlines in a readable form.
function literal(value) {
  return String(value ?? "").replace(/\r\n?/g, "\n").split("\n").map((line) => `    ${line}`).join("\n");
}
function recordSection(label, records) {
  return `## ${label} (${records.length})\n\n` + (records.length ? records.map((record) => `${literal(JSON.stringify(record, null, 2))}\n`).join("\n") : "No retained records.\n") + "\n";
}
function markdown(source, sourceDigest) {
  let text = "# MoonTown building review packet\n\n";
  text += "Local development-service evidence only. Not accepted Book knowledge, proof of successful execution, a backup, or a live status view.\n\n";
  text += `Source projection SHA-256: ${sourceDigest}\n\n`;
  text += "## Building\n\n" + literal(JSON.stringify(source.building, null, 2)) + "\n\n";
  text += recordSection("Placements", source.placements) + recordSection("Agents", source.agents);
  text += `## Conversations (${source.threads.length})\n\n`;
  if (!source.threads.length) text += "No retained conversations.\n\n";
  for (const thread of source.threads) {
    text += "### Thread\n\n" + literal(JSON.stringify(thread, null, 2)) + "\n\n";
    const messages = source.messages.filter((message) => message.threadId === thread.id);
    if (!messages.length) text += "No retained messages.\n\n";
    for (const message of messages) {
      const { body, ...metadata } = message;
      text += "Message record:\n\n" + literal(JSON.stringify(metadata)) + "\n\n" + literal(body) + "\n\n";
    }
  }
  text += recordSection("Runs (recorded statuses)", source.runs);
  text += recordSection("Scoped audit events", source.auditEvents);
  text += "## Reading this packet\n\nThe source digest binds JSON.stringify(source) in the companion JSON representation, not the state-file bytes. Record arrays retain saved order. Message counts are recorded values; listed messages are the retained records. No synthesis, verification, acceptance, dispatch, publication, restore or upload occurred. Review source text for private data before sharing.\n";
  return text;
}

export function buildingReviewPacket(state, userId, params) {
  const buildingId = params.get("buildingId");
  const format = params.get("format") || "preview";
  if (!buildingId || !buildingId.trim()) return failure(400, "building-id-required");
  if (!["preview", "json", "markdown"].includes(format)) return failure(400, "unsupported-packet-format");
  const building = state.buildings.find((item) => item.id === buildingId);
  if (!building || !editable(building, userId)) return failure(404, "building-not-editable");
  try {
    const { source, sourceDigest } = collectSource(state, building);
    const counts = Object.fromEntries(Object.keys(fields).filter((key) => key !== "buildings").map((key) => [key, source[key].length]));
    if (format === "preview") {
      const previewPath = reviewPacketAction(building, userId).previewPath;
      return { status: 200, body: {
        ok: true, kind: "building-review-packet", schema: SCHEMA, building: source.building, counts, sourceDigest,
        qualification: "Local development-service records; no accepted knowledge or execution proof.",
        downloads: Object.fromEntries(["json", "markdown"].map((name) => [name, `${previewPath}&format=${name}&expectedDigest=${sourceDigest}`])),
      } };
    }
    const expectedDigest = params.get("expectedDigest");
    if (!/^[a-f0-9]{64}$/.test(expectedDigest || "")) return failure(400, "inspected-source-digest-required");
    if (expectedDigest !== sourceDigest) return failure(409, "packet-source-changed");
    const content = format === "json" ? JSON.stringify({ schema: SCHEMA, sourceDigest, source }, null, 2) + "\n" : markdown(source, sourceDigest);
    const length = Buffer.byteLength(content);
    if (length > MAX_OUTPUT_BYTES) return failure(413, "packet-output-byte-limit");
    return { status: 200, body: content, headers: {
      "content-type": format === "json" ? "application/json; charset=utf-8" : "text/markdown; charset=utf-8",
      "content-disposition": `attachment; filename="moontown-building-${sourceDigest.slice(0, 12)}.${format === "json" ? "json" : "md"}"`,
      "content-length": String(length), "cache-control": "no-store", "x-content-type-options": "nosniff",
      "x-source-digest": sourceDigest, "x-content-sha256": hash(content),
    } };
  } catch (error) {
    return failure(error.status || 409, error.reason || "invalid-packet-source");
  }
}
