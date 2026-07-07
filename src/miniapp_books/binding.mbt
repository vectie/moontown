///|
pub fn miniapp_building_book_binding(
  building : @miniapp_contracts.MiniappBuilding,
  support_book_ids? : Array[String] = [],
) -> MiniappBuildingBookBinding {
  {
    building_id: building.id,
    primary_book_id: building.primary_book_id,
    support_book_ids,
    ledgers: miniapp_book_ledgers_for_building(building.id),
    version: building.version,
  }
}

///|
fn miniapp_book_ledgers_for_building(
  building_id : String,
) -> MiniappBookLedgerIds {
  {
    request_ledger_id: "ledger-\{building_id}-requests",
    review_ledger_id: "ledger-\{building_id}-reviews",
    accepted_memory_ledger_id: "ledger-\{building_id}-accepted-memory",
    publication_ledger_id: "ledger-\{building_id}-publication",
    run_ledger_id: "ledger-\{building_id}-runs",
  }
}
