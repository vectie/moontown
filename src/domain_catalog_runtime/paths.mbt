///|
pub fn default_knowledge_domain_catalog_path() -> String {
  "assets/templates/domains/catalog.v1.json"
}

///|
pub fn knowledge_catalog_request_path(
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  @book_templates.request_path_for_snapshot(snapshot_path)
}

///|
pub fn knowledge_catalog_config_root(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{@storage.snapshot_base_dir(snapshot_path)}/knowledge-catalogs/\{catalog.catalog_id}/v\{catalog.version}/configs"
}

///|
pub fn knowledge_catalog_book_config_path(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
  book : @domain_catalog.KnowledgeDomainBook,
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  "\{knowledge_catalog_config_root(catalog, snapshot_path~)}/\{book.book_id}.json"
}

///|
pub fn knowledge_catalog_book_request_id(
  catalog : @domain_catalog.KnowledgeDomainCatalog,
  book : @domain_catalog.KnowledgeDomainBook,
) -> String {
  "knowledge-\{catalog.catalog_id}-v\{catalog.version}-\{book.book_id}"
}
