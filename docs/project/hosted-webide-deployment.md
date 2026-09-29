# Hosted MoonTown WebIDE

This is a portable, account-bound MoonTown profile. The desktop, miniapp and
browser UI live in a per-user workspace; MoonClaw and MoonGate are companion
processes in the same private Pod. The model stays in the model-serving tier.
Never package model weights or application credentials into these images.

1. Build the Linux amd64 native desktop and miniapp executables, then assemble
   the production `src/ui/rabbita-town` browser files. The assembled UI must
   contain `platform-scope.js` and `platform-base.js` before `bootstrap.js`.
2. On the Linux build host, run `moon run scripts/package-hosted-webide.mbtx`
   with the OCI base tar, both binaries, assembled UI directory, reviewed
   operator-policy JSON, a new work directory and the desired image tag, in
   that order. Import the resulting `.oci.tar` to your registry and pin the
   resulting digest. Build the MoonClaw/MoonGate companion image separately.
3. Configure LunaNexa's `moontown` client catalog entry to launch at
   `/moontown/connect`. Its gateway gets the two pinned images, a workspace
   storage class, control-plane and model-gateway origins, the trusted CA, and
   the `/moontown` public base path. LunaNexa provides a reusable gateway and
   ingress template in `deploy/examples/hosted-moontown.yaml.tpl`.
4. Redeem a one-use portal handoff. Verify each account sees its own saved
   workspace, that the policy guide uses only its granted `moongate/<alias>`,
   and that a second account cannot read the first account's browser storage
   or workspace volume. Stop/reopen the session and check persistence.

The browser scripts leave standalone root-mounted development unchanged. A
hosted session fails closed until the authenticated gateway supplies its
workspace scope; a public URL alone cannot select another user's workspace.
Cluster addresses, subject IDs, pinned deployment digests and secrets belong
only in the deployment environment, not this repository.
