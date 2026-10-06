///|
fn public_wenyu_work() -> @native_work.Work {
  let request : @native_work.Request = {
    kind: "wenyu_build",
    work_key: "wenyu:book:goal:task",
    generation: 1,
    owner_workspace: "/synthetic/owner",
    book_id: "book",
    book_root: "/synthetic/book",
    book_type: "wenyu",
    catalog_path: "/synthetic/catalog.json",
    execution_root: "/synthetic/source",
    source_binding: Json::null(),
    criterion_id: "",
    model_request: "",
    prompt: "Implement",
    input_blocker: "",
    input_digest: @native_work.digest("Implement"),
    output_contract: "wenyu.build.native-result.v1",
    result_path: "",
    acceptance_policy: {
      "contract": "wenyu.build.native-policy.v1",
      "task_id": "task",
      "goal_id": "goal",
      "task_kind": "code-patch",
      "commit_requirement": "not_requested",
      "required_validation_commands": ["moon check --no-render"],
      "preserve_preexisting_unrelated_dirty_files": true,
      "push_requested": false,
    },
    created_at_ms: 1UL,
  }
  {
    id: "work",
    request,
    request_digest: @native_work.digest(request.to_json().stringify()),
    state: "queued",
    blocked_reason: "",
    reservation: None,
    control: None,
    baseline: Json::null(),
    observed_instances: [],
    last_attempt_at_ms: 0UL,
    retry_after_ms: 0UL,
    output: "",
    receipt: Json::null(),
  }
}

///|
test "public wenyu result contract is exact identity bound and mutation only" {
  let work = public_wenyu_work()
  let valid : Json = {
    "contract": "wenyu.build.native-result.v1",
    "work_id": "work",
    "book_id": "book",
    "task_id": "task",
    "goal_id": "goal",
    "outcome": "implemented",
    "summary": "Implemented requested behavior",
    "behavior": "",
    "residual_risks": [],
  }
  assert_true(
    @native_work.wenyu_result_satisfies_contract(work, valid.stringify()),
  )
  for
    key in [
      "contract", "work_id", "book_id", "task_id", "goal_id", "outcome", "summary",
      "behavior", "residual_risks",
    ] {
    let changed = @json.parse(valid.stringify())
    if changed is Object(fields) {
      fields[key] = Json::null()
    }
    assert_false(
      @native_work.wenyu_result_satisfies_contract(work, changed.stringify()),
      msg=key,
    )
  }
  for outcome in ["blocked", "no_change", "accepted"] {
    let changed = @json.parse(valid.stringify())
    if changed is Object(fields) {
      fields["outcome"] = outcome.to_json()
    }
    assert_false(
      @native_work.wenyu_result_satisfies_contract(work, changed.stringify()),
      msg=outcome,
    )
  }
  for
    invalid in ["", "not JSON", "[]", "```json\n" + valid.stringify() + "\n```"] {
    assert_false(@native_work.wenyu_result_satisfies_contract(work, invalid))
  }
  let extra = @json.parse(valid.stringify())
  if extra is Object(fields) {
    fields["artifacts"] = ["../../foreign.md"].to_json()
  }
  assert_false(
    @native_work.wenyu_result_satisfies_contract(work, extra.stringify()),
  )
  let duplicate = "{\"outcome\":\"blocked\"," + valid.stringify()[1:].to_owned()
  assert_false(@native_work.wenyu_result_satisfies_contract(work, duplicate))
  let escaped = @json.parse(valid.stringify())
  if escaped is Object(fields) {
    fields["summary"] = "Quoted \\\" text with { : } [ ] and \\ backslash".to_json()
  }
  assert_true(
    @native_work.wenyu_result_satisfies_contract(work, escaped.stringify()),
  )
  assert_true(@native_work.is_workspace_change("wenyu_build"))
  assert_true(@native_work.is_workspace_change("planbook_repair"))
  assert_false(@native_work.is_workspace_change("book_quality_review"))
  assert_false(@native_work.is_workspace_change("unknown"))
}
