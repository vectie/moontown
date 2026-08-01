///|
fn sha256_text(value : String) -> String {
  "sha256:\{@crypto.bytes_to_hex_string(@crypto.sha256(@utf8.encode(value)))}"
}

///|
pub fn publication_state_name(state : PublicationState) -> String {
  match state {
    PublicationDraft => "draft"
    PublicationShared => "shared"
    PublicationSubmitted => "submitted"
    PublicationPublished => "published"
    PublicationArchived => "archived"
  }
}

///|
pub fn listing_kind_name(kind : ListingKind) -> String {
  match kind {
    AgentListing => "agent"
    BuildingListing => "building"
  }
}

///|
fn published_at_wire(lifecycle : PublicationLifecycle) -> Json {
  match lifecycle.published_at_ms {
    Some(value) => value.to_string().to_json()
    None => Json::null()
  }
}

///|
fn optional_string_wire(value : String?) -> Json {
  match value {
    Some(content) => content.to_json()
    None => Json::null()
  }
}

///|
fn agent_listing_digest(draft : AgentListingDraft) -> String {
  sha256_text(draft.to_json().stringify())
}

///|
fn building_listing_digest(draft : BuildingListingDraft) -> String {
  sha256_text(draft.to_json().stringify())
}

///|
/// Exact 15-field canonical projection consumed by MoonFind.
fn canonical_agent_listing_card(listing : AgentListingRecord) -> Json {
  {
    "contract_id": "moonsuite.public-listing.v1",
    "listing_id": listing.listing_id,
    "listing_kind": "agent",
    "publisher_id": listing.publisher_id,
    "title": listing.title,
    "summary": listing.summary,
    "capabilities": listing.capabilities.to_json(),
    "tags": listing.tags.to_json(),
    "action_ids": listing.action_ids.to_json(),
    "publication_state": "published",
    "published_at": published_at_wire(listing.lifecycle),
    "version": listing.version,
    "content_digest": listing.content_digest,
    "license_class": listing.license_class,
    "rights_summary": listing.rights_summary,
  }
}

///| Sanitized Town presentation projection; the canonical 15 fields are

///|
/// preserved while presentation-only metadata stays out of index export.
pub fn public_agent_listing_card(listing : AgentListingRecord) -> Json {
  if listing.lifecycle.state != PublicationPublished {
    return Json::null()
  }
  let canonical = canonical_agent_listing_card(listing)
  guard canonical is Object(fields) else { return Json::null() }
  fields["image_ref"] = listing.image_ref.to_json()
  fields["pricing_summary"] = listing.pricing_summary.to_json()
  fields["authority_ceiling"] = listing.authority_ceiling.to_json()
  fields["required_permissions"] = listing.required_permissions.to_json()
  fields["quality_score"] = listing.quality_score.to_json()
  fields["reliability_score"] = listing.reliability_score.to_json()
  fields["version_label"] = listing.version_label.to_json()
  Json::object(fields)
}

///|
/// Canonical, sanitized cross-product public listing projection.
fn canonical_building_listing_card(listing : BuildingListingRecord) -> Json {
  {
    "contract_id": "moonsuite.public-listing.v1",
    "listing_id": listing.listing_id,
    "listing_kind": "building",
    "publisher_id": listing.publisher_id,
    "title": listing.title,
    "summary": listing.summary,
    "capabilities": listing.capabilities.to_json(),
    "tags": listing.tags.to_json(),
    "action_ids": listing.action_ids.to_json(),
    "publication_state": "published",
    "published_at": published_at_wire(listing.lifecycle),
    "version": listing.version,
    "content_digest": listing.content_digest,
    "license_class": listing.license_class,
    "rights_summary": listing.rights_summary,
  }
}

