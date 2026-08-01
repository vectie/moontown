///|
fn validate_public_common(
  listing_id : String,
  title : String,
  summary : String,
  image_ref : String,
  capabilities : Array[String],
  tags : Array[String],
  action_ids : Array[String],
  license_class : String,
  rights_summary : String,
  version_label : String,
) -> Unit raise {
  if !valid_symbolic_id(listing_id) {
    fail("listing_id must be symbolic")
  }
  ignore(validate_public_text("title", title, 120))
  ignore(validate_public_text("summary", summary, 1000))
  ignore(validate_public_text("image_ref", image_ref, 500))
  if normalized_terms(capabilities).is_empty() ||
    normalized_terms(tags).is_empty() ||
    normalized_terms(action_ids).is_empty() {
    fail("capabilities, tags, and action_ids are required")
  }
  ignore(validate_public_text("license_class", license_class, 80))
  ignore(validate_public_text("rights_summary", rights_summary, 400))
  ignore(validate_public_text("version_label", version_label, 40))
  for capability in capabilities {
    ignore(validate_public_text("capability", capability, 80))
  }
  for tag in tags {
    ignore(validate_public_text("tag", tag, 80))
  }
  for action_id in action_ids {
    ignore(validate_public_text("action_id", action_id, 80))
    if !supported_listing_action_id(action_id) {
      fail("unsupported public listing action_id")
    }
  }
}

///| Public actions are a closed vocabulary. Each identifier has a defined UI

///| meaning; executable work still requires a separate, accepted MoonClaw

///|
/// authority handoff rather than treating this card field as a command.
fn supported_listing_action_id(value : String) -> Bool {
  match value.trim().to_owned().to_lower() {
    "follow"
    | "message"
    | "try"
    | "visit"
    | "request_access"
    | "install"
    | "invite"
    | "share" => true
    _ => false
  }
}

///|
pub fn marketplace_upsert_agent_draft(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : AgentListingDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if state.building_listings.any(listing => {
      listing.listing_id == draft.listing_id
    }) {
    fail("listing_id is already used by a building")
  }
  validate_public_common(
    draft.listing_id,
    draft.title,
    draft.summary,
    draft.image_ref,
    draft.capabilities,
    draft.tags,
    draft.action_ids,
    draft.license_class,
    draft.rights_summary,
    draft.version_label,
  )
  ignore(validate_public_text("pricing_summary", draft.pricing_summary, 300))
  ignore(
    validate_public_text("authority_ceiling", draft.authority_ceiling, 120),
  )
  for permission in draft.required_permissions {
    ignore(validate_public_text("required_permission", permission, 120))
  }
  let listings : Array[AgentListingRecord] = []
  let mut prior : AgentListingRecord? = None
  for current in state.agent_listings {
    if current.listing_id == draft.listing_id {
      prior = Some(current)
    } else {
      listings.push(current)
    }
  }
  let (lifecycle, version, quality, reliability) = match prior {
    Some(current) => {
      if current.publisher_id != principal.principal_id ||
        current.tenant_id != principal.tenant_id {
        fail("only the listing publisher can edit this draft")
      }
      if current.lifecycle.state == PublicationPublished {
        fail(
          "published listings are immutable; archive or version a new listing",
        )
      }
      (
        current.lifecycle,
        current.version + 1,
        current.quality_score,
        current.reliability_score,
      )
    }
    None => (publication_lifecycle_draft(), 1, 0, 0)
  }
  let normalized_draft = {
    ..draft,
    listing_id: draft.listing_id.trim().to_owned(),
    title: draft.title.trim().to_owned(),
    summary: draft.summary.trim().to_owned(),
    capabilities: normalized_terms(draft.capabilities),
    tags: normalized_terms(draft.tags),
    action_ids: normalized_terms(draft.action_ids),
    required_permissions: normalized_terms(draft.required_permissions),
  }
  listings.push({
    listing_id: normalized_draft.listing_id,
    publisher_id: principal.principal_id,
    tenant_id: principal.tenant_id,
    title: normalized_draft.title,
    summary: normalized_draft.summary,
    image_ref: normalized_draft.image_ref.trim().to_owned(),
    capabilities: normalized_draft.capabilities,
    tags: normalized_draft.tags,
    action_ids: normalized_draft.action_ids,
    required_permissions: normalized_draft.required_permissions,
    pricing_summary: normalized_draft.pricing_summary.trim().to_owned(),
    authority_ceiling: normalized_draft.authority_ceiling.trim().to_owned(),
    license_class: normalized_draft.license_class.trim().to_owned(),
    rights_summary: normalized_draft.rights_summary.trim().to_owned(),
    version_label: normalized_draft.version_label.trim().to_owned(),
    quality_score: quality,
    reliability_score: reliability,
    content_digest: agent_listing_digest(normalized_draft),
    lifecycle,
    updated_at_ms: now_ms,
    version,
  })
  { ..state, agent_listings: listings, version: state.version + 1 }
}

