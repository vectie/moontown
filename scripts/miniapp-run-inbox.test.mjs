import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import { createHash } from "node:crypto";
import { initialState, routeRequest, createServer, saveState, loadState } from "./miniapp-local-backend.mjs";
import { runInbox } from "./miniapp-run-inbox.mjs";

const hash = value => createHash("sha256").update(JSON.stringify(value)).digest("hex");
function request(state, route, userId = "user-a", body = {}, method = "GET") {
  const url = new URL(route, "http://localhost"); url.searchParams.set("userId", userId);
  return routeRequest(state, method, url, body, {});
}
const inbox = (state, options = "", user = "user-a") => request(state, `/miniapp/runs/inbox?asOfMs=10000&${options}`, user);
function prepare() {
  const state = initialState();
  for (const [id, buildingId, status, updatedAtMs, user] of [
    ["run-private-old", "private-lab", "waiting_review", 1000, "user-a"],
    ["run-team-failed", "team-studio", "failed", 2000, "user-b"],
    ["run-private-done", "private-lab", "done", 3000, "user-a"],
    ["run-hidden", "other-private-lab", "waiting_review", 0, "user-b"],
  ]) {
    const created = request(state, "/miniapp/buildings/query", user, { buildingId, runId: id, messageId: `message-${id}`,
      body: `Question for ${id} <tag> 月`, answerSummary: `Summary ${id}` }, "POST");
    assert.equal(created.status, 200);
    Object.assign(created.body.run, { status, updatedAtMs, createdAtMs: 0 });
  }
  return state;
}

test("town snapshot embeds actionable backlog, counts and exact run inspection links", () => {
  const state = prepare(), before = structuredClone(state);
  const discovery = request(state, "/miniapp/town/snapshot").body.runInbox;
  assert.equal(discovery.path, "/miniapp/runs/inbox");
  assert.equal(discovery.preview.totalMatches, 3);
  assert.deepEqual(discovery.preview.results.map(item => item.run.id), ["run-private-old", "run-team-failed", "run-policy-hall-1"]);
  assert.ok(discovery.preview.filters.asOfMs > 10000);
  const result = inbox(state).body;
  assert.deepEqual(result.statusCounts, [{ status: "done", count: 1 }, { status: "failed", count: 1 }, { status: "waiting_review", count: 2 }]);
  assert.equal(result.groups[0].oldestAgeMs, 9000);
  const row = result.results[0];
  assert.equal(row.runDigest, hash({ building: row.building, run: row.run, thread: row.thread }));
  const detail = request(state, row.inspectPath).body;
  assert.equal(detail.source.run.id, row.run.id);
  assert.equal(detail.source.messages.length, 2); // Shared thread, not a per-run transcript.
  assert.equal(detail.source.auditEvents.length, 1);
  assert.equal(detail.source.auditEvents[0].objectId, row.run.id);
  assert.equal(detail.sourceDigest, hash(detail.source));
  assert.match(detail.contextMeaning, /not a run-specific transcript/);
  assert.deepEqual(state, before);
});

test("status, owner, building and inclusive minimum recorded age combine", () => {
  const state = prepare();
  assert.deepEqual(inbox(state, "owner=mine&minAgeMs=9000").body.results.map(item => item.run.id), ["run-private-old"]);
  assert.equal(inbox(state, "status=all&buildingId=private-lab").body.totalMatches, 2);
  assert.deepEqual(inbox(state, "status=done").body.results.map(item => item.run.id), ["run-private-done"]);
  assert.equal(inbox(state, "minAgeMs=9001").body.totalMatches, 0);
  assert.equal(inbox(state, "status=running").body.nextPath, null);
  assert.equal(inbox(state, "buildingId=other-private-lab").status, 404);
  const other = inbox(state, "", "user-b").body.results.map(item => item.run.id);
  assert.ok(other.includes("run-hidden")); assert.ok(!other.includes("run-private-old"));
});

