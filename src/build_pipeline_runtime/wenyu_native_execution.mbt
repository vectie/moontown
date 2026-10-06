///|
pub fn is_wenyu_native_execution(execution : @core.TaskExecutionRecord) -> Bool {
  execution.output_contract == "wenyu.build.native-result.v1"
}

///|
pub fn wenyu_native_attention_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  path : String,
  reason : String,
  tick : Int,
  assigned_worker_id? : String? = None,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id="wenyu-native-unresolved",
    packet_path=path,
    status=Running,
    summary="Saved Wenyu native launch needs attention: " + reason,
    output_contract="wenyu.build.native-result.v1",
    context_pages=task.target_pages,
    assigned_worker_id~,
    heartbeat_tick=tick,
    stale_after_tick=tick + 30,
    next_retry_tick=None,
    result_decision="native-attention",
    requires_review=true,
    notify_town=true,
  )
}

///|
pub fn wenyu_native_execution_record(
  launch : WenyuLaunch,
  work : @native_work.Work,
  tick : Int,
  assigned_worker_id? : String? = None,
  imported? : Bool = false,
  import_blocker? : String = "",
) -> @core.TaskExecutionRecord {
  let status : @core.TaskExecutionStatus = if work.state == "completed" {
    if imported {
      ReviewQueued
    } else {
      AwaitingPersistence
    }
  } else if @native_work.terminal(work.state) {
    if import_blocker != "" {
      AwaitingPersistence
    } else {
      Failed
    }
  } else {
    Running
  }
  @core.TaskExecutionRecord::new(
    task_id=launch.task.id,
    book_id=launch.entry.id,
    packet_id=work.id,
    packet_path=wenyu_launch_path(launch.native_path, launch.task.id),
    status~,
    summary=@native_work.summary(work) +
      (if import_blocker == "" {
        ""
      } else {
        "; Book import pending: " + import_blocker
      }) +
      (if imported { "; Book deliverable saved for human review" } else { "" }),
    output_contract="wenyu.build.native-result.v1",
    context_pages=launch.task.target_pages,
    skill_paths=launch.entry.skills,
    last_command=Some(
      "Native work " +
      work.id +
      "; use saved status, refresh, sync or exact-target cancel",
    ),
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + 30,
    next_retry_tick=None,
    result_decision=if imported {
      if work.state == "completed" {
        "native-persisted-review"
      } else {
        "native-blocked-review"
      }
    } else if work.reservation is Some(_) {
      "native-reserved"
    } else {
      "native-pending"
    },
    requires_review=true,
    notify_town=true,
  )
}

///|
pub async fn execute_wenyu_native(
  launch : WenyuLaunch,
  tick : Int,
  assigned_worker_id? : String? = None,
) -> @core.TaskExecutionRecord {
  guard launch.execution == "native" else {
    fail("wenyu_native_route_mismatch")
  }
  let pending = @native_work.enqueue(launch.request, path=launch.native_path)
  let work = @native_work.sync(pending.id, @env.now(), path=launch.native_path)
  project_wenyu_native_result(launch, work, tick, assigned_worker_id~)
}

///|
async fn project_wenyu_native_result(
  launch : WenyuLaunch,
  work : @native_work.Work,
  tick : Int,
  assigned_worker_id? : String? = None,
) -> @core.TaskExecutionRecord {
  if !@native_work.terminal(work.state) || work.state == "superseded" {
    return wenyu_native_execution_record(
      launch,
      work,
      tick,
      assigned_worker_id~,
    )
  }
  let blocker = try {
    ignore(import_wenyu_native_result(launch, work))
    ""
  } catch {
    error => error.to_string()
  }
  let execution = wenyu_native_execution_record(
    launch,
    work,
    tick,
    assigned_worker_id~,
    imported=blocker == "",
    import_blocker=blocker,
  )
  if blocker != "" {
    return execution
  }
  read_wenyu_imported_review(launch, work, execution, tick) catch {
    error =>
      copy_execution_with(
        execution,
        summary=execution.summary +
          "; Book review readback unavailable: " +
          error.to_string(),
      )
  }
}

///|
pub async fn sync_wenyu_native_execution(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
  tick : Int,
) -> @core.TaskExecutionRecord {
  let launch = load_wenyu_launch(execution.packet_path)
  guard launch.execution == "native" &&
    launch.task.id == execution.task_id &&
    launch.entry.id == entry.id &&
    launch.entry.workspace_root == entry.workspace_root else {
    fail("wenyu_native_projection_binding_mismatch")
  }
  if execution.packet_id == "wenyu-native-unresolved" ||
    execution.packet_id == "wenyu-launch-missing" {
    // Enqueue compares the exact frozen key, so recovery reuses any work that
    // was durably saved before the original exception; it never rotates it.
    return execute_wenyu_native(
      launch,
      tick,
      assigned_worker_id=execution.assigned_worker_id,
    )
  }
  let work = @native_work.sync(
    execution.packet_id,
    @env.now(),
    path=launch.native_path,
  )
  guard work.request.work_key == launch.request.work_key else {
    fail("wenyu_native_work_mismatch")
  }
  project_wenyu_native_result(
    launch,
    work,
    tick,
    assigned_worker_id=execution.assigned_worker_id,
  )
}

///|
/// The explicit operator sync surface applies the same saved owner package as
/// daemon supervision. Observation-only refresh and saved GET never call this.
pub async fn apply_wenyu_native_work_result(
  work : @native_work.Work,
  native_path? : String = @native_work.default_path(),
) -> Unit {
  if work.request.kind != "wenyu_build" ||
    !@native_work.terminal(work.state) ||
    work.state == "superseded" {
    return
  }
  let launch = load_wenyu_launch(
    wenyu_launch_path(native_path, work.request.criterion_id),
  )
  ignore(import_wenyu_native_result(launch, work))
}
