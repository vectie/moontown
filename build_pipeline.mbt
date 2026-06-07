///|
fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  entry.id.has_prefix("wenyu-")
}

///|
async fn wenyu_book_ready_for_build(entry : @moonbook.BookCatalogEntry) -> Bool {
  if !is_wenyu_book(entry) {
    return false
  }
  let root = @moonbook.workspace_root(entry)
  let required = [
    "raw/bootstrap/deep-report.md", "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/marketing-brief.md",
    "raw/bootstrap/local-sources.md", "mounted-sources/MANIFEST.md",
  ]
  workspace_relative_paths_ready(root, required)
}

///|
fn wenyu_build_task_limit(task_limit : Int) -> Int {
  if task_limit < 4 {
    4
  } else {
    task_limit
  }
}

///|
fn wenyu_build_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> ResearchBootstrapPlan {
  {
    tasks: wenyu_build_tasks(entry, objective),
    task_limit: wenyu_build_task_limit(task_limit),
    bootstrap_active: false,
  }
}

///|
fn wenyu_build_tasks(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
) -> Array[@moonbook.BookTask] {
  let module_name = wenyu_module_name(entry)
  let repo_root = moontown_repo_root()
  let build_tasks = [
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-implementation-backlog",
      goal=Some(objective),
      title="Compile implementation backlog for \{module_name}",
      kind="implementation-backlog",
      prompt=wenyu_implementation_backlog_prompt(entry, objective, repo_root),
      priority=120,
      requires_review=true,
      target_pages=[
        "build/IMPLEMENTATION_BACKLOG.md",
        "build/ACCEPTANCE_TESTS.md",
        "wiki/synthesis/\{entry.id}-build-plan.md",
      ],
      required_role=Some(@core.WorkerRole::Planner),
    ),
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-code-patch",
      goal=Some(objective),
      title="Implement code slice for \{module_name}",
      kind="code-patch",
      prompt=wenyu_code_patch_prompt(entry, objective, repo_root),
      priority=115,
      requires_review=true,
      target_pages=[
        "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "repo:/Users/kq/Workspace/moontown",
      ],
      required_role=Some(@core.WorkerRole::Harness),
    ),
    @moonbook.BookTask::new(
      id="goal-\{entry.id}-asset-pack",
      goal=Some(objective),
      title="Generate asset and projection pack for \{module_name}",
      kind="image-asset",
      prompt=wenyu_asset_pack_prompt(entry, objective, repo_root),
      priority=110,
      requires_review=true,
      target_pages=[
        "build/ASSET_PROMPTS.md", "build/ASSET_MANIFEST.md", "book/site/generated/index.html",
      ],
      required_role=Some(@core.WorkerRole::Specialist),
    ),
  ]
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      [@civic.wenyu_civic_service_task(service, objective), ..build_tasks]
    None => build_tasks
  }
}

///|
fn wenyu_civic_service_plan(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      let service_task = @civic.wenyu_civic_service_task(service, objective)
      let ordered = prioritized_tasks(tasks, objective)
      let merged = [service_task]
      for task in ordered {
        if task.id != service_task.id &&
          task.kind != "research-bootstrap-ingest" {
          merged.push(task)
        }
      }
      {
        tasks: merged,
        task_limit: if task_limit < 1 {
          1
        } else {
          task_limit
        },
        bootstrap_active: false,
      }
    }
    None =>
      {
        tasks: prioritized_tasks(tasks, objective),
        task_limit: if task_limit < 1 {
          1
        } else {
          task_limit
        },
        bootstrap_active: false,
      }
  }
}
