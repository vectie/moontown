# One identity, account-owned compute

MoonTown reuses LunaNexa's existing identity gateway; it does not register a
second account, copy a password database, or infer ownership from the desktop
host. MoonGate remains the execution boundary, not an identity provider.

## Current product decision — public town, four-node admin, owned compute

The user clarified the product on 2026-10-23 and explicitly selected **8443**.
Do not investigate or migrate 443 as part of this work. The intended entry is
`https://suanli.kechuangfuwu.com:8443/moontown/`.

| Viewer | Compute source | Presentation |
| --- | --- | --- |
| Anonymous | Curated trial catalog, backed by the approved .176/.177 pool | Two Trial entries; unknown telemetry; town agents explicitly demonstrations |
| Platform operator | Current human session, live PlatformOperator role, controller GET /v1/nodes | Exactly the approved .176/.177/.178/.179 fleet; unrelated nodes excluded |
| Ordinary account | Existing subject-authorized /v1/machine-access/self | Only that account's exclusive leases; never trial or someone else's resources as owned |

This supersedes the earlier suggestion to create a new .178/.179 ownership
binding for acceptance account B. No lease, account grant, or reservation is
created. An empty owned-machine view is valid if the authority has no assignment.
An organization admin is not a platform operator. Display names, URL parameters,
frontend fixture roles and browser storage never confer resource access.

The shared shell is independent of model/workspace readiness. It serves the
unchanged packaged town and complete 3D models from a dedicated immutable public
asset volume, with read-only account/compute BFF routes. Runtime snapshots,
private files, mutation routes and arbitrary controller proxies are not served.
Anonymous access currently means **catalog/demo**, not anonymous inference or
real trial telemetry. Public simulation counters must not be described as live
workloads. Live execution and trial consumption still require their existing
account/model grants and are not implemented by this read-only shell.

Private execution moves to `/moontown/workspace/`. The old portal's
`/moontown/connect` entry redirects to its private connect page, preserving the
single-use fragment without the public service reading it. LunaNexa's generic
bridge permits a product's own `/workspace` subpath, never a sibling product.
The existing private BFF additionally pins account and organization to the
workspace grant. The public service has no Kubernetes token or operator secret;
admin reads forward only the current human bearer to the fixed TLS controller
endpoint, which independently checks the live role.

Browser storage separates `public`, hashed `account-*` and `webide-*` namespaces.
The identity bootstrap checks that its storage scope still matches; account
changes and logout clear stale compute and reload before another principal is
displayed. Account responses are no-store, Cookie-varying and same-origin-only.
Identity failures do not fall back to a local account or global machine list.

UI uses the existing town controls and art, a compact login/account and compute
entry, and explicit public-demo labels. The public route omits the legacy second
account navigation, forced avatar onboarding and nonfunctional work-submission
card. Existing local/private-workspace behavior is preserved. Full 3D loading
and CSS sprite URLs now respect the product base path.

Implementation: `account_gateway/src/main/public_platform.mbt`,
`account_compute/platform.mbt`, and `scripts/prepare-public-town.mbtx`.
The preparation script saves private before-state and renders drift-checked
gateway/profile/ingress patches; it does not apply them. Deployment and real
account evidence must be recorded separately below before claiming acceptance.

### Public-shell validation and deployment hold — 2026-10-23

Targeted verification passed: 26 account/compute tests, 5 gateway tests (also
passed on Linux), 25 spatial/account UI tests, 16 browser-transport tests and
21 generic WebIDE bridge tests: **93 distinct targeted tests**. Targeted
`moon info`, formatter checks/builds and `git diff --check` were run; the existing
workspace emits deprecation warnings. This is not a claim that the entire
multi-repository test matrix was run.

The packaged UI was verified at 769 files / 70.4 MiB. Browser checks on the
actual read-only native public adapter at `http://127.0.0.1:17844/moontown/`
confirmed the town, shared login link, underground model and two Trial entries.
Those are local UI checks, **not real-account production acceptance**. Cookie
filtering now forwards only LunaNexa's supported enterprise identity cookie
names (including its 8443 and HTTP migration names), never another product's
workspace/local cookie. Missing health data is labelled unknown, not failed.

Private r1 release artifacts were published:

