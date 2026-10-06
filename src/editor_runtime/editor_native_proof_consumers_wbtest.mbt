///|
async test "all editor proof consumers reject native markers and provenance without bound application" {
  let root = @fsx.mkdtemp("/tmp/town-editor-native-consumers-XXXXXX")
  let workspace_root = "\{root}/book"
  let snapshot_path = "\{root}/town.json"
  let feature_id = "building-protocol-history"
  write_editor_feature_selection_fixture(
    workspace_root, feature_id, "Building Protocol History", 1, "Add durable protocol history",
    "History is visible",
  )
  for
    marker in [
      "native_owner_contract:\n", "native_owner_contract: unsupported\n", "  native_owner_contract: unsupported\n",
      "prefix native_owner_contract: unsupported\n", "native_owner_contract:planbook.repair.native_editor_owner.v1\n",
      "native_owner_contract: first\nnative_owner_contract: second\n", "native_owner_contract = planbook.editor.owner-output.v1\n",
      "native_owner_contract planbook.editor.owner-output.v1\n", "native_owner_contract\n",
      "owner_work_id: native-editor-work\n", "owner_request_digest: native-request-digest\n",
      "native_session_id: native-session\n", "native_command_id: native-command\n",
      "native_request_body_digest: native-body-digest\n", "application_receipt: native-editor-work/application-receipt.json\n",
    ] {
    @support.write_text_file(
      editor_selected_feature_implementation_path(workspace_root),
      test_editor_feature_implementation_proof(feature_id) + "\n" + marker,
    )
    assert_editor_native_proof_rejected(
      workspace_root, snapshot_path, feature_id,
    )
  }
}

///|
async test "removing only native owner marker cannot restore legacy readiness or archive" {
  let root = @fsx.mkdtemp("/tmp/town-editor-native-marker-removed-XXXXXX")
  let workspace_root = "\{root}/book"
  let snapshot_path = "\{root}/town.json"
  let feature_id = "building-protocol-history"
  write_editor_feature_selection_fixture(
    workspace_root, feature_id, "Building Protocol History", 1, "Add durable protocol history",
    "History is visible",
  )
  let native_metadata = [
    "owner_work_id: native-editor-work", "owner_request_digest: native-request-digest",
    "native_session_id: native-session", "native_command_id: native-command", "native_request_body_digest: native-body-digest",
    "application_receipt: native-editor-work/application-receipt.json",
  ].join("\n")
  let without_marker = test_editor_feature_implementation_proof(feature_id) +
    "\n" +
    native_metadata
  assert_false(without_marker.contains("native_owner_contract"))
  assert_true(without_marker.contains("implementation_status: accepted"))
  for
    proof in [
      without_marker +
      "\nnative_owner_contract: planbook.editor.owner-output.v1",
      without_marker,
    ] {
    @support.write_text_file(
      editor_selected_feature_implementation_path(workspace_root),
      proof,
    )
    assert_editor_native_proof_rejected(
      workspace_root, snapshot_path, feature_id,
    )
  }
}

///|
async fn assert_editor_native_proof_rejected(
  workspace_root : String,
  snapshot_path : String,
  feature_id : String,
) -> Unit {
  assert_false(editor_selected_feature_implementation_ready(workspace_root))
  assert_eq(editor_current_accepted_feature_id(workspace_root), None)
  let lifecycle = inspect_editor_pipeline_lifecycle(
    snapshot_path, workspace_root, "native-proof-consumers",
  )
  assert_false(lifecycle.lifecycle_status == "ready-to-export")
  assert_eq(
    editor_pipeline_feature_history_ready(workspace_root),
    editor_pipeline_history_source_ready(),
  )
  record_accepted_editor_feature_if_present(workspace_root)
  assert_false(
    @fs.exists(editor_implemented_features_ledger_path(workspace_root)),
  )
  for suffix in ["selection.json", "implementation.md"] {
    assert_false(
      @fs.exists(
        editor_implemented_feature_archive_path(
          workspace_root, feature_id, suffix,
        ),
      ),
    )
  }
  assert_eq(editor_accepted_feature_ids(workspace_root), [])
}

