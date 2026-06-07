///|
async test "book quality ledger reconciliation aggregates changed runs" {
  let root = cleaned_book_quality_test_root(
    "/tmp/moontown-book-quality-ledger-reconcile-wbtest",
  )
  let stale = book_quality_review_run_fixture(
    "course-example",
    "\{root}/packet-stale.json",
    "\{root}/result-stale.md",
    Some("proposal-stale"),
    Some("run-stale-book-quality-review"),
    book_quality_review_run_dispatched_status(),
    "started but never produced a result",
    1UL,
  )
  let queued = book_quality_review_run_fixture(
    "course-queued",
    "\{root}/packet-queued.json",
    "\{root}/result-queued.md",
    None,
    None,
    book_quality_review_run_queued_status(),
    "waiting for dispatch",
    2UL,
  )
  let result = reconcile_book_quality_review_ledger(
    BookQualityReviewRunLedger::{ runs: [stale, queued] },
    "\{root}/results",
    root,
    ".moonclaw",
  )
  assert_eq(result.written, 0)
  assert_true(result.changed)
  assert_eq(result.ledger.runs.length(), 2)
  assert_eq(
    result.ledger.runs[0].status,
    book_quality_review_run_orphaned_status(),
  )
  assert_eq(
    result.ledger.runs[1].status,
    book_quality_review_run_queued_status(),
  )
}

///|
test "book quality ledger reconcile accumulator preserves order and counts" {
  let first = book_quality_review_run_fixture(
    "book-first",
    "/tmp/packet-first.json",
    "/tmp/result-first.md",
    Some("proposal-first"),
    Some("run-first"),
    book_quality_review_run_dispatched_status(),
    "first",
    1UL,
  )
  let second = book_quality_review_run_fixture(
    "book-second",
    "/tmp/packet-second.json",
    "/tmp/result-second.md",
    Some("proposal-second"),
    Some("run-second"),
    book_quality_review_run_written_status(),
    "second",
    2UL,
  )
  let first_result = BookQualityReviewRunReconcileResult::{
    run: first,
    written: false,
    changed: true,
  }
  let second_result = BookQualityReviewRunReconcileResult::{
    run: second,
    written: true,
    changed: false,
  }
  let result = book_quality_review_ledger_reconcile_result(
    [first_result.run, second_result.run],
    book_quality_review_run_reconcile_written_delta(first_result) +
    book_quality_review_run_reconcile_written_delta(second_result),
    book_quality_review_ledger_reconcile_changed_after(
      book_quality_review_ledger_reconcile_changed_after(false, first_result),
      second_result,
    ),
  )
  assert_eq(result.ledger.runs.length(), 2)
  assert_eq(result.ledger.runs[0].book_id, "book-first")
  assert_eq(result.ledger.runs[1].book_id, "book-second")
  assert_eq(result.written, 1)
  assert_true(result.changed)
}

///|
test "book quality reconcile result centralizes changed semantics" {
  let run = book_quality_review_run_fixture(
    "book-result",
    "packet.json",
    "result.md",
    None,
    None,
    book_quality_review_run_queued_status(),
    "waiting",
    1UL,
  )
  let unchanged = book_quality_review_run_reconcile_result(
    run,
    run,
    written=false,
  )
  assert_false(unchanged.written)
  assert_false(unchanged.changed)
  let status_changed = book_quality_review_run_reconcile_result(
    run,
    { ..run, status: book_quality_review_run_written_status() },
    written=false,
  )
  assert_false(status_changed.written)
  assert_true(status_changed.changed)
  let written = book_quality_review_run_reconcile_result(run, run, written=true)
  assert_true(written.written)
  assert_true(written.changed)
}
