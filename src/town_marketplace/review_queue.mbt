///|
fn marketplace_principal_display_name(
  state : MarketplaceState,
  principal_id : String,
) -> String {
  for principal in state.principals {
    if principal.principal_id == principal_id {
      return principal.display_name
    }
  }
  principal_id
}

///|
fn submitted_agent_review_card(
  state : MarketplaceState,
  listing : AgentListingRecord,
) -> Json {
  {
    "contract_id": "moontown.publication-review-card.v1",
    "listing_id": listing.listing_id,
    "listing_kind": "agent",
    "publisher_id": listing.publisher_id,
    "publisher_display_name": marketplace_principal_display_name(
      state,
      listing.publisher_id,
    ),
    "title": listing.title,
    "summary": listing.summary,
    "capabilities": listing.capabilities.to_json(),
    "tags": listing.tags.to_json(),
    "license_class": listing.license_class,
    "rights_summary": listing.rights_summary,
    "version_label": listing.version_label,
    "content_digest": listing.content_digest,
    "version": listing.version,
  }
}

///|
fn submitted_building_review_card(
  state : MarketplaceState,
  listing : BuildingListingRecord,
) -> Json {
  {
    "contract_id": "moontown.publication-review-card.v1",
    "listing_id": listing.listing_id,
    "listing_kind": "building",
    "publisher_id": listing.publisher_id,
    "publisher_display_name": marketplace_principal_display_name(
      state,
      listing.publisher_id,
    ),
    "title": listing.title,
    "summary": listing.summary,
    "capabilities": listing.capabilities.to_json(),
    "tags": listing.tags.to_json(),
    "license_class": listing.license_class,
    "rights_summary": listing.rights_summary,
    "version_label": listing.version_label,
    "content_digest": listing.content_digest,
    "version": listing.version,
  }
}

///|
/// Return only same-tenant submitted public-card metadata that a distinct
/// publisher or moderator may review. Runtime memory, raw evidence, secrets,
/// host paths, consent records, and private messages never enter this view.
pub fn marketplace_listing_review_queue(
  state : MarketplaceState,
  principal : MarketplacePrincipal,
) -> Json raise {
  if !(principal_has_role(principal, "publisher") ||
    principal_has_role(principal, "moderator")) {
    fail("publication review queue requires publisher or moderator role")
  }
  let listings : Array[Json] = []
  for listing in state.agent_listings {
    if listing.tenant_id == principal.tenant_id &&
      listing.publisher_id != principal.principal_id &&
      listing.lifecycle.state == PublicationSubmitted {
      listings.push(submitted_agent_review_card(state, listing))
    }
  }
  for listing in state.building_listings {
    if listing.tenant_id == principal.tenant_id &&
      listing.publisher_id != principal.principal_id &&
      listing.lifecycle.state == PublicationSubmitted {
      listings.push(submitted_building_review_card(state, listing))
    }
  }
  {
    "contract_id": "moontown.publication-review-queue.v1",
    "listings": listings,
    "result_count": listings.length(),
  }
}
