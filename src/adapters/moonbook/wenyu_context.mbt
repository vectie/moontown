///|
fn enrich_wenyu_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  ignore(entry)
  let civic_context = is_wenyu_civic_context_bundle(bundle)
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      ..wenyu_civic_skill_paths(civic_context, bundle.context_pages),
      ..wenyu_base_skill_paths(),
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      ..wenyu_base_context_pages(),
      ..wenyu_civic_context_pages(civic_context),
    ],
  )
  let output_contract = if civic_context {
    unique_paths(
      [
        ..bundle.output_contract,
        "civic_service_decision: update | no_change | needs_review | blocked",
        "book_changed: yes | no",
        "wiki_pages_changed_count: <integer>",
        "changed_pages: comma-separated durable page paths, or none",
        "accepted_facts_count: <integer>",
        "review_items_created_count: <integer>",
        "review_items: comma-separated review item ids/paths, or none",
        "projection_updated: yes | no",
        "projection_delta: one sentence explaining the projection-safe change, or blocked:<reason>",
        "protocol_decision_basis: one sentence naming the evidence, ledger, or blocker basis for the decision",
        "next_check_hint: normal | faster | slower | review",
      ],
    )
  } else {
    bundle.output_contract
  }
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths,
    context_pages,
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract,
  }
}

///|
fn wenyu_base_skill_paths() -> Array[String] {
  [
    "skills/wenyu-build/SKILL.md", "skills/wenyu-code-patch/SKILL.md", "skills/wenyu-asset-pack/SKILL.md",
    "skills/web-first-research/SKILL.md", "skills/research-evidence-synthesis/SKILL.md",
    "skills/repo-source-materialize/SKILL.md", "skills/wiki-marketing/SKILL.md",
  ]
}

///|
fn wenyu_civic_skill_paths(
  civic_context : Bool,
  context_pages : Array[String],
) -> Array[String] {
  if civic_context {
    [
      "skills/wenyu-civic-service/SKILL.md",
      ..skill_paths_from_context_pages(context_pages),
    ]
  } else {
    []
  }
}

///|
fn wenyu_base_context_pages() -> Array[String] {
  [
    "raw/bootstrap/RESEARCH_REQUEST.md",
    "raw/bootstrap/SOURCE_HINTS.md",
    wenyu_prd_path(),
    wenyu_vision_path(),
    wenyu_build_report_path(),
    wenyu_evidence_matrix_path(),
    wenyu_marketing_brief_path(),
    wenyu_local_sources_path(),
    "mounted-sources/MANIFEST.md",
    "build/IMPLEMENTATION_BACKLOG.md",
    "build/ACCEPTANCE_TESTS.md",
  ]
}

///|
fn wenyu_prd_path() -> String {
  "raw/bootstrap/WENYU_VALLEY_PRD.md"
}

///|
fn wenyu_vision_path() -> String {
  "raw/bootstrap/WENYU_VISION.md"
}

///|
fn wenyu_build_report_path() -> String {
  "raw/bootstrap/deep-report.md"
}

///|
fn wenyu_evidence_matrix_path() -> String {
  "raw/bootstrap/evidence-matrix.md"
}

///|
fn wenyu_marketing_brief_path() -> String {
  "raw/bootstrap/marketing-brief.md"
}

///|
fn wenyu_local_sources_path() -> String {
  "raw/bootstrap/local-sources.md"
}

///|
fn wenyu_civic_context_pages(civic_context : Bool) -> Array[String] {
  if civic_context {
    [wenyu_civic_service_contract_path(), "book/moonbook-ui-state.json"]
  } else {
    []
  }
}

///|
fn wenyu_civic_service_contract_path() -> String {
  "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md"
}
