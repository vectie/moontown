///|
fn wenyu_town_shell_service() -> CivicServiceDefinition {
  civic_service(
    id="town-shell",
    title="Town Shell",
    service_kind="town-supervision",
    module_mode="projection-surface",
    book_role="town-journal",
    skill_mode="mayor-supervision",
    purpose="Live valley map, mayor supervision, town projection, operator console, and 24x7 service visibility.",
    workflow=[
      "read the latest town snapshot and daemon status", "detect stalled modules, missing projections, and stale workers",
      "publish a projection-safe mayor digest with recovery actions",
    ],
    agent_work=[
      "diagnose stalled modules and stale workers", "write mayor recovery directives",
      "publish an operator-safe town digest",
    ],
    place_work=[
      "show whole-town state", "route operator commands", "link into module interiors",
    ],
    schema_pages=[
      "wiki/schemas/town-runtime.md", "wiki/schemas/module-registry.md",
    ],
    wiki_pages=[
      "wiki/civic/town-shell.md", "wiki/synthesis/town-runtime.md", "wiki/history/mayor-journal.md",
    ],
    review_queues=["wiki/reviews/town-operations.md"],
    skill_pack="civic-town-supervisor",
    output_contract="wenyu.civic.town_supervision.v1",
    worker_role=Operator,
    acceptance=[
      "detects module/workspace/projection gaps", "writes a mayor digest", "updates the visible town projection without exposing private book memory",
    ],
    projection_summary="Mayor-controlled shell for module health, worker activity, projection freshness, and civic service readiness.",
  )
}

///|
fn wenyu_resident_twins_service() -> CivicServiceDefinition {
  civic_service(
    id="resident-twins",
    title="Resident Twin Homes",
    service_kind="resident-memory",
    module_mode="hybrid",
    book_role="private-memory-with-projection",
    skill_mode="resident-memory-keeping",
    purpose="Projection-safe resident profiles, preferences, needs, reflection summaries, and daily autonomous routines.",
    workflow=[
      "ingest resident-safe updates and explicit preferences", "separate private memory from public projection",
      "propose next helpful actions without leaking sensitive data",
    ],
    agent_work=[
      "promote explicit resident preferences into private memory", "draft projection-safe resident summaries",
      "queue sensitive changes for review",
    ],
    place_work=[
      "host resident-facing presence", "hide private memory from public town views",
      "surface only consented projection cards",
    ],
    schema_pages=[
      "wiki/schemas/resident-profile.md", "wiki/schemas/privacy-projection.md",
    ],
    wiki_pages=[
      "wiki/civic/resident-twins.md", "wiki/entities/residents.md", "wiki/concepts/privacy-boundaries.md",
    ],
    review_queues=["wiki/reviews/resident-memory.md"],
    skill_pack="civic-resident-keeper",
    output_contract="wenyu.civic.resident_memory.v1",
    worker_role=MemoryKeeper,
    acceptance=[
      "keeps private and projection-safe fields separate", "records resident next-action candidates",
      "queues review for sensitive profile changes",
    ],
    projection_summary="Resident memory lane for personal context, projection safety, and everyday town participation.",
  )
}

///|
fn wenyu_vitality_dashboard_service() -> CivicServiceDefinition {
  civic_service(
    id="vitality-dashboard",
    title="Vitality Tower",
    service_kind="vitality-analytics",
    module_mode="projection-surface",
    book_role="operational-health-journal",
    skill_mode="observability-and-accounting",
    purpose="Town health metrics, resource budgets, service response, points flow, retention signals, alerts, and recovery loops.",
    workflow=[
      "read daemon, watcher, worker, and projection ledgers", "separate operational activity from real domain updates",
      "publish a service-health digest and recovery queue",
    ],
    agent_work=[
      "audit daemon/watch/service records", "separate operational events from domain progress",
      "draft recovery queue items for stale modules",
    ],
    place_work=[
      "display town vitality metrics", "surface warnings and freshness", "explain what changed versus what merely ran",
    ],
    schema_pages=[
      "wiki/schemas/vitality-metric.md", "wiki/schemas/service-alert.md",
    ],
    wiki_pages=[
      "wiki/civic/vitality-dashboard.md", "wiki/synthesis/health.md", "wiki/history/daemon-digest.md",
    ],
    review_queues=["wiki/reviews/service-alerts.md"],
    skill_pack="civic-vitality-analyst",
    output_contract="wenyu.civic.vitality_analytics.v1",
    worker_role=Watcher,
    acceptance=[
      "does not count operational retries as domain progress", "publishes stale-worker and stale-book alerts",
      "summarizes what changed and what did not change",
    ],
    projection_summary="Health and vitality lane for real-time town metrics, recovery signals, and domain-change accounting.",
  )
}

///|
fn wenyu_physical_bridge_service() -> CivicServiceDefinition {
  civic_service(
    id="physical-bridge",
    title="Physical Bridge",
    service_kind="physical-bridge",
    module_mode="gateway",
    book_role="offline-handoff-ledger",
    skill_mode="confirmation-gated-handoff",
    purpose="Virtual-to-real venue, robot, QR, display, room booking, and offline handoff workflows with confirmation gates.",
    workflow=[
      "draft the offline request and required confirmation", "verify venue, robot, or display constraints",
      "write a handoff packet without finalizing external action automatically",
    ],
    agent_work=[
      "draft offline handoff packets", "check venue or robot constraints", "queue confirmation-gated actions",
    ],
    place_work=[
      "act as virtual-to-real gateway", "show confirmation state", "prevent unapproved external actions",
    ],
    schema_pages=[
      "wiki/schemas/physical-request.md", "wiki/schemas/handoff-confirmation.md",
    ],
    wiki_pages=[
      "wiki/civic/physical-bridge.md", "wiki/entities/venues.md", "wiki/entities/robots.md",
      "wiki/queries/offline-service.md",
    ],
    review_queues=["wiki/reviews/physical-handoffs.md"],
    skill_pack="civic-bridge-operator",
    output_contract="wenyu.civic.physical_bridge.v1",
    worker_role=Operator,
    acceptance=[
      "never finalizes bookings or robot actions without approval", "records offline constraints and confirmation status",
      "publishes only projection-safe telemetry",
    ],
    projection_summary="Virtual-physical connector for venue, robot, display, and offline-service handoff packets.",
  )
}
