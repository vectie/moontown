///|
fn research_bootstrap_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = [
    "skills/web-first-research/SKILL.md", "skills/source-diarize/SKILL.md", "skills/research-evidence-synthesis/SKILL.md",
    "skills/research-report/SKILL.md", "skills/wiki-marketing/SKILL.md",
  ]
  let context_pages = [
    "raw/bootstrap/RESEARCH_REQUEST.md", "raw/bootstrap/SOURCE_HINTS.md", "raw/bootstrap/REFERENCE_STYLE.md",
    "raw/bootstrap/REFERENCE_OUTPUT.md", "raw/bootstrap/REFERENCE_SOURCE_HINTS.md",
  ]
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: research_bootstrap_worker_prompt(entry),
    policy: [
      "MoonClaw owns raw evidence/report execution for this bootstrap worker.", "MoonBook owns durable wiki materialization after raw artifacts are ready.",
      "Use web discovery before local file inspection; do not infer a local repository for external-domain topics.",
      "If a tool or source is blocked, record the exact blocker and continue with clearly labeled evidence limits.",
    ],
    routines: [
      "Read `raw/bootstrap/RESEARCH_REQUEST.md` and `raw/bootstrap/SOURCE_HINTS.md` first.",
      "Produce raw bootstrap artifacts with provenance, source IDs, claim IDs, and blockers.",
      "Return a concise Markdown handoff summary from each worker step.",
    ],
    skill_paths,
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "Sanitized Moontown research bootstrap context for `\{entry.id}`.",
    output_contract: research_bootstrap_output_contract_lines(),
  }
}

///|
fn research_bootstrap_worker_prompt(entry : BookCatalogEntry) -> String {
  let display = display_topic_name(research_topic_id(entry))
  [
    "Own the MoonClaw raw research bootstrap handoff for \{display}.",
    "",
    "Use the generated job profile steps as the execution authority:",
    "- stage 1 writes research question and starter search log",
    "- stage 2 performs bounded web/source screening",
    "- stage 3 writes evidence matrix, synthesis brief, deep report, and marketing brief",
    "",
    "Do not materialize durable `wiki/*` pages in the worker stage. MoonBook will materialize wiki pages from the raw evidence envelope.",
    "Do not treat \{display} as a local repository unless screened sources prove that interpretation.",
    "Do not hard-code final research claims. Let the LLM choose sources and claims from screened evidence.",
    research_bootstrap_context_reference_style_policy(),
    research_bootstrap_context_reference_source_policy(),
  ].join("\n")
}

///|
fn research_bootstrap_context_reference_style_policy() -> String {
  [
    "If `raw/bootstrap/REFERENCE_STYLE.md` or `raw/bootstrap/REFERENCE_OUTPUT.md` exists, use it only as a style, length, language, and quality target.",
    "Do not import its claims as evidence for this topic.",
  ].join(" ")
}

///|
fn research_bootstrap_context_reference_source_policy() -> String {
  [
    "If `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` exists, treat it as a candidate lead sheet only.",
    "Fetch, screen, accept, reject, or mark blocked.", "Never cite it as evidence by itself.",
  ].join(" ")
}

///|
fn research_bootstrap_output_contract_lines() -> Array[String] {
  [
    "For direct Moontown research bootstrap worker steps, return plain Markdown summaries unless a step prompt explicitly asks for JSON.",
    "Do not return adaptive-planning JSON such as `needs_subplan` or `suggested_substeps`.",
    "Raw artifacts must be workspace-relative paths under `raw/bootstrap/`.",
    research_bootstrap_required_artifacts_contract(),
    "If any artifact cannot be produced, write a blocker artifact and explain the missing tool or source.",
  ]
}

///|
fn research_bootstrap_required_artifacts_contract() -> String {
  [
    "Required raw artifacts before the handoff is complete:",
    "\{research_raw_bootstrap_artifacts_sentence()}.",
  ].join(" ")
}
