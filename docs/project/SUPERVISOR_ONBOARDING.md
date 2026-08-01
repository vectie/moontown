# First Supervisor Onboarding and Runtime Handoff

MoonTown owns the durable user character. Bunnia renders the phone flow,
MoonDesk transports durable outbox records, MoonClaw alone runs agents, and
MoonBook Bookkeeper alone accepts outcomes or learns from them.

## Canonical call chain

```text
Bunnia
  -> GET /miniapp/book-registrations (installed, trusted-root books only)
  -> PUT /miniapp/onboarding/supervisor/draft
  -> MoonTown immutable SupervisorProfile revision + audit/idempotency record
  -> POST /miniapp/onboarding/supervisor/activate
  -> MoonTown activation outbox (pending_transport; no local agent)
MoonDesk (same configured MoonTown owner service)
  -> GET /miniapp/outbox/runtime
  -> POST /miniapp/outbox/runtime/claim
  -> forwards the returned exact moonclaw.supervisor-command.v1
  -> MoonClaw verifies authority/profile digest and owns execution
  -> POST /miniapp/outbox/runtime/reconcile with the exact receipt
MoonTown
  -> projects runtime_acknowledged only after exact receipt replay
  -> shows durable supervisor separately from bounded worker runs
```

The desktop owner service advertises and serves the runtime and Bookkeeper
outbox routes on its configured service URL. The session-scoped mini-app
adapter also serves them and defaults to `http://127.0.0.1:18191`; deployments
may publish it with `MOONTOWN_MINIAPP_SERVICE_URL`.

## User routes

- `GET /miniapp/onboarding/supervisor` returns profile, readiness, cursor, and
  activation state. `/readiness` is an alias.
- `GET /miniapp/book-registrations` returns only `id`, `name`, and `purpose`
  for catalog entries whose canonical trusted root contains a recognized
  MoonBook installation marker (`book.json`, `book/book.json`, or
  `book/moonbook-ui-state.json`).
  Draft save and activation rerun that installation check; the phone never
  sends or receives `workspace_root`.
- `PUT /miniapp/onboarding/supervisor/draft` creates or revises a profile.
  `commandId`, `expectedVersion`, and `expectedCursor` are mandatory.
- `POST /miniapp/onboarding/supervisor/activate` queues activation. A response
  is pending transport, never proof that an agent ran.
- `POST /miniapp/messages` creates supervisor `message`; `/miniapp/runs/steer`
  creates supervisor `steer`; and `/miniapp/runs/delegate` creates an exact
  finite-scope child assignment.
- `POST /miniapp/runs/supervisor/wake`, `/supervisor/stop`, and
  `/supervisor/resume` create exact `wake`, `supervisor_stop`, and
  `supervisor_resume` lifecycle handoffs for the receipt-backed parent run.
  They are separate from every child-run control.
- `POST /miniapp/runs/child/steer` creates `child_steer`;
  `/miniapp/runs/cancel` creates `child_stop`; and `/miniapp/runs/retry`
  creates `child_retry`, transported as `worker-retry-resume`. Parent and
  target run identity stay distinct. Town never executes these operations.
- `POST /miniapp/reviews/:id/decision` (or `/miniapp/reviews/decision`) accepts
  only an exact evidence-bound MoonClaw ProductOutcomeSubmission. It creates a
  pending `bookkeeper.outcome.submit` request and never changes accepted memory.

The canonical draft accepts nested `persona`, `bindings`, and `consents`.
For the Bunnia phone adapter it also accepts `name`, `archetypeId`, `toneId`,
`capabilityIds`, `workspaceId`, `buildingId`, `bookId`,
`consentAgentControl`, and `consentBookkeeperReview`. Agent-control consent maps
to both activation and bounded delegation consent; Bookkeeper consent remains
separate. A missing mission is the bounded mission for the selected book.

## Transport and recovery

Runtime and Bookkeeper outboxes expose `GET`, `claim`, `release`, and
`reconcile` routes. Claims use the optimistic Town cursor and a
`x-moondesk-transport-id`. Repeating a claim by the same transport returns the
exact stored command/submission. `release` makes an abandoned claim available
after a crash. Exact receipt replay is idempotent; a conflicting receipt fails
closed.

Execution claims bind two different digests. `sourceRequestDigest` is the
semantic `moontown.supervisor-execution-handoff.v2` digest.
`transportRequestDigest` is SHA-256 of the exact endpoint operation in
`transportRequest`. The claim also stores `transportEndpoint` and the exact
`runtimeCommand`; its envelope repeats the transport digest, command id,
issued/evaluated time, cursor, and fixed MoonClaw authority receiver. Release
and same-owner reclaim cannot replace that mapping.

MoonDesk observes MoonClaw status/events and posts the digest-bound result to
`POST /miniapp/runtime/observations/reconcile`. MoonTown advances only a
monotonic runtime cursor, projects receipt-backed workers, and reconstructs
phone conversation history from canonical `message.sent`,
`supervisor.steered`, and `supervisor.assistant.responded` replay events. An
assistant bubble therefore requires exact source-event, delivery-event,
executor-run, and provider evidence rather than local optimistic text.

MoonTown only checks structural identity and exact digests. The host supplies
the authority decision reference; MoonClaw/MoonGate verify its operation,
ceiling, receiver, and expiry. Activation carries an immutable
`runtime_profile` whose canonical digest is `profile_digest`; MoonClaw consumes
that snapshot but does not own or edit the persona.

## Projection truth

Profiles project as `durable-supervisor` / `user-owned-profile`. Town workers
and runs project as `bounded-worker` / `run-scoped`. Movement and work-building
fields are emitted only from the live visual/task/execution projection and are
labelled with their source; absent movement is `null` or `not-observed`.
Supervisor-child lineage comes from persisted execution handoffs and exact
runtime receipts, not from map animation.

## Phone flow and human gates

The phone loads the installed-book list, selects a real MoonBook, creates the
persona, chooses 1–3 capabilities, reviews the immutable three-worker policy,
saves, then activates. Save/activation remain disabled without a live
selection. Every command performs a fresh profile/cursor read, and foreground
polling stops when the page hides.

Successful child work exposes “Request Bookkeeper review” only for an exact
`review_ready` outcome candidate. Bookkeeper alone owns Accept or Reject.
Human gates remain `deliverable_review_required`,
`assessment_review_required`, or `proposal_review_required`; terminal results
include `closed_no_capability_change`, `reviewed_proposal_handed_off`,
`deliverable_rejected`, `assessment_rejected`, and `proposal_rejected`.
Reject never appears pending, and no phone or Town path changes accepted memory.
