import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import { createServer, initialState, loadState, routeRequest, saveState } from "./miniapp-local-backend.mjs";

function request(state, method, pathname, body = {}, userId = "user-a") {
  const url = new URL(pathname, "http://localhost");
  if (!url.searchParams.has("userId")) url.searchParams.set("userId", userId);
  return routeRequest(state, method, url, body, {});
}
function archive(state, id = "private-lab", userId = "user-a") {
  const response = request(state, "POST", "/miniapp/buildings/archive", { buildingId: id }, userId);
  assert.equal(response.status, 200);
  return response.body.building.version;
}
function restore(state, id, expectedVersion, userId = "user-a", extra = {}) {
  return request(state, "POST", "/miniapp/buildings/restore", { buildingId: id, expectedVersion, ...extra }, userId);
}
function archived(state, userId = "user-a", query = "") {
  return request(state, "GET", `/miniapp/buildings/archived?query=${encodeURIComponent(query)}`, {}, userId).body.results;
}
function snapshot(state, userId = "user-a") {
  return request(state, "GET", "/miniapp/town/snapshot", {}, userId).body;
}
function related(state) {
  return structuredClone(Object.fromEntries(["placements", "agents", "threads", "messages", "runs"].map((key) => [key, state[key]])));
}

// Exercise the actual service's request listener without requiring a listening
// socket. This covers adapter decoding, session resolution and persistence;
// loopback transport is a separate smoke, not implied by these portable tests.
function serviceRequest(server, method, pathname, body = {}, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = Readable.from([Buffer.from(JSON.stringify(body))]);
    Object.assign(req, { method, url: pathname, headers });
    req.on("error", reject);
    const res = {
      headers: {},
      setHeader(name, value) { this.headers[name] = value; },
      writeHead(status, values) { this.status = status; Object.assign(this.headers, values); },
      end(text) { resolve({ status: this.status, headers: this.headers, body: JSON.parse(text) }); },
    };
    server.emit("request", req, res);
  });
}

test("archive list starts empty, is searchable and does not change state", () => {
  const state = initialState();
  assert.deepEqual(archived(state), []);
  archive(state);
  archive(state, "team-studio");
  const before = structuredClone(state);
  assert.equal(archived(state).length, 2);
  assert.deepEqual(archived(state, "user-a", " PRIVATE ").map((entry) => entry.building.id), ["private-lab"]);
  assert.equal(archived(state, "user-a", "unmatched").length, 0);
  assert.deepEqual(state, before);
});

test("recover an archived building with retained placements, agents, conversation and run", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/agents", { id: "private-agent", buildingId: "private-lab", displayName: "Lab guide" });
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", threadId: "private-thread", runId: "private-run", messageId: "private-message", body: "Keep this question" });
  const preserved = related(state);
  const version = archive(state);
  assert.equal(snapshot(state).buildings.some((building) => building.id === "private-lab"), false);
  const selected = archived(state)[0];
  assert.equal(selected.building.version, version);
  assert.equal(selected.restoreVisibility, "private_draft");
  assert.deepEqual(selected.retained, { placements: 1, agents: 1, threads: 1, messages: 1, runs: 1 });
  const result = restore(state, selected.building.id, version);
  assert.equal(result.status, 200);
  assert.equal(result.body.building.visibility, "private_draft");
  assert.equal(result.body.building.primaryBookId, "book-private-lab");
  assert.equal(result.body.building.version, version + 1);
  assert.deepEqual(related(state), preserved);
  assert.equal(archived(state).length, 0);
  const reopened = snapshot(state);
  assert.equal(reopened.messages.find((message) => message.id === "private-message").body, "Keep this question");
  assert.equal(reopened.runs.find((run) => run.id === "private-run").status, "waiting_review");
  assert.equal(state.auditEvents.filter((event) => event.action === "building.restored").length, 1);
});

test("a formerly published personal building is recovered privately, never republished", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/publish", { buildingId: "private-lab" });
  assert.equal(snapshot(state, "user-b").buildings.some((building) => building.id === "private-lab"), true);
  const version = archive(state);
  const result = restore(state, "private-lab", version, "user-a", { visibility: "published" });
  assert.equal(result.body.building.visibility, "private_draft");
  assert.equal(snapshot(state, "user-b").buildings.some((building) => building.id === "private-lab"), false);
  assert.equal(request(state, "GET", "/miniapp/buildings/search?query=private").body.results.length, 0);
  assert.equal(state.auditEvents.filter((event) => event.action === "building.published").length, 1);
});

test("fixture organization recovery retains team visibility and never uses a public state", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/publish", { buildingId: "team-studio" });
  const version = archive(state, "team-studio");
  assert.equal(archived(state, "user-b")[0].restoreVisibility, "shared_private");
  assert.equal(restore(state, "team-studio", version, "user-b").body.building.visibility, "shared_private");
  assert.equal(snapshot(state, "user-a").buildings.some((building) => building.id === "team-studio"), true);
  assert.equal(request(state, "GET", "/miniapp/buildings/search?query=Team").body.results.length, 0);
});

