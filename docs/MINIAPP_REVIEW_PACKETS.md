# Export a building review packet from the local mini-app service

The existing dependency-free Node mini-app development service can now turn one
editable building's retained state into a portable review packet. Inspect the
building, download readable Markdown or structured JSON, and reopen it offline.
Archived buildings can be reviewed without restoring or publishing them. This
closes a different loop from archive recovery: the exported conversation and run
history can be reviewed outside the running service, while recovery changes the
building's lifecycle state.

This is an actual route in `scripts/miniapp-local-backend.mjs`. It is available
through the existing town snapshot's `reviewPackets` actions and through each
archived entry's `reviewPacket` action. It is not a new Bunnia client control or a
native MoonTown adapter feature. The canonical collaboration outcome library's
retained-dossier export remains separate; these packets contain development
mini-app records, not its captured source files or reviewed Book outcomes.

## Select, inspect, download and reopen

Start the existing service with Node 18 or later and an explicit state path:

```sh
node scripts/miniapp-local-backend.mjs --state /tmp/moontown-packet-demo.json --port 18191
```

In another terminal run `node`, then use its interactive top-level await. These
steps only read and export existing state after a development login. Use a new
output filename when repeating them: exclusive writes avoid overwriting files.

```js
const base = 'http://127.0.0.1:18191';
const fs = await import('node:fs');
const crypto = await import('node:crypto');
const loginResponse = await fetch(base + '/miniapp/auth/dev-login', {
  method: 'POST', headers: {'content-type': 'application/json'},
  body: JSON.stringify({userId: 'user-a'})
});
if (!loginResponse.ok) throw new Error(await loginResponse.text());
const login = await loginResponse.json();
const headers = {'x-miniapp-session': login.session.id};
const read = async route => {
  const response = await fetch(base + route, {headers});
  if (!response.ok) throw new Error(await response.text());
  return response.json();
};
const town = await read('/miniapp/town/snapshot');
console.table(town.reviewPackets);
const action = town.reviewPackets.find(item => item.buildingId === 'private-lab');
if (!action) throw new Error('Select an editable building from the current snapshot.');
const preview = await read(action.previewPath);
console.dir(preview, {depth: null});
```

Inspect the title, visibility, primary Book reference, version, record counts and
source digest before downloading. Use `preview.downloads.markdown` for the
readable account or `preview.downloads.json` for the complete typed projection:

```js
const response = await fetch(base + preview.downloads.json, {headers});
if (!response.ok) throw new Error(await response.text());
const bytes = Buffer.from(await response.arrayBuffer());
const actual = crypto.createHash('sha256').update(bytes).digest('hex');
if (actual !== response.headers.get('x-content-sha256')) throw new Error('Download digest mismatch.');
fs.writeFileSync('/tmp/building-review.json', bytes, {flag: 'wx'});
const reopened = JSON.parse(fs.readFileSync('/tmp/building-review.json', 'utf8'));
const sourceDigest = crypto.createHash('sha256').update(JSON.stringify(reopened.source)).digest('hex');
if (sourceDigest !== reopened.sourceDigest) throw new Error('Source projection mismatch.');
console.dir(reopened.source, {depth: null});
```

For an archive, select the action from the existing archived-building surface:

```js
const archive = await read('/miniapp/buildings/archived');
console.table(archive.results.map(item => ({id: item.building.id, title: item.building.title, messages: item.retained.messages})));
const archivedAction = archive.results.find(item => item.building.id === 'YOUR_ARCHIVED_BUILDING_ID')?.reviewPacket;
if (!archivedAction) throw new Error('Select an editable archive first.');
const archivedPreview = await read(archivedAction.previewPath);
```

Download using that preview's URLs and the same session header. Neither a packet
preview nor a download restores the building, appends an audit event, writes the
state file, dispatches/retries a run, updates a Book or grants access. Stop and
restart with the same state path to recover the service records. Log in again
because development sessions are memory-only. Unchanged projected records yield
byte-identical packets after restart; local files remain readable independently.

## Route contract and freshness

`GET /miniapp/buildings/review-packet?buildingId=ID` returns a JSON preview with
`schema: moontown.miniapp-building-review.v1`, the selected building, counts,
`sourceDigest`, qualification and two bound download URLs. IDs are URL-encoded.

Downloads use the same route with `format=json` or `format=markdown` and the
preview's `expectedDigest`. Successful responses are actual attachment bytes,
with a fixed digest-based filename, content type and length, `X-Source-Digest`,
`X-Content-SHA256`, `Cache-Control: no-store` and `X-Content-Type-Options: nosniff`.
JSON exports contain `schema`, `sourceDigest` and `source`; Markdown is a readable
projection with recorded statuses and source text rendered as indented code.
No source strings become generated HTML, headings or Markdown links.