- gateway `sha256:7e6f5f1c37b1f98b49ef5cedc1efcd0690e96a5de4288ecd5c1b98f80c56cbf1`
- UI `sha256:2fd5d4a98a0e0b8a3fb51d9227d022043dd8265bb683b7783eceab2e6b0a7b4b`

**Do not activate these r1 artifacts/patches:** the final cookie-filter and
unknown-health fixes came afterwards. Rebuild/publish both reviewed source
artifacts and render a fresh release directory after resolving capacity.
Their private preparation directory is
`/home/HwHiAiUser/moon-public/work/moontown-public-stage-20261023-r1/rollout-r1`;
it contains gateway/profile/ingress before-state and drift-checked patches.

Only the new inactive `moontown-platform` Deployment/Service, its narrow network
policies and `moontown-workspace-strip` middleware were created. Kubernetes
refused to schedule the Pod because `ubuntu` has `DiskPressure=True` and the
`node.kubernetes.io/disk-pressure:NoSchedule` taint (transition 14:47:18 UTC).
The management filesystem reported 457 GiB total / 401 GiB used / 33 GiB available
(93% used). The two task-owned build directories together are about 2.9 GiB;
deleting them alone cannot establish sufficient scheduling headroom.

The new Deployment was scaled back to **zero**, preventing automatic activation
of the superseded candidate. No disk taint was removed/tolerated, no model data,
database, customer volume or unrelated build was deleted, and no application was
moved onto a managed GPU node. **Production ingress still points to the original
`moontown-webide-gateway`, running `paas-scope-20261018-r4`; its workspace profile
and image were not switched.** Account A/B/admin production acceptance remains
pending at this checkpoint. The user subsequently approved the old-build cleanup
recorded below. Both repositories remain on `main`; these changes have not been
committed or pushed.

### Approved management-node cleanup — 2026-10-23

Inventoried the exact paths and checked live Kubernetes hostPath references and
visible process open files before cleanup. Removed **one compiler cache and 49
duplicate OCI/base archive files**, not container-runtime images. Every archive
was byte-compared against its retained OCI directory with `tar --compare` before
deletion. Two H3 archive paths were hard links to one inode, counted only once
for reclaimed capacity. The retained OCI layouts, source trees, toolchains,
rollout backups, registry storage, model data, databases and user workspaces were
not removed. Archives can be repacked from the retained layouts; the compiler
cache can be rebuilt. These were permanent cache/archive deletions, not trash.

Four old caches with root-owned/non-writable contents were skipped. An initial
attempt on `r54/linux-source/_build` failed with permission errors; there was no
privilege escalation or permission change. The removed cache was exactly
`/home/HwHiAiUser/control-build/src/_build`.

After cleanup and rebuilding the candidate, the filesystem was **84% used**, with
76,218,736,640 bytes available (about **71 GiB**, up from about 33 GiB).
**DiskPressure cleared naturally at 15:27:36 UTC**; no taint/eviction threshold was
overridden. Read-only kubelet checks confirmed 5% hard thresholds, 10% minimum
reclaim and a five-minute transition period. The registry had also been evicted;
it recovered automatically at 15:29:28 UTC after transient pull-QPS limiting.
No registry Deployment, PVC, image cache or bootstrap configuration was changed.
After the evicted workloads repulled their runtime images and recovered, free
space settled at about **61 GiB / 86% used**; DiskPressure remained false. The
71 GiB reading above is the post-cleanup checkpoint, not the final steady-state
space after workload recovery.

Per-target receipts (including inode/link information and recovery basis) are
retained on the management node under `/home/HwHiAiUser/moon-public/evidence/`:
`moontown-cleanup-20261023-r2-apply.json` and
`moontown-cleanup-20261023-r2-bases-apply.json`, with local copies under `output/`.
The one-off `output/cleanup-reviewed-builds.mbtx` uses an explicit allowlist and
fails before deletion if verification does not pass; it is not a recurring
pruning policy.

Fresh candidate r2 Linux release tests: **5 passed**. UI artifact verification:
**769 files / 70.4 MiB**, preserving the full models. An overly broad debug test
invocation failed at native linking; the targeted release-mode gateway tests and
release build passed. This does not claim full-workspace test coverage.

Candidate r2 artifacts were then successfully published, with a fresh
`moontown-public-stage-20261023-r1/rollout-r2` preparation directory:

