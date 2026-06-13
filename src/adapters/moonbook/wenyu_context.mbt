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
      ..@civic_contracts.wenyu_base_skill_paths(),
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      ..@civic_contracts.wenyu_base_context_pages(),
      ..wenyu_civic_context_pages_for(civic_context),
    ],
  )
  let output_contract = if civic_context {
    unique_paths(
      [
        ..bundle.output_contract,
        ..@civic_contracts.wenyu_civic_output_contract_lines(),
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
fn wenyu_civic_skill_paths(
  civic_context : Bool,
  context_pages : Array[String],
) -> Array[String] {
  if civic_context {
    @civic_contracts.wenyu_civic_skill_paths(
      skill_paths_from_context_pages(context_pages),
    )
  } else {
    []
  }
}

///|
fn wenyu_civic_context_pages_for(civic_context : Bool) -> Array[String] {
  if civic_context {
    @civic_contracts.wenyu_civic_context_pages()
  } else {
    []
  }
}
