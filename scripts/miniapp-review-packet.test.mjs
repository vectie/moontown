import test from "node:test";
import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import { createServer, initialState, loadState, routeRequest, saveState } from "./miniapp-local-backend.mjs";

const digest = (text) => createHash("sha256").update(text).digest("hex");
function request(state, method, route, body = {}, userId = "user-a", headers = {}) {
  const url = new URL(route, "http://localhost");
  url.searchParams.set("userId", userId);
  return routeRequest(state, method, url, body, headers);
}
function inspect(state, id = "private-lab", user = "user-a") {
  return request(state, "GET", `/miniapp/buildings/review-packet?buildingId=${encodeURIComponent(id)}`, {}, user);
}
function prepare() {
  const state = initialState();
  request(state, "POST", "/miniapp/agents", { id: "lab-guide", buildingId: "private-lab", displayName: "Lab guide" });
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", agentId: "lab-guide", runId: "lab-run", body: "What changed in the local plan?\nKeep the original context." });
  return state;
}
function serviceRequest(server, method, url, body = {}, headers = {}) {
  return new Promise((resolve, reject) => {
    const req = Readable.from([Buffer.from(JSON.stringify(body))]);
    Object.assign(req, { method, url, headers });
    req.on("error", reject);
    const res = {
      headers: {},
      setHeader(name, value) { this.headers[name] = value; },
      writeHead(status, headers) { this.status = status; Object.assign(this.headers, headers); },
      end(text) { resolve({ status: this.status, headers: this.headers, text }); },
    };
    server.emit("request", req, res);
  });
}

test("town snapshot exposes packet actions only for editable buildings", () => {
  const state = initialState();
  const snapshot = request(state, "GET", "/miniapp/town/snapshot").body;
  assert.deepEqual(snapshot.reviewPackets.map((action) => action.buildingId), ["private-lab", "team-studio"]);
  const action = snapshot.reviewPackets[0];
  assert.deepEqual(action.formats, ["json", "markdown"]);
  assert.equal(request(state, "GET", action.previewPath).body.building.id, action.buildingId);
  assert.equal(inspect(state, "policy-hall").status, 404);
  assert.equal(inspect(state, "other-private-lab").status, 404);
  const other = request(state, "GET", "/miniapp/town/snapshot", {}, "user-b").body;
  assert.deepEqual(other.reviewPackets.map((action) => action.buildingId), ["team-studio", "other-private-lab"]);
});

test("inspect, export JSON and reopen one complete source-linked building packet", () => {
  const state = prepare();
  const before = structuredClone(state);
  const preview = inspect(state).body;
  assert.deepEqual(preview.counts, { placements: 1, agents: 1, threads: 1, messages: 1, runs: 1, auditEvents: 2 });
  const result = request(state, "GET", preview.downloads.json);
  assert.equal(result.status, 200);
  const packet = JSON.parse(result.body);
  assert.equal(packet.sourceDigest, digest(JSON.stringify(packet.source)));
  assert.equal(packet.sourceDigest, preview.sourceDigest);
  assert.equal(packet.source.building.primaryBookId, "book-private-lab");
  assert.equal(packet.source.messages[0].body, "What changed in the local plan?\nKeep the original context.");
  assert.equal(packet.source.runs[0].status, "waiting_review");
  assert.equal(packet.source.runs[0].id, "lab-run");
  assert.equal(packet.source.threads[0].id, packet.source.runs[0].threadId);
  assert.deepEqual(packet.source.auditEvents.map((event) => event.action), ["agent.created", "chat.sent"]);
  assert.equal(result.headers["x-content-sha256"], digest(result.body));
  assert.equal(Number(result.headers["content-length"]), Buffer.byteLength(result.body));
  assert.match(result.headers["content-disposition"], /^attachment; filename="moontown-building-[a-f0-9]{12}\.json"$/);
  assert.equal("users" in packet.source, false);
  assert.equal("sessions" in packet.source, false);
  assert.equal(result.body.includes("book-policy-hall"), false);
  assert.deepEqual(state, before);
});