///|
pub fn public_building_listing_card(listing : BuildingListingRecord) -> Json {
  if listing.lifecycle.state != PublicationPublished {
    return Json::null()
  }
  let canonical = canonical_building_listing_card(listing)
  guard canonical is Object(fields) else { return Json::null() }
  fields["image_ref"] = listing.image_ref.to_json()
  fields["pricing_summary"] = listing.pricing_summary.to_json()
  fields["authority_ceiling"] = "building-service".to_json()
  fields["required_permissions"] = Json::array([])
  fields["quality_score"] = listing.quality_score.to_json()
  fields["reliability_score"] = listing.reliability_score.to_json()
  fields["version_label"] = listing.version_label.to_json()
  Json::object(fields)
}

///|
fn public_listing_by_ref(
  state : MarketplaceState,
  kind : ListingKind,
  listing_id : String,
) -> Json? {
  match kind {
    AgentListing =>
      for listing in state.agent_listings {
        if listing.listing_id == listing_id &&
          listing.lifecycle.state == PublicationPublished {
          return Some(public_agent_listing_card(listing))
        }
      }
    BuildingListing =>
      for listing in state.building_listings {
        if listing.listing_id == listing_id &&
          listing.lifecycle.state == PublicationPublished {
          return Some(public_building_listing_card(listing))
        }
      }
  }
  None
}

///| Owner-authorized pre-publication share projection. It contains only card

///| metadata and lifecycle state; private workspace/runtime material remains

///|
/// excluded. It is never eligible for public search or MoonFind export.
fn safe_private_listing_share_projection(
  state : MarketplaceState,
  kind : ListingKind,
  listing_id : String,
) -> Json? {
  match kind {
    AgentListing =>
      for listing in state.agent_listings {
        if listing.listing_id == listing_id {
          return Some({
            "contract_id": "moontown.private-listing-share-preview.v1",
            "listing_id": listing.listing_id,
            "listing_kind": "agent",
            "publisher_id": listing.publisher_id,
            "title": listing.title,
            "summary": listing.summary,
            "capabilities": listing.capabilities.to_json(),
            "tags": listing.tags.to_json(),
            "action_ids": listing.action_ids.to_json(),
            "image_ref": listing.image_ref,
            "pricing_summary": listing.pricing_summary,
            "publication_state": publication_state_name(listing.lifecycle.state),
            "version": listing.version_label,
          })
        }
      }
    BuildingListing =>
      for listing in state.building_listings {
        if listing.listing_id == listing_id {
          return Some({
            "contract_id": "moontown.private-listing-share-preview.v1",
            "listing_id": listing.listing_id,
            "listing_kind": "building",
            "publisher_id": listing.publisher_id,
            "title": listing.title,
            "summary": listing.summary,
            "capabilities": listing.capabilities.to_json(),
            "tags": listing.tags.to_json(),
            "action_ids": listing.action_ids.to_json(),
            "image_ref": listing.image_ref,
            "pricing_summary": listing.pricing_summary,
            "publication_state": publication_state_name(listing.lifecycle.state),
            "version": listing.version_label,
          })
        }
      }
  }
  None
}

///|
/// Exportable cards contain only allowlisted public fields.
pub fn public_listing_cards(state : MarketplaceState) -> Array[Json] {
  let cards : Array[Json] = []
  for listing in state.agent_listings {
    if listing.lifecycle.state == PublicationPublished {
      cards.push(public_agent_listing_card(listing))
    }
  }
  for listing in state.building_listings {
    if listing.lifecycle.state == PublicationPublished {
      cards.push(public_building_listing_card(listing))
    }
  }
  cards
}

///|
pub fn public_listing_index_export(state : MarketplaceState) -> Json {
  let listings : Array[Json] = []
  for listing in state.agent_listings {
    if listing.lifecycle.state == PublicationPublished {
      listings.push(canonical_agent_listing_card(listing))
    }
  }
  for listing in state.building_listings {
    if listing.lifecycle.state == PublicationPublished {
      listings.push(canonical_building_listing_card(listing))
    }
  }
  {
    "contract_id": "moontown.public-listing-export.v1",
    "listings": listings.to_json(),
  }
}
