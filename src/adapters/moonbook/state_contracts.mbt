///|
pub struct BookStateSummary {
  book_id : String
  root : String
  page_count : Int
  source_count : Int
  source_page_count : Int
  candidate_source_count : Int
  provisional_source_count : Int
  verified_source_count : Int
  entity_count : Int
  entity_page_count : Int
  concept_count : Int
  concept_page_count : Int
  query_note_count : Int
  pending_review_count : Int
  keeper_memory_count : Int
  keeper_working_count : Int
  evidence_count : Int
  total_evidence_count : Int
  operational_evidence_count : Int
  substantive_coverage_ready : Bool
  summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn BookStateSummary::new(
  book_id~ : String,
  root~ : String,
  page_count~ : Int,
  source_count~ : Int,
  source_page_count? : Int = source_count,
  candidate_source_count? : Int = 0,
  provisional_source_count? : Int = 0,
  verified_source_count? : Int = source_page_count,
  entity_count~ : Int,
  entity_page_count? : Int = entity_count,
  concept_count~ : Int,
  concept_page_count? : Int = concept_count,
  query_note_count? : Int = 0,
  pending_review_count~ : Int,
  keeper_memory_count~ : Int,
  keeper_working_count~ : Int,
  evidence_count~ : Int,
  total_evidence_count? : Int = evidence_count,
  operational_evidence_count? : Int = total_evidence_count - evidence_count,
  substantive_coverage_ready? : Bool = false,
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
pub struct BookHealthReport {
  level : String
  summary : String
  pending_review_count : Int
  low_confidence_claim_count : Int
  maintenance_entry_count : Int
  keeper_working_count : Int
  evidence_count : Int
  issues : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookCatalogRecord {
  id : String
  name : String
  purpose : String
  workspace_root : String
  memory_scope : String
  tags : Array[String]
  skills : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct KnowledgePageRecord {
  path : String
  moonbook_type : String
  title : String
  summary : String
  review_status : String
  source_quality : String
  tags : Array[String]
  outbound_links : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct KnowledgeGraphEdge {
  from : String
  to : String
  label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct KnowledgeGraph {
  nodes : Array[KnowledgePageRecord]
  edges : Array[KnowledgeGraphEdge]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct KnowledgeBundle {
  contract : String
  book_id : String
  root : String
  generated_at : Int
  summary : BookStateSummary
  health : BookHealthReport
  pages : Array[KnowledgePageRecord]
  graph : KnowledgeGraph
  review_queue_path : String
  event_protocol : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookStatePaths {
  knowledge_manifest : String
  generated_knowledge_bundle : String
  generated_graph : String
  latest_event : String
  review_queue : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct BookStateSnapshot {
  contract : String
  book_id : String
  root : String
  generated_at : Int
  catalog : BookCatalogRecord
  summary : BookStateSummary
  health : BookHealthReport
  knowledge : KnowledgeBundle
  latest_event : @moonbook_contracts.ExecutableBookEvent?
  paths : BookStatePaths
} derive(Debug, Eq, ToJson, FromJson)
