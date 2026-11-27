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
    Some(value) => ToJson::to_json(value.to_string())
    None => Json::null()
  }
}

///|
fn optional_string_wire(value : String?) -> Json {
  match value {
    Some(content) => ToJson::to_json(content)
    None => Json::null()
  }
}

///|
fn agent_listing_digest(draft : AgentListingDraft) -> String {
  sha256_text(ToJson::to_json(draft).stringify())
}

///|
fn building_listing_digest(draft : BuildingListingDraft) -> String {
  sha256_text(ToJson::to_json(draft).stringify())
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
    "capabilities": ToJson::to_json(listing.capabilities),
    "tags": ToJson::to_json(listing.tags),
    "action_ids": ToJson::to_json(listing.action_ids),
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
  fields["image_ref"] = ToJson::to_json(listing.image_ref)
  fields["pricing_summary"] = ToJson::to_json(listing.pricing_summary)
  fields["authority_ceiling"] = ToJson::to_json(listing.authority_ceiling)
  fields["required_permissions"] = ToJson::to_json(listing.required_permissions)
  fields["quality_score"] = ToJson::to_json(listing.quality_score)
  fields["reliability_score"] = ToJson::to_json(listing.reliability_score)
  fields["version_label"] = ToJson::to_json(listing.version_label)
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
    "capabilities": ToJson::to_json(listing.capabilities),
    "tags": ToJson::to_json(listing.tags),
    "action_ids": ToJson::to_json(listing.action_ids),
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
  fields["image_ref"] = ToJson::to_json(listing.image_ref)
  fields["pricing_summary"] = ToJson::to_json(listing.pricing_summary)
  fields["authority_ceiling"] = ToJson::to_json("building-service")
  fields["required_permissions"] = Json::array([])
  fields["quality_score"] = ToJson::to_json(listing.quality_score)
  fields["reliability_score"] = ToJson::to_json(listing.reliability_score)
  fields["version_label"] = ToJson::to_json(listing.version_label)
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
          return Some(
            attach_private_portable_binding(state, listing_id, {
              "contract_id": "moontown.private-listing-share-preview.v1",
              "listing_id": listing.listing_id,
              "listing_kind": "agent",
              "publisher_id": listing.publisher_id,
              "title": listing.title,
              "summary": listing.summary,
              "capabilities": ToJson::to_json(listing.capabilities),
              "tags": ToJson::to_json(listing.tags),
              "action_ids": ToJson::to_json(listing.action_ids),
              "image_ref": listing.image_ref,
              "pricing_summary": listing.pricing_summary,
              "publication_state": publication_state_name(
                listing.lifecycle.state,
              ),
              "version": listing.version_label,
            }),
          )
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
            "capabilities": ToJson::to_json(listing.capabilities),
            "tags": ToJson::to_json(listing.tags),
            "action_ids": ToJson::to_json(listing.action_ids),
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
    "listings": ToJson::to_json(listings),
  }
}
