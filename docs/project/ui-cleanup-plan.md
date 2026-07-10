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

### Phase 12: Direct Town Areas Dock

The area launcher now contains only four concrete area commands, so the
secondary `Civic surfaces` heading is redundant. The default dashboard should
name the region once, then let the area controls carry the choices.

Default state should keep:

- `Town Areas` as the dock title
- `Districts`, `Residents`, `Quests`, and `Social capital`
- closed-by-default detail panels

Default state should remove:

- the `Civic surfaces` heading
- duplicate title chrome before the four area commands

### Phase 13: Compact Launchpad Signal Rail

The launchpad is now the largest remaining phone block. Professional users
still need the four operating signals, but the labels should read like a dense
status rail instead of explanatory card headings.

Default state should keep:

- four visible signals for health, watches, attention, and books
- full values such as `Healthy`, `Review`, and queue counts
- detail notes on larger screens

Default state should remove:

- verbose labels such as `Town health`, `Standing watches`, and `Book queue`
- tall mobile signal cards that crowd the Request Desk below the fold
- repeated signal explanation in the default phone rail

### Phase 14: Compact Town Areas Rail

Town Areas is secondary navigation, not a work surface. It should remain
available, but its default phone footprint should match a compact rail rather
than a large 2x2 block.

Default state should keep:

- `Town Areas` as the dock title
- four direct destinations for districts, residents, quests, and social work
- 44px minimum mobile targets
- closed-by-default detail panels

Default state should remove:

- the verbose `Social capital` default tab label
- the mobile 2x2 area grid that makes secondary navigation taller than the
  Request Desk

### Phase 15: Compact Attention Rail

The launchpad already owns the top-level attention state. The separate
attention dock should behave like a short review rail, not another section with
its own tall mobile heading.

Default state should keep:

- `Attention` as the dock label
- the current attention action
- `Next opening`
- `Latest signal`

Default state should remove:

- verbose action titles such as `Review queued work`
- the two-row phone layout that makes attention taller than secondary
  navigation

### Phase 16: Compact Launchpad Action Strip

The launchpad action strip still uses sentence-length status chips. On phones,
those chips wrap the map entry onto a separate row and keep the launchpad as
the tallest first-screen surface.

Default state should keep:

- alert state
- worker count
- attention count
- a direct map command

Default state should remove:

- `No active alerts` as full default chip copy
- `Workers online:` as full default chip copy
- `Open Wenyu Map` as full default command copy
- long alert messages in the default launchpad action strip

### Phase 17: Compact Launchpad Signal Row

The launchpad signal rail still behaves like four separate cards on phones.
After the action strip cleanup, the 2x2 signal block is the largest remaining
source of first-screen vertical weight.

Default state should keep:

- the four launchpad signals for health, watches, attention, and books
- readable signal labels and values
- the existing desktop signal-card treatment

Default state should remove:

- the phone-only 2x2 signal block
- secondary signal notes from the default phone launchpad
- extra mobile card padding that makes status heavier than action commands

### Phase 18: Compact Request Desk Rail

The Request Desk is now a command surface, but the phone layout still stacks
the section title above the two commands. This spends a full extra row on a
surface whose default job is simply choosing `Save` or `Queue`.

Default state should keep:

- `Request Desk` as the professional section label
- the `Requests` heading as compact orientation copy
- the two visible request commands
- 44px command targets on phones

Default state should remove:

- the phone-only title row above the command rail
- excess vertical gap between the request label and commands
- tutorial-like request framing in the default scroll

### Phase 19: Compact Town Areas Rail

Town Areas is secondary navigation and should not spend more first-screen
height than the request command rail. The phone layout still stacks the title
above the four area commands, leaving the default scroll taller than its
professional value.

Default state should keep:

- `Town Areas` as the section label
- four direct area commands
- 44px area targets on phones
- closed-by-default area details

Default state should remove:

- the phone-only title row above the area commands
- excess secondary-navigation height in the default scroll
- any return to a 2x2 phone area grid

### Phase 20: Compact Launchpad Title Rail

The launchpad remains the largest phone surface after request, attention, and
town-area rails have been compacted. Its title area still stacks `Moontown`
above the scene title, spending a full row before the action and signal rails.

Default state should keep:

- `Moontown` as product identity
- the current scene title
- alert, worker, review, and map actions
- the four operating signals

Default state should remove:

