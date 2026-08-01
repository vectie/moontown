# MoonTown Production Deployment Handoff

This handoff deploys the completed two-user MoonTown loop without adding a new
agent runtime. MoonTown owns identity, marketplace, consent, and durable
handoffs; MoonDesk owns the operator bridge; MoonClaw executes supervisors and
workers; MoonGate verifies exact capabilities and routes models; MoonBook owns
the installed book and Bookkeeper review.

## Release boundary

The public edge exposes only the Bunnia mini-app API through HTTPS. Keep the
MoonTown owner service, MoonDesk, MoonClaw, MoonGate, and MoonBook on loopback or
a private service network. Publishing, Bookkeeper acceptance, and any authority
increase remain explicit human actions.

```text
WeChat / Bunnia UI
        |
        | HTTPS + opaque user session
        v
MoonTown mini-app API
        |
        +--> Town marketplace and supervisor outboxes
        |
        v
MoonDesk owner bridge --> MoonClaw runtime --> bounded worker
        |                      |
        |                      +--> MoonGate exact capability + gpt-5.6-sol
        |
        +--> MoonBook Bookkeeper review --> accepted evidence receipt
```

## Immutable release inputs

Record these in the deployment ticket before promotion:

- release commits for `moontown`, `bunnia`, `moondesk`, `moonclaw`,
  `moongate`, and `moonbook`;
- approved HTTPS host name and certificate owner;
- WeChat AppID and the matching request-domain allowlist;
- tenant ID and the initial publisher/reviewer identities;
- secret-manager references for session signing, MoonGate control, provider
  credentials, and backup encryption;
- object-storage/CDN host, retention class, and data residency;
- restore target, recovery owner, and rollback release.

Never put session tokens, provider credentials, control tokens, AppID private
material, or user evidence in Git.

## Build artifacts

Use release builds for runtime services. The MoonClaw debug build currently
triggers a native compiler ICE in this workspace; production must use its
release artifact.

```sh
cd /srv/moonsuite/moontown && moon build --release
cd /srv/moonsuite/moondesk && moon build --release
cd /srv/moonsuite/moonclaw && moon build --release cmd/main
cd /srv/moonsuite/moongate && moon build --release cmd/main
cd /srv/moonsuite/moonbook && moon build --release
cd /srv/moonsuite/bunnia && moon run cmd/main -- build examples/moontown_miniapp
```

The generated WeChat project is
`bunnia/_build/bunnia/wechat/moontown_miniapp`. Import it with the production
AppID and do not commit DevTools-local metadata.

## State and permissions

Choose one absolute `MOONSUITE_ROOT`. The service account needs read/write
access to that root and no write access to source checkouts. At minimum back up:

- `.moonsuite/products/moontown/marketplace`;
- `.moonsuite/products/moontown/supervisor-setup`;
- `.moonsuite/products/moonclaw/jobs`;
- installed `books/` and their accepted assets;
- MoonBook review receipts and evidence indexes.

Use mode `0700` for secret directories and `0600` for secret files. Project the
Codex credential into MoonClaw's tenant-local credential path through the
secret manager; do not copy it into an image:

```text
$MOONSUITE_ROOT/.moonsuite/products/moonclaw/credentials/codex-credentials.json
```

MoonGate's control token is supplied to MoonClaw/MoonDesk as the
`MOONGATE_CONTROL_TOKEN` environment secret. The runtime model policy remains
`gpt-5.6-sol`; MoonClaw maps it to the provider-qualified
`codex/gpt-5.6-sol` selector at the execution boundary.

MoonDesk claims and reconciles the desktop owner outbox as the stable transport
identity `moondesk-owner-service`. Do not substitute the public mini-app adapter
identity. MoonTown's shared marketplace-runtime bridge projects the same exact
MoonClaw result into the requester-facing state for both owner-service and
mini-app reconciliation paths.

## Service topology

Recommended private listeners:

