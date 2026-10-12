# Find retained conversations in the local mini-app

The existing Node development service now lets operators find literal message
text across visible buildings rather than opening every building packet. This
is a read-only retained-record view under MOONTOWN-UC05/B05, not a live worker,
semantic synthesis, knowledge acceptance, or a new native UI.

Start the existing fixture service using Node 18+:

```sh
node scripts/miniapp-local-backend.mjs --port 18191 --state /absolute/path/town-state.json
```

The service remains loopback-bound. The existing development login/session rules
apply, including the intentional caller-selected `userId` fallback; this is not
production authentication. Use the exact supported `--state` option as shown in
the backend help/source. Do not expose the fixture to untrusted users.

Inspect GET `/miniapp/town/snapshot`: its `conversationSearch` action advertises
`/miniapp/conversations/search` and filters. For example:

```sh
curl -sS -G http://127.0.0.1:18191/miniapp/conversations/search --data-urlencode 'query=Budget' --data-urlencode 'buildingId=private-lab' --data-urlencode 'userId=user-a' > search.json
```

With an existing development session, use the same `x-miniapp-session` header
on every request instead of relying on the fixture identity fallback. A supplied
expired token refuses; it is not replaced with a fallback user.

## Query and results

- `query`: required nonblank literal, at most 256 UTF-16 code units. Regex
  punctuation is ordinary text. No tokenization, stemming or semantic inference.
- `buildingId`, `actorId`: optional exact case-sensitive IDs; a selected hidden
  or archived building returns 404, not an empty successful search.
- `case=sensitive` (default) or `case=insensitive`: JavaScript Unicode-aware
  regex case matching of the escaped literal; no accent or Unicode normalization.
- `limit`: 1–100 results (default 50); `offset`: nonnegative safe integer.

Results sort newest recorded message timestamp first, then exact message ID.
Each row names its building, thread, message, actor, recorded time/version, text
SHA-256, and linked run IDs/statuses/versions. Run statuses are retained fixture
values, not proof of actual execution. They are thread-level links and are not
claimed to be caused by that individual message.

Use the returned `inspectPath` (the existing snapshot route) and exact
`messageId` to reopen the full current message; compare its body hash when exact
identity matters. The snapshot is live current state, so a changed digest means
it is no longer the searched copy. For editable buildings, the existing snapshot
also advertises a separate source-bound review-packet workflow.

An excerpt contains the first match plus up to 80 code units before and 160 after.
`matchStart`, `matchLength` and `excerptStart` are UTF-16 offsets into the original
body; `excerptTruncated` discloses clipping. Render excerpts as plain text, never
HTML. They may contain private content. Matches count messages, not occurrences.
No matches returns an explicit zero and an empty list.

## Pages, scope and freshness

Follow `nextPath` with the same identity/session transport. It includes an
`expectedDigest` binding the query, filters and exact selected source projection.
Identity/session parameters are not copied into that URL. Offset pages require
the digest; changed selected messages, thread metadata, building metadata or
recorded run status return 409 `search-source-changed`. Restart from page zero
when this happens. A digest is unsigned consistency evidence, not a timestamp,
authenticated signature, or durable historical revision. No search index or
checkpoint file is created.

Only current visible buildings are searched, using the existing service's
published/owner/team/system visibility rule. Archive hides their conversations;
restoring the building makes the same retained messages discoverable. Another
user's private building is excluded. Orphan messages with no visible thread are
outside the search scope, and counts describe that scope only. Crossing a visible
thread into another building's run fails explicitly instead of joining unrelated
context. A shared/public thread's recorded content follows the current fixture's
building visibility, not per-message ACLs.

At most 20,000 records in each scanned building/thread/message/run array and
4 MiB of selected source projection or output are allowed. Exceeded caps fail
413 rather than silently claiming complete coverage. Malformed/duplicate record
identities and crossed links fail 409. Search responses set Cache-Control:
no-store. The same bounds are checked on every page. No state is modified,
conversation marked read, run dispatched, review accepted, or file uploaded.

## Verification and limits

`node --test scripts/miniapp-conversation-search.test.mjs` exercises the actual
route, snapshot discovery, exact record reopening, literal/Unicode/case filters,
visible scope, archive/restore, digest-bound pages, persisted-state reload,
excerpts, empty results and the real service request listener with in-process
request/response doubles. Set `MOONTOWN_SEARCH_EVIDENCE` to an existing directory
to retain the persisted state and JSON result there. Existing packet/archive/
session regression tests must also pass.

The test does not open a listening socket, launch a browser, compile native
MoonBit, execute a live runtime/provider or prove production security/full-product
operation. This extends the established development-service lane only. R50 remains
the last fully verified cumulative baseline; R51–55 remain separate.
