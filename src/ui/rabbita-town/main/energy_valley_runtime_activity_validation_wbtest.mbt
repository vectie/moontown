///|
test "runtime activity vocabulary is closed" {
  for
    kind in [
      "walking", "researching", "synthesizing", "discussing", "reviewing", "revising",
      "recovering", "returning", "idle",
    ] {
    assert_true(energy_valley_runtime_activity_kind_is_valid(kind))
  }
  for invalid in ["", "queued", "running", "Researching", "researching/path"] {
    assert_true(!energy_valley_runtime_activity_kind_is_valid(invalid))
  }
}

///|
test "runtime catalog digest is a lowercase SHA-256 identity" {
  assert_true(
    energy_valley_runtime_sha256_digest_is_valid(
      "sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
    ),
  )
  assert_false(energy_valley_runtime_sha256_digest_is_valid("sha256:short"))
  assert_false(
    energy_valley_runtime_sha256_digest_is_valid(
      "sha256:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
    ),
  )
}

///|
test "runtime optional labels and identities fail closed" {
  assert_true(energy_valley_runtime_activity_metadata_is_valid(None, None))
  assert_true(
    energy_valley_runtime_activity_metadata_is_valid(
      Some("researching"),
      Some("研究资料"),
    ),
  )
  assert_true(
    !energy_valley_runtime_activity_metadata_is_valid(
      None,
      Some("untyped activity"),
    ),
  )
  assert_true(
    !energy_valley_runtime_activity_metadata_is_valid(
      Some("queued"),
      Some("等待调度"),
    ),
  )
  for invalid_label in ["", "   ", " leading", "two\nlines", "tab\tlabel"] {
    assert_true(
      !energy_valley_runtime_optional_activity_label_is_valid(
        Some(invalid_label),
      ),
    )
  }
  assert_true(
    energy_valley_runtime_optional_identity_is_valid(Some("research-ai-agents")),
  )
  for
    invalid_identity in [
      "", "../policy-hall", "policy/hall", "Policy-Hall", "policy hall", "policy%2fhall",
    ] {
    assert_true(
      !energy_valley_runtime_optional_identity_is_valid(Some(invalid_identity)),
    )
  }
}

///|
test "runtime work and agent validators reject unsafe activity metadata" {
  let state = energy_valley_runtime_state_from_text(
    energy_valley_runtime_test_projection_text(
      "1970-01-01T00:01:40.000Z", "live",
    ),
    3,
    110000.0,
  )
  let projection = state.projection.unwrap()
  let task = projection.tasks[0]
  let agent = projection.agents[0]
  assert_true(
    energy_valley_runtime_work_item_is_valid({
      ..task,
      activityKind: Some("researching"),
      activityLabel: Some("研究资料"),
      originBuildingModuleKey: Some("policy-hall"),
      destinationBuildingModuleKey: Some("social-square"),
    }),
  )
  assert_true(
    !energy_valley_runtime_work_item_is_valid({
      ..task,
      activityKind: Some("queued"),
      activityLabel: Some("等待调度"),
    }),
  )
  assert_true(
    !energy_valley_runtime_work_item_is_valid({
      ..task,
      bookId: Some("../private-book"),
    }),
  )
  assert_true(
    energy_valley_runtime_agent_is_valid({
      ..agent,
      bookId: Some("policy-hall"),
      activityKind: Some("walking"),
      activityLabel: Some("前往研究建筑"),
      originBuildingModuleKey: Some("policy-hall"),
      destinationBuildingModuleKey: Some("social-square"),
    }),
  )
  assert_true(
    !energy_valley_runtime_agent_is_valid({
      ..agent,
      activityKind: Some("researching"),
      activityLabel: Some(" "),
    }),
  )
  assert_true(
    !energy_valley_runtime_agent_is_valid({
      ..agent,
      destinationBuildingModuleKey: Some("social/../../square"),
    }),
  )
}
