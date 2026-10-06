///|
async test "editor owner conflict stays waiting in native and PlanBook status without displaying prior result" {
  let fixture = native_editor_fixture()
  let task = native_editor_materialize(fixture)
  let queued = native_editor_saved(fixture, task.id)
  let path = @native_work.path_for_snapshot(fixture.snapshot_path)
  write_planbook_repair_status(task, fixture.book_root, fixture.snapshot_path)
  let posted : Array[String] = []
  let journal : Array[Json] = []
  let receipts : Array[Json] = []
  let calls : Array[String] = []
  let client = native_editor_client(
    queued.request,
    posted,
    journal,
    receipts,
    ["moongate/editor-fixture-one"],
    calls,
  )
  let running = @native_work.sync(task.id, 1UL, path~, client~)
  assert_eq(running.state, "running")
  ignore(native_editor_finish_fixture(running, journal, receipts))
  let prior = "OLD_CONFLICTING_OUTPUT_SHOULD_NOT_BE_RENDERED\n"
  @support.write_text_file(queued.request.result_path, prior)
  let blocked = @native_work.sync(task.id, 40000UL, path~, client~)
  assert_eq(blocked.state, "completed")
  assert_eq(@native_work.owner_status(blocked), "waiting_owner_output")
  assert_eq(@native_work.status(blocked).state, "waiting_owner_output")
  assert_true(
    blocked.blocked_reason.contains(
      "editor_owner_output_changed_by_human_or_newer_work",
    ),
  )
  let rendered = render_moontown_planbook_repair_status(
    snapshot_path=fixture.snapshot_path,
  )
  assert_true(rendered.contains("waiting_owner_output"))
  assert_false(rendered.contains(prior.trim().to_owned()))
  let pending = pending_native_planbook_repair(
    fixture.snapshot_path,
    fixture.book_root,
    false,
  ).unwrap()
  assert_eq(pending.id, task.id)
  assert_eq(pending.status, "waiting_owner_output")
  let retry = pending_native_planbook_repair(
    fixture.snapshot_path,
    fixture.book_root,
    true,
  ).unwrap()
  assert_eq(retry.id, task.id)
  assert_eq(retry.status, "waiting_owner_output")
  assert_eq(posted.length(), 1)
  assert_eq(@fs.read_file(queued.request.result_path).text(), prior)
}
