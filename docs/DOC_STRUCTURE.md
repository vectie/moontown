# Moontown Documentation Structure

This repository has outgrown a single README. The docs should be organized by
operational purpose, not by the order features were added.

## Top-Level Reading Order

1. [README.md](/Users/kq/Workspace/moontown/README.md)
   - product overview, current status, and command entry points
2. [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md)
   - system boundaries, data flow, packages, daemon, and ownership
3. [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
   - plan-first workflow for code/product changes
4. [docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
   - document/book-first system philosophy for buildings, agents, protocols,
     and future self-build work
5. [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)
   - stable-state control book and drift checks
6. [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md)
   - local development commands and validation rules
7. [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md)
   - operator UI and Rabbita viewport guidance
8. [docs/WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md)
   - Wenyu product specification

## Doc Families

### Core System

- [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md)
- [docs/PACKAGES.md](/Users/kq/Workspace/moontown/docs/PACKAGES.md)
- [docs/USAGE.md](/Users/kq/Workspace/moontown/docs/USAGE.md)
- [docs/DEVELOPMENT.md](/Users/kq/Workspace/moontown/docs/DEVELOPMENT.md)

### Operating Memory

- [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md)
- [docs/PLANBOOK.md](/Users/kq/Workspace/moontown/docs/PLANBOOK.md)
- [docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
- [docs/REFACTOR_PLAN.md](/Users/kq/Workspace/moontown/docs/REFACTOR_PLAN.md)

### Wenyu Valley Product

- [docs/WENYU_VALLEY_PRD.md](/Users/kq/Workspace/moontown/docs/WENYU_VALLEY_PRD.md)
- [docs/WENYU_UI_MODULE_SYSTEM.md](/Users/kq/Workspace/moontown/docs/WENYU_UI_MODULE_SYSTEM.md)
- [docs/WENYU_BUILDING_PROTOCOL_PLAN.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_PROTOCOL_PLAN.md)
- [docs/WENYU_BUILDING_STYLE_SHEET.md](/Users/kq/Workspace/moontown/docs/WENYU_BUILDING_STYLE_SHEET.md)
- [docs/WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md)

### Civic Protocols

- [docs/CIVIC_COMMUNICATION_PATTERNS.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_PATTERNS.md)
- [docs/CIVIC_COMMUNICATION_TEMPLATES.md](/Users/kq/Workspace/moontown/docs/CIVIC_COMMUNICATION_TEMPLATES.md)
- [docs/FINAL_INTEGRATION.md](/Users/kq/Workspace/moontown/docs/FINAL_INTEGRATION.md)

### Tile Map And UI Production

- [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md)
- [docs/TILED_MAP_PIPELINE.md](/Users/kq/Workspace/moontown/docs/TILED_MAP_PIPELINE.md)

## Book Types And Doc Outputs

Book templates are discoverable through the registry at
[assets/templates/books/templates.json](/Users/kq/Workspace/moontown/assets/templates/books/templates.json).
Use:

```bash
moon run src/cmd/main -- books templates
moon run src/cmd/main -- books template install <template-id> <config.json>
moon run src/cmd/main -- books template requests process
```

Moondesk should use this registry as its book-creation palette. The Mayor can
also use it later when a task says “create a specialized book” and the system
needs to choose a reusable template rather than inventing a one-off workspace.
The file `.moonsuite/products/moontown/book-template-requests.json` is the
document-first inbox for that handoff: Moondesk or Mayor writes pending template
requests, and the daemon’s `book-template-request` scheduled job installs them.
The sibling
`.moonsuite/products/moontown/book-template-request-events.jsonl` file is the
append-only proof trail for those installs and failures.

| Book | Purpose | Typical docs generated or updated |
| --- | --- | --- |
| Research book | Discover and synthesize domain knowledge | research reports, evidence, source pages |
| Course book | Teach a beginner a workflow | lessons, exercises, checkpoints |
| Planbook | Drive code/product implementation | `plan.md`, acceptance criteria, execution log |
| Cookbook | Preserve stable town state | canonical docs index, definitions, drift report |
| Civic protocol support workspace | Persist accepted or reviewable outputs from one building protocol | schemas when needed, service ledgers, exchange ledgers, review queues, service history, projection-safe output |
| Operational book | Preserve private operating memory | review policy, journey log, keeper skill, projection-safe operating notes |

The docs should make this distinction visible. A research report should not be
used as a code plan. A course should not be used as a bug tracker. A planbook
should not become a permanent domain wiki. A civic building should not be
reduced to a book: the building is a protocol place, while MoonBook is the
optional durable support surface.

### Specialized Research Book Templates

Some domain books need a stricter evidence pipeline while still remaining
research books. The first reusable template is:

- [assets/templates/books/pdf-evidence-watch/](/Users/kq/Workspace/moontown/assets/templates/books/pdf-evidence-watch)

Use `pdf-evidence-watch` when a domain should repeatedly watch websites for
PDFs, download and extract full text, analyze with a book-owned method, and
notify only when accepted knowledge changes. This is not a new top-level book
family. It is a `research-book` plus template data, schemas, and dedicated
`SKILL.md` files.

Moondesk should be the human creation surface for this kind of book: edit
source websites, cadence, notification policy, and
`wiki/methods/analysis-method.md`; then export a portable MoonBook folder and a
standing-goal record for Moontown. The current Moontown CLI bridge is:

```bash
moon run src/cmd/main -- books pdf-watch bootstrap <book-id>
moon run src/cmd/main -- books pdf-watch install <config.json>
moon run src/cmd/main -- books pdf-watch status <book-id>
```

That bridge installs the template into `books/<book-id>/`, registers
the MoonBook catalog entry, and upserts a standing goal. Moondesk should wrap
this behavior with a file-manager-style wizard rather than duplicating the
template logic. The config-driven route is the preferred Moondesk contract
because it carries websites, cadence, workspace override, and
`analysis_method_path` without a Moontown code change.

## Document-First Rule

The stable interface of the town is documents and books, not agent runs.
Agent runs are temporary process-like workers. Buildings are protocol places
that exchange and reduce document packets. MoonBook owns durable book state.
Moontown schedules and projects protocols. MoonClaw executes bounded roles.
Moondesk should expose the durable document tree to humans.

Use
[docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md](/Users/kq/Workspace/moontown/docs/DOCUMENT_PROTOCOL_PHILOSOPHY.md)
as the canonical doctrine when deciding whether a new feature is a book, a
building protocol, a worker role, or a UI projection.

## Book Quality Checks

Moontown keeps book quality checks split into two responsibilities:

- `books doctor`
  runs deterministic structural checks and writes
  `.moonsuite/products/moontown/book-quality/audit.json` plus
  `.moonsuite/products/moontown/book-quality/audit.md`.
- `books ai-review-packets`
  writes review packets that an AI reviewer should judge with
  `BOOK_QUALITY_REVIEW_SKILL.md` and the book's own contract/skill files.

Structural checks are allowed to be hard-coded because they protect invariants:
workspace exists, contract exists, projection exists, and service books have
real service-loop output. They must be presented as readiness only. Actual
quality should not be hard-coded. Depth, insight, usefulness, originality,
correctness, and genre fit belong to the AI semantic review pass, with results
written to
`.moonsuite/products/moontown/book-quality/ai-review-results/<book-id>.md`.

Weak AI semantic reviews are actionable repair records, not accepted knowledge.
The daemon bridges them into `wiki/reviews/book-quality-repair.md` inside the
owning MoonBook workspace, records the bridge in
`.moonsuite/products/moontown/book-quality/repair-bridge.json`, and queues a
bounded standing repair goal. This keeps book growth live while preserving the
rule that operational review evidence is separate from domain/service evidence.

`books bootstrap` should stay genre-aware. It should repair canonical
registered book workspaces without turning course, civic, planbook, cookbook,
or operational books into research books.

## Update Rules

- If a command changes how the town is operated, update
  [docs/USAGE.md](/Users/kq/Workspace/moontown/docs/USAGE.md).
- If a package boundary changes, update
  [docs/ARCHITECTURE.md](/Users/kq/Workspace/moontown/docs/ARCHITECTURE.md)
  and [docs/PACKAGES.md](/Users/kq/Workspace/moontown/docs/PACKAGES.md).
- If a UI mode changes, update
  [docs/FRONTEND.md](/Users/kq/Workspace/moontown/docs/FRONTEND.md).
- If a Wenyu product feature changes, update
  [docs/WENYU_TOWN_STATUS.md](/Users/kq/Workspace/moontown/docs/WENYU_TOWN_STATUS.md)
  and the relevant Wenyu spec.
- If a stable definition changes, update
  [docs/COOKBOOK.md](/Users/kq/Workspace/moontown/docs/COOKBOOK.md) or the
  cookbook workspace.
- If a non-trivial implementation starts, create or update a planbook plan.

## Desired Future Automation

The Mayor should eventually route incoming work like this:

```text
research / watch / compare -> research book
teach / course / beginner -> course book
build / fix / refactor / implement -> planbook
stable definition / operating procedure -> cookbook
civic exchange / meeting / marketplace / service -> building protocol over books
```

This keeps Moontown from turning every task into research and keeps MoonBook
from mixing learning material, product strategy, and implementation control in
one generic wiki.