///|
pub fn marketplace_upsert_building_draft(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  draft : BuildingListingDraft,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  if state.agent_listings.any(listing => listing.listing_id == draft.listing_id) {
    fail("listing_id is already used by an agent")
  }
  validate_public_common(
    draft.listing_id,
    draft.title,
    draft.summary,
    draft.image_ref,
    draft.capabilities,
    draft.tags,
    draft.action_ids,
    draft.license_class,
    draft.rights_summary,
    draft.version_label,
  )
  ignore(validate_public_text("pricing_summary", draft.pricing_summary, 300))
  let listings : Array[BuildingListingRecord] = []
  let mut prior : BuildingListingRecord? = None
  for current in state.building_listings {
    if current.listing_id == draft.listing_id {
      prior = Some(current)
    } else {
      listings.push(current)
    }
  }
  let (lifecycle, version, quality, reliability) = match prior {
    Some(current) => {
      if current.publisher_id != principal.principal_id ||
        current.tenant_id != principal.tenant_id {
        fail("only the building publisher can edit this draft")
      }
      if current.lifecycle.state == PublicationPublished {
        fail(
          "published buildings are immutable; archive or version a new listing",
        )
      }
      (
        current.lifecycle,
        current.version + 1,
        current.quality_score,
        current.reliability_score,
      )
    }
    None => (publication_lifecycle_draft(), 1, 0, 0)
  }
  let normalized_draft = {
    ..draft,
    listing_id: draft.listing_id.trim().to_owned(),
    title: draft.title.trim().to_owned(),
    summary: draft.summary.trim().to_owned(),
    capabilities: normalized_terms(draft.capabilities),
    tags: normalized_terms(draft.tags),
    action_ids: normalized_terms(draft.action_ids),
  }
  listings.push({
    listing_id: normalized_draft.listing_id,
    publisher_id: principal.principal_id,
    tenant_id: principal.tenant_id,
    title: normalized_draft.title,
    summary: normalized_draft.summary,
    image_ref: normalized_draft.image_ref.trim().to_owned(),
    capabilities: normalized_draft.capabilities,
    tags: normalized_draft.tags,
    action_ids: normalized_draft.action_ids,
    pricing_summary: normalized_draft.pricing_summary.trim().to_owned(),
    license_class: normalized_draft.license_class.trim().to_owned(),
    rights_summary: normalized_draft.rights_summary.trim().to_owned(),
    version_label: normalized_draft.version_label.trim().to_owned(),
    quality_score: quality,
    reliability_score: reliability,
    content_digest: building_listing_digest(normalized_draft),
    lifecycle,
    updated_at_ms: now_ms,
    version,
  })
  { ..state, building_listings: listings, version: state.version + 1 }
}

///|
fn transition_allowed(from : PublicationState, to : PublicationState) -> Bool {
  match (from, to) {
    (PublicationDraft, PublicationShared) => true
    (PublicationDraft, PublicationSubmitted) => true
    (PublicationShared, PublicationDraft) => true
    (PublicationShared, PublicationSubmitted) => true
    (PublicationSubmitted, PublicationDraft) => true
    (PublicationSubmitted, PublicationPublished) => true
    (PublicationPublished, PublicationArchived) => true
    (PublicationArchived, PublicationDraft) => true
    _ => false
  }
}

