# Usage Guide

This guide is the practical “how to use everything” entry for the current
`moontown` repo.

It covers:

- the text dashboard
- the persisted town state
- the moonbook catalog
- the keeper packet and proposal/run lifecycle
- parallel research goal runs
- mayor-level town synthesis
- the scene assets
- the Rabbita frontend
- the current limits of the repo
- the Wenyu civic MoonBook bootstrap
- the MoonBook-generated stable-state cookbook
- the final Wenyu integration portfolio

## What You Can Use Right Now

Right now, `moontown` is usable as:

- a MoonBit town model
- a persisted demo bootstrap
- a real MoonBook CLI-backed planning and context-hydration boundary
- a real MoonClaw CLI-backed proposal import/run/polling boundary
- a real MoonBook result-persistence and generated-site refresh boundary for goal runs
- a mayor-level synthesis and quality-gate surface for parallel research lanes
- typed runtime status and one-shot daemon tick commands
- persisted standing goals, a continuous daemon-loop command, and a supervised background daemon
- a MoonBook-generated cookbook for docs, definitions, and stable-state control
- a scene-based dashboard
- a Rabbita simulation frontend
- a starter asset pipeline

It is not yet usable as:

- a packaged cross-platform systemd/container service
- a backend-synced browser UI

So the right way to use the repo today is as a real goal-run control plane plus
a live architectural and frontend prototype. It can launch and observe bounded
MoonBook/MoonClaw research runs, and it has the first durable daemon tick seam,
plus a supervised standing-goal daemon loop. It is now suitable for local
multi-day supervised testing on macOS through the included launchd installer,
while cross-platform production service packaging is still a separate layer.

## 1. Run The Text Dashboard

From the repo root:

```bash
moon run src/cmd/main
```

What you get:

- a text dashboard
- current town map summary
- books, workers, tasks
- executions with packet / proposal / run ids
- real failure details when MoonBook or MoonClaw rejects a handoff
- mayor role summary
- scheduler tick summary
- snapshot summary

The CLI entry is:

- [cmd/main/main.mbt](/Users/kq/Workspace/moontown/src/cmd/main/main.mbt)

The root demo/bootstrap surface is:

- [moontown.mbt](/Users/kq/Workspace/moontown/src/facade.mbt)

## 1.1 Inspect Runtime Status

After a run has created `.moontown/town.json`, inspect the persisted town:

```bash
moon run src/cmd/main -- status
```

This prints:

- snapshot path
- book, worker, task, execution, and event counts
- running/review/failed/stale/completed execution counts
- planned scheduler/daemon actions

The status model lives in:

- [runtime_status.mbt](/Users/kq/Workspace/moontown/src/runtime_status/runtime_status_snapshot.mbt)

## 1.2 Run One Durable Daemon Tick

Run one mayor supervision tick against the saved town:

```bash
moon run src/cmd/main -- daemon tick
```

This is not a permanent background process yet. It is the restart-safe unit the
future daemon should repeat: load snapshot, reconcile live executions, apply
mayor directives, persist checkpoint, update `.moontown/daemon.json`, and
report planned next actions.

## 1.3 Run The Standing-Goal Daemon Loop

Start the supervised background daemon:

```bash
moon run src/cmd/main -- daemon start
```

Inspect the supervisor/worker health:

```bash
moon run src/cmd/main -- daemon doctor
```

Stop the supervised background daemon:

```bash
moon run src/cmd/main -- daemon stop
```

Run the continuous daemon loop:

```bash
moon run src/cmd/main -- daemon run
```

Run exactly one loop iteration for verification:

```bash
moon run src/cmd/main -- daemon run --once
```

The daemon loop repeats the restart-safe tick. Each tick:

- loads `.moontown/town.json`
- bootstraps a saved town if the snapshot is missing
- loads `.moontown/daemon.json`
- loads `.moontown/standing-goals.json`
- lets the Mayor dispatch due standing goals
- routes the target book to a book-local `standing-watch` task
- lets MoonBook decide whether the check produced useful new information
- persists checkpoint and standing-goal next due state
- appends `.moontown/watchers/<goal-id>.jsonl`
- sleeps before the next tick

Daemon-triggered standing-watch handoffs are detached from the tick loop. The
Mayor records a running snapshot and reconciles the MoonBook standing-watch
marker on later ticks, so a large MoonClaw proposal import cannot block
real-world cadence. When `MOONTOWN_MOONCLAW_INLINE=1` is present, the detached
child passes `--inline` to MoonClaw after confirmation; that keeps the daemon
tick nonblocking while letting the child run the confirmed proposal instead of
leaving an unstarted run for a later shell. If the receipt never appears, the
stale execution summary includes the captured detached-import stderr excerpt
from `.import.json.err`.
Before each standing-watch import, Moontown also compacts oversized book-local
MoonClaw hot-store files by moving them into
`.moonclaw/jobs/archive/tick-<tick>/` and replacing the active index with valid
empty JSON. This prevents long-lived books from repeatedly failing proposal
imports because old job proposal indexes have grown too large.
You can run the same maintenance explicitly:

```bash
moon run src/cmd/main -- moonclaw stores compact
```

Transient transport/contention failures, including temporary resource
unavailability, are treated as deferred operational retries with immediate
cadence instead of being counted as domain progress or durable review evidence.

If a standing-watch handoff has to retry, the Mayor keeps polling the MoonClaw
run and then re-reads the MoonBook standing-watch history before final
accounting. A successful retry appends a corrected watcher ledger row with the
real task/run id and updates `next_due_tick`; the earlier failed or deferred row
stays in the append-only log as an operational trail, not as final research
truth.

`daemon start` runs a background supervisor process, and that supervisor runs a
worker loop. The supervisor watches PID liveness and heartbeat age. If the
worker exits or its heartbeat becomes stale, the supervisor records the event in
`.moontown/daemon.log` and starts a fresh worker. The worker records every tick
start, tick success, and tick failure so a bad watcher cycle does not silently
kill the long-lived daemon.

When a self-patch changes Moontown source code while the daemon is already
running, request a clean reload instead of trusting the old process to pick up
new logic:

```bash
moon run src/cmd/main -- daemon restart "validated source patch"
```

This writes `.moontown/daemon.restart`. The worker consumes that marker between
ticks, preserves supervisor state, exits cleanly, and lets the supervisor or
launchd start a fresh worker with the newly compiled code. Use this after a
PlanBook/MoonClaw code repair has passed validation and before treating the
next live packet as proof of the new behavior.

Launcher selection is environment-driven:

- `MOONTOWN_DAEMON_COMMAND`
  overrides the command used by `daemon start`.
- `MOON_BIN`
  overrides the MoonBit runner path.
- default
  uses `$HOME/.moon/bin/moon` and launches `moon run src/cmd/main -- daemon ...`.

If a host process manager aggressively cleans up child processes, run
`daemon run` in the foreground under that manager instead of using
`daemon start`. The Codex execution harness does this cleanup, so local smoke
tests should use `daemon run --once`, `daemon supervise --once`, and
`daemon doctor`; a normal terminal or OS service wrapper can use `daemon start`.

## 1.4 Open The Wenyu Viewport

