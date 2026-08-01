///|
fn knowledge_catalog_request_in(
  requests : Array[@book_templates.BookTemplateRequest],
  request_id : String,
) -> Bool {
  for request in requests {
    if request.id == request_id {
      return true
    }
  }
  false
}

///|
fn knowledge_catalog_request_status(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
  book : @domain_catalog.KnowledgeDomainBook,
  requests : Array[@book_templates.BookTemplateRequest],
) -> String {
  let request_id = knowledge_catalog_book_request_id(catalog, book)
  for request in requests {
    if request.id == request_id {
      return match request.status {
        "installed" => "workspace_installed"
        "retry" => "pending_retry"
        "failed" => "install_failed"
        status => status
      }
    }
  }
  if knowledge_book_seed_enabled(book) {
    "declared"
  } else {
    book.status
  }
}

///|
pub async fn seed_knowledge_domain_catalog(
  catalog_path? : String = default_knowledge_domain_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  let (loaded, errors) = load_knowledge_domain_catalog_with_errors(catalog_path)
  let catalog = match loaded {
    Some(catalog) => catalog
    None =>
      return render_catalog_load_failure(
        "Knowledge Catalog Seed", catalog_path, errors,
      )
  }
  let request_path = knowledge_catalog_request_path(snapshot_path~)
  let ledger = @book_templates_runtime.load_request_ledger(request_path)
  let requests = ledger.requests.copy()
  let mut declared = 0
  let mut enqueued = 0
  let mut already_present = 0
  let mut unsupported = 0
  let mut inactive = 0
  let mut configs_written = 0
  let mut configs_preserved = 0
  let mut source_configured = 0
  let mut source_configuration_required = 0
  let mut deferred_for_sources = 0
  let mut existing_requests_blocked_by_sources = 0
  let source_rows : Array[String] = []
  for domain in catalog.domains {
    for book in domain.books {
      declared += 1
      if !knowledge_book_seed_enabled(book) {
        inactive += 1
        continue
      }
      if !knowledge_book_template_supported(book) {
        unsupported += 1
        continue
      }
      let policy = match @domain_catalog.find_policy(catalog, book.policy_id) {
        Some(policy) => policy
        None => {
          unsupported += 1
          continue
        }
      }
      let config = match knowledge_book_config_json(domain, book, policy) {
        Some(config) => config
        None => {
          unsupported += 1
          continue
        }
      }
      let config_path = knowledge_catalog_book_config_path(
        catalog,
        book,
        snapshot_path~,
      )
      if !@fs.exists(config_path) {
        @support.write_text_file(config_path, config.stringify(indent=2))
        configs_written += 1
      } else {
        configs_preserved += 1
      }
      let request_id = knowledge_catalog_book_request_id(catalog, book)
      let source_readiness = inspect_knowledge_book_source_readiness(
        book, config_path,
      )
      if source_readiness.status != "source_configured" {
        source_configuration_required += 1
        source_rows.push(
          "| `\{book.book_id}` | `\{book.source_policy}` | `\{source_readiness.status}` | `\{config_path}` | \{source_readiness.next_action} |",
        )
        if knowledge_catalog_request_in(requests, request_id) {
          already_present += 1
          existing_requests_blocked_by_sources += 1
        } else {
          deferred_for_sources += 1
        }
        continue
      }
      source_configured += 1
      if knowledge_catalog_request_in(requests, request_id) {
        already_present += 1
        continue
      }
      requests.push({
        id: request_id,
        template_id: knowledge_book_installer_template_id(book).unwrap(),
        config_path,
        status: @book_templates.request_status_pending(),
        summary: "Declared by `\{catalog.catalog_id}@\{catalog.version}` from archetype `\{book.template_id}`; pending template installation and not accepted knowledge.",
        last_processed_tick: 0,
      })
      enqueued += 1
    }
  }
  if enqueued > 0 {
    @book_templates_runtime.save_request_ledger(request_path, { requests, })
  }
  [
    "# Knowledge Catalog Seed",
    "",
    "- Catalog: `\{catalog.catalog_id}@\{catalog.version}`",
    "- Seed: `\{catalog.seed}`",
    "- Catalog books declared: `\{declared}`",
    "- Newly pending template requests: `\{enqueued}`",
    "- Existing requests preserved: `\{already_present}`",
    "- Active books with configured source references: `\{source_configured}`",
    "- Active books requiring source configuration: `\{source_configuration_required}`",
    "- New requests deferred for source configuration: `\{deferred_for_sources}`",
    "- Existing requests blocked by missing or invalid source configuration: `\{existing_requests_blocked_by_sources}`",
    "- Incubating, paused, or archived books left declared: `\{inactive}`",
    "- Unsupported books left declared: `\{unsupported}`",
    "- Config files written: `\{configs_written}`",
    "- Existing config files preserved without mutation: `\{configs_preserved}`",
    "- Request ledger: `\{request_path}`",
    "",
    "Seeding creates only missing empty config scaffolds and never inserts, guesses, or overwrites user source references. Active books without explicit source configuration are not newly queued for installation.",
    "",
    "A queued or installed workspace is still not research-ready. Research readiness requires approved sources, successful evidence work, and the catalog policy's review chain; this command never claims those gates passed.",
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
    "",
    "After configuring approved sources, run `knowledge seed` again to queue eligible books. Run `books template requests process` separately to install pending workspaces.",
  ].join("\n")
}
