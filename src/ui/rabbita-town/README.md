# Rabbita Town

This package is the browser-facing Rabbita frontend for `moontown`.

It uses the published Rabbita MoonBit stack:

- `moon.mod` imports `moonbit-community/rabbita@0.12.4`.
- `moon.work` only binds this nested frontend and the local MoonTown source tree.
- `package.json` only declares Node's ES-module semantics for checked-in browser
  and verification scripts; it has no package dependencies or lockfile.
- the production build copies MoonBit's release `main.js` directly and does not
  invoke npm, Vite, React, TypeScript, or another frontend bundler.

The product boundary is MoonBit-only:

- this nested package authors the browser surface in MoonBit with Rabbita;
- the root module imports the published `vectie/lepusa` package;
- `lepusa.json` packages this compiled surface with the MoonBit desktop server.

JavaScript in this directory is browser, local-server, and build verification
glue. Product state, rendering, town generation, work projection, and
interaction behavior remain in MoonBit source.

It consumes the renderer-agnostic scene contracts from the root module:

- `vectie/moontown/ui/scene_layout`
- `vectie/moontown/ui/dashboard`
- `vectie/moontown/ui/scene_render`

The intent is to keep town orchestration and scene modeling in the main module
while this package provides a browser shell that can be built for JS.

## Current UI Model

This frontend is a live simulation dashboard, not a static renderer.

It currently includes:

- live tick loop
- scene-based selection and inspector state
- moving worker avatars
- professional town pulse and attention summary
- Wenyu Valley map workspace entry
- request desk with standing-watch and PDF evidence-book creation paths
- attention workbench with priority guidance and activity ledger
- generated Wenyu Valley map with animated real-agent overlay
- deterministic procedural building interiors with runtime work stations
- stronger keyboard focus visibility

The current frontend can run in demo mode, while the MoonBit desktop server
bridges real runtime files:

- `.moonsuite/products/moontown/town.json`
- `.moonsuite/products/moontown/daemon.json`
- `.moonsuite/products/moontown/standing-goals.json`
- `.moonsuite/products/moontown/watchers/watch-opc-news.jsonl`
- `.moonsuite/products/moontown/operator-requests/requests.jsonl`

The default dashboard summarizes town pulse, map entry, safe request creation,
and attention work without rendering runtime drill controls, vitality metrics,
or duplicate brief/focus side panels. The request desk posts to
`/api/operator-requests`, writes an operator request record, and creates or
replaces a standing goal in
`.moonsuite/products/moontown/standing-goals.json`.
The daemon then picks that goal up during its normal standing-goal dispatch
cycle.

The request composer reads its default standing-goal source policy from
`../../../assets/templates/operator-request-policy.json`. The browser layer
must not own source-policy vocabulary; the MoonBit desktop server applies the
document contract when turning a user request into a durable Mayor queue item.

The packaged entry opens the Wenyu Valley workspace directly. Districts,
residents, standing watches, active work, procedural interiors, and evidence
handoffs are inspected in place.

This package owns the MoonTown operator dashboard only. It does not own the
generated MoonBook site that appears under live workspace directories such as
`books/coding/site/`.

Check the MoonBit frontend from this directory:

```bash
moon check
moon info
```

Build the deterministic static product from the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

The script formats and checks the MoonBit package, compiles its JS release
entry, assembles the browser glue/CSS/product assets, writes a content-hashed
`asset-manifest.json`, and verifies the result. Outputs land in
`src/ui/rabbita-town/dist/`.

For live runtime data, serve that directory through the MoonBit desktop service
(the same localhost service started by Lepusa). A plain static file server can
show the shell, but it cannot provide the town ledgers or safe request
endpoints.

## Important Files

- `main/main.mbt`
  - Rabbita app model, update loop, and scene rendering
- `styles.css`
  - dashboard styling
- `index.html`
  - page shell
- `bootstrap.js`
  - browser entry
- `scripts/assemble-production-build.mjs`
  - deterministic no-bundler artifact assembly
- `scripts/verify-production-build.mjs`
  - release allowlist, integrity, and dependency-boundary checks
