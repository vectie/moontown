///|
async test "editor finish schema preserves exact selection acceptance and reserved identities" {
  let (work, _) = editor_owner_fixture()
  assert_true(editor_result_satisfies_contract(work, work.output, false))
  let reserved = @json.parse(work.reservation.unwrap().request_body)
  let contract = field(field(reserved, "payload"), "task_contract")
  assert_eq(text(reserved, "book_root"), work.request.execution_root)
  assert_eq(text(reserved, "model_workspace"), work.request.owner_workspace)
  assert_eq(field(contract, "scope"), ["."].to_json())
  assert_true(field(contract, "constraints").stringify().contains(work.id))
  assert_true(
    field(contract, "constraints").stringify().contains("selection_digest"),
  )
  assert_true(
    field(contract, "constraints").stringify().contains("A road can be edited"),
  )
  assert_eq(
    field(contract, "completion_policy"),
    field(work.request.acceptance_policy, "completion_policy"),
  )
  assert_false(
    editor_result_satisfies_contract(work, "repair_decision: accepted", false),
  )
  assert_false(editor_result_satisfies_contract(work, work.output, true))
  for
    key in [
      "contract", "work_id", "book_id", "criterion_id", "selected_feature", "selection_digest",
      "outcome", "summary",
    ] {
    let answer = @json.parse(work.output)
    no_change_set(answer, key, "".to_json())
    assert_false(
      editor_result_satisfies_contract(work, answer.stringify(), false),
      msg=key,
    )
  }
  for
    changed in [
      ([] : Array[Json]).to_json(),
      [
        {
          "acceptance": "Different acceptance",
          "explanation": "Plausible prose is not a frozen requirement",
        },
      ].to_json(),
      [{ "acceptance": "A road can be edited", "explanation": "" }].to_json(),
    ] {
    let answer = @json.parse(work.output)
    no_change_set(answer, "acceptance_evidence", changed)
    assert_false(
      editor_result_satisfies_contract(work, answer.stringify(), false),
    )
  }
  let duplicate = "{\"work_id\":\"other\"," + work.output[1:].to_owned()
  assert_false(editor_result_satisfies_contract(work, duplicate, false))
  let extra = @json.parse(work.output)
  no_change_set(extra, "output_path", "../../human.md".to_json())
  assert_false(editor_result_satisfies_contract(work, extra.stringify(), false))
}

///|
async test "editor owner unsupported request or receipt identities cannot create acceptance" {
  let (work, _) = editor_owner_fixture()
  for
    key in [
      "request_id", "request_digest", "criterion_id", "book_root", "source_root",
      "output_digest", "session_id", "command_id", "model", "model_workspace", "request_body_digest",
    ] {
    let receipt = @json.parse(work.receipt.stringify())
    no_change_set(receipt, key, "other".to_json())
    let invalid = { ..work, receipt, }
    assert_false(editor_evidence_bound(invalid), msg=key)
    let blocked = apply_editor_owner_result(invalid)
    assert_true(
      blocked.blocked_reason.contains("editor_owner_evidence_binding_invalid"),
      msg=key,
    )
  }
  assert_false(@fs.exists(work.request.result_path))
  assert_eq(editor_applied_feature(work.request.book_root), None)
}
