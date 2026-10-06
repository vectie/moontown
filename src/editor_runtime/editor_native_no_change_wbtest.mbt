///|
async test "native no change editor display preserves distinct outcome and legacy text behavior" {
  let native = "contract: planbook.repair.result.v1\nrepair_decision: no_change\nnative_receipt_contract: planbook.repair.native_no_change_receipt.v1\noriginal_task_acceptance: unevaluated\n"
  assert_eq(
    editor_pipeline_lifecycle_status_from_repair_result(
      native, "/unused/native-no-change",
    ),
    "no_change",
  )
  assert_eq(
    editor_pipeline_lifecycle_status_from_repair_result(
      "repair_decision: no_change\n", "/unused/native-no-change",
    ),
    "accepted",
  )
  assert_eq(
    editor_pipeline_lifecycle_status_from_repair_result(
      "repair_decision: accepted\n", "/unused/native-no-change",
    ),
    "accepted",
  )
}