test("session principal controls discovery and recovery despite a caller-selected user field", () => {
  const state = initialState();
  const version = archive(state);
  assert.deepEqual(archived(state, "user-b"), []);
  assert.equal(restore(state, "private-lab", version, "user-b").status, 404);
  const sessionId = request(state, "POST", "/miniapp/auth/dev-login", { userId: "user-b" }).body.session.id;
  const before = related(state);
  const list = routeRequest(state, "GET", new URL(`http://localhost/miniapp/buildings/archived?userId=user-a`), {}, { "x-miniapp-session": sessionId });
  assert.equal(list.body.userId, "user-b");
  assert.deepEqual(list.body.results, []);
  assert.equal(restore(state, "private-lab", version, "user-a", { sessionId }).status, 404);
  assert.deepEqual(related(state), before);
  assert.equal(state.buildings.find((building) => building.id === "private-lab").visibility, "archived");
});

test("stale selections, missing inspected versions and repeat restores do not mutate state", () => {
  const state = initialState();
  const version = archive(state);
  const before = structuredClone(state);
  const stale = restore(state, "private-lab", version - 1);
  assert.equal(stale.status, 409);
  assert.equal(stale.body.reason, "building-version-changed");
  assert.equal(stale.body.currentVersion, version);
  assert.equal(restore(state, "private-lab", undefined).status, 400);
  assert.deepEqual(state, before);
  assert.equal(restore(state, "private-lab", version).status, 200);
  const restored = structuredClone(state);
  assert.equal(restore(state, "private-lab", version).body.reason, "building-not-archived");
  assert.deepEqual(state, restored);
});

test("legacy archived version-1 state needs no new metadata or schema migration", () => {
  const state = initialState();
  const building = state.buildings.find((item) => item.id === "private-lab");
  building.visibility = "archived";
  assert.equal(archived(state)[0].building.version, 1);
  assert.equal(restore(state, building.id, 1).status, 200);
  assert.equal(building.visibility, "private_draft");
});

test("request adapter persists archive and restore, reloads history, and requires a new dev session", async () => {
  const evidenceRoot = process.env.MOONTOWN_ARCHIVE_TEST_EVIDENCE || os.tmpdir();
  fs.mkdirSync(evidenceRoot, { recursive: true });
  const directory = fs.mkdtempSync(path.join(evidenceRoot, "moontown-archive-test-"));
  console.log(`retained-state-evidence=${directory}`);
  const statePath = path.join(directory, "state.json");
  let state = initialState();
  let writes = 0;
  let server = createServer(state, (next) => { saveState(statePath, next); writes += 1; });
  const login = await serviceRequest(server, "POST", "/miniapp/auth/dev-login", { userId: "user-a" });
  const headers = { "x-miniapp-session": login.body.session.id };
  await serviceRequest(server, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", body: "Recover after restart" }, headers);
  await serviceRequest(server, "POST", "/miniapp/buildings/archive", { buildingId: "private-lab" }, headers);
  const oldBytes = fs.readFileSync(statePath, "utf8");
  assert.equal(writes, 2);
  const firstList = await serviceRequest(server, "GET", "/miniapp/buildings/archived", {}, headers);
  assert.equal(writes, 2);
  assert.equal(firstList.headers["content-type"], "application/json; charset=utf-8");
  state = loadState(statePath);
  server = createServer(state, (next) => { saveState(statePath, next); writes += 1; });
  assert.equal((await serviceRequest(server, "GET", "/miniapp/buildings/archived", {}, headers)).status, 401);
  const newLogin = await serviceRequest(server, "POST", "/miniapp/auth/dev-login", { userId: "user-a" });
  const newHeaders = { "x-miniapp-session": newLogin.body.session.id };
  const selected = (await serviceRequest(server, "GET", "/miniapp/buildings/archived", {}, newHeaders)).body.results[0];
  assert.deepEqual(selected, firstList.body.results[0]);
  const stale = await serviceRequest(server, "POST", "/miniapp/buildings/restore", { buildingId: selected.building.id, expectedVersion: selected.building.version - 1 }, newHeaders);
  assert.equal(stale.status, 409);
  assert.equal(fs.readFileSync(statePath, "utf8"), oldBytes);
  const result = await serviceRequest(server, "POST", "/miniapp/buildings/restore", { buildingId: selected.building.id, expectedVersion: selected.building.version }, newHeaders);
  assert.equal(result.status, 200);
  assert.equal(writes, 3);
  const reloaded = loadState(statePath);
  assert.deepEqual(archived(reloaded), []);
  assert.equal(snapshot(reloaded).messages.some((message) => message.body === "Recover after restart"), true);
  assert.equal(reloaded.auditEvents.filter((event) => event.action === "building.restored").length, 1);
  assert.deepEqual(related(reloaded), related(state));
});
