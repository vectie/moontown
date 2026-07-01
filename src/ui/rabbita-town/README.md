# Rabbita Town

This package is the browser-facing Rabbita frontend for `moontown`.

It uses the published Rabbita frontend stack:

- `moon.mod` imports `moonbit-community/rabbita@0.12.4`.
- `moon.work` only binds this nested frontend and the local Moontown source tree.
- `package.json` imports the published `@rabbita/vite` package instead of a
  local `../rba` checkout.

Lepusa is intentionally not imported here yet. If Moontown gains a native
desktop shell, that target should import the published `vectie/lepusa` package
from its own MoonBit module instead of wiring to a local `../lepusa` checkout.

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
- pause/resume/step controls
- strategy switching
- runtime summary bar
- packet/import/run/persist/review stage rail
- scene-based selection and inspector state
- moving worker avatars
- packet/proposal/run lifecycle visibility
- budget/energy/pressure/stability metrics
- activity feed and anomaly surfacing
- Mayor command center with real standing-goal progress
- watcher decision timeline from `.moonsuite/products/moontown/watchers/*.jsonl`
- local standing-watch request composer
- dashboard portal to the canonical standalone Wenyu viewport
- generated Wenyu Valley tilemap viewport with animated resident overlay
- stronger keyboard focus visibility

The current frontend can run in demo mode, but the dev server also bridges real
runtime files:

- `.moonsuite/products/moontown/town.json`
- `.moonsuite/products/moontown/daemon.json`
- `.moonsuite/products/moontown/standing-goals.json`
- `.moonsuite/products/moontown/watchers/watch-opc-news.jsonl`
- `.moonsuite/products/moontown/operator-requests/requests.jsonl`

The Mayor command center uses those files to show progress, next due tick,
latest watcher decision, source delta count, and decision mix. The request
composer posts to `/api/operator-requests`, writes an operator request record,
and creates or replaces a standing goal in
`.moonsuite/products/moontown/standing-goals.json`.
The daemon then picks that goal up during its normal standing-goal dispatch
cycle.

The request composer reads its default standing-goal source policy from
`../../../assets/templates/operator-request-policy.json`. The browser/Vite
layer must not own source-policy vocabulary; it only applies the document
contract when turning a user request into a durable Mayor queue item.

The dashboard intentionally does not embed a second scaled copy of the Wenyu
map. It links to `viewport.html?assets=generated&v=wenyu`, which is the
canonical generated-tilemap viewport used for visual inspection.

This package owns the Moontown operator dashboard only. It does not own the
generated MoonBook site that appears under live workspace directories such as
`books/coding/site/`.

Run locally from this directory:

```bash
moon check
moon info
npm install
npm run dev
```

Build the production bundle from the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

Outputs land in `ui/rabbita-town/dist/`.

## Important Files

- `main/main.mbt`
  - Rabbita app model, update loop, and scene rendering
- `styles.css`
  - dashboard styling
- `index.html`
  - page shell
- `bootstrap.js`
  - browser entry
- `vite.config.js`
  - Vite integration
