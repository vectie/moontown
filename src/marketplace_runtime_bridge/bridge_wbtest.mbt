///|
test "terminal worker receipt maps to marketplace evidence" {
  let request : Json = {
    "kind": "execution",
    "receipt": {
      "worker": {
        "worker_run_id": "worker-1",
        "execution_status": "succeeded",
        "summary": "Evidence note created",
        "artifact_refs": ["books/coding/artifacts/note.md"],
      },
    },
  }
  let draft = execution_runtime_draft(request.stringify(), {
    "handoffId": "handoff-1",
    "status": "runtime_acknowledged",
  })
  assert_eq(draft.handoff_id, "handoff-1")
  assert_eq(draft.runtime_status, "succeeded")
  assert_eq(draft.worker_run_id, "worker-1")
  assert_eq(draft.result_summary, "Evidence note created")
  assert_eq(draft.result_evidence_refs, ["books/coding/artifacts/note.md"])
}
