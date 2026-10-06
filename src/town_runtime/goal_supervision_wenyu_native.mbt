///|
/// Restore the Town projection after a crash without reconstructing a prompt,
/// changing its saved route, or treating the missing legacy run ID as failure.
async fn recover_saved_wenyu_native_launches(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  tick : Int,
) -> Unit {
  let path = @native_work.path_for_snapshot(snapshot_path)
  let directory = path + ".wenyu-launches"
  if !@fs.exists(directory) {
    return
  }
  let names = @fs.readdir(directory)
  names.sort()
  for name in names {
    if !name.has_suffix(".json") {
      continue
    }
    let launch = @build_pipeline_runtime.load_wenyu_launch(
      directory + "/" + name,
    ) catch {
      _ => continue
    }
    if launch.execution != "native" ||
      @core.find_execution(state, launch.task.id) is Some(_) {
      continue
    }
    let entry = match @moonbook.entry_for_book_id(catalog, launch.entry.id) {
      Some(entry) if entry.workspace_root == launch.entry.workspace_root =>
        entry
      _ => continue
    }
    let saved = @native_work.load(path~)
    let mut existing : @native_work.Work? = None
    let mut superseded = false
    for work in saved.work {
      if work.request.work_key == launch.request.work_key &&
        work.state != "superseded" {
        existing = Some(work)
      }
      if work.request.work_key == launch.request.work_key &&
        work.state == "superseded" {
        superseded = true
      }
    }
    if existing is None && superseded {
      continue
    }
    let work = match existing {
      Some(work) => work
      None => {
        if @core.live_external_execution_count(state) >=
          @core.max_live_external_executions() {
          continue
        }
        @native_work.enqueue(launch.request, path~)
      }
    }
    let execution = @build_pipeline_runtime.wenyu_native_execution_record(
      launch, work, tick,
    )
    record_goal_execution(state, entry, launch.task, execution)
  }
}
