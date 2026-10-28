# Neighborhood lifecycle

Native MoonBit domain and file store for public stories, hosted events, attendance,
and voluntary private follow-up. A new store is empty. Models, contacts, publication
consent, and participation are never seeded or inferred from simulation state.

## Trusted boundary

The server calls `@neighborhood.execute(operation, payload, now_ms, actor_id,
path~, can_host~)`. It supplies the authenticated actor, current epoch milliseconds,
hosting capability, and configured private store path. Client JSON cannot set an
owner, participant, role, timestamp, or lifecycle state.

`can_host` grants creation of new events only. Existing events require their exact
owner; another operator cannot administer them. Signed-in users may author and
explicitly publish their own stories. Authentication and account revocation remain
the HTTP adapter's responsibility.

Successful responses are `{ok:true, operation, payload:snapshot}`. Domain errors
are `Unauthenticated`, `Forbidden`, `NotFound`, `InvalidRequest(message)`, and
`Conflict(message)`, suitable for HTTP 401, 403, 404, 400, and 409. File errors must
not be presented as success or replaced with empty state.

## Operations

Optional text fields default to empty strings. Empty or omitted new-object `id`
allocates a server ID. User-provided IDs are symbolic, at most 80 characters.
All submitted content is plain text.

| Operation | JSON payload | Rule |
| --- | --- | --- |
| `public` | `{}` | Anonymous, public projection only |
| `mine` | `{}` | Signed-in caller's private projection |
| `save-story` | `{id?, author_name?, title, body}` | Create or edit own unpublished story |
| `publish-story` | `{story_id, consent:true, expected_content_revision}` | Exact author, consent to this saved content version |
| `withdraw-story` | `{story_id}` | Exact author, remove published story from public |
| `save-event` | `{id?, title, description, location, starts_ms, ends_ms, capacity}` | New: trusted `can_host`; existing: own draft |
| `publish-event` | `{event_id, consent:true, expected_content_revision}` | Owner, future draft, consent to this saved content version |
| `cancel-event` | `{event_id}` | Owner, draft or published event |
| `end-event` | `{event_id}` | Owner, published event that has started |
| `register` | `{event_id, display_name, contact?}` | Caller registers only themself, before event end |
| `cancel-registration` | `{registration_id}` | Own confirmed/waitlisted entry, before event end |
| `check-in` | `{registration_id}` | Event owner checks in a confirmed participant during event |
| `request-follow-up` | `{event_id, message, contact?, consent:true}` | Caller with confirmed/checked-in entry after event is ended |
| `resolve-follow-up` | `{followup_id, next_step, outcome?}` | Owner records a response to an open request |

Times on the API are integer JSON numbers in epoch milliseconds, or `null` for
unset optional timestamps. New events require `now < starts_ms < ends_ms`;
capacity is 1–10,000. Text limits are title 160, author/display name 100,
story body 20,000, event description 10,000, location/contact 500, and follow-up
message/next step/outcome 5,000 characters.

Every story/event save assigns a server-owned `content_revision`. Public and
private projections include it. Publication requires the exact
`expected_content_revision` from the saved content the user reviewed, checked
under the file lock; stale consent returns conflict without writing. Unrelated
registrations do not invalidate that object's version. Existing stores without a
version project zero until the next save. Save operations themselves remain
explicit owner updates; this fence protects publication, not concurrent draft
editing or merge conflict resolution.

Story states are `draft`, `published`, `withdrawn`; editing requires withdrawal
and returns the story to draft, requiring fresh publication consent.
Event states are `draft`, `published`, `cancelled`, `ended`.
Registration states are `confirmed`, `waitlisted`, `checked_in`, `cancelled`,
`event_cancelled`. Cancelling a confirmed entry atomically promotes the first
waiting entry. A returning participant rejoins at the end of the queue.
Cancelling an event closes every active entry without promoting anyone.

Follow-ups are `open` or `resolved`. They are never created automatically;
an organizer cannot submit on somebody else's behalf. A resolution records
organizer-authored next-step/outcome text, not independent proof of delivery and
not creation or execution of a task. Duplicate active registration, repeated
check-in, duplicate follow-up, and repeated resolution return a conflict without
duplicating records.

## Snapshot and privacy

The snapshot has schema `moontown.neighborhood.v1`, `revision`, `stories`,
`events`, and `mine`.

Public stories expose ID, public author name, title, body, state, content revision,
and timestamps.
Public events expose ID, title, description, location, schedule, capacity, state,
confirmed/waitlisted counts, and timestamps. Ended/cancelled notices remain visible
only when the event was previously published. Cancelling a draft never publishes it.
Public responses exclude actor IDs, draft content, registration names/contact
details, and all follow-up records.

For `public`, `mine` is always `null`, even if an actor was supplied. Otherwise
`mine` contains trusted `actor_id`, `can_host`, all of the caller's `stories`,
owned `events` including their private `registrations` and `followups`, and the
caller's own `registrations` and `followups`. Switching identity must clear cached
private UI content.

Private registration fields are `id`, `event_id`, `participant_id`,
`display_name`, `contact`, `state`, `created_ms`, `updated_ms`, `checked_in_ms`.
Private follow-up fields are `id`, `event_id`, `participant_id`, `message`,
`contact`, `state`, `next_step`, `outcome`, `created_ms`, `updated_ms`, `resolved_ms`.

## Persistence

The default path is the configured MoonTown product-state directory plus
`/neighborhood/state.json`; an adapter may explicitly configure a separate path.
The store uses an in-process mutex and cross-process exclusive file lock around
load, authorization, lifecycle/capacity checks, mutation, and save. It writes a
private `0600` temporary file with full sync then renames it over the state file.
Every call reloads from disk. Failed actions do not persist changes. Internal
storage schema is `moontown.neighborhood-store.v1`; its UInt64 timestamp encoding
is private and distinct from the numeric HTTP projection.

The file lock coordinates processes sharing one filesystem path. Multiple hosts
with separate files are separate stores, not a distributed database. This package
does not send emails, schedule notifications, process payments, or claim remote
production deployment.

## Executable example

```mbt check
///|
async test "new neighborhood has no public or personal seed data" {
  let root = @fs.tmpdir(prefix="neighborhood-documentation-")
  defer @fs.rmdir(root, recursive=true)
  let response = @neighborhood.execute(
    "public",
    Json::empty_object(),
    1UL,
    None,
    path=root + "/state.json",
  )
  assert_true(
    response
    is {
      "ok": True,
      "payload": {
        "schema": String("moontown.neighborhood.v1"),
        "stories": Array([]),
        "events": Array([]),
        "mine": Null,
        ..
      },
      ..
    },
  )
}
```
