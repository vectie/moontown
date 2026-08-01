///|
pub fn domain_count(catalog : KnowledgeDomainCatalog) -> Int {
  catalog.domains.length()
}

///|
pub fn building_count(catalog : KnowledgeDomainCatalog) -> Int {
  let building_ids : Array[String] = []
  for domain in catalog.domains {
    if !building_ids.contains(domain.building_id) {
      building_ids.push(domain.building_id)
    }
  }
  building_ids.length()
}

///|
pub fn policy_count(catalog : KnowledgeDomainCatalog) -> Int {
  catalog.policies.length()
}

///|
pub fn book_count(catalog : KnowledgeDomainCatalog) -> Int {
  let mut count = 0
  for domain in catalog.domains {
    count += domain.books.length()
  }
  count
}

///|
pub fn book_count_with_status(
  catalog : KnowledgeDomainCatalog,
  status : String,
) -> Int {
  let mut count = 0
  for domain in catalog.domains {
    for book in domain.books {
      if book.status == status {
        count += 1
      }
    }
  }
  count
}

///|
pub fn active_book_count(catalog : KnowledgeDomainCatalog) -> Int {
  book_count_with_status(catalog, "active")
}

///|
pub fn communication_scenario_count(catalog : KnowledgeDomainCatalog) -> Int {
  let scenario_ids : Array[String] = []
  for domain in catalog.domains {
    for scenario_id in domain.communication_scenario_ids {
      if !scenario_ids.contains(scenario_id) {
        scenario_ids.push(scenario_id)
      }
    }
  }
  scenario_ids.length()
}

///|
pub fn knowledge_domain_portfolio(
  catalog : KnowledgeDomainCatalog,
) -> KnowledgeDomainPortfolio {
  {
    domain_count: domain_count(catalog),
    building_count: building_count(catalog),
    policy_count: policy_count(catalog),
    book_count: book_count(catalog),
    active_book_count: book_count_with_status(catalog, "active"),
    incubating_book_count: book_count_with_status(catalog, "incubating"),
    paused_book_count: book_count_with_status(catalog, "paused"),
    archived_book_count: book_count_with_status(catalog, "archived"),
    communication_scenario_count: communication_scenario_count(catalog),
  }
}
