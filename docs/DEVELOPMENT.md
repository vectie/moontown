# Development Workflow

This is a multi-package MoonBit module with an additional Rabbita frontend
submodule.

## Core Commands

From the repo root:

```bash
moon check
moon test
moon info
moon fmt
```

Run the text dashboard:

```bash
moon run cmd/main
```

Build the frontend:

```bash
./scripts/build-rabbita-ui.sh
```

## Recommended Local Loop

For normal code changes:

```bash
moon check
moon test
moon info
moon fmt
```

For UI changes:

```bash
moon check
moon test
moon info
moon fmt
./scripts/build-rabbita-ui.sh
```

## Package Boundaries

Each directory with a `moon.pkg` is a separate package.

Important packages:

- `core`
- `dispatch`
- `experiment`
- `health`
- `scheduler`
- `storage`
- `roles`
- `adapters/moonbook`
- `adapters/moonclaw`
- `ui`
- `cmd/main`

`ui/rabbita-town` is its own nested module for the browser frontend.

## Persistence Files

Runtime state is stored under:

- `.moontown/moonbooks.json`
- `.moontown/town.json`

These are runtime artifacts, not source-of-truth project files.

## Testing Notes

Package tests currently cover:

- core state and package surfaces
- scene layout/render contracts
- mayor role behavior
- root demo path

If a change affects dashboard output or scene contracts, update the relevant
tests in:

- `moontown_test.mbt`
- `ui/scene_layout_test.mbt`
- `ui/scene_render_test.mbt`
- `roles/mayor_test.mbt`

## Docs Maintenance

When architecture or frontend behavior changes, update:

- [README.mbt.md](/Users/kq/Workspace/moontown/README.mbt.md)
- [docs/USAGE.md](/Users/kq/Workspace/moontown/docs/USAGE.md)
- [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md)
- [docs/PACKAGES.md](/Users/kq/Workspace/moontown/docs/PACKAGES.md)
- [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md)
- [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md)

Also update UI-local docs when relevant:

- [ui/rabbita-town/README.md](/Users/kq/Workspace/moontown/ui/rabbita-town/README.md)
- [ui/assets/README.md](/Users/kq/Workspace/moontown/ui/assets/README.md)
