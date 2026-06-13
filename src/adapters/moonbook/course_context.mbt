///|
fn course_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = unique_paths(
    [..bundle.skill_paths, ..@course_contracts.course_skill_paths()],
  )
  let context_pages = unique_paths(
    [..bundle.context_pages, ..@course_contracts.course_context_pages()],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: course_worker_prompt(entry, bundle),
    policy: @course_contracts.course_worker_policy_lines(),
    routines: @course_contracts.course_worker_routine_lines(),
    skill_paths,
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: @course_contracts.course_worker_memory_summary(entry.id),
    output_contract: @course_contracts.course_output_contract_lines(),
  }
}

///|
fn course_worker_prompt(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> String {
  let display = display_topic_name(research_topic_id(entry))
  @course_contracts.course_worker_prompt(display, bundle.prompt)
}
