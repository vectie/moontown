///|
/// A versioned policy profile shared by every book in one or more knowledge
/// domains. The profile names governance and scheduling decisions; execution
/// remains owned by MoonTown and durable knowledge remains owned by MoonBook.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomainPolicy {
  id : String
  version : Int32
  template_id : String
  source_policy : String
  evidence_policy : String
  cadence : String
  cadence_ticks : Int32
  quality_threshold : Int32
  review_chain : Array[String]
  max_revision_rounds : Int32
  schedule_tier : String
  budget_class : String
  completion_claim : String
}

///|
/// A canonical MoonBook specification bound to a registered knowledge domain.
/// It contains catalog metadata only, never mutable book content or memory.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomainBook {
  book_id : String
  title : String
  question : String
  role : String
  template_id : String
  policy_id : String
  schedule_tier : String
  cadence_ticks : Int32
  tags : Array[String]
  source_policy : String
  status : String
}

///|
/// A semantic domain attached to one registered town building. Geometry and
/// visual placement deliberately live outside this contract.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomain {
  domain_id : String
  title : String
  icon : String
  building_id : String
  kind : String
  primary_book_id : String
  policy_id : String
  communication_scenario_ids : Array[String]
  summary : String
  books : Array[KnowledgeDomainBook]
}

///|
/// The portable source of truth for building-to-domain-to-book membership.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomainCatalog {
  schema : String
  catalog_id : String
  version : Int32
  seed : Int32
  description : String
  policies : Array[KnowledgeDomainPolicy]
  domains : Array[KnowledgeDomain]
}

///|
/// Aggregate counts used by runtimes and interfaces without reimplementing
/// catalog traversal.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomainPortfolio {
  domain_count : Int32
  building_count : Int32
  policy_count : Int32
  book_count : Int32
  active_book_count : Int32
  incubating_book_count : Int32
  paused_book_count : Int32
  archived_book_count : Int32
  communication_scenario_count : Int32
}

///|
/// Closed JSON-compatible vocabularies accepted by the catalog parser. The
/// checked-in JSON Schema mirrors these arrays exactly.
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct KnowledgeDomainCatalogVocabulary {
  domain_kinds : Array[String]
  template_ids : Array[String]
  source_policies : Array[String]
  evidence_policies : Array[String]
  cadences : Array[String]
  schedule_tiers : Array[String]
  budget_classes : Array[String]
  completion_claims : Array[String]
  review_roles : Array[String]
  book_roles : Array[String]
  book_statuses : Array[String]
}