Run the Rabbita frontend, then open the canonical standalone Wenyu viewport:

```bash
cd src/ui/rabbita-town
npm run dev
```

Direct viewport modes:

- `http://127.0.0.1:5173/viewport.html?assets=generated&mode=view&v=wenyu`
  opens the clean town view.
- `http://127.0.0.1:5173/viewport.html?assets=generated&mode=editor&v=wenyu`
  opens the module editor/validation view.
- `http://127.0.0.1:5173/viewport.html?assets=generated&mode=output&v=wenyu`
  opens the final generated-output browser.

Use view mode to present the town, editor mode to check module placement and
bindings, and output mode to retrieve MoonBook-generated sites, reports,
review queues, and page-family summaries.

## 1.5 Run A Building Communication Pattern Template

Social Square can run a research-salon `CivicCommunicationScenario` JSON template
through the generic building communication-pattern model:

```bash
moon run src/cmd/main -- civic protocols patterns
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/robotics-mini-salon.json
moon run src/cmd/main -- civic protocols status
```

That command creates the internal participant workspaces declared by the
template, sends their domain perspectives through Social Square, runs a
MoonClaw reducer guided by the generated `SKILL.md`, and writes relevant ideas
back to each home workspace after the reducer emits
`raw/bootstrap/civic-communication-results.json`. Participant workspaces are treated as
intermediate pattern state. The public UI and main MoonBook catalog surface the
building book, such as `wenyu-social-square`, rather than every temporary
participant workspace.

Important outputs:

- `.moontown/civic/protocols/social-square/metrics.json`
- `.moontown/civic/protocols/social-square/home_returns.jsonl`
- `.moontown/books/wenyu-social-square/wiki/metrics/<salon>.md`
- `.moontown/books/wenyu-social-square/book/site/generated/index.html`
- `.moontown/books/<participant-book>/wiki/queries/salon-returned-ideas.md`

The metric is structural: it counts idea yield, research-question yield,
cross-book links, home-book coverage, and return-home records. It proves the
building performed exchange-reduce-distribute; it does not bypass the review
queue or claim the ideas are already correct.

The pattern path is not robotics-hardcoded. `civic protocols pattern-template
<path>` loads a `CivicCommunicationScenario` JSON file and runs the same protocol
envelope for that domain. Use
[CIVIC_COMMUNICATION_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_TEMPLATES.md)
and [robotics-mini-salon.json](/Users/kq/Workspace/moontown/assets/templates/civic-salons/robotics-mini-salon.json)
as the copyable contract.

The viewport editor is intentionally town-level. Use it to compose modules,
bind books, validate placement, inspect worker lanes, and check output
availability. Do not use it as a detailed single-agent or single-book editor.
That deeper workspace belongs in `../moondesk`; Moondesk-produced books, skill
packs, agent profiles, assets, and module packs should be imported back into
Moontown as data/config artifacts.

Useful bridge artifacts:

- `http://127.0.0.1:5173/tilemap/modules/wenyu-town-modules.json`
  opens the current module registry.
- `http://127.0.0.1:5173/tilemap/modules/moondesk-handoff.json`
  opens the portable Moondesk-to-Moontown artifact contract.
- `http://127.0.0.1:5173/moondesk-bridge.json`
  opens the live bridge ledger built from `.moontown/moondesk-*` and
  `.moontown/book-results`.

## 1.6 Generate The Stable-State Cookbook

Generate or refresh the cookbook control book:

```bash
moon run src/cmd/main -- cookbook bootstrap
moon run src/cmd/main -- cookbook status
```

This registers the `moontown-cookbook` MoonBook, writes the generated
workspace under `.moontown/books/moontown-cookbook/`, and emits the
stable-state manifest at:

```text
.moonsuite/products/moontown/cookbook/stable-state.json
```

The cookbook tracks canonical docs, machine-readable definitions, and optional
runtime state files. It is the control surface for stable Moontown definitions:
MoonBook generates it, Moondesk should manage the human editing/browsing
surface, and Moontown consumes it for drift checks and operator guidance.

Use the cookbook when you want to answer:

- which docs are canonical
- which JSON registries define the town
- which runtime files prove the daemon/civic systems are alive
- which missing files are real drift versus optional not-yet-started state

More detail:

- [COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)

For overnight macOS runs, prefer launchd. This runs the foreground worker under
the OS instead of relying on a detached child process:

```bash
./scripts/install-launchd-daemon.sh
moon run src/cmd/main -- daemon doctor
tail -f .moontown/daemon.log
```

The installer writes `.moontown/launchd/com.vectie.moontown.daemon.plist`,
loads it into the current user launchd domain, and points stdout/stderr at:

- `.moontown/launchd.out.log`
- `.moontown/launchd.err.log`

The launchd profile also sets `MOONTOWN_MOONCLAW_INLINE=1`, so bounded
MoonClaw handoffs such as PlanBook repairs and book semantic reviews can run
inside the supervised worker instead of stopping at a dispatch receipt.

Stop it with:

```bash
./scripts/uninstall-launchd-daemon.sh
```

## 1.7 Bootstrap Wenyu Civic MoonBooks

Create or refresh the Wenyu civic service workspaces:

```bash
moon run src/cmd/main -- civic bootstrap
```

This command updates `.moontown/moonbooks.json` and creates 11 canonical civic
support workspaces:

- `wenyu-town-shell`
- `wenyu-resident-twins`
- `wenyu-policy-hall`
- `wenyu-contest-express`
- `wenyu-social-square`
- `wenyu-talent-avenue`
- `wenyu-vitality-dashboard`
- `wenyu-ai-garden`
- `wenyu-physical-bridge`
- `wenyu-valley-market`
- `wenyu-broadcast-tower`

Each workspace is seeded with:

- service contract: `raw/bootstrap/CIVIC_SERVICE_CONTRACT.md`
- building protocol contract: `raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md`
- generic civic skill: `skills/wenyu-civic-service/SKILL.md`
- role-specific skill pack such as `skills/civic-policy-researcher/SKILL.md`
- schema pages under `wiki/schemas/`
- civic wiki pages under `wiki/civic/`, `wiki/sources/`, `wiki/entities/`,
  `wiki/concepts/`, `wiki/queries/`, or `wiki/synthesis/`
- review queues under `wiki/reviews/`
- UI projection: `book/moonbook-ui-state.json`
- generated HTML: `book/Home.html` and `book/site/generated/index.html`
- MoonClaw profile: `moonclaw.jobs.json`

Moontown uses these seeded books as civic module support bindings. A Wenyu
building is not automatically a MoonBook: some are agent workspaces, some are
exchange places, some are projection surfaces, and some are gateways. MoonBook
remains the long-term owner of durable wiki/memory/review semantics where the
module needs them, and MoonClaw remains the executor that turns service tasks
into result packets. The bootstrap command is therefore a local workspace
creation bridge, not a replacement for real civic service execution.

When a Wenyu civic book is selected by the Mayor, Moontown now routes it
directly to the registry-defined `civic-service-workflow`. It does not send
that book through the Wenyu product research/bootstrap quality gate first. That
keeps service modules such as Policy Hall, Social Square, Talent Avenue, Valley
Market, and Story Radar operating as civic services instead of generic Wenyu
research lanes.

