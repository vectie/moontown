# Moontown Cookbook

The Moontown cookbook is the stable-state control book for the town.

It is not a new executor and not a replacement for source docs. It is a
MoonBook-generated workspace that indexes the canonical docs, machine-readable
definitions, and restart-readable runtime state needed to understand and repair
the town.

## Responsibility Split

- MoonBook generates and stores the cookbook workspace.
- Moondesk should manage the human desktop surface for editing, reviewing,
  packaging, and browsing cookbook material.
- Moontown consumes the cookbook manifest for stable-state checks, operator
  guidance, and drift detection.
- MoonClaw performs bounded cookbook maintenance tasks through skill-guided
  packets, such as summarizing drift or proposing doc updates.

## Generated State

The cookbook command writes:

```text
.moontown/cookbook/stable-state.json
.moontown/books/moontown-cookbook/wiki/index.md
.moontown/books/moontown-cookbook/wiki/definitions/stable-state.md
.moontown/books/moontown-cookbook/wiki/definitions/ownership.md
.moontown/books/moontown-cookbook/wiki/operating-procedures/doctor.md
.moontown/books/moontown-cookbook/raw/bootstrap/COOKBOOK_CONTRACT.md
.moontown/books/moontown-cookbook/schemas/stable-state-manifest.schema.md
.moontown/books/moontown-cookbook/book/moonbook-ui-state.json
.moontown/books/moontown-cookbook/book/site/generated/index.html
```

The stable-state manifest tracks three artifact classes:

- `doc`: canonical source documents such as architecture, usage, Wenyu PRD, UI
  module system, communication-pattern registry, and protocol plans.
- `definition`: machine-readable registries such as MoonBook catalog, civic
  protocol registry, communication-pattern schedules, and standing goals.
- `runtime-state`: restart-readable generated state such as civic status,
  protocol status, daemon heartbeat, and daemon runtime records.

Missing required artifacts are drift. Optional runtime artifacts may be absent
before the daemon, civic doctor, or recurring communication-pattern schedule has been started.

## Stable Doctrine

The cookbook should treat
[DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
as a stable architecture document once PlanBook accepts the rule. The summary
is:

```text
Everything durable is a document/book.
Everything active is a protocol running over documents.
Agents are temporary workers that read/write documents through protocols.
Buildings are protocol places.
```

This means cookbook drift checks should prefer stable files, manifests,
ledgers, and protocol documents over transient agent-run logs.

## Relationship To Planbooks

The cookbook is not the place where every active idea lives. It records stable
state after a decision has been accepted.

Use a planbook when the town needs to decide or implement:

- a code refactor
- a product change
- a UI redesign
- a daemon reliability fix
- a civic workflow change
- a docs reorganization

After the plan is accepted and validated, update the cookbook only if the
stable operating state changed.

```text
planbook
  -> active plan, acceptance criteria, execution log, review notes
  -> accepted change
  -> cookbook stable-state update
```

This keeps the cookbook from becoming a task tracker while still allowing it to
index the final accepted state.

## Commands

```bash
moon run cmd/main -- cookbook bootstrap
moon run cmd/main -- cookbook status
moon run cmd/main -- cookbook doctor
```

`cookbook bootstrap` creates or refreshes the control MoonBook and stable-state
manifest. `cookbook doctor` is an alias for bootstrap. `cookbook status`
renders a compact Markdown status report.

## Moondesk Role

Moondesk should eventually open this cookbook as the user-facing file manager
for town definitions:

- browse generated wiki pages and stable-state artifacts
- edit proposed cookbook pages before promotion
- package portable definitions into Moontown-compatible bundles
- compare cookbook state against live Moontown state
- show drift without making operational logs look like research progress

Moondesk should not own daemon supervision, mayor routing, or MoonClaw
execution. It is the human desk for stable definition management.