///|
async test "legacy accepted manual proof remains ready and archival remains available" {
  let root = @fsx.mkdtemp("/tmp/town-editor-legacy-consumers-XXXXXX")
  let workspace_root = "\{root}/book"
  let snapshot_path = "\{root}/town.json"
  let feature_id = "road-editor"
  write_editor_feature_selection_fixture(
    workspace_root, feature_id, "Road Editor", 1, "Add editable roads", "Roads can be edited",
  )
  write_editor_feature_implementation_fixture(workspace_root, feature_id)
  assert_false(
    editor_proof_has_native_provenance(
      test_editor_feature_implementation_proof(feature_id),
    ),
  )
  assert_true(editor_selected_feature_implementation_ready(workspace_root))
  assert_eq(
    editor_current_accepted_feature_id(workspace_root),
    Some(feature_id),
  )
  let lifecycle = inspect_editor_pipeline_lifecycle(
    snapshot_path, workspace_root, "legacy-proof-consumers",
  )
  assert_eq(lifecycle.lifecycle_status, "ready-to-export")
  record_accepted_editor_feature_if_present(workspace_root)
  assert_true(
    @support.read_text_or_empty(
      editor_implemented_features_ledger_path(workspace_root),
    ).contains("- `road-editor`"),
  )
  assert_eq(
    @support.read_text_or_empty(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "selection.json",
      ),
    ),
    @support.read_text_or_empty(
      editor_feature_selection_result_path(workspace_root),
    ),
  )
  assert_eq(
    @support.read_text_or_empty(
      editor_implemented_feature_archive_path(
        workspace_root, feature_id, "implementation.md",
      ),
    ),
    test_editor_feature_implementation_proof(feature_id),
  )
}

///|
async test "implementation readiness and lifecycle require exact current selected ID" {
  let root = @fsx.mkdtemp("/tmp/town-editor-selection-match-XXXXXX")
  let workspace_root = "\{root}/book"
  let snapshot_path = "\{root}/town.json"
  write_editor_feature_selection_fixture(
    workspace_root, "road", "Road", 1, "Add a road", "Road visible",
  )
  write_editor_feature_implementation_fixture(workspace_root, "road-editor")
  assert_false(editor_selected_feature_implementation_ready(workspace_root))
  let lifecycle = inspect_editor_pipeline_lifecycle(
    snapshot_path, workspace_root, "exact-current-selection",
  )
  assert_false(lifecycle.lifecycle_status == "ready-to-export")
  // Legacy archival can still identify an already accepted previous selection.
  assert_eq(
    editor_current_accepted_feature_id(workspace_root),
    Some("road-editor"),
  )
}

///|
test "native history proof cannot mask independent current source evidence" {
  let unrelated_native = test_editor_feature_implementation_proof("road-editor") +
    "\nnative_owner_contract: planbook.editor.owner-output.v1"
  assert_true(
    editor_pipeline_history_evidence_ready(
      unrelated_native,
      Some("road-editor"),
      true,
    ),
  )
  assert_false(
    editor_pipeline_history_evidence_ready(
      unrelated_native,
      Some("road-editor"),
      false,
    ),
  )
  // Retained metadata without a valid bound proof contributes no history
  // evidence, but it cannot erase independently observed source/UI support.
  let retained_metadata = "owner_work_id: native-editor-work\n"
  assert_true(
    editor_pipeline_history_evidence_ready(retained_metadata, None, true),
  )
  assert_false(
    editor_pipeline_history_evidence_ready(retained_metadata, None, false),
  )
}

///|
test "only validated native history ID can contribute proof readiness" {
  let legacy_history = test_editor_feature_implementation_proof(
    "building-protocol-history",
  )
  let native_history = legacy_history +
    "\nnative_owner_contract: planbook.editor.owner-output.v1"
  assert_false(
    editor_pipeline_history_evidence_ready(native_history, None, false),
  )
  assert_false(
    editor_pipeline_history_evidence_ready(
      native_history,
      Some("road-editor"),
      false,
    ),
  )
  assert_true(
    editor_pipeline_history_evidence_ready(
      native_history,
      Some("building-protocol-history"),
      false,
    ),
  )
  assert_true(
    editor_pipeline_history_evidence_ready(legacy_history, None, false),
  )
}
