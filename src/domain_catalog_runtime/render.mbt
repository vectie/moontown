///|
pub async fn render_knowledge_domain_catalog(
  catalog_path? : String = default_knowledge_domain_catalog_path(),
) -> String {
  let (loaded, errors) = load_knowledge_domain_catalog_with_errors(catalog_path)
  let catalog = match loaded {
    Some(catalog) => catalog
    None =>
      return render_catalog_load_failure(
        "Knowledge Domain Catalog", catalog_path, errors,
      )
  }
  let rows : Array[String] = []
  for domain in catalog.domains {
    rows.push(
      "| `\{domain.domain_id}` | \{domain.title} | `\{domain.building_id}` | `\{domain.primary_book_id}` | \{domain.books.length()} | `\{domain.policy_id}` |",
    )
  }
  [
    "# Knowledge Domain Catalog",
    "",
    "- Catalog: `\{catalog.catalog_id}@\{catalog.version}`",
    "- Schema: `\{catalog.schema}`",
    "- Seed: `\{catalog.seed}`",
    "- Valid: `true`",
    "- Domains: `\{@domain_catalog.domain_count(catalog)}`",
    "- Buildings: `\{@domain_catalog.building_count(catalog)}`",
    "- Books: `\{@domain_catalog.book_count(catalog)}`",
    "- Active books: `\{@domain_catalog.active_book_count(catalog)}`",
    "- Policies: `\{@domain_catalog.policy_count(catalog)}`",
    "",
    "| Domain | Title | Building | Primary MoonBook | Books | Policy |",
    "| --- | --- | --- | --- | ---: | --- |",
    rows.join("\n"),
  ].join("\n")
}

///|
pub async fn render_knowledge_domain_catalog_status(
  catalog_path? : String = default_knowledge_domain_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let (loaded, errors) = load_knowledge_domain_catalog_with_errors(catalog_path)
  let catalog = match loaded {
    Some(catalog) => catalog
    None =>
      return render_catalog_load_failure(
        "Knowledge Catalog Status", catalog_path, errors,
      )
  }
  let request_path = knowledge_catalog_request_path(snapshot_path~)
  let ledger = @book_templates_runtime.load_request_ledger(request_path)
  let mut declared = 0
  let mut pending = 0
  let mut installed = 0
  let mut failed = 0
  let mut inactive = 0
  let mut source_configured = 0
  let mut source_configuration_required = 0
  let rows : Array[String] = []
  let source_rows : Array[String] = []
  for domain in catalog.domains {
    for book in domain.books {
      let status = knowledge_catalog_request_status(
        catalog,
        book,
        ledger.requests,
      )
      match status {
        "declared" => declared += 1
        "pending" | "pending_retry" => pending += 1
        "workspace_installed" => installed += 1
        "install_failed" => failed += 1
        _ => inactive += 1
      }
      let config_path = knowledge_catalog_book_config_path(
        catalog,
        book,
        snapshot_path~,
      )
      let source_readiness = inspect_knowledge_book_source_readiness(
        book, config_path,
      )
      if book.status == "active" {
        if source_readiness.status == "source_configured" {
          source_configured += 1
        } else {
          source_configuration_required += 1
          source_rows.push(
            "| `\{book.book_id}` | `\{book.source_policy}` | `\{source_readiness.status}` | `\{config_path}` | \{source_readiness.next_action} |",
          )
        }
      }
      let research_readiness = knowledge_book_research_readiness(
        book, status, source_readiness,
      )
      rows.push(
        "| `\{domain.building_id}` | `\{book.book_id}` | \{book.role} | `\{book.template_id}` → `\{knowledge_book_installer_template_id(book).unwrap_or("unsupported")}` | `\{status}` | `\{source_readiness.status}` (\{source_readiness.configured_source_count}) | `\{research_readiness}` |",
      )
    }
  }
  [
    "# Knowledge Catalog Status",
    "",
    "- Catalog: `\{catalog.catalog_id}@\{catalog.version}`",
    "- Request ledger: `\{request_path}`",
    "- Declared only: `\{declared}`",
    "- Pending template installation: `\{pending}`",
    "- Workspace installed: `\{installed}`",
    "- Installation failed: `\{failed}`",
    "- Active books with configured source references: `\{source_configured}`",
    "- Active books requiring source configuration: `\{source_configuration_required}`",
    "- Incubating, paused, archived, or other catalog state: `\{inactive}`",
    "",
    "This status command is read-only: it does not create configs, add sources, enqueue requests, or modify MoonBook state.",
    "",
    "`workspace_installed` is only a provisioning state. Even with configured sources it does not prove research ran, evidence passed review, or MoonBook accepted knowledge. This command never emits a `research_ready` claim.",
    "",
    "| Building | MoonBook | Role | Template | Provisioning state | Source state (refs) | Research readiness |",
    "| --- | --- | --- | --- | --- | --- | --- |",
    rows.join("\n"),
    "",
    "## Active books requiring source configuration",
    "",
    if source_rows.is_empty() {
      "No active book is currently blocked by missing source configuration."
    } else {
      [
        "| MoonBook | Source policy | Source state | Config | Required action |",
        "| --- | --- | --- | --- | --- |",
        source_rows.join("\n"),
      ].join("\n")
    },
  ].join("\n")
}