Each module also has a dedicated skill mode. Policy Hall performs policy
intelligence, Contest Express performs contest coaching, Social Square performs
consent-aware matchmaking, Vitality Tower performs observability/accounting,
Physical Bridge performs confirmation-gated handoff, Valley Market performs
market ledger keeping, and Story Radar performs public story editing. Do not
judge these modules by whether they produced a research report.

Inspect and publish civic operability status:

```bash
moon run src/cmd/main -- civic status
moon run src/cmd/main -- civic reconcile
moon run src/cmd/main -- civic doctor
```

`civic status` prints a Markdown table covering all civic modules. `civic
reconcile` bridges protocol ledgers back into MoonBook service-result records
under `.moontown/book-results/goal-<book-id>-civic-service.json`. Review-gated
outputs reconcile as `needs_review` with `accepted_facts_count: 0`, so
operational/protocol activity does not inflate accepted domain evidence.
`civic doctor` writes `.moontown/civic/status.json` and
`.moontown/civic/status.md`. The Rabbita viewport serves that JSON as
`civic-status.json`, so each module interior can show whether its MoonBook
workspace is only seeded, fully operable, blocked, review-needed, changed, or
still missing files.

Inspect the civic-building protocol layer:

```bash
moon run src/cmd/main -- civic protocols bootstrap
moon run src/cmd/main -- civic protocols status
moon run src/cmd/main -- civic protocols doctor
moon run src/cmd/main -- civic protocols patterns
moon run src/cmd/main -- civic protocols pattern-template assets/templates/civic-salons/robotics-mini-salon.json
moon run src/cmd/main -- civic protocols schedules status
moon run src/cmd/main -- civic protocols schedules tick
```

`civic protocols bootstrap` writes `.moontown/civic/protocols.json`, per-building
`PROTOCOL.md` files, and the current Social Square proof ledgers under
`.moontown/civic/protocols/social-square/`. `civic protocols status` prints the
building protocol table. `civic protocols doctor` refreshes
`.moontown/civic/protocol-status.json` and `.moontown/civic/protocol-status.md`.

`civic protocols patterns` lists reusable communication patterns such as
`research-salon`, `signal-watch`, `triage-desk`, `review-council`,
`match-market`, `learning-cohort`, `story-forge`, and `incident-bridge`.

`civic protocols pattern-template <path>` runs a communication-pattern scenario
from JSON. The runtime materializes the generic `CivicCommunicationIdea` output
contract; `research-salon` is one pattern example. The template defines
participants, pattern id, skill rules, quality rules, output paths, and review
gate. Template `ideas` are fixture examples only; production runs use the
MoonClaw reducer output contract. If the `building_id` is not already in the
Wenyu registry, Moontown synthesizes a generic exchange-reduce-distribute
protocol from the scenario fields. For recurring daemon use, place the file at
`.moontown/civic/pattern-scenarios/<session-id>.json` and make sure
`.moontown/civic/pattern-schedules.json` has a schedule with the same `id`.

`civic protocols schedules status` reports the persisted recurring
communication-pattern schedule from `.moontown/civic/pattern-schedules.json`.
`civic protocols schedules tick` performs the
same due-check used by the daemon: it compares real wall-clock time against
`next_due_ms`, runs only due sessions, advances the schedule, and appends a
round record to `.moontown/civic/pattern-runs/<session-id>.jsonl`. There is no
built-in recurring pattern session; operators add schedules and matching templates
explicitly while the system is experimental.

Run `civic doctor` after protocol updates so `civic-status.json` includes
protocol status for the viewport interiors. The daemon also runs the generic
`civic-service` reconciliation job, so protocol-active modules keep service
result proof current without a per-building MoonBit branch.

Overnight validation checklist:

- `moon run src/cmd/main -- daemon doctor` should report a fresh heartbeat and a
  non-stale runtime.
- `.moontown/daemon.json` should show `tick_sequence` increasing.
- `.moontown/civic/pattern-schedules.json` should show `round_count` increasing
  roughly every 30 minutes for enabled due sessions.
- `.moontown/civic/pattern-runs/<session-id>.jsonl` should
  contain one JSON line per completed communication-pattern round.

## 1.8 Install The Final Wenyu Integration Portfolio

Install the current “everything together” local integration:

```bash
moon run src/cmd/main -- integration final install
moon run src/cmd/main -- integration final status
```

The default manifest is:

```text
assets/templates/integration/wenyu-final-integration.json
```

It maps the current domain interests to the least surprising operating form:

- OPC: `signal-watch` into `research-opc`
- LLM training: `signal-watch` into
  `research-how-llms-are-trained-in-very-detail`
- Robotics: `signal-watch` plus the recurring Social Square `research-salon`
- Agents: `signal-watch` into `research-ai-agents`
- Hardware: `signal-watch` into `research-ai-hardware`
- Wenyu civic buildings: data-driven communication pattern scenarios from
  `assets/templates/civic-patterns/wenyu-civic-patterns.json`

The installer does not hardcode a domain workflow into MoonBit. It reads the
manifest, upserts `.moonsuite/products/moontown/standing-goals.json`, refreshes
Wenyu civic protocol support workspaces, refreshes building protocol
definitions, installs the recurring civic pattern schedules, and writes:

```text
.moonsuite/products/moontown/integration/wenyu-final-integration-status.json
```

After installing, run or keep alive the daemon:

```bash
moon run src/cmd/main -- daemon run
```

or use the launchd installer described above for overnight checks.

Standing-watch dispatch is nonblocking by default. Moontown starts or polls the
MoonClaw run, records the current state, and returns to the mayor loop so other
domain watches and civic schedules can keep advancing. Set
`MOONTOWN_MOONCLAW_SUPERVISION_SECONDS` to a positive value only for debugging a
single run where you explicitly want Moontown to wait inline.

The expected 24/7 loop is:

1. Mayor dispatches due domain standing watches.
2. MoonBook owns each domain book and accepts only useful deltas.
3. MoonClaw executes web-first/source-first watch work and returns accounting.
4. Civic buildings run scheduled communication patterns on wall-clock due
   checks.
5. Pattern reducers generate reviewable ideas, questions, and next actions.
6. Building books receive the public synthesis/review surface.
7. Participant/home workspaces receive returned follow-up work.
8. The Rabbita UI shows standing-watch cards, civic protocol summaries,
   worker state, the phone-like mayor message thread, and final output links.
- `.moontown/watchers/watch-opc-news.jsonl` should contain a new record after
  the OPC standing goal reaches `next_due_tick`.
- `.moontown/watchers/watch-llm-training.jsonl` should contain a new record
  after the LLM watcher reaches `next_due_tick`.
- A real no-change cycle is still progress only if it reports nonzero checked
  sources and clear accepted/rejected accounting.
- A retry is healthy only when the latest row for that task/run is
  `Update`, `NoChange`, or `NeedsReview`; an older `Failed` row may remain as
  historical evidence of the retry path.
