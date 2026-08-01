///|
fn schema_object_field(
  fields : Map[String, Json],
  key : String,
) -> Map[String, Json] raise {
  match fields.get(key) {
    Some(Object(value)) => value
    _ => fail("expected JSON Schema object field `\{key}`")
  }
}

///|
fn schema_enum_values(
  definitions : Map[String, Json],
  key : String,
) -> Array[String] raise {
  let definition = schema_object_field(definitions, key)
  match definition.get("enum") {
    Some(Array(values)) => {
      let result : Array[String] = []
      for value in values {
        match value {
          String(item) => result.push(item)
          _ => fail("schema enum `\{key}` contains a non-string value")
        }
      }
      result
    }
    _ => fail("schema definition `\{key}` must declare an enum")
  }
}

///|
fn schema_string_field(
  fields : Map[String, Json],
  key : String,
) -> String raise {
  match fields.get(key) {
    Some(String(value)) => value
    _ => fail("expected JSON Schema string field `\{key}`")
  }
}

///|
fn schema_property_reference(
  properties : Map[String, Json],
  key : String,
) -> String raise {
  schema_string_field(schema_object_field(properties, key), "$ref")
}

///|
fn source_readiness_catalog_fixture() -> @domain_catalog.KnowledgeDomainCatalog {
  {
    schema: @domain_catalog.knowledge_domain_catalog_schema(),
    catalog_id: "source-readiness-fixture",
    version: @domain_catalog.knowledge_domain_catalog_version(),
    seed: 20260727,
    description: "Source readiness fixture",
    policies: [
      {
        id: "research-watch-v1",
        version: 1,
        template_id: "domain-research-book",
        source_policy: "primary-sources",
        evidence_policy: "primary-source-required",
        cadence: "daily",
        cadence_ticks: 24,
        quality_threshold: 86,
        review_chain: ["specialist", "independent-reviewer", "keeper"],
        max_revision_rounds: 2,
        schedule_tier: "daily",
        budget_class: "standard",
        completion_claim: "evidence-backed-research",
      },
    ],
    domains: [
      {
        domain_id: "source-readiness",
        title: "Source Readiness",
        icon: "book",
        building_id: "source-readiness-lab",
        kind: "knowledge-domain",
        primary_book_id: "source-readiness-book",
        policy_id: "research-watch-v1",
        communication_scenario_ids: [],
        summary: "Verify that provisioning and source readiness stay distinct.",
        books: [
          {
            book_id: "source-readiness-book",
            title: "Source Readiness Book",
            question: "Which approved evidence sources should this book watch?",
            role: "owner",
            template_id: "domain-research-book",
            policy_id: "research-watch-v1",
            schedule_tier: "daily",
            cadence_ticks: 24,
            tags: ["sources", "readiness"],
            source_policy: "primary-sources",
            status: "active",
          },
        ],
      },
    ],
  }
}

