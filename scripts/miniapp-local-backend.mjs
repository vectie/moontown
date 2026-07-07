#!/usr/bin/env node
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import { URL } from "node:url";

const defaultPort = 18191;
const durableKeys = ["users", "buildings", "placements", "agents", "threads", "messages", "runs", "auditEvents"];
const now = () => Date.now();

function initialState() {
  return {
    sessions: new Map(),
    users: [
      { id: "user-a", displayName: "User A" },
      { id: "user-b", displayName: "User B" },
    ],
    buildings: [
      building("policy-hall", "Policy Hall", "published", "system", "book-policy-hall", ["policy", "review", "public"], ["query", "review", "publish"]),
      building("private-lab", "Private Agent Lab", "private_draft", "user-a", "book-private-lab", ["agent", "private", "draft"], ["query", "create-agent"]),
      building("team-studio", "Team Project Studio", "shared_private", "org-a", "book-team-studio", ["project", "team", "shared"], ["query", "review"]),
      building("other-private-lab", "Other Private Lab", "private_draft", "user-b", "book-other-private-lab", ["hidden", "private"], ["query"]),
    ],
    placements: [
      placement("placement-policy-hall", "policy-hall", "layer-personal-user-a", 42, 24),
      placement("placement-private-lab", "private-lab", "layer-personal-user-a", 64, 36),
      placement("placement-team-studio", "team-studio", "layer-personal-user-a", 76, 42),
    ],
    agents: [
      { id: "agent-policy-guide", displayName: "Policy Guide", ownerId: "system", buildingId: "policy-hall", capabilities: ["answer", "review", "route"], version: 1 },
    ],
    threads: [
      { id: "thread-policy-hall", buildingId: "policy-hall", title: "Policy Hall chat", messageCount: 1, unreadCount: 0, version: 1 },
    ],
    messages: [
      { id: "msg-policy-hall-1", threadId: "thread-policy-hall", actorId: "agent-policy-guide", actorLabel: "Policy Guide", body: "Policy Hall can answer with reviewable book-backed output.", createdAtMs: 2100, version: 1 },
    ],
    runs: [
      { id: "run-policy-hall-1", userId: "user-a", buildingId: "policy-hall", bookId: "book-policy-hall", agentId: "agent-policy-guide", threadId: "thread-policy-hall", status: "waiting_review", summary: "Waiting for human review before accepting memory.", createdAtMs: 2000, updatedAtMs: 2500, version: 1 },
    ],
    auditEvents: [
      { id: "audit-policy-hall-1", actorUserId: "user-a", objectKind: "run", objectId: "run-policy-hall-1", action: "query.waiting_review", summary: "Policy Hall answer is waiting for review.", createdAtMs: 2500 },
    ],
  };
}

function building(id, title, visibility, ownerId, primaryBookId, tags, capabilities) {
  return {
    id,
    title,
    visibility,
    ownerId,
    primaryBookId,
    kind: id.includes("lab") ? "agent_lab" : "policy_hall",
    summary: `${title} local backend fixture.`,
    tags,
    capabilities,
    version: 1,
    updatedAtMs: 2000,
  };
}

function placement(id, buildingId, layerId, x, y) {
  return { id, buildingId, layerId, x, y, regionId: "central-plaza", pinned: true, version: 1 };
}

function parseArgs(argv) {
  const result = {
    port: Number(process.env.PORT || defaultPort),
    smoke: false,
    resetState: false,
    statePath: process.env.MOONTOWN_MINIAPP_STATE || path.join(".moontown", "miniapp-local-backend-state.json"),
    statePathExplicit: Boolean(process.env.MOONTOWN_MINIAPP_STATE),
  };
  for (let i = 0; i < argv.length; i += 1) {
    if (argv[i] === "--port" && argv[i + 1]) {
      result.port = Number(argv[i + 1]);
      i += 1;
    } else if (argv[i] === "--state" && argv[i + 1]) {
      result.statePath = argv[i + 1];
      result.statePathExplicit = true;
      i += 1;
    } else if (argv[i] === "--reset-state") {
      result.resetState = true;
    } else if (argv[i] === "--smoke") {
      result.smoke = true;
    }
  }
  return result;
}