- gateway `sha256:a930a8b61a5d75db2b6f1367e6c832a6c0eccd06dc3c2a0309d2570296bd625a`
- UI `sha256:12201fef1e81ca5aae4ce09e2d19622d157ff3dbb59230300c6fcff848d171eb`

### Public r2 live on 8443 — 2026-10-23

The public resources passed server-side dry-run and were applied. Both
`moontown-platform` and `moontown-webide-gateway` rolled out successfully. Each
passed its credential-free identity preflight from inside the actual Pod:
private destination `10.43.243.148:8443`, original public TLS authority, invalid
session rejected with 401. The workspace profile and gateway patches were
applied, then the drift-checked ingress patch switched the public entry and
isolated `/moontown/workspace/`. No 443 changes were made.

Verified from the workstation over the real public 8443 endpoint:

- `/moontown/`: 200; town visibly loads without account/model provisioning.
- `/moontown/account/self.json`: signed-out public scope, no-store, Vary Cookie.
- `/moontown/connect`: 307 to `/moontown/workspace/connect`.
- `/moontown/workspace/connect`: 200; private account endpoint without login: 401.
- Public compute: exactly two curated Trial entries, no claimed live telemetry.
- New service probes: full 3D loader 200; private `town.json` 404; writes 405;
  cross-site account reads 403; unrelated product cookies remain signed out.

Browser verification on the production URL confirmed the town and complete
underground 3D model, Trial selection, and unknown—not failed/healthy—incomplete
telemetry labels. Screenshot: `output/moontown-public-live-20261023.png`.
The 16 browser identity/scope/snapshot tests were rerun and passed. Source UI and
uploaded UI matched with checksum-based dry-run comparison before packaging.

**Real-user acceptance is still pending.** The portal is signed out; the owner
has been asked to log in an authorized administrator, then a normal account for
resource-scope and cross-account isolation checks. The 5 live-candidate gateway
tests include simulated A/B/admin/revocation cases, but do not substitute for
this human-login acceptance. No ownership lease, paid grant, or operator role
was created. Both repositories remain on `main`; no commit/push in this turn.

## Initial domain and product entry decision — 2026-10-23 (historical)

The owner confirmed `suanli.kechuangfuwu.com` as the project domain. Reuse the
existing customer portal as the shared account entry; do not create a second
password form, a new account subdomain, or an unimplemented `/account/` site.
The account system is a platform capability, not a second MoonTown feature.

| Public path | Responsibility |
| --- | --- |
| `/user/` | Shared sign-in/account entry, organizations and owned services |
| `/moontown/` | Town and 3D rooms; account-authorized compute presentation |
| `/moondesk/` | Workbench using the same platform identity |
| `/mana/` | Operator console; separate operator authorization remains required |
| `/docs/` | Product help |

Use `https://suanli.kechuangfuwu.com:8443` as the current external origin. A
credential-free GET to `/user/` returned HTTP 200 on 2026-10-23; the same request
on 443 failed its TLS connection from this workstation. This checks reachability,
not authenticated acceptance. Do not silently remove `:8443`. An approved 443
deployment may use the same paths, but must migrate gateway Host/Origin,
OIDC callbacks, workspace public origin and port-specific session cookies
together. Existing 443-hosted UI links stay on 443; local preview links use the
verified 8443 entry. The initial domain selection changed no public DNS, TLS,
ingress or live account settings. The subsequent private connectivity resources
and their verification are recorded below; they add no public listener.

One account does not mean copying one bearer into every product. Reuse the
existing identity issuer/account ID and derive scoped product sessions; preserve
the enterprise/operator audience split. LunaNexa owns machine/lease access,
MoonGate owns model execution permissions, and MoonTown owns its product
entitlements. Login alone grants neither an admin role nor a paid subscription.

## Initial hosted integration: adapter outside personal workspaces (historical)

The current deployment is **not** a transparent reverse proxy to a shared
MoonTown process. `lunanexa/deploy/cluster/moontown-public.yaml` routes the town
through the WebIDE gateway to a per-user Pod/PVC. Its
`workspace/webide/bridge.mbt::proxy_http` deliberately strips browser cookies,
Authorization and forwarded identity. `moontown_scope_script` supplies a scoped
storage namespace; that namespace is not an identity credential.

