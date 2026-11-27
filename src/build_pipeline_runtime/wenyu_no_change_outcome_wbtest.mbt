///|
#warnings("-unused_async")
async test "Wenyu import rejects both relabel directions and failed native no change projection" {
  let launch = wenyu_launch_fixture()
  let work = wenyu_journey_completed(launch)
  let changed : @native_work.Work = @json.from_json(
    @json.parse(ToJson::to_json(work).stringify()),
  )
  let answer = @json.parse(changed.output)
  wenyu_test_set(answer, "outcome", ToJson::to_json("implemented"))
  let output = answer.stringify()
  wenyu_test_set(
    changed.receipt,
    "engineering_status",
    ToJson::to_json("applied_and_validated"),
  )
  wenyu_test_set(
    changed.receipt,
    "contract",
    ToJson::to_json("wenyu.build.native_patch_receipt.v1"),
  )
  wenyu_test_set(
    changed.receipt,
    "output_digest",
    ToJson::to_json(@native_work.digest(output)),
  )
  let relabeled = { ..changed, output, }
  try {
    ignore(
      import_wenyu_native_result(launch, relabeled, persist=async fn(result) {
        wenyu_owner_outcome(result)
      }),
    )
    fail("accepted relabeled no change")
  } catch {
    error =>
      assert_true(error.to_string().contains("wenyu_result_evidence_invalid"))
  }
  for status in ["runtime-failed", "runtime-cancelled"] {
    let changed : @native_work.Work = @json.from_json(
      @json.parse(ToJson::to_json(work).stringify()),
    )
    wenyu_test_set(
      wenyu_test_field(changed.receipt, "native_receipt"),
      "status",
      ToJson::to_json(status),
    )
    try {
      ignore(
        import_wenyu_native_result(launch, changed, persist=async fn(result) {
          wenyu_owner_outcome(result)
        }),
      )
      fail("accepted failed native status")
    } catch {
      error =>
        assert_true(error.to_string().contains("wenyu_result_evidence_invalid"))
    }
  }
  let (mutation_launch, mutation) = wenyu_owner_fixture("outcome-agreement")
  wenyu_test_set(
    mutation.receipt,
    "result_decision",
    ToJson::to_json("no_change"),
  )
  try {
    ignore(
      import_wenyu_native_result(mutation_launch, mutation, persist=async fn(
        result,
      ) {
        wenyu_owner_outcome(result)
      }),
    )
    fail("accepted contradictory mutation decision")
  } catch {
    error =>
      assert_true(error.to_string().contains("wenyu_result_evidence_invalid"))
  }
  let answer = @json.parse(mutation.output)
  wenyu_test_set(answer, "outcome", ToJson::to_json("no_change"))
  let output = answer.stringify()
  wenyu_test_set(
    mutation.receipt,
    "engineering_status",
    ToJson::to_json("no_change"),
  )
  wenyu_test_set(
    mutation.receipt,
    "contract",
    ToJson::to_json("wenyu.build.native_no_change_receipt.v1"),
  )
  wenyu_test_set(
    mutation.receipt,
    "output_digest",
    ToJson::to_json(@native_work.digest(output)),
  )
  try {
    ignore(
      import_wenyu_native_result(mutation_launch, { ..mutation, output, }, persist=async fn(
        result,
      ) {
        wenyu_owner_outcome(result)
      }),
    )
    fail("accepted mutation relabeled as no change")
  } catch {
    error =>
      assert_true(error.to_string().contains("wenyu_result_evidence_invalid"))
  }
  assert_false(@fs.exists(launch.entry.workspace_root + "/raw/build/native"))
  assert_false(
    @fs.exists(mutation_launch.entry.workspace_root + "/raw/build/native"),
  )
}
