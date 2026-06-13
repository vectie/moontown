# Moontown Planbook

The planbook is one of Moontown's durable MoonBook archetypes.

Research books answer "what is true or changing?"
Course books teach "how should a beginner learn this?"
Planbooks decide "what should we build, change, verify, and ship?"
Cookbooks preserve "what is the accepted stable state?"

Generated tools are not a separate top-level book taxonomy. An App ToolBook is
a composed capability: a MoonBook policy plus a generated-tool surface,
standing-watch inputs, `tool-manifest.json`, app source, and a civic route.
This distinction matters because autonomous implementation should add policy
capabilities instead of inventing a new hardcoded book type every time a book
needs another surface.

The goal is to make planning a persisted artifact, not a chat side effect.
For non-trivial code or product work, Moontown should create or update a
planbook before execution starts. MoonClaw can then execute against the plan,
mark acceptance criteria, and leave reviewable evidence.

## Why This Exists

The current Moontown repo already has strong execution paths:

- MoonTown routes work and supervises the daemon.
- MoonBook owns durable workspace memory and projection.
- MoonClaw executes bounded work through skills and result contracts.

The weak point is product/code intent drift. A request can start as a design
idea, become a UI task, turn into a MoonBook task, and then land as code without
a stable checkpoint that explains why the direction is correct.

The planbook fixes that.

## Document Protocol Philosophy

PlanBook must preserve the town's baseline architecture rule:

> Everything durable is a document/book. Everything active is a protocol
> running over documents. Agents are temporary workers that read/write
> documents through protocols. Buildings are protocol places.