- Infrastructure failures such as MoonBook/MoonClaw dependency locks, transient
  transport errors, or MoonClaw proposal-store aborts are not domain review.
  Moontown classifies them as deferred or transient infrastructure recovery so
  they do not inflate evidence counts or keeper review queues. The live spine
  reports them separately as `transient_infrastructure_debt`; this is historical
  operational accounting, not an unresolved failure, unless the latest watcher
  is still deferred or the count keeps growing.

Standing goals are data-driven. To add another long-horizon watcher, edit
`.moontown/standing-goals.json`; no MoonBit code change is required as long as
the entry follows the same shape:

```json
{
  "id": "watch-llm-training",
  "title": "Track LLM training research",
  "prompt": "Maintain a long-horizon research watch on how LLMs are trained in detail. Use web search first, screen sources, compare against the book baseline, and update only when useful evidence changes the baseline.",
  "target_book_id": "research-how-llms-are-trained-in-very-detail",
  "cadence_ticks": 60,
  "next_due_tick": 0,
  "enabled": true,
  "source_policy": "web-first",
  "quality_threshold": 90
}
```

This creates or reuses the dynamic target MoonBook lane. Moontown owns the
schedule and dispatch event; MoonBook owns the topic wiki and generated site;
MoonClaw owns bounded research execution.

### PDF Evidence Watch Books

For domains that need a clear source pipeline such as “watch these websites,
fetch related PDFs, extract all text, analyze using my method, and notify me
when new knowledge appears”, use a specialized research-book template:

```text
assets/templates/books/pdf-evidence-watch/
```

This template keeps the same ownership split:

```text
Moondesk creates/edits the book config and method
  -> Moontown registers a standing goal
  -> MoonBook owns PDFs, extracted text, wiki, review queue, and projection
  -> MoonClaw discovers, downloads, extracts, analyzes, and packages results
  -> MoonBook accepts or rejects new knowledge
  -> Moontown notifies only on accepted knowledge changes
```

The important files are:

- `book.json`
  stores websites, cadence, notification rules, and method path.
- `raw/bootstrap/PDF_WATCH_CONTRACT.md`
  defines lifecycle, accounting, and standing-watch markers.
- `wiki/methods/analysis-method.md`
  is where the operator writes the analysis method.
- `skills/pdf-watch/SKILL.md`
  guides discovery, download, extraction, dedupe, and watch accounting.
- `skills/pdf-analysis/SKILL.md`
  guides extracted-text analysis and baseline comparison.
- `schemas/pdf-source.schema.md`
  defines accepted/rejected/review source pages.
- `schemas/analysis-result.schema.md`
  defines per-run analysis results.

Create a default PDF-watch book from the reusable template:

```bash
moon run src/cmd/main -- books pdf-watch bootstrap
moon run src/cmd/main -- books pdf-watch status
```

Create a named PDF-watch book:

```bash
moon run src/cmd/main -- books pdf-watch bootstrap research-my-domain-pdf-watch
moon run src/cmd/main -- books pdf-watch status research-my-domain-pdf-watch
```

Archive a temporary or completed PDF-watch book without deleting its workspace:

```bash
moon run src/cmd/main -- books pdf-watch archive research-my-domain-pdf-watch
```

Archiving disables every standing goal targeting the book, including the PDF
watcher and any `book-quality-repair-<book-id>` repair goal. It also tags the
catalog entry as `archived`/`hidden`/`internal`, preserves the workspace for
audit, and appends an `archived` lifecycle event to
`.moontown/book-template-request-events.jsonl`. Use this for smoke proofs and
retired watches so they do not keep consuming autonomous daemon cycles.
Archived watches remain in `.moontown/standing-goals.json` as disabled audit
records. `status`, `live status`, and the operator console now separate active
enabled watches from disabled archived watches, so preserved history does not
look like live autonomous workload.

Install a fully configured PDF-watch book from a Moondesk/exported JSON file:

```bash
moon run src/cmd/main -- books pdf-watch install assets/templates/books/pdf-evidence-watch/install.example.json
```

The config file shape is:

```json
{
  "book_id": "research-my-domain-pdf-watch",
  "title": "My Domain PDF Watch",
  "purpose": "Watch approved websites for relevant PDFs and notify only when accepted knowledge changes.",
  "websites": ["https://example.org/reports"],
  "analysis_method": "",
  "analysis_method_path": "analysis-method.example.md",
  "cadence_ticks": 30,
  "workspace_root": ""
}
```

If `analysis_method` is empty, Moontown reads `analysis_method_path` relative
to the config file. If `workspace_root` is empty, Moontown uses the standard
`.moontown/books/<book-id>` workspace. This is the intended Moondesk contract:
Moondesk edits a JSON file plus a method Markdown file; Moontown installs the
book and standing goal; MoonBook/MoonClaw handle the watch loop.

The command writes:

- `.moontown/books/<book-id>/book.json`
- `.moontown/books/<book-id>/raw/bootstrap/PDF_WATCH_CONTRACT.md`
- `.moontown/books/<book-id>/wiki/methods/analysis-method.md`
- `.moontown/books/<book-id>/skills/pdf-watch/SKILL.md`
- `.moontown/books/<book-id>/skills/pdf-analysis/SKILL.md`
- `.moontown/books/<book-id>/book/site/generated/index.html`
- a registered MoonBook catalog entry in `.moontown/moonbooks.json`
- a standing goal in `.moontown/standing-goals.json`

Example standing goal:

```json
{
  "id": "watch-my-domain-pdfs",
  "title": "Watch my domain PDFs",
  "prompt": "Watch configured websites for relevant PDFs, download and extract new PDFs, analyze them using the book method page, update only when accepted new knowledge appears, and notify the operator when useful knowledge changes.",
  "target_book_id": "research-my-domain-pdf-watch",
  "cadence_ticks": 30,
  "next_due_tick": 0,
  "enabled": true,
  "source_policy": "web-first",
  "quality_threshold": 90
}
```

Moondesk should call this installer rather than hand-copying directories. Its
creation wizard should fill `book.json`, edit
`wiki/methods/analysis-method.md`, and let the operator add websites,
cadence, and notification policy. Moontown should not need a new MoonBit
branch for every PDF-watched domain.

The expected MoonBook result marker for a standing watcher is:

```text
standing_goal_decision: update | no_change | needs_review | failed
delta_score: 0-100
new_source_count: <integer>
next_check_hint: normal | slower | faster | review
checked_sources_count: <integer>
new_sources_found: <integer>
accepted_facts_count: <integer>
rejected_facts_count: <integer>
wiki_pages_changed_count: <integer>
book_changed: yes | no
```

Moontown uses that marker only for control-plane scheduling:

- `update`: normal cadence
- `no_change`: increasing no-change backoff, capped at 4x cadence
- `needs_review`: shorter review retry window
- `failed`: shorter failure retry window
- active duplicate watcher: defer one tick

Accounting rule: retries, generated site rebuilds, journal maintenance, and
failed/no-change checks are not research evidence. Only MoonBook-accepted facts,
review items, and changed durable book pages count as book progress.

Moontown also normalizes MoonBook summary accounting at the adapter boundary:

- `evidence_count` means domain evidence used for readiness.
- `operational_evidence_count` means watcher audits, no-change patrol records,
  run wrappers, and other control-plane evidence.
