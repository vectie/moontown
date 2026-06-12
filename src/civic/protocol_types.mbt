///|
pub(all) struct BuildingProtocolDefinition {
  building_id : String
  service_id : String
  title : String
  book_id : String
  protocol_mode : String
  persistence_mode : String
  social_responsibility : String
  participant_roles : Array[String]
  input_channels : Array[String]
  output_channels : Array[String]
  aggregation_policy : String
  exchange_policy : String
  reduction_policy : String
  distribution_policy : String
  review_gates : Array[String]
  privacy_scope : String
  moonbook_role : String
  skill_packs : Array[String]
  projection_contract : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingInputPacket {
  id : String
  building_id : String
  source_kind : String
  source_id : String
  channel : String
  privacy_label : String
  summary : String
  payload : String
  review_status : String
  idempotency_key : String
  related_book_id : String
  related_task_id : String
  related_run_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingContribution {
  id : String
  building_id : String
  contribution_kind : String
  input_packet_ids : Array[String]
  summary : String
  basis : Array[String]
  confidence : String
  privacy_label : String
  review_status : String
  idempotency_key : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingReductionResult {
  id : String
  building_id : String
  reduction_kind : String
  decision : String
  summary : String
  contribution_ids : Array[String]
  output_channel : String
  distribution_targets : Array[String]
  changed_pages : Array[String]
  accepted_records : Array[String]
  review_items : Array[String]
  review_status : String
  idempotency_key : String
  related_book_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingDistributionRecord {
  id : String
  building_id : String
  target_kind : String
  target_id : String
  target_path : String
  summary : String
  review_status : String
  idempotency_key : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingReviewGateRecord {
  id : String
  building_id : String
  gate : String
  status : String
  reason : String
  related_packet_id : String
  related_reduction_id : String
  owner : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingProtocolSnapshot {
  building_id : String
  title : String
  book_id : String
  protocol_mode : String
  persistence_mode : String
  social_responsibility : String
  status : String
  ready : Bool
  inbox_count : Int
  contribution_count : Int
  reduction_count : Int
  outbox_count : Int
  review_count : Int
  latest_reduction_summary : String
  latest_distribution_summary : String
  skill_packs : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingProtocolPortfolio {
  total : Int
  ready_count : Int
  active_count : Int
  review_count : Int
  blocked_count : Int
  status_path : String
  registry_path : String
  protocols : Array[BuildingProtocolSnapshot]
} derive(Debug, Eq, ToJson, FromJson)
