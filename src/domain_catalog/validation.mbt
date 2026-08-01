///|
fn push_blank_error(
  errors : Array[String],
  value : String,
  path : String,
) -> Unit {
  if value.trim().is_empty() {
    errors.push("\{path} must not be blank")
  }
}

///|
fn validate_identifier(
  errors : Array[String],
  value : String,
  path : String,
) -> Unit {
  if !valid_catalog_identifier(value) {
    errors.push("\{path} `\{value}` must be a lowercase path-safe identifier")
  }
}

///|
fn validate_unique_nonblank_strings(
  errors : Array[String],
  values : Array[String],
  path : String,
) -> Unit {
  let seen : Array[String] = []
  for value in values {
    if value.trim().is_empty() {
      errors.push("\{path} must not contain blank values")
    } else if seen.contains(value) {
      errors.push("\{path} contains duplicate `\{value}`")
    } else {
      seen.push(value)
    }
  }
}

///|
fn validate_policy(
  policy : KnowledgeDomainPolicy,
  errors : Array[String],
) -> Unit {
  let path = "policies[\{policy.id}]"
  push_blank_error(errors, policy.id, "\{path}.id")
  validate_identifier(errors, policy.id, "\{path}.id")
  if policy.version <= 0 {
    errors.push("\{path}.version must be positive")
  }
  if !valid_template_id(policy.template_id) {
    errors.push("\{path}.template_id `\{policy.template_id}` is unsupported")
  }
  if !valid_source_policy(policy.source_policy) {
    errors.push(
      "\{path}.source_policy `\{policy.source_policy}` is unsupported",
    )
  }
  if !valid_evidence_policy(policy.evidence_policy) {
    errors.push(
      "\{path}.evidence_policy `\{policy.evidence_policy}` is unsupported",
    )
  }
  if !valid_cadence(policy.cadence) {
    errors.push("\{path}.cadence `\{policy.cadence}` is unsupported")
  }
  if policy.cadence_ticks <= 0 {
    errors.push("\{path}.cadence_ticks must be positive")
  }
  if policy.quality_threshold < 0 || policy.quality_threshold > 100 {
    errors.push("\{path}.quality_threshold must be between 0 and 100")
  }
  if policy.review_chain.is_empty() {
    errors.push("\{path}.review_chain must not be empty")
  }
  validate_unique_nonblank_strings(
    errors,
    policy.review_chain,
    "\{path}.review_chain",
  )
  for reviewer in policy.review_chain {
    if !valid_review_role(reviewer) {
      errors.push("\{path}.review_chain role `\{reviewer}` is unsupported")
    }
  }
  if policy.max_revision_rounds < 0 || policy.max_revision_rounds > 10 {
    errors.push("\{path}.max_revision_rounds must be between 0 and 10")
  }
  if !valid_schedule_tier(policy.schedule_tier) {
    errors.push(
      "\{path}.schedule_tier `\{policy.schedule_tier}` is unsupported",
    )
  }
  if !valid_budget_class(policy.budget_class) {
    errors.push("\{path}.budget_class `\{policy.budget_class}` is unsupported")
  }
  if !valid_completion_claim(policy.completion_claim) {
    errors.push(
      "\{path}.completion_claim `\{policy.completion_claim}` is unsupported",
    )
  }
}

///|
fn validate_book(
  book : KnowledgeDomainBook,
  domain : KnowledgeDomain,
  catalog : KnowledgeDomainCatalog,
  errors : Array[String],
) -> Unit {
  let path = "domains[\{domain.domain_id}].books[\{book.book_id}]"
  push_blank_error(errors, book.book_id, "\{path}.book_id")
  validate_identifier(errors, book.book_id, "\{path}.book_id")
  push_blank_error(errors, book.title, "\{path}.title")
  push_blank_error(errors, book.question, "\{path}.question")
  if !valid_book_role(book.role) {
    errors.push("\{path}.role `\{book.role}` is unsupported")
  }
  if !valid_template_id(book.template_id) {
    errors.push("\{path}.template_id `\{book.template_id}` is unsupported")
  }
  if find_policy(catalog, book.policy_id) == None {
    errors.push("\{path}.policy_id `\{book.policy_id}` is not declared")
  }
  if !valid_schedule_tier(book.schedule_tier) {
    errors.push("\{path}.schedule_tier `\{book.schedule_tier}` is unsupported")
  }
  if book.cadence_ticks <= 0 {
    errors.push("\{path}.cadence_ticks must be positive")
  }
  if book.tags.is_empty() {
    errors.push("\{path}.tags must not be empty")
  }
  validate_unique_nonblank_strings(errors, book.tags, "\{path}.tags")
  if !valid_source_policy(book.source_policy) {
    errors.push("\{path}.source_policy `\{book.source_policy}` is unsupported")
  }
  if !valid_book_status(book.status) {
    errors.push("\{path}.status `\{book.status}` is unsupported")
  }
}

