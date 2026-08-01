///|
fn channel_member(channel : Channel, principal_id : String) -> ChannelMember? {
  for participant in channel.members {
    if participant.principal_id == principal_id && participant.active {
      return Some(participant)
    }
  }
  None
}

///|
pub fn marketplace_can_read_channel(
  channel : Channel,
  principal : MarketplacePrincipal,
) -> Bool {
  if channel.visibility == PublicAnnouncementChannel {
    return true
  }
  channel_member(channel, principal.principal_id) is Some(_)
}

///|
pub fn marketplace_can_send_channel(
  channel : Channel,
  principal : MarketplacePrincipal,
) -> Bool {
  match channel_member(channel, principal.principal_id) {
    Some(participant) =>
      match participant.role {
        ChannelOwner | ChannelModerator | ChannelParticipant | ChannelAgent =>
          true
        ChannelObserver => false
      }
    None => false
  }
}

///|
fn channel_member_role_name(role : ChannelMemberRole) -> String {
  match role {
    ChannelOwner => "owner"
    ChannelModerator => "moderator"
    ChannelParticipant => "participant"
    ChannelObserver => "observer"
    ChannelAgent => "agent"
  }
}

///|
fn channel_visibility_name(visibility : ChannelVisibility) -> String {
  match visibility {
    DirectChannel => "direct"
    PrivateChannel => "private"
    WorkspaceChannel => "workspace"
    BuildingChannel => "building"
    AgentChannel => "agent"
    PublicAnnouncementChannel => "public_announcement"
  }
}

///|
fn channel_by_id(state : MarketplaceState, channel_id : String) -> Channel? {
  for channel in state.channels {
    if channel.channel_id == channel_id {
      return Some(channel)
    }
  }
  None
}

///|
fn validate_channel_members(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  members : Array[ChannelMember],
) -> Array[ChannelMember] raise {
  let normalized : Array[ChannelMember] = []
  let mut owner_seen = false
  for participant in members {
    if normalized.any(current => {
        current.principal_id == participant.principal_id
      }) {
      fail("channel members must be unique")
    }
    let target = principal_by_id(state, participant.principal_id).unwrap_or_else(() => {
        fail("channel member principal does not exist")
      },
    )
    if target.tenant_id != principal.tenant_id {
      fail("channel membership cannot cross tenant boundaries")
    }
    if participant.principal_id == principal.principal_id &&
      participant.role == ChannelOwner {
      owner_seen = true
    }
    normalized.push({
      ..participant,
      active: true,
      version: participant.version.max(1),
    })
  }
  if !owner_seen {
    fail("channel creator must be the channel owner")
  }
  normalized
}

///|
pub fn marketplace_create_channel(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  channel : Channel,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if !valid_symbolic_id(channel.channel_id) ||
    channel.owner_principal_id != principal.principal_id ||
    channel.tenant_id != principal.tenant_id ||
    state.channels.any(current => current.channel_id == channel.channel_id) {
    fail("invalid or duplicate channel")
  }
  let title = validate_public_text("channel title", channel.title, 120)
  let members = validate_channel_members(state, principal, channel.members)
  if !(channel.sensitivity == "public" ||
    channel.sensitivity == "internal" ||
    channel.sensitivity == "confidential" ||
    channel.sensitivity == "restricted") {
    fail("unknown channel sensitivity")
  }
  if (channel.visibility == PublicAnnouncementChannel) !=
    (channel.sensitivity == "public") {
    fail(
      "public announcement visibility requires public sensitivity and vice versa",
    )
  }
  if channel.visibility == DirectChannel && members.length() != 2 {
    fail("direct channels require exactly two active members")
  }
  if channel.visibility == WorkspaceChannel {
    guard channel.workspace_id is Some(workspace_id) &&
      principal.workspace_ids.contains(workspace_id) else {
      fail("workspace channels require a workspace owned by the creator")
    }
    for participant in members {
      let member_principal = principal_by_id(state, participant.principal_id).unwrap_or_else(() => {
          fail("workspace channel member does not exist")
        },
      )
      if !member_principal.workspace_ids.contains(workspace_id) {
        fail("every workspace channel member must belong to the workspace")
      }
    }
  }
  if channel.visibility == AgentChannel {
    guard channel.agent_listing_id is Some(agent_id) &&
      public_listing_by_ref(state, AgentListing, agent_id) is Some(_) &&
      channel.building_listing_id is None &&
      principal_can_bind_listing_channel(
        state, principal, "agent", agent_id, now_ms,
      ) else {
      fail("agent channels require one published agent listing")
    }
  } else if channel.visibility == BuildingChannel {
    guard channel.building_listing_id is Some(building_id) &&
      public_listing_by_ref(state, BuildingListing, building_id) is Some(_) &&
      channel.agent_listing_id is None &&
      principal_can_bind_listing_channel(
        state, principal, "building", building_id, now_ms,
      ) else {
      fail("building channels require one published building listing")
    }
  } else if channel.agent_listing_id is Some(_) ||
    channel.building_listing_id is Some(_) {
    fail("only agent or building channels may bind a listing")
  }
  let next = {
    ..channel,
    title,
    members,
    created_at_ms: now_ms,
    updated_at_ms: now_ms,
    version: 1,
  }
  { ..state, channels: state.channels + [next], version: state.version + 1 }
}

