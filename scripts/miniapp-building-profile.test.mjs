import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import { createServer, initialState, loadState, routeRequest, saveState } from "./miniapp-local-backend.mjs";

const previewPath = "/miniapp/buildings/profile/preview";
const applyPath = "/miniapp/buildings/profile/apply";
function request(state, method, route, body = {}, userId = "user-a", headers = {}) {
  const url = new URL(route, "http://localhost");
  url.searchParams.set("userId", userId);
  return routeRequest(state, method, url, body, headers);
}
function proposal(state, changes, buildingId = "private-lab", userId = "user-a") {
  const expectedVersion = state.buildings.find((b) => b.id === buildingId).version;
  const body = { buildingId, expectedVersion, changes };
  const preview = request(state, "POST", previewPath, body, userId);
  assert.equal(preview.status, 200, JSON.stringify(preview.body));
  return { body: { ...body, previewDigest: preview.body.previewDigest }, preview: preview.body };
}
function retained(state) {
  return Object.fromEntries(["placements", "agents", "threads", "messages", "runs"].map((key) => [key, structuredClone(state[key])]));
}
function serviceRequest(server, method, url, body = {}, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = Readable.from([Buffer.from(JSON.stringify(body))]);
    Object.assign(req, { method, url, headers });
    req.on("error", reject);
    const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; },
      writeHead(status, headers) { this.status = status; Object.assign(this.headers, headers); },
      end(text) { resolve({ status: this.status, headers: this.headers, body: JSON.parse(text) }); } };
    server.emit("request", req, res);
  });
}

test("snapshot exposes exact profile actions only for editable current buildings", () => {
  const state = initialState();
  const view = request(state, "GET", "/miniapp/town/snapshot").body;
  assert.deepEqual(view.profileEdits.map((a) => a.buildingId), ["private-lab", "team-studio"]);
  assert.deepEqual(view.profileEdits[0], { buildingId: "private-lab", expectedVersion: 1,
    fields: ["title", "summary", "tags"], previewPath, applyPath });
  const other = request(state, "GET", "/miniapp/town/snapshot", {}, "user-b").body;
  assert.deepEqual(other.profileEdits.map((a) => a.buildingId), ["team-studio", "other-private-lab"]);
});

test("review before/after then apply to the same building with retained conversation and audit", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", body: "Keep my evidence" });
  const before = structuredClone(state), history = retained(state);
  const changes = { title: "Research 月 Lab", summary: "New focus\nwith old evidence", tags: ["research", "月"] };
  const prepared = proposal(state, changes);
  assert.deepEqual(state, before);
  assert.deepEqual(prepared.preview.before.tags, ["agent", "private", "draft"]);
  assert.deepEqual(prepared.preview.after, changes);
  assert.deepEqual(prepared.preview.changedFields, ["title", "summary", "tags"]);
  const result = request(state, "POST", applyPath, prepared.body);
  assert.equal(result.status, 200);
  assert.equal(result.body.changed, true);
  const current = result.body.building;
  assert.equal(current.id, "private-lab");
  assert.equal(current.version, 2);
  assert.equal(current.primaryBookId, "book-private-lab");
  assert.equal(current.ownerId, "user-a");
  assert.equal(current.visibility, "private_draft");
  assert.deepEqual(current.capabilities, before.buildings[1].capabilities);
  assert.deepEqual(retained(state), history);
  assert.equal(state.auditEvents.length, before.auditEvents.length + 1);
  assert.equal(state.auditEvents.at(-1).id, result.body.auditEventId);
  assert.equal(state.auditEvents.at(-1).action, "building.profile.updated");
  assert.equal(request(state, "GET", "/miniapp/town/snapshot").body.profileEdits[0].expectedVersion, 2);
  const packet = request(state, "GET", "/miniapp/buildings/review-packet?buildingId=private-lab").body;
  const exported = JSON.parse(request(state, "GET", packet.downloads.json).body);
  assert.equal(exported.source.building.title, changes.title);
  assert.equal(exported.source.messages[0].body, "Keep my evidence");
  assert.equal(exported.source.auditEvents.at(-1).action, "building.profile.updated");
});