///|
async test "JSON Schema enums mirror every MoonBit catalog vocabulary" {
  let schema = @json.parse(
    @fs.read_file("schemas/knowledge-domain-catalog.schema.json").text(),
  ) catch {
    error => fail("schema must parse: \{error}")
  }
  let root = match schema {
    Object(fields) => fields
    _ => fail("schema root must be an object")
  }
  let definitions = schema_object_field(root, "$defs")
  let vocabulary = @domain_catalog.knowledge_domain_catalog_vocabulary()
  assert_eq(
    schema_enum_values(definitions, "domain_kind"),
    vocabulary.domain_kinds,
  )
  assert_eq(
    schema_enum_values(definitions, "template_id"),
    vocabulary.template_ids,
  )
  assert_eq(
    schema_enum_values(definitions, "source_policy"),
    vocabulary.source_policies,
  )
  assert_eq(
    schema_enum_values(definitions, "evidence_policy"),
    vocabulary.evidence_policies,
  )
  assert_eq(schema_enum_values(definitions, "cadence"), vocabulary.cadences)
  assert_eq(
    schema_enum_values(definitions, "schedule_tier"),
    vocabulary.schedule_tiers,
  )
  assert_eq(
    schema_enum_values(definitions, "budget_class"),
    vocabulary.budget_classes,
  )
  assert_eq(
    schema_enum_values(definitions, "completion_claim"),
    vocabulary.completion_claims,
  )
  assert_eq(
    schema_enum_values(definitions, "review_role"),
    vocabulary.review_roles,
  )
  assert_eq(schema_enum_values(definitions, "book_role"), vocabulary.book_roles)
  assert_eq(
    schema_enum_values(definitions, "book_status"),
    vocabulary.book_statuses,
  )
  let policy_properties = schema_object_field(
    schema_object_field(definitions, "policy"),
    "properties",
  )
  assert_eq(
    schema_property_reference(policy_properties, "template_id"),
    "#/$defs/template_id",
  )
  assert_eq(
    schema_property_reference(policy_properties, "source_policy"),
    "#/$defs/source_policy",
  )
  assert_eq(
    schema_property_reference(policy_properties, "evidence_policy"),
    "#/$defs/evidence_policy",
  )
  assert_eq(
    schema_property_reference(policy_properties, "cadence"),
    "#/$defs/cadence",
  )
  assert_eq(
    schema_property_reference(policy_properties, "schedule_tier"),
    "#/$defs/schedule_tier",
  )
  assert_eq(
    schema_property_reference(policy_properties, "budget_class"),
    "#/$defs/budget_class",
  )
  assert_eq(
    schema_property_reference(policy_properties, "completion_claim"),
    "#/$defs/completion_claim",
  )
  let review_chain = schema_object_field(policy_properties, "review_chain")
  assert_eq(
    schema_string_field(schema_object_field(review_chain, "items"), "$ref"),
    "#/$defs/review_role",
  )
  let book_properties = schema_object_field(
    schema_object_field(definitions, "book"),
    "properties",
  )
  assert_eq(
    schema_property_reference(book_properties, "role"),
    "#/$defs/book_role",
  )
  assert_eq(
    schema_property_reference(book_properties, "template_id"),
    "#/$defs/template_id",
  )
  assert_eq(
    schema_property_reference(book_properties, "schedule_tier"),
    "#/$defs/schedule_tier",
  )
  assert_eq(
    schema_property_reference(book_properties, "source_policy"),
    "#/$defs/source_policy",
  )
  assert_eq(
    schema_property_reference(book_properties, "status"),
    "#/$defs/book_status",
  )
  let domain_properties = schema_object_field(
    schema_object_field(definitions, "domain"),
    "properties",
  )
  assert_eq(
    schema_property_reference(domain_properties, "kind"),
    "#/$defs/domain_kind",
  )
}

///|
async test "status is read-only and seed defers books until sources are configured" {
  let root = @fs.tmpdir(prefix="moontown-knowledge-source-readiness")
  let catalog_path = "\{root}/catalog.json"
  let snapshot_path = "\{root}/town.json"
  let catalog = source_readiness_catalog_fixture()
  @support.write_text_file(catalog_path, catalog.to_json().stringify(indent=2))
  let book = catalog.domains[0].books[0]
  let config_path = knowledge_catalog_book_config_path(
    catalog,
    book,
    snapshot_path~,
  )
  let request_path = knowledge_catalog_request_path(snapshot_path~)
  let initial_status = render_knowledge_domain_catalog_status(
    catalog_path~,
    snapshot_path~,
  )
  assert_true(
    initial_status.contains("Active books requiring source configuration: `1`"),
  )
  assert_true(initial_status.contains("blocked_by_source_configuration"))
  assert_false(@fs.exists(config_path))
  assert_false(@fs.exists(request_path))
  let first_seed = seed_knowledge_domain_catalog(catalog_path~, snapshot_path~)
  assert_true(
    first_seed.contains("New requests deferred for source configuration: `1`"),
  )
  assert_true(first_seed.contains("Newly pending template requests: `0`"))
  assert_true(@fs.exists(config_path))
  assert_false(@fs.exists(request_path))
  let configured = @pdf_evidence_watch.PdfEvidenceWatchInstallSpec::{
    book_id: book.book_id,
    title: book.title,
    purpose: book.question,
    websites: ["https://example.org/primary-source"],
    analysis_method: "Use attributable primary evidence.",
    analysis_method_path: "",
    cadence_ticks: book.cadence_ticks,
    workspace_root: "",
  }
  @support.write_text_file(
    config_path,
    configured.to_json().stringify(indent=2),
  )
  let second_seed = seed_knowledge_domain_catalog(catalog_path~, snapshot_path~)
  assert_true(second_seed.contains("Newly pending template requests: `1`"))
  assert_true(
    second_seed.contains("Active books with configured source references: `1`"),
  )
  let pending_status = render_knowledge_domain_catalog_status(
    catalog_path~,
    snapshot_path~,
  )
  assert_true(pending_status.contains("source_configured_install_pending"))
  let ledger = @book_templates_runtime.load_request_ledger(request_path)
  assert_eq(ledger.requests.length(), 1)
  @book_templates_runtime.save_request_ledger(request_path, {
    requests: [{ ..ledger.requests[0], status: "installed" }],
  })
  let installed_status = render_knowledge_domain_catalog_status(
    catalog_path~,
    snapshot_path~,
  )
  assert_true(installed_status.contains("workspace_installed"))
  assert_true(
    installed_status.contains("source_configured_not_research_verified"),
  )
  assert_true(installed_status.contains("never emits a `research_ready` claim"))
}