///|
fn audience_allows_reader(
  audience : MessageAudience,
  principal_id : String,
  sender_id : String,
) -> Bool {
  if principal_id == sender_id {
    return true
  }
  match audience {
    EntireChannel | PublicAudience => true
    NamedPrincipals(principals) => principals.contains(principal_id)
  }
}

///|
fn validate_message_audience(
  channel : Channel,
  message : ChannelMessage,
) -> Unit raise {
  match message.audience {
    EntireChannel => ()
    PublicAudience =>
      if channel.visibility != PublicAnnouncementChannel {
        fail("public audience is allowed only in public announcement channels")
      }
    NamedPrincipals(principals) => {
      if principals.is_empty() {
        fail("named message audience cannot be empty")
      }
      for principal_id in principals {
        if channel_member(channel, principal_id) is None {
          fail("named message audience must be a channel member")
        }
      }
    }
  }
}

///|
fn notification_for_message(
  message : ChannelMessage,
  channel_title : String,
  sender_label : String,
  principal_id : String,
  now_ms : UInt64,
) -> TownNotification {
  {
    notification_id: "message:\{message.message_id}:\{principal_id}",
    principal_id,
    kind: if message.mentions.contains(principal_id) {
      "mention"
    } else {
      "message"
    },
    title: if message.mentions.contains(principal_id) {
      "You were mentioned"
    } else {
      "New message"
    },
    summary: if message.mentions.contains(principal_id) {
      "\{sender_label} mentioned you in \{channel_title}"
    } else {
      "New message in \{channel_title} from \{sender_label}"
    },
    object_kind: "channel_message",
    object_id: message.message_id,
    created_at_ms: now_ms,
    read_at_ms: None,
    version: 1,
  }
}

///|
pub fn marketplace_send_message(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  message : ChannelMessage,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if !valid_symbolic_id(message.message_id) ||
    state.messages.any(current => current.message_id == message.message_id) ||
    message.sender_principal_id != principal.principal_id {
    fail("invalid, duplicate, or impersonated message")
  }
  let channel = channel_by_id(state, message.channel_id).unwrap_or_else(() => {
    fail("channel not found")
  })
  if !marketplace_can_send_channel(channel, principal) {
    fail("principal cannot send to this channel")
  }
  validate_message_audience(channel, message)
  let body = validate_public_text("message body", message.body, 8000)
  match message.reply_to_message_id {
    Some(reply_id) =>
      if !state.messages.any(candidate => {
          candidate.message_id == reply_id &&
          candidate.channel_id == message.channel_id
        }) {
        fail("reply target must exist in the same channel")
      }
    None => ()
  }
  validate_message_attachment_access(state, channel, principal, message, now_ms)
  for mentioned in message.mentions {
    if channel_member(channel, mentioned) is None {
      fail("mentions must name active channel members")
    }
  }
  let next_message = {
    ..message,
    body,
    created_at_ms: now_ms,
    edited_at_ms: None,
    version: 1,
  }
  let notifications = state.notifications.copy()
  let sender_label = principal.display_name
  for participant in channel.members {
    if participant.active &&
      participant.principal_id != principal.principal_id &&
      audience_allows_reader(
        next_message.audience,
        participant.principal_id,
        principal.principal_id,
      ) {
      notifications.push(
        notification_for_message(
          next_message,
          channel.title,
          sender_label,
          participant.principal_id,
          now_ms,
        ),
      )
    }
  }
  {
    ..state,
    messages: state.messages + [next_message],
    notifications,
    version: state.version + 1,
  }
}

