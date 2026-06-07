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
    policy: [
      "Keep all memory and durable artifacts inside this book unless the task explicitly names a repository patch.",
      "Return explicit blockers instead of fake completion when required tools or sources are missing.",
      "Preserve Moontown, MoonBook, and MoonClaw responsibility boundaries.",
    ],
    routines: [
      "Read task context pages first.", "Create or update target pages listed in the task when applicable.",
      "Report changed files, artifacts, blockers, and validation results.",
    ],
    skill_paths: ["skills/wiki-maintainer/SKILL.md"],
    context_pages: default_keeper_context_pages(task),
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "Fallback MoonBook context for externally planned task `\{task.id}` in book `\{entry.id}`.",
    output_contract: [
      "task_id", "summary", "artifacts", "memory_candidates", "requires_review",
      "notify_town",
    ],
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
      ["skills/wiki-maintainer/SKILL.md"]
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
    ["skills/wiki-maintainer/SKILL.md"]
  } else {
    skill_paths
  }
}

///|
fn default_keeper_context_pages(task : BookTask) -> Array[String] {
  let context_pages = unique_nonblank_paths(task.target_pages)
  if context_pages.length() == 0 {
    ["wiki/index.md", "wiki/log.md"]
  } else {
    context_pages
  }
}
