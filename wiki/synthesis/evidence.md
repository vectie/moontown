# Evidence notes

## Current durable evidence set used in this step

The approved plan names raw bootstrap packets as the primary factual anchor, but those packet files were not present in this worktree during this execution step. To avoid overclaiming while still making durable progress, the revised pages in this step cite repository-local docs and code only:

- `README.md`
- `docs/ARCHITECTURE.md`
- `docs/PACKAGES.md`
- `adapters/moonbook/client.mbt`
- `adapters/moonclaw/client.mbt`
- `roles/mayor.mbt`

## Added durable pages

- [Moontown-MoonBook-MoonClaw stack](../sources/moontown-moonbook-moonclaw-stack.md)
- [Layered town-book-runtime stack](../concepts/layered-town-book-runtime-stack.md)

## Caution policy applied

- preserve the distinction between documented intent and code-backed seams
- avoid diagnosing `Unknown provider task target: moonbook` without direct packet evidence
- avoid asserting unverified MoonBook or MoonClaw internals beyond the interfaces visible from this repo