///|
pub fn marketplace_visible_channels(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
) -> Array[Json] {
  let result : Array[Json] = []
  for channel in state.channels {
    if marketplace_can_read_channel(channel, principal) {
      let role = match channel_member(channel, principal.principal_id) {
        Some(participant) => channel_member_role_name(participant.role)
        None => "public_reader"
      }
      result.push({
        "channel_id": channel.channel_id,
        "title": channel.title,
        "visibility": channel_visibility_name(channel.visibility),
        "sensitivity": channel.sensitivity,
        "building_listing_id": optional_string_wire(channel.building_listing_id),
        "agent_listing_id": optional_string_wire(channel.agent_listing_id),
        "member_count": channel.members
        .filter(participant => participant.active)
        .length(),
        "my_role": role,
        "updated_at_ms": channel.updated_at_ms.to_string(),
      })
    }
  }
  result
}

///|
pub fn marketplace_visible_messages(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  channel_id : String,
) -> Array[Json] raise {
  let channel = channel_by_id(state, channel_id).unwrap_or_else(() => {
    fail("channel not found")
  })
  if !marketplace_can_read_channel(channel, principal) {
    fail("principal cannot read this channel")
  }
  let result : Array[Json] = []
  for message in state.messages {
    if message.channel_id == channel_id &&
      audience_allows_reader(
        message.audience,
        principal.principal_id,
        message.sender_principal_id,
      ) {
      result.push({
        "message_id": message.message_id,
        "channel_id": message.channel_id,
        "sender_principal_id": message.sender_principal_id,
        "body": message.body,
        "attachment_refs": message.attachment_refs.to_json(),
        "mentions": message.mentions.to_json(),
        "reply_to_message_id": optional_string_wire(message.reply_to_message_id),
        "created_at_ms": message.created_at_ms.to_string(),
        "version": message.version,
      })
    }
  }
  result
}

///|
fn principal_can_grant_resource(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
) -> Bool {
  match resource_kind {
    "agent" =>
      state.agent_listings.any(listing => {
        listing.listing_id == resource_id &&
        listing.publisher_id == principal.principal_id &&
        listing.tenant_id == principal.tenant_id &&
        listing.lifecycle.state != PublicationArchived
      })
    "building" =>
      state.building_listings.any(listing => {
        listing.listing_id == resource_id &&
        listing.publisher_id == principal.principal_id &&
        listing.tenant_id == principal.tenant_id &&
        listing.lifecycle.state != PublicationArchived
      })
    "channel" =>
      state.channels.any(channel => {
        channel.channel_id == resource_id &&
        channel.owner_principal_id == principal.principal_id
      })
    "artifact" =>
      artifact_reference_owner(resource_id) == Some(principal.principal_id)
    _ => false
  }
}

///|
fn grant_permission_allows(granted : String, required : String) -> Bool {
  granted == "collaborate" ||
  granted == required ||
  (granted == "message" && required == "view")
}

///|
fn share_grant_is_active(grant : ShareGrant, now_ms : UInt64) -> Bool {
  if grant.revoked_at_ms is Some(_) {
    return false
  }
  match grant.expires_at_ms {
    Some(expiry) => expiry > now_ms
    None => true
  }
}

///|
fn principal_has_active_share_grant(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
  required_permission : String,
  now_ms : UInt64,
) -> Bool {
  state.share_grants.any(grant => {
    grant.grantee_principal_id == principal.principal_id &&
    grant.tenant_id == principal.tenant_id &&
    grant.resource_kind == resource_kind &&
    grant.resource_id == resource_id &&
    share_grant_is_active(grant, now_ms) &&
    grant_permission_allows(grant.permission, required_permission)
  })
}

///|
fn listing_publisher_id(
  state : MarketplaceState,
  resource_kind : String,
  resource_id : String,
) -> String? {
  match resource_kind {
    "agent" => {
      for listing in state.agent_listings {
        if listing.listing_id == resource_id {
          return Some(listing.publisher_id)
        }
      }
      None
    }
    "building" => {
      for listing in state.building_listings {
        if listing.listing_id == resource_id {
          return Some(listing.publisher_id)
        }
      }
      None
    }
    _ => None
  }
}

///|
fn principal_can_bind_listing_channel(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
  now_ms : UInt64,
) -> Bool {
  listing_publisher_id(state, resource_kind, resource_id) ==
  Some(principal.principal_id) ||
  principal_has_active_share_grant(
    state, principal, resource_kind, resource_id, "message", now_ms,
  )
}