| Service | Listener | Public |
|---|---:|---|
| MoonTown owner service | `127.0.0.1:17842` | no |
| MoonDesk owner bridge | `127.0.0.1:18199` | no |
| MoonBook | `127.0.0.1:18221` | no |
| MoonGate | `127.0.0.1:18521` | no |
| MoonClaw daemon/workers | dynamic loopback | no |
| MoonTown mini-app API | `127.0.0.1:18191` | through HTTPS proxy only |

Use separate opaque sessions for each person. A request must not be allowed to
select its own marketplace principal. In a multi-instance deployment, every
instance uses the same durable marketplace store and the trusted session issuer
maps each token to one tenant principal.

Start order:

1. mount the suite root and secret projections;
2. start MoonBook and register the tenant's installed books;
3. start MoonGate and verify its control-token-protected capability projection;
4. start MoonTown owner and mini-app services;
5. start MoonDesk with the MoonClaw service manifest and control token;
6. verify MoonClaw health and exact `supervisor.activate` and
   `supervisor.delegate` resolution;
7. enable external HTTPS traffic.

Stop in reverse order. Drain new marketplace decisions before stopping the
bridge; durable pending handoffs remain replayable after restart.

## HTTPS edge

`deploy/Caddyfile.example` is the reference edge. Replace the placeholder host,
apply the approved certificate policy, and restrict request bodies. Forward the
opaque session header but never log it. Configure the exact HTTPS origin in the
WeChat request-domain allowlist.

Health checks must not require or reveal a user session. All write endpoints
require JSON, a bounded `Content-Length`, and an authenticated session. Keep
owner-service endpoints inaccessible from the edge.

## Media, CDN, and package budget

The current generated main package is 779,050 bytes (about 0.78 MB), below both the 1.5 MB
operating threshold and WeChat's 2 MB main-package limit. Do not introduce
subpackage complexity yet.

- keep the main package below 1.5 MB to preserve release headroom;
- create lazy subpackages only when the main package crosses that threshold;
- keep every main/subpackage below 2 MB and all subpackages below 30 MB total;
- place photos, video, audio, map tiles, generated artifacts, and large book
  previews on the approved CDN/object store;
- store immutable asset digests and rights metadata beside remote URLs;
- use versioned, cacheable media URLs and short-cache API responses;
- block a release if local media re-enters the code package without a budget
  exception.

## Tenant bootstrap

1. Initialize or import the MoonBook.
2. Register it in MoonTown's installed-book catalog.
3. Provision publisher and reviewer principals and opaque sessions.
4. In the Bunnia UI, the publisher creates a supervisor, selects exactly one
   installed book, accepts the visible authority/Bookkeeper consents, and
   requests activation.
5. In MoonDesk, the named operator grants the activation. Confirm Town shows an
   `activeRunId` and a reconciled runtime cursor.
6. Only then enable `try`, `install`, or `invite` marketplace actions.

## Two-user acceptance journey

Use two independent signed-in UI sessions. Do not switch identity with a request
header in production.

### Ada (requester)

1. Open **Discover** and search for the published agent.
2. Open its card, inspect permissions, authority ceiling, price/terms, and
   publisher identity.
3. Choose **Try**, enter a concrete deliverable, and submit.
4. Open **Messages / Requests** and confirm the request is waiting for the
   publisher. Ada must not see an approval control.

### Bo (publisher)

1. Open **Messages / Requests** and inspect Ada's request.
2. Confirm the instruction, claim ceiling, cost, runtime, token, artifact,
   Web-search, and expiry bounds.
3. Approve. If the supervisor was offline, activate it and choose **Retry
   handoff**; do not recreate or silently alter the decision.
4. Confirm the request advances from queued to runtime acknowledged to running.

### Completion and review

1. Wait for MoonClaw to return the worker summary and artifact references.
2. Confirm both users see the same completed request identity and evidence
   references.
3. Bo requests Bookkeeper review in the MoonBook UI.
4. The named reviewer accepts or rejects the evidence. A completed worker is not
   accepted knowledge until this receipt exists.
