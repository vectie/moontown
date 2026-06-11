///|
pub async fn bootstrap_wenyu_civic_workspaces(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let services = @civic.wenyu_civic_services()
  let merged = merge_wenyu_civic_catalog(catalog, services)
  @moonbook.save_catalog_file(book_catalog_path, merged)
  let objective = "Bootstrap Wenyu Valley civic service MoonBook workspaces, schemas, review queues, projections, and MoonClaw skill contracts."
  for service in services {
    let entry = @civic.wenyu_civic_book_entry(service)
    write_wenyu_civic_workspace_seed_for_service(entry, service, objective)
  }
  ignore(bootstrap_wenyu_building_protocols())
  "Bootstrapped \{services.length()} Wenyu civic MoonBook workspaces, building protocol definitions, and updated \{book_catalog_path}."
}

///|
fn merge_wenyu_civic_catalog(
  catalog : Array[@moonbook.BookCatalogEntry],
  services : Array[@civic.CivicServiceDefinition],
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if !@civic.is_wenyu_civic_book_id(entry.id) {
      merged.push(entry)
    }
  }
  for service in services {
    merged.push(@civic.wenyu_civic_book_entry(service))
  }
  merged
}

///|
async fn write_wenyu_civic_workspace_seed(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Unit {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      write_wenyu_civic_workspace_seed_for_service(entry, service, objective)
    None => ()
  }
}

///|
async fn write_wenyu_civic_workspace_seed_for_service(
  entry : @moonbook.BookCatalogEntry,
  service : @civic.CivicServiceDefinition,
  objective : String,
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  write_text_file_if_missing(
    "\{root}/wiki/index.md",
    @civic.workspace_index_text(entry, service),
  )
  write_text_file(
    "\{root}/raw/bootstrap/CIVIC_SERVICE_CONTRACT.md",
    @civic.service_contract_text(entry, service, objective),
  )
  write_text_file(
    "\{root}/raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
    @civic.building_protocol_contract_text(service),
  )
  write_text_file(
    "\{root}/skills/wenyu-civic-service/SKILL.md",
    @civic.wenyu_civic_service_skill_text(),
  )
  write_text_file(
    @civic.service_skill_path(root, service),
    @civic.civic_module_skill_text(service),
  )
  write_civic_schema_pages(root, service)
  write_civic_wiki_pages(root, service)
  write_civic_review_queues(root, service)
  write_civic_service_ledgers(root, service)
  write_civic_projection(root, service)
  write_civic_html_pages(root, service)
  ensure_wenyu_civic_moonclaw_profile(root)
}

///|
async fn write_civic_schema_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.schema_pages {
    write_text_file_if_missing(
      "\{root}/\{path}",
      @civic.schema_page_text(service, path),
    )
  }
}

///|
async fn write_civic_wiki_pages(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.wiki_pages {
    write_text_file_if_missing(
      "\{root}/\{path}",
      @civic.wiki_page_text(service, path),
    )
  }
}

///|
async fn write_civic_review_queues(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  for path in service.review_queues {
    write_text_file_if_missing(
      "\{root}/\{path}",
      @civic.review_queue_text(service, path),
    )
  }
}

///|
async fn write_civic_service_ledgers(
  root : String,
  service : @civic.CivicServiceDefinition,
) -> Unit {
  write_text_file_if_missing(
    "\{root}/wiki/ledgers/service-ledger.md",
    @civic.service_ledger_text(service),
  )
  write_text_file_if_missing(
    "\{root}/wiki/ledgers/exchange-ledger.md",
    @civic.exchange_ledger_text(service),
  )
  write_text_file_if_missing(
    "\{root}/wiki/history/service-history.md",
    @civic.service_history_text(service),
  )
}