test("published building edits are rediscoverable by new title and tags with unchanged visibility", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/publish", { buildingId: "private-lab" });
  const edit = proposal(state, { title: "Climate Observatory", tags: ["atmosphere"] });
  assert.equal(request(state, "POST", applyPath, edit.body).status, 200);
  for (const query of ["climate", "atmosphere"]) {
    const found = request(state, "GET", `/miniapp/buildings/search?query=${query}`, {}, "user-b").body.results;
    assert.deepEqual(found.map((b) => b.id), ["private-lab"]);
    assert.equal(found[0].visibility, "published");
  }
  const old = request(state, "GET", "/miniapp/buildings/search?query=private").body.results;
  assert.equal(old.some((b) => b.id === "private-lab"), false);
});

test("archived profile can be corrected and found without restoring or publishing", () => {
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/archive", { buildingId: "private-lab" });
  const archived = request(state, "GET", "/miniapp/buildings/archived").body.results[0];
  assert.equal(archived.profileEdit.expectedVersion, 2);
  const edit = proposal(state, { title: "Retained 2026 study", tags: ["completed-study"] });
  request(state, "POST", applyPath, edit.body);
  const found = request(state, "GET", "/miniapp/buildings/archived?query=completed-study").body.results;
  assert.equal(found.length, 1);
  assert.equal(found[0].building.visibility, "archived");
  assert.equal(found[0].building.version, 3);
  assert.equal(request(state, "GET", "/miniapp/town/snapshot").body.buildings.some((b) => b.id === "private-lab"), false);
});

test("newer metadata or changed proposed text requires fresh review and repeated apply adds no audit", () => {
  const state = initialState();
  const edit = proposal(state, { title: "Reviewed title" });
  const original = structuredClone(state);
  const wrong = request(state, "POST", applyPath, { ...edit.body, changes: { title: "Different title" } });
  assert.equal(wrong.status, 409);
  assert.equal(wrong.body.reason, "profile-preview-changed");
  assert.deepEqual(state, original);
  assert.equal(request(state, "POST", applyPath, edit.body).status, 200);
  const changed = structuredClone(state);
  assert.equal(request(state, "POST", applyPath, edit.body).body.reason, "building-version-changed");
  assert.deepEqual(state, changed);
  const pending = proposal(state, { summary: "Later review" });
  request(state, "POST", "/miniapp/buildings/archive", { buildingId: "private-lab" });
  const archived = structuredClone(state);
  assert.equal(request(state, "POST", applyPath, pending.body).status, 409);
  assert.deepEqual(state, archived);
});

test("fixture sessions and organization ownership govern profile editing and actor binding", () => {
  const state = initialState();
  const initial = structuredClone(state);
  for (const id of ["other-private-lab", "policy-hall", "missing"]) {
    assert.equal(request(state, "POST", previewPath, { buildingId: id, expectedVersion: 1, changes: { title: "No" } }).status, 404);
  }
  assert.deepEqual(state, initial);
  const edit = proposal(state, { title: "Shared new name" }, "team-studio");
  assert.equal(request(state, "POST", applyPath, edit.body, "user-b").status, 409);
  const otherEdit = proposal(state, { title: "Shared new name" }, "team-studio", "user-b");
  assert.equal(request(state, "POST", applyPath, otherEdit.body, "user-b").status, 200);
  state.sessions.set("valid-b", { userId: "user-b", expiresAtMs: Date.now() + 60000 });
  const userAEdit = proposal(state, { title: "Owner only" });
  const denied = request(state, "POST", applyPath, { ...userAEdit.body, userId: "user-a" }, "user-a", { "x-miniapp-session": "valid-b" });
  assert.equal(denied.status, 404);
  assert.equal(request(state, "POST", applyPath, userAEdit.body, "user-a", { "x-miniapp-session": "expired" }).status, 401);
});

