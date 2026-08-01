///|
/// A versioned policy profile shared by every book in one or more knowledge
/// domains. The profile names governance and scheduling decisions; execution
/// remains owned by MoonTown and durable knowledge remains owned by MoonBook.
pub(all) struct KnowledgeDomainPolicy {
  id : String
  version : Int
  template_id : String
  source_policy : String
  evidence_policy : String
  cadence : String
  cadence_ticks : Int
  quality_threshold : Int
  review_chain : Array[String]
  max_revision_rounds : Int
  schedule_tier : String
  budget_class : String
  completion_claim : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A canonical MoonBook specification bound to a registered knowledge domain.
/// It contains catalog metadata only, never mutable book content or memory.
pub(all) struct KnowledgeDomainBook {
  book_id : String
  title : String
  question : String
  role : String
  template_id : String
  policy_id : String
  schedule_tier : String
  cadence_ticks : Int
  tags : Array[String]
  source_policy : String
  status : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A semantic domain attached to one registered town building. Geometry and
/// visual placement deliberately live outside this contract.
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
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The portable source of truth for building-to-domain-to-book membership.
pub(all) struct KnowledgeDomainCatalog {
  schema : String
  catalog_id : String
  version : Int
  seed : Int
  description : String
  policies : Array[KnowledgeDomainPolicy]
  domains : Array[KnowledgeDomain]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Aggregate counts used by runtimes and interfaces without reimplementing
/// catalog traversal.
pub(all) struct KnowledgeDomainPortfolio {
  domain_count : Int
  building_count : Int
  policy_count : Int
  book_count : Int
  active_book_count : Int
  incubating_book_count : Int
  paused_book_count : Int
  archived_book_count : Int
  communication_scenario_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Closed JSON-compatible vocabularies accepted by the catalog parser. The
/// checked-in JSON Schema mirrors these arrays exactly.
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
} derive(Debug, Eq, ToJson, FromJson)
