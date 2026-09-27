///|
test "Code schedule transport encodes paths and recognizes terminal receipts" {
  assert_eq(
    code_url_component("/suite/books/my book"),
    "%2Fsuite%2Fbooks%2Fmy%20book",
  )
  let claim : Json = {
    "delivered_commands": [
      {
        "command_id": "code-schedule-review-60",
        "receipt": { "status": "runtime-failed" },
      },
    ],
  }
  assert_eq(
    code_receipt_status(claim, "code-schedule-review-60"),
    Some("failed"),
  )
  assert_true(code_receipt_status(claim, "other") is None)
  let unknown : Json = {
    "delivered_commands": [
      {
        "command_id": "code-schedule-review-60",
        "receipt": { "status": "runtime-unknown" },
      },
    ],
  }
  assert_true(code_receipt_status(unknown, "code-schedule-review-60") is None)
}
