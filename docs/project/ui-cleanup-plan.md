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

### Phase 6: Compact Professional Request Intake

The Request Desk is a frequent enough professional action to remain visible,
but not important enough to spend default-screen height explaining the two
paths. Professional users can recognize `Save Watch` and `Queue PDF Watch Book`
without long card descriptions.

Default state should show:

- a short `Request Desk` / `Request intake` label pair
- the two primary commands as compact controls
- no form fields, explanatory request cards, or workflow copy until a command is
  selected

Expanded state should show only the selected composer. This keeps request
creation deliberate while removing another large tutorial-like block from the
normal operating scroll.

### Phase 7: Single Launchpad Gateway

The Town Launchpad should expose one Wenyu map gateway, not a separate map card
with duplicated scene, latest, source, check, and active-work chips. Those
runtime summaries already feed the health, attention, and work surfaces. The
default launchpad should keep:

- town pulse title and concise summary
- worker and attention chips
- the four compact signal cells
- one direct `Open Wenyu Map` command

Default UI should remove the lower map-card copy and map stat chips. Advanced
or map-specific runtime state can live inside the Wenyu workspace itself.

### Phase 8: Compact Town Status Bar

The remaining masthead should behave like product chrome, not an intro hero.
Moontown already has an operating launchpad immediately below it, so the top
bar should only preserve identity and alert state.

Default state should show:

- `Moontown` as the product label
- the current scene title
- the current alert chips

Default state should remove:

- the `Wenyu Valley workspace` chip
- the explanatory civic-watch summary sentence
- old `operator-masthead-*` hero classes

### Phase 9: Unified Launchpad Chrome

The compact masthead still duplicates the launchpad because it creates a
separate first-screen band for identity and alert state immediately before the
operating pulse. Professional users need the same information, but not as an
extra section.

Default state should fold into the Town Launchpad header:

- `Moontown` as the product label
- the current scene title
- alert chips
- worker and attention chips
- one direct `Open Wenyu Map` command
- the four compact signal cells

Default state should remove:

- the standalone `town-status-bar`
- the separate operator masthead source file
- the tutorial-like `Town Launchpad` / `Current town pulse` heading pair
- the launchpad summary sentence

### Phase 10: Compact Attention Dock

The launchpad already shows the professional attention state, so the separate
Attention Workbench should not restate the same signal in a second large panel.
Default users still need the next opening and latest signal, but those should
behave like an operating dock rather than another dashboard section.

Default state should keep:

- the current attention action
- the next opening
- the latest signal

Default state should remove:

- the `Attention Workbench` heading
- the duplicated `Signal` chip
- the workbench summary sentence
- old `attention-review-*` and `attention-strip-*` classes

### Phase 11: Compact Request Command Dock

Default request creation should read as two professional commands, not a small
form chooser. The full submit labels still belong inside the expanded
composers, but the default dashboard should keep the request surface short
enough that attention and town-area navigation remain visible on phones.

Default state should keep:

- `Request Desk` as the section label
- `Standing watch` and `Evidence book` as the command targets
- short `Save` and `Queue` actions
- a two-column command dock on phone and desktop

Default state should remove:

- the `Request intake` heading
- long shortcut commands such as `Save Watch`
- long shortcut commands such as `Queue PDF Watch Book`

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
- Recent activity signals translate execution task records into professional
  labels and details, such as `Town shell code patch is running`, rather than
  exposing raw task, packet, run, or proposal ids.
- Default dashboard tests now guard against raw runtime ids and developer copy
  leaking back into the professional first screen.
- Ecosystem detail now sits behind focused dashboard tabs, so district,
  resident, quest, and social-capital surfaces do not all render in the default
  scroll.
- Request creation now starts from two shortcuts, `Save Watch` and `Queue PDF
  Watch Book`, and shows the detailed watch or book form only after the
  operator chooses that path.
- The next request-intake cleanup should replace the large explanatory
  shortcut cards with a compact command dock, keeping the same two actions but
  dropping default card titles and descriptions.
- Advanced runtime counters no longer render inside the professional dashboard;
  the dashboard keeps a single `Open Advanced Viewport` portal for deliberate
  runtime inspection.
- The default sidebar no longer carries the old map legend. Focus guidance now
  points operators at recovery, review, standing watch setup, pending book
  requests, or steady monitoring based on live state.
- The duplicate lower `Advanced Viewport` block was removed from the default
  dashboard. Professional users now use the primary Wenyu map entry instead of
  reading advanced/runtime intervention copy on the first screen.
- Activity copy now reads as professional town signals instead of phone-style
  chat bubbles, and standing-watch feed copy no longer exposes daemon wording or
  raw watch/book identifiers on the default dashboard.
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
- The separate town overview and Wenyu map portal have been merged into a
  compact `Town Launchpad`. The first screen still exposes health, watches,
  attention, book queue, and the Wenyu map link, but it no longer spends a
  second hero-sized block before the professional request path.
- The remaining marketing-scale dashboard hero has been replaced by a compact
  operator masthead. The default first screen now starts as a professional
  operating console instead of an intro page, while keeping scene identity and
  alert state visible.
- The lower ecosystem workspace no longer renders an always-open overview-card
  grid by default. It is now a compact `Town Areas` launcher; detailed district,
  resident, quest, and social-capital panels render only after the operator
  explicitly opens that area.
- The Request Desk no longer renders a separate idle explanation panel by
  default. The professional dashboard now shows the two request choices as a
  compact intake control, and opens the full watch or book composer only after
  the operator chooses that path.
- The Attention Workbench no longer embeds the full scrollable Activity Ledger
  in the professional dashboard. It now shows the current decision signal, next
  opening, and one compact recent signal; the stale ledger renderer and related
  CSS were removed from the default UI code path.
- The Town Areas launcher no longer uses a pseudo `Areas` tab or a closed-state
  explanation panel. The default dashboard now shows four real area choices and
  keeps every civic detail panel unrendered until the operator selects that
  area; selecting the active area closes it again.
- The Town Launchpad no longer uses four tall explanatory status cards. Its
  default state is a compact signal rail for health, watches, attention, and
  book queue, keeping the Wenyu map action visible while leaving more first
  screen room for the Request Desk.
- The Attention Workbench is now a compact review strip instead of a separate
  card grid. It keeps the current action, next opening, and recent signal in
  one row, reducing repeated attention surface area after the Request Desk.
- The Town Areas launcher is now a compact civic surface dock. It no longer
  renders instructional heading copy or per-area kicker text in the default
  dashboard, and phone layout keeps the four area choices in a 2x2 dock.
- The next launchpad cleanup should keep a single Wenyu map gateway in the
  launchpad header and remove the duplicated lower map card plus its runtime
  stat helper.
- The next masthead cleanup should collapse the remaining hero-style masthead
  into a compact town status bar that keeps scene identity and alerts without
  delaying the launchpad/request path.
- The status bar and launchpad chrome are now unified. The default dashboard
  starts with one Town Launchpad surface containing product identity, scene
  title, alerts, worker/attention chips, map entry, and the compact signal rail.
- The Attention Workbench has been replaced by a compact Attention dock. The
  launchpad owns the attention signal, while the dock keeps only the current
  action, next opening, and latest signal.
- Request Desk shortcuts now behave as a compact two-command dock on phone and
  desktop. The default dashboard shows `Standing watch / Save` and
  `Evidence book / Queue`, while longer submit wording stays inside the
  expanded composers.