///|
fn validate_domain(
  domain : KnowledgeDomain,
  catalog : KnowledgeDomainCatalog,
  errors : Array[String],
) -> Unit {
  let path = "domains[\{domain.domain_id}]"
  push_blank_error(errors, domain.domain_id, "\{path}.domain_id")
  push_blank_error(errors, domain.title, "\{path}.title")
  push_blank_error(errors, domain.icon, "\{path}.icon")
  push_blank_error(errors, domain.building_id, "\{path}.building_id")
  push_blank_error(errors, domain.primary_book_id, "\{path}.primary_book_id")
  push_blank_error(errors, domain.summary, "\{path}.summary")
  validate_identifier(errors, domain.domain_id, "\{path}.domain_id")
  validate_identifier(errors, domain.building_id, "\{path}.building_id")
  validate_identifier(errors, domain.primary_book_id, "\{path}.primary_book_id")
  if !valid_domain_kind(domain.kind) {
    errors.push("\{path}.kind `\{domain.kind}` is unsupported")
  }
  if find_policy(catalog, domain.policy_id) == None {
    errors.push("\{path}.policy_id `\{domain.policy_id}` is not declared")
  }
  validate_unique_nonblank_strings(
    errors,
    domain.communication_scenario_ids,
    "\{path}.communication_scenario_ids",
  )
  for scenario_id in domain.communication_scenario_ids {
    validate_identifier(
      errors,
      scenario_id,
      "\{path}.communication_scenario_ids",
    )
  }
  if domain.books.is_empty() {
    errors.push("\{path}.books must not be empty")
  }
  let local_book_ids : Array[String] = []
  for book in domain.books {
    if local_book_ids.contains(book.book_id) {
      errors.push("\{path}.books contains duplicate `\{book.book_id}`")
    } else {
      local_book_ids.push(book.book_id)
    }
    validate_book(book, domain, catalog, errors)
  }
  if !local_book_ids.contains(domain.primary_book_id) {
    errors.push(
      "\{path}.primary_book_id `\{domain.primary_book_id}` is not a member book",
    )
  }
}

///|
/// Return every schema, vocabulary, referential-integrity, and uniqueness
/// violation without stopping at the first error.
pub fn validate_knowledge_domain_catalog(
  catalog : KnowledgeDomainCatalog,
) -> Array[String] {
  let errors : Array[String] = []
  if catalog.schema != knowledge_domain_catalog_schema() {
    errors.push(
      "schema `\{catalog.schema}` is unsupported; expected `\{knowledge_domain_catalog_schema()}`",
    )
  }
  push_blank_error(errors, catalog.catalog_id, "catalog_id")
  push_blank_error(errors, catalog.description, "description")
  if catalog.version != knowledge_domain_catalog_version() {
    errors.push(
      "version `\{catalog.version}` is unsupported; expected `\{knowledge_domain_catalog_version()}`",
    )
  }
  if catalog.seed <= 0 {
    errors.push("seed must be positive")
  }
  validate_identifier(errors, catalog.catalog_id, "catalog_id")
  if catalog.policies.is_empty() {
    errors.push("policies must not be empty")
  }
  if catalog.domains.is_empty() {
    errors.push("domains must not be empty")
  }
  let policy_ids : Array[String] = []
  for policy in catalog.policies {
    if policy_ids.contains(policy.id) {
      errors.push("policies contains duplicate id `\{policy.id}`")
    } else {
      policy_ids.push(policy.id)
    }
    validate_policy(policy, errors)
  }
  let domain_ids : Array[String] = []
  let building_ids : Array[String] = []
  let global_book_ids : Array[String] = []
  for domain in catalog.domains {
    if domain_ids.contains(domain.domain_id) {
      errors.push("domains contains duplicate id `\{domain.domain_id}`")
    } else {
      domain_ids.push(domain.domain_id)
    }
    if building_ids.contains(domain.building_id) {
      errors.push(
        "domains contains duplicate building_id `\{domain.building_id}`",
      )
    } else {
      building_ids.push(domain.building_id)
    }
    for book in domain.books {
      if global_book_ids.contains(book.book_id) {
        errors.push("catalog contains duplicate book_id `\{book.book_id}`")
      } else {
        global_book_ids.push(book.book_id)
      }
    }
    validate_domain(domain, catalog, errors)
  }
  errors
}

///|
/// Require a valid catalog at a runtime boundary.
pub fn require_valid_knowledge_domain_catalog(
  catalog : KnowledgeDomainCatalog,
) -> Unit raise {
  let errors = validate_knowledge_domain_catalog(catalog)
  if !errors.is_empty() {
    fail("invalid knowledge-domain catalog: \{errors.join("; ")}")
  }
}