Consequently, configuring the cookie-based adapter inside those Pods is not a
working hosted integration. Do not fix that by forwarding the platform cookie
or installing an operator credential in the workspace. The target design is:

```text
Browser — /user/ shared account and existing portal launch
   │
   └─ /moontown/ trusted account/workspace gateway
        ├─ current identity + current workspace grant must agree
        ├─ account/compute BFF → subject-authorized LunaNexa self APIs
        ├─ execution adapter → account-scoped MoonGate routes (future)
        └─ user workspace → complete town/3D models, no platform credentials
```

The BFF (browser-facing backend adapter) belongs on the trusted platform tier,
not a tenant-editable workspace. It exposes the existing narrow read contracts
at `/moontown/account/self.json` and `/moontown/secret-compute-room.json` before
workspace proxying, using the shared projection implemented in this repository.
This edge placement is now implemented as the independently deployable native
`src/account_gateway` module. It is a **release candidate, not a live route**:
production traffic has not been switched. Hosted federation must not be enabled
until the candidate passes its in-cluster preflight and real-user acceptance.
LunaNexa stays product-neutral; any platform-grant introspection contract belongs
there, while MoonTown UI/projection translation stays in MoonTown/MoonGate.

On every account/compute read, compare the authenticated identity against the
server-validated workspace grant, including the active organization/context.
Never use a browser-supplied subject ID or storage namespace as authority. If
portal user B replaced user A while A's workspace remains open, clear the old
projection and require reopening from the portal: do not show B's resources
inside A's workspace. Revocation, expiration and shared sign-out must revoke or
invalidate product grants too, including long-lived connections. Organization
changes must preserve or explicitly change the active workspace context.

Existing client handoffs are client/model/workspace delivery grants, not a
general-purpose local account login. Reuse them for portal-launched workspaces;
do not treat a redeemed model API key as a user session. For now, localhost
offers an “在线账户” link only. Local browser-to-app identity handoff needs a
separate approved scoped login flow; opening the online portal does not bind
the local preview.

### User-facing journey

1. Sign in once at `/user/`, then open MoonTown from the existing portal entry.
2. “我的算力” shows account name, authorized machines and observed status. Select
   an organization only when needed; do not ask for tenant IDs, tokens or URLs.
3. A single “账户中心” action opens the same portal. Missing binding says so;
   unknown telemetry stays unknown. Detailed diagnostics remain in Advanced.

The UI entry is implemented using the existing town button style, including a
screen-reader label for its new tab. It does not invent an automatic return
callback, replace the town with a login form, or mark a portal click as binding.

## Implemented boundary

- `account_identity` resolves the existing HttpOnly gateway cookie through
  `/auth/session` and revalidates the resulting short-lived bearer with
  `/v1/auth/self` on each read. Bearers stay server-side and are not persisted.
- The canonical MoonTown user ID hashes `(identity_issuer, account_id)`, not
  email or display name. It is the same in the account context and compute UI.
- `/account/self.json` drives frontend identity. When federation is enabled,
  a missing, revoked or unavailable session never falls back to a local user
  or creates a new anonymous account.
- Miniapp's common account boundary resolves the same cookie, ignores legacy
  local session tokens in federated mode, and checks same-origin cookie writes.
- `/secret-compute-room.json` only reads `/v1/machine-access/self` with the
  verified user's session. LunaNexa authorizes the subject, lease and selected
  organization. The former `/v1/nodes` operator-token inventory path is removed.
- A multi-organization response exposes only the user's active memberships
  from `/v1/portal/self/organizations`; the UI offers organization names, not
  editable tenant/subject identifiers. Every selection is reauthorized upstream.
- Stable lease-scoped machine references drive 3D selection. No proximity-based
  association with a physical rack is fabricated. Ended leases are omitted.
- Unknown hardware capacity, load, power and cooling metrics remain unknown.
  The current customer API exposes machine reachability, not node telemetry.
- Host-wide MoonGate routes are not the user's model permissions. The account
  projection leaves remote routes empty until an authenticated account-scoped
  MoonGate adapter is available; it does not infer access from provider names.
- Reads are bounded, timeout-protected and `no-store`. Account change/sign-out
  discards the compute snapshot and reloads the account context. Older unscoped
  compute payloads are not rendered as owned resources.

