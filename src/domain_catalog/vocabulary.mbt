///|
pub fn knowledge_domain_catalog_schema() -> String {
  "moontown.knowledge-domain-catalog.v1"
}

///|
pub fn knowledge_domain_catalog_version() -> Int {
  1
}

///|
/// Return whether an identifier is a single lowercase, path-safe segment.
/// Catalog-supplied identifiers are later used in artifact and workspace paths,
/// so separators, traversal, whitespace, and punctuation are rejected here.
pub fn valid_catalog_identifier(value : String) -> Bool {
  if value.is_empty() ||
    value.trim() != value ||
    value.has_prefix("-") ||
    value.has_suffix("-") ||
    value.contains("--") {
    return false
  }
  for char in value {
    if !((char >= 'a' && char <= 'z') ||
      (char >= '0' && char <= '9') ||
      char == '-') {
      return false
    }
  }
  true
}

///|
fn domain_kind_vocabulary() -> Array[String] {
  [
    "civic-core", "civic-service", "knowledge-domain", "learning-domain", "market-domain",
    "physical-service",
  ]
}

///|
fn template_id_vocabulary() -> Array[String] {
  [
    "domain-research-book", "civic-ledger-book", "service-operations-book", "learning-book",
    "private-resident-book", "market-intelligence-book", "project-review-book", "story-publication-book",
    "physical-handoff-book",
  ]
}

///|
fn source_policy_vocabulary() -> Array[String] {
  [
    "owner-ledger", "primary-sources", "primary-plus-licensed", "public-evidence",
    "mixed-reviewed", "privacy-scoped", "protocol-derived", "telemetry-first", "contractual-record",
  ]
}

///|
fn evidence_policy_vocabulary() -> Array[String] {
  [
    "owner-ledger", "source-linked", "primary-source-required", "licensed-provenance-required",
    "privacy-scoped", "protocol-receipt-required", "telemetry-provenance-required",
    "rights-and-claims-required",
  ]
}

///|
fn cadence_vocabulary() -> Array[String] {
  [
    "continuous", "every-tick", "hourly", "daily", "weekly", "monthly", "on-demand",
    "event-driven",
  ]
}

///|
fn schedule_tier_vocabulary() -> Array[String] {
  ["realtime", "frequent", "daily", "weekly", "monthly", "on-demand"]
}

///|
fn budget_class_vocabulary() -> Array[String] {
  ["minimal", "standard", "elevated", "controlled"]
}

///|
fn completion_claim_vocabulary() -> Array[String] {
  [
    "operational-record", "reviewed-synthesis", "evidence-backed-research", "advisory-only",
    "publication-ready", "human-accepted", "private-memory",
  ]
}

///|
fn review_role_vocabulary() -> Array[String] {
  [
    "specialist", "watcher", "analyst", "educator", "engineer", "facilitator", "publisher",
    "independent-reviewer", "keeper", "operator", "owner", "client", "safety-reviewer",
    "rights-reviewer", "mayor",
  ]
}

///|
fn book_role_vocabulary() -> Array[String] {
  [
    "owner", "orchestrator", "watcher", "researcher", "analyst", "reviewer", "archivist",
    "facilitator", "operator", "educator", "publisher", "liaison", "evaluator", "engineer",
    "strategist",
  ]
}

///|
fn book_status_vocabulary() -> Array[String] {
  ["active", "incubating", "paused", "archived"]
}

///|
/// Return the complete closed vocabulary used by MoonBit validation and the
/// portable JSON Schema.
pub fn knowledge_domain_catalog_vocabulary() -> KnowledgeDomainCatalogVocabulary {
  {
    domain_kinds: domain_kind_vocabulary(),
    template_ids: template_id_vocabulary(),
    source_policies: source_policy_vocabulary(),
    evidence_policies: evidence_policy_vocabulary(),
    cadences: cadence_vocabulary(),
    schedule_tiers: schedule_tier_vocabulary(),
    budget_classes: budget_class_vocabulary(),
    completion_claims: completion_claim_vocabulary(),
    review_roles: review_role_vocabulary(),
    book_roles: book_role_vocabulary(),
    book_statuses: book_status_vocabulary(),
  }
}

///|
fn valid_domain_kind(value : String) -> Bool {
  domain_kind_vocabulary().contains(value)
}

///|
fn valid_template_id(value : String) -> Bool {
  template_id_vocabulary().contains(value)
}

///|
fn valid_source_policy(value : String) -> Bool {
  source_policy_vocabulary().contains(value)
}

///|
fn valid_evidence_policy(value : String) -> Bool {
  evidence_policy_vocabulary().contains(value)
}

///|
fn valid_cadence(value : String) -> Bool {
  cadence_vocabulary().contains(value)
}

///|
fn valid_schedule_tier(value : String) -> Bool {
  schedule_tier_vocabulary().contains(value)
}

///|
fn valid_budget_class(value : String) -> Bool {
  budget_class_vocabulary().contains(value)
}

///|
fn valid_completion_claim(value : String) -> Bool {
  completion_claim_vocabulary().contains(value)
}

///|
fn valid_review_role(value : String) -> Bool {
  review_role_vocabulary().contains(value)
}

///|
fn valid_book_role(value : String) -> Bool {
  book_role_vocabulary().contains(value)
}

///|
fn valid_book_status(value : String) -> Bool {
  book_status_vocabulary().contains(value)
}