function createServer(state = initialState(), persistState = null) {
  return http.createServer(async (req, res) => {
    const url = new URL(req.url || "/", "http://127.0.0.1");
    setCors(res);
    if (req.method === "OPTIONS") {
      return sendJson(res, 204, {});
    }
    try {
      const body = await readJson(req);
      const response = routeRequest(state, req.method || "GET", url, body, req.headers);
      if (persistState && shouldPersist(req.method || "GET", url.pathname, response)) {
        persistState(state);
      }
      return sendJson(res, response.status, response.body);
    } catch (error) {
      return sendJson(res, 500, { ok: false, kind: "server-error", error: String(error && error.message ? error.message : error) });
    }
  });
}

function shouldPersist(method, pathName, response) {
  if (method !== "POST" || response.status < 200 || response.status >= 300) return false;
  return pathName !== "/miniapp/auth/dev-login";
}

function routeRequest(state, method, url, body, headers) {
  const path = url.pathname;
  if (method === "GET" && path === "/healthz") {
    return ok({ kind: "health", ok: true, service: "moontown-miniapp-local-backend" });
  }
  if (method === "POST" && path === "/miniapp/auth/dev-login") {
    return devLogin(state, body);
  }
  const session = requireSession(state, url, body, headers);
  if (!session.ok) return session;
  if (method === "GET" && path === "/miniapp/town/snapshot") {
    return snapshot(state, session.userId);
  }
  if (method === "GET" && path === "/miniapp/buildings/search") {
    return searchBuildings(state, session.userId, url.searchParams.get("query") || body.query || "");
  }
  if (method === "POST" && path === "/miniapp/buildings") {
    return createBuilding(state, session.userId, body);
  }
  if (method === "POST" && path === "/miniapp/buildings/place") {
    return placeBuilding(state, session.userId, body);
  }
  if (method === "POST" && path === "/miniapp/buildings/publish") {
    return publishBuilding(state, session.userId, body);
  }
  if (method === "POST" && path === "/miniapp/agents") {
    return createAgent(state, session.userId, body);
  }
  if (method === "POST" && path === "/miniapp/buildings/query") {
    return sendChat(state, session.userId, body);
  }
  if (method === "POST" && path === "/miniapp/runs/cancel") {
    return updateRun(state, session.userId, body, "cancelled", "run.cancelled");
  }
  if (method === "POST" && path === "/miniapp/runs/retry") {
    return updateRun(state, session.userId, body, "pending", "run.retry");
  }
  if (method === "POST" && path === "/miniapp/reviews/accept") {
    return updateRun(state, session.userId, body, "done", "review.accepted");
  }
  return json(404, { ok: false, kind: "not-found", path, method });
}

function devLogin(state, body) {
  const userId = body.userId || body.loginId || body.login_id || "user-a";
  const user = state.users.find((item) => item.id === userId);
  if (!user) return json(404, { ok: false, kind: "dev-login", reason: "user-not-found", userId });
  const sessionId = `dev-session-${userId}-${now()}`;
  state.sessions.set(sessionId, { id: sessionId, userId, expiresAtMs: now() + 3600000 });
  return ok({ ok: true, kind: "dev-login", user, session: { id: sessionId, userId, tokenLabel: `dev:${userId}` } });
}

function requireSession(state, url, body, headers) {
  const sessionId = body.sessionId || url.searchParams.get("sessionId") || headerValue(headers, "x-miniapp-session");
  if (sessionId && state.sessions.has(sessionId)) return { ok: true, userId: state.sessions.get(sessionId).userId, sessionId };
  const userId = body.userId || url.searchParams.get("userId") || "user-a";
  if (state.users.some((item) => item.id === userId)) return { ok: true, userId, sessionId: "" };
  return json(401, { ok: false, kind: "auth", reason: "session-invalid" });
}