test("readable Markdown preserves conversation text as inert code and reports recorded status", () => {
  const state = prepare();
  state.messages.find((message) => message.threadId === "thread-private-lab").body = "中文 plan\n# forged heading\n<script>alert(1)</script>\n```\n[link](https://example.invalid)";
  const preview = inspect(state).body;
  const result = request(state, "GET", preview.downloads.markdown);
  assert.equal(result.status, 200);
  assert.equal(result.headers["content-type"], "text/markdown; charset=utf-8");
  assert.match(result.body, /    中文 plan\n    # forged heading\n    <script>/);
  assert.match(result.body, /    ```\n    \[link\]/);
  assert.match(result.body, /"status": "waiting_review"/);
  assert.match(result.body, /Not accepted Book knowledge/);
  assert.match(result.body, new RegExp(preview.sourceDigest));
  assert.equal(result.body.includes("Policy Hall"), false);
});

test("archive discovery exports retained conversation without restoring or publishing", () => {
  const state = prepare();
  request(state, "POST", "/miniapp/buildings/archive", { buildingId: "private-lab" });
  const before = structuredClone(state);
  const archived = request(state, "GET", "/miniapp/buildings/archived").body.results[0];
  const preview = request(state, "GET", archived.reviewPacket.previewPath).body;
  const packet = JSON.parse(request(state, "GET", preview.downloads.json).body);
  assert.equal(packet.source.building.visibility, "archived");
  assert.equal(packet.source.messages.length, 1);
  assert.equal(packet.source.auditEvents.at(-1).action, "building.archived");
  assert.equal(request(state, "GET", "/miniapp/town/snapshot").body.reviewPackets.some((action) => action.buildingId === "private-lab"), false);
  assert.deepEqual(state, before);
});

test("empty buildings still export valid packets with explicit empty sections", () => {
  const state = initialState();
  const preview = inspect(state, "team-studio", "user-b").body;
  assert.equal(preview.counts.messages, 0);
  const json = request(state, "GET", preview.downloads.json, {}, "user-b");
  assert.deepEqual(JSON.parse(json.body).source.messages, []);
  const markdown = request(state, "GET", preview.downloads.markdown, {}, "user-b");
  assert.match(markdown.body, /No retained conversations/);
  assert.match(markdown.body, /## Runs \(recorded statuses\) \(0\)/);
});

test("new messages and changed runs invalidate an inspected download even without building version changes", () => {
  const state = prepare();
  const originalVersion = state.buildings.find((building) => building.id === "private-lab").version;
  const preview = inspect(state).body;
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", body: "New review context" });
  assert.equal(state.buildings.find((building) => building.id === "private-lab").version, originalVersion);
  assert.equal(request(state, "GET", preview.downloads.json).body.reason, "packet-source-changed");
  const refreshed = inspect(state).body;
  request(state, "POST", "/miniapp/runs/cancel", { runId: "lab-run", summary: "Stop pending work" });
  assert.equal(request(state, "GET", refreshed.downloads.markdown).status, 409);
  const current = inspect(state).body;
  assert.equal(JSON.parse(request(state, "GET", current.downloads.json).body).source.runs[0].status, "cancelled");
});

test("unrelated work and session changes do not invalidate the selected source projection", () => {
  const state = prepare();
  const preview = inspect(state).body;
  request(state, "POST", "/miniapp/auth/dev-login", { userId: "user-a" });
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "other-private-lab", body: "Another user's context" }, "user-b");
  assert.equal(inspect(state).body.sourceDigest, preview.sourceDigest);
  assert.equal(request(state, "GET", preview.downloads.json).status, 200);
});

test("the resolved session controls export and no private or system history is returned to other users", () => {
  const state = prepare();
  const preview = inspect(state).body;
  const session = request(state, "POST", "/miniapp/auth/dev-login", { userId: "user-b" }).body.session.id;
  const denied = request(state, "GET", preview.downloads.json, {}, "user-a", { "x-miniapp-session": session });
  assert.equal(denied.status, 404);
  assert.deepEqual(denied.body, inspect(state, "missing").body);
  assert.equal(request(state, "GET", preview.downloads.json, {}, "user-a", { "x-miniapp-session": "expired" }).status, 401);
});

test("download needs explicit selection and refuses unsupported formats without state changes", () => {
  const state = prepare();
  const before = structuredClone(state);
  assert.equal(request(state, "GET", "/miniapp/buildings/review-packet").status, 400);
  assert.equal(request(state, "GET", "/miniapp/buildings/review-packet?buildingId=private-lab&format=html").status, 400);
  assert.equal(request(state, "GET", "/miniapp/buildings/review-packet?buildingId=private-lab&format=json").body.reason, "inspected-source-digest-required");
  assert.deepEqual(state, before);
});

test("mixed conversation identities refuse export instead of including another building's context", () => {
  const state = prepare();
  request(state, "POST", "/miniapp/buildings/query", { buildingId: "team-studio", threadId: "thread-private-lab", body: "Conflicting thread identity" });
  const before = structuredClone(state);
  assert.equal(inspect(state).body.reason, "inconsistent-conversation-links");
  assert.deepEqual(state, before);
});

test("source size and retained-record limits fail without a partial packet", () => {
  const state = prepare();
  state.messages[1].body = "x".repeat(2 * 1024 * 1024);
  const large = inspect(state);
  assert.equal(large.status, 413);
  assert.equal(large.body.reason, "packet-source-byte-limit");
  assert.equal("downloads" in large.body, false);
  state.messages = Array.from({ length: 5001 }, (_, i) => ({ id: `message-${i}`, threadId: "thread-private-lab", body: "retained" }));
  assert.equal(inspect(state).body.reason, "packet-record-limit");
});

test("a valid large conversation previews but refuses oversized rendered output atomically", () => {
  const state = prepare();
  state.messages[1].body = "\n".repeat(850000);
  const preview = inspect(state);
  assert.equal(preview.status, 200);
  const before = structuredClone(state);
  const result = request(state, "GET", preview.body.downloads.markdown);
  assert.equal(result.status, 413);
  assert.equal(result.body.reason, "packet-output-byte-limit");
  assert.equal("headers" in result, false);
  assert.equal(request(state, "GET", preview.body.downloads.json).status, 200);
  assert.deepEqual(state, before);
});

test("service request listener exports files, reopens after restart, and never persists reads", async () => {
  const evidenceRoot = process.env.MOONTOWN_PACKET_TEST_EVIDENCE || os.tmpdir();
  fs.mkdirSync(evidenceRoot, { recursive: true });
  const directory = fs.mkdtempSync(path.join(evidenceRoot, "moontown-packet-"));
  console.log(`retained-packet-evidence=${directory}`);
  const statePath = path.join(directory, "state.json");
  const state = prepare();
  saveState(statePath, state);
  const bytesBefore = fs.readFileSync(statePath);
  let writes = 0;
  const server = createServer(state, () => { writes += 1; });
  const login = await serviceRequest(server, "POST", "/miniapp/auth/dev-login", { userId: "user-a" });
  const headers = { "x-miniapp-session": JSON.parse(login.text).session.id };
  const snapshot = JSON.parse((await serviceRequest(server, "GET", "/miniapp/town/snapshot", {}, headers)).text);
  const action = snapshot.reviewPackets.find((entry) => entry.buildingId === "private-lab");
  const preview = JSON.parse((await serviceRequest(server, "GET", action.previewPath, {}, headers)).text);
  for (const [format, route] of Object.entries(preview.downloads)) {
    const result = await serviceRequest(server, "GET", route, {}, headers);
    assert.equal(result.status, 200);
    assert.equal(result.headers["cache-control"], "no-store");
    assert.equal(result.headers["x-source-digest"], preview.sourceDigest);
    fs.writeFileSync(path.join(directory, `review.${format === "json" ? "json" : "md"}`), result.text, { flag: "wx" });
  }
  assert.equal(writes, 0);
  assert.deepEqual(fs.readFileSync(statePath), bytesBefore);
  const saved = JSON.parse(fs.readFileSync(path.join(directory, "review.json"), "utf8"));
  assert.equal(saved.source.messages[0].body, state.messages[1].body);
  const restarted = createServer(loadState(statePath), () => { writes += 1; });
  assert.equal((await serviceRequest(restarted, "GET", preview.downloads.json, {}, headers)).status, 401);
  const newLogin = JSON.parse((await serviceRequest(restarted, "POST", "/miniapp/auth/dev-login", { userId: "user-a" })).text);
  const reopened = await serviceRequest(restarted, "GET", preview.downloads.json, {}, { "x-miniapp-session": newLogin.session.id });
  assert.equal(reopened.status, 200);
  assert.equal(reopened.text, fs.readFileSync(path.join(directory, "review.json"), "utf8"));
  assert.deepEqual(fs.readFileSync(statePath), bytesBefore);
  assert.equal(writes, 0);
});