test("invalid fields and malformed values are rejected before any profile mutation", () => {
  const state = initialState(), before = structuredClone(state);
  for (const changes of [{ ownerId: "user-b" }, { title: " " }, { summary: null }, { tags: ["same", "same"] }, { tags: [2] }, {}]) {
    assert.equal(request(state, "POST", previewPath, { buildingId: "private-lab", expectedVersion: 1, changes }).status, 400);
  }
  const edit = proposal(state, { title: "Valid preview" });
  const { previewDigest, ...unbound } = edit.body;
  assert.equal(request(state, "POST", applyPath, unbound).status, 400);
  assert.deepEqual(state, before);
});

test("no-op review preserves version and does not call persistence or append an event", async () => {
  const state = initialState(), before = structuredClone(state);
  let saves = 0;
  const server = createServer(state, () => saves++);
  const body = { buildingId: "private-lab", expectedVersion: 1, changes: { title: "Private Agent Lab" } };
  const preview = await serviceRequest(server, "POST", previewPath, body);
  assert.equal(preview.status, 200);
  assert.deepEqual(preview.body.changedFields, []);
  const applied = await serviceRequest(server, "POST", applyPath, { ...body, previewDigest: preview.body.previewDigest });
  assert.equal(applied.status, 200);
  assert.equal(applied.body.changed, false);
  assert.equal(applied.body.auditEventId, null);
  assert.equal(saves, 0);
  assert.deepEqual(state, before);
});

test("actual request listener persists an applied edit and reopens same identity/history after restart", async () => {
  const root = process.env.MOONTOWN_PROFILE_EVIDENCE || os.tmpdir();
  fs.mkdirSync(root, { recursive: true });
  const directory = fs.mkdtempSync(path.join(root, "moontown-profile-"));
  console.log(`retained-profile-evidence=${directory}`);
  const statePath = path.join(directory, "state.json");
  const state = initialState();
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", body: "Exact retained question" });
  saveState(statePath, state);
  const savedBefore = fs.readFileSync(statePath);
  let saves = 0;
  const server = createServer(state, (next) => { saves++; saveState(statePath, next); });
  const snapshot = await serviceRequest(server, "GET", "/miniapp/town/snapshot");
  const action = snapshot.body.profileEdits.find((a) => a.buildingId === "private-lab");
  const body = { buildingId: action.buildingId, expectedVersion: action.expectedVersion,
    changes: { title: "Reviewed 月 archive", summary: "", tags: [] } };
  const preview = await serviceRequest(server, "POST", action.previewPath, body);
  assert.equal(preview.status, 200);
  assert.equal(preview.headers["cache-control"], "no-store");
  assert.equal(saves, 0);
  assert.deepEqual(fs.readFileSync(statePath), savedBefore);
  const result = await serviceRequest(server, "POST", action.applyPath, { ...body, previewDigest: preview.body.previewDigest });
  assert.equal(result.status, 200);
  assert.equal(saves, 1);
  const reloaded = loadState(statePath);
  const reopened = await serviceRequest(createServer(reloaded), "GET", "/miniapp/town/snapshot");
  assert.deepEqual(reopened.body.buildings.find((b) => b.id === action.buildingId), result.body.building);
  assert.equal(reopened.body.messages.some((m) => m.body === "Exact retained question"), true);
  assert.equal(reopened.body.auditEvents.filter((e) => e.action === "building.profile.updated").length, 1);
  fs.writeFileSync(path.join(directory, "responses.json"), JSON.stringify({ preview, result, reopened }, null, 2));
});

test("current source changes cannot reuse an earlier preview even without a version bump", () => {
  const state = initialState();
  const edit = proposal(state, { title: "Reviewed" });
  state.buildings.find((b) => b.id === "private-lab").summary = "Changed by another editor";
  const before = structuredClone(state);
  assert.equal(request(state, "POST", applyPath, edit.body).body.reason, "profile-preview-changed");
  assert.deepEqual(state, before);
});