function headerValue(headers, name) {
  const value = headers[name];
  if (Array.isArray(value)) return value[0] || "";
  return value || "";
}

function snapshot(state, userId) {
  const buildings = visibleBuildings(state, userId);
  const buildingIds = new Set(buildings.map((item) => item.id));
  const threads = state.threads.filter((item) => buildingIds.has(item.buildingId));
  const threadIds = new Set(threads.map((item) => item.id));
  const runs = state.runs.filter((item) => item.userId === userId || buildingIds.has(item.buildingId));
  const runIds = new Set(runs.map((item) => item.id));
  return ok({
    ok: true,
    kind: "snapshot",
    userId,
    buildings,
    placements: state.placements.filter((item) => buildingIds.has(item.buildingId)),
    agents: state.agents.filter((item) => !item.buildingId || buildingIds.has(item.buildingId)),
    threads,
    messages: state.messages.filter((item) => threadIds.has(item.threadId)),
    runs,
    auditEvents: state.auditEvents.filter((item) => item.actorUserId === userId || runIds.has(item.objectId)),
  });
}

function searchBuildings(state, userId, query) {
  const normalized = query.toLowerCase();
  const results = visibleBuildings(state, userId).filter((item) => {
    return item.visibility === "published" && (
      normalized === "" ||
      item.title.toLowerCase().includes(normalized) ||
      item.tags.some((tag) => tag.toLowerCase().includes(normalized))
    );
  });
  return ok({ ok: true, kind: "search-buildings", query, results });
}

function createBuilding(state, userId, body) {
  const id = body.id || body.buildingId || `building-${state.buildings.length + 1}`;
  if (state.buildings.some((item) => item.id === id)) return json(409, { ok: false, kind: "create-building", reason: "building-exists", id });
  const next = building(id, body.title || "New Agent Lab", "private_draft", userId, body.primaryBookId || `book-${id}`, body.tags || ["agent", "private"], body.capabilities || ["query", "create-agent"]);
  state.buildings.push(next);
  audit(state, userId, "building", id, "building.created", "Private building created locally.");
  return ok({ ok: true, kind: "create-building", building: next });
}

function placeBuilding(state, userId, body) {
  const buildingId = body.buildingId || "policy-hall";
  const target = state.buildings.find((item) => item.id === buildingId);
  if (!target || !canView(target, userId)) return json(404, { ok: false, kind: "place-building", reason: "building-not-visible", buildingId });
  const next = placement(body.id || `placement-${userId}-${buildingId}`, buildingId, body.layerId || `layer-personal-${userId}`, Number(body.x || 12), Number(body.y || 18));
  state.placements = state.placements.filter((item) => item.id !== next.id);
  state.placements.push(next);
  audit(state, userId, "building", buildingId, "building.placed", "Building placed locally.");
  return ok({ ok: true, kind: "place-building", placement: next });
}

function publishBuilding(state, userId, body) {
  const buildingId = body.buildingId || body.id;
  const target = state.buildings.find((item) => item.id === buildingId);
  if (!target || !canEdit(target, userId)) return json(403, { ok: false, kind: "publish-building", reason: "building-not-editable", buildingId });
  if (target.visibility !== "private_draft" && target.visibility !== "shared_private") {
    return json(409, { ok: false, kind: "publish-building", reason: "building-not-publishable", buildingId, visibility: target.visibility });
  }
  target.visibility = "published";
  target.ownerId = target.ownerId || userId;
  target.updatedAtMs = now();
  target.version += 1;
  audit(state, userId, "building", buildingId, "building.published", "Building published to local town.");
  return ok({ ok: true, kind: "publish-building", building: target });
}

