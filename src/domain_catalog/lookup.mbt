///|
pub fn find_policy(
  catalog : KnowledgeDomainCatalog,
  policy_id : String,
) -> KnowledgeDomainPolicy? {
  for policy in catalog.policies {
    if policy.id == policy_id {
      return Some(policy)
    }
  }
  None
}

///|
pub fn find_domain(
  catalog : KnowledgeDomainCatalog,
  domain_id : String,
) -> KnowledgeDomain? {
  for domain in catalog.domains {
    if domain.domain_id == domain_id {
      return Some(domain)
    }
  }
  None
}

///|
pub fn find_domain_by_building_id(
  catalog : KnowledgeDomainCatalog,
  building_id : String,
) -> KnowledgeDomain? {
  for domain in catalog.domains {
    if domain.building_id == building_id {
      return Some(domain)
    }
  }
  None
}

///|
pub fn find_book(
  catalog : KnowledgeDomainCatalog,
  book_id : String,
) -> KnowledgeDomainBook? {
  for domain in catalog.domains {
    for book in domain.books {
      if book.book_id == book_id {
        return Some(book)
      }
    }
  }
  None
}

///|
pub fn find_domain_for_book(
  catalog : KnowledgeDomainCatalog,
  book_id : String,
) -> KnowledgeDomain? {
  for domain in catalog.domains {
    for book in domain.books {
      if book.book_id == book_id {
        return Some(domain)
      }
    }
  }
  None
}

///|
pub fn books_for_building(
  catalog : KnowledgeDomainCatalog,
  building_id : String,
) -> Array[KnowledgeDomainBook] {
  match find_domain_by_building_id(catalog, building_id) {
    Some(domain) => domain.books.copy()
    None => []
  }
}

///|
pub fn primary_book_for_building(
  catalog : KnowledgeDomainCatalog,
  building_id : String,
) -> KnowledgeDomainBook? {
  match find_domain_by_building_id(catalog, building_id) {
    Some(domain) => find_book(catalog, domain.primary_book_id)
    None => None
  }
}

///|
pub fn all_books(
  catalog : KnowledgeDomainCatalog,
) -> Array[KnowledgeDomainBook] {
  let result : Array[KnowledgeDomainBook] = []
  for domain in catalog.domains {
    for book in domain.books {
      result.push(book)
    }
  }
  result
}

///|
pub fn domains_of_kind(
  catalog : KnowledgeDomainCatalog,
  kind : String,
) -> Array[KnowledgeDomain] {
  catalog.domains.filter(domain => domain.kind == kind)
}
