///|
test "public native identity digest and lifecycle classification remain stable" {
  assert_eq(
    @native_work.digest("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  assert_true(@native_work.terminal("completed"))
  assert_false(@native_work.terminal("waiting_control"))
  assert_false(@native_work.terminal("blocked_commit_capability"))
}

///|
async test "public owner controls cancel unreserved work locally and expose saved status" {
  let root = "/tmp/town-native-controls-public-" + @env.now().to_string()
  @fs.mkdir(root)
  let path = root + "/state.json"
  let request : @native_work.Request = {
    kind: "planbook_repair",
    work_key: "public-local-control",
    generation: 0,
    owner_workspace: root,
    book_id: "fixture",
    book_root: root + "/book",
    book_type: "planbook",
    catalog_path: root + "/unused-catalog.json",
    execution_root: root + "/source",
    source_binding: Json::null(),
    criterion_id: "fixture",
    model_request: "",
    prompt: "private prompt",
    input_blocker: "source_workspace_unconfigured",
    input_digest: @native_work.digest("private prompt"),
    output_contract: "planbook.repair.native_patch_receipt.v1",
    result_path: root + "/result.md",
    acceptance_policy: Json::null(),
    created_at_ms: 1UL,
  }
  let queued = @native_work.enqueue(request, path~)
  let state = @native_work.load(path~)
  let observed = @native_work.refresh(queued.id, state.revision, 2UL, path~)
  assert_eq(observed.state, "queued")
  let stopped = @native_work.cancel(queued.id, state.revision, 3UL, path~)
  assert_eq(stopped.state, "cancelled")
  let shown = @native_work.status(stopped)
  assert_eq(shown.control_state, "none")
  assert_eq(shown.blocked_reason, "cancelled_before_reservation")
  assert_false(shown.to_json().stringify().contains("private prompt"))
  assert_false(@fs.exists(request.result_path))
}
