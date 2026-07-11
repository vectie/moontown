///|
fn civic_projection_state(
  service : @civic.CivicServiceDefinition,
) -> CivicProjectionState {
  {
    title: "Wenyu Valley / \{service.title}",
    summary: service.projection_summary,
    status_chips: [
      { label: "Civic workspace", tone: "healthy" },
      { label: service.service_kind, tone: "info" },
      { label: service.module_mode, tone: "info" },
      { label: "Review gated", tone: "review" },
    ],
    metrics: civic_projection_metrics(service),
    readiness: projection_items(
      [
        ..service.schema_pages,
        ..service.wiki_pages,
        service.skill_path,
        "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
        "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
      ],
      "Ready",
    ),
    review_queue: projection_items(service.review_queues, "Pending"),
    page_families: projection_items(service.target_pages, "Workspace"),
    journey: civic_projection_journey(service),
  }
}

///|
fn civic_projection_metrics(
  service : @civic.CivicServiceDefinition,
) -> Array[CivicProjectionMetric] {
  [
    {
      label: "Schemas",
      value: "\{service.schema_pages.length()}",
      note: "module-specific schemas",
      tone: "healthy",
    },
    {
      label: "Wiki pages",
      value: "\{service.wiki_pages.length()}",
      note: "durable civic pages",
      tone: "healthy",
    },
    {
      label: "Review queues",
      value: "\{service.review_queues.length()}",
      note: "keeper/operator gates",
      tone: "review",
    },
    {
      label: "Skill pack",
      value: service.skill_pack,
      note: service.output_contract,
      tone: "info",
    },
    {
      label: "Mode",
      value: service.module_mode,
      note: service.skill_mode,
      tone: "info",
    },
  ]
}

///|
fn civic_projection_journey(
  service : @civic.CivicServiceDefinition,
) -> Array[CivicProjectionJourney] {
  [
    {
      title: "Civic workspace bootstrap",
      stage: "bootstrap",
      status: "projected",
      summary: "MoonTown created the MoonBook-facing workspace scaffold, module skill pack, review queue, and projection fragment for \{service.title}.",
      highlights: [
        "Book id: \{service.book_id}",
        "Mode: \{service.module_mode}",
        "Book role: \{service.book_role}",
        "Skill: \{service.skill_path}",
        "Contract: \{service.output_contract}",
      ],
    },
  ]
}

///|
fn projection_items(
  paths : Array[String],
  meta : String,
) -> Array[CivicProjectionItem] {
  let items : Array[CivicProjectionItem] = []
  for path in paths {
    items.push({ title: schema_title(path), detail: path, meta })
  }
  items
}
