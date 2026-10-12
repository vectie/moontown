# Review and correct a retained building profile

Owners can correct a building's title, summary and search tags through the
existing Node mini-app development service. Inspect a before/after preview,
apply that exact version, then find the same building with its updated name.
Conversation, placement, agent, run and book references keep their identities.
There is no need to recreate a building or hand-edit its state file.

This is a bounded local fixture workflow under the original MoonTown PRD
MOONTOWN-UC05/B05 (exact durable-record inspection and intervention with visible
freshness), and the product contract's town-state ownership. It does not qualify
the native operator UI, canonical town/Book adapter or production authentication.
The [Wenyu requirements](WENYU_VALLEY_PRD.md) retain Book ownership and publication
boundaries; changing display metadata cannot accept knowledge or dispatch work.

## Start and discover

Use Node 18+ and its standard library. Restart with the same state path to reopen
work; don't use `--reset-state` for retained work.

```sh
node scripts/miniapp-local-backend.mjs --state /absolute/path/town-state.json --port 18191
```

The service binds to loopback and uses development identities. Its intentional
caller-selected user fallback remains; this is not a production security model.
Don't expose it to untrusted users. In another terminal, start `node`, then:

```js
const base = 'http://127.0.0.1:18191';
const post = async (route, body, session = '') => {
  const response = await fetch(base + route, {method: 'POST', headers: {'content-type': 'application/json', 'x-miniapp-session': session}, body: JSON.stringify(body)});
  const result = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(result));
  return result;
};
const login = await post('/miniapp/auth/dev-login', {userId: 'user-a'});
const session = login.session.id;
const get = async route => {
  const response = await fetch(base + route, {headers: {'x-miniapp-session': session}});
  const result = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(result));
  return result;
};
const snapshot = await get('/miniapp/town/snapshot');
const action = snapshot.profileEdits.find(item => item.buildingId === 'private-lab');
if (!action) throw new Error('Select a current editable building.');
console.dir(snapshot.buildings.find(item => item.id === action.buildingId));
const request = {buildingId: action.buildingId, expectedVersion: action.expectedVersion, changes: {title: 'Research Studio', summary: 'Retained research and decisions.', tags: ['research', 'decisions']}};
const preview = await post(action.previewPath, request, session);
console.dir(preview, {depth: null});
```

Review `before`, `after` and `changedFields`. Preview is read-only and does not
call the persistence callback. After deciding to apply this exact proposal:

```js
const applied = await post(action.applyPath, {...request, previewDigest: preview.previewDigest}, session);
console.dir(applied.building);
const reopened = await get('/miniapp/town/snapshot');
console.dir(reopened.buildings.find(item => item.id === action.buildingId));
```

The current snapshot returns fresh `profileEdits` actions with the new version.
For a published building, `/miniapp/buildings/search?query=research` finds its new
title or tags. A private building remains private and is found in the owner's
snapshot. For an archived building use `/miniapp/buildings/archived`; each result
has a `profileEdit` action and the same before/after workflow. Its new title/tags
are searchable in that archive list. Editing never restores or publishes it.

Stop and restart with the same state path, log in again, and inspect the same ID
to reopen the persisted profile. Sessions are memory-only. To undo a correction,
review a new edit at the current version using the previous values you retained;
there is no automatic undo or historical-profile browser.

## Fields and changes

Only title, summary and tags may be set in `changes`. Provide one or more fields;
omitted fields retain their exact current value. The preview and apply envelope
requires a nonblank `buildingId`, positive safe-integer `expectedVersion`, and
`changes`. Apply also requires the preview's lowercase SHA-256 `previewDigest`.
Fixture identity/session transport fields are allowed; other envelope keys refuse.

- Title: nonblank text up to 160 UTF-16 code units
- Summary: text up to 4,096 code units; empty string clears it
- Tags: at most 32 exact, distinct nonblank strings, each up to 64 code units;
  an empty array clears the list
- Nulls, NUL characters, unknown fields and repeated exact tags refuse. Values
  are preserved as entered, without trimming or HTML interpretation. Consumers
  must render them as plain text. The service does not sanitize secrets.

Identity, owner, visibility, book, kind, capabilities and other records cannot be
edited here. Published edits are immediately visible through the fixture's
existing public-building views, so review their content accordingly. Thread
titles are retained historical labels; renaming a building does not rewrite them.
The existing owner/`org-a` edit rule also applies to archived records. A system
building or another user's personal building returns 404 without its contents.
Both built-in users retain the existing fixture organization edit scope.

## Freshness and persistence

`POST /miniapp/buildings/profile/preview` returns `building-profile-preview` with
exact before/after values, changed fields and a digest bound to the resolved
actor, building ID/version, profile and protected metadata. The digest is unsigned
consistency evidence; it neither authenticates a user nor proves human review.
A caller may compute it, but cannot gain edit authority by possessing it.

`POST /miniapp/buildings/profile/apply` repeats the same validation and checks that
the reviewed source/proposal still matches. It updates only profile fields,
increments version once, refreshes the timestamp and appends one standard
`building.profile.updated` audit event naming the changed fields. The response
returns the audit ID, preview, resulting building and `changed: true`.
The normal service persistence path writes this state before returning success.
Review packets show the new profile and audit event with retained conversation.

A no-op returns `changed: false`, leaves version and audit unchanged, and skips
persistence. Repeating a successful changed apply with its old version returns
409 rather than appending another event. Invalid payloads return 400; changed
version or digest returns 409. An oversized source projection returns 413. Preview
and apply responses are `Cache-Control: no-store`. Refresh the discovery record,
make a new preview and inspect it before retrying a conflicting change.

The existing version-1 state format remains. The audit event records field names,
not old/new content. The service's existing single-process persistence model is
unchanged: a disk-write failure returns a server error, and in-memory state can
be ahead of disk. Do not blindly repeat an uncertain apply. Inspect/reopen the
same saved state, resolve the disk problem, then review a fresh version. This is
not a transactional multi-process store, backup workflow or daemon-soak proof.

## Focused verification

```sh
node --check scripts/miniapp-local-backend.mjs
node --check scripts/miniapp-building-profile.mjs
node --test scripts/miniapp-building-profile.test.mjs scripts/miniapp-archive-recovery.test.mjs scripts/miniapp-review-packet.test.mjs scripts/miniapp-conversation-search.test.mjs scripts/miniapp-session-retention.test.mjs
```

Ten new focused tests exercise discovered actions, before/after review, preserved
records, published rediscovery, archive-only editing, missing/stale preview,
session/organization scope, no-op behavior, actual listener persistence and
state-file reopen. The listener is driven by in-process request/response doubles;
no socket or graphical browser is opened. Set `MOONTOWN_PROFILE_EVIDENCE` to a
directory to retain state and response evidence beneath it.

No MoonBit source/interface changed or Moon command ran. Native app, frontend
rendering, network transport, live runtime/provider, production security and
full-product operation remain unqualified. R50 remains the last fully verified
cumulative checkpoint; R51–55 remain separate.