5. Restart MoonDesk and MoonClaw, reload both UIs, and confirm the completed
   request, evidence, and review receipt recover from durable state.

## Release checks

Run one consolidated qualification pass:

```sh
cd /srv/moonsuite/moontown && moon info && moon fmt && moon test
cd /srv/moonsuite/moondesk && moon info && moon fmt && moon test
cd /srv/moonsuite/moonclaw && moon info && moon fmt && moon test
cd /srv/moonsuite/moongate && moon info && moon fmt && moon test
cd /srv/moonsuite/bunnia && ./scripts/ci.sh
```

Then run `bunnia/scripts/two_user_ui_to_ui.mjs` on the self-hosted macOS runner
with WeChat DevTools. CI must fail if DevTools is unavailable; an API-only test
must never be reported as UI-to-UI evidence.

Promotion requires:

- HTTPS and WeChat domain verification;
- exact MoonGate capability resolution for activation and delegation;
- publisher/requester authorization isolation;
- queued to running to completed worker evidence;
- Bookkeeper receipt or an explicit `pending human review` state;
- restart replay;
- package and remote-media budgets;
- encrypted backup and a rehearsed restore.

## Qualification evidence from the 2026-08-01 staging run

The local integration tenant at
`/tmp/moonsuite-two-user-acceptance-20260801-v2` proved the runtime path with
real `gpt-5.6-sol` execution:

| Evidence | Observed value |
|---|---|
| Installed MoonBook | `coding` |
| Supervisor | `bo-supervisor` / active run `29105fe2-0fa6-40de-836e-85f4e67fa061` |
| Marketplace request | `action:ada-policy-guide-card:reviewer-a:15` |
| Execution handoff | `supervisor-execution-marketplace-action:ada-policy-guide-card:reviewer-a:15` |
| Worker | `94a00ae4-d698-497e-8656-86c0515c9aa4` / `succeeded` |
| Artifact | `books/coding/artifacts/evidence-handoff-validation.md` |
| Artifact SHA-256 | `a465ebc88887339b1eceffbefc5bb232b9616635e77a4b7efa494540abc3e17f` |
| Requester projection | `succeeded`, with the same worker and artifact reference |
| Restart recovery | MoonClaw restarted, became healthy, restored Bo, preserved both terminal workers, and replayed cursor `7` |
| WeChat package | 779,050 bytes; release-ready 8/8 and within the 1.5 MB operating budget |

The first worker attempt is intentionally retained as negative evidence: it
failed because a provider returned `sha256` where the parser required `digest`.
The normalized parser and object-or-null provider-receipt contract were then
used by the successful worker above.

The actual WeChat UI automation script and GitHub workflow are installed in
Bunnia. Its local qualification attempt correctly failed closed because the
DevTools automation service port is disabled. An operator must explicitly
enable **Settings → Security Settings → Service Port** on the trusted macOS
runner, then rerun the workflow and attach
`two-user-ui-result.json` before production promotion. This is not counted as a
passed UI-to-UI run.

Production HTTPS is likewise configuration-ready, not externally deployed:
the release owner must supply the approved domain, certificate policy, WeChat
AppID/request-domain registration, secret-manager references, and CDN. Use
[`deploy/Caddyfile.example`](../deploy/Caddyfile.example) and
[`deploy/moontown.env.example`](../deploy/moontown.env.example) as the reviewed
inputs; never promote the staging tokens or paths.

## Rollback and recovery

Disable new marketplace actions, snapshot the suite root, stop the public API,
roll back binaries as a unit, and restart in normal order. Do not roll back or
delete user evidence. Reconcile claimed handoffs from the durable outbox; release
only a claim owned by the stopped transport. If the provider is unavailable,
leave work visibly pending or failed and preserve the exact retry command.

The deployment is operationally complete only after the operator records the
release commits, domain, AppID, secret references, backup location, first
successful two-user receipt, and rollback drill in the deployment ticket.
