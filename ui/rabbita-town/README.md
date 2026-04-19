# Rabbita Town

This package is the browser-facing Rabbita frontend for `moontown`.

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
- responsive scroll-safe scene viewport
- stronger keyboard focus visibility

The current frontend model is still local/demo-driven. It is not yet attached to
a real town backend.

This package owns the Moontown operator dashboard only. It does not own the
generated MoonBook site that appears under live workspace directories such as
`.moontown/books/coding/site/`.

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