The source digest is SHA-256 of UTF-8 `JSON.stringify(source)` with the producer's
fixed field order. It binds the documented projection, not the original state
file's bytes, file path, save timestamp, authentication records or unknown
extension fields. The content digest instead binds every downloaded byte. These
are unsigned local integrity checks, not authenticity, a named review decision
or independent proof of execution. Keep the JSON for machine verification;
Markdown normalizes CR/CRLF in message display to LF and is not a lossless state
archive. JSON preserves the retained strings and scalar types.

Related record changes invalidate the selection, including a new message or
changed run when the building version itself has not changed. A stale download
returns HTTP 409 `packet-source-changed`; reload the preview and inspect it again.
This is a current-state export, not a historical revision store. Unrelated work
and login changes do not alter the selected source digest. The synchronous
projection, digest check and rendering use one in-process snapshot.

Missing IDs, unsupported formats or missing/invalid inspected digests return
400. Unknown and non-editable buildings return the same 404 without disclosing
records. Duplicate record identities or crossed conversation/run links fail with
409 instead of producing a misleading partial packet. Missing/invalid sessions
keep the service's existing 401 behavior. Errors are JSON, never partial files.

## Included records and scope

- One building: ID, title, visibility, owner, Book reference, kind, summary,
  tags, capabilities, version and update timestamp.
- Its placements and configured agents, with their known fixture fields.
- Its threads and every retained message linked to those exact threads.
- Its runs, preserving IDs, caller, Book/agent/thread references, recorded
  status, summary, timestamps and version. Missing externally referenced agents
  or Book content are not invented or fetched.
- Audit events whose object kind and ID identify this building, its configured
  agents, threads or runs. Other events from the same actor are excluded.

Arrays retain their saved order. Recorded message counts are not recalculated
or represented as outcomes; preview counts describe actual exported records.
Empty collections are explicit. All known fixture fields in those records are
preserved; unknown extension fields, users, sessions and unrelated records are
excluded. This is not an import format, backup or whole-town export.

Only the building owner or the fixture's existing `org-a` editors can obtain a
packet, even when a building is public. Both built-in users have the existing
organization edit scope. An explicit session resolves the principal even if a
conflicting caller user field appears. This service intentionally still supports
a caller-selected development identity when no session is supplied. It must not
be exposed as production authentication or multi-tenant security. No permissions
or persistent access are created by this feature.

Source strings may contain private information. Inspect before sharing. Nothing
is uploaded, transmitted to another service, accepted as Book knowledge or
reported as a successful business outcome by this workflow.

## Bounds and verification

The already-loaded state is scanned locally. Each relevant collection is limited
to 20,000 records; a packet contains at most 5,000 selected records including the
building, at most 2 MiB of compact UTF-8 projected JSON and at most 4 MiB final
output. Any exceeded bound returns 413 with no partial export. A large packet may
preview successfully but exceed the pretty-printed output bound when downloaded;
that response still fails atomically. No truncation or pagination hides records.

```sh
node --check scripts/miniapp-local-backend.mjs
node --check scripts/miniapp-review-packet.mjs
node --test scripts/miniapp-review-packet.test.mjs scripts/miniapp-archive-recovery.test.mjs scripts/miniapp-session-retention.test.mjs
```

Focused tests exercise actual production route functions and the actual Node
request listener with in-process readable request/response adapters. They cover
discovery, preview/export/reopen, archive export, recorded statuses, source-bound
freshness, owner/team scope, empty records and immutable durable state before and
after restart. They retain sample JSON/Markdown exports and state bytes under the
printed `retained-packet-evidence` directory. Set `MOONTOWN_PACKET_TEST_EVIDENCE`
to choose its parent. No listening socket, live Bunnia client, graphical browser,
MoonBit/native graph, provider, daemon or complete product is qualified by these
tests.

## Product rationale

The actual MoonTown PRD's MOONTOWN-UC05/B05 requires inspection of exact durable
records behind town activity, without mistaking activity for outcomes. This
bounded export lets an operator preserve that review context from the existing
local service. It does not complete production authentication, multi-day
supervision, canonical civic coordination or accepted MoonBook history. See
[the product contract](PRODUCT_CONTRACT.md) and
[the frontend adapter boundary](project/FRONTEND_ADAPTER_ARCHITECTURE.md).

To locate a remembered phrase before opening a packet, use the existing service's
[conversation search](MINIAPP_CONVERSATION_SEARCH.md). It searches current visible
building conversations and returns exact message/thread references; archived
buildings remain excluded from search until explicitly restored.