///|
fn transition_lifecycle(
  current : PublicationLifecycle,
  target : PublicationState,
  reviewer_id : String,
  review_summary : String,
  now_ms : UInt64,
) -> PublicationLifecycle raise {
  if !transition_allowed(current.state, target) {
    fail("invalid publication lifecycle transition")
  }
  match target {
    PublicationDraft =>
      {
        ..current,
        state: target,
        reviewed_by: Some(reviewer_id),
        review_summary,
      }
    PublicationShared =>
      { ..current, state: target, shared_at_ms: Some(now_ms) }
    PublicationSubmitted =>
      { ..current, state: target, submitted_at_ms: Some(now_ms) }
    PublicationPublished =>
      {
        ..current,
        state: target,
        published_at_ms: Some(now_ms),
        reviewed_by: Some(reviewer_id),
        review_summary,
      }
    PublicationArchived =>
      { ..current, state: target, archived_at_ms: Some(now_ms) }
  }
}

///|
pub fn marketplace_transition_listing(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
  kind : ListingKind,
  listing_id : String,
  target : PublicationState,
  review_summary~ : String,
  now_ms~ : UInt64,
) -> MarketplaceState raise {
  let requires_reviewer = target == PublicationPublished
  let normalized_review_summary = if requires_reviewer {
    validate_public_text("publication review summary", review_summary, 2000)
  } else {
    review_summary.trim().to_owned()
  }
  if requires_reviewer &&
    !(principal_has_role(principal, "publisher") ||
    principal_has_role(principal, "moderator")) {
    fail("publication requires a publisher or moderator role")
  }
  match kind {
    AgentListing => {
      let listings : Array[AgentListingRecord] = []
      let mut found = false
      for listing in state.agent_listings {
        if listing.listing_id == listing_id {
          found = true
          let is_owner = listing.publisher_id == principal.principal_id
          let is_independent_reviewer = target == PublicationPublished &&
            requires_reviewer
          let is_moderator_archive = target == PublicationArchived &&
            principal_has_role(principal, "moderator")
          if listing.tenant_id != principal.tenant_id ||
            !(is_owner || is_independent_reviewer || is_moderator_archive) {
            fail("principal cannot transition this agent listing")
          }
          if target == PublicationPublished &&
            (
              principal.principal_id == listing.publisher_id ||
              !valid_public_index_id(listing.listing_id) ||
              !valid_public_index_id(listing.publisher_id)
            ) {
            fail(
              "publication requires a distinct reviewer and canonical public IDs",
            )
          }
          listings.push({
            ..listing,
            lifecycle: transition_lifecycle(
              listing.lifecycle,
              target,
              principal.principal_id,
              normalized_review_summary,
              now_ms,
            ),
            updated_at_ms: now_ms,
            version: listing.version + 1,
          })
        } else {
          listings.push(listing)
        }
      }
      if !found {
        fail("agent listing not found")
      }
      { ..state, agent_listings: listings, version: state.version + 1 }
    }
    BuildingListing => {
      let listings : Array[BuildingListingRecord] = []
      let mut found = false
      for listing in state.building_listings {
        if listing.listing_id == listing_id {
          found = true
          let is_owner = listing.publisher_id == principal.principal_id
          let is_independent_reviewer = target == PublicationPublished &&
            requires_reviewer
          let is_moderator_archive = target == PublicationArchived &&
            principal_has_role(principal, "moderator")
          if listing.tenant_id != principal.tenant_id ||
            !(is_owner || is_independent_reviewer || is_moderator_archive) {
            fail("principal cannot transition this building listing")
          }
          if target == PublicationPublished &&
            (
              principal.principal_id == listing.publisher_id ||
              !valid_public_index_id(listing.listing_id) ||
              !valid_public_index_id(listing.publisher_id)
            ) {
            fail(
              "publication requires a distinct reviewer and canonical public IDs",
            )
          }
          listings.push({
            ..listing,
            lifecycle: transition_lifecycle(
              listing.lifecycle,
              target,
              principal.principal_id,
              normalized_review_summary,
              now_ms,
            ),
            updated_at_ms: now_ms,
            version: listing.version + 1,
          })
        } else {
          listings.push(listing)
        }
      }
      if !found {
        fail("building listing not found")
      }
      { ..state, building_listings: listings, version: state.version + 1 }
    }
  }
}
