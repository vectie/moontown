///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct BookStateSummary {
  book_id : String
  root : String
  page_count : Int32
  source_count : Int32
  source_page_count : Int32
  candidate_source_count : Int32
  provisional_source_count : Int32
  verified_source_count : Int32
  entity_count : Int32
  entity_page_count : Int32
  concept_count : Int32
  concept_page_count : Int32
  query_note_count : Int32
  pending_review_count : Int32
  keeper_memory_count : Int32
  keeper_working_count : Int32
  evidence_count : Int32
  total_evidence_count : Int32
  operational_evidence_count : Int32
  substantive_coverage_ready : Bool
  summary : String
}

///|
pub fn BookStateSummary::new(
  book_id~ : String,
  root~ : String,
  page_count~ : Int32,
  source_count~ : Int32,
  source_page_count~ : Int32 = source_count,
  candidate_source_count~ : Int32 = 0,
  provisional_source_count~ : Int32 = 0,
  verified_source_count~ : Int32 = source_page_count,
  entity_count~ : Int32,
  entity_page_count~ : Int32 = entity_count,
  concept_count~ : Int32,
  concept_page_count~ : Int32 = concept_count,
  query_note_count~ : Int32 = 0,
  pending_review_count~ : Int32,
  keeper_memory_count~ : Int32,
  keeper_working_count~ : Int32,
  evidence_count~ : Int32,
  total_evidence_count~ : Int32 = evidence_count,
  operational_evidence_count~ : Int32 = total_evidence_count - evidence_count,
  substantive_coverage_ready~ : Bool = false,
  summary~ : String,
) -> BookStateSummary {
  {
    book_id,
    root,
    page_count,
    source_count,
    source_page_count,
    candidate_source_count,
    provisional_source_count,
    verified_source_count,
    entity_count,
    entity_page_count,
    concept_count,
    concept_page_count,
    query_note_count,
    pending_review_count,
    keeper_memory_count,
    keeper_working_count,
    evidence_count,
    total_evidence_count,
    operational_evidence_count,
    substantive_coverage_ready,
    summary,
  }
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct BookHealthReport {
  level : String
  summary : String
  pending_review_count : Int32
  low_confidence_claim_count : Int32
  maintenance_entry_count : Int32
  keeper_working_count : Int32
  evidence_count : Int32
  issues : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct BookCatalogRecord {
  id : String
  name : String
  purpose : String
  workspace_root : String
  memory_scope : String
  tags : Array[String]
  skills : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct KnowledgePageRecord {
  path : String
  moonbook_type : String
  title : String
  summary : String
  review_status : String
  source_quality : String
  tags : Array[String]
  outbound_links : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct KnowledgeGraphEdge {
  from : String
  to : String
  label : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct KnowledgeGraph {
  nodes : Array[KnowledgePageRecord]
  edges : Array[KnowledgeGraphEdge]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct KnowledgeBundle {
  contract : String
  book_id : String
  root : String
  // Numeric epoch milliseconds on the MoonBook JSON wire.
  generated_at : Double
  summary : BookStateSummary
  health : BookHealthReport
  pages : Array[KnowledgePageRecord]
  graph : KnowledgeGraph
  review_queue_path : String
  event_protocol : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct BookStatePaths {
  knowledge_manifest : String
  generated_knowledge_bundle : String
  generated_graph : String
  latest_event : String
  review_queue : String
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub struct BookStateSnapshot {
  contract : String
  book_id : String
  root : String
  // Keep older numeric snapshot values readable.
  generated_at : Double
  catalog : BookCatalogRecord
  summary : BookStateSummary
  health : BookHealthReport
  knowledge : KnowledgeBundle
  latest_event : @moonbook_contracts.ExecutableBookEvent?
  paths : BookStatePaths
}

///|
fn valid_generated_at_millis(value : Double) -> Bool {
  !value.is_nan() &&
  !value.is_nan() &&
  !value.is_inf() &&
  value >= -9007199254740991.0 &&
  value <= 9007199254740991.0 &&
  value.trunc() == value
}
