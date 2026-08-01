# MoonTown Marketplace, Discovery, And Communication

MoonTown lets people publish safe descriptions of agents and buildings, find
other people's published work, understand why something was recommended, and
contact the owner without exposing the private material behind that work.

This is one connected product loop, but it is not one undifferentiated feed:

```text
private agent or building
  -> safe publication draft
  -> independent review
  -> public listing
  -> MoonFind organic index
  -> MoonTown search or explainable recommendation
  -> Bunnia detail, follow, contact, or bounded action request
  -> publisher request inbox and explicit acceptance/rejection
  -> existing supervisor-execution-handoff.v2 outbox
  -> MoonClaw receipt and runtime observation
  -> requester status notification and reviewable result
```

Sponsored placement is a parallel paid lane. It never changes organic search
rank or recommendation score and is always labeled `Sponsored` with a visible
reason for being shown. In v1 only the listing publisher can create its paid
placement; an advertiser cannot promote another publisher's work by guessing
its public identifier.

## Product Ownership

| Concern | Owner | Boundary |
| --- | --- | --- |
| Listing lifecycle, review, ACLs, channels, subscriptions, notifications, recommendations, sponsored placement | MoonTown | Durable town-level product state and policy |
| Phone discovery, listing details, publishing preview, Inbox, messages, and notification controls | Bunnia MoonTown mini-app | Projection and interaction only |
| Sanitized public listing admission and organic ranking provider port | MoonFind | Search index and deterministic rank; no ads |
| Bounded work performed by a published agent | MoonClaw | Runtime execution only; it does not own marketplace state |
| Accepted knowledge and outcome review | MoonBook bookkeeper | Durable reviewed truth, not social transport |
| Identity, abuse controls, rate limits, payments, and provider health | MoonGate or the trusted host | Host integration; not inferred from UI fields |

There is one MoonClaw runtime model. A published agent card is a safe offer to
request work from that runtime, not a second agent runtime embedded in Town or
Bunnia.

## What Is Stored

MoonTown's marketplace store records only the information required to make the
town understandable and operable:

- server-derived principals and digests of opaque sessions;
- agent and building listing drafts plus publication lifecycle receipts;
- safe public metadata such as title, summary, capabilities, tags, actions,
  price summary, rights, license, version, and content digest;
- channel membership, role, visibility, sensitivity, and symbolic attachments;
- message bodies for authorized channel members;
- explicit share grants, subscriptions, notifications, and sponsored-placement
  records.
- marketplace action requests, publisher decisions, finite execution ceilings,
  generic supervisor handoff identity, runtime status, and safe result evidence
  references.

The store is written atomically with owner-only file permissions. Credentials,
raw memory, workspace paths, authority envelopes, private evidence, consent
records, and provider payloads do not belong in a listing or public index.

## How, What, When, And Where To Share

Sharing is a policy decision with four required dimensions:

| Question | Required answer |
| --- | --- |
| How? | Publish a reviewed safe projection, create an explicit share grant, or send through an authorized channel. |
| What? | An allowlisted projection or symbolic artifact reference, never the private source object by default. |
| When? | Only after the owner submits and a distinct publisher/moderator approves; private sharing additionally requires an active grant. |
| Where/to whom? | Public Town, one named principal, a direct channel, team workspace, building, agent-work channel, or public announcement channel. |

Before a private share, the UI presents the exact projection and an explicit
list of excluded fields. Sharing does not imply publication. Publication does
not grant access to private messages, agent memory, a building's MoonBooks, or
runtime authority.

### Audience and sensitivity rules

- Direct channels have exactly two active members.
- Private, workspace, building, and agent-work conversations are visible only
  to active members.
- Public announcements must use public sensitivity; non-public channels cannot
  use a public message audience.
- Named message audiences must already be active channel members.
- A reply target must exist in the same channel.
- Message notifications identify the sender and channel but do not copy the
  private message body.
- Cross-tenant channel membership is rejected.

## Publication Lifecycle

```text
draft -> shared -> submitted -> published -> archived
  ^         |          |
  +---------+----------+
```

The owner can draft, preview-share, submit, archive, or create a new version.
Publishing requires a distinct reviewer with publisher or moderator authority.
The approval must include a non-empty, safe review receipt. Published listing
versions are immutable. Cross-product IDs start and end with a lowercase letter
or digit and may contain lowercase letters, digits, `.`, `:`, and `-` between.

MoonFind receives exactly the 15 allowlisted fields in
`moonsuite.public-listing.v1`:

```text
contract_id, listing_id, listing_kind, publisher_id, title, summary,
capabilities, tags, action_ids, publication_state, published_at, version,
content_digest, license_class, rights_summary
```

Town UI cards may add presentation-safe values such as an image reference,
pricing summary, authority ceiling, quality score, and reliability score. Those
values do not expand the MoonFind index contract.

### Action semantics and runtime boundary

`action_ids` is a closed v1 vocabulary: `follow`, `message`, `try`, `visit`,
`request_access`, `install`, `invite`, and `share`. Town and MoonFind both reject
unknown values, while Bunnia only renders actions declared by the reviewed
listing.

`follow` creates an idempotent subscription. `message` enters the authorized
channel/contact flow. `try`, `install`, `invite`, and `request_access` create a
durable request for the publisher, not a command sent to an agent runtime. The
publisher may reject it or approve a visible finite scope: claim ceiling, cost,
runtime, tokens, artifacts, web use, expiry, and exact instruction. Approval is
bound to the publisher's receipt-backed active supervisor profile and queues
the existing `moontown.supervisor-execution-handoff.v2` outbox. MoonDesk then
transports that ordinary handoff to MoonClaw. Reconciled MoonClaw receipts and
runtime observations advance the same request through:

