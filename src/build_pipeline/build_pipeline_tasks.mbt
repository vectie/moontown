///|
pub fn wenyu_build_task_limit(task_limit : Int) -> Int {
  if task_limit < 4 {
    4
  } else {
    task_limit
  }
}

///|
pub fn wenyu_build_tasks(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  repo_root : String,
) -> Array[@moonbook.BookTask] {
  let module_name = wenyu_module_name(entry)
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
      required_role=Some(Planner),
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
        "build/CODE_PATCH.md", "build/TEST_RESULTS.md", "repo:this-moontown-checkout",
      ],
      required_role=Some(Harness),
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
        "build/ASSET_PROMPTS.md",
        "build/ASSET_MANIFEST.md",
        @policy.default_generated_site_projection_path(),
      ],
      required_role=Some(Specialist),
    ),
  ]
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) =>
      [@civic.wenyu_civic_service_task(service, objective), ..build_tasks]
    None => build_tasks
  }
}

///|
pub fn wenyu_civic_service_plan_tasks(
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  ordered_tasks : Array[@moonbook.BookTask],
) -> Array[@moonbook.BookTask] {
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      let service_task = @civic.wenyu_civic_service_task(service, objective)
      let merged = [service_task]
      for task in ordered_tasks {
        if task.id != service_task.id &&
          task.kind != "research-bootstrap-ingest" {
          merged.push(task)
        }
      }
      merged
    }
    None => ordered_tasks
  }
}

///|
pub fn positive_wenyu_task_limit(task_limit : Int) -> Int {
  if task_limit < 1 {
    1
  } else {
    task_limit
  }
}
