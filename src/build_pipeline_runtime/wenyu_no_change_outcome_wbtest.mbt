///|
async test "Wenyu import rejects both relabel directions and failed native no change projection" {
  let launch = wenyu_launch_fixture()
  let work = wenyu_journey_completed(launch)
  let changed : @native_work.Work = @json.from_json(
    @json.parse(work.to_json().stringify()),
  )
  let answer = @json.parse(changed.output)
  wenyu_test_set(answer, "outcome", "implemented".to_json())
  let output = answer.stringify()
  wenyu_test_set(
    changed.receipt,
    "engineering_status",
    "applied_and_validated".to_json(),
  )
  wenyu_test_set(
    changed.receipt,
    "contract",
    "wenyu.build.native_patch_receipt.v1".to_json(),
  )
  wenyu_test_set(
    changed.receipt,
    "output_digest",
    @native_work.digest(output).to_json(),
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
      @json.parse(work.to_json().stringify()),
    )
    wenyu_test_set(
      wenyu_test_field(changed.receipt, "native_receipt"),
      "status",
      status.to_json(),
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
  wenyu_test_set(mutation.receipt, "result_decision", "no_change".to_json())
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
  wenyu_test_set(answer, "outcome", "no_change".to_json())
  let output = answer.stringify()
  wenyu_test_set(mutation.receipt, "engineering_status", "no_change".to_json())
  wenyu_test_set(
    mutation.receipt,
    "contract",
    "wenyu.build.native_no_change_receipt.v1".to_json(),
  )
  wenyu_test_set(
    mutation.receipt,
    "output_digest",
    @native_work.digest(output).to_json(),
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