## Direct trusted-service configuration: opt in, do not silently migrate

Set these on **both** the desktop and miniapp services only after deploying a
trusted same-origin identity/proxy integration. This is the direct trusted
service mode, **not** an instruction to put credentials or this adapter into
the hosted personal workspace:

```text
MOONTOWN_ACCOUNT_PROVIDER=lunanexa
MOONTOWN_IDENTITY_ENDPOINT=https://suanli.kechuangfuwu.com:8443
MOONTOWN_IDENTITY_HOST=suanli.kechuangfuwu.com:8443
MOONTOWN_IDENTITY_ORIGIN=https://suanli.kechuangfuwu.com:8443
MOONTOWN_IDENTITY_PREFIX=/user
```

Use an empty prefix for an existing dedicated enterprise gateway host in the
direct-service mode. The hosted gateway explicitly requires `/user`. Only
HTTPS or a loopback HTTP upstream is allowed. Endpoint authority and configured
Host must agree: the HTTP library owns Host and does not support overriding it
with a second header. No operator token is needed. Public TLS uses system roots,
or an explicit `MOONTOWN_IDENTITY_CA_FILE`; controller `SSL_CERT_FILE` remains
separate. Certificate verification is never disabled.
The gateway must see its actual configured Host/Origin and audience; do not
forward arbitrary client identity headers or expose `/auth/session`'s bearer
response through MoonTown. The two new customer reads do not broaden the
desktop service's existing operator gate for other routes.

The browser must already have the existing gateway's cookie on the deployed
origin. A localhost preview cannot read a different production domain's cookie.
Do not copy browser cookies, use an administrator token, or treat a public
portal link as an SSO callback. A local desktop login needs an approved broker
handoff/session mechanism, or the town must be served behind the shared origin.
The production domain and entry are now selected above. This change does **not**
activate federation or deploy to production; the hosted edge bridge is still
required. Do not relax the existing operator-only routes to admit ordinary
customer sessions.

When the provider variable is absent, existing local account mode is preserved.
Its host-wide compute inventory is still no longer presented as owned compute.
Unsupported/misconfigured nonempty providers fail closed, rather than restoring
local-token authority.

## Explicitly unfinished product integration

Identity, subscription, organization membership and resource access are separate
claims. An authenticated LunaNexa account is projected as `account_kind: member`
with public-town and `compute.own.view` rights only. Its existing identity role
does not grant MoonTown billing, workspace or administrator permissions.

Before enabling federation on a deployment with existing paid/enterprise users,
define and implement the authoritative MoonTown entitlement mapping/migration.
Do not match existing accounts by display name/email. Legacy portable package
transfer is denied in federated mode until its account/entitlement adapter is
implemented; a local transfer token cannot become a backdoor second login.
Legacy local billing, tenant/admin management and logout endpoints are also
denied in this mode because they independently resolve local tokens. Sign out
through the existing identity portal until a shared logout adapter is added.

Still needed: production activation and real two-account acceptance;
MoonTown product entitlement migration; account-scoped MoonGate routes/usage;
customer-authorized telemetry, dedicated endpoint/container projections; explicit
physical site/rack/slot assignment. The full 3D design models are preserved and
do not depend on these feeds being available.

### Ordered delivery and acceptance

1. Keep the existing 8443 origin and account portal. Add the trusted edge
   adapter with server-validated workspace-owner binding; do not alter the
   WebIDE cookie stripping or MoonTown operator gate.
2. Map MoonTown entitlements and shared sign-out without migrating users by
   email/name; preserve existing workspaces and paid grants.
3. Run real accounts A/B: A sees only A's machines; B sees only B's; forged
   organization IDs fail; switching accounts, organization, logout, expiry and
   lease revocation remove stale resources. Check the workspace-A/portal-B case.
4. Verify the served bundle against the tested release, portal launch, return
   navigation and complete 3D models. Keep prior immutable images for rollback.
5. Add authorized telemetry and MoonGate model permissions separately. Only
   then bind physical rack/slot IDs; design racks are not discovered inventory.

## Local verification

`moon run scripts/check-account-compute.mbtx` checks native identity/projection
contracts, unchanged legacy account policy, UI member/compute states and browser
transport/cache transitions. Fixtures are tests, not real account binding proof.

## Gateway candidate — 2026-10-23

