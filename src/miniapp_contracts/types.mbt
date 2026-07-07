///|
pub(all) enum MiniappOwnerKind {
  UserOwner
  OrganizationOwner
  SystemOwner
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappVisibilityState {
  PrivateDraft
  SharedPrivate
  SubmittedForPublish
  Published
  Archived
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappScope {
  PersonalScope
  TeamScope
  TownPublicScope
  SystemPublicScope
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappPermissionRole {
  OwnerRole
  EditorRole
  ViewerRole
  PublisherRole
  AdminRole
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappRunStatus {
  RunPending
  RunRunning
  RunWaitingReview
  RunDone
  RunFailed
  RunCancelled
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MiniappBuildingKind {
  AgentLab
  PolicyHall
  KnowledgeHouse
  ProjectStudio
  MarketSquare
  ReviewCouncil
  SystemGateway
  CustomBuilding(String)
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappUser {
  id : String
  display_name : String
  avatar_url : String?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappSession {
  id : String
  user_id : String
  token_label : String
  expires_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappOrganization {
  id : String
  name : String
  owner_user_id : String
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappWorkspace {
  id : String
  owner_kind : MiniappOwnerKind
  owner_id : String
  name : String
  scope : MiniappScope
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappPermission {
  subject_kind : String
  subject_id : String
  role : MiniappPermissionRole
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappTownLayer {
  id : String
  title : String
  scope : MiniappScope
  owner_kind : MiniappOwnerKind
  owner_id : String
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingPublication {
  state : MiniappVisibilityState
  submitted_at_ms : UInt64?
  published_at_ms : UInt64?
  review_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBookSummary {
  id : String
  title : String
  summary : String
  visibility : MiniappVisibilityState
  accepted_memory_count : Int
  pending_review_count : Int
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuilding {
  id : String
  kind : MiniappBuildingKind
  title : String
  summary : String
  owner_kind : MiniappOwnerKind
  owner_id : String
  workspace_id : String
  visibility : MiniappVisibilityState
  scope : MiniappScope
  tags : Array[String]
  capabilities : Array[String]
  primary_book_id : String
  publication : MiniappBuildingPublication
  version : Int
  updated_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappBuildingPlacement {
  id : String
  building_id : String
  layer_id : String
  x : Int
  y : Int
  region_id : String
  pinned : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappAgent {
  id : String
  display_name : String
  owner_kind : MiniappOwnerKind
  owner_id : String
  building_id : String?
  capabilities : Array[String]
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappThread {
  id : String
  building_id : String
  title : String
  message_count : Int
  unread_count : Int
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappMessage {
  id : String
  thread_id : String
  actor_id : String
  actor_label : String
  body : String
  created_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappRun {
  id : String
  user_id : String
  building_id : String
  book_id : String
  agent_id : String?
  thread_id : String
  status : MiniappRunStatus
  summary : String
  created_at_ms : UInt64
  updated_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappAuditEvent {
  id : String
  actor_user_id : String
  object_kind : String
  object_id : String
  action : String
  summary : String
  created_at_ms : UInt64
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappTownSnapshot {
  id : String
  user : MiniappUser
  workspace : MiniappWorkspace
  layers : Array[MiniappTownLayer]
  buildings : Array[MiniappBuilding]
  placements : Array[MiniappBuildingPlacement]
  books : Array[MiniappBookSummary]
  agents : Array[MiniappAgent]
  threads : Array[MiniappThread]
  messages : Array[MiniappMessage]
  runs : Array[MiniappRun]
  permissions : Array[MiniappPermission]
  audit_events : Array[MiniappAuditEvent]
  generated_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MiniappSearchResult {
  building : MiniappBuilding
  placement : MiniappBuildingPlacement?
  book : MiniappBookSummary
  score : Int
  reason : String
} derive(Debug, Eq, ToJson, FromJson)
