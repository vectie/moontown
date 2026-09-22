# Managed MoonTown service

MoonTown uses the same management-node user-service lifecycle as MoonDesk,
but owns port 5007. Port 5006 remains the identity service. The public instance
shares the configured MoonSuite workspace and is currently **PlatformOperator
only**, not a tenant-isolated ordinary-user deployment.

Build the browser product with `zsh scripts/build-rabbita-ui.sh`; this reuses
the existing assembler and artifact verifier. Build the Linux executable with
`moon build src/cmd/desktop_server --target native --release` on Linux. Copy
that executable as `moontown`, `src/ui/rabbita-town/dist` as `ui`, and the
`assets/templates` directory into a new immutable release directory. Keep
user data in the separately configured `MOONSUITE_ROOT`, never in a release.

Install `deploy/moontown.service` under the user's systemd directory and the
reviewed `deploy/moontown-service.env.example` as `.config/moontown/service.env`.
Point `moon-public/releases/moontown-current` to the verified release, reload
the user service manager, and enable the service. Roll back by pointing the
symlink at the preceding verified release and restarting this service only.

## Access boundary

`MOONTOWN_PUBLIC_HOST` enables the public access gate for every route except
the content-free `/health` endpoint. The exact Host is checked. Every request
resolves its HttpOnly identity cookie through the existing identity gateway,
then checks `/v1/auth/self` for **Active + PlatformOperator**. Caller-provided
role headers, static operator keys, and bare bearer tokens cannot grant access.
Identity failures deny access. Public mutations require an exact Origin in
addition to the existing bounded JSON write checks.

The login form forwards credentials to `/auth/password` on the platform
identity gateway and returns only its HttpOnly cookies, never its bearer
response. Passwords are not saved. A successful login returns to the same `/`
on port 5007; there is no caller-selected redirect URL. HTTP transport matches
the current explicit no-outer-TLS deployment choice, and must not be described
as encrypted transit. Do not expose this HTTP profile to an untrusted network.

Verify health, anonymous UI/API rejection, forged cookies, wrong Host,
cross-origin writes, non-operator denial, real operator login and a loaded
browser UI before calling a release live. A build alone is not acceptance.

## 2026-09-22 acceptance

- Management release: `moon-public/releases/moontown-20260922-r3`, supervised
  by `moontown.service`; public URL `http://106.39.18.146:5007/`.
- The user opened the outer TCP 5007 mapping. Identity on 5006 was untouched.
- Public health 200; anonymous UI/API and forged cookie 401; incorrect Host
  and cross-origin login 403. An actual EnterpriseUser login was denied 403.
- A temporary Active PlatformOperator completed the real identity password
  flow, received HttpOnly cookies, and opened the fully rendered map through
  the public URL. The browser reported no error/warning logs at that checkpoint.
- Native desktop tests: 40/40. Browser MoonBit tests: 709/709. Production
  static artifact verifier: 277 files, 68.4 MiB. Existing deprecation warnings
  remain; this is not a deny-warnings-clean repository.
- This deployment intentionally packages the current mixed working tree,
  including the user's existing uncommitted scene/UI work. The deployment
  adaptation commit does **not** claim those unrelated changes as its own.
- The outer gate authenticates platform operators. The inner town's visitor
  and resident/avatar creation model is separate; account/role federation into
  that model is not part of this deployment claim.
- A real Guide answer passed after restoring the missing distributed model
  rank; see the initial failure and successful retest below. Multi-day soak
  remains unproven. Persistent product data stays under
  `/home/HwHiAiUser/moonsuite`, outside the release directory.

The service environment selects the installed MoonClaw binary and MoonBook
launcher explicitly; it does not rely on an interactive shell PATH or source
checkout fallback. The town guide is a separate integration: it calls the
MoonClaw **gateway** `/v1/agent` and `/v1/rpc` on loopback 18123, not the
daemon's port 8090.

## Private Guide gateway

Build MoonClaw's `cmd/gateway` native release with the HTTP API bearer fix
(`4162d766`) and standalone/input fixes (`63cac1e3` or newer). Install it as `moonclaw-gateway` next to the MoonTown
executable. The existing 8090 daemon remains unchanged. Install
`deploy/moontown-guide.service` in the same user service manager.

Run `scripts/bootstrap-guide-gateway.mbtx PRIVATE_CONTROL GATEWAY_HOME TOWN_ENV`
with MoonBit on the management node. `PRIVATE_CONTROL` is the existing paired
MoonClaw control file, `GATEWAY_HOME` is a new dedicated directory such as
`/home/HwHiAiUser/.local/share/moontown-guide`, and `TOWN_ENV` is the private
MoonTown service environment. The script checks the instance-bound 8090 route,
requires ready MoonGate on loopback 5883, and creates an independent random
gateway bearer token in mode-0600 files. It never returns that credential to
the browser. Existing gateway configuration is not overwritten or rotated.