- the phone-only two-row launchpad identity block
- excess title spacing before actionable status
- any truncation of the primary scene title at 390px

### Phase 21: Desktop Operations Deck

The phone default stack is now compact, but desktop and tablet still render the
Request Desk, Attention rail, and Town Areas rail as full-width rows. That
preserves a mobile scroll pattern on professional workstations where users
should be able to scan commands, review state, and navigation together.

Default state should keep:

- launchpad as the top operating pulse
- Request Desk, Attention, and Town Areas in their existing order
- the single-column phone stack
- closed-by-default area details

Default state should remove:

- full-width desktop rows for the three secondary operating surfaces
- unnecessary desktop vertical scroll before operators can compare actions
- any new duplicate desktop-specific component variants

### Phase 22: Guard Operations Deck Contract

The default dashboard tests guard against developer/runtime copy, but they
should also guard the new structural contract: the professional dashboard is a
launchpad followed by one operations deck containing request intake, attention,
and town-area navigation. Without this, a future cleanup can accidentally
return to a full-width row stack while still passing copy checks.

Default state should keep:

- `town-operations-deck` around secondary operating surfaces
- Request Desk, Attention, and Town Areas visible inside the default dashboard
- the no-detail default behavior for ecosystem panels
- the default-copy forbidden string guard

Default state should remove:

- unguarded structural regressions back to separate full-width rows
- stale request-intake progress notes that describe already-finished work
- any compatibility allowance for the old explanatory request cards

### Phase 23: Purge Retired Masthead Compatibility CSS

The standalone masthead was folded into the Town Launchpad, and rendered HTML
already forbids the old `operator-masthead-*` classes. Shared CSS should carry
the same contract so future dashboard work does not preserve retired layout
hooks that no longer belong to the standalone product surface.

Default state should keep:

- the unified launchpad identity and alert chrome
- the rendered-output guard that forbids old masthead classes
- responsive rules for currently rendered runtime, request, map, and module
  surfaces

Default state should remove:

- `operator-masthead` selectors from shared responsive CSS
- compatibility styling for the removed standalone masthead band
- any assumption that old hero chrome may return to the default dashboard

### Phase 24: Professional Standalone Visual System

The compact default dashboard now has the right information hierarchy, but its
visual system still reads like a retro game shell: striped green page
background, chunky brown borders, stepped shadows, and monospace control
chrome. Moontown should borrow the reference designs' clear blue-white
optimism without copying the phone mini-app style or keeping old pixel
compatibility as the default product identity.

Default state should keep:

- the compact launchpad, request, attention, and town-area deck
- visible alert, worker, review, map, request, and area actions
- professional status density and 44px mobile action targets

Default state should remove:

- pixelated page rendering from the default shell
- green striped wallpaper behind the operating dashboard
- heavy brown borders, square cards, and stepped shadows on default surfaces
- monospace button/chip typography where it reads as game chrome rather than
  operational UI

### Phase 25: Advanced Viewport Product Chrome

The advanced viewport is deliberately separate from the professional default
dashboard, but it should not look like an old compatibility mode. Advanced
operators still need map, module, runtime, interior, and handoff detail, while
the surface itself should share the standalone Moontown visual system.

Advanced state should keep:

- map and module inspection as deliberate advanced workflows
- runtime stats, module issues, handoff artifacts, book projections, and
  interior agent detail
- dense operator information where it helps diagnosis
- mobile access to the advanced map without clipping the viewport behind a
  wrapped diagnostics header

Advanced state should remove:

- green grid wallpaper and yellow/brown viewport chrome
- old pixel borders, stepped shadows, and monospace typography on viewport
  panels, runtime stats, module detail cards, and interior cards
- separate visual treatment that implies the advanced viewport is a legacy
  debug product instead of a first-class Moontown surface
- paragraph-length status chips that push the mobile map below the visible
  area

### Phase 26: Truthful Runtime States

The browser must never convert missing live state into convincing sample work.
The professional default connects to the local projection, while sample data
is available only through the explicit `?demo=1` URL.

Default state should keep:

- distinct connecting, offline, live, and demo labels
- a useful request desk and map entry while runtime data is unavailable
- empty area details until workers, tasks, or executions provide operational
  evidence

Default state should remove:

- automatic fallback from live mode to demo mode
- placeholder workers, tasks, executions, books, and activity
- simulated metric drift while a snapshot source is selected

### Phase 27: Action-First Attention

