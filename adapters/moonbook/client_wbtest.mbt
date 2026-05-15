///|
test "book-local moonclaw provider manifest entry is stable" {
  let root = "/tmp/moontown-provider-manifest-book"
  let moonbook_root = "/tmp/moontown-provider-manifest-moonbook"
  let path = moonclaw_provider_manifest_path(root)
  let provider = moonbook_task_provider_manifest_entry(root, moonbook_root)
  assert_eq(
    path, "/tmp/moontown-provider-manifest-book/.moonclaw/providers.json",
  )
  assert_eq(provider.name, "moonbook")
  assert_eq(provider.kind, "task-provider")
  assert_eq(provider.metadata.command, "moon")
  assert_eq(provider.metadata.args, ["run", "cmd/main", "--"])
  assert_eq(provider.metadata.cwd, moonbook_root)
  assert_eq(provider.metadata.workspace_root, root)
  assert_true(provider.capabilities.contains("moonbook.bookapi"))
}

///|
test "OPC research hints are external-domain web first" {
  let entry = BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root="/tmp/research-opc",
  )
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
  let entry = BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root=root,
  )
  assert_eq(
    generated_site_index_path(entry),
    "\{root}/book/site/generated/index.html",
  )
}

///|
test "OPC research request rejects guessed local repo path" {
  let entry = BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root="/tmp/research-opc",
  )
  let request = research_request_text(entry).to_lower()
  assert_true(request.contains("one person company model"))
  assert_true(request.contains("do not infer a local repository"))
  assert_true(request.contains("fetch that page"))
  assert_true(!request.contains("official repositories, maintainer docs"))
}

///|
test "research bootstrap profile is direct MoonClaw execution" {
  let profile_text = moontown_research_bootstrap_profile_json()
  assert_true(profile_text.contains("moontown_research_bootstrap_worker"))
  assert_true(profile_text.contains("\"role\": \"worker\""))
  assert_true(profile_text.contains("research_bootstrap_sources"))
  assert_true(profile_text.contains("research_bootstrap_report"))
  assert_true(profile_text.contains("Use native web_search first"))
  assert_true(profile_text.contains("\"web_search\": true"))
  assert_true(profile_text.contains("\"retry_max_attempts\": 1"))
  assert_true(profile_text.contains("\"best_effort_on_timeout\": true"))
  assert_true(profile_text.contains("curl -L --max-time 12"))
  assert_true(profile_text.contains("Return plain Markdown, not JSON"))
  assert_true(profile_text.contains("raw/bootstrap/deep-report.md"))
  assert_true(
    profile_text.contains("Do not update wiki pages in this worker stage"),
  )
  assert_true(!profile_text.contains("research_bootstrap_question"))
  assert_true(!profile_text.contains("\"execution_mode\": \"provider\""))
}

///|
test "research bootstrap context is sanitized for direct MoonClaw worker" {
  let entry = BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root="/tmp/research-opc",
  )
  let bundle = WorkerContextBundle::{
    book_id: "research-opc",
    workspace_root: "/tmp/research-opc",
    task_id: "goal-research-opc-research-bootstrap-ingest",
    prompt: "Loaded skill excerpts and local source hints for moonbook /Users/kq/Workspace/moonbook",
    policy: [],
    routines: [],
    skill_paths: [
      "skills/wiki-ingest/SKILL.md", "skills/repo-source-materialize/SKILL.md",
    ],
    context_pages: ["wiki/sources", "/Users/kq/Workspace/moonbook/README.md"],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "dirty",
    output_contract: ["Return exactly one JSON object."],
  }
  let clean = enrich_worker_context_bundle(entry, bundle)
  assert_true(clean.prompt.contains("raw research bootstrap handoff"))
  assert_true(clean.output_contract.join("\n").contains("plain Markdown"))
  assert_true(clean.skill_paths.contains("skills/web-first-research/SKILL.md"))
  assert_true(
    !clean.skill_paths.contains("skills/repo-source-materialize/SKILL.md"),
  )
  assert_true(
    !clean.context_pages.contains("/Users/kq/Workspace/moonbook/README.md"),
  )
  assert_true(!clean.prompt.contains("/Users/kq/Workspace/moonbook"))
}
