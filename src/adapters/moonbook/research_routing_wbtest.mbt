///|
test "OPC research hints are external-domain web first" {
  let entry = moonbook_adapter_opc_research_entry()
  let hints = research_source_hints_text(entry)
  let lower = hints.to_lower()
  assert_true(lower.contains("external domain research topic"))
  assert_true(lower.contains("one person company"))
  assert_true(lower.contains("web search first"))
  assert_true(lower.contains("opc.community"))
  assert_true(lower.contains("gov.uk/running-a-limited-company"))
  assert_true(!lower.contains("vectie opc"))
  assert_true(!lower.contains("github.com/vectie/opc"))
  assert_true(!lower.contains("/users/kq/workspace/opc"))
}

///|
test "generated site index points at live generated MoonBook output layout" {
  let root = "/tmp/moontown-generated-site-layout"
  let entry = moonbook_adapter_opc_research_entry(workspace_root=root)
  assert_eq(
    generated_site_index_path(entry),
    "\{root}/\{@policy.default_generated_site_projection_path()}",
  )
}

///|
test "OPC research request rejects guessed local repo path" {
  let entry = moonbook_adapter_opc_research_entry()
  let request = research_request_text(entry).to_lower()
  assert_true(request.contains("one person company model"))
  assert_true(request.contains("do not infer a local repository"))
  assert_true(request.contains("fetch that page"))
  assert_true(!request.contains("official repositories, maintainer docs"))
}

///|
test "generic external research topics are web-first and reference-aware" {
  let entry = moonbook_adapter_external_research_entry(
    id="research-euv-lithography-machine-new-advantages-and-supplements",
    name="EUV lithography machine new advantages and supplements",
    purpose="Research EUV lithography technology routes",
    workspace_root="/tmp/research-euv",
  )
  let topic = research_topic_id(entry)
  let request = research_request_text(entry).to_lower()
  let hints = research_source_hints_text(entry).to_lower()
  assert_true(is_external_domain_research_topic(topic))
  assert_true(request.contains("new advantages or supplements are emerging"))
  assert_true(request.contains("reference_style.md"))
  assert_true(request.contains("reference_output.md"))
  assert_true(hints.contains("reference_source_hints.md"))
  assert_true(hints.contains("external domain research topic"))
  assert_true(hints.contains("technology roadmap 2026"))
  assert_true(hints.contains("optional reference style inputs"))
  assert_true(
    request.contains(research_policy_deep_dossier_word_target().to_lower()),
  )
  assert_true(request.contains("source-class blocker"))
  assert_true(request.contains("source-domain front-door discovery"))
  assert_true(request.contains("command fallback attempts"))
  assert_true(request.contains("execute_command"))
  assert_true(
    request.contains(
      "fetch at least \{research_policy_harvest_candidate_fetch_count()} high-signal candidate pages",
    ),
  )
  assert_true(research_reference_urls(topic).is_empty())
  assert_true(research_local_paths(topic).is_empty())
  assert_true(!hints.contains("github.com/vectie"))
  assert_true(!hints.contains("/users/kq/workspace/euv"))
}

///|
test "tagged research topic does not require research prefix" {
  let entry = BookCatalogEntry::new(
    id="opc-lab",
    name="OPC Lab",
    purpose="Research OPC.",
    workspace_root="/tmp/opc-lab",
    tags=["research", "topic:opc"],
  )
  assert_eq(research_topic_id(entry), "opc")
  let request = research_request_text(entry).to_lower()
  assert_true(request.contains("one person company model"))
}

///|
test "versioned explicit research book id canonicalizes to stable topic book" {
  let entry = entry_for_explicit_research_book(
    default_catalog(),
    "research-euv-native-quality-v2",
    "research euv lithography machine new advantages and supplements",
  ).unwrap()
  assert_eq(
    entry.id,
    "research-euv-lithography-machine-new-advantages-and-supplements",
  )
  assert_true(
    entry.tags ==
    [
      "research", "euv-lithography-machine-new-advantages-and-supplements", "topic:euv-lithography-machine-new-advantages-and-supplements",
      "explicit-book", "requested-book:research-euv-native-quality-v2",
    ],
  )
  assert_true(entry.purpose.contains("do not create v1/v2/v3 forks"))
  let request = research_request_text(entry).to_lower()
  assert_true(
    request.contains(
      "topic: euv lithography machine new advantages and supplements",
    ),
  )
  assert_true(!request.contains("topic: euv native-quality-v2"))
}