- `total_evidence_count` preserves the raw support-record count for audit trails.

The latest verified no-change shape looks like this:

```text
standing_goal_decision: no_change
delta_score: 10
new_source_count: 0
next_check_hint: slower
checked_sources_count: 4
new_sources_found: 1
accepted_facts_count: 0
rejected_facts_count: 1
wiki_pages_changed_count: 0
book_changed: no
```

Interpretation: the watcher executed a real check, opened enough sources to
judge them, found one candidate signal, rejected it, and correctly left the
book unchanged. This is healthy 24/7 behavior. A no-change cycle is only a
problem if `checked_sources_count` stays zero during cycles that claim to have
searched.

### App ToolBooks

For domains where the book should produce both knowledge and a usable web tool,
use the `app-tool-book` template:

```text
assets/templates/books/app-tool-book/
```

This template creates a MoonBook workspace with:

- `tool-manifest.json`
- `wiki/reports/latest-analysis.md`
- `wiki/tools/tool-spec.md`
- `app/index.html`
- `book/site/generated/tool.html`
- `skills/tool-watch/SKILL.md`
- `skills/tool-build/SKILL.md`

Ownership split:

```text
Moondesk edits config, method, tool spec, and review decisions
  -> Moontown installs the template and registers a standing goal
  -> MoonBook owns data, reports, app source, generated site, manifest, review
  -> MoonClaw watches sources, analyzes deltas, updates/repairs the tool
  -> Moontown links the generated tool from a civic building
```

Create a default App ToolBook:

```bash
moon run src/cmd/main -- books app-tool bootstrap
moon run src/cmd/main -- books app-tool status
```

Install one from a Moondesk/exported config:

```bash
moon run src/cmd/main -- books app-tool install assets/templates/books/app-tool-book/install.example.json
moon run src/cmd/main -- books app-tool status app-tool-market-signal-lab
```

The config file shape is:

```json
{
  "book_id": "app-tool-market-signal-lab",
  "title": "Market Signal Lab",
  "purpose": "Watch approved data sources, analyze useful changes, and expose an interactive dashboard through a civic building.",
  "websites": ["https://example.org/data"],
  "analysis_method": "",
  "analysis_method_path": "analysis-method.example.md",
  "tool_spec": "",
  "tool_spec_path": "tool-spec.example.md",
  "civic_building_id": "market-signal-lab",
  "cadence_ticks": 60,
  "workspace_root": ""
}
```

The generic template-request inbox also supports this book type:

```json
{
  "requests": [
    {
      "id": "create-market-signal-lab",
      "template_id": "app-tool-book",
      "config_path": "book-template-configs/market-signal-lab.json",
      "status": "pending",
      "summary": "",
      "last_processed_tick": 0
    }
  ]
}
```

The daemon's `book-template-request` job processes that request without Codex
manual file creation. Once installed, the standing goal keeps the book alive;
MoonClaw should update `raw/data/latest.json`, `wiki/reports/latest-analysis.md`,
`app/`, `book/site/generated/tool.html`, and `tool-manifest.json` only when the
book's accepted knowledge or tool behavior changes.

## 2. Use The Persisted Town State

The demo town persists runtime bootstrap files under:

- `.moontown/moonbooks.json`
- `.moontown/town.json`
- `.moontown/daemon.json`
- `.moonsuite/products/moontown/packets/` when packet files are exported
- `.moontown/daemon-runtime.json`
- `.moontown/daemon.log`
- `.moontown/daemon.pid`
- `.moontown/daemon-supervisor.pid`
- `.moontown/standing-goals.json`
- `.moontown/watchers/*.jsonl`
- `.moontown/books/<book>/` for MoonBook lane workspaces
- `.moontown/books/wenyu-*/` for civic MoonBook workspaces created by
  `moon run src/cmd/main -- civic bootstrap`
- `.moontown/town-synthesis/` for mayor-level cross-book reports

## 2.1 Manage Book Types And Quality

List available book templates:

```bash
moon run src/cmd/main -- books templates
moon run src/cmd/main -- books templates status
```

Install a book through the generic template registry:

```bash
moon run src/cmd/main -- books template install pdf-evidence-watch assets/templates/books/pdf-evidence-watch/install.example.json
moon run src/cmd/main -- books template install app-tool-book assets/templates/books/app-tool-book/install.example.json
```

Process Moondesk or Mayor-submitted book creation requests:

```bash
moon run src/cmd/main -- books template requests status
moon run src/cmd/main -- books template requests process
```

During local UI development, the Rabbita operator console can queue the same
request without hand-editing JSON:

```bash
curl -X POST http://127.0.0.1:5173/api/book-template-requests \
  -H 'Content-Type: application/json' \
  -d '{
    "template_id": "pdf-evidence-watch",
    "title": "My Domain PDF Watch",
    "book_id": "research-my-domain-pdf-watch",
    "purpose": "Watch approved websites for relevant PDFs and notify only when accepted knowledge changes.",
    "websites": "https://example.org/reports",
    "cadence_ticks": "60",
    "analysis_method": ""
  }'
```

The browser endpoint is a development bridge, not a separate product contract:
it writes the same config document under `.moontown/book-template-configs/`
and the same request document under `.moontown/book-template-requests.json`.
Moondesk should use this document shape directly when it becomes the stable
human desktop surface.

The request inbox lives at `.moontown/book-template-requests.json` and has this
shape:

```json
{
  "requests": [
    {
      "id": "create-my-domain-pdf-watch",
      "template_id": "pdf-evidence-watch",
      "config_path": "books/my-domain-pdf-watch.json",
      "status": "pending",
      "summary": "",
      "last_processed_tick": 0
    }
  ]
}
```

`config_path` is resolved relative to the request inbox unless it is absolute.
Processing also appends lifecycle events to
`.moontown/book-template-request-events.jsonl`. That JSONL file is the durable
audit trail for unattended book creation: each processed request records the
request id, template id, resolved config path, status, tick, timestamp, and
installer summary. The status command prints the event log path and latest
event so an operator can distinguish “request exists” from “request was
actually installed or failed”.

The daemon includes a `book-template-request` scheduled job, so pending
requests can be processed as part of the live loop. This is the preferred
document-first handoff for Moondesk and future Mayor planning: create a request
document, let Moontown install the appropriate template, then let MoonBook and
MoonClaw handle the running book.

`moon run src/cmd/main -- status` reports the same inbox as:

```text
book_template_requests=<count> pending=<pending+retry> failed=<failed> ...
```

The same status line also reports standing watches as both total and active
workload:

```text
standing_goals=<total> enabled=<active> disabled=<archived> due_next_tick=<due>
```

Use `enabled` as the current 24/7 workload count. Use `disabled` to audit
retired or archived watches that are intentionally preserved but should not
consume daemon cadence.

`moon run src/cmd/main -- live status` reports the inbox in the live autonomy
spine as `Book template requests`, `Pending template requests`, and
`Failed template requests`, plus `Enabled standing goals`,
`Disabled standing goals`, and the latest book-template lifecycle event. The
generated digest at
`.moontown/live-digest.md` includes the same fields, which makes Moondesk
book-creation handoffs visible in the 24/7 operator surface instead of hiding
them in the daemon log.

