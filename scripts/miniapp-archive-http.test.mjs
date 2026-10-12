import test from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createServer, loadState, saveState } from "./miniapp-local-backend.mjs";

test("loopback HTTP archive, inspect, restore and service restart preserve the exact record", async (t) => {
  const evidenceRoot = process.env.MOONTOWN_ARCHIVE_TEST_EVIDENCE || os.tmpdir();
  fs.mkdirSync(evidenceRoot, { recursive: true });
  const directory = fs.mkdtempSync(path.join(evidenceRoot, "moontown-archive-http-"));
  const statePath = path.join(directory, "state.json");
  const transcript = path.join(directory, "responses.jsonl");
  console.log(`retained-http-evidence=${directory}`);
  const servers = [];
  t.after(async () => {
    for (const server of servers) {
      if (server.listening) await new Promise((resolve) => server.close(resolve));
    }
  });
  async function start() {
    const server = createServer(loadState(statePath), (state) => saveState(statePath, state));
    servers.push(server);
    await new Promise((resolve, reject) => {
      server.once("error", reject);
      server.listen(0, "127.0.0.1", resolve);
    });
    return { server, base: `http://127.0.0.1:${server.address().port}` };
  }
  async function call(base, method, route, body = {}, sessionId = "") {
    const response = await fetch(base + route, {
      method,
      headers: { "content-type": "application/json", "x-miniapp-session": sessionId },
      ...(method === "POST" ? { body: JSON.stringify(body) } : {}),
    });
    const result = await response.json();
    const evidence = route === "/miniapp/auth/dev-login" ? { user: result.user } : result;
    fs.appendFileSync(transcript, JSON.stringify({ method, route, status: response.status, body: evidence }) + "\n");
    assert.equal(response.status, 200, JSON.stringify(result));
    return result;
  }
  const first = await start();
  const session = (await call(first.base, "POST", "/miniapp/auth/dev-login", { userId: "user-a" })).session.id;
  await call(first.base, "POST", "/miniapp/buildings/query", { buildingId: "private-lab", body: "Recover this exact question" }, session);
  await call(first.base, "POST", "/miniapp/buildings/archive", { buildingId: "private-lab" }, session);
  const selected = (await call(first.base, "GET", "/miniapp/buildings/archived", {}, session)).results[0];
  assert.equal(selected.retained.messages, 1);
  const restored = await call(first.base, "POST", "/miniapp/buildings/restore", {
    buildingId: selected.building.id, expectedVersion: selected.building.version,
  }, session);
  assert.equal(restored.building.visibility, "private_draft");
  await new Promise((resolve) => first.server.close(resolve));
  const second = await start();
  const newSession = (await call(second.base, "POST", "/miniapp/auth/dev-login", { userId: "user-a" })).session.id;
  const snapshot = await call(second.base, "GET", "/miniapp/town/snapshot", {}, newSession);
  assert.deepEqual(snapshot.buildings.find((item) => item.id === "private-lab"), restored.building);
  assert.equal(snapshot.messages.some((message) => message.body === "Recover this exact question"), true);
  assert.equal(snapshot.auditEvents.filter((event) => event.action === "building.restored").length, 1);
  assert.equal((await call(second.base, "GET", "/miniapp/buildings/archived", {}, newSession)).results.length, 0);
});
