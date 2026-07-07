///|
pub(all) struct MiniappBookLedgerIds {
  request_ledger_id : String
  review_ledger_id : String
  accepted_memory_ledger_id : String
  publication_ledger_id : String
  run_ledger_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingBookBinding {
  building_id : String
  primary_book_id : String
  support_book_ids : Array[String]
  ledgers : MiniappBookLedgerIds
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingBookDetail {
  building_id : String
  title : String
  summary : String
  primary_book : @miniapp_contracts.MiniappBookSummary
  support_books : Array[@miniapp_contracts.MiniappBookSummary]
  ledgers : MiniappBookLedgerIds?
  can_query : Bool
  can_accept_memory : Bool
  recent_run_count : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingQueryDraft {
  building_id : String
  run_id : String
  thread_id : String
  agent_id : String?
  question_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBookMemoryDraft {
  run_id : String
  accepted_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBookChange {
  ok : Bool
  snapshot : @miniapp_contracts.MiniappTownSnapshot
  message : String
  building_id : String
  book_id : String
  run_id : String?
} derive(Debug, Eq, ToJson, FromJson)