test("missing, invalid and future update times remain distinct from numeric age", () => {
  const state = prepare();
  delete state.runs.find(item => item.id === "run-private-old").updatedAtMs;
  state.runs.find(item => item.id === "run-team-failed").updatedAtMs = 12000;
  const result = inbox(state).body;
  assert.deepEqual(result.results.map(item => [item.run.id, item.timestampState, item.ageMs]), [
    ["run-policy-hall-1", "known", 7500], ["run-private-old", "unknown", null], ["run-team-failed", "after-as-of", null],
  ]);
  assert.equal(result.groups.find(item => item.buildingId === "private-lab").unknownTimestampCount, 1);
  assert.equal(result.groups.find(item => item.buildingId === "team-studio").afterAsOfCount, 1);
  assert.equal(inbox(state, "minAgeMs=0").body.totalMatches, 1);
  state.runs[0].updatedAtMs = "2500";
  assert.equal(inbox(state, "minAgeMs=0").body.totalMatches, 0);
});

test("stable age/id ordering and digest-bound pages cover the full backlog", () => {
  const state = prepare();
  state.runs.find(item => item.id === "run-team-failed").updatedAtMs = 1000;
  const first = inbox(state, "limit=1").body;
  assert.ok(first.nextPath.includes("asOfMs=10000"));
  const second = request(state, first.nextPath).body;
  const third = request(state, second.nextPath).body;
  assert.deepEqual([first, second, third].map(page => page.results[0].run.id), ["run-private-old", "run-team-failed", "run-policy-hall-1"]);
  assert.equal(third.nextPath, null);
  state.runs.reverse();
  assert.equal(inbox(state, "limit=1").body.sourceDigest, first.sourceDigest);
  state.runs.find(item => item.id === "run-private-old").status = "done";
  assert.equal(request(state, first.nextPath).status, 409);
  assert.equal(inbox(state, "offset=1").status, 400);
});

test("snapshot first-five preview continues to remaining records", () => {
  const state = prepare();
  const prototype = state.runs.find(item => item.id === "run-private-old");
  for (let i = 0; i < 5; i++) state.runs.push({ ...prototype, id: `run-extra-${i}`, updatedAtMs: i });
  const preview = request(state, "/miniapp/town/snapshot").body.runInbox.preview;
  assert.equal(preview.totalMatches, 8); assert.equal(preview.results.length, 5);
  const rest = request(state, preview.nextPath).body;
  assert.equal(rest.results.length, 3); assert.equal(rest.sourceDigest, preview.sourceDigest);
  assert.equal(new Set([...preview.results, ...rest.results].map(item => item.run.id)).size, 8);
});

test("archive hides the run and restore returns the same retained record", () => {
  const state = prepare(), selected = inbox(state).body.results[0];
  const first = inbox(state, "limit=1").body;
  request(state, "/miniapp/buildings/archive", "user-a", { buildingId: "private-lab" }, "POST");
  assert.equal(inbox(state).body.totalMatches, 2);
  assert.equal(request(state, selected.inspectPath).status, 404);
  assert.equal(request(state, first.nextPath).status, 409);
  const building = state.buildings.find(item => item.id === "private-lab");
  request(state, "/miniapp/buildings/restore", "user-a", { buildingId: building.id, expectedVersion: building.version }, "POST");
  const reopened = inbox(state).body.results.find(item => item.run.id === selected.run.id);
  assert.deepEqual(reopened.run, selected.run);
  assert.equal(request(state, selected.inspectPath).status, 409); // Building identity version changed.
  assert.equal(request(state, reopened.inspectPath).status, 200);
});

test("reviewed run exits backlog and stale inspection requests cannot relabel it", () => {
  const state = prepare(), row = inbox(state).body.results[0];
  request(state, "/miniapp/reviews/accept", "user-a", { runId: row.run.id }, "POST");
  assert.equal(inbox(state).body.totalMatches, 2);
  assert.equal(request(state, row.inspectPath).status, 409);
  const done = inbox(state, "status=done").body.results.find(item => item.run.id === row.run.id);
  assert.equal(done.run.status, "done");
  const detail = request(state, done.inspectPath).body;
  assert.ok(detail.source.auditEvents.some(item => item.action === "review.accepted"));
  assert.match(detail.qualification, /records only/);
});