///| Artifact references are ownership-bearing symbolic references:

///|
/// `artifact:<owner-principal-id>:<artifact-id>`.
fn artifact_reference_owner(reference : String) -> String? {
  if !reference.has_prefix("artifact:") {
    return None
  }
  let remainder = reference[9:]
  match remainder.find(":") {
    Some(index) if index > 0 && index < remainder.length() - 1 => {
      let owner = remainder[:index].to_owned()
      if valid_symbolic_id(owner) {
        Some(owner)
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn attachment_resource(reference : String) -> (String, String)? {
  if reference.has_prefix("artifact:") {
    return if artifact_reference_owner(reference) is Some(_) {
      Some(("artifact", reference))
    } else {
      None
    }
  }
  match reference.find(":") {
    Some(index) if index > 0 && index < reference.length() - 1 => {
      let kind = reference[:index].to_owned()
      let resource_id = reference[index + 1:].to_owned()
      if (kind == "agent" || kind == "building" || kind == "channel") &&
        valid_symbolic_id(resource_id) {
        Some((kind, resource_id))
      } else {
        None
      }
    }
    _ => None
  }
}

///|
fn principal_can_view_resource(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
  now_ms : UInt64,
) -> Bool {
  if principal_has_active_share_grant(
      state, principal, resource_kind, resource_id, "view", now_ms,
    ) {
    return true
  }
  match resource_kind {
    "agent" =>
      public_listing_by_ref(state, AgentListing, resource_id) is Some(_) ||
      listing_publisher_id(state, resource_kind, resource_id) ==
      Some(principal.principal_id)
    "building" =>
      public_listing_by_ref(state, BuildingListing, resource_id) is Some(_) ||
      listing_publisher_id(state, resource_kind, resource_id) ==
      Some(principal.principal_id)
    "channel" =>
      match channel_by_id(state, resource_id) {
        Some(target) => marketplace_can_read_channel(target, principal)
        None => false
      }
    "artifact" =>
      artifact_reference_owner(resource_id) == Some(principal.principal_id)
    _ => false
  }
}

///|
fn validate_message_attachment_access(
  state : MarketplaceState,
  channel : Channel,
  sender : MarketplacePrincipal,
  message : ChannelMessage,
  now_ms : UInt64,
) -> Unit raise {
  for reference in message.attachment_refs {
    let (resource_kind, resource_id) = attachment_resource(reference).unwrap_or_else(() => {
        fail("attachment reference has no supported ownership type")
      },
    )
    if !principal_can_view_resource(
        state, sender, resource_kind, resource_id, now_ms,
      ) {
      fail("sender is not authorized to attach this resource")
    }
    if message.audience == PublicAudience {
      if !((
          resource_kind == "agent" &&
          public_listing_by_ref(state, AgentListing, resource_id) is Some(_)
        ) ||
        (
          resource_kind == "building" &&
          public_listing_by_ref(state, BuildingListing, resource_id) is Some(_)
        )) {
        fail("public messages may attach only published listings")
      }
      continue
    }
    for participant in channel.members {
      if participant.active &&
        participant.principal_id != sender.principal_id &&
        audience_allows_reader(
          message.audience,
          participant.principal_id,
          sender.principal_id,
        ) {
        let recipient = principal_by_id(state, participant.principal_id).unwrap_or_else(() => {
            fail("attachment recipient does not exist")
          },
        )
        if !principal_can_view_resource(
            state, recipient, resource_kind, resource_id, now_ms,
          ) {
          fail("attachment recipient lacks an active view grant")
        }
      }
    }
  }
}

///|
fn mark_listing_shared_for_grant(
  state : MarketplaceState,
  grant : ShareGrant,
  now_ms : UInt64,
) -> MarketplaceState {
  if grant.resource_kind == "agent" {
    return {
      ..state,
      agent_listings: state.agent_listings.map(listing => {
        if listing.listing_id == grant.resource_id &&
          listing.tenant_id == grant.tenant_id &&
          listing.lifecycle.state == PublicationDraft {
          {
            ..listing,
            lifecycle: {
              ..listing.lifecycle,
              state: PublicationShared,
              shared_at_ms: Some(now_ms),
            },
            updated_at_ms: now_ms,
            version: listing.version + 1,
          }
        } else {
          listing
        }
      }),
    }
  }
  if grant.resource_kind == "building" {
    return {
      ..state,
      building_listings: state.building_listings.map(listing => {
        if listing.listing_id == grant.resource_id &&
          listing.tenant_id == grant.tenant_id &&
          listing.lifecycle.state == PublicationDraft {
          {
            ..listing,
            lifecycle: {
              ..listing.lifecycle,
              state: PublicationShared,
              shared_at_ms: Some(now_ms),
            },
            updated_at_ms: now_ms,
            version: listing.version + 1,
          }
        } else {
          listing
        }
      }),
    }
  }
  state
}

///|
pub fn marketplace_create_share_grant(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  grant : ShareGrant,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let grantee = principal_by_id(state, grant.grantee_principal_id)
  if !valid_symbolic_id(grant.grant_id) ||
    grant.grantor_principal_id != principal.principal_id ||
    grant.tenant_id != principal.tenant_id ||
    grantee is None ||
    grantee.unwrap().tenant_id != principal.tenant_id ||
    !principal_can_grant_resource(
      state,
      principal,
      grant.resource_kind,
      grant.resource_id,
    ) ||
    !(grant.permission == "view" ||
    grant.permission == "message" ||
    grant.permission == "collaborate") {
    fail("invalid or unauthorized share grant")
  }
  match grant.expires_at_ms {
    Some(expiry) =>
      if expiry <= now_ms {
        fail("share grant expiry must be in the future")
      }
    None => ()
  }
  let mut next_version = 1
  for current in state.share_grants {
    if current.grant_id == grant.grant_id {
      if current.grantor_principal_id != principal.principal_id ||
        current.tenant_id != principal.tenant_id ||
        current.revoked_at_ms is Some(_) {
        fail("grant_id cannot overwrite or reactivate another grant")
      }
      next_version = current.version + 1
    }
  }
  let grants = state.share_grants.filter(current => {
    current.grant_id != grant.grant_id
  })
  grants.push({
    ..grant,
    created_at_ms: now_ms,
    revoked_at_ms: None,
    version: next_version,
  })
  mark_listing_shared_for_grant(
    { ..state, share_grants: grants, version: state.version + 1 },
    grant,
    now_ms,
  )
}

///|
fn private_listing_share_projection(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
) -> Json? {
  match resource_kind {
    "agent" => {
      for listing in state.agent_listings {
        if listing.listing_id == resource_id &&
          listing.tenant_id == principal.tenant_id &&
          listing.lifecycle.state != PublicationPublished &&
          listing.lifecycle.state != PublicationArchived {
          return safe_private_listing_share_projection(
            state,
            AgentListing,
            resource_id,
          )
        }
      }
      None
    }
    "building" => {
      for listing in state.building_listings {
        if listing.listing_id == resource_id &&
          listing.tenant_id == principal.tenant_id &&
          listing.lifecycle.state != PublicationPublished &&
          listing.lifecycle.state != PublicationArchived {
          return safe_private_listing_share_projection(
            state,
            BuildingListing,
            resource_id,
          )
        }
      }
      None
    }
    _ => None
  }
}

///| Return only allowlisted card data for non-public listings shared with the

///|
/// principal by an active grant. Expired and revoked grants fail closed.
pub fn marketplace_shared_listing_cards(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  now_ms~ : UInt64,
) -> Array[Json] {
  let registered = match principal_by_id(state, principal.principal_id) {
    Some(value) if value.tenant_id == principal.tenant_id => value
    _ => return []
  }
  let cards : Array[Json] = []
  let seen : Array[String] = []
  for grant in state.share_grants {
    if grant.grantee_principal_id == registered.principal_id &&
      grant.tenant_id == registered.tenant_id &&
      share_grant_is_active(grant, now_ms) &&
      grant_permission_allows(grant.permission, "view") {
      let key = "\{grant.resource_kind}:\{grant.resource_id}"
      if !seen.contains(key) {
        match
          private_listing_share_projection(
            state,
            registered,
            grant.resource_kind,
            grant.resource_id,
          ) {
          Some(card) => {
            seen.push(key)
            cards.push(card)
          }
          None => ()
        }
      }
    }
  }
  cards
}

///|
fn restore_listing_draft_after_last_grant(
  state : MarketplaceState,
  revoked_grant : ShareGrant,
  now_ms : UInt64,
) -> MarketplaceState {
  let still_shared = state.share_grants.any(grant => {
    grant.tenant_id == revoked_grant.tenant_id &&
    grant.resource_kind == revoked_grant.resource_kind &&
    grant.resource_id == revoked_grant.resource_id &&
    share_grant_is_active(grant, now_ms) &&
    grant_permission_allows(grant.permission, "view")
  })
  if still_shared {
    return state
  }
  if revoked_grant.resource_kind == "agent" {
    return {
      ..state,
      agent_listings: state.agent_listings.map(listing => {
        if listing.listing_id == revoked_grant.resource_id &&
          listing.tenant_id == revoked_grant.tenant_id &&
          listing.lifecycle.state == PublicationShared {
          {
            ..listing,
            lifecycle: {
              ..listing.lifecycle,
              state: PublicationDraft,
              shared_at_ms: None,
            },
            updated_at_ms: now_ms,
            version: listing.version + 1,
          }
        } else {
          listing
        }
      }),
    }
  }
  if revoked_grant.resource_kind == "building" {
    return {
      ..state,
      building_listings: state.building_listings.map(listing => {
        if listing.listing_id == revoked_grant.resource_id &&
          listing.tenant_id == revoked_grant.tenant_id &&
          listing.lifecycle.state == PublicationShared {
          {
            ..listing,
            lifecycle: {
              ..listing.lifecycle,
              state: PublicationDraft,
              shared_at_ms: None,
            },
            updated_at_ms: now_ms,
            version: listing.version + 1,
          }
        } else {
          listing
        }
      }),
    }
  }
  state
}

///| Revoke a grant without deleting its audit record. Only the original

///|
/// grantor may revoke it.
pub fn marketplace_revoke_share_grant(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  grant_id : String,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let grants : Array[ShareGrant] = []
  let mut revoked : ShareGrant? = None
  for grant in state.share_grants {
    if grant.grant_id == grant_id {
      if grant.grantor_principal_id != principal.principal_id ||
        grant.tenant_id != principal.tenant_id ||
        grant.revoked_at_ms is Some(_) {
        fail("share grant cannot be revoked by this principal")
      }
      let next = {
        ..grant,
        revoked_at_ms: Some(now_ms),
        version: grant.version + 1,
      }
      revoked = Some(next)
      grants.push(next)
    } else {
      grants.push(grant)
    }
  }
  let revoked_grant = revoked.unwrap_or_else(() => fail("share grant not found"))
  restore_listing_draft_after_last_grant(
    { ..state, share_grants: grants, version: state.version + 1 },
    revoked_grant,
    now_ms,
  )
}

///|
/// Preview exactly the safe data the grantee will receive before sharing.
pub fn marketplace_share_preview(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  resource_kind : String,
  resource_id : String,
  grantee_principal_id : String,
) -> Json raise {
  if !principal_can_grant_resource(state, principal, resource_kind, resource_id) {
    fail("share preview is not authorized")
  }
  if !grantee_principal_id.is_empty() {
    let grantee = principal_by_id(state, grantee_principal_id).unwrap_or_else(() => {
      fail("share preview grantee does not exist")
    })
    if grantee.tenant_id != principal.tenant_id {
      fail("share preview cannot cross tenant boundaries")
    }
  }
  let projection : Json? = match resource_kind {
    "agent" =>
      match public_listing_by_ref(state, AgentListing, resource_id) {
        Some(value) => Some(value)
        None =>
          safe_private_listing_share_projection(
            state,
            AgentListing,
            resource_id,
          )
      }
    "building" =>
      match public_listing_by_ref(state, BuildingListing, resource_id) {
        Some(value) => Some(value)
        None =>
          safe_private_listing_share_projection(
            state,
            BuildingListing,
            resource_id,
          )
      }
    "channel" =>
      match channel_by_id(state, resource_id) {
        Some(channel) =>
          Some({
            "contract_id": "moontown.shared-channel-preview.v1",
            "channel_id": channel.channel_id,
            "title": channel.title,
            "sensitivity": channel.sensitivity,
          })
        None => None
      }
    _ => None
  }
  {
    "contract_id": "moontown.share-preview.v1",
    "resource_kind": resource_kind,
    "resource_id": resource_id,
    "grantee_principal_id": if grantee_principal_id.is_empty() {
      Json::null()
    } else {
      grantee_principal_id.to_json()
    },
    "projection": projection.unwrap_or_else(() => {
      fail("resource has no safe share projection")
    }),
    "excluded_fields": [
      "raw_memory", "credentials", "paths", "authority_envelopes", "consent", "private_evidence",
    ],
  }
}
