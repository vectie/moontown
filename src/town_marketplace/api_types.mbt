///|
pub(all) struct ListingTransitionDraft {
  listing_id : String
  listing_kind : String
  target_state : String
  review_summary : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ListingActionDraft {
  listing_id : String
  listing_kind : String
  action_id : String
  message : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ChannelDraft {
  channel_id : String
  title : String
  visibility : String
  sensitivity : String
  workspace_id : String?
  building_listing_id : String?
  agent_listing_id : String?
  member_principal_ids : Array[String]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct MessageDraft {
  message_id : String
  channel_id : String
  body : String
  attachment_refs : Array[String]
  mentions : Array[String]
  audience_principal_ids : Array[String]
  public_audience : Bool
  reply_to_message_id : String?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct NotificationReadDraft {
  notification_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SubscriptionDraft {
  subscription_id : String
  topic_kind : String
  topic_id : String
  enabled : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ShareGrantDraft {
  grant_id : String
  resource_kind : String
  resource_id : String
  grantee_principal_id : String
  permission : String
  expires_at_ms : UInt64?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct ShareGrantRevokeDraft {
  grant_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SharePreviewDraft {
  resource_kind : String
  resource_id : String
  grantee_principal_id : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct SponsoredPlacementDraft {
  placement_id : String
  listing_kind : String
  listing_id : String
  why_shown : String
  interest_tags : Array[String]
  starts_at_ms : UInt64
  ends_at_ms : UInt64
  active : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
fn parse_listing_kind(value : String) -> ListingKind raise {
  match value.trim().to_owned().to_lower() {
    "agent" => AgentListing
    "building" => BuildingListing
    _ => fail("listing_kind must be agent or building")
  }
}

///|
fn parse_publication_state(value : String) -> PublicationState raise {
  match value.trim().to_owned().to_lower() {
    "draft" => PublicationDraft
    "shared" => PublicationShared
    "submitted" => PublicationSubmitted
    "published" => PublicationPublished
    "archived" => PublicationArchived
    _ => fail("unknown publication target_state")
  }
}

///|
fn parse_channel_visibility(value : String) -> ChannelVisibility raise {
  match value.trim().to_owned().to_lower() {
    "direct" => DirectChannel
    "private" => PrivateChannel
    "workspace" => WorkspaceChannel
    "building" => BuildingChannel
    "agent" => AgentChannel
    "public_announcement" => PublicAnnouncementChannel
    _ => fail("unknown channel visibility")
  }
}

///|
fn api_object(payload : Json) -> Map[String, Json] raise {
  match payload {
    Object(fields) => fields
    _ => fail("marketplace payload must be a JSON object")
  }
}

///|
fn api_string(fields : Map[String, Json], key : String) -> String {
  match fields.get(key) {
    Some(String(value)) => value.trim().to_owned()
    _ => ""
  }
}

///|
fn api_string_array(fields : Map[String, Json], key : String) -> Array[String] {
  match fields.get(key) {
    Some(Array(values)) =>
      values.filter_map(value => {
        match value {
          String(text) => Some(text.trim().to_owned())
          _ => None
        }
      })
    _ => []
  }
}

///|
fn api_bool(fields : Map[String, Json], key : String) -> Bool {
  match fields.get(key) {
    Some(True) => true
    _ => false
  }
}

///| External wire options use a direct scalar or null/missing, never MoonBit's

///|
/// derived one-element-array representation.
fn api_optional_string(fields : Map[String, Json], key : String) -> String? {
  match fields.get(key) {
    Some(String(value)) if !value.trim().is_empty() =>
      Some(value.trim().to_owned())
    _ => None
  }
}

///|
fn api_optional_uint64(fields : Map[String, Json], key : String) -> UInt64? {
  match fields.get(key) {
    Some(Number(value, ..)) => Some(value.to_uint64())
    _ => None
  }
}

///|
fn parse_channel_draft(payload : Json) -> ChannelDraft raise {
  let fields = api_object(payload)
  {
    channel_id: api_string(fields, "channel_id"),
    title: api_string(fields, "title"),
    visibility: api_string(fields, "visibility"),
    sensitivity: api_string(fields, "sensitivity"),
    workspace_id: api_optional_string(fields, "workspace_id"),
    building_listing_id: api_optional_string(fields, "building_listing_id"),
    agent_listing_id: api_optional_string(fields, "agent_listing_id"),
    member_principal_ids: api_string_array(fields, "member_principal_ids"),
  }
}

///|
fn parse_message_draft(payload : Json) -> MessageDraft raise {
  let fields = api_object(payload)
  {
    message_id: api_string(fields, "message_id"),
    channel_id: api_string(fields, "channel_id"),
    body: api_string(fields, "body"),
    attachment_refs: api_string_array(fields, "attachment_refs"),
    mentions: api_string_array(fields, "mentions"),
    audience_principal_ids: api_string_array(fields, "audience_principal_ids"),
    public_audience: api_bool(fields, "public_audience"),
    reply_to_message_id: api_optional_string(fields, "reply_to_message_id"),
  }
}

///|
fn parse_share_grant_draft(payload : Json) -> ShareGrantDraft raise {
  let fields = api_object(payload)
  {
    grant_id: api_string(fields, "grant_id"),
    resource_kind: api_string(fields, "resource_kind"),
    resource_id: api_string(fields, "resource_id"),
    grantee_principal_id: api_string(fields, "grantee_principal_id"),
    permission: api_string(fields, "permission"),
    expires_at_ms: api_optional_uint64(fields, "expires_at_ms"),
  }
}

///|
fn parse_share_preview_draft(payload : Json) -> SharePreviewDraft raise {
  let fields = api_object(payload)
  {
    resource_kind: api_string(fields, "resource_kind"),
    resource_id: api_string(fields, "resource_id"),
    grantee_principal_id: api_string(fields, "grantee_principal_id"),
  }
}
