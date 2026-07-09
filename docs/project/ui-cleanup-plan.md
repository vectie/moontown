# Moontown Professional UI Cleanup Plan

Moontown users should be treated as professional operators, researchers, and
district builders. They can understand concepts such as Mayor, MoonBook,
standing watch, review queue, worker, and evidence watch. They should not need
to understand runtime filenames, daemon identity, request ids, source bridge
state, or local development controls during normal use.

This cleanup track keeps Moontown technically honest while reducing visible
noise. The goal is not a consumer mini-app. The goal is a calm professional
surface with advanced runtime detail available on purpose.

## Audience Levels

| Level | User | Default visibility |
| --- | --- | --- |
| Professional | normal Moontown operator or expert user | town status, watches, map entry, review needs, requests |
| Advanced Operator | power user managing live operations | cadence, source health, exact watch ids, queue internals |
| Developer Diagnostics | maintainer debugging the app/runtime bridge | JSON filenames, request ids, source switching, ticks, bridge placeholders |

Default UI should serve the Professional level. Advanced Operator and Developer
Diagnostics content should be available through explicit disclosure, not mixed
into the first screen.

## Product Principle

Default screens answer:

- What changed?
- What needs attention?
- Which town area should I open?
- What work is running, blocked, or waiting for review?
- What can I safely request next?

Advanced screens answer:

- Which daemon/source/runtime file is active?
- Which exact request id, standing-goal id, or bridge path is involved?
- Which diagnostic state explains a failure?

## Cleanup Phases

### Phase 1: Inventory And Classification

Classify visible labels and controls as `default`, `advanced`, or `developer`.
Start with:

- `src/ui/rabbita-town/main/dashboard_page.mbt`
- `src/ui/rabbita-town/main/request_desk.mbt`
- `src/ui/rabbita-town/main/viewport_controls.mbt`
- `src/ui/rabbita-town/main/viewport_runtime_bar.mbt`
- `src/ui/rabbita-town/main/viewport_operator_requests.mbt`
- `src/ui/rabbita-town/main/viewport_book_template_requests.mbt`
- `src/ui/rabbita-town/main/app_request_update.mbt`

Likely advanced/developer labels include JSON filenames, daemon identity, raw
request ids, source switching, simulation step controls, and bridge status.

### Phase 2: Reorder The Default Dashboard

The first screen should prioritize:

1. Town pulse and attention summary.
2. Wenyu Valley map workspace entry.
3. Review, failure, stale, and active-watch attention cards.
4. Request shortcuts.
5. Focused request desk for deliberate watch/book creation.
6. Developer diagnostics behind an explicit boundary.

### Phase 3: Translate Visible Copy

Keep internal contracts stable and add display labels.

| Current visible copy | Default copy |
| --- | --- |
| `Writes standing-goals.json` | Saves a durable watch |
| `Writes book-template-requests.json` | Queues a new book |
| `Daemon ...` | Town status active |
| `Live spine ...` | Town readiness connected |
| raw request/goal ids after submit | Watch accepted / Book request queued |
| `Cadence ticks` | Check frequency |
| `Target MoonBook` | Target book |
| `Switch Source` / `Step` | Advanced runtime controls |

Exact ids and files can remain in an expanded details surface.

### Phase 4: Collapse Rare Controls

Default-hide simulation and runtime-tuning controls:

- source switching
- single-step simulation
- strategy mode strip
- budget/queue/stability drills
- daemon heartbeat chip
- state source count

These are valuable for development and live recovery, but not frequent
professional workflow controls.

### Phase 5: Guard Default Space

Add tests or generated-output checks so default UI does not regress into runtime
copy. Candidate forbidden default strings:

- `.json`
- `daemon.json`
- `standing-goals.json`
- `book-template-requests.json`
- `request-`
- `goal-`
- `task-`
- `packet-`
- `run-`
- `proposal-`
- `Live spine`
- `Snapshot bridge`
- `Switch Source`
- `State sources`
- `endpoint`
- `payload`
- `dispatch tick`

Allow these only in advanced/developer surfaces.

## Done Criteria

- A professional user can operate watches, reviews, book requests, and the map
  without reading runtime filenames or request ids.
- Advanced users can still inspect exact runtime state deliberately.
- The first screen reads as a Moontown operating surface, not a runtime
  debugger.
- Backend contracts remain stable; most changes are display-label and hierarchy
  changes.

## Progress Notes

- Default Rabbita town now hides rare runtime source switching, simulation
  stepping, strategy tuning, and inspector drill controls from the professional
  dashboard.
- Activity Ledger now translates execution task records into professional labels
  and details, such as `Town shell code patch is running`, rather than exposing
  raw task, packet, run, or proposal ids.
- Default dashboard tests now guard against raw runtime ids and developer copy
  leaking back into the professional first screen.
- Ecosystem detail now sits behind focused dashboard tabs, so district,
  resident, quest, and social-capital surfaces do not all render in the default
  scroll.
- Request creation now starts from two shortcuts, `Save Watch` and `Queue PDF
  Watch Book`, and shows the detailed watch or book form only after the
  operator chooses that path.
- Advanced runtime counters no longer render inside the professional dashboard;
  the dashboard keeps a single `Open Advanced Viewport` portal for deliberate
  runtime inspection.
- The default sidebar no longer carries the old map legend. Focus guidance now
  points operators at recovery, review, standing watch setup, pending book
  requests, or steady monitoring based on live state.
- The duplicate lower `Advanced Viewport` block was removed from the default
  dashboard. Professional users now use the primary Wenyu map entry instead of
  reading advanced/runtime intervention copy on the first screen.
- Activity Ledger now renders as a professional activity ledger instead of a
  phone-style chat thread, and standing-watch feed copy no longer exposes daemon
  wording or raw watch/book identifiers on the default dashboard.
- The first-viewport status strip no longer exposes preview/source state or
  daemon check cadence. It now summarizes the professional workspace, active
  watches, and attention state.
- The Wenyu entry now reads as a map workspace instead of exposing viewport,
  tile-map, scaled-copy, or execution-count implementation language. The same
  cleanup also renames the default command-center execution chip to
  `Active work`.
- The old always-open command center, standing-watch portfolio, watcher
  timeline, and operator-stat grid have been removed from the default code path.
  The remaining lower dashboard action is a focused `Request Desk` that only
  opens a detailed watch or book composer after the operator chooses that job.
- The separate header chip row, `Operating Brief`, `Current focus`, and
  vitality metric strip have been collapsed into one `Attention Workbench`.
  `Request Desk` now appears immediately after the Wenyu map workspace entry so
  safe watch/book creation is reachable before lower ecosystem browsing.
- Town pulse and Attention Workbench now share one professional attention
  summary, so execution reviews, watcher reviews, failed work, and failed book
  requests produce the same top-level review/recovery state instead of showing
  contradictory `Review` and `Clear` signals.