function createAgent(state, userId, body) {
  const id = body.id || body.agentId || `agent-${state.agents.length + 1}`;
  if (state.agents.some((item) => item.id === id)) return json(409, { ok: false, kind: "create-agent", reason: "agent-exists", id });
  const buildingId = body.buildingId || null;
  if (buildingId) {
    const target = state.buildings.find((item) => item.id === buildingId);
    if (!target || !canEdit(target, userId)) return json(403, { ok: false, kind: "create-agent", reason: "building-not-editable", buildingId });
  }
  const agent = { id, displayName: body.displayName || "Local Agent", ownerId: userId, buildingId, capabilities: body.capabilities || ["answer"], version: 1 };
  state.agents.push(agent);
  audit(state, userId, "agent", id, "agent.created", "Agent created locally.");
  return ok({ ok: true, kind: "create-agent", agent });
}

function sendChat(state, userId, body) {
  const buildingId = body.buildingId || "policy-hall";
  const target = state.buildings.find((item) => item.id === buildingId);
  if (!target || !canView(target, userId)) return json(404, { ok: false, kind: "chat-send", reason: "building-not-visible", buildingId });
  const threadId = body.threadId || `thread-${buildingId}`;
  const runId = body.runId || `run-${threadId}-${state.runs.length + 1}`;
  const messageId = body.messageId || `msg-${threadId}-${state.messages.length + 1}`;
  let thread = state.threads.find((item) => item.id === threadId);
  if (!thread) {
    thread = { id: threadId, buildingId, title: `${target.title} chat`, messageCount: 0, unreadCount: 0, version: 1 };
    state.threads.push(thread);
  }
  thread.messageCount += 1;
  thread.unreadCount += 1;
  state.messages.push({ id: messageId, threadId, actorId: userId, actorLabel: "user", body: body.body || body.message || "Ask local agent.", createdAtMs: now(), version: 1 });
  const run = { id: runId, userId, buildingId, bookId: target.primaryBookId, agentId: body.agentId || null, threadId, status: "waiting_review", summary: body.answerSummary || "Local answer waiting for review.", createdAtMs: now(), updatedAtMs: now(), version: 1 };
  state.runs.push(run);
  audit(state, userId, "run", runId, "chat.sent", "Chat message recorded for reviewable agent run.");
  return ok({ ok: true, kind: "chat-send", thread, run });
}

function updateRun(state, userId, body, status, action) {
  const runId = body.runId || body.id;
  const run = state.runs.find((item) => item.id === runId);
  if (!run) return json(404, { ok: false, kind: action, reason: "run-not-found", runId });
  if (run.userId !== userId) return json(403, { ok: false, kind: action, reason: "run-not-owned", runId });
  run.status = status;
  run.summary = body.summary || run.summary;
  run.updatedAtMs = now();
  run.version += 1;
  audit(state, userId, "run", runId, action, run.summary);
  return ok({ ok: true, kind: action, run });
}

function visibleBuildings(state, userId) {
  return state.buildings.filter((item) => canView(item, userId));
}

function canView(building, userId) {
  return building.visibility === "published" || building.ownerId === userId || building.ownerId === "org-a" || building.ownerId === "system";
}

function canEdit(building, userId) {
  return building.ownerId === userId || building.ownerId === "org-a";
}

function audit(state, userId, objectKind, objectId, action, summary) {
  state.auditEvents.push({ id: `audit-${state.auditEvents.length + 1}`, actorUserId: userId, objectKind, objectId, action, summary, createdAtMs: now() });
}

async function readJson(req) {
  if (req.method === "GET" || req.method === "HEAD") return {};
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const text = Buffer.concat(chunks).toString("utf8").trim();
  if (!text) return {};
  try {
    return JSON.parse(text);
  } catch {
    return {};
  }
}

function setCors(res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "content-type,x-miniapp-session");
}

function sendJson(res, status, body) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8" });
  res.end(JSON.stringify(body));
}

function ok(body) {
  return json(200, body);
}

function json(status, body) {
  return { status, body };
}

function loadState(statePath, resetState = false) {
  const resolved = path.resolve(statePath);
  if (resetState && fs.existsSync(resolved)) {
    fs.unlinkSync(resolved);
  }
  if (!fs.existsSync(resolved)) return initialState();
  const loaded = JSON.parse(fs.readFileSync(resolved, "utf8"));
  const state = initialState();
  for (const key of durableKeys) {
    if (Array.isArray(loaded[key])) state[key] = loaded[key];
  }
  return state;
}

