///|
fn valid_catalog_fixture() -> KnowledgeDomainCatalog {
  {
    schema: knowledge_domain_catalog_schema(),
    catalog_id: "fixture",
    version: knowledge_domain_catalog_version(),
    seed: 20260727,
    description: "Fixture catalog",
    policies: [
      {
        id: "research-watch-v1",
        version: 1,
        template_id: "domain-research-book",
        source_policy: "primary-sources",
        evidence_policy: "primary-source-required",
        cadence: "daily",
        cadence_ticks: 24,
        quality_threshold: 80,
        review_chain: ["specialist", "independent-reviewer", "keeper"],
        max_revision_rounds: 2,
        schedule_tier: "daily",
        budget_class: "standard",
        completion_claim: "evidence-backed-research",
      },
    ],
    domains: [
      {
        domain_id: "robotics",
        title: "Robotics Lab",
        icon: "robot",
        building_id: "research-embodied-robotics",
        kind: "knowledge-domain",
        primary_book_id: "research-embodied-robotics",
        policy_id: "research-watch-v1",
        communication_scenario_ids: ["robotics-salon"],
        summary: "Robotics evidence and synthesis.",
        books: [
          {
            book_id: "research-embodied-robotics",
            title: "Robotics Research",
            question: "What changed in embodied robotics?",
            role: "owner",
            template_id: "domain-research-book",
            policy_id: "research-watch-v1",
            schedule_tier: "daily",
            cadence_ticks: 24,
            tags: ["research", "robotics"],
            source_policy: "primary-sources",
            status: "active",
          },
          {
            book_id: "embodied-robotics-vla",
            title: "VLA",
            question: "How should VLA recovery be evaluated?",
            role: "researcher",
            template_id: "domain-research-book",
            policy_id: "research-watch-v1",
            schedule_tier: "weekly",
            cadence_ticks: 168,
            tags: ["research", "vla"],
            source_policy: "primary-sources",
            status: "incubating",
          },
        ],
      },
    ],
  }
}

///|
test "catalog JSON round-trip validates" {
  let fixture = valid_catalog_fixture()
  let parsed = decode_knowledge_domain_catalog(fixture.to_json()) catch {
    error => fail("unexpected decode error: \{error}")
  }
  assert_eq(parsed, fixture)
  assert_eq(validate_knowledge_domain_catalog(parsed), [])
}

///|
test "lookups use exact building and book identifiers" {
  let catalog = valid_catalog_fixture()
  assert_eq(
    find_domain_by_building_id(catalog, "research-embodied-robotics").map(domain => {
      domain.domain_id
    }),
    Some("robotics"),
  )
  assert_eq(find_domain_by_building_id(catalog, "robotics"), None)
  assert_eq(
    find_domain_for_book(catalog, "embodied-robotics-vla").map(domain => {
      domain.building_id
    }),
    Some("research-embodied-robotics"),
  )
  assert_eq(find_book(catalog, "vla"), None)
}

///|
test "portfolio counts domains books states and scenarios" {
  let portfolio = knowledge_domain_portfolio(valid_catalog_fixture())
  assert_eq(portfolio.domain_count, 1)
  assert_eq(portfolio.building_count, 1)
  assert_eq(portfolio.policy_count, 1)
  assert_eq(portfolio.book_count, 2)
  assert_eq(portfolio.active_book_count, 1)
  assert_eq(portfolio.incubating_book_count, 1)
  assert_eq(portfolio.communication_scenario_count, 1)
}

///|
test "validation accumulates vocabulary and reference errors" {
  let catalog = valid_catalog_fixture()
  let invalid = {
    ..catalog,
    domains: [
      {
        ..catalog.domains[0],
        kind: "imaginary",
        policy_id: "missing-policy",
        primary_book_id: "missing-book",
      },
    ],
  }
  let errors = validate_knowledge_domain_catalog(invalid)
  assert_true(errors.length() >= 3)
  assert_true(errors.any(error => error.contains("kind")))
  assert_true(errors.any(error => error.contains("policy_id")))
  assert_true(errors.any(error => error.contains("primary_book_id")))
}

///|
test "catalog identifiers reject path traversal and punctuation" {
  assert_true(valid_catalog_identifier("research-ai-agents"))
  assert_false(valid_catalog_identifier("../research-ai-agents"))
  assert_false(valid_catalog_identifier("Research Agents"))
  assert_false(valid_catalog_identifier("research--agents"))
  let catalog = valid_catalog_fixture()
  let invalid = { ..catalog, catalog_id: "../fixture" }
  assert_true(
    validate_knowledge_domain_catalog(invalid).any(error => {
      error.contains("path-safe identifier")
    }),
  )
}
