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
test "generic external research topics are web-first and reference-aware" {
  let entry = BookCatalogEntry::new(
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
  assert_true(request.contains("12k-15k english-word"))
  assert_true(request.contains("source-class blocker"))
  assert_true(request.contains("source-domain front-door discovery"))
  assert_true(request.contains("command fallback attempts"))
  assert_true(request.contains("execute_command"))
  assert_true(
    request.contains("fetch at least eight high-signal candidate pages"),
  )
  assert_true(research_reference_urls(topic).is_empty())
  assert_true(research_local_paths(topic).is_empty())
  assert_true(!hints.contains("github.com/vectie"))
  assert_true(!hints.contains("/users/kq/workspace/euv"))
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
  assert_eq(entry.tags, [
    "research", "euv-lithography-machine-new-advantages-and-supplements", "topic:euv-lithography-machine-new-advantages-and-supplements",
    "explicit-book", "requested-book:research-euv-native-quality-v2",
  ])
  assert_true(entry.purpose.contains("do not create v1/v2/v3 forks"))
  let request = research_request_text(entry).to_lower()
  assert_true(
    request.contains(
      "topic: euv lithography machine new advantages and supplements",
    ),
  )
  assert_true(!request.contains("topic: euv native-quality-v2"))
}

///|
test "standing watch context hydration uses task prompt over bare goal" {
  let task = BookTask::new(
    id="standing-watch-opc-news-tick-1",
    goal=Some("Research latest One Person Company news."),
    title="Standing watch",
    kind="standing-watch",
    prompt="This is a MoonBook-owned 24/7 standing-watch cycle.\nstanding_goal_decision: update | no_change | needs_review | failed",
    priority=95,
    requires_review=false,
  )
  let goal = context_goal_for_task(task)
  assert_true(goal.contains("24/7 standing-watch"))
  assert_true(goal.contains("standing_goal_decision"))
  assert_true(!goal.contains("Research latest One Person Company news."))
}

///|
test "regular context hydration still honors explicit task goal" {
  let task = BookTask::new(
    id="research-opc-bootstrap",
    goal=Some("Research One Person Company."),
    title="Bootstrap",
    kind="bootstrap_gather",
    prompt="Detailed bootstrap prompt",
    priority=100,
    requires_review=true,
  )
  assert_eq(context_goal_for_task(task), "Research One Person Company.")
}

///|
test "research bootstrap profile is direct MoonClaw execution" {
  let profile_text = moontown_research_bootstrap_profile_json()
  assert_true(profile_text.contains("moontown_research_bootstrap_worker"))
  assert_true(profile_text.contains("\"role\": \"worker\""))
  assert_true(profile_text.contains("research_bootstrap_sources"))
  assert_true(profile_text.contains("research_bootstrap_source_expansion"))
  assert_true(profile_text.contains("research_bootstrap_report"))
  assert_true(profile_text.contains("research_bootstrap_quality_repair"))
  assert_true(profile_text.contains("Use native web_search first"))
  assert_true(profile_text.contains("focused source-expansion stage"))
  assert_true(profile_text.contains("optional raw/bootstrap/QUALITY_REPAIR.md"))
  assert_true(profile_text.contains("tool-backed self-review"))
  assert_true(profile_text.contains("No active quality repair"))
  assert_true(profile_text.contains("treat this as repair mode"))
  assert_true(profile_text.contains("preserve the existing report"))
  assert_true(profile_text.contains("review gate"))
  assert_true(profile_text.contains("repair in-place"))
  assert_true(profile_text.contains("REFERENCE_SOURCE_HINTS.md"))
  assert_true(
    profile_text.contains(
      "Do not load the full reference report in this source-screening stage",
    ),
  )
  assert_true(profile_text.contains("final deep-research review gate"))
  assert_true(profile_text.contains("Six included sources is the minimum"))
  assert_true(profile_text.contains("ten to fourteen"))
  assert_true(profile_text.contains("extract candidate result URLs"))
  assert_true(profile_text.contains("13k-15k English-word"))
  assert_true(profile_text.contains("hard acceptance floor of 12k words"))
  assert_true(profile_text.contains("reference line-count target"))
  assert_true(profile_text.contains("\"disable_adaptive\": true"))
  assert_true(profile_text.contains("\"web_search\": true"))
  assert_true(profile_text.contains("\"retry_max_attempts\": 3"))
  assert_true(profile_text.contains("\"retry_backoff_ms\": 4000"))
  assert_true(profile_text.contains("\"timeout_ms\": 900000"))
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

///|
test "standing watch context is not mistaken for research bootstrap" {
  let entry = BookCatalogEntry::new(
    id="research-opc",
    name="One Person Company",
    purpose="Track OPC research",
    workspace_root="/tmp/research-opc",
  )
  let bundle = WorkerContextBundle::{
    book_id: "research-opc",
    workspace_root: "/tmp/research-opc",
    task_id: "standing-watch-opc-news-tick-3",
    prompt: "This is a MoonBook-owned 24/7 standing-watch cycle. Research OPC, compare wiki history, wiki/sources, and raw/bootstrap baseline only as context. standing_goal_decision: update | no_change | needs_review | failed",
    policy: [],
    routines: [],
    skill_paths: ["skills/standing-watch/SKILL.md"],
    context_pages: ["history/standing-watch.md", "raw/bootstrap/"],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "watch baseline",
    output_contract: ["standing_goal_decision"],
  }
  let clean = enrich_worker_context_bundle(entry, bundle)
  assert_true(clean.prompt.contains("24/7 standing-watch"))
  assert_true(clean.skill_paths.contains("skills/standing-watch/SKILL.md"))
  assert_true(clean.output_contract.join("\n").contains("new_source_count"))
  assert_true(clean.output_contract.join("\n").contains("book_changed"))
  assert_true(!clean.prompt.contains("raw research bootstrap handoff"))
  assert_true(!clean.skill_paths.contains("skills/wiki-marketing/SKILL.md"))
}

///|
test "sparse worker context gets keeper-safe defaults before MoonClaw import" {
  let entry = BookCatalogEntry::new(
    id="coding",
    name="Coding",
    purpose="Keep coding workspace healthy",
    workspace_root="/tmp/coding",
  )
  let task = BookTask::new(
    id="coding-synthesis",
    title="Synthesize coding memory",
    kind="synthesis",
    prompt="Review the protocol and keep harness memory healthy.",
    priority=80,
    requires_review=true,
  )
  let bundle = WorkerContextBundle::{
    book_id: "coding",
    workspace_root: "/tmp/coding",
    task_id: "coding-synthesis",
    prompt: "Review coding memory.",
    policy: [],
    routines: [],
    skill_paths: [],
    context_pages: [],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "empty sparse bundle",
    output_contract: [],
  }
  let clean = finalize_worker_context_bundle(entry, task, bundle)
  assert_eq(clean.context_pages, ["wiki/index.md", "wiki/log.md"])
  assert_eq(clean.skill_paths, ["skills/wiki-maintainer/SKILL.md"])
}

///|
test "sparse worker context prefers book skills and task target pages" {
  let entry = BookCatalogEntry::new(
    id="finance",
    name="Finance",
    purpose="Maintain finance memory",
    workspace_root="/tmp/finance",
    skills=["skills/ledger-review/SKILL.md"],
  )
  let task = BookTask::new(
    id="finance-synthesis",
    title="Synthesize finance memory",
    kind="synthesis",
    prompt="Review the ledger workflow.",
    priority=80,
    requires_review=true,
    target_pages=["wiki/synthesis/overview.md"],
  )
  let bundle = WorkerContextBundle::{
    book_id: "finance",
    workspace_root: "/tmp/finance",
    task_id: "finance-synthesis",
    prompt: "Review finance memory.",
    policy: [],
    routines: [],
    skill_paths: ["  "],
    context_pages: [""],
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "empty sparse bundle",
    output_contract: [],
  }
  let clean = finalize_worker_context_bundle(entry, task, bundle)
  assert_eq(clean.context_pages, ["wiki/synthesis/overview.md"])
  assert_eq(clean.skill_paths, ["skills/ledger-review/SKILL.md"])
}

///|
test "evidence accounting separates operational watcher records from domain evidence" {
  let content =
    #|# Evidence
    #|
    #|## Records
    #|
    #|### EV-standing-watch-opc-news-tick-1
    #|
    #|- Task ID: `standing-watch-opc-news-tick-1`
    #|- Status: `accepted`
    #|- Summary: standing_goal_decision: no_change
    #|delta_score: 10
    #|new_source_count: 0
    #|next_check_hint: slower
    #|checked_sources_count: 4
    #|new_sources_found: 1
    #|accepted_facts_count: 0
    #|rejected_facts_count: 1
    #|wiki_pages_changed_count: 0
    #|book_changed: no
    #|
    #|### EV-provider-standing-watch-update
    #|
    #|- Task ID: `provider-standing-watch-update`
    #|- Status: `accepted`
    #|- Summary: standing_goal_decision: update
    #|delta_score: 82
    #|new_source_count: 2
    #|next_check_hint: normal
    #|checked_sources_count: 6
    #|new_sources_found: 3
    #|accepted_facts_count: 2
    #|rejected_facts_count: 1
    #|wiki_pages_changed_count: 2
    #|book_changed: yes
    #|
    #|### EV-source-analysis
    #|
    #|- Task ID: `research-source-analysis`
    #|- Status: `accepted`
    #|- Summary: Added durable source evidence for the current research thesis.
    #|

  let accounting = evidence_accounting_from_text(content)
  assert_eq(accounting.total_count, 3)
  assert_eq(accounting.operational_count, 1)
  assert_eq(accounting.domain_count, 2)
}

///|
test "standing watcher run without marker block is operational evidence" {
  let content =
    #|# Evidence
    #|
    #|## Records
    #|
    #|### EV-standing-watch-llm-training-tick-5502
    #|
    #|- Task ID: `standing-watch-llm-training-tick-5502`
    #|- Status: `accepted`
    #|- Summary: MoonClaw run run-20260526-124123-usersk completed: Workflow completed workspace=/tmp/book/moonclaw-jobs/run-20260526-124123-usersk
    #|

  let accounting = evidence_accounting_from_text(content)
  assert_eq(accounting.total_count, 1)
  assert_eq(accounting.operational_count, 1)
  assert_eq(accounting.domain_count, 0)
}

///|
test "evidence accounting summary appends split counts" {
  let summary = append_evidence_accounting_summary("pages=17 evidence=225", {
    total_count: 225,
    domain_count: 17,
    operational_count: 208,
  })
  assert_true(summary.contains("domain_evidence=17"))
  assert_true(summary.contains("operational_evidence=208"))
  assert_true(summary.contains("total_evidence=225"))
}