That line is part of the stable autonomy spine: if the town is alive but
waiting, pending and failed template requests should be zero; if Moondesk or
Mayor submits a new book request, this line should change before the daemon
installs the book.

The registry is data-driven by
`assets/templates/books/templates.json`. Moondesk should read the same registry to
show available book types, editable files, install examples, and required
template assets. The generic installer dispatches to the template-specific
installer but keeps the UI/Mayor contract stable.

Bootstrap the stable cookbook:

```bash
moon run src/cmd/main -- cookbook bootstrap
moon run src/cmd/main -- cookbook status
```

Bootstrap the current planbook:

```bash
moon run src/cmd/main -- planbook bootstrap
moon run src/cmd/main -- planbook status
moon run src/cmd/main -- planbook doctor
moon run src/cmd/main -- planbook autonomy
moon run src/cmd/main -- planbook repair
moon run src/cmd/main -- planbook repair status
```

`planbook doctor` is the self-build check. It writes
`.moonsuite/products/moontown/planbook/autonomy.json`,
`.moonsuite/products/moontown/planbook/autonomy.md`, and the
PlanBook workspace pages `wiki/planning/execution-evidence.md`,
`wiki/planning/self-healing.md`, and `wiki/reviews/active-plan-review.md`.
Daemon ticks run the same check and the live spine exposes
`planbook_open_count`, so unresolved implementation gaps stay visible while the
town is running.

The editable implementation backlog lives in the PlanBook workspace:

- `raw/backlog/implementation-backlog.json`
- `wiki/planning/implementation-backlog.md`
- `wiki/planning/backlog-progress.md`
- `wiki/planning/stop-policy.md`
- `wiki/history/change-log.md`
- `raw/backlog/completed/<id>.md`

Add future self-build work by editing the JSON backlog. The daemon will pick the
highest-priority open item after stricter self-build criteria are satisfied.
Open items are taken one at a time. When the backlog is clear, the code-building
check decays to a 30-minute interval. If a worker discovers the selected item is
already done, it should write completion/progress evidence and update the plan
or backlog instead of producing unnecessary code.

`planbook repair` queues the first open self-build gap as a bounded PlanBook
repair packet. It writes repair context, repair skill instructions, a restartable
repair plan, and `.moonsuite/products/moontown/planbook/repair-task.json`. During live operation,
daemon ticks run the same path automatically: if a gap is open and no repair is
active, the town dispatches one repair through MoonClaw using `execution_mode:
acp` and `execution_target: codex-main`, so Codex ACP can patch the Moontown
source root and return software-engineering evidence. Daemon dispatch is
detached, so long code-repair runs cannot stall real-world watcher cadence.
Accepted source repairs must include `planbook.repair.patch_receipt.v1`
evidence. That receipt proves source-root ACP execution, changed files,
validation command results, `git status --short`, `git diff --check`, focused
diff summary, commit status/message, and push policy. Without the receipt, the
result can still be a useful diagnostic, blocker, or no-change record, but it
must not close the source-patch criteria.
For `backlog-*` criteria, accepted repairs must also write
`raw/backlog/completed/<id>.md` and record `plan_update_status`. Use
`planbook repair --dispatch` as an explicit operator/debug trigger. Daemon ticks
leave active repairs alone until they are resolved or inspected.
If MoonClaw reports temporary dispatch contention, the repair packet stays
queued and the daemon retries while the gap remains open; it is not counted as a
blocked implementation failure.

For live operation, use `daemon doctor` to verify the supervisor and worker are
healthy:

```bash
moon run src/cmd/main -- daemon doctor
moon run src/cmd/main -- live status
```

The daemon preserves the supervisor-recorded worker PID so a worker does not
corrupt its own runtime identity and cause duplicate daemon workers. If
`daemon doctor` reports stale runtime, restart the daemon before trusting live
status.

Bootstrap the Wenyu beginner course book:

```bash
moon run src/cmd/main -- course wenyu-game-design bootstrap
moon run src/cmd/main -- course wenyu-game-design status
```

Repair canonical registered book workspaces, then inspect structural readiness:

```bash
moon run src/cmd/main -- books bootstrap
moon run src/cmd/main -- books doctor
moon run src/cmd/main -- books quality
```

Generate AI semantic review packets:

```bash
moon run src/cmd/main -- books ai-review-packets
```

Dispatch the next pending semantic review manually:

```bash
moon run src/cmd/main -- books ai-review --dispatch
moon run src/cmd/main -- books ai-review status
```

The `books doctor` structural readiness column is intentionally deterministic.
It checks whether a book has the expected workspace, contract, skills,
projection, and service-loop artifacts. It should not be treated as a book
quality score.

`books bootstrap` repairs the canonical book families together:

- coding and finance operational books
- `moontown-cookbook`
- `plan-moontown-quality`
- `course-wenyu-game-design`
- all Wenyu civic protocol support workspaces

Each family is bootstrapped with a different workspace shape. Course books use
course contracts, lessons, exercises, and checkpoints. Planbooks use plan
indexes, execution evidence, active review, decision logs, and plan schemas.
Cookbook uses stable-state definitions and operating procedures. Civic protocol
support workspaces use the substrate required by their persistence mode:
schemas, service ledgers, exchange ledgers, review queues, service history,
generated projections, and MoonClaw skill contracts. The civic building itself
remains the protocol place.

`books quality` is broader than the curated catalog. It merges live books from
`.moontown/town.json` before scoring, so standing-watch books created by the
runtime, such as OPC, LLM training, robotics, agents, and hardware, are visible
to quality checks even before an operator curates them into the catalog.

The AI review packets are the semantic layer. They ask MoonClaw/MoonBook to read
the book's own contract and `SKILL.md`, then judge role fit, correctness,
usefulness, curiosity, originality, evidence accounting, and next repairs. That
is where “world-class” quality should be decided. Write those review results to
`.moontown/book-quality/ai-review-results/<book-id>.md`.

The live daemon includes a `review-book-quality` scheduled job. It dispatches at
most one semantic review at a time and skips duplicate dispatch while an active
MoonClaw review is still running. This makes book maturation autonomous without
turning the town into an unbounded generic agent loop. Scheduled jobs honor
their `interval_seconds` cadence; `review-book-quality` defaults to a
thirty-minute interval. Scheduled semantic reviews are launched detached from
the daemon tick even when inline MoonClaw execution is enabled for other paths;
otherwise a long AI review would monopolize the Mayor supervision loop.

On every `review-book-quality` tick, Moontown first reconciles existing AI
review results. Weak results are not counted as progress. They are bridged into
the affected MoonBook as `wiki/reviews/book-quality-repair.md`, recorded in
`.moontown/book-quality/repair-bridge.json`, and converted into a bounded
standing goal named `book-quality-repair-<book-id>`. Research-book repairs use
`web-first`; course, civic, cookbook, planbook, and operational book repairs use
`book-first` so the target book's own contract and skill decide the work shape.
If a later semantic review reaches the quality threshold, or the target book is
removed from the managed catalog or archived as hidden/internal, the bridge
retires the stale `book-quality-repair-<book-id>` standing goal instead of
letting the daemon keep polling a satisfied or retired gap.
For immediate inspection or recovery, run `moon run src/cmd/main -- books ai-review
bridge`; the daemon runs the same reconciliation automatically on the scheduled
cadence.

