import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createHash } from "node:crypto";
import { Readable } from "node:stream";
import { initialState, routeRequest, createServer, saveState, loadState } from "./miniapp-local-backend.mjs";

const hash = (text) => createHash("sha256").update(text).digest("hex");
function request(state, route, userId = "user-a", body = {}, method = "GET") {
  const url = new URL(route, "http://localhost"); url.searchParams.set("userId", userId);
  return routeRequest(state, method, url, body, {});
}
function prepare() {
  const state = initialState();
  for (const [buildingId, text, id, user] of [
    ["private-lab", "Budget [draft].* 月 ready", "private-msg", "user-a"],
    ["team-studio", "Budget shared discussion", "team-msg", "user-a"],
    ["other-private-lab", "Budget secret discussion", "other-msg", "user-b"],
  ]) {
    request(state, "/miniapp/buildings/query", user, { buildingId, messageId: id, body: text }, "POST");
  }
  state.messages.forEach((message, index) => { message.createdAtMs = 1000 + index; });
  return state;
}
function search(state, options = "query=Budget", user = "user-a") {
  return request(state, `/miniapp/conversations/search?${options}`, user);
}

test("discover, search scoped records, inspect exact message and linked recorded run", () => {
  const state = prepare(), before = structuredClone(state);
  const discovery = request(state, "/miniapp/town/snapshot").body.conversationSearch;
  assert.equal(discovery.path, "/miniapp/conversations/search");
  const result = search(state).body;
  assert.equal(result.totalMatches, 2);
  assert.deepEqual(result.results.map((row) => row.messageId), ["team-msg", "private-msg"]);
  const row = result.results[1];
  assert.equal(row.buildingId, "private-lab");
  assert.equal(row.runs[0].status, "waiting_review");
  assert.equal(row.runs[0].threadId, row.threadId);
  const snapshot = request(state, row.inspectPath).body;
  const message = snapshot.messages.find((item) => item.id === row.messageId);
  assert.equal(row.textDigest, hash(message.body));
  assert.equal(row.excerpt, message.body);
  assert.equal(row.matchStart, 0);
  assert.deepEqual(state, before);
});

test("literal punctuation, Unicode, case option, exact building and actor filters", () => {
  const state = prepare();
  assert.equal(search(state, "query=" + encodeURIComponent("[draft].* 月")).body.totalMatches, 1);
  assert.equal(search(state, "query=budget").body.totalMatches, 0);
  assert.equal(search(state, "query=budget&case=insensitive").body.totalMatches, 2);
  assert.equal(search(state, "query=Budget&buildingId=private-lab&actorId=user-a").body.totalMatches, 1);
  assert.equal(search(state, "query=Budget&actorId=user-b").body.totalMatches, 0);
  assert.equal(search(state, "query=Budget&buildingId=other-private-lab").status, 404);
  assert.deepEqual(search(state, "query=Budget", "user-b").body.results.map((row) => row.messageId), ["other-msg", "team-msg"]);
});

test("archive hides conversations and restore makes same message discoverable", () => {
  const state = prepare();
  request(state, "/miniapp/buildings/archive", "user-a", { buildingId: "private-lab" }, "POST");
  assert.equal(search(state).body.totalMatches, 1);
  assert.equal(search(state, "query=Budget&buildingId=private-lab").status, 404);
  request(state, "/miniapp/buildings/restore", "user-a", { buildingId: "private-lab", expectedVersion: state.buildings.find(b => b.id === "private-lab").version }, "POST");
  // Use the actual restore contract's version field where required.
  assert.equal(search(state).body.totalMatches, 2);
});

test("digest-bound pagination detects changed messages and preserves total coverage", () => {
  const state = prepare();
  const first = search(state, "query=Budget&limit=1").body;
  assert.equal(first.totalMatches, 2);
  assert.ok(first.nextPath);
  const second = request(state, first.nextPath).body;
  assert.equal(second.results[0].messageId, "private-msg");
  assert.equal(second.nextPath, null);
  assert.equal(second.sourceDigest, first.sourceDigest);
  assert.equal(search(state, "query=Budget&offset=1").status, 400);
  state.messages.find((row) => row.id === "private-msg").body += " edited";
  assert.equal(request(state, first.nextPath).status, 409);
});

test("reopen persisted state returns identical search and saves readable evidence", () => {
  const state = prepare();
  const root = fs.mkdtempSync(path.join(process.env.MOONTOWN_SEARCH_EVIDENCE || os.tmpdir(), "moontown-search-"));
  const file = path.join(root, "state.json");
  saveState(file, state);
  const before = fs.readFileSync(file);
  const result = search(loadState(file)).body;
  fs.writeFileSync(path.join(root, "search.json"), JSON.stringify(result, null, 2));
  assert.deepEqual(result, search(state).body);
  assert.deepEqual(fs.readFileSync(file), before);
  console.log("Retained search evidence: " + root);
});

test("long text returns bounded plain-text excerpt with exact UTF-16 offsets", () => {
  const state = prepare();
  const body = "x".repeat(300) + "<script>Budget</script>" + "y".repeat(400);
  state.messages.find(row => row.id === "private-msg").body = body;
  const row = search(state, "query=Budget&buildingId=private-lab").body.results[0];
  assert.equal(row.matchStart, 308);
  assert.equal(row.matchLength, 6);
  assert.equal(row.excerptStart, 228);
  assert.equal(row.excerpt, body.slice(228, 474));
  assert.equal(row.excerptTruncated, true);
  assert.equal(row.textDigest, hash(body));
});

test("empty results and invalid queries are explicit", () => {
  const state = prepare();
  const empty = search(state, "query=absent").body;
  assert.equal(empty.totalMatches, 0); assert.deepEqual(empty.results, []); assert.equal(empty.nextPath, null);
  for (const options of ["", "query=%20", "query=x&limit=0", "query=x&offset=-1", "query=x&case=unknown"])
    assert.equal(search(state, options).status, 400);
});

test("crossed source links refuse and source caps never silently truncate", () => {
  const state = prepare();
  state.runs.find(row => row.buildingId === "private-lab").buildingId = "other-private-lab";
  assert.equal(search(state).status, 409);
  const big = prepare(); big.messages[1].body = "x".repeat(4 * 1024 * 1024);
  assert.equal(search(big).status, 413);
});

test("actual service listener serializes search without persisting or listening on a socket", async () => {
  const state = prepare(); let persists = 0;
  const server = createServer(state, () => { persists++; });
  const response = await new Promise((resolve, reject) => {
    const req = Readable.from([]);
    Object.assign(req, { method: "GET", url: "/miniapp/conversations/search?query=Budget", headers: {} });
    req.on("error", reject);
    const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; },
      writeHead(status, headers) { this.status = status; Object.assign(this.headers, headers); },
      end(text) { resolve({ status: this.status, text }); } };
    server.emit("request", req, res);
  });
  assert.equal(response.status, 200);
  assert.equal(JSON.parse(response.text).totalMatches, 2);
  assert.equal(persists, 0);
});
