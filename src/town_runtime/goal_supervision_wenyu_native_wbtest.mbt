///|
async test "wenyu native work survives generic stale retry and transient recovery" {
  let state = @core.empty_state(
    @core.TownConfig::new(id="synthetic-wenyu", name="Synthetic Wenyu"),
  )
  let execution = @core.TaskExecutionRecord::new(
    task_id="wenyu-synthetic-task",
    book_id="book",
    packet_id="town-work-synthetic",
    packet_path="/synthetic/manifest",
    status=Running,
    summary="Native approval remains pending",
    output_contract="wenyu.build.native-result.v1",
    heartbeat_tick=1,
    stale_after_tick=2,
  )
  state.replace_execution(execution)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    100000,
    launch_confirmed_run=false,
  )
  assert_eq(@core.find_execution(state, execution.task_id), Some(execution))
  let failed = copy_execution_with(
    execution,
    status=Failed,
    summary="MoonClaw dependency lock unavailable",
  )
  state.replace_execution(failed)
  reconcile_transient_dependency_failures(state)
  assert_eq(@core.find_execution(state, failed.task_id), Some(failed))
}

///|
async test "wenyu corrupt native launch never becomes an ACP fallback or fake code handoff" {
  let root = @fs.tmpdir(prefix="town-wenyu-native-launch-error-")
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-native-code",
    name="Wenyu Valley / Native Code",
    purpose="Synthetic",
    workspace_root=root,
    tags=["wenyu"],
  )
  let task = @moonbook.BookTask::new(
    id="wenyu-frozen-task",
    title="Code",
    kind="code-patch",
    prompt="Frozen task",
    priority=1,
    requires_review=true,
    target_pages=["build/CODE_PATCH.md", "build/TEST_RESULTS.md"],
  )
  let native_path = root + "/native/state.json"
  let manifest = @build_pipeline_runtime.wenyu_launch_path(native_path, task.id)
  @support.write_text_file(manifest, "{}")
  let execution = execute_goal_book_task(
    @roles.Mayor::new(),
    entry,
    task,
    native_path~,
    run_inline=false,
  )
  assert_true(@build_pipeline_runtime.is_wenyu_native_execution(execution))
  assert_eq(execution.status, @core.TaskExecutionStatus::Running)
  assert_eq(execution.packet_path, manifest)
  assert_eq(execution.packet_id, "wenyu-native-unresolved")
  assert_eq(execution.run_id, None)
  assert_eq(execution.proposal_id, None)
  let projected = @build_pipeline_runtime.complete_wenyu_build_artifacts_if_needed(
    entry, task, execution,
  )
  assert_eq(projected, execution)
  let state = @core.empty_state(
    @core.TownConfig::new(id="wenyu-native-error", name="Synthetic"),
  )
  state.replace_execution(execution)
  assert_eq(persist_execution_into_book(state, entry, execution), None)
  reconcile_no_run_id_live_execution(
    state,
    execution,
    100000,
    launch_confirmed_run=false,
  )
  assert_eq(@core.find_execution(state, task.id), Some(execution))
  assert_false(@fs.exists(root + "/build/CODE_PATCH.md"))
  assert_false(@fs.exists(root + "/build/CODE_BLOCKERS.md"))
  assert_false(@fs.exists(root + "/moonclaw.jobs.json"))
  assert_false(@fs.exists(native_path))
}
