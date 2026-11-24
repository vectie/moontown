# Cluster application refresh — 2026-11-11

Scope: MoonTown, MoonDesk and MoonRobo application services on management node
`ubuntu` / `192.168.2.173`. Existing GPU/model services, permissions, quotas,
physical bridges and training processes are outside this release.

## Sources

- MoonTown: fetched `github/main`, `ef19c952`; built in isolated checkout
  `/Users/kq/Workspace/moontown-release-20261111`. The ordinary checkout remains
  on its older mobile-review branch. Never deploy that older branch over the
  newer live guest/upload, invitation and sharing features.
- MoonDesk: `7fd15d83`, current working sources and local workspace dependencies.
- MoonRobo: current working sources, including uncommitted learning/cockpit
  work, on baseline `22ef620c`; it is not a clean tagged upstream release.
- Private source/build/rollback evidence:
  `/home/HwHiAiUser/moon-public/work/products-20261111-r1`.
  Local evidence: `output/cluster-products-20261111-r1/`.
- The original source receipt describes the initial checkout. `town-latest.json`
  supersedes its MoonTown entry. The transferred source archive SHA-256 is
  `e0b5229750eb5d2d56c5fd90aad5e6f152b2cd319c6a6ebfe5012cbad0463929`.
  `legacy-metadata.tgz` restores existing nested legacy MoonBit module boundaries.
  A later account-scope patch and its regression test are on branch
  `codex/cluster-refresh-20261111` in the isolated checkout.

## Qualified application artifacts

All references use the existing private registry prefix
`lunanexa-registry.lunanexa-registry.svc.cluster.local:5000/`.

| Application | Repository | Digest |
| --- | --- | --- |
| MoonDesk | `moon/hosted-apps` | `sha256:84a18bbdd50aae9b714528f19a248efd4364aa8269c1c98a6541412467857dde` |
| MoonRobo | `moon/hosted-apps` | `sha256:c3127565be01639c16d8ab188c006950f80c0ba8d27adfa5d206fb439f1a71fd` |
| MoonTown desktop/UI/templates | `moon/hosted-apps` | `sha256:083e402f1515d397ce441e89bba609f1e4bedf976186eb02ce47b3efb6f71217` |
| MoonTown account gateway | `moon/moontown-account-gateway` | `sha256:5baf6c9c2c930abf41ab2a4ba839adedf7cc80ee624145ccc64954928803325e` |

The account gateway includes the scope compatibility fix; the other three
application artifacts retain the captured application sources.

## Updated surfaces and persistence

- Updated all three personal launch profiles. Existing companion/model-proxy
  images and their credentials/permissions are preserved.
- Updated the active personal MoonDesk workspace and public MoonTown platform;
  backed up the complete three workspace/activity/creative PVCs while their
  writers were stopped. Same PVCs remain attached. No activity deadlines,
  generation limits, votes, accounts or grants were changed.
- Updated shared `moonrobo-jiaan` to a pinned complete image. Removed only its
  obsolete binary/UI hostPath mounts; retained the same state mount and its
  read-only/physical-execution boundary.
- Updated the two management-node user services. Immutable releases are
  `moondesk-20261111-r1` and `moontown-20261111-r1` below `moon-public/releases`.
  MoonDesk's `zz-products-20261111.conf` overrides only ExecStart; its existing
  environment remains. MoonTown uses the existing `moontown-current` symlink.
- Backups: `shared-robo-state.tgz`, `shared-suite-state.tgz`,
  `workspace-states.tgz`, original deployments/config maps, user-service units
  and previous MoonTown symlink target. All are private on the management host.
- Restarted six existing application gateways sequentially to load new launch
  profiles. Did not restart ComfyUI or change identity/controller deployments.

## Validation and pitfalls

- Linux native builds completed for all three applications and the account
  gateway. Matching browser builds and private canaries verified health,
  exact served HTML and bundled shell tools. Actual browser checks rendered
  Desk, the Town map and Robo; Robo resolved all 25 meshes (50 visual/collision
  loads) while retaining the pre-existing joint-map diagnostics and read-only
  physical state. No robot commands or model inference were submitted.
- Preserve existing `moon.mod.json` / `moon.pkg.json` files while exporting
  older nested dependencies. Omitting them makes their packages incorrectly
  join the parent module and breaks otherwise valid builds.
- Preserve each base image's glibc/loader. Replacing its newer platform libraries
  with Ubuntu 20.04 build-host libraries broke bundled tools in a private
  candidate. Rejected candidates were never promoted to production. Add only
  the required PNG/WebP/JPEG add-on libraries; verify both native health and cp.
- A public static UI image is not a full native Town runtime. The final personal
  image uses the qualified full runtime and explicitly includes
  `/opt/moontown/assets/templates/operator-request-policy.json` and the template
  directory expected by the workspace launcher.
- Use relative Vite asset bases for the shared root and gateway-mounted Desk/
  Robo builds. A build fixed to `/moondesk/` cannot serve its standalone root
  without the gateway rewrite.
- A first shared Robo service probe saw connection refusal immediately after
  rollout and triggered rollback. The completed release uses a distinct release
  revision and bounded connection-refused retries; its service health passed.
  Do not infer service endpoint readiness from a successful build or stale
  Deployment availability alone.
- Real login exposed a separate Town contract bug: account scopes were
  `account-sha256:<hex>`, but the frontend accepts `account-<64 lowercase hex>`.
  Normalize the backend digest tag; preserve the browser's isolation guard.
  The enhanced real HTTP fixture checks exact length, character set, two-account
  separation, anonymous mode, expiry and revocation. Focused native tests passed
  3/3; browser storage/isolation tests passed 7/7. This is not a full-suite claim.
- Native test execution needs the same pinned JPEG/WebP dependency search path
  as packaging. Existing compiler/deprecation warnings remain; do not describe
  the entire product as deny-warn clean.
- The real portal account is logged in, but its allowed GLM model is stopped.
  New private app handoffs are blocked by that existing model-readiness gate;
  no model was resumed or new entitlement granted for acceptance.

## Final acceptance

The real signed-in account's public MoonTown page renders the map after the
gateway hotfix. Its account endpoint returns `state=bound` and a canonical
`account-<64 hex>` storage scope. The browser's existing isolation check stays
intact. Native public identity/isolation tests passed 3/3 and browser storage
tests 7/7. `moon info` completed with existing warnings and no errors; no public
function/type signatures changed. Formatting-only differences from the newer
remote formatter were removed from the two hotfix inputs so their recorded
compiled-source and binary checksums remain directly verifiable.

All nine target Deployments are Ready 1/1 and the two shared user services are
active. Internal HTTPS 443/8443 serve the exact staged Town HTML and anonymous
scope. The external 8443 HTML also matches its staged SHA-256; one request took
0.152s, which is a smoke observation, not a latency benchmark. Final inventories,
image/source checksums and private canary logs remain in the release directory.
Private canary Pods and the local verification SSH tunnel are removed after
acceptance. Existing model-readiness gating limits the personal launch journey;
do not describe the blocked GLM-dependent handoff as a passing inference test.
