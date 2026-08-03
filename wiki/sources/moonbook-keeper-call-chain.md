# MoonBook Keeper Call Chain

## Status

This page reconstructs the current MoonBook-to-keeper call chain from repo docs
and implementation files because the referenced bootstrap packets and preexisting
wiki source pages are absent from this worktree. It keeps uncertainty explicit
where the repo models a boundary more strongly than it executes it end to end.

## High-Confidence Call Chain

The strongest current evidence supports this chain:

```text
moonbook catalog entry
  -> goal acceptance / task batch
  -> worker context hydration
  -> Mayor.prepare_keeper_packet(...)
  -> keeper-facing ExternalProposalPacket
  -> packet file under .moontown/packets/
  -> moonclaw proposal import --json
  -> ProposalImportReceipt
  -> TownState execution record
```

This chain is distributed across `adapters/moonbook/client.mbt`,
`roles/mayor.mbt`, `adapters/moonclaw/client.mbt`, `docs/USAGE.md`, and
`docs/ARCHITECTURE.md`.

## Source Surfaces In Order

### 1. MoonBook catalog selects the book surface

`adapters/moonbook/client.mbt` defines `BookCatalogEntry`,
`MoonbookCatalogProvider`, and `default_catalog()`.

Evidence:

- catalog entries carry `id`, `name`, `purpose`, `workspace_root`,
  `memory_scope`, `tags`, and `skills`
- `default_catalog_path()` points at `.moontown/moonbooks.json`
- `load_or_create_catalog(...)` persists a normalized catalog if missing

This is the durable town-side source for which book receives a keeper-targeted
handoff.

### 2. MoonBook accepts goals and shapes tasks

The strongest maintained description of this stage is in `docs/PACKAGES.md`,
which lists the MoonBook adapter's real pieces as:

- `accept_goal(...)`
- `produce_task_batch(...)`
- `hydrate_worker_context(...)`
- `persist_result(...)`
- `summarize_state(...)`
- `report_health(...)`

`docs/ARCHITECTURE.md` and `README.mbt.md` also describe the path from MoonBook
catalog to book task batch and worker context bundle.

Caveat: only part of this flow is visible in the lines reviewed from
`adapters/moonbook/client.mbt`; the docs are the strongest concise source for the
full adapter contract.

### 3. Worker context bundle is the keeper handoff payload source

`adapters/moonclaw/client.mbt` shows that
`proposal_packet_from_bundle(bundle, ...)` pulls the following into the external
packet:

- `bundle.prompt` -> `request_text`
- `bundle.context_pages` -> `context_pages`
- `bundle.skill_paths` -> `skill_paths`
- `bundle.output_contract` -> packet output contract
- metadata including `book_id`, `workspace_root`, `task_id`, and
  `memory_summary`

This is the clearest code-level evidence that the worker context bundle is the
bridge between MoonBook-side planning state and the keeper packet exported toward
MoonClaw.

### 4. Mayor shapes the keeper handoff and packet

`roles/mayor.mbt` is the strongest direct source for the mayor-to-keeper step.

`Mayor.prepare_keeper_packet(...)`:

- calls `@moonbook.hydrate_worker_context(entry, task)`
- derives `packet_id` as `keeper-{entry.id}-{task.id}`
- selects a MoonClaw profile from task kind
- calls `@moonclaw.proposal_packet_from_bundle(...)`
- emits a `MayorKeeperPacket` containing:
  - `handoff`
  - `packet`
  - `packet_path`
  - `rationale`

The same file shows `Mayor.handoff_to_keeper(...)` delegating to
`@moonclaw.mayor_to_keeper_handoff(...)` with book id, objective, scope summary,
and constraints.

### 5. Handoff semantics are strategic-to-domain

`adapters/moonclaw/client.mbt` defines `EmbeddedHandoffKind`, including
`StrategicToDomain`, and `EmbeddedRuntimeHandoff` with:

- `objective`
- `scope_summary`
- `constraints`
- `output_contract`
- `target_role_id`

This is the strongest implementation evidence that the keeper call chain is
modeled as a strategic mayor handing off to a domain-scoped keeper, not as a raw
worker dispatch.

### 6. Packet file is durable provenance

`adapters/moonclaw/client.mbt` defines:

- `default_packet_directory()` -> `.moontown/packets`
- `packet_file_path(packet_dir, packet_id)` -> `{packet_dir}/{packet_id}.json`
- `save_packet_file(path, packet)`
- `load_packet_file(path)`

`docs/USAGE.md` also states that `.moontown/packets/` is used when packet files
are exported.

This packet file path is important provenance and should be preserved in the wiki
as evidence, not collapsed into a generic claim that a handoff occurred.

### 7. MoonClaw import is the external execution boundary

`adapters/moonclaw/client.mbt` defines:

- `build_import_command(...)`
- `import_packet(...)`

The import command is constructed as a real MoonClaw CLI invocation:

```text
moon -C {moonclaw_root} run cmd/main -- proposal import {packet_path} --json --cwd {cwd} --home {home}[ --confirm ]
```

`docs/PACKAGES.md` describes this as `import_packet(...)` via real
`moonclaw proposal import --json`.

This is the strongest evidence that the call chain crosses from town/book-side
preparation into MoonClaw proposal lifecycle management through a CLI boundary.

### 8. Receipt and lifecycle state feed town records

`adapters/moonclaw/client.mbt` defines `ProposalImportReceipt` with:

- `packet_id`
- `packet_path`
- `proposal_id`
- `run_id`
- `status`
- `command`
- `summary`

`docs/USAGE.md` says the town model tracks:

- keeper packet id
- packet path
- proposal id
- run id
- execution status

and places those records in `TownState.executions` / `TaskExecutionRecord`.

This is the best current evidence for the post-import half of the keeper call
chain.

## Profile Selection Evidence

`roles/mayor.mbt` maps task kind to MoonClaw profile:

- `ingest` and `ingest-followup` -> `wiki_ingest_controller`
- `review` and `planning` -> `wiki_lint_controller`
- `analysis` and `synthesis` -> `wiki_query_controller`
- fallback -> `wiki_query_controller`

That mapping is important because it shows the keeper chain is not just generic
packet export; the mayor selects role/profile metadata based on task shape.

## Caveats

- The repo clearly models keeper handoff, but the actual keeper implementation is
  still described in `docs/ARCHITECTURE.md` as belonging on the `moonbook` side.
- `docs/ARCHITECTURE.md` still lists long-running run-status polling and result
  persistence back into MoonBook as stubbed at the system level.
- Because raw bootstrap packets are missing from this worktree, this page does
  not assert any packet contents beyond what code and maintained docs show.

## Provenance

Primary evidence used for this revision:

- `roles/mayor.mbt`
- `adapters/moonclaw/client.mbt`
- `adapters/moonbook/client.mbt`
- `docs/ARCHITECTURE.md`
- `docs/PACKAGES.md`
- `docs/USAGE.md`
- `README.mbt.md`

Missing packet-level sources during revision:

- `raw/bootstrap/moontown-moonbook-moonclaw-bootstrap-2026-04-17.md`
- `raw/bootstrap/docs-lane-bootstrap-packet-2026-04-17.md`
- `raw/bootstrap/implementation-lane-bootstrap-step_3.md`
- `raw/bootstrap/architecture-bootstrap-packet.md`
