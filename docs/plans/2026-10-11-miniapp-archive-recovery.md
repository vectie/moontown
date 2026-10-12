# Plan: recover archived local mini-app buildings

## Problem and scope

The existing dependency-free Node mini-app development service can archive a
building, but the normal snapshot hides it and there is no list or restore
operation. A local user cannot resume that building's conversation without
editing the JSON state file. Add one inspect-and-restore workflow to this
existing fixture service, preserving the same identity and retained records.

MOONTOWN-UC05/B05 in the 30 September 2026 product PRD motivates inspecting exact
durable records and intervening within owning-service authority. The repository
PRODUCT_CONTRACT requires persistent, recoverable town records; WENYU_VALLEY_PRD
§2 and §8 preserve knowledge ownership and explicit publication boundaries.
This is a bounded development-service extension, not fulfillment of the PRD's
native visual-item acceptance or production recovery requirements.

## Document Protocol Fit

- Source of truth: the explicit local mini-app JSON state, not MoonBook truth.
- Protocol owner: the existing Node mini-app service's building lifecycle.
- Agent roles: none; no provider or worker is launched.
- Ledgers: append a building.restored audit event in the same saved state.
- Review gate: the local operator inspects the archived version then explicitly
  restores that version; publication remains a separate existing operation.
- Projection: GET archive list and the existing town snapshot; no UI is added.

## Affected files and implementation steps

1. Extend scripts/miniapp-local-backend.mjs with GET archived list and POST
   restore. Require the inspected version for restoration. Keep the executable
   entry point, expose the service functions for portable focused tests.
2. List only buildings editable by the current local fixture user, with retained
   record counts and the non-public restoration visibility.
3. Restore personal buildings to private_draft and fixture organization buildings
   to shared_private; preserve identity, book reference, content and history.
4. Add executable route/HTTP-adapter and save/reload tests, plus exact operator
   documentation, a docs index entry and explicit local-only qualification.

## Acceptance criteria and validation

- An archived building is discoverable only through the editable archive list.
- Restoring its current version returns it to the same user's snapshot with its
  original related records and one durable audit event, including after reload.
- A formerly published personal building is restored privately, not republished.
- The second fixture user cannot list/restore the first user's personal archive.
- Stale selections and non-archived targets change no state.
- Old version-1 state files need no migration.
- Run node --test scripts/miniapp-archive-recovery.test.mjs
  scripts/miniapp-session-retention.test.mjs and node --check on the service.
- No MoonBit files or interface metadata change; Moon/native/browser/provider and
  full product tests are not run or qualified. No dependencies are installed.

## Rollback

Revert this source commit. Restore only changes existing building visibility,
version, timestamp and audit events, all already supported by the old schema.
Retain the local state file as evidence; do not overwrite or remove histories.