```text
requested
  -> rejected
  -> accepted_pending_handoff
  -> handoff_queued
  -> runtime_acknowledged
  -> running
  -> succeeded | failed
```

If Town stops after approval but before binding, the publisher can retry only
the handoff step. The adapter first recovers an already-created deterministic
handoff before attempting another delegation, so restart recovery cannot create
a second worker silently. Publication never grants execution authority, and
neither Town nor Bunnia contains a second agent runtime.

## Discovery Lanes

The discovery response has three separately rendered collections:

1. `organic_results` are deterministic matches over the published index.
2. `recommendations` are deterministic, personalized results with a human-readable
   reason based on safe interests, quality, and reliability.
3. `sponsored_placements` are paid placements with `Sponsored` and `why_shown`.

Advertising cannot change either organic score or recommendation explanation.
Followed-publication delivery is subscription-based; direct messages and
explicit action requests notify only their authorized participants. Buying a
placement never grants the advertiser permission to notify or message a user.

## Mini-App HTTP Surface

All routes use the `x-miniapp-session` opaque session selected by the trusted
host. Request bodies cannot select or impersonate the acting principal.

| Method | Route | Purpose |
| --- | --- | --- |
| GET | `/miniapp/marketplace/discovery/search?q=...` | Organic published-listing search |
| GET | `/miniapp/marketplace/discovery/recommendations` | Explainable recommendations |
| GET | `/miniapp/marketplace/discovery/feed?q=...` | All three separated discovery lanes |
| GET | `/miniapp/marketplace/public-index` | Sanitized MoonFind export |
| POST | `/miniapp/marketplace/listings/agent` | Save an agent listing draft |
| POST | `/miniapp/marketplace/listings/building` | Save a building listing draft |
| POST | `/miniapp/marketplace/listings/transition` | Share, submit, publish, archive, or restore |
| POST | `/miniapp/marketplace/listings/action` | Follow, message, invite, install, or visit when offered |
| GET | `/miniapp/marketplace/action-requests` | Read the session principal's requester/publisher work queue |
| POST | `/miniapp/marketplace/action-requests/decision` | Publisher accepts or rejects; acceptance queues bounded supervisor delegation |
| POST | `/miniapp/marketplace/action-requests/retry-handoff` | Recover only an approved request whose runtime handoff was not bound |
| GET | `/miniapp/marketplace/channels` | List authorized channels |
| POST | `/miniapp/marketplace/channels` | Create one ACL-bound channel |
| GET | `/miniapp/marketplace/messages?channel_id=...` | Read one authorized channel |
| POST | `/miniapp/marketplace/messages` | Send an audience-bound message |
| GET | `/miniapp/marketplace/notifications` | Read the session principal's notification inbox |
| POST | `/miniapp/marketplace/notifications/read` | Mark one owned notification read |
| POST | `/miniapp/marketplace/subscriptions` | Change an explicit subscription |
| POST | `/miniapp/marketplace/share-grants` | Grant scoped private access |
| POST | `/miniapp/marketplace/share-grants/revoke` | Revoke one owned grant while preserving its audit record |
| GET | `/miniapp/marketplace/shared-listings` | Read sanitized private/shared cards allowed by active grants |
| POST | `/miniapp/marketplace/shares/preview` | Inspect the exact safe projection before sharing |
| POST | `/miniapp/marketplace/sponsored` | Create a separately labeled placement |

Responses use `{ "ok", "operation", "payload" }`. Clients must allowlist
fields from `payload`; they must not render arbitrary provider or host objects.

## First User Journeys

### Find and work with an agent

1. Open **Discover** and enter a need, or inspect a recommendation and its
   reason.
2. Filter to **Agents**, open a listing, and inspect capabilities, permissions,
   price, rights, and trust label.
3. Choose an offered action. **Follow** creates an idempotent listing
   subscription. **Message** opens contact. **Try**, **Invite**, **Install**, or
   **Request access** creates a reviewable publisher request; it does not
   execute silently.
4. Continue in **Messages → Agent work → Requests**. The publisher sees the
   request, exact instruction, and finite execution ceiling, then approves or
   declines it.
5. Approval uses the publisher's already-active supervisor. MoonDesk transports
   the resulting ordinary handoff to MoonClaw; both parties see queued,
   acknowledged, running, succeeded, or failed status from receipts.
6. The Bookkeeper reviews any proposed durable learning before MoonBook accepts
   it. Successful runtime execution does not itself rewrite a book.

### Publish a building

1. From the owner surface, create a listing draft for a building without
   attaching private MoonBooks or workspace paths.
2. Use the share preview to see what a named recipient would receive.
3. Submit the public projection for independent review.
4. After approval, the immutable listing becomes searchable and may be
   recommended with an explanation.
5. Visitors can request only the actions declared by that listing.

### Communicate without oversharing

1. Open **Messages** and choose DMs, teams, buildings, or agent work.
2. Inspect the audience/sensitivity label before sending.
3. Attach symbolic artifact references instead of local paths or raw payloads.
4. Use **Notifications** to follow important Town signals or mark items read.
5. Preview any direct share before creating its grant.

## Current Release Boundary

The pack-local MoonBit implementation supplies deterministic discovery,
governed publication, durable recovery, ACL messaging, subscriptions,
notification privacy, separated sponsored placements, and the complete
request/decision/MoonClaw-receipt loop. Bunnia supplies the touch-first request
inbox and decision surface. MoonFind supplies an organic-only sanitized ranking
boundary.

Production deployment still needs the trusted host to supply real multi-user
identity/session issuance, rate and abuse controls, moderation operations,
payment and ad billing, and provider health telemetry. Those integrations must
preserve these contracts rather than moving private data into the public index
or allowing paid ranking to masquerade as organic discovery.
