///|
fn context_goal_for_task(task : BookTask) -> String {
  if task.kind == "standing-watch" {
    task.prompt
  } else {
    task.goal.unwrap_or(task.prompt)
  }
}

///|
fn fallback_worker_context_bundle(
  entry : BookCatalogEntry,
  task : BookTask,
) -> WorkerContextBundle {
  {
    book_id: entry.id,
    workspace_root: resolved_workspace_root(entry.workspace_root),
    task_id: task.id,
    prompt: task.prompt,
    policy: @moonbook_contracts.fallback_keeper_policy_lines(),
    routines: @moonbook_contracts.fallback_keeper_routine_lines(),
    skill_paths: @moonbook_contracts.default_keeper_skill_paths(),
    context_pages: default_keeper_context_pages(task),
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: @moonbook_contracts.fallback_keeper_memory_summary(
      entry.id,
      task.id,
    ),
    output_contract: @moonbook_contracts.fallback_keeper_output_contract_lines(),
  }
}

///|
fn finalize_worker_context_bundle(
  entry : BookCatalogEntry,
  task : BookTask,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let bundle_skill_paths = unique_nonblank_paths(bundle.skill_paths)
  let skill_paths = if bundle_skill_paths.length() == 0 {
    default_keeper_skill_paths(entry)
  } else {
    bundle_skill_paths
  }
  let bundle_context_pages = unique_nonblank_paths(bundle.context_pages)
  let context_pages = if bundle_context_pages.length() == 0 {
    default_keeper_context_pages(task)
  } else {
    bundle_context_pages
  }
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths: if skill_paths.length() == 0 {
      @moonbook_contracts.default_keeper_skill_paths()
    } else {
      skill_paths
    },
    context_pages: if context_pages.length() == 0 {
      ["wiki/index.md"]
    } else {
      context_pages
    },
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract: bundle.output_contract,
  }
}

///|
fn default_keeper_skill_paths(entry : BookCatalogEntry) -> Array[String] {
  let skill_paths = unique_nonblank_paths(entry.skills)
  if skill_paths.length() == 0 {
    @moonbook_contracts.default_keeper_skill_paths()
  } else {
    skill_paths
  }
}

///|
fn default_keeper_context_pages(task : BookTask) -> Array[String] {
  let context_pages = unique_nonblank_paths(task.target_pages)
  if context_pages.length() == 0 {
    @moonbook_contracts.default_keeper_context_pages()
  } else {
    context_pages
  }
}
