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
} derive(FromJson)

///|
priv struct ModuleProjectionIndex {
  generated_at : String
  projections : Array[BookProjectionFragment]
} derive(FromJson)