test("conversation context is current, source-bound and explicitly missing when unretained", () => {
  const state = prepare(), selected = inbox(state).body.results[0];
  const first = request(state, selected.inspectPath).body;
  state.messages.find(item => item.threadId === selected.thread.id).body += " new context";
  const second = request(state, selected.inspectPath).body;
  assert.equal(first.runDigest, second.runDigest); assert.notEqual(first.sourceDigest, second.sourceDigest);
  state.threads = state.threads.filter(item => item.id !== selected.thread.id);
  const row = inbox(state).body.results.find(item => item.run.id === selected.run.id);
  assert.equal(row.thread, null);
  const missing = request(state, row.inspectPath).body;
  assert.deepEqual(missing.gaps, ["thread-not-retained"]); assert.deepEqual(missing.source.messages, []);
});

test("saved state reopens identically and read-only inspection leaves file bytes intact", () => {
  const state = prepare();
  const root = fs.mkdtempSync(path.join(process.env.MOONTOWN_INBOX_EVIDENCE || os.tmpdir(), "moontown-inbox-"));
  const file = path.join(root, "state.json"); saveState(file, state);
  const before = fs.readFileSync(file), reopened = loadState(file), result = inbox(reopened).body;
  const detail = request(reopened, result.results[0].inspectPath).body;
  fs.writeFileSync(path.join(root, "inbox.json"), JSON.stringify(result, null, 2) + "\n");
  fs.writeFileSync(path.join(root, "run-context.json"), JSON.stringify(detail, null, 2) + "\n");
  assert.deepEqual(result, inbox(state).body);
  assert.deepEqual(fs.readFileSync(file), before);
  console.log("Retained inbox evidence: " + root);
});

test("malformed options, crossed links and bounded evidence report explicit failures", () => {
  const state = prepare();
  assert.equal(inbox(state, "status=bogus").status, 400);
  assert.equal(inbox(state, "limit=0").status, 400);
  assert.equal(inbox(state, "minAgeMs=-1").status, 400);
  assert.equal(runInbox(state, "user-a", new URLSearchParams("asOfMs=1.5")).status, 400);
  const row = inbox(state).body.results[0];
  assert.equal(request(state, "/miniapp/runs/inspect?runId=" + row.run.id).status, 400);
  state.threads.find(item => item.id === row.thread.id).buildingId = "other-private-lab";
  assert.equal(inbox(state).status, 409);
  assert.equal(request(state, row.inspectPath).status, 409);
  const large = prepare(); large.runs[0].summary = "x".repeat(4 * 1024 * 1024);
  assert.equal(inbox(large).status, 413);
});

test("generated next and inspect links omit session and unrecognized query data", () => {
  const state = prepare();
  const page = inbox(state, "limit=1&secret=not-for-links").body;
  assert.ok(!page.nextPath.includes("secret")); assert.ok(!page.nextPath.includes("userId"));
  assert.ok(!page.results[0].inspectPath.includes("userId"));
});

test("real service listener serializes inbox and inspection without persistence or sockets", async () => {
  const state = prepare(); let persists = 0;
  const server = createServer(state, () => { persists++; });
  async function get(route) {
    return new Promise((resolve, reject) => {
      const req = Readable.from([]); Object.assign(req, { method: "GET", url: route, headers: {} }); req.on("error", reject);
      const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; },
        writeHead(status, headers) { this.status = status; Object.assign(this.headers, headers); },
        end(text) { resolve({ status: this.status, headers: this.headers, body: JSON.parse(text) }); } };
      server.emit("request", req, res);
    });
  }
  const page = await get("/miniapp/runs/inbox?asOfMs=10000");
  assert.equal(page.status, 200); assert.equal(page.headers["cache-control"], "no-store");
  const inspected = await get(page.body.results[0].inspectPath);
  assert.equal(inspected.status, 200); assert.equal(inspected.body.source.messages.length, 2);
  const denied = await get("/miniapp/runs/inbox?sessionId=expired");
  assert.equal(denied.status, 401); assert.equal(persists, 0);
});
