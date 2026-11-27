///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappPublicationPolicy {
  required_capabilities : Array[String]
  allowed_category_ids : Array[String]
  allowed_asset_refs : Array[String]
  banned_terms : Array[String]
  max_tags : Int32
  max_summary_chars : Int32
  min_summary_chars : Int32
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappPublicationRequest {
  building_id : String
  public_summary : String
  category_id : String
  asset_refs : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappPublicationValidation {
  ok : Bool
  building_id : String
  issues : Array[String]
  warnings : Array[String]
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) enum MiniappModerationDecision {
  ApprovePublication
  RejectPublication(String)
  HidePublished(String)
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappModerationChange {
  ok : Bool
  snapshot : @miniapp_contracts.MiniappTownSnapshot
  building_id : String
  message : String
  validation : MiniappPublicationValidation
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappDiscoveryFilter {
  query : String
  tag : String?
  category_id : String?
  owner_id : String?
  capability : String?
  min_updated_at_ms : UInt64?
}

///|
#derive(Debug, Eq, ToJson, FromJson)
pub(all) struct MiniappPublicBuildingPreview {
  building_id : String
  title : String
  owner_id : String
  owner_label : String
  category_id : String
  summary : String
  tags : Array[String]
  capabilities : Array[String]
  book_summary : String
  score : Int32
  reason : String
  can_place : Bool
}
