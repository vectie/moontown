///|
fn standing_watch_worker_context_bundle(
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      ..@standing_watch_contracts.standing_watch_skill_paths(),
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      ..@standing_watch_contracts.standing_watch_context_pages(),
    ],
  )
  let output_contract = unique_paths(
    [
      ..bundle.output_contract,
      ..@standing_watch_contracts.standing_watch_output_contract_lines(),
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
    output_contract,
  }
}
