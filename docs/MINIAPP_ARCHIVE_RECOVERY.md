# Recover archived buildings in the local mini-app development service

This workflow belongs only to `scripts/miniapp-local-backend.mjs`, the existing
loopback-only, dependency-free Node development fixture. It does not connect to
canonical MoonTown/MoonBook ledgers, the native mini-app server or a live UI.
The service has development identities and an intentional caller-selected user
fallback; it is not a production authentication or multi-tenant security boundary.
See [the frontend adapter boundary](project/FRONTEND_ADAPTER_ARCHITECTURE.md).

## Why use it

An archived building disappears from the normal town snapshot. You can now find
that archived building, inspect the history still attached to it, and recover
its same identity without hand-editing the saved JSON. Conversation messages,
agent configuration, placements, run status and book reference are retained.
No run is dispatched or retried, and no book knowledge is accepted.

## Run and inspect

Use Node 18 or later. No npm packages or MoonBit compilation are needed. Choose
a new state filename for a demo; omit `--reset-state` when reopening real local
fixture work. Stop with Ctrl-C and restart with the same file to reopen it.

```sh
node scripts/miniapp-local-backend.mjs --state /tmp/moontown-recovery-demo.json --port 18191
```

In another terminal, open `node` and paste these lines. They log in to the local
fixture, create a demonstration building, retain a question, archive it, then
inspect the archive. If reusing the same state, skip creation when the building
already exists, or choose a new ID. Node's interactive console supports await.

```js
const base = 'http://127.0.0.1:18191';
const post = async (route, body) => {
  const response = await fetch(base + route, {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(result));
  return result;
};
const login = await post('/miniapp/auth/dev-login', {userId: 'user-a'});
const sessionId = login.session.id;
await post('/miniapp/buildings', {sessionId, id: 'recovery-demo', title: 'Recovered project studio'});
await post('/miniapp/buildings/query', {sessionId, buildingId: 'recovery-demo', body: 'Keep the project decision context.'});
await post('/miniapp/buildings/archive', {sessionId, buildingId: 'recovery-demo'});
const response = await fetch(base + '/miniapp/buildings/archived?query=recovery-demo', {headers: {'x-miniapp-session': sessionId}});
const archive = await response.json();
console.dir(archive, {depth: null});
```

The list includes `building.version`, the exact `restoreVisibility`, and counts
of retained placements, agents, threads, messages and runs. These are record
counts, not business outcomes. An empty list means no editable archived building
matched. The optional query matches building ID, title or tags, ignoring case and
surrounding query whitespace. Results sort by latest building update, then ID.

After inspecting the selected record and deciding to restore it, run:

```js
const selected = archive.results.find(entry => entry.building.id === 'recovery-demo');
if (!selected) throw new Error('Refresh the archive list and select a building.');
const restored = await post('/miniapp/buildings/restore', {sessionId, buildingId: selected.building.id, expectedVersion: selected.building.version});
console.dir(restored, {depth: null});
const snapshot = await (await fetch(base + '/miniapp/town/snapshot', {headers: {'x-miniapp-session': sessionId}})).json();
console.dir(snapshot.buildings.find(building => building.id === 'recovery-demo'));
console.dir(snapshot.messages.filter(message => message.threadId === 'thread-recovery-demo'));
```

The normal snapshot now contains the building and its conversation again. Stop
and reopen the service with the same state path to verify persistence; dev
sessions are memory-only, so log in again after restart.

## API and lifecycle

- `GET /miniapp/buildings/archived?query=...`: returns `kind: archived-buildings`,
  the resolved fixture `userId`, query and `results`. Only archived buildings the
  current user can edit are included. Reading does not persist or add events.
- `POST /miniapp/buildings/restore`: requires `buildingId` and the positive
  integer `expectedVersion` read from the archive. It restores one exact record,
  increases its version once, updates its timestamp, and appends one
  `building.restored` audit event through the existing persistence path.
- A personal owner's building returns to `private_draft`, even if it was public
  before archival. The caller cannot select `published` in the restore request.
- An `org-a` building returns to `shared_private`. Both built-in users have the
  service's existing fixture organization edit authority. No new ownership,
  grants or membership are created. Public publication remains a separate action.
- Other users' personal archives are absent from the list. Unknown and
  non-editable restoration targets return 404 without their records. An explicit
  session resolves the user even when a conflicting caller user field is given.
- Missing/invalid building ID or version returns 400. A non-archived record or a
  changed version returns 409. Refresh the archive and inspect the new state
  before deciding again. Repeating a successful restore returns 409 and does not
  append a second event. A later archive can be restored with its new version.

The version-1 state schema is unchanged. Existing archived records need no new
archive metadata and can be restored. All previous records remain in the file;
this operation is recovery, not deletion or backup restoration. The local
service's existing fixture-only publication and write behavior is unchanged.
There is no production publishing/review qualification, canonical ledger
migration, rendered UI, daemon recovery, live provider run or accepted MoonBook
outcome in this feature.

## Verification

From the repository root:

```sh
node --check scripts/miniapp-local-backend.mjs
node --test scripts/miniapp-archive-recovery.test.mjs scripts/miniapp-session-retention.test.mjs
```

The tests cover the list–inspect–restore loop, previously public buildings,
fixture organization scope, session identity, stale selection, retained records,
old state compatibility and persistence/reload through the actual HTTP request
listener. The portable listener test emits in-process requests without a
listening socket; it does not qualify network transport or a client UI.

## Product rationale

MOONTOWN-UC05/B05 in the 30 September 2026 product PRD calls for exact durable
record inspection and bounded intervention. This local development workflow
makes a previously hidden record actionable with its inspected version.
[PRODUCT_CONTRACT](PRODUCT_CONTRACT.md) preserves town state and authority;
[Wenyu PRD](WENYU_VALLEY_PRD.md) §2 and §8 retain knowledge ownership and
publication/privacy boundaries. None of these broader requirements is marked
complete by a fixture restore. The implementation plan is
[archive recovery plan](plans/2026-10-11-miniapp-archive-recovery.md).

A separate executable loopback transport/restart check is available where local
listening sockets are allowed:

```sh
node --test scripts/miniapp-archive-http.test.mjs
```

Both persistence tests retain their generated state instead of deleting it. Set
`MOONTOWN_ARCHIVE_TEST_EVIDENCE` to a chosen evidence directory, or find the
printed `retained-*-evidence` path under the system temporary directory. The
loopback test additionally saves response records with login tokens omitted.
These files are development fixture evidence, not production backups.

## Review without restoring

Each archived entry now exposes a `reviewPacket` action for a [source-bound JSON/Markdown export](MINIAPP_REVIEW_PACKETS.md). Use it to inspect the retained conversation, run records and scoped audit history offline without changing the archive state.

## Correct an archived profile

Archived entries also expose `profileEdit` for a [reviewed title, summary or tag
correction](MINIAPP_BUILDING_PROFILE.md). Editing keeps the record archived and
retains its identity and history; restoring remains a separate action.