This rule is documented in
[docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
and in the PlanBook workspace at
[wiki/planning/document-protocol-philosophy.md](/Users/kq/Workspace/moontown/.moontown/books/plan-moontown-quality/wiki/planning/document-protocol-philosophy.md).

For future self-build work, the planbook should model durable state as files,
books, ledgers, schemas, and review queues. It should model active behavior as
protocol rounds over those documents. It should model MoonClaw agents as
temporary process-like participants, reducers, critics, reviewers, and
bookkeepers, not as the durable source of truth.

Every non-trivial implementation plan should include a `Document Protocol Fit`
section:

- source of truth: which document/book owns durable state?
- protocol owner: which building or plan owns active exchange?
- agent roles: which temporary workers are needed?
- ledgers: where are events and decisions appended?
- review gate: what must be accepted before promotion?
- projection: which UI or site reads the resulting state?

If a plan cannot answer those questions, it is not ready for autonomous
implementation.

## BookPolicy Compass

PlanBook should treat every future book feature as a policy change first, not
as a new hardcoded book type.

The policy model lives in the dedicated
[policy](/Users/kq/Workspace/moontown/src/policy) package. New plans should import
and compose that package directly. Root-level code may contain adapters from
legacy labels to policy values, but it should not grow a parallel policy API.
The same package owns the executable loop description through
`loop_plan(policy)` and `loop_markdown(policy)`: read the policy, execute
execute-lane skills, record results under the output contract, run tend-lane
skills, and evaluate health. Future repair plans should reference that API
instead of writing their own loop sequence into prompt text, review criteria, or
status pages.

The mapping from policy-owned legacy labels such as `research-book`,
`course-book`, and `civic-protocol-support` into composed `BookPolicy` values
belongs in `policy/book_policy_profiles.mbt`. The book-quality migration
adapter lives in the dedicated
[book_quality](/Users/kq/Workspace/moontown/src/book_quality) package; it may
attach repair actions to those profiles for scoring/review workflows, but it
must not rebuild the profile map or duplicate source-policy fields outside
`@policy.PolicyProfile`. Catalog string/tag classification rules such as
archived/transient and cookbook/planbook/course/research/civic/operational
classification belong in `policy/book_policy_catalog.mbt`, not book-quality.
Book-quality may expose facade helpers for its scoring callers, but future
plans should change classification in `policy/` first. When catalog metadata is
available, plans should require code to call policy classification instead of
branching directly on storage prefixes like `research-` or `wenyu-`; those
prefixes are compatibility and slug conventions, not the architecture. It also owns
book-quality path contract helpers such as
workspace path composition, wiki index path, projection state path, generated
site path, and review result path. It owns base workspace, per-path, and typed
path-set score calculation and strength/gap wording too; root may observe which
files exist or are missing, but it should pass that observation into
`book_quality` assessment helpers instead of redefining scoring math. It also
owns research word-count thresholds, course identity scoring, civic latest-result
scoring, cookbook audit-link scoring, and generated-skill exploration quality
contracts. Skill templates should call `@book_quality.skill_quality_*` helpers
for depth, breadth, curiosity, judgment, long-horizon memory, and auditable
progress requirements instead of defining root-local MoonBook skill predicates.
Book-quality plans may judge observed document shape, but id/type
interpretation must use `policy.catalog_entry_type(...)` rather than direct
storage-prefix checks.
MoonBook adapter plans must preserve catalog-first lookup, then use goal-derived
topic policy for explicit research requests that name a non-canonical book id.
They must not require the requested id itself to start with `research-`; the
stable `research-*` slug is a storage target, not an eligibility rule.
Catalog-level research topic hints from `topic:` tags or canonical
`research-*` storage slugs belong in `policy/`; detailed research topic
mechanics belong in `research_policy/`. Adapters and quality packages should
consume policy hints, then call `research_policy` for attempt-suffix stripping,
topic normalization/display, local-vs-external routing, query/reference/local
source hints, canonical raw/wiki artifact paths, canonical research skill path
sets, research context-page sets, and bootstrap output-contract lines. Dynamic
MoonBook research-entry creation must call the catalog hint, then use
`research_policy` before constructing a stable storage entry. Future plans must
not add another adapter-local research topic table, artifact-path table,
research context table, bootstrap output-contract table, or research skill-path
table.
Wenyu/civic plans must keep module identity predicates in `civic/`; town
runtime may ask whether an entry is a Wenyu build book, but it must not branch
directly on `wenyu-*` slugs. Build-pipeline and quality plans should follow the
same rule: call civic identity helpers, then compose their own task contracts or
quality gates from that result.
Course-book implementation follows the same domain/runtime split:
`course_book/` owns course identity, catalog-entry shape, teaching contracts,
route policy, generated UI state, and generated HTML, while
`course_book_runtime/` owns MoonBook catalog mutation, source artifact reads,
workspace writes, and readiness status from filesystem observations. Future
plans must not add file IO, catalog load/save, or source-workspace harvesting
back into `course_book/`; those are runtime duties.
Root may pass observed facts, but it
should not own thresholds, point values, or note wording. Root may adapt MoonBook catalog entries into those classifier
inputs, but it should not redefine the labels. It also owns the public
audit/review DTOs: score records, audit summaries, review packets, review runs,
and review run ledgers. It also owns semantic review packet templates:
context-page selection, reviewer skill markdown, AI review output contract,
packet construction, and packet-pack README rendering.
Static profile scoring rules such as research/course/PlanBook/Cookbook/civic
required-path lists are also package-owned data. Root scoring may check whether
those paths exist in a workspace, but it should not define the profile lists.
Structural observers should consume `@book_quality.required_paths_for_book_type`
instead of rebuilding type-to-required-path switches.
Root book-quality files may still orchestrate audits, write files, dispatch
MoonClaw, and run repair bridges, but they should operate on
`@book_quality.*` contracts instead of defining their own domain records or
packet semantics. Review-run ledger paths, parsing, serialization, and append
semantics are package-owned storage contracts; root code should only decide
when to dispatch or reconcile. Accepted review result storage is package-owned
too; root should not define the result path or accepted-result write helper.
Review lifecycle vocabulary is also package
owned: queued/dispatched/running/written/orphaned/blocked status names,
bucket classification, terminal correction, stale-window math, accepted review
transformations, review result paths, review-run construction, review
reconciliation result DTOs, review ledger views, and Markdown rendering
contracts belong to `book_quality/`, not root orchestration. Reconciliation
record construction for unchanged runs and existing result files also belongs
there; `book_quality_runtime/` should observe files, fetch MoonClaw content,
poll process state, and ask the package to build the durable reconcile result.
Repair bridge ledger/item schemas
also belong to `book_quality/`; root code may translate those items into Mayor
standing goals, but the durable book-quality repair record format should have
one package owner. Structural and semantic
assessment rules also belong there, so root scoring can assemble a score from
workspace files without redefining what "strong", "ready", or "needs repair"
means. AI review result parsing belongs there too; root code may read result
files, but `book_quality/` defines how `ai_quality_score`, `repair_owner`, and
`next_repair_task` are interpreted. Audit aggregation and Markdown rendering
also belong there, so root commands write audit files without owning the report
format. Semantic review candidate filtering and ordering also belong there:
`book_quality/` decides which scores remain pending by inspecting semantic
review result files through its package API, and it decides which pending
book-quality score is weaker and should be reviewed first. Root orchestration
should pass the audit and result directory, not construct completed-id lists.
Review-status summary rendering, active-review counting/status policy,
stale/orphan review reconciliation policy, and result-state wording also belong
there; root may pass observed filesystem/process facts, but should not own the
ledger summary language, duplicate-dispatch active count, orphaning rules, or
the pending/written display decision. Semantic review profile policy
also belongs there: profile id, execution-target metadata contract, preferred
skills, role-runtime envelope, target-parameterized MoonClaw jobs profile JSON,
packet step metadata, and neutral review proposal spec are package-owned. The
semantic-review ACP config belongs to
`book_quality_runtime/`, which combines those review semantics with the
adapter-owned Codex target JSON and adapts the neutral review proposal spec to a
MoonClaw external proposal packet at dispatch time. Root may pass the observed
source root, resolved Codex command, args, and model, but it should not define
the `codex-main` target schema, reviewer label, packet ids, context page paths,
skill paths, tags, notes, request text, or metadata itself.
Book-quality run-record semantics are package-owned, but MoonClaw import
receipts and detached runner command lookup belong to `book_quality_runtime/`.
MoonClaw run observation belongs there too: the runtime package owns process
liveness checks, workspace-result harvesting, poll summaries, accepted-result
writes, and ledger persistence around those observed facts. `book_quality/`
owns the ledger schema and pure state transition from observed facts to durable
review-run status.
Future plans should pass observed proposal/run fields into `book_quality/`
instead of adding MoonClaw receipt types to the domain package.
The same rule applies to ordinary catalog-backed keeper packets: caller code
passes the catalog entry, task, and hydrated context, while
`adapters/moonclaw` attaches the policy-owned context metadata and consumes
`moonclaw_policy` keeper-profile overrides. PlanBook tasks should not copy
policy context fields or profile ids into root orchestration.
Root must resolve Codex ACP defaults through the `adapters/codex` boundary:
`model()`, `command()`, `args()`, `moontown_args()`, reusable `codex-main`
target JSON/upsert helpers, and target JSON builders.
Do not hard-code separate Codex model strings in PlanBook, book-quality, Wenyu
build, or future self-build profiles. The configured args must include
`--model <model>` because MoonClaw exposes the model as launch metadata/env and
does not automatically rewrite Codex CLI arguments.
Book-quality's semantic-review ACP config builder enforces this by normalizing
caller-provided args: if `--model` is missing it is appended, and if the flag is
present with a stale value it is rewritten to the configured model. Future
repair profiles should follow the same adapter-first model boundary rather than
treating metadata-only model fields as executable proof.
PlanBook source repair now uses the adapter-owned `codex-main` target builder,
so future repair work should not reconstruct backend/label/cwd/workspace/
command/args/model target JSON in root files.
PlanBook source-repair policy lives in the dedicated
[planbook_policy](/Users/kq/Workspace/moontown/src/planbook_policy) package. It
owns the autonomy/repair DTOs, validation command list, repair result contract,
PlanBook validation-evidence contract/readiness, repair decision vocabulary,
engineering-evidence markers, ACP patch-receipt contract, MoonClaw status bucket
mapping, and the pure repair workspace layout paths. That includes repair
context/result filenames, packet path derivation,
skill/plan page paths, target pages, and MoonClaw repair index paths. It also
owns the repair request task-rule wording that tells workers how to load
context, respect ownership boundaries, edit exact target files first, handle
selected editor features, validate, inspect diffs, commit, avoid churn, update
stale plans, complete backlog items, write results, and satisfy gates. It also
owns the generated `planbook-repair` skill text because that text defines the
worker contract, concrete example, accepted patch-receipt requirements, and
no-churn rules. It also owns implementation-backlog policy: backlog item schema,
canonical backlog/progress/stop/completion/change-log paths, default seed
items, generated backlog/progress/stop Markdown, cadence calculation, criterion
id/evidence/next-action wording, and target-file hints. Root
PlanBook code may still inspect workspaces, materialize repair files, dispatch
MoonClaw packets, and read run outputs, but future plans should not add
root-local copies of repair receipt fields, validation commands, repair paths,
repair request rules, generated repair skill text, run-status predicates, or
backlog schema/rendering/cadence semantics.
Live-autonomy policy lives in the dedicated
[live_autonomy_policy](/Users/kq/Workspace/moontown/src/live_autonomy_policy)
package. It owns the live spine DTO, journal/probe DTOs, active worker and
execution counting rules, transient-infrastructure-debt predicate, autonomy
tick calculation, aggregate metric-count DTO/assembly, stable-waiting blocker
policy, waiting-streak progression, next-action wording, status classification,
canonical live-status Markdown renderer, and canonical live-autonomy path
derivation. Root code may supply the current snapshot path and PlanBook
workspace root, perform filesystem refresh, snapshot reconciliation, health inspection, watcher-ledger reads,
latest-watcher-decision derivation, and PlanBook count synchronization, but
future plans should not add root-local copies of live-worker semantics,
metric-count shape, stable-waiting rules, transient-debt recognition,
next-action wording, live-autonomy file naming, or the operator status Markdown
contract.
Health anomaly detection and exact-title anomaly counts live in the dedicated
[health](/Users/kq/Workspace/moontown/src/health) package. Runtime-status and
live-autonomy code should consume `HealthReport` values and call health-owned
counting helpers instead of reimplementing anomaly-title semantics locally.
Runtime-status policy lives in the dedicated
[runtime_status_policy](/Users/kq/Workspace/moontown/src/runtime_status_policy)
package. It owns the runtime status DTO, empty-status contract, effective
execution de-duplication, lifecycle ranking, active/review execution-status set
membership, standing-goal runtime accounting, stable summary metric language,
and reusable operator report rendering. Root code and live-autonomy policy may
load snapshots, daemon state, watcher ledgers, and book-template request
inboxes, then pass observed state and root-only daemon health strings into the
package. Future plans should not add root-local copies of execution ranking,
active/review status lists, status-count semantics, runtime summary wording, or
status report formatting.
Daemon-runtime policy lives in the dedicated
[daemon_runtime_policy](/Users/kq/Workspace/moontown/src/daemon_runtime_policy)
package. It owns daemon runtime state/health DTOs, status-mode classification,
heartbeat age/staleness rules, durable-worker/supervisor activity predicates,
doctor/start actions, health labels, health summary field ordering, and pure
daemon path derivation from snapshot paths plus transition-state builders for
supervisor start, worker start, heartbeat, tick start/finish, stop, and worker
reload. Root code may supply storage defaults, perform PID checks, process
spawning, launchd interaction, runtime file IO, PID-file IO, stop/restart flag
cleanup, and stale-process cleanup, but future plans should not add root-local
copies of daemon runtime status vocabulary, canonical file naming, transition
semantics, or health interpretation.

Cookbook policy lives in the dedicated
[cookbook](/Users/kq/Workspace/moontown/src/cookbook) package. It owns Cookbook
DTOs, artifact summary accounting, required-missing drift semantics, and
operator-facing Cookbook status Markdown. Root code may keep the async
bootstrap/status command facade, construct observed artifact records from the
filesystem, register the MoonBook catalog entry, and write generated pages, but
future plans should not add root-local copies of docs/definition/runtime-state
counting or status wording.

Book-template request DTOs and lifecycle semantics live in the dedicated
[book_templates](/Users/kq/Workspace/moontown/src/book_templates) package.
PlanBook should treat template installation as another policy-loop support
system: package-owned contracts describe registry descriptors, requests,
registry-file manifests, events, ledgers, registry readiness/output rendering,
descriptor filesystem check-path policy, descriptor lookup semantics, status
counts, retry-as-pending runtime accounting, status vocabulary/predicates,
installer availability failure
wording, install-success marker/classification, request-status construction/
readiness/summary wording, empty request-status shape, request inbox Markdown
rendering, request-event identity/DTO construction, request-event summary
wording, and process-summary wording; request-event JSONL text normalization/
append format, line parsing, latest-event fallback, and unique request-id
extraction are package-owned too.
Post-install request-state transitions and terminal-event reconcile gates are
also package-owned. Per-request process-result records and processed/
reconciled outcome aggregation are package-owned; root may execute each
request and pass those result records back to `book_templates`.
Canonical registry, request inbox, and request-event filenames are also
package-owned; root may pass the current snapshot path into the package path
deriver. Root should not reintroduce local default path wrappers for
book-template registry, request inbox, or request-event paths; PlanBook repair
work should call `@book_templates` path helpers directly.
Root adapters may perform filesystem IO and call template-specific installers.
Do not recreate registry readiness pages,
descriptor path expansion, descriptor lookup, installer failure messages,
request status buckets, raw status decisions, prose-based success matching,
request inbox rendering, request event identities, request event DTOs, request
event summaries, event-log text append/normalization, event-line parsing,
latest-event fallback, request-id extraction, process-result booleans, updated
ledger aggregation, processed/reconciled counters, empty request-status fields,
canonical inbox/event-log filenames, or operator summary language in
root code. Do not construct post-install request records or terminal event
backfill gates in root code.
App ToolBook contracts live in the dedicated
[app_tool_book](/Users/kq/Workspace/moontown/src/app_tool_book) package. It owns
the stable template root, default book identity, default purpose, install/status
DTOs, required workspace path set, template-copy path set, config/manifest
schemas, catalog-identity-aware config construction, catalog identity,
generated history/site/tool page shape, status Markdown, standing-goal
construction/list policy, and readiness gate. Runtime App ToolBook work lives in
[app_tool_book_runtime](/Users/kq/Workspace/moontown/src/app_tool_book_runtime):
config JSON loading, config-relative path resolution, template copying,
MoonBook catalog mutation, workspace writes, standing-goal persistence, and
filesystem/catalog/goal status observation. Root code and template installers
should call the runtime package. Future plans should not add new root-local
ToolBook path lists, catalog tags or skills, generated-page renderers, status
renderers, bootstrap/install summary wording, ToolBook standing-goal semantics,
config/manifest schemas, default identity wrappers, readiness rules, or
ToolBook file/catalog IO in `app_tool_book/`.
Generic standing-watch policy lives in
[standing_watch_policy](/Users/kq/Workspace/moontown/src/standing_watch_policy).
Adapter-safe standing-watch worker contracts live in
[standing_watch_contracts](/Users/kq/Workspace/moontown/src/standing_watch_contracts).
`standing_watch_contracts` owns skill path sets, context page sets, and
output-contract lines. `standing_watch_policy` owns the standing-watch task
kind, id format, compact id segment policy, target pages, prompt text, strict
accounting marker vocabulary, marker parser, MoonBook history block parser,
provider-decision collapse policy, material-delta metrics, execution-summary
classification, effective watcher-record decision selection, watcher-record
preference ordering, and repair-mode appendix composition. `town_runtime` may
construct the concrete MoonBook `BookTask` from these policy values, schedule
standing goals, launch MoonClaw/MoonBook work, persist town snapshots, read and
write book history files, and append watcher ledgers. Future plans should not
add root-local or adapter-local standing-watch context tables, output-contract
tables, prompt copies, id-format helpers, marker vocabulary forks, history
parser clones, material-delta accounting clones, no-change/update/deferred/review
inference, or terminal-record selection.
Reusable transient external dependency classification lives in
[runtime_error_policy](/Users/kq/Workspace/moontown/src/runtime_error_policy).
Future plans should route provider infrastructure, temporary resource, storage
abort, and `{bad request}` classification through that package instead of
copying string predicates into root recovery, standing-watch, or PlanBook code.
External review packet request text, notes, tags, and metadata are
package-owned too; root may materialize MoonClaw profile/config files, resolve
paths, and instantiate external packets, but should not define the reviewer
persona, job shape, or semantic packet contract. Active review lifecycle
policy also belongs there; root may observe result-file/process state, but
`book_quality/` decides how those observations combine with statuses and stale
windows. Book-quality repair standing-goal semantics also belong there: repair
goal id, cadence, source policy, base prompt language, `StandingGoal`
construction, existing-goal refresh/upsert behavior, repair-goal id filtering,
disabled-state transition, standing-watch repair-mode appendix, and generic
empty repair-output classification are package-owned policy. Root may persist
the registry, append the package-provided mode text to the watcher prompt, and
combine package classifiers with execution state, but it should not define the
repair loop's intent, recurrence, standing-goal shape, id filtering, disable
transition, or generic-completion accounting.
Review dispatch status messages also belong there; root may observe active runs
and pending candidates, but it should not define the operator-facing
semantic-review message contract.
Review status section and table rendering also belong there; root may observe
whether result files exist and pass display rows into the package, but headings,
historical-attempt explanation, table headers, and row formatting are
book-quality presentation policy.
Stale-run reconciliation vocabulary also belongs there; root may check process
liveness and poll MoonClaw for a summary, but the transition to `orphaned`,
retry-facing summary text, and timestamped review-run record are book-quality
domain policy.
Accepted-result reconciliation records also belong there; root may harvest
MoonClaw content and write accepted result files, but the transition to
`written`, harvested summary text, written-count flag, and changed flag are
book-quality domain policy. Ledger-level reconciliation aggregation also
belongs there: root may supply per-run reconcile results, but order
preservation, written-count accumulation, and changed-state folding are
book-quality accounting rules.
Repair-goal retirement policy also belongs there; root may observe standing
goal state, result files, repairable book ids, and parsed semantic scores, but
`book_quality/` owns score-table existence checks, the decision vocabulary, and
the "should retire" rule. Repair
bridge summary wording also belongs there; root may apply candidates and
persist ledgers, but it should not define what queued/refreshed/retired means
to the operator. The repair review page Markdown also belongs there; root may
write `wiki/reviews/book-quality-repair.md`, but the sections, accounting rule,
and embedded review-contract presentation are book-quality contracts. Repair
bridge item construction also belongs there; root may pass observed score,
result, and clock inputs, but `book_quality/` owns the durable item schema
mapping from AI review fields and the decision that weak review text should
become a repair candidate. Repair-goal identity also belongs there:
`book_quality/` owns the repair-goal prefix, id construction, and id
recognition predicate. Root code may iterate standing goals, but should call the
package predicate instead of matching literal prefixes.
Operational book bootstrap templates also belong there. The index, contract,
review policy, journey page, operational-keeper skill, `moonbook-ui-state.json`,
and generated-site shell are book-quality package templates. Root may derive
title/summary/focus fields from the catalog and write the files, but it should
not own the wording, UI-state schema, or generated-site HTML for operational
books.

The core loop is:

```text
read BookPolicy -> run execute-lane skills -> record artifacts
                -> run tend-lane review -> update health/projection
```

A `BookPolicy` contains:

- `skills`: the execute/tend skill set the book runs
- `required_files`: the durable files that prove the workspace exists
- `quality_criteria`: what good means for this book
- `output`: the contract and projection surface the book owns

Research, course, PlanBook, Cookbook, civic-support, and operational books are
policy presets, not permanent runtime categories. Generated web tools, PDF
watches, standing watches, and civic routes are capabilities attached to those
policies. Future autonomous implementation should prefer composing policies
over adding more `if book_type` branches.

Use capability composition for features that can attach to more than one book
shape:

- PDF evidence watch: `with_pdf_watch(base_policy)`
- generated web tool: `with_web_tool_surface(base_policy, ...)`
- recurring watch: `with_standing_watch(base_policy)`

Do not create a new hardcoded category when a policy capability is enough.

Every implementation plan should say which policy it changes or creates. If
the work cannot name a policy, it is probably still a loose task rather than a
stable product capability.

When a plan invokes book-quality repair or semantic review, the generated packet
must include the composed `BookPolicy`. The reviewer should judge the book
against execute-lane skills, tend-lane skills, required files, quality criteria,
and output contract, not merely against a label such as `research-book`.

## Operating Architecture To Preserve

Every PlanBook plan, repair, and review must preserve this architecture:

```text
Mayor routes and supervises
  -> building protocol or target MoonBook hydrates durable context
  -> MoonClaw worker executes one bounded packet
  -> MoonBook bookkeeper reviews and persists memory/projection changes
  -> Moontown records health, visual state, and next action
```

Do not blur these roles:

- A civic building is a protocol place for exchange and reduction, not a
  generic persistent agent.
- A MoonBook is the durable book/workspace and memory surface.
- A MoonBook bookkeeper is the resident role that wakes to maintain that book.
- A MoonClaw worker is a temporary executor.
- A PlanBook is the durable implementation-control book.
- The Cookbook is the accepted stable-state book.

Plans must say how output returns home. For research, this means source/wiki/
synthesis/review pages. For course work, this means lessons, exercises, and
checkpoints. For a generated-tool capability, this means accepted data,
analysis reports, app source, tool manifest, generated web tool, review queue,
and civic building route. For civic work, this means
inbox/contribution/reduction/outbox/review/return-home ledgers. For
implementation work, this means code changes, tests, validation evidence,
commit readiness, and cookbook impact when stable definitions change.

## Book Types

| Book type | Primary question | Durable output | Main owner |
| --- | --- | --- | --- |
| Research book | What is true, new, or uncertain? | sources, evidence, synthesis, reports | MoonBook |
| Course book | How should someone learn this? | lessons, exercises, checkpoints | MoonBook |
| Planbook | What should be built and how will we know it worked? | `plan.md`, acceptance criteria, execution log, review notes | MoonBook + Mayor |
| Cookbook | What is the stable state of the town? | canonical docs, definitions, runtime index | MoonBook |

The cookbook is the stable control book. A planbook is a working decision book.
Plans may update the cookbook after they are accepted.

Generated tools are modeled as policy capabilities, not a row in this table.
For example, a general book with `with_web_tool_surface(...)` and a
standing-watch capability can become an App ToolBook without introducing a new
runtime category.

## Generated Tool Capability Roadmap

An App ToolBook is a MoonBook whose durable output includes an interactive web
tool, not only markdown pages. It is a reusable capability package over a
composed BookPolicy, not a separate runtime type. The book still follows
document protocol philosophy: the source of truth is files in the book, and
active agents are temporary workers that update those files through protocols.

Canonical flow:

```text
Moondesk writes an App ToolBook config/request document
  -> Moontown daemon processes the book-template request
  -> MoonBook workspace is created with report, app, manifest, and review files
  -> Moontown registers a standing goal for the book
  -> MoonClaw watches sources, analyzes data, updates app source, validates tool
  -> MoonBook bookkeeper accepts or reviews data/tool changes
  -> Moontown civic building links to the live generated tool and latest report
```

Required durable files:

- `book.json`
- `tool-manifest.json`
- `raw/data/latest.json`
- `wiki/methods/analysis-method.md`
- `wiki/tools/tool-spec.md`
- `wiki/reports/latest-analysis.md`
- `wiki/reviews/tool-review.md`
- `app/index.html`
- `book/site/generated/tool.html`

The template is `app-tool-book` in `assets/templates/books/app-tool-book/`. It is
installed through the same request inbox as other book templates, so a Mayor,
Moondesk, or future planning agent can create one without Codex manually
copying files:

```text
.moontown/book-template-requests.json
  request.template_id = "app-tool-book"
  request.config_path = "<config>.json"
```

PlanBook acceptance rule: if a plan asks for a book-backed usable tool, it must
create or update an App ToolBook request rather than hardcoding a one-off page
inside Moontown. Moontown presents the building and route; MoonBook owns the
tool source and generated page; MoonClaw performs bounded watch/analyze/build
work; Moondesk edits the method/spec and approves durable changes.

## Mayor, Bookkeeper, And Worker Roles

PlanBook must distinguish three kinds of active AI role:

- `Mayor`
  is the town-level supervisor. It is logically long-lived through the daemon
  and owns standing goals, routing, scheduling, escalation, recovery,
  cross-book priority, and civic/building protocol dispatch.
- `MoonBook Bookkeeper`
  is a resident role for one book. It is logically live through scheduled or
  event-driven keeper ticks, not necessarily a continuously burning process. It
  wakes when results arrive, reviews change, projections age, or the operator
  asks the book to act. It owns working memory, durable wiki promotion,
  evidence/source ledgers, review policy, book health, next questions, and
  generated site quality.
- `MoonClaw Worker`
  is a freelance bounded executor. It spawns for one packet, uses tools,
  produces observations/results/artifacts/memory candidates, and exits. It does
  not own durable memory or town policy.

Future plans must say which role is responsible. If a task is about durable
book memory, route it to the bookkeeper. If a task is tool-heavy execution,
spawn a worker. If a task is cross-book priority or cadence, keep it in the
Mayor.

For civic work, PlanBook must also preserve the protocol boundary: the reusable
communication-pattern taxonomy lives in the `civic/` package, while root
Moontown only adapts those patterns into scenario files, ledgers, runtime
packets, CLI output, and UI projection. A future plan that adds a civic
building should compose or add a `civic/` pattern/service definition first,
then bind it through configuration; it should not encode a new building's
social logic directly in the daemon or viewport.

The same rule applies to scenario data. `CivicCommunicationScenario`,
`CivicCommunicationIdea`, `CivicCommunicationMetric`, participant records, home-return records,
and reduction-mode vocabulary are civic protocol DTOs. Root code may keep thin
facade aliases for compatibility, but new durable data fields should be added
inside `civic/` first.

Scenario policy is civic-owned too. Pattern id fallback, pattern-label
fallback, generic building-protocol derivation, and reusable building/metric/
return-home notes belong in `civic/communication_scenario_policy.mbt`. Root runtime
files may materialize scenario pages and packets, but they should call the
package policy instead of reconstructing protocol contracts.

Civic skill contracts are civic-owned too. Generic Wenyu civic service skills,
module-specific skills, communication-pattern participant skills, and
communication-pattern reducer skill/input/contract text belong in
`civic/skill_text.mbt`. Public helper names should use generic
communication-pattern vocabulary; `research-salon` is one configured pattern,
not the reusable API. Root may write generated `SKILL.md` and reducer contract
files to workspaces, but future plans should not add root-local skill text
helpers for civic service behavior.

Adapter-safe Wenyu worker contracts live in
[civic_contracts](/Users/kq/Workspace/moontown/src/civic_contracts). Future
plans that change Wenyu build/civic worker skill paths, context pages,
bootstrap artifact paths, or civic service output contracts must update that
package first. `adapters/moonbook` may detect civic context and append those
contracts to a worker bundle, but it must not become the owner of Wenyu
skill/context/output tables.

Adapter-safe course worker contracts live in
[course_contracts](/Users/kq/Workspace/moontown/src/course_contracts). Future
plans that change beginner-course skill paths, context pages, required course
artifacts, course prompt wording, course policy/routine lines, or course output
contracts must update that package first. `adapters/moonbook` may detect course
context and pass display/request context into those helpers, but it must not
own course skill/context/prompt/output tables.

Civic workspace seed text is civic-owned too. Workspace index pages, service
contracts, building protocol contracts, schema pages, wiki seed pages, review
queue pages, service ledgers, exchange ledgers, and service history pages
belong in `civic/workspace_text.mbt`. Root may choose paths, create
directories, and write the generated files, but future plans should not add
root-local page or ledger template helpers for civic service behavior.

Metric semantics are also civic-owned. If a plan changes how a building
measures exchange yield, returned-home coverage, or structural effectiveness,
the implementation belongs in `civic/communication_metrics.mbt`; root may only
display or persist those metrics.

Schedule vocabulary is civic-owned too. `CivicCommunicationSchedule`,
`CivicCommunicationRoundRecord`, due checks, round ids, completion cadence, and round
record construction belong in `civic/`. Root owns wall-clock IO, schedule files,
daemon claiming/retry policy, and append-only persistence.

Civic status vocabulary is civic-owned as well. Service buckets, protocol
readiness, result-proven checks, and operator-facing health-note wording belong
in `civic/status_labels.mbt`. Root may inspect files and render portfolio
status, but it should call the civic package for all status-string semantics so
UI, daemon, and review gates cannot drift.

Civic reconciliation policy is also civic-owned. When a building protocol round
is converted into a MoonBook service result, `civic/service_reconcile_policy.mbt`
owns the decision vocabulary, page-count rule, review-count rule,
`next_check_hint`, reconcilable-work gate, current-result check, contract block,
and narrative wording. Root may observe `CivicServiceHealth`, build a MoonBook
`BookResult`, and call MoonBook persistence, but it should not define a
separate result-contract grammar or duplicate reconciliation predicates for
civic service reconciliation.

Building-protocol status portfolio rules are civic-owned too. Ready, active,
review, and blocked predicates, portfolio count aggregation, and compact
Markdown row formatting belong in `civic/protocol_portfolio.mbt`. Root may
inspect JSONL ledgers and write status Markdown files, but it should not own a
second definition of protocol health buckets.

Building-protocol contract text is civic-owned too. The reusable Markdown for a
building protocol contract belongs in `civic/protocol_contract_text.mbt`. Root
may write that text into protocol ledger directories, but future plans should
not add root-local building protocol contract renderers.

Building-protocol snapshot construction is civic-owned too. Root may observe
ledger counts and latest summaries; `civic/protocol_snapshot.mbt` owns how those
observations become `BuildingProtocolSnapshot`, including status labels and
readiness. Plans should not build protocol snapshots manually in runtime code.

## Stable Watch State

A mature town is not always busy. The desired stable state is:

- daemon healthy
- active workers `0`
- stable waiting reported as `true` in the live autonomy spine
- stable waiting observation streak increasing across consecutive quiet daemon
  observations
- unresolved failures `0`
- PlanBook open gaps `0`
- due standing goals `0`
- MoonBook quality audit includes every live runtime book from the saved town
  snapshot, not only the curated catalog
- review queues visible but not counted as accepted progress
- transient infrastructure failures cleared or deferred without becoming
  durable domain evidence or review debt
- detached MoonClaw startup logs do not count as terminal watcher failure when
  a receipt/run is still pending or has already been confirmed
- scheduler-only deferrals do not count as watcher decisions. If the Mayor
  defers a due standing goal because the per-tick dispatch budget or live
  external-execution cap is full, the goal must remain due until an actual
  watcher cycle writes a durable watcher ledger record.
- transient infrastructure debt visible as its own live-spine metric, separate
  from unresolved failures and no-change cycles
- civic protocol schedules enabled for the next real-world interval
- civic service reconciliation current for protocol-active buildings; review
  gated exchanges should appear as `needs_review`, not accepted facts

Visible review queues do not block the live loop by themselves. They mean the
town has review-gated artifacts waiting for a bookkeeper, operator, or later
AI-review pass. The Mayor should keep watching and dispatching scheduled work
while keeping those queues visible.

For overnight or long-horizon checks, do not infer stability only from the
latest status text. The authoritative evidence is the live autonomy spine:

- `stable_waiting`
- `stable_waiting_observation_streak`
- `stable_waiting_blockers`
- `town-journal.jsonl`

`stable_waiting_blockers` must be empty before the town can claim it is waiting
cleanly. The streak proves that the condition survived repeated daemon
observations rather than one lucky tick.

Weak live books are not allowed to disappear just because they were created by
standing watches rather than hand-registered in the MoonBook catalog. The
book-quality audit merges the saved runtime snapshot into the catalog view, so
research books such as OPC, LLM training, robotics, agents, and hardware are
judged by the same structural and semantic review loop as canonical books.

## Lifecycle

```text
idea / bug / operator voice note / town anomaly
  -> Mayor creates or updates a planbook goal
  -> Planbook gathers codebase, docs, history, and optional web/community context
  -> Planbook writes plans/<date>-<slug>/plan.md
  -> MoonClaw executes against that plan
  -> MoonClaw marks acceptance criteria and writes execution evidence
  -> MoonBook reviews and persists the result
  -> Cookbook is updated only when the stable state changed
```

## Planbook Workspace Layout

```text
.moontown/books/plan-<area>/
  raw/
    inbox/
      <timestamp>-operator-note.md
      <timestamp>-bug-report.md
      <timestamp>-screenshot-note.md
    context/
      codebase-map.md
      recent-decisions.md
      external-research.md
  plans/
    2026-05-29-wenyu-planbook/
      plan.md
      acceptance.md
      execution-log.md
      review.md
      handoff.md
  wiki/
    index.md
    planning/decision-records.md
    planning/open-questions.md
    planning/role-model.md
    planning/quality-gates.md
    history/journey.md
  skills/
    code-plan/SKILL.md
    code-review/SKILL.md
    doc-sync/SKILL.md
.moontown/
  planbook/
    autonomy.json
    autonomy.md
    latest-validation.md
```

MoonBook also seeds a native `planbook` skill for new workspaces at
`skills/planbook/SKILL.md`. When the MoonClaw extension is enabled, MoonBook
exposes dedicated `wiki_planbook_controller` and `wiki_planbook_worker`
profiles. Those profiles use the PlanBook skill and explicitly avoid injecting
research-report or course structure into implementation plans.

The planbook should not store long-term domain research unless that research is
needed for a plan. Domain facts still belong in research books. Beginner
teaching still belongs in course books.

## `plan.md` Contract

Every non-trivial plan should include:

- Problem statement
- Current state, with links to files or docs
- Goal and non-goals
- Document Protocol Fit
- Design decision
- Alternatives considered
- Affected files
- Implementation steps
- Acceptance criteria with checkboxes
- Test and validation commands
- Rollback or recovery path
- Follow-up tasks

Use [assets/templates/planbook/PLAN_TEMPLATE.md](/Users/kq/Workspace/moontown/assets/templates/planbook/PLAN_TEMPLATE.md)
as the default shape.

## Plan Quality Rules

A plan is not ready for execution if:

- it does not name the problem
- it does not identify the durable document/book source of truth
- it treats an agent run as the source of truth instead of a protocol over
  documents
- it does not mention affected files or packages
- it hides unresolved decisions
- it has no acceptance criteria
- it has no validation command
- it changes ownership boundaries between Moontown, MoonBook, MoonClaw, and
  Moondesk without saying so
- it reads like generic advice instead of this repository's situation

## Execution Rules

MoonClaw execution should:

- read the plan first
- update `execution-log.md` as work progresses
- mark acceptance criteria only after validation
- write blockers into `review.md`
- avoid creating `v1`, `v2`, `v3` replacement plans unless the old plan is
  superseded by a clear decision record

The planbook is allowed to evolve a plan in place, but it must preserve a
decision trail.

## Implementation Backlog And Change Log

The live town must have planned work to choose from. That source of future work
is a MoonBook-managed PlanBook document, not a hardcoded MoonBit list:

- `raw/backlog/implementation-backlog.json`
  is the editable backlog. Operators or future MoonBook tools can add, remove,
  reprioritize, pause, or close implementation goals by changing this JSON.
- `wiki/planning/implementation-backlog.md`
  is the generated human-readable projection of that backlog.
- `wiki/planning/backlog-progress.md`
  shows open/completed/blocked counts and the next code-building check cadence.
- `wiki/planning/stop-policy.md`
  defines when a worker should stop instead of generating more code.
- `wiki/history/change-log.md`
  records live PlanBook autonomy and repair events over time.
- `raw/backlog/completed/<id>.md`
  is the completion evidence for an accepted backlog item.

The daemon chooses the highest-priority open backlog item only when no stricter
self-build criterion is already open. This keeps the town active without letting
it invent unbounded work.

Stop conditions are explicit:

- Stop when completion evidence exists for the selected item.
- Stop when the item is `done`, `blocked`, or `paused`.
- Stop when the worker discovers the requested feature is already complete; it
  should update progress/backlog evidence, not create code churn.
- Stop when validation fails or the focused diff would cross ownership
  boundaries.
- Stop and update the plan/backlog first when the plan is stale.

Cadence is also explicit. While open backlog work exists, the town can take the
next bounded task immediately, one at a time. Once the backlog is clear, the
code-building visit decays to a 30-minute check interval.

## Overnight Monitoring Expectations

When the daemon is left running, the next morning review should be able to
answer these questions from durable artifacts rather than chat memory:

- Did the daemon remain healthy, with success count increasing and failure
  count stable?
- Did standing-watch books gain accepted facts, review items, questions, or
  explicit no-change decisions?
- Did civic building protocols add round records and return-home outputs?
- Did PlanBook either close a gap, dispatch a bounded repair, or record a clear
  blocker/no-change decision?
- Did code/test state change only when a PlanBook repair had validation
  evidence and commit readiness?
- Did UI projections read the live state rather than static demo content?

If the answer is no, the correct repair is usually a wiring fix: connect the
existing daemon, schedule, building protocol, MoonBook bookkeeper, MoonClaw
worker, PlanBook evidence, and UI projection surfaces. Do not add a second
hardcoded workflow that bypasses those documents.

## Self-Build And Self-Healing Loop

The current Moontown runtime now has a PlanBook autonomy doctor. It is not a
replacement for MoonBook-native planning, but it is the first live spine for
self-build governance:

```text
daemon tick / manual doctor
  -> inspect PlanBook criteria
  -> write .moontown/planbook/autonomy.json
  -> write .moontown/planbook/autonomy.md
  -> update PlanBook execution evidence and active review pages
  -> update PlanBook backlog projection, progress, stop policy, and live change log
  -> expose open gap count in .moontown/live-autonomy.json
  -> queue one bounded repair packet for the first open gap
  -> Mayor sees active repair work as live next action
```

The doctor checks concrete criteria such as:

- PlanBook workspace exists with plans, skills, and quality gates.
- Live autonomy spine exposes PlanBook open-gap count.
- Operator UI references live autonomy state.
- Standing-watch outputs have a strict result contract.
- AI semantic review results are persisted.
- The daemon has a bounded semantic-review cadence that dispatches at most one
  book-quality review at a time.
- Standing-goal cadence accounting only advances when a real watcher cycle is
  launched and recorded. Budget/cap deferrals remain due and are not allowed to
  make work disappear until the next cadence window.
- Weak semantic-review results are bridged into the owning MoonBook review
  queue and into a bounded standing repair goal, so Mayor supervision can mature
  books without treating failed/no-change review records as accepted evidence.
- PlanBook repair can route repository source patches through Codex ACP instead
  of only asking Codex-in-this-chat to edit files.
- PlanBook has an editable implementation backlog and live change history.
- Validation evidence is recorded.
- MoonBook has a native PlanBook skill and MoonClaw planbook profiles.

This keeps the town honest: open implementation gaps remain visible to the
Mayor and operator until they are implemented, validated, and recorded.
The latest accounting is stricter than earlier versions: ACP route wiring is not
the same as proven self-patching. A PlanBook source-repair criterion must remain
open until an accepted MoonClaw result includes
`planbook.repair.patch_receipt.v1` evidence from a Codex ACP run rooted at the
Moontown source tree. Text-only claims, read-only sandbox attempts,
`files_changed: none`, or review-only ACP runs are useful diagnostics, but they
do not prove that the town patched its own code.
When all criteria are satisfied, the live autonomy spine reports
`planbook_open=0` and stale repair packets no longer count as active work. If
the implementation backlog contains open items, `planbook_open` should remain
above zero and the daemon should dispatch one bounded repair at a time. When a
worker visits the code-building lane and finds the work already done, the correct
output is a plan/progress update plus completion evidence, not more code.

The repair bridge is intentionally bounded. It does not let the town run an
unconstrained generic agent loop. Instead, it writes:

- `.moontown/planbook/repair-task.json`
- `.moontown/planbook/repair-task.md`
- `raw/repair/PLANBOOK_REPAIR_CONTEXT.md`
- `skills/planbook-repair/SKILL.md`
- `plans/self-healing-repair/plan.md`
- `raw/repair/planbook-repair-*.packet.json`

Use the repair commands directly when inspecting or dispatching self-repair:

```bash
moon run src/cmd/main -- planbook repair
moon run src/cmd/main -- planbook repair status
moon run src/cmd/main -- planbook repair --dispatch
```

Without `--dispatch`, Moontown only queues the repair packet and records the
active repair. With `--dispatch`, the packet is imported into MoonClaw using the
PlanBook repair skill and the `planbook.repair.result.v1` output contract.
For Moontown-owned source repairs, the repair profile uses
`execution_mode: acp` and `execution_target: codex-main`; the configured ACP
target runs from the repository source root, not only the PlanBook workspace.
The target model is not a book policy decision. It is a Moontown ACP adapter
default, currently `gpt-5.5` unless `MOONTOWN_CODEX_ACP_MODEL` overrides it.
Daemon-created repair dispatches are detached; operator `--dispatch` may still
use inline execution when the environment explicitly enables it for debugging.
That is the intended self-patching path: Mayor/PlanBook choose and bound the
gap, MoonClaw launches Codex ACP as the code executor, Codex patches the repo,
and PlanBook reconciles the result contract after validation, diff inspection,
and commit readiness.

Editor-mode pipeline work follows the same package-owned policy rule. The
`editor_pipeline/` package owns the pipeline DTOs, feature-selection result
contract, selected-feature implementation contract, feature-rater skill text,
stage/status policy, selected-style lookup, selected-feature readiness gates,
module-placement DTO and record policy, canonical status Markdown renderer, and
style-catalog metadata. PlanBook may decide when to run feature selection,
which course/book evidence to include, and how to reconcile the selected
feature into a repair task. Root Moontown may inspect runtime state, create
files, compute evidence paths, load module JSON, convert config entries into
package DTOs, and dispatch workers, but future plans must not add a second
root-local editor record shape, stage readiness policy, status renderer, rubric,
selected-style policy, selected-feature readiness gates, module-placement
policy, terrain-labeling policy, or style catalog. Root should also avoid
compatibility wrappers over those package APIs; PlanBook/editor callers should
use `editor_pipeline/` directly.

For a source patch, accepted reconciliation also requires a
`planbook.repair.patch_receipt.v1` receipt. The receipt is the durable boundary
between “Codex ACP was configured” and “Codex ACP actually changed, validated,
and accounted for source code.” It must identify the criterion, source root,
execution mode/target, changed files, validation commands, diff hygiene, commit
status/message, and push status. PlanBook rejects accepted source-repair claims
that do not carry this evidence.
If the gap belongs in MoonBook or MoonClaw, the repair worker must return a
precise ownership blocker instead of moving that responsibility into Moontown.

This still must stay bounded. The town should not run an unconstrained generic
agent loop with arbitrary authority. A self-patch must name target files,
acceptance criteria, validation commands, and the durable PlanBook evidence it
will update. An accepted repair must also record the software-engineering
evidence expected from a human-quality code change: validation command results,
`git diff --check`, `git status --short`, a focused diff summary, commit
status/message, and push status. The default policy allows local commit
preparation after validation but does not push unless a future policy explicitly
enables it. For `backlog-*` criteria, the repair worker must also write
completion evidence under `raw/backlog/completed/<id>.md`.
If the repair changes source code that the live daemon depends on, the worker
must also request a clean reload after validation with
`moon run src/cmd/main -- daemon restart "validated source patch"` and then inspect
fresh live evidence. A packet produced by a pre-reload daemon does not prove the
new code path.

## Relation To Voice And Parallel Work

The desired operator workflow is:

```text
voice note / pasted bug / screenshot
  -> planbook inbox item
  -> plan.md
  -> work execution
  -> validation evidence
  -> accepted stable-state update
```

Multiple planbooks can run in parallel, but each plan should be isolated by
area. Good examples:

- `plan-moontown-core`
- `plan-wenyu-ui`
- `plan-civic-protocols`
- `plan-daemon-reliability`
- `plan-docs-and-cookbook`

Bad examples:

- one global mega-plan for all work
- a research book pretending to be a code plan
- a course book pretending to be an implementation tracker

## Where This Should Be Implemented

Moontown should implement:

- planbook registration and routing
- mayor decision to create, resume, or execute a plan
- daemon-visible plan status
- UI surfaces for active plans and acceptance status

MoonBook should implement:

- native `planbook` workspace template
- `code-plan` skill route
- plan projection pages
- review queue for plan acceptance and drift

MoonClaw should implement:

- role-specific plan writer, implementer, reviewer, and doc-sync skills
- output contracts for plan creation, execution evidence, and review findings

Moondesk should implement:

- human file-manager surface for browsing and editing planbooks
- voice-note capture into `raw/inbox/`
- plan diff/review UI

## Immediate Moontown Rule

Moontown now has a first-class bootstrap for the current planbook workspace:

```bash
moon run src/cmd/main -- planbook bootstrap
moon run src/cmd/main -- planbook status
moon run src/cmd/main -- planbook doctor
moon run src/cmd/main -- planbook autonomy
moon run src/cmd/main -- planbook repair
moon run src/cmd/main -- planbook repair status
```

Use this repository rule:

If a change is larger than a trivial one-line fix, write or update a plan under
`docs/plans/` or a planbook workspace before implementation. The plan should be
good enough for a new Codex/MoonClaw session to continue after context loss.

The remaining upgrade belongs mostly in MoonBook: add a native `planbook`
provider/profile so future plan creation, plan review, and plan repair run
through MoonBook skills instead of only through Moontown bootstrap. Until that
exists, Moontown's PlanBook doctor keeps the gap explicit in live runtime state.
