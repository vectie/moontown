# Explore the retained-run review backlog

The existing Node mini-app development service now surfaces waiting-review and
failed runs together, oldest recorded update first. The town snapshot includes
the first five records, total and per-building counts, and links to continue or
inspect a run. You can find review debt without remembering a message's wording
or opening every building packet.

This is a read-only exploration workflow for MOONTOWN-B02's review surfacing and
MOONTOWN-B05's exact-record inspection. It is based on retained fixture state,
not a live worker poll, a review decision or accepted MoonBook knowledge. The
native mini-app adapter and Rabbita UI have not been wired to these new routes.

## Start, discover, narrow and inspect

Use Node 18+ with no package installation:

```sh
node scripts/miniapp-local-backend.mjs --state /absolute/path/town-state.json --port 18191
```

The existing service binds to loopback. Keep the same state path to reopen work;
do not use `--reset-state` on work you want to keep. Its caller-selected development
identities and organization scope are unchanged and are not production security.
Do not expose this service to untrusted users.

In another terminal, start `node` and use its built-in fetch:

```js
const base = 'http://127.0.0.1:18191';
const login = await fetch(base + '/miniapp/auth/dev-login', {
  method: 'POST', headers: {'content-type': 'application/json'},
  body: JSON.stringify({userId: 'user-a'})
}).then(response => response.json());
const get = async route => {
  const response = await fetch(base + route, {headers: {'x-miniapp-session': login.session.id}});
  const result = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(result));
  return result;
};
const snapshot = await get('/miniapp/town/snapshot');
console.dir(snapshot.runInbox.preview, {depth: null});
const page = await get(snapshot.runInbox.path + '?owner=mine&status=attention&minAgeMs=86400000');
console.dir(page.groups); // Full matched backlog counts, not only this page.
console.dir(page.results, {depth: null});
if (page.results.length) {
  const inspection = await get(page.results[0].inspectPath);
  console.dir(inspection, {depth: null});
}
if (page.nextPath) console.dir(await get(page.nextPath), {depth: null});
```

The default initial fixture contains one Policy Hall run waiting for review.
The minimum-age example asks for runs with a recorded update at least one day
ago. Omit `minAgeMs` to retain runs whose timestamp is unknown too. An empty
result is explicitly `totalMatches: 0`, `results: []`, `nextPath: null`.

To explore a single currently visible building or completed work, for example:

```js
await get('/miniapp/runs/inbox?buildingId=private-lab&status=all');
await get('/miniapp/runs/inbox?owner=mine&status=done');
```

No query in this guide accepts, cancels or retries a run. Existing mutation
routes remain separate. Even a stored `done` status is a record label, not proof
that a real provider ran or an owning Book accepted its contents.

## Selection and age meanings

`GET /miniapp/runs/inbox` accepts:

- `status`: `attention` (default, exactly `waiting_review` or `failed`),
  `waiting_review`, `failed`, `pending`, `running`, `done`, `cancelled`, or `all`.
  Unknown future stored status labels remain visible under `all`; they are not
  silently classified as actionable.
- `owner`: `all` (default, within currently visible buildings) or `mine`
  (run `userId` exactly matches the resolved fixture user).
- `buildingId`: optional exact ID of a currently visible, unarchived building.
  Unknown, private-to-another-user and archived selections return 404.
- `asOfMs`: optional nonnegative safe-integer Unix milliseconds; defaults to the
  service clock when that request is read. The response retains it in `filters`.
  This is an age reference applied to current retained records, not a historical
  snapshot or proof that the worker was observed at that instant.
- `minAgeMs`: optional nonnegative safe integer; inclusive minimum elapsed time
  since the recorded `updatedAtMs`. Supplying zero still excludes unknown and
  after-as-of timestamps because they have no comparable age.
- `limit`: 1–100, default 50. `offset`: nonnegative safe integer, default 0.
  Continuation pages require the original `asOfMs` and `expectedDigest`.

Age never substitutes `createdAtMs` for a missing update. Missing, null, string,
negative, fractional or unsafe update timestamps produce `timestampState:
"unknown"` and `ageMs: null`. A valid timestamp later than `asOfMs` produces
`"after-as-of"` and null age. These records remain at the end when no numeric
minimum age is requested. Known ages sort largest first, ties by exact run ID;
unknown/future rows also sort by exact ID. Source array order is not priority.
Age is not time spent in the current status, a stale-worker diagnosis, an SLA,
or a claim that nothing happened since that update.

`statusCounts` describes all candidate runs after visibility, owner and building
selection, before status/age filtering. `groups` describes all matched rows after
all filters, including counts, oldest known age and unknown/after-as-of counts
per building. Both span every page. Only `results` is paginated.

## Freshness, linked context and recovery

`sourceDigest` pins the user, filters (including the frozen age reference) and
selected run/building/thread projections. Follow the exact `nextPath` and resend
your existing session header separately. Paths contain neither session tokens
nor caller identity parameters. A changed run, relevant building/thread metadata,
visibility or selection returns 409 rather than mixing pages. Restart from the
inbox path to get a fresh view; the old page remains historical evidence.

Every result includes `runDigest` and a bound `inspectPath`. The inspection route
requires both the exact run ID and that digest. It rechecks current visibility
and the selected run/building/thread projection, then returns:

- The same selected run, building and thread records
- All currently retained messages in the linked thread, in saved order
- Audit events whose `objectKind` is exactly `run` and `objectId` is that run ID
- A separate `sourceDigest` over the complete inspection source

Messages are thread context, not a per-run transcript: the fixture does not have
a message-to-run key. Context is captured at inspection time, so a later message
can change the inspection digest without changing the inbox run digest. A missing
thread is retained as a named `thread-not-retained` gap with no messages. Crossed
run/thread building links fail explicitly. Text is inert data; clients must render
it as plain text, never HTML. Digests are local integrity labels, not signatures.

Archiving a building removes its runs from this view. Restoring it returns the
same run identities with a fresh building version. A reviewed/cancelled run leaves
the default attention view and remains discoverable with an explicit status or
`all`. Stop and reopen the existing service with the same saved state path to
recover the same records. Reading does not write a state file or create an audit
entry. Sessions remain in-memory and must be renewed after restart.

## Bounds and verified scope

Each needed state array is capped at 20,000 records; the selected source and
serialized output are capped at 4 MiB each. Duplicate/missing record IDs, crossed
conversation links and exceeded bounds fail explicitly. Snapshot inspection
exposes inbox failures in `runInbox.preview.ok/reason` instead of presenting an
empty healthy backlog; its other existing snapshot fields remain available.

Run the focused and adjacent dependency-free tests from the repository root:

```sh
node --test scripts/miniapp-run-inbox.test.mjs scripts/miniapp-session-retention.test.mjs scripts/miniapp-archive-recovery.test.mjs scripts/miniapp-review-packet.test.mjs scripts/miniapp-conversation-search.test.mjs scripts/miniapp-building-profile.test.mjs
```

The inbox suite exercises actual route dispatch and HTTP request-listener
serialization without binding a socket, plus saved-state reopen and byte-preserving
reads. `MOONTOWN_INBOX_EVIDENCE` may point to an existing directory for retained
state, inbox and inspection JSON evidence; otherwise it uses the OS temporary
directory. No network, browser, native MoonBit execution, production identity,
provider, full-product qualification, or owning-Book acceptance is implied.
