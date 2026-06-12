///|
test "build pipeline owns local Wenyu build execution record" {
  let entry = @moonbook.BookCatalogEntry::new(
    id="wenyu-town-shell",
    name="Wenyu Valley / Town Shell",
    purpose="Build town shell.",
    workspace_root="/tmp/wenyu-town-shell",
  )
  let task = @moonbook.BookTask::new(
    id="goal-wenyu-town-shell-implementation-backlog",
    title="Compile implementation backlog",
    kind="implementation-backlog",
    prompt="Build backlog",
    priority=120,
    requires_review=true,
    target_pages=["build/IMPLEMENTATION_BACKLOG.md"],
  )
  let execution = local_wenyu_build_execution_record(
    entry,
    task,
    assigned_worker_id=Some("worker-wenyu"),
    tick=8,
  )
  assert_eq(
    execution.packet_id,
    "local-wenyu-town-shell-goal-wenyu-town-shell-implementation-backlog",
  )
  assert_eq(
    execution.packet_path,
    "local://wenyu-build/wenyu-town-shell/goal-wenyu-town-shell-implementation-backlog",
  )
  assert_eq(execution.output_contract, wenyu_build_packet_contract())
  assert_eq(execution.status, @core.TaskExecutionStatus::Completed)
  assert_eq(execution.heartbeat_tick, 8)
  assert_eq(execution.stale_after_tick, 11)
  assert_true(execution.skill_paths.contains("skills/wenyu-build/SKILL.md"))
}
