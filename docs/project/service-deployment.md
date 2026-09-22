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

- Management release: `moon-public/releases/moontown-20260922-r1`, supervised
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
- Model execution, live agent success, and multi-day soak are not proven by
  this UI deployment. Persistent product data stays under
  `/home/HwHiAiUser/moonsuite`, outside the release directory.