Attention should identify the next bounded action instead of describing the
dashboard. Recovery, review, watch creation, pending requests, and map
inspection each receive a direct destination.

### Phase 28: Semantic Navigation And Deep Links

Area tabs, request modes, and viewport modes should expose selected state to
assistive technology and preserve that state in the URL. Form controls should
have durable labels, ids, and live submission feedback.

### Phase 29: Request Ledger Projection

Book-template requests should refresh through the same browser snapshot path as
the other runtime ledgers. The launchpad book count must report pending or retry
work, not an unrelated operator-request count.

### Phase 30: Local Write Security

Development write routes should bind to localhost and accept only same-origin
JSON POST requests. Invalid method, content type, and origin combinations must
fail before any state file is changed.

### Phase 31: End-To-End Delivery Gates

CI and local validation should cover source boundaries, native and JavaScript
MoonBit tests, server route tests, persistent user workflows, projection smoke
tests, and the production build. Browser validation should click both request
flows and verify their visible result and durable filesystem effect.

### Phase 32: Runtime Asset Boundary

The production frontend should ship the town that users can operate, not the
entire visual-authoring workspace. Vite may continue to serve the full asset
tree during development, but production export must be driven by a checked
runtime manifest.

Production should keep:

- the rendered Wenyu map, labels, module contracts, and compact district art
- every configured alpha building asset
- role animation strips, resident strips, and the resident portraits used by
  professional area details
- runtime tiles, objects, frontend bundles, and exported town ledgers

Production should remove:

- raw building source renders and style sheets
- authoring prompts, maps, generated tilesets, and individual animation frames
- unreferenced visual experiments copied only because they share `publicDir`

Acceptance requires:

- a missing runtime asset fails tests or the build
- the production artifact contains no authoring-only directories
- the complete artifact remains below 64 MiB
- dashboard, advanced map, module interiors, and resident animation assets load
  from the built artifact without browser errors

### Phase 33: Truthful Compact Advanced Command Bar

The advanced viewport should expose the controls needed to inspect the town,
without presenting simulation state as live runtime state or repeating browser
navigation that already exists in the mode selector and URL.

The command bar should keep:

- the three viewport modes with one clear selected state
- truthful demo, connecting, offline, and live runtime status
- module readiness and compact zoom controls
- daemon tick state only when a live daemon snapshot exists
- pause and step controls only in explicit demo mode

The command bar should remove:

- the duplicate current-mode badge
- the redundant `Copyable Mode URL` link
- local clock copy that does not change an operator decision
- waiting daemon copy when no daemon snapshot exists
- pause and step controls from live-snapshot workflows

Acceptance requires:

- missing live data never renders a `Live` status
- demo controls remain usable in explicit demo mode
- each mode remains keyboard-operable and URL-addressable
- the map receives materially more first-screen space on phone and desktop
- no command, status, title, or map content overlaps at supported viewports

## Done Criteria

- A professional user can operate watches, reviews, book requests, and the map
  without reading runtime filenames or request ids.
- Advanced users can still inspect exact runtime state deliberately.
- The first screen reads as a Moontown operating surface, not a runtime
  debugger.
- Backend contracts remain stable; most changes are display-label and hierarchy
  changes.
- Missing or sparse runtime data never appears as sample operational activity.
- Request success is verified from click feedback through persisted ledgers.
- Production output contains only runtime assets and remains below 64 MiB.

## Progress Notes

- Phase 33 is implemented: the advanced viewport now distinguishes demo,
  connecting, offline, and live town state instead of deriving a misleading
  `Live` chip from the simulation pause flag. Pause and step remain available
  only in explicit demo mode.
- The advanced command bar no longer repeats the selected mode, local clock,
  waiting daemon state, or copyable-URL link. Its three semantic mode buttons,
  module readiness, runtime status, and accessible zoom symbols fit one desktop
  row and two phone rows at 390 px without overlap.
- Small phones keep the complete town name on two lines, and module-interior
  worker or empty states now follow the room content in normal flow instead of
  floating over book projections.
- Phase 32 is implemented: production no longer copies the full UI authoring
  tree. A generated runtime manifest derives configured building art, resident
  strips, district previews, map contracts, tiles, and objects, then fails the
  build if a required asset is absent.
- The production artifact dropped from 155 MiB to 43.8 MiB by actual file
  bytes. Raw building sources, style sheets, prompts, tilesets, and individual
  animation frames stay in the authoring workspace and no longer ship.