Both MoonTown and the sibling LunaNexa checkout remain on `main`; no commit or
push was requested for this phase. Existing unrelated edits are preserved.

The gateway composes LunaNexa's provider-neutral WebIDE host with two optional
callbacks: browser-principal authorization and a post-authorization HTTP handler.
No MoonTown package or domain schema is imported into LunaNexa. The gateway is
a platform CPU process, never a tenant container or managed GPU-node component.

- The live portal subject must equal the controller-issued workspace owner on
  connect, every HTTP request and periodic WebSocket authorization. A mismatch
  removes only that workspace browser session, without deleting its PVC.
- Failed identity availability denies the request but does not revoke a valid
  workspace or interpret an outage as logout. Only concurrent identical-cookie
  checks share work; successful decisions are not cached between requests.
- The account and compute adapters run before workspace proxying. Cookies and
  browser authorization remain stripped from the workspace request.
- Organization is pinned to the workspace grant. A different client selector
  returns 403 and requires a new portal launch, never cross-organization reads.
- Local account/auth/portable-transfer endpoints remain denied until their
  unified-account entitlement adapter exists. `/miniapp/me` retains its existing
  `{account: ...}` response envelope.
- A plain-text 401 from the gateway clears old browser identity and compute
  data, not just JSON-shaped scope-change responses. Existing WebSockets check
  the opening session; a new HTTP request detects a changed browser cookie and
  removes the old workspace token. Upstream logout/revocation is also rechecked.

### Reproducible release inputs

`scripts/stage-account-gateway.mbtx` exports only the required MoonTown packages,
LunaNexa's committed WebIDE baseline plus the reviewed callback changes, and
module metadata. It excludes unrelated dirty controller/model/event code,
runtime state, credentials and user output. Build the resulting nested module
with `moon -C moontown/src/account_gateway build src/main --target native --release`.

The gateway and companion static UI are separate immutable candidate images.
`fetch-hosted-ui-base.mbtx` verifies the currently deployed workspace image by
digest; `package-account-ui.mbtx` replaces only image-owned `/opt/moontown/ui`
with the verified current bundle. The existing native workspace executables,
runtime libraries, entrypoint and `/workspace` data remain untouched. New native
identity/account logic lives in the gateway, not inside the workspace. The UI
contains the full current 3D models and excludes the private reference photograph.

`publish-account-gateway.mbtx` accepts only the two account-release repositories
on the existing private TLS registry and refuses an already-present release tag.
The current UI verifier checks 769 files, 70.4 MiB. Publishing a candidate image
is not a production rollout.

### Deployment verification boundary

The credential-free `--check-identity` mode requests the real identity endpoint
with a fixed invalid cookie and requires HTTP 401. It uses no account, controller
grant, Kubernetes token or workspace provisioning. It is connectivity/denial
evidence only, never proof that a real account or lease was bound.

The first pod preflights exposed a container-network path problem despite
successful host-native HTTPS probes. A private ClusterIP Service aliases the
existing Traefik HTTPS listener on port 8443, with gateway-only host mapping to
preserve the public hostname, SNI, Host, Origin and audience. Its NetworkPolicy
permits only DNS and that existing ingress; no general LAN/Internet egress or
new public listener is opened. Re-read the Service ClusterIP before rendering
hostAliases/NetworkPolicy for a different deployment. Do not switch production
while the in-pod probe or paired UI verification is failing.

Real A/B acceptance is pending user-completed login at the supported `/user/`
portal. Do not create accounts, extend leases, reset credentials, add administrator
roles or substitute fixture data to make that acceptance pass.

### Cluster result and real-account blocker — 2026-10-23

The final credential-free preflight Job `moontown-account-preflight-20261023-r9`
completed successfully in `aigc-acceptance-20260915`. It resolved the public
identity hostname to the intended private Service `10.43.243.148:8443`, verified
TLS for the unchanged public hostname, and received HTTP 401 for its deliberately
invalid cookie. This is transport/denial evidence, not successful account binding.

Two base-image permission defects were identified: its public CA bundle and
`/etc/nsswitch.conf` were root-readable only (0640). The gateway runs as UID 1000.
The existing non-root policy was preserved. A read-only 0444 ConfigMap supplies
the host's public CA bundle and `hosts: files dns` lookup configuration; the latter
is mounted at `/etc/nsswitch.conf`. Before that repair, the r8 probe succeeded but
resolved to the public address; it was not accepted as private-route evidence.
No private key was copied, and TLS verification was not disabled.

