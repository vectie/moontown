# MoonTown documentation

- [Responsibility and testability](RESPONSIBILITY_AND_TESTABILITY.md)

- [Product contract](PRODUCT_CONTRACT.md) — current maturity, runtime
  boundaries and release gates.
- [Architecture](ARCHITECTURE.md) — product and package ownership.
- [MoonFlow civic adapter](MOONFLOW_CIVIC_ADAPTER.md) — versioned operation,
  schemas, health, evidence, reconciliation and acceptance boundary.
- [Usage](USAGE.md) and [cookbook](COOKBOOK.md) — operator/developer paths.
- [System settings](SYSTEM_SETTINGS.md) — the grouped, validated operational
  configuration registry and administrator workflow.
- [Wenyu status](WENYU_TOWN_STATUS.md) — dated integration status.
- [Final integration](FINAL_INTEGRATION.md) — cross-product objectives.
- [UI-to-UI use cases](qualification/UI_TO_UI_USE_CASES.md) — reproducible
  Energy Valley and typed research-handoff qualification, including
  fail-closed links and restart recovery.
- [`project/README.md`](project/README.md) — project identity, memory and
  release notes.

- [Join table places to separate zones](TABLE_ZONE_JOIN.md): offline CSV/TSV and
  GeoJSON input, source-linked memberships, unmatched places and overlap exports.

- [Compare human effort for saved goals](GOAL_EFFORT_REPORT.md): import measured
  manual/Town period pairs, retain missing data, and export goal-linked totals.

## Source-backed cross-book claim comparison

Import explicit claim CSV/TSV and local source quotes into a readable Markdown or JSON comparison brief with `src/cmd/claim_compare`. [Workflow, example and limits](CLAIM_COMPARISON.md).

- [Explore and compare goal schedules](GOAL_OUTLOOK.md): preview a tick horizon, edit a goal-table candidate and compare exact per-goal occurrences and shared ticks.

- [Recover local mini-app archived buildings](MINIAPP_ARCHIVE_RECOVERY.md): inspect
  retained records and restore the same building privately in the Node fixture
  service. Separate from the native product adapter and canonical town ledgers.

- [Export mini-app building review packets](MINIAPP_REVIEW_PACKETS.md): inspect one editable live or archived building, download source-bound JSON/Markdown, and reopen its retained conversation/run context offline in the local Node service.

- [Explore retained run review backlog](MINIAPP_RUN_INBOX.md): the existing town snapshot includes an oldest-update-first waiting-review/failed inbox, source-bound continuation and exact run/thread/audit inspection in the local Node service.