- Browser bootstrap now completes its initial runtime/module bridge before
  importing the MoonBit application. This removes a production-only race that
  previously mounted the advanced viewport with `Modules 0/0`.
- Wenyu modules now render their configured high-fidelity building images
  directly with lazy loading and asynchronous decoding. The retired CSS-drawn
  pavilion compatibility layer and pixelated building rendering are removed.
- Phases 26-31 are implemented in the current major-upgrade pass: browser
  startup is live-first, demo mode is explicit, unavailable town areas show an
  honest state, and snapshot mode no longer injects synthetic work or metrics.
- Attention states now carry direct actions; tabs and composers expose selected
  state with ARIA and URL query parameters; request fields have semantic labels
  and live status feedback.
- The book-template ledger is part of bootstrap and periodic refresh state, so
  queued work appears immediately in the launchpad and remains backed by the
  durable request file.
- Local write endpoints now enforce same-origin JSON POST requests and the Vite
  server binds to `127.0.0.1` by default.
- CI and local smoke coverage now verify MoonBit contracts, route security,
  persisted standing-watch and evidence-book requests, projection generation,
  and the production frontend build.

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
- Request creation now starts from two compact commands, `Save` and `Queue`,
  and shows the detailed watch or book form only after the operator chooses
  that path.
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
- Town Areas now renders as a direct area dock. It keeps the four professional
  area commands but removes the redundant `Civic surfaces` heading from the
  default dashboard.
- The launchpad signal rail now uses shorter professional labels and denser
  phone cards, reducing the tallest remaining first-screen block after the
  request, attention, and town-area docks were compacted.
- Town Areas now behaves like a compact secondary navigation rail on phone. It
  keeps all four destinations visible, shortens the longest label to `Social`,
  and removes the tall 2x2 default area block.
- Attention now renders as a compact rail on phone. It keeps the current
  action, next opening, and latest signal, but shortens action titles and
  removes the extra stacked heading row from the default mobile layout.
- The launchpad action strip now uses compact operating chips: `Alerts clear`,
  `Workers N`, `Review N`, and `Map`. The strip preserves default state while
  avoiding sentence-length chips that push the map command onto a separate
  phone row.
- Shared responsive CSS no longer carries retired `operator-masthead` layout
  selectors. The default dashboard guard still forbids those old masthead
  classes in rendered HTML, matching the unified launchpad contract.
- The default dashboard now uses a cleaner blue-white standalone visual system:
  soft page depth, restrained 8px operating surfaces, lighter borders,
  smoother shadows, and product typography for chips, buttons, signals, request
  actions, attention chips, and town-area tabs.
- The advanced viewport now shares the standalone product chrome: blue-white
  shell, lighter panel borders, restrained radii, smooth shadows, and product
  typography for viewport controls, runtime stats, module detail cards,
  handoff artifacts, book projections, and interior cards. Its mobile shell can
  scroll to the map, and the module status chip now uses compact count/version
  copy instead of a long diagnostic sentence.
- The professional default dashboard now has a real ecosystem visual without
  reopening advanced controls. The launchpad remains the only `Map` gateway,
  while a compact, non-interactive Wenyu map preview follows the
  request/attention/town-area deck so the product reads as Moontown instead of
  an empty operating form.
- Opened ecosystem areas now use the same professional blue-white surface
  language as the default dashboard. District, resident, quest, and social
  detail cards have restrained 8px radii, lighter borders, and concise product
  headings, while implementation phrases such as UI contract, static service
  replacement, and handoff plumbing are no longer rendered in those panels.
  The opened Districts context rail is also reduced to four operating signals
  so the actual district cards appear sooner, especially on phone layouts.
- Opened Town Areas now render outside the launcher as a full-width ecosystem
  detail surface. The compact area dock stays in the operating deck, while the
  selected district/resident/quest/social panel appears below the deck before
  the map preview instead of being squeezed into the left request column.
- District system cards now carry real district building art from the generated
  Wenyu tilemap assets. The shared civic module card shell infers each
  building image from the module title, so all nine district cards gain visual
  identity without duplicating asset wiring in each renderer.
- Resident Agent cards now use generated resident roster art instead of text
  initials, and the default resident surface hides low-frequency memory,
  reflection, plan, and handoff internals. The visible card keeps professional
  context, compact need/mood/goal state, privacy scope, and one current signal,
  while stale resident memory/reflection sample fields have been removed from
  the UI data model.