function saveState(statePath, state) {
  const resolved = path.resolve(statePath);
  fs.mkdirSync(path.dirname(resolved), { recursive: true });
  const tmpPath = `${resolved}.${process.pid}.tmp`;
  fs.writeFileSync(tmpPath, JSON.stringify(serializeState(state), null, 2) + "\n");
  fs.renameSync(tmpPath, resolved);
}

function serializeState(state) {
  const output = { version: 1, savedAtMs: now() };
  for (const key of durableKeys) {
    output[key] = state[key];
  }
  return output;
}

async function smoke(port, statePath = "") {
  const effectiveStatePath = statePath || path.join(os.tmpdir(), `moontown-miniapp-local-backend-smoke-${process.pid}-${now()}.json`);
  const smokeBuildingId = `smoke-persisted-building-${process.pid}-${now()}`;
  const server = createServer(loadState(effectiveStatePath, !statePath), (state) => saveState(effectiveStatePath, state));
  await new Promise((resolve) => server.listen(port, "127.0.0.1", resolve));
  const base = `http://127.0.0.1:${port}`;
  try {
    const login = await post(`${base}/miniapp/auth/dev-login`, { userId: "user-a" });
    const sessionId = login.session.id;
    const snapshotResponse = await get(`${base}/miniapp/town/snapshot`, { "x-miniapp-session": sessionId });
    const created = await post(`${base}/miniapp/buildings`, {
      sessionId,
      id: smokeBuildingId,
      title: "Smoke Persisted Building",
      tags: ["smoke", "local"],
    });
    const published = await post(`${base}/miniapp/buildings/publish`, {
      sessionId,
      buildingId: smokeBuildingId,
    });
    const userBLogin = await post(`${base}/miniapp/auth/dev-login`, { userId: "user-b" });
    const userBSearch = await get(`${base}/miniapp/buildings/search?query=smoke`, { "x-miniapp-session": userBLogin.session.id });
    const chat = await post(`${base}/miniapp/buildings/query`, {
      sessionId,
      buildingId: "private-lab",
      threadId: "thread-private-lab",
      runId: "run-smoke-chat",
      messageId: "msg-smoke-chat",
      body: "Smoke test chat.",
    });
    const reloaded = loadState(effectiveStatePath);
    const persisted = reloaded.buildings.some((item) => item.id === smokeBuildingId);
    const discoverable = userBSearch.results.some((item) => item.id === smokeBuildingId);
    if (!login.ok || !snapshotResponse.ok || !created.ok || !published.ok || !userBLogin.ok || !discoverable || !chat.ok || !persisted) {
      throw new Error("miniapp local backend smoke failed");
    }
    console.log(`miniapp-local-backend-smoke=ok port=${port} buildings=${snapshotResponse.buildings.length} created=${created.building.id} published=${published.building.id} discoverable=${discoverable} persisted=${persisted} run=${chat.run.id}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    if (!statePath && fs.existsSync(effectiveStatePath)) {
      fs.unlinkSync(effectiveStatePath);
    }
  }
}

async function get(url, headers = {}) {
  const response = await fetch(url, { headers });
  return response.json();
}

async function post(url, body) {
  const response = await fetch(url, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(body),
  });
  return response.json();
}

const args = parseArgs(process.argv.slice(2));
if (args.smoke) {
  await smoke(args.port, args.statePathExplicit ? args.statePath : "");
} else {
  const statePath = path.resolve(args.statePath);
  const state = loadState(statePath, args.resetState);
  createServer(state, (nextState) => saveState(statePath, nextState)).listen(args.port, "127.0.0.1", () => {
    console.log(`moontown-miniapp-local-backend=http://127.0.0.1:${args.port}`);
    console.log("wechat-devtools-backendBaseUrl=http://127.0.0.1:" + args.port);
    console.log("moontown-miniapp-local-state=" + statePath);
  });
}