The gateway's local `default` model alias is mapped to the live route's exact
model ID at bootstrap, with `/openclaw/v1` as the provider endpoint. This is
separate from MoonGate's Codex-facing `/v1/models` catalog and does not change
the MoonGate service or its upstream credentials. Reconfigure this private
alias explicitly if the operator changes the underlying model route.

Enable the guide unit and restart MoonTown after configuration. Verify that
18123 binds only 127.0.0.1, `/health` works, and unauthenticated `/v1/agent`,
`/v1/rpc`, and `/v1/runs` return 401. Then verify a real question through the
authenticated public MoonTown UI. Neither 18123 nor 5883 needs a public port.

`moon run scripts/smoke-guide.mbtx http://106.39.18.146:5007 COOKIE_JAR`
is the opt-in live regression check: it requires a real operator cookie and
fails on HTTP errors or an empty agent completion. It sends only a short
generic onboarding question, not workspace files or private content.

### Live Guide result (2026-09-22, 18:42 CST)

- The final private gateway runs the HTTP-bearer, standalone-argument and
  queued-user-input fixes. Loopback health returns 200; anonymous API calls
  return 401; the authenticated gateway CLI health succeeds. The existing
  MoonClaw daemon on 8090 and MoonGate on 5883 remain active and unchanged.
- The authenticated route probe identifies `GLM-5.3-Flash-EXL3`. One direct
  non-streaming `/openclaw/v1/chat/completions` request with `max_tokens: 32`
  timed out after 60 seconds with zero response bytes.
- One real public-browser Guide question, submitted at 18:41:22, reached
  the gateway and selected that configured model, but produced no answer
  before the 55-second bound. The UI showed a truthful unavailable/timeout
  state and re-enabled the input. This is **not** a successful inference
  acceptance; no GPU or model-serving configuration was changed to mask it.
- Temporary identity cleanup is coordinated with the concurrent platform
  authority/renderer acceptance tests; do not revoke that shared smoke account
  until those tests finish. The operator-only service does not depend on the
  continued existence of the smoke account.

### Corrected inference diagnosis (2026-09-22, read-only inspection)

The timeout must **not** be attributed specifically to MoonGate. A minimal
eight-token request sent directly to `192.168.2.178:8888` also timed out after
45 seconds with zero response bytes. That endpoint's `/health` and `/v1/models`
returned 200; those checks prove HTTP liveness/catalog access, not successful
inference. Zero running/waiting counters likewise do not prove that the
distributed engine can execute a request.

The serving process is a two-node, tensor-parallel-size-2 vLLM deployment:

- Head: `192.168.2.178`, fabric address `10.0.22.1`.
- Worker: `192.168.2.179`, fabric address `10.0.22.2`; fabric SSH hostname and
  worker logs independently identify rank 1 with NCCL world size 2.
- Worker logs show shutdown at 17:45:49 and exit at 17:46:00, exit code 0,
  `OOMKilled=false`. The head subsequently logged a shared-memory broadcast
  block unavailable for 60 seconds, repeatedly.
- A **separate benchmark** container, `lunaflux-spark-vllm-ncu`, ran from
  18:10:29 to 18:44:31 and exited 137 with `OOMKilled=true`; kernel logs show
  global OOM. The fourth node later recovered to Kubernetes Ready, but the
  GLM worker remained exited. Do not conflate the later benchmark OOM with
  the earlier clean exit of the serving rank.

The missing serving rank makes this two-node model unavailable even though
the head's health endpoint responds. Fixing a MoonTown or MoonGate queue alone
cannot restore the absent worker. At this checkpoint, further inference retries
were paused until the benchmark owner coordinated restoration of both serving ranks. No GPU,
benchmark, or model-serving configuration was changed during this inspection.

### Successful real-browser retest (2026-09-22, 19:04 CST)

After the benchmark owner released the resources, the recovery operator
restarted the existing GLM head/worker containers without changing their image
or inference stack. Independent probes then returned real `hello` output:
direct model endpoint HTTP 200 in 0.490 seconds and MoonGate HTTP 200 in
1.088 seconds. These probe timings are not the full Guide response latency.

The dedicated 18123 gateway still held one old pending request from the outage.
Only `moontown-guide.service` was restarted; the existing 8090 daemon, MoonGate,
and GPU services were not changed by this MoonTown retest.

A fresh Safari tab opened the public `http://106.39.18.146:5007/` page,
completed the actual platform password login using the temporary operator,
loaded the town, opened 小爪, and submitted:

> 请用一句话告诉我如何开始使用 MoonTown。

The real Guide answered visibly in the page:

> 点击屏幕上可见的「创建角色」按钮建立你的专属头像，之后就可以通过地图、底部工具栏和仪表盘开始探索并建设你的 MoonTown 小镇啦。

The input returned to its ready state, and the authenticated gateway health
reported zero pending requests. Screenshot evidence is saved locally as
`.shots/moontown-guide-success-20260922.png`. This verifies one actual
browser → Town → private MoonClaw gateway → MoonGate → GLM response, not
scripted resident dialogue or a health-only probe. It is not a claim of
exhaustive model-answer accuracy, full user-role federation, or long-term HA.
