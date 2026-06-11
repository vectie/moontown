///|
test "transient external dependency error classifies retryable runtime noise" {
  assert_true(
    transient_external_dependency_error("Resource temporarily unavailable"),
  )
  assert_true(transient_external_dependency_error("{bad request}"))
  assert_true(
    transient_external_dependency_error(
      "runtime error: abort() called in SystemStore::save_job_proposals",
    ),
  )
  assert_true(!transient_external_dependency_error("domain claim was rejected"))
}
