# Moonclaw Phone Mascot Plan

## Status

- State: Accepted
- Owner: MoonClaw Worker
- Created: 2026-08-08
- Updated: 2026-08-08
- Related book: `none`
- Related run: `none`

## Problem

The Energy Valley front page has a useful virtual phone, but its floating entry
looks like a generic utility and is unavailable before avatar creation. The
phone also separates fictional local resident replies from read-only runtime
Agent projections, so it currently has no truthful path for asking a live
Moonclaw Agent how Moontown works or what to do next.

## Current State

- `src/ui/rabbita-town/main/town_phone.mbt`: phone contacts, conversation UI,
  local scripted replies, and read-only runtime contacts.
- `src/ui/rabbita-town/main/energy_valley_page.mbt`: canonical front-page
  composition and overlays.
- `src/cmd/desktop_server/main.mbt`: same-origin trusted local desktop API.
- Moonclaw gateway: loopback `POST /v1/agent` plus RPC `agent.wait`.

## Goal

Make a persistent corner mascot the memorable entry into the existing phone.
Clicking it opens a dedicated Moonclaw Guide contact. Guide messages travel
through Moontown's same-origin desktop service to a validated local Moonclaw
gateway session, with loading, success, and failure states clearly labelled.

## Non-Goals

- Do not turn fictional resident scripts into AI responses.
- Do not make runtime Agent projections writable.
- Do not expose Moonclaw gateway tokens to browser code.
- Do not let the guide silently create work, edit files, or claim actions.
- Do not add a second chat history or competing chat panel.

## Research / Context Inputs

- Existing product uses the phone as its single resident conversation surface.
- UI review guidance favors one stable entry, progressive disclosure, labelled
  icon controls, visible async feedback, announced errors, 44px touch targets,
  responsive panels, and reduced-motion support.
- Moonclaw's gateway supports direct agent requests, stable session keys, and a
  bounded wait RPC on the loopback service.

## Operating Architecture Fit

- Durable source of truth: existing TownLife phone event log for visible chat
  history; Moonclaw owns its own agent session continuity.
- Active protocol/place: Moontown desktop `POST /api/agent/chat` proxy to the
  loopback Moonclaw gateway.
- Mayor responsibility: none.
- MoonBook bookkeeper responsibility: none.
- MoonClaw worker responsibility: answer product-navigation questions without
  taking actions.
- Civic building responsibility, if any: none.
- MoonDesk responsibility, if any: serve the same-origin desktop surface.
- Return-home target: Energy Valley phone panel.
- Review gate: MoonBit checks/tests plus rendered desktop and mobile inspection.
- Projection/UI surface: canonical Rabbita Energy Valley front page.

## Generated-Tool Capability Fit, If Applicable

- Requires generated-tool capability: no

## Design Decision

Use one phone system. Replace the generic phone FAB with a code-native Moonclaw
pet button that opens a first-class `moonclaw-guide` contact. The guide gets
one-click starter questions, reuses phone history and composer behavior, and
calls a same-origin endpoint. The native desktop service strictly accepts
loopback gateway configuration, bounds request/response sizes, keeps auth on
the server, and prompts the agent as an explanation-only Moontown guide.

## Alternatives Considered

| Option | Why rejected or deferred |
| --- | --- |
| Separate mascot chat panel | Duplicates history, composer, responsive rules, and user mental models. |
| Treat a runtime contact as writable | Runtime contacts are projections, not a guaranteed messaging transport. |
| Browser-to-Moonclaw request | Exposes gateway topology and credentials and complicates same-origin security. |
| Scripted mascot answers | Would not satisfy the live Moonclaw Agent requirement and could misrepresent freshness. |

## Affected Files

| File | Expected change |
| --- | --- |
| `src/town_contract/contract.mbt` | Declare the desktop guide endpoint. |
| `src/cmd/desktop_server/moonclaw_guide.mbt` | Validate, prompt, proxy, and parse Moonclaw responses. |
| `src/cmd/desktop_server/main.mbt` | Route the same-origin guide request. |
| `src/ui/rabbita-town/main/types.mbt` | Add guide request state/messages. |
| `src/ui/rabbita-town/main/town_phone.mbt` | Add the guide contact, mascot entry, composer states, and quick questions. |
| `src/ui/rabbita-town/main/browser_request_bridge.mbt` | Add the same-origin browser bridge and stable local session id. |
| `src/ui/rabbita-town/styles/town-life.css` | Style the pet and guide states responsively. |
| focused `*_wbtest.mbt` files | Cover contracts, validation, and state transitions. |

## Implementation Steps

1. Add a tested native proxy contract with loopback-only gateway resolution.
2. Add guide state and async effects to the existing phone model.
3. Replace the phone FAB presentation with the Moonclaw pet entry.
4. Add guide-specific quick questions, loading/error feedback, and truthful labels.
5. Run package and full checks, build the UI, and inspect rendered desktop/mobile states.

## Acceptance Criteria

- [x] The mascot remains reachable on the front page before and after onboarding.
- [x] Clicking the mascot opens the phone with Moonclaw Guide selected.
- [x] The normal phone contact list and existing resident/runtime behavior remain intact.
- [x] Guide messages use a real local Moonclaw gateway session through same-origin Moontown.
- [x] Loading, unavailable, invalid-response, and success states are visible and announced.
- [x] The proxy rejects non-loopback gateway URLs and oversized/invalid input.
- [x] The guide is instructed to explain only and not claim or perform actions.
- [x] Touch, keyboard, reduced-motion, desktop, and narrow-screen behavior are verified.
- [x] The relevant tests/checks pass and the production UI builds.

## Validation Commands

```bash
moon test src/town_contract src/cmd/desktop_server
moon -C src/ui/rabbita-town check --target js main
moon -C src/ui/rabbita-town test --target js
moon check
moon test
moon info
moon fmt
./scripts/build-rabbita-ui.sh
```

## Growth / Monitoring Evidence

- Code/tests: guide proxy and phone integration receive focused tests.
- UI/projection: one mascot entry opens one existing phone with a new live guide contact.
- Explicit no-change record: fictional residents remain locally scripted; runtime
  contacts remain read-only projections.

## Rollback / Recovery

Remove the guide route/contact/state and restore the original phone FAB markup
and styles. Existing persisted phone events remain valid because guide messages
use the existing optional contact string rather than a new persistence schema.

## Execution Log

- 2026-08-08: Inspected the canonical Energy Valley composition, phone truth
  boundaries, desktop write checks, Moonclaw gateway request/wait flow, and UI
  accessibility guidance. Selected the integrated phone-contact design.
- 2026-08-08: Added the same-origin loopback-only Moonclaw proxy, stable guide
  session, first-class phone contact, code-native corner pet, quick questions,
  persisted visible history, and announced loading/error states.
- 2026-08-08: Browser-validated the front page and phone at 1440x900 and
  390x844. Reworked the narrow phone contact list into a compact horizontal
  strip and kept the mascot inside the avatar dialog's modal boundary.
- 2026-08-08: `moon check`, 1,143 root tests, 32 focused native tests, four
  focused JS guide tests, `moon info`, `moon fmt`, and the 162-file / 49.9 MiB
  production Rabbita build passed. A live gateway was not present, so runtime
  smoke validation covered the explicit HTTP 503 unavailable state; accepted
  and completed Moonclaw gateway payloads are covered by native parser tests.

## Review Notes

- Runtime validation distinguishes a gateway being unavailable from an Agent
  returning an empty or malformed completion. Operators can validate a live
  model reply after starting the loopback gateway documented in
  `docs/DEVELOPMENT.md`.
