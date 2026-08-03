# MoonBook README Surface In Moontown

## Status

The requested maintained page `wiki/sources/moonbook-readme.md` did not exist in
this worktree, so this revision creates it as a durable source page. It is based
on the strongest README-adjacent evidence available here: `README.mbt.md`,
`docs/USAGE.md`, `docs/PACKAGES.md`, `docs/ARCHITECTURE.md`, and the MoonBook
adapter implementation in `adapters/moonbook/client.mbt`.

Because the direct upstream MoonBook README or approved bootstrap packets are not
present here, this page is intentionally scoped to what the Moontown repo claims
about MoonBook and what the adapter code currently exposes.

## What This Repo Says MoonBook Is

Across the maintained docs, MoonBook is consistently described as the per-domain
harness layer that sits between `moontown` and `moonclaw`.

High-confidence role statement from `docs/ARCHITECTURE.md`:

- workspace root and domain identity
- memory policy and durable memory
- context hydration
- local planning
- result review and persistence decisions

`README.mbt.md` reinforces the same split by saying:

- town orchestration lives in `moontown`
- harness and memory control live in `moonbook`
- execution-heavy behavior lives in `moonclaw`

## README-Level MoonBook Capabilities Reflected In This Repo

The nearest maintained README-like surface is `README.mbt.md`, which says the
current repo includes:

- a book-harness-shaped MoonBook adapter
- persisted moonbook catalog in `.moontown/moonbooks.json`
- external proposal packet and proposal/run receipt lifecycle
- strategic mayor routing over embedded MoonClaw runtime metadata

`docs/USAGE.md` sharpens that into current usage claims:

- real MoonBook CLI-backed planning and context hydration boundary
- persisted town bootstrap linked to the moonbook catalog
- real failure details when MoonBook rejects a handoff

`docs/PACKAGES.md` gives the strongest concrete adapter inventory:

- catalog read/write
- catalog-backed `BookProvider`
- workspace initialization through real `moonbook wiki init`
- MoonClaw extension seeding through real `moonbook wiki enable moonclaw`
- `accept_goal(...)`
- `produce_task_batch(...)`
- `hydrate_worker_context(...)`
- `persist_result(...)`
- `summarize_state(...)`
- `report_health(...)`

## Durable Data Surfaces

The strongest code-backed MoonBook durability surface in this repo is the catalog
file defined by `adapters/moonbook/client.mbt`:

- `default_catalog_path()` -> `.moontown/moonbooks.json`
- `load_or_create_catalog(...)`
- `save_catalog_file(...)`
- `load_catalog_file(...)`

`BookCatalogEntry` persists:

- `id`
- `name`
- `purpose`
- `workspace_root`
- `memory_scope`
- `tags`
- `skills`

The current default catalog contains at least two built-in books:

- `coding`
- `finance`

Caveat: this durable surface is Moontown's persisted view of MoonBook domains,
not evidence that all MoonBook-internal memory structures are represented in this
repo.

## Workspace And Memory Expectations

The repo's current MoonBook-facing adapter expects each book to have its own
workspace root and memory policy.

Implementation evidence in `adapters/moonbook/client.mbt`:

- `default_workspace_root(book_id)` -> `.moontown/books/{book_id}`
- catalog entries carry `memory_scope`

Architectural evidence in `docs/ARCHITECTURE.md`:

- domain-specific durable data belongs to `moonbook`
- workspace root, memory records, and domain summaries are MoonBook-owned

This is one of the strongest stable claims the current repo makes about MoonBook:
MoonBook is the durable per-domain memory/harness boundary, even when Moontown is
holding a bootstrap catalog for those domains.

## MoonBook In The Packet Lifecycle

The maintained docs consistently place MoonBook upstream of keeper packet
creation.

Representative flow from `docs/ARCHITECTURE.md`:

```text
moonbook catalog
  -> BookProvider
  -> book task batch
  -> worker context bundle
  -> external proposal packet
  -> proposal import receipt
```

`roles/mayor.mbt` confirms that mayor packet preparation calls
`@moonbook.hydrate_worker_context(entry, task)` before packet shaping.

That means the strongest code-backed claim is:

- MoonBook supplies the domain/task context bundle
- mayor shapes that into a keeper-facing packet
- MoonClaw imports the external packet

Caveat: `docs/ARCHITECTURE.md` explicitly says the actual keeper implementation
still belongs on the MoonBook side, so the current repo shows the handoff
boundary more directly than the full downstream keeper behavior.

## What Is Real vs Not Yet Fully Live

The docs make an important distinction that should be preserved.

Documented as real now:

- MoonBook CLI-backed planning
- context hydration
- summary and health surfaces
- workspace initialization and MoonClaw extension seeding
- persisted catalog-backed bootstrap

Documented as not yet fully live end to end:

- automatic result persistence back into external MoonBook after completed runs
- fully integrated long-running supervision loop
- some completion-ingestion behavior beyond initial handoff

This page keeps those caveats because the repo docs explicitly do so.

## Provenance

Primary evidence used for this revision:

- `README.mbt.md`
- `docs/ARCHITECTURE.md`
- `docs/USAGE.md`
- `docs/PACKAGES.md`
- `adapters/moonbook/client.mbt`
- `roles/mayor.mbt`

Missing during revision:

- upstream MoonBook README in this worktree
- `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md`
- `raw/bootstrap/docs-lane-bootstrap-packet-2026-04-17.md`
- `raw/bootstrap/implementation-lane-bootstrap-step_3.md`
- `raw/bootstrap/architecture-bootstrap-packet.md`

Future updates should merge in the raw packet trail or upstream MoonBook README
when available rather than replacing this page with a one-off summary.
