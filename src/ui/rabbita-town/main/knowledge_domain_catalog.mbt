///|
type KnowledgeDomainBook = @domain_catalog.KnowledgeDomainBook

///|
type KnowledgeDomainPolicy = @domain_catalog.KnowledgeDomainPolicy

///|
type KnowledgeDomain = @domain_catalog.KnowledgeDomain

///|
type KnowledgeDomainCatalog = @domain_catalog.KnowledgeDomainCatalog

///|
priv struct KnowledgeBookDisplayState {
  key : String
  label : String
  explanation : String
}

///|
fn knowledge_domain_catalog_digest_matches(
  expected_digest : String?,
  actual_digest : String,
) -> Bool {
  match expected_digest {
    Some(expected) => expected == actual_digest
    None => true
  }
}

///|
fn parse_bootstrap_knowledge_domain_catalog(
  expected_digest : String?,
) -> KnowledgeDomainCatalog? {
  let text = load_bootstrap_knowledge_domain_catalog_json()
  if text.trim().is_empty() {
    return None
  }
  if !knowledge_domain_catalog_digest_matches(
      expected_digest,
      knowledge_domain_catalog_digest(),
    ) {
    return None
  }
  let catalog = @domain_catalog.parse_knowledge_domain_catalog(text) catch {
    _ => return None
  }
  Some(catalog)
}

///|
fn find_knowledge_domain_by_building_id(
  catalog : KnowledgeDomainCatalog,
  building_id : String,
) -> KnowledgeDomain? {
  @domain_catalog.find_domain_by_building_id(catalog, building_id)
}

///|
fn find_knowledge_domain_for_building(
  model : Model,
  building : GoldenValleyBuilding,
) -> KnowledgeDomain? {
  match model.knowledge_domain_catalog {
    None => None
    Some(catalog) => {
      let module_key = golden_valley_building_module_key(building)
      let civic_id = golden_valley_building_civic_id(building)
      match find_knowledge_domain_by_building_id(catalog, module_key) {
        Some(domain) => Some(domain)
        None => find_knowledge_domain_by_building_id(catalog, civic_id)
      }
    }
  }
}

///|
fn find_knowledge_domain_policy(
  model : Model,
  policy_id : String,
) -> KnowledgeDomainPolicy? {
  match model.knowledge_domain_catalog {
    None => None
    Some(catalog) => @domain_catalog.find_policy(catalog, policy_id)
  }
}

///|
fn find_exact_book_projection(
  model : Model,
  book_id : String,
) -> BookProjectionFragment? {
  for projection in model.module_projections {
    if projection.book_id == book_id {
      return Some(projection)
    }
  }
  None
}

///|
fn knowledge_status_text_is_review(text : String) -> Bool {
  let value = text.to_lower()
  value.contains("review") ||
  value.contains("pending") ||
  value.contains("待审") ||
  value.contains("复核")
}

///|
fn knowledge_acceptance_receipt_is_valid(
  receipt : ProjectionAcceptanceReceipt,
) -> Bool {
  receipt.contract_version ==
  "moontown.moonbook.acceptance-receipt-projection.v1" &&
  receipt.decision == "accepted" &&
  !receipt.decision_id.trim().is_empty() &&
  !receipt.candidate_version.trim().is_empty() &&
  !receipt.reviewer.trim().is_empty() &&
  receipt.evidence_count > 0 &&
  receipt.issue_count == 0 &&
  !receipt.requires_human_review &&
  receipt.source_contract == "moonbook.bookkeeper.v1" &&
  receipt.source_projection == "moonbook.bookkeeper.ui.v1"
}

///|
fn knowledge_projection_is_under_review(
  projection : BookProjectionFragment,
) -> Bool {
  if !projection.review_queue.is_empty() {
    return true
  }
  projection.status_chips.any(chip => {
    knowledge_status_text_is_review(chip.label)
  }) ||
  projection.journey.any(item => {
    knowledge_status_text_is_review(item.status) ||
    knowledge_status_text_is_review(item.stage)
  })
}

///|
fn knowledge_projection_is_explicitly_accepted(
  projection : BookProjectionFragment,
) -> Bool {
  match projection.acceptance_receipt {
    Some(receipt) => knowledge_acceptance_receipt_is_valid(receipt)
    None => false
  }
}

///|
fn knowledge_book_display_state(
  model : Model,
  book : KnowledgeDomainBook,
) -> KnowledgeBookDisplayState {
  match find_exact_book_projection(model, book.book_id) {
    Some(projection) =>
      if knowledge_projection_is_under_review(projection) {
        {
          key: "review",
          label: "In review",
          explanation: "A real MoonBook projection has review work pending.",
        }
      } else if knowledge_projection_is_explicitly_accepted(projection) {
        {
          key: "accepted",
          label: "Accepted",
          explanation: "The projection explicitly records accepted work.",
        }
      } else {
        {
          key: "real",
          label: "Real projection",
          explanation: "This card is joined to a published MoonBook projection.",
        }
      }
    None =>
      if book.status == "incubating" {
        {
          key: "planned",
          label: "Planned",
          explanation: "Declared in the domain catalog; no MoonBook projection exists yet.",
        }
      } else {
        {
          key: "declared",
          label: "Declared",
          explanation: "Registered by policy; not presented as completed work.",
        }
      }
  }
}

///|
fn knowledge_domain_primary_book(
  domain : KnowledgeDomain,
) -> KnowledgeDomainBook? {
  for book in domain.books {
    if book.book_id == domain.primary_book_id {
      return Some(book)
    }
  }
  None
}

///|
fn knowledge_domain_primary_tier(domain : KnowledgeDomain) -> String {
  match knowledge_domain_primary_book(domain) {
    Some(book) => book.schedule_tier
    None => "on-demand"
  }
}

///|
fn knowledge_domain_real_book_count(
  model : Model,
  domain : KnowledgeDomain,
) -> Int {
  let mut count = 0
  for book in domain.books {
    if find_exact_book_projection(model, book.book_id) is Some(_) {
      count += 1
    }
  }
  count
}

///|
fn knowledge_domain_review_book_count(
  model : Model,
  domain : KnowledgeDomain,
) -> Int {
  let mut count = 0
  for book in domain.books {
    if knowledge_book_display_state(model, book).key == "review" {
      count += 1
    }
  }
  count
}

///|
fn knowledge_domain_accepted_book_count(
  model : Model,
  domain : KnowledgeDomain,
) -> Int {
  let mut count = 0
  for book in domain.books {
    if knowledge_book_display_state(model, book).key == "accepted" {
      count += 1
    }
  }
  count
}
