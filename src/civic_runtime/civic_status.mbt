///|
pub struct ProtocolHistoryEntry {
  step : String
  status : String
  title : String
  detail : String
  evidence_ref : String
} derive(Eq, ToJson, FromJson)

///|
pub struct CivicServiceHealth {
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
  protocol_history : Array[ProtocolHistoryEntry]
  protocol_history_state : String
  workspace_root : String
  status : String
  operable : Bool
  proven_by_result : Bool
  workspace_exists : Bool
  schema_ready : Bool
  wiki_ready : Bool
  review_ready : Bool
  projection_ready : Bool
  skill_ready : Bool
  moonclaw_profile_ready : Bool
  latest_result_path : String
  latest_result_found : Bool
  latest_decision : String
  latest_book_changed : String
  latest_pages_changed : Int
  latest_accepted_facts : Int
  latest_review_items : Int
  next_check_hint : String
  missing_required_paths : Array[String]
  notes : Array[String]
} derive(Eq, ToJson, FromJson)

///|
pub struct CivicServicePortfolio {
  total : Int
  operable_count : Int
  proven_count : Int
  seeded_count : Int
  missing_count : Int
  review_count : Int
  blocked_count : Int
  changed_count : Int
  no_change_count : Int
  status_path : String
  markdown_path : String
  services : Array[CivicServiceHealth]
} derive(Eq, ToJson, FromJson)

///|
pub fn default_wenyu_civic_status_path() -> String {
  "\{@storage.moontown_product_state_dir()}/civic/status.json"
}

///|
pub async fn inspect_wenyu_civic_services(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  status_path? : String = default_wenyu_civic_status_path(),
) -> CivicServicePortfolio {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let healths : Array[CivicServiceHealth] = []
  for service in @civic.wenyu_civic_services() {
    let entry = civic_catalog_entry_for_service(service, catalog)
    healths.push(inspect_wenyu_civic_service(service, entry))
  }
  civic_service_portfolio(healths, status_path)
}

///|
pub async fn render_wenyu_civic_status(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  render_wenyu_civic_portfolio(inspect_wenyu_civic_services(book_catalog_path~))
}

///|
pub async fn write_wenyu_civic_status(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  status_path? : String = default_wenyu_civic_status_path(),
) -> String {
  let portfolio = inspect_wenyu_civic_services(book_catalog_path~, status_path~)
  @support.write_text_file(status_path, portfolio.to_json().stringify(indent=2))
  ignore(write_wenyu_building_protocol_status())
  @support.write_text_file(
    portfolio.markdown_path,
    render_wenyu_civic_portfolio(portfolio),
  )
  "Wrote Wenyu civic service status for \{portfolio.total} module(s) to \{status_path} and \{portfolio.markdown_path}."
}