`moon run src/cmd/main -- books ai-review status` is intentionally split into two
views:

- `Current By Book`
  shows the latest effective semantic-review state for each book. This is the
  operational truth for whether a book still needs review or recovery.
- `Historical Attempts`
  preserves earlier blocked, orphaned, or duplicate attempts as audit trail. If
  a later current row is `written`, the earlier failure is already recovered and
  should not be counted as active unresolved work.

What they do:

- `.moontown/moonbooks.json`
  - stores the available books loaded into town bootstrap
- `.moontown/town.json`
  - stores the seeded town snapshot
- `.moontown/daemon.json`
  - stores daemon state, tick sequence, lease owner, heartbeat event count, active goal ids, and scheduled job metadata
- `.moontown/daemon-runtime.json`
  - stores supervised daemon process state, heartbeat times, tick counters, last error, and stop-request status
- `.moontown/daemon.log`
  - stores supervisor and worker lifecycle records for restart/debug accounting
- `.moontown/daemon.pid`
  - stores the current daemon worker process id
- `.moontown/daemon-supervisor.pid`
  - stores the current daemon supervisor process id
- `.moontown/standing-goals.json`
  - stores Mayor-owned standing goals, target book, cadence, source policy, last run tick, and next due tick
- `.moontown/watchers/*.jsonl`
  - stores standing-watch decisions, target book, task/run ids, strict research accounting, detail, and next due tick
- `.moontown/books/<book>/raw/bootstrap/`
  - stores research questions, search logs, source screens, evidence matrices,
    local source digests, and synthesis briefs
- `.moontown/town-synthesis/*.md`
  - stores cross-book mayor synthesis reports

Current persistence code:

- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)
- [storage/store.mbt](/Users/kq/Workspace/moontown/src/storage/store.mbt)

If those files do not exist, `moontown` creates them during bootstrap. It also
initializes missing MoonBook workspaces and seeds the MoonBook MoonClaw
extension pack before attempting proposal import.

## 3. Edit The Town Books

The simplest real customization point is the moonbook catalog.

Edit:

- `.moontown/moonbooks.json`

Each catalog entry describes one book:

- `id`
- `name`
- `purpose`
- `workspace_root`
- `memory_scope`
- `tags`
- `skills`

Current defaults are created by:

- `default_catalog()` in [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)

Current built-in books:

- `coding`
- `finance`

If you want a different town shape, this is the first file to change.

## 4. Understand The Current Town Model

Core town types live in:

- [core/types.mbt](/Users/kq/Workspace/moontown/src/core/types.mbt)

Important concepts:

- `TownConfig`
- `BookRef`
- `WorkerRef`
- `TownTask`
- `TaskExecutionStatus`
- `TaskExecutionRecord`
- `TownEvent`
- `TownState`
- `BookProvider`

This is the current ownership split:

- town data model
  - `core/`
- dispatch
  - `dispatch/`
- health
  - `health/`
- scheduling
  - `scheduler/`
- persistence
  - `storage/`

If you want to “use the system as code”, start there.

## 5. Use The Mayor Role

The strategic town runtime is modeled as `Mayor`.

Code:

- [roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)

Current Mayor capabilities:

- decide dispatch
- run patrol
- produce keeper handoff packets
- prepare keeper proposal packets

Current embedded moonclaw runtime metadata:

- [adapters/moonclaw/import.mbt](/Users/kq/Workspace/moontown/src/adapters/moonclaw/import.mbt)

Important current functions:

- `Mayor.decide_dispatch(...)`
- `Mayor.patrol(...)`
- `Mayor.handoff_to_keeper(...)`
- `Mayor.prepare_keeper_packet(...)`

This is the right entry if you want to extend strategic orchestration.

Role lifetime rule:

- Mayor is the long-lived town supervisor through daemon ticks.
- Bookkeeper is the resident MoonBook role. It wakes on new results, standing
  watch updates, stale projections, review queue changes, or explicit operator
  requests, then decides what belongs in durable book memory.
- Worker claws are freelance bounded executors. They spawn for a packet, use
  tools, emit result/evidence/artifacts, and exit.
- Every registered book has a watcher lane. Operational books still use their
  specialized harness/review/domain workers, but standing-watch goals route to
  `claw-<book-id>-watcher` so missing watcher capacity is repaired by the town
  instead of becoming repeated deferred work.

Do not model every worker as a persistent resident. Do not let temporary workers
own durable memory. For memory promotion, wiki upkeep, review queues, and
generated-site quality, route through the target MoonBook bookkeeper.

## 6. Use The Scene Dashboard Model

The renderer-agnostic town scene lives in:

- [src/ui/scene_layout.mbt](/Users/kq/Workspace/moontown/src/ui/scene_layout.mbt)
- [ui/dashboard.mbt](/Users/kq/Workspace/moontown/src/ui/dashboard.mbt)
- [src/ui/scene_render.mbt](/Users/kq/Workspace/moontown/src/ui/scene_render.mbt)

Current flow:

```text
TownState -> DashboardModel -> SceneRenderModel -> HTML / Rabbita
```

Current semantic places:

- Town Gate
- City Hall
- Moonbook / Coding
- Moonbook / Finance
- Worker Yard
- Anomaly Corner

Use this layer when you want to:

- change the town layout
- add new scene areas
- change asset slots
- add more dashboard-projected state

## 7. Use The Scene Assets

Current example assets live under:

- [src/ui/assets/backgrounds](/Users/kq/Workspace/moontown/src/ui/assets/backgrounds)
- [src/ui/assets/buildings](/Users/kq/Workspace/moontown/src/ui/assets/buildings)
- [src/ui/assets/actors](/Users/kq/Workspace/moontown/src/ui/assets/actors)
- [src/ui/assets/props](/Users/kq/Workspace/moontown/src/ui/assets/props)
- [src/ui/assets/effects](/Users/kq/Workspace/moontown/src/ui/assets/effects)

Current starter assets:

- `backgrounds/town-square.svg`
- `buildings/city-hall.svg`
- `buildings/book-house-coding.svg`
- `buildings/book-house-finance.svg`
- `actors/mayor-claw.svg`
- `actors/keeper-claw.svg`
- `actors/worker-claw.svg`
- `props/worker-yard.svg`
- `props/gate-sign.svg`
- `effects/anomaly-signal.svg`

These are original starter examples. You can replace them with richer art while
keeping the same scene keys.

## 8. Use The Keeper Packet Lifecycle

The current town model now tracks:

- keeper packet id
- packet path
- proposal id
- run id
- execution status

These lifecycle records live in:

- `TownState.executions`
- `TaskExecutionRecord`

The relevant code is in:

- [core/types.mbt](/Users/kq/Workspace/moontown/src/core/types.mbt)
- [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)
- [adapters/moonclaw/import.mbt](/Users/kq/Workspace/moontown/src/adapters/moonclaw/import.mbt)
- [roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)

The current lifecycle is:

