///|
priv struct ProtocolHistoryEntrySnapshot {
  step : String
  status : String
  title : String
  detail : String
  evidence_ref : String
} derive(FromJson)

///|
priv struct CivicServiceHealthSnapshot {
  service_id : String
  title : String
  book_id : String
  service_kind : String
  module_mode : String
  book_role : String
  skill_mode : String
  protocol_status : String
  protocol_ready : Bool
  protocol_inbox_count : Int
  protocol_contribution_count : Int
  protocol_reduction_count : Int
  protocol_outbox_count : Int
  protocol_review_count : Int
  latest_protocol_summary : String
  protocol_history : Array[ProtocolHistoryEntrySnapshot]?
  protocol_history_state : String?
  status : String
  operable : Bool
  proven_by_result : Bool
  latest_decision : String
  latest_pages_changed : Int
  latest_accepted_facts : Int
  latest_review_items : Int
  missing_required_paths : Array[String]
  notes : Array[String]
} derive(FromJson)

///|
priv struct CivicServicePortfolioSnapshot {
  total : Int
  operable_count : Int
  proven_count : Int
  seeded_count : Int
  missing_count : Int
  review_count : Int
  blocked_count : Int
  changed_count : Int
  no_change_count : Int
  services : Array[CivicServiceHealthSnapshot]
} derive(FromJson)
