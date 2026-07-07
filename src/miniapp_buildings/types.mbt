///|
pub(all) struct MiniappBuildingDraft {
  id : String
  kind : @miniapp_contracts.MiniappBuildingKind
  title : String
  summary : String
  workspace_id : String
  tags : Array[String]
  capabilities : Array[String]
  primary_book_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingPatch {
  title : String?
  summary : String?
  tags : Array[String]?
  capabilities : Array[String]?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingShareGrant {
  subject_kind : String
  subject_id : String
  role : @miniapp_contracts.MiniappPermissionRole
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappPlacementDraft {
  id : String
  building_id : String
  layer_id : String
  x : Int
  y : Int
  region_id : String
  pinned : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappPublishAction {
  SubmitForPublish
  ApprovePublish
  RejectPublish(String)
  ArchiveBuilding
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingSearchFilter {
  query : String
  tag : String?
  capability : String?
  owner_id : String?
  visibility : @miniapp_contracts.MiniappVisibilityState?
  layer_id : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingChange {
  ok : Bool
  snapshot : @miniapp_contracts.MiniappTownSnapshot
  message : String
  building_id : String
  placement_id : String?
} derive(Debug, Eq, ToJson, FromJson)