```text
book task
  -> keeper packet
  -> imported proposal
  -> confirmed run
  -> run polling
  -> MoonBook persistence
  -> generated site refresh
  -> mayor quality gate
  -> review or complete
```

Current execution statuses include:

- `PacketReady`
- `ProposalImported`
- `RunConfirmed`
- `Running`
- `AwaitingPersistence`
- `ReviewQueued`
- `Completed`
- `Failed`

## 9. Run A Parallel Research Goal

The goal runner can split a multi-topic research request into isolated
MoonBook lanes. For example:

```bash
moon run src/cmd/main -- run "research moontown, moonbook, and moonclaw"
```

For that goal, the mayor currently creates one book lane per named subject:

- `research-moontown`
- `research-moonbook`
- `research-moonclaw`

Each lane gets its own MoonBook workspace under:

- `.moontown/books/research-moontown`
- `.moontown/books/research-moonbook`
- `.moontown/books/research-moonclaw`

The mayor then imports keeper packets into MoonClaw, polls run status, persists
terminal results back into the lane's MoonBook workspace, and asks MoonBook to
refresh the generated site.

## 10. Read The Town Synthesis

After a parallel research goal settles or times out, Moontown writes a
town-level synthesis artifact under:

- `.moontown/town-synthesis/<goal-slug>.md`
- `.moontown/town-synthesis/latest.md`

The synthesis is a mayor-owned control-plane projection. It summarizes:

- executive summary
- integrated research narrative
- lane count
- running/completed/review/failed lane status
- verified source counts
- evidence, entity, and concept counts
- generated-site paths
- W-source and L-source evidence references from each lane
- comparative findings
- maturity and gap summary
- lane readiness gaps
- the mayor decision for whether the goal is complete or still blocked

This is intentionally not a MoonBook page. MoonBook owns durable domain
knowledge; Moontown owns cross-book supervision and acceptance.

## 11. Understand The Research Quality Gate

Moontown now blocks weak research instead of accepting file existence as
success. For research lanes, the mayor checks for required bootstrap artifacts
and rejects output that still contains provisional-only markers.

Examples of blockers:

- missing bootstrap files such as `search-log.md` or `evidence-matrix.md`
- no verified source digest under `wiki/sources/`
- synthesis brief is not lane-specific
- web candidates were listed but not fetched and screened
- search log says the web pass may be enriched later
- wiki synthesis still says review is pending

When those gaps exist, Moontown marks the lane as `ReviewQueued` and the town
synthesis remains blocked or interim.

## 12. Run The Rabbita Frontend

The browser frontend lives in:

- [src/ui/rabbita-town](/Users/kq/Workspace/moontown/src/ui/rabbita-town)

From that directory:

```bash
cd src/ui/rabbita-town
npm install
npm run dev
```

Or from the repo root:

```bash
./scripts/build-rabbita-ui.sh
```

Important frontend files:

- [src/ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/src/ui/rabbita-town/main/main.mbt)
- [src/ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/src/ui/rabbita-town/styles.css)
- [src/ui/rabbita-town/index.html](/Users/kq/Workspace/moontown/src/ui/rabbita-town/index.html)
- [src/ui/rabbita-town/bootstrap.js](/Users/kq/Workspace/moontown/src/ui/rabbita-town/bootstrap.js)
- [src/ui/rabbita-town/vite.config.js](/Users/kq/Workspace/moontown/src/ui/rabbita-town/vite.config.js)

## 13. Use The Live Simulation Controls

The current Rabbita frontend is a live simulation dashboard.

What you can do in the UI:

- let ticks run continuously
- pause
- resume
- step one tick
- switch strategy
  - balanced
  - throughput
  - recovery
- inspect nodes and workers
- issue simulation actions
  - inject budget
  - relieve queue
  - stability drill

Current live metrics:

- budget
- energy
- pressure
- stability

Current dashboard surfaces:

- runtime summary bar
- Mayor command center
- standing-watch portfolio with all enabled topics, per-goal decision mix, next
  due tick, and latest watcher decision
- request composer that submits new standing goals through the local Vite endpoint
- Wenyu viewport portal linking to the standalone tilemap page
- inspector sidebar
- activity feed

Current visual behaviors:

- moving worker avatars in the standalone Wenyu viewport
- activity feed
- anomaly surfacing
- scene selection/inspector

On narrower screens, the scene now scrolls internally instead of clipping the
town layout.

The UI can still run demo simulation state, but the dev server now also bridges
real runtime files: `.moontown/town.json`, `.moontown/daemon.json`,
`.moontown/standing-goals.json`, `.moontown/watchers/*.jsonl`, and
`.moontown/operator-requests/requests.jsonl`.

Browser-submitted standing goals use
[assets/templates/operator-request-policy.json](/Users/kq/Workspace/moontown/assets/templates/operator-request-policy.json)
for their default `source_policy`. Change that document when the default Mayor
queue policy should change; do not patch the Vite request handler for ordinary
policy changes.

## 14. Validate Changes

For normal repo validation:

```bash
moon check
moon test
moon info
moon fmt
```

For UI changes, also run:

```bash
./scripts/build-rabbita-ui.sh
```

That is the expected workflow for this repo now.

## 15. Know The Current Boundaries

There are three important “real vs stubbed” boundaries.

Real now:

- persisted book catalog
- persisted town snapshot
- keeper packet generation
- proposal/run lifecycle records
- MoonClaw run polling for bounded goal runs
- MoonBook persistence and generated-site refresh after terminal goal runs
- mayor-level research synthesis, integrated narrative, and quality gating
- strategic mayor role model
- dispatch and health model
- scene dashboard model
- Rabbita simulation frontend

Stubbed now:

- experiment runtime loop
- 24/7 daemon supervision
- restart-safe multi-day process supervision
- backend-synced Rabbita state

Separate ownership note:

- the Rabbita town dashboard belongs to `moontown`
- the generated workspace website under `.moontown/books/*/site/` belongs to
  `moonbook`

So the correct expectation is:

- use `moontown` today as a bounded control-plane runner and frontend prototype
- do not assume it already runs a durable 24/7 multi-agent backend

## 16. Best Entry Points By Goal

If you want to:

- change town data model
  - start in [core/types.mbt](/Users/kq/Workspace/moontown/src/core/types.mbt)
- change routing or isolation
  - start in [dispatch/router.mbt](/Users/kq/Workspace/moontown/src/dispatch/router.mbt)
- change strategic role behavior
  - start in [roles/mayor.mbt](/Users/kq/Workspace/moontown/src/roles/mayor.mbt)
- change persisted books
  - start in [adapters/moonbook/client.mbt](/Users/kq/Workspace/moontown/src/adapters/moonbook/client.mbt)
- change scene layout or assets
  - start in [src/ui/scene_layout.mbt](/Users/kq/Workspace/moontown/src/ui/scene_layout.mbt)
- change browser UI behavior
  - start in [src/ui/rabbita-town/main/main.mbt](/Users/kq/Workspace/moontown/src/ui/rabbita-town/main/main.mbt)
- change browser styling
  - start in [src/ui/rabbita-town/styles.css](/Users/kq/Workspace/moontown/src/ui/rabbita-town/styles.css)
