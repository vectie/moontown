///|
fn enrich_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  if catalog_entry_is_civic(entry) {
    return enrich_wenyu_worker_context_bundle(entry, bundle)
  }
  if !catalog_entry_is_research(entry) {
    return bundle
  }
  if is_standing_watch_context_bundle(bundle) {
    return standing_watch_worker_context_bundle(bundle)
  }
  if is_course_context_bundle(bundle) {
    return course_worker_context_bundle(entry, bundle)
  }
  if is_research_bootstrap_context_bundle(bundle) {
    return research_bootstrap_worker_context_bundle(entry, bundle)
  }
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/web-first-research/SKILL.md",
      "skills/research-evidence-synthesis/SKILL.md",
      "skills/repo-source-materialize/SKILL.md",
      "skills/wiki-marketing/SKILL.md",
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      "raw/bootstrap/RESEARCH_REQUEST.md",
      "raw/bootstrap/SOURCE_HINTS.md",
      "wiki/history/journey.md",
    ],
  )
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
    output_contract: bundle.output_contract,
  }
}
