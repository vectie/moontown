# Rabbita Town

This package is the first browser-facing Rabbita frontend for `moontown`.

It consumes the renderer-agnostic scene contracts from the root module:

- `username/moontown/ui/scene_layout`
- `username/moontown/ui/dashboard`
- `username/moontown/ui/scene_render`

The intent is to keep town orchestration and scene modeling in the main module,
while this package provides a browser shell that can be built for JS.

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
