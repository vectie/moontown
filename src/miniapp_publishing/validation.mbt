///|
pub fn miniapp_validate_publication(
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  viewer : @miniapp_projection.MiniappViewerContext,
  request : MiniappPublicationRequest,
  policy? : MiniappPublicationPolicy = miniapp_default_publication_policy(),
) -> MiniappPublicationValidation {
  match miniapp_publishing_building_by_id(snapshot, request.building_id) {
    None =>
      {
        ok: false,
        building_id: request.building_id,
        issues: ["building-not-found"],
        warnings: [],
      }
    Some(building) => {
      let issues : Array[String] = []
      let warnings : Array[String] = []
      if !@miniapp_projection.miniapp_can_submit_building_for_publish(
          viewer, building,
        ) &&
        !@miniapp_projection.miniapp_can_approve_building_publication(
          viewer, building,
        ) {
        issues.push("viewer-cannot-publish-building")
      }
      miniapp_validate_metadata(issues, warnings, building, request, policy)
      miniapp_validate_public_summary(issues, request.public_summary, policy)
      miniapp_validate_book_projection(issues, snapshot, building, policy)
      miniapp_validate_assets(issues, request.asset_refs, policy)
      miniapp_validate_duplicate_signals(issues, warnings, snapshot, building)
      { ok: issues.length() == 0, building_id: building.id, issues, warnings }
    }
  }
}

///|
fn miniapp_validate_metadata(
  issues : Array[String],
  warnings : Array[String],
  building : @miniapp_contracts.MiniappBuilding,
  request : MiniappPublicationRequest,
  policy : MiniappPublicationPolicy,
) -> Unit {
  if building.title.trim().to_owned() == "" {
    issues.push("missing-title")
  }
  if request.category_id != miniapp_building_category_id(building.kind) {
    issues.push("category-does-not-match-building-kind")
  }
  if !policy.allowed_category_ids.contains(request.category_id) {
    issues.push("category-not-allowed")
  }
  if building.tags.length() == 0 {
    issues.push("missing-tags")
  }
  if building.tags.length() > policy.max_tags {
    issues.push("too-many-tags")
  }
  if miniapp_has_duplicate_strings(building.tags) {
    warnings.push("duplicate-tags")
  }
  for capability in policy.required_capabilities {
    if !building.capabilities.contains(capability) {
      issues.push("missing-required-capability:\{capability}")
    }
  }
}

///|
fn miniapp_validate_public_summary(
  issues : Array[String],
  summary : String,
  policy : MiniappPublicationPolicy,
) -> Unit {
  let trimmed = summary.trim().to_owned()
  if trimmed.length() < policy.min_summary_chars {
    issues.push("summary-too-short")
  }
  if trimmed.length() > policy.max_summary_chars {
    issues.push("summary-too-long")
  }
  if miniapp_contains_banned_term(trimmed, policy.banned_terms) {
    issues.push("summary-contains-private-or-secret-material")
  }
}

///|
fn miniapp_validate_book_projection(
  issues : Array[String],
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
  policy : MiniappPublicationPolicy,
) -> Unit {
  match miniapp_publishing_book_by_id(snapshot, building.primary_book_id) {
    None => issues.push("primary-book-projection-missing")
    Some(book) =>
      if miniapp_contains_banned_term(book.summary, policy.banned_terms) {
        issues.push("book-summary-contains-private-or-secret-material")
      }
  }
}

///|
fn miniapp_validate_assets(
  issues : Array[String],
  asset_refs : Array[String],
  policy : MiniappPublicationPolicy,
) -> Unit {
  for asset_ref in asset_refs {
    if !policy.allowed_asset_refs.contains(asset_ref) {
      issues.push("asset-not-allowed:\{asset_ref}")
    }
  }
}

///|
fn miniapp_validate_duplicate_signals(
  issues : Array[String],
  warnings : Array[String],
  snapshot : @miniapp_contracts.MiniappTownSnapshot,
  building : @miniapp_contracts.MiniappBuilding,
) -> Unit {
  let mut same_title_count = 0
  for item in snapshot.buildings {
    if item.id != building.id &&
      item.visibility == @miniapp_contracts.Published &&
      item.title.to_lower() == building.title.to_lower() {
      same_title_count += 1
    }
  }
  if same_title_count > 0 {
    issues.push("duplicate-public-title")
  }
  if building.tags.length() > 0 && same_title_count == 0 {
    warnings.push("dedupe-scan-clear")
  }
}
