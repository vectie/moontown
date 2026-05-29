# Planbook Documentation Reorganization

## Status

- State: Accepted
- Owner: Mayor + Human Operator
- Created: 2026-05-29
- Updated: 2026-05-29
- Related book: `moontown-cookbook`
- Related run: none

## Problem

Moontown has research books and course books, but code/product planning is not
yet represented as a first-class durable book type. Planning currently happens
inside chat, docs, or ad hoc TODOs, which makes context recovery harder and can
turn implementation work into vague research.

## Current State

- [README.md](/Users/kq/Workspace/moontown/README.md): describes research,
  daemon, civic, and cookbook flows.
- [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md): describes
  stable-state control, but not active plan control.
- [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md):
  describes system boundaries but not planbook routing.
- [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md):
  describes validation commands but not a plan-first rule.

## Goal

Add a durable documentation structure that distinguishes:

- research books for knowledge discovery
- course books for learning material
- planbooks for implementation plans and quality gates
- cookbook for accepted stable state

## Non-Goals

- Do not implement the full MoonBook-native planbook route in this iteration.
- Do not change MoonClaw execution behavior in this iteration.
- Do not reorganize every existing Wenyu document into folders yet.

## Research / Context Inputs

- User-provided plan-first workflow description inspired by Compound
  Engineering and `plan.md` driven execution.
- Existing Moontown cookbook, daemon, research, course, and Wenyu docs.
- Current MoonBook course-routing work, which clarified the need for distinct
  book types.

## Design Decision

Create a small top-level docs layer:

- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
- [docs/DOC_STRUCTURE.md](/Users/kq/Workspace/moontown/docs/DOC_STRUCTURE.md)
- [templates/planbook/PLAN_TEMPLATE.md](/Users/kq/Workspace/moontown/templates/planbook/PLAN_TEMPLATE.md)
- [templates/planbook/PLANBOOK_CONTRACT.md](/Users/kq/Workspace/moontown/templates/planbook/PLANBOOK_CONTRACT.md)

Then link the model from README, architecture, cookbook, and development docs.

## Alternatives Considered

| Option | Why rejected or deferred |
| --- | --- |
| Put plans only in README | README is already long and should stay an entry point. |
| Put active plans in cookbook | Cookbook should record stable state, not every working decision. |
| Treat code plans as research books | Research output and implementation control have different quality gates. |
| Implement full planbook runtime now | The immediate need is clear docs and templates; runtime can follow. |

## Affected Files

| File | Expected change |
| --- | --- |
| `README.md` | Introduce planbook workflow and links. |
| `docs/ARCHITECTURE.md` | Add planbook to system architecture. |
| `docs/COOKBOOK.md` | Separate planbook active decisions from cookbook stable state. |
| `docs/DEVELOPMENT.md` | Add plan-first rule. |
| `docs/PLANBOOK.md` | Define planbook lifecycle and ownership. |
| `docs/DOC_STRUCTURE.md` | Define reading order and doc families. |
| `templates/planbook/*` | Provide reusable plan contract and template. |

## Implementation Steps

1. Add planbook docs and templates.
2. Update README, architecture, cookbook, and development docs.
3. Add this plan as a seed example.
4. Run whitespace validation.

## Acceptance Criteria

- [x] Research, course, planbook, and cookbook responsibilities are separated.
- [x] A reusable `plan.md` template exists.
- [x] README links to the new docs.
- [x] Architecture explains where planbook fits.
- [x] Cookbook remains stable-state focused.
- [x] Development docs include the plan-first rule.
- [x] The result can be continued from this plan by a new session.

## Validation Commands

```bash
git diff --check
rg -n "PLANBOOK|Planbook|planbook|DOC_STRUCTURE" README.md docs templates
```

## Rollback / Recovery

Remove the new planbook docs/templates and revert the README, architecture,
cookbook, and development doc references.

## Execution Log

- 2026-05-29: Added planbook model, doc structure map, templates, and README/doc
  links.

## Review Notes

The runtime implementation is intentionally deferred. Next technical step is a
MoonBook-native `planbook` template and `code-plan/SKILL.md` route, then
Moontown routing for build/fix/refactor requests.
