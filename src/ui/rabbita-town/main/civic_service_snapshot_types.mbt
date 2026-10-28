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
  protocol_inbox_count : Int32
  protocol_contribution_count : Int32
  protocol_reduction_count : Int32
  protocol_outbox_count : Int32
  protocol_review_count : Int32
  latest_protocol_summary : String
  protocol_history : Array[ProtocolHistoryEntrySnapshot]?
  protocol_history_state : String?
  status : String
  operable : Bool
  proven_by_result : Bool
  latest_decision : String
  latest_pages_changed : Int32
  latest_accepted_facts : Int32
  latest_review_items : Int32
  missing_required_paths : Array[String]
  notes : Array[String]
} derive(FromJson)

///|
priv struct CivicServicePortfolioSnapshot {
  total : Int32
  operable_count : Int32
  proven_count : Int32
  seeded_count : Int32
  missing_count : Int32
  review_count : Int32
  blocked_count : Int32
  changed_count : Int32
  no_change_count : Int32
  services : Array[CivicServiceHealthSnapshot]
} derive(FromJson)
