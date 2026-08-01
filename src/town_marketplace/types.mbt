///|
pub(all) enum PublicationState {
  PublicationDraft
  PublicationShared
  PublicationSubmitted
  PublicationPublished
  PublicationArchived
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ListingKind {
  AgentListing
  BuildingListing
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ChannelVisibility {
  DirectChannel
  PrivateChannel
  WorkspaceChannel
  BuildingChannel
  AgentChannel
  PublicAnnouncementChannel
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum ChannelMemberRole {
  ChannelOwner
  ChannelModerator
  ChannelParticipant
  ChannelObserver
  ChannelAgent
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) enum MessageAudience {
  EntireChannel
  NamedPrincipals(Array[String])
  PublicAudience
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MarketplacePrincipal {
  principal_id : String
  tenant_id : String
  display_name : String
  workspace_ids : Array[String]
  roles : Array[String]
  interest_tags : Array[String]
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// The durable store contains only the digest of an opaque session token.
pub(all) struct MarketplaceSession {
  session_id : String
  token_digest : String
  principal_id : String
  expires_at_ms : UInt64
  revoked : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct PublicationLifecycle {
  state : PublicationState
  shared_at_ms : UInt64?
  submitted_at_ms : UInt64?
  published_at_ms : UInt64?
  archived_at_ms : UInt64?
  reviewed_by : String?
  review_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///| Publishable agent metadata. It intentionally has no runtime memory,

///|
/// credentials, authority envelope, raw evidence, path, or consent fields.
pub(all) struct AgentListingRecord {
  listing_id : String
  publisher_id : String
  tenant_id : String
  title : String
  summary : String
  image_ref : String
  capabilities : Array[String]
  tags : Array[String]
  action_ids : Array[String]
  required_permissions : Array[String]
  pricing_summary : String
  authority_ceiling : String
  license_class : String
  rights_summary : String
  version_label : String
  quality_score : Int
  reliability_score : Int
  content_digest : String
  lifecycle : PublicationLifecycle
  updated_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///| Publishable building metadata. Private MoonBook contents and workspace

///|
/// internals never appear in this record or its public projection.
pub(all) struct BuildingListingRecord {
  listing_id : String
  publisher_id : String
  tenant_id : String
  title : String
  summary : String
  image_ref : String
  capabilities : Array[String]
  tags : Array[String]
  action_ids : Array[String]
  pricing_summary : String
  license_class : String
  rights_summary : String
  version_label : String
  quality_score : Int
  reliability_score : Int
  content_digest : String
  lifecycle : PublicationLifecycle
  updated_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ChannelMember {
  principal_id : String
  role : ChannelMemberRole
  joined_at_ms : UInt64
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Channel {
  channel_id : String
  tenant_id : String
  workspace_id : String?
  building_listing_id : String?
  agent_listing_id : String?
  owner_principal_id : String
  title : String
  visibility : ChannelVisibility
  sensitivity : String
  members : Array[ChannelMember]
  created_at_ms : UInt64
  updated_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ChannelMessage {
  message_id : String
  channel_id : String
  sender_principal_id : String
  body : String
  attachment_refs : Array[String]
  mentions : Array[String]
  audience : MessageAudience
  reply_to_message_id : String?
  created_at_ms : UInt64
  edited_at_ms : UInt64?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ShareGrant {
  grant_id : String
  tenant_id : String
  resource_kind : String
  resource_id : String
  grantor_principal_id : String
  grantee_principal_id : String
  permission : String
  created_at_ms : UInt64
  expires_at_ms : UInt64?
  revoked_at_ms : UInt64?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Subscription {
  subscription_id : String
  principal_id : String
  topic_kind : String
  topic_id : String
  enabled : Bool
  created_at_ms : UInt64
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct TownNotification {
  notification_id : String
  principal_id : String
  kind : String
  title : String
  summary : String
  object_kind : String
  object_id : String
  created_at_ms : UInt64
  read_at_ms : UInt64?
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///| Paid distribution is deliberately modeled separately from both the

///|
/// organic search index and recommendation score.
pub(all) struct SponsoredPlacement {
  placement_id : String
  sponsor_principal_id : String
  listing_kind : ListingKind
  listing_id : String
  label : String
  why_shown : String
  interest_tags : Array[String]
  starts_at_ms : UInt64
  ends_at_ms : UInt64
  active : Bool
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MarketplaceState {
  schema : String
  principals : Array[MarketplacePrincipal]
  sessions : Array[MarketplaceSession]
  agent_listings : Array[AgentListingRecord]
  building_listings : Array[BuildingListingRecord]
  channels : Array[Channel]
  messages : Array[ChannelMessage]
  share_grants : Array[ShareGrant]
  subscriptions : Array[Subscription]
  notifications : Array[TownNotification]
  sponsored_placements : Array[SponsoredPlacement]
  version : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct AgentListingDraft {
  listing_id : String
  title : String
  summary : String
  image_ref : String
  capabilities : Array[String]
  tags : Array[String]
  action_ids : Array[String]
  required_permissions : Array[String]
  pricing_summary : String
  authority_ceiling : String
  license_class : String
  rights_summary : String
  version_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct BuildingListingDraft {
  listing_id : String
  title : String
  summary : String
  image_ref : String
  capabilities : Array[String]
  tags : Array[String]
  action_ids : Array[String]
  pricing_summary : String
  license_class : String
  rights_summary : String
  version_label : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Recommendation {
  listing : Json
  score : Int
  reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MarketplaceApplication {
  state_path : String
  bootstrap_principal : MarketplacePrincipal
  bootstrap_session_id : String
  bootstrap_token_digest : String
} derive(Debug, Eq)
