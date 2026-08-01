///|
priv struct ProjectionChipSnapshot {
  label : String
  tone : String
} derive(FromJson)

///|
priv struct ProjectionMetricSnapshot {
  label : String
  value : String
  note : String
  tone : String
} derive(FromJson)

///|
priv struct ProjectionItemSnapshot {
  title : String
  detail : String
  meta : String
} derive(FromJson)

///|
priv struct ProjectionJourneySnapshot {
  title : String
  stage : String
  status : String
  summary : String
  highlights : Array[String]
} derive(FromJson)

///|
priv struct ProjectionLinkSnapshot {
  label : String
  kind : String
  url : String
} derive(FromJson)

///|
/// Read-only proof that MoonBook's durable bookkeeper accepted one exact
/// candidate. This field is absent when no explicit decision exists.
priv struct ProjectionAcceptanceReceipt {
  contract_version : String
  decision : String
  decision_id : String
  candidate_version : String
  reviewer : String
  evidence_count : Int
  issue_count : Int
  requires_human_review : Bool
  source_contract : String
  source_projection : String
} derive(FromJson)

///|
priv struct BookProjectionFragment {
  book_id : String
  title : String
  summary : String
  status_chips : Array[ProjectionChipSnapshot]
  metrics : Array[ProjectionMetricSnapshot]
  readiness : Array[ProjectionItemSnapshot]
  review_queue : Array[ProjectionItemSnapshot]
  page_families : Array[ProjectionItemSnapshot]
  journey : Array[ProjectionJourneySnapshot]
  links : Array[ProjectionLinkSnapshot]
  acceptance_receipt : ProjectionAcceptanceReceipt?
} derive(FromJson)

///|
priv struct ModuleProjectionIndex {
  generated_at : String
  projections : Array[BookProjectionFragment]
} derive(FromJson)
