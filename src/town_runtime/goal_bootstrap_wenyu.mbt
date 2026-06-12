///|
fn moontown_repo_root() -> String {
  match @env.current_dir() {
    Some(dir) => dir
    None => "."
  }
}

///|
fn is_wenyu_book(entry : @moonbook.BookCatalogEntry) -> Bool {
  @build_pipeline.is_wenyu_book(entry)
}

///|
async fn wenyu_book_ready_for_build(entry : @moonbook.BookCatalogEntry) -> Bool {
  @build_pipeline.wenyu_book_ready_for_build(entry)
}

///|
fn wenyu_build_task_limit(task_limit : Int) -> Int {
  @build_pipeline.wenyu_build_task_limit(task_limit)
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
  @build_pipeline.wenyu_build_tasks(entry, objective, moontown_repo_root())
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
