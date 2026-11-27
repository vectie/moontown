///|
async test "native no change task specific check proof must be latest and precede final checkpoint" {
  let request = no_change_fixture_request(fixture_request())
  rows(field(request.acceptance_policy, "completion_policy"), "required_checks").push({
      "id": "task-specific",
      "tool": "moon_cmd",
      "command": "moon test focused",
      "cwd": "fixtures",
      "exit_code": 0,
    },
  )
  let work = fixture_reserved(request)
  for
    boundary in [
      "valid", "wrong-cwd", "nonzero", "no-cleanup", "wrong-tool", "valid-rerun",
      "stale-checkpoint",
    ] {
    let receipt = no_change_fixture_receipt(work)
    let events = no_change_fixture_events(work)
    let journal = rows(events, "events")
    let proof = fixture_validation(work, "task-check")
    no_change_set(proof, "tool", ToJson::to_json("moon_cmd"))
    let metadata = field(field(proof, "tool_result"), "metadata")
    no_change_set(metadata, "command", ToJson::to_json("moon test focused"))
    no_change_set(metadata, "cwd", ToJson::to_json("fixtures"))
    journal.insert(1, proof)
    let proposal = no_change_fixture_proposal()
    rows(proposal, "evidence_refs").push(ToJson::to_json("task-check"))
    let execution = field(receipt, "execution")
    let verdict = field(execution, "completion_verdict")
    no_change_set(verdict, "no_change", proposal)
    rows(verdict, "required_check_evidence").push({
      "id": "task-specific",
      "event_id": "task-check",
    })
    no_change_set(
      field(field(rows(execution, "tool_results")[0], "result"), "metadata"),
      "no_change",
      proposal,
    )
    no_change_set(
      field(field(field(journal[2], "tool_result"), "metadata"), "checkpoint"),
      "no_change",
      proposal,
    )
    no_change_set(
      field(field(journal[3], "tool_result"), "metadata"),
      "no_change",
      proposal,
    )
    if boundary != "valid" {
      let later = @json.parse(proof.stringify())
      no_change_set(later, "id", ToJson::to_json("later-check"))
      let later_metadata = field(field(later, "tool_result"), "metadata")
      match boundary {
        "wrong-cwd" =>
          no_change_set(later_metadata, "cwd", ToJson::to_json("elsewhere"))
        "nonzero" =>
          no_change_set(later_metadata, "exit_code", ToJson::to_json(1))
        "no-cleanup" =>
          no_change_set(
            field(later_metadata, "sandbox_evidence"),
            "cleanup_verified",
            ToJson::to_json(false),
          )
        "wrong-tool" => {
          no_change_set(later, "tool", ToJson::to_json("shell"))
          no_change_set(
            later_metadata,
            "cmd",
            ToJson::to_json("moon test focused"),
          )
        }
        _ => ()
      }
      journal.insert(if boundary == "stale-checkpoint" { 3 } else { 2 }, later)
    }
    for index, event in journal {
      no_change_set(
        event,
        "journal_sequence",
        ToJson::to_json((index + 1).to_string()),
      )
    }
    no_change_set(events, "event_count", ToJson::to_json(journal.length()))
    let result = reconcile_repair_evidence(
      work,
      receipt,
      events,
      work.baseline,
      0,
      5UL,
    )
    if boundary == "valid" {
      assert_eq(result.state, "completed")
      assert_eq(rows(result.receipt, "validation_commands").length(), 2)
    } else {
      assert_true(result.state != "completed", msg=boundary)
    }
  }
}
