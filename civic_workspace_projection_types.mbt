///|
priv struct CivicProjectionChip {
  label : String
  tone : String
} derive(ToJson)

///|
priv struct CivicProjectionMetric {
  label : String
  value : String
  note : String
  tone : String
} derive(ToJson)

///|
priv struct CivicProjectionItem {
  title : String
  detail : String
  meta : String
} derive(ToJson)

///|
priv struct CivicProjectionJourney {
  title : String
  stage : String
  status : String
  summary : String
  highlights : Array[String]
} derive(ToJson)

///|
priv struct CivicProjectionState {
  title : String
  summary : String
  status_chips : Array[CivicProjectionChip]
  metrics : Array[CivicProjectionMetric]
  readiness : Array[CivicProjectionItem]
  review_queue : Array[CivicProjectionItem]
  page_families : Array[CivicProjectionItem]
  journey : Array[CivicProjectionJourney]
} derive(ToJson)
