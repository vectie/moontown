///|
/// Decode and validate a catalog from an already parsed JSON value.
pub fn decode_knowledge_domain_catalog(
  value : Json,
) -> KnowledgeDomainCatalog raise {
  let catalog : KnowledgeDomainCatalog = @json.from_json(value)
  require_valid_knowledge_domain_catalog(catalog)
  catalog
}

///|
/// Parse and validate a portable catalog document.
pub fn parse_knowledge_domain_catalog(
  text : String,
) -> KnowledgeDomainCatalog raise {
  decode_knowledge_domain_catalog(@json.parse(text))
}