The applied supporting resources are the private Service, narrowly scoped egress
policy, and `moontown-browser-identity-ca` ConfigMap. The gateway Deployment and
workspace image profile remain unchanged. Published private candidates are:

- Gateway: `moon/moontown-account-gateway@sha256:7722c02728971de758a586d7d91dc40d7b8bbfa0c5f599b501ce0a89a730146a`.
- Paired UI: `moon/moontown-account-ui@sha256:3833fcd58534cdf4cd7127fba933cd2f3b4dee345d1177386bc1ca112ae8fbae`.

`prepare-account-rollout.mbtx` renders drift-checked patches and private rollback
snapshots but does not apply them. Its readiness timeout covers DNS plus all five
bounded probe attempts. The final prepared snapshot/patch directory on management
is `/home/HwHiAiUser/moon-public/work/moontown-account-20261023.2yE5o4/rollout-backup-r3`.

The user logged into real account A. Read-only portal inspection showed zero
machine-access records, no organization selected/available, and MoonTown marked
unconfigured/unavailable. Refreshing workspace permissions returned that the
current account lacks permission. No organization, resource lease, or permission
was created to bypass this result. A cannot currently launch an authorized
MoonTown workspace, so real A/B gateway isolation and owned-resource binding
remain **unverified**. The user was asked to log into an already-authorized B.

Verified targeted suites: 21 LunaNexa WebIDE tests, 23 account/compute tests,
2 gateway HTTP isolation tests, 25 UI MoonBit tests, and 14 browser-state tests
(85 total). These include A/B fixtures, foreign organization denial, cookie
stripping, expiry, and stale browser-state clearing. The full miniapp native
test compilation ran out of local disk space; it is not counted as passing.
The production UI verifier passed for 769 files / 70.4 MiB, preserving full models.
Do not describe either these fixtures or the portal's empty state as completed
real two-account acceptance.

### Account B and the .178/.179 ownership mismatch — 2026-10-23

The user completed the second login and identified `.178` and `.179` as expected
resources. The signed-in B portal loaded enterprise access, but showed zero
machine-access records and no managed machine applications. Unlike A, B has a
configured MoonTown client; its launch is disabled because no supported model is
currently callable. These are distinct blockers, not a failed password/login.

A management-side diagnostic read of the controller's exclusive-lease API found
no lease records for either live node. Kubernetes node addresses and the deployed
node agents independently confirmed these mappings:

| Expected address | Current LunaNexa / Kubernetes node ID | Matching exclusive leases |
| --- | --- | --- |
| `192.168.2.178` | `spark-57f5-98a504ed` | 0 |
| `192.168.2.179` | `spark-368c-0f2ee8b2` | 0 |

The diagnostic observed timestamp was `1792764226807` Unix milliseconds. It used
existing management authorization only to inspect these records; that authority
was not forwarded to a customer, workspace, browser or MoonTown feed, and is not
evidence of customer access. No credentials were logged or copied into this repo.
The normal controller GET also runs its existing expiry reconciliation; no lease
creation, renewal, reassignment or explicit termination was requested.

`event-qwen-178` and `event-qwen-179` Deployment definitions target these nodes,
but both currently request zero replicas. This does not establish physical
ownership, an exclusive customer grant, overall machine idleness or inference
readiness. Historical inventory/example node aliases are not live identifiers.

The implemented MoonTown feed covers **customer exclusive leases only**. It does
not yet cover platform-owned hardware visibility, operator-managed inventory or
authorized model services. These must be represented as separate access types,
not fabricated as paid/exclusive leases or inferred from an IP/display name.
The proposed next step is explicit, read-only owned-resource authorization for
the verified B principal (and confirmed organization if applicable), issued by
LunaNexa. Machine use/manage permissions and model invocation remain separate.
This proposal is not applied: the owner must confirm the intended resource
relationship before new access is granted.

The later browser session no longer retained the portal login; the local town
tab was left untouched and a fresh portal was opened for the next handoff.
Real A/B binding/isolation remains unverified, and production gateway/profile
activation remains pending. Both repositories remain on `main`.
