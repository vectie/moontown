///|
async test "native archive writes frozen artifacts after current files change" {
  let root = @fsx.mkdtemp("/tmp/town-editor-frozen-archive-XXXXXX")
  let workspace_root = "\{root}/book"
  let selection_a = test_editor_feature_selection_json(
    "road-editor", "Road Editor", 1, "Add editable roads", "Roads persist",
  )
  let proof_a = test_editor_feature_implementation_proof("road-editor") +
    "\nnative_owner_contract: planbook.editor.owner-output.v1\nowner_work_id: frozen-a"
  // This is the post-validation seam: native_work owns package/receipt
  // validation and hands these immutable package bytes to the archive writer.
  let validated : @native_work.EditorAppliedFeature = {
    selected_feature: "road-editor",
    selection_content: selection_a,
    implementation_content: proof_a,
  }
  @support.write_text_file(
    editor_feature_selection_result_path(workspace_root),
    selection_a,
  )
  @support.write_text_file(
    editor_selected_feature_implementation_path(workspace_root),
    proof_a,
  )
  @async.sleep(1)
  let selection_b = test_editor_feature_selection_json(
    "terrain-label-map", "Terrain Labels", 1, "Add terrain labels", "Labels are visible",
  )
  let proof_b = test_editor_feature_implementation_proof("terrain-label-map") +
    "\nnative_owner_contract: planbook.editor.owner-output.v1\nowner_work_id: changed-b"
  @support.write_text_file(
    editor_feature_selection_result_path(workspace_root),
    selection_b,
  )
  @support.write_text_file(
    editor_selected_feature_implementation_path(workspace_root),
    proof_b,
  )
  archive_editor_applied_feature(workspace_root, validated)
  assert_eq(
    @support.read_text_or_empty(
      editor_implemented_feature_archive_path(
        workspace_root, "road-editor", "selection.json",
      ),
    ),
    selection_a,
  )
  assert_eq(
    @support.read_text_or_empty(
      editor_implemented_feature_archive_path(
        workspace_root, "road-editor", "implementation.md",
      ),
    ),
    proof_a,
  )
  let ledger = @support.read_text_or_empty(
    editor_implemented_features_ledger_path(workspace_root),
  )
  assert_true(ledger.contains("- `road-editor`"))
  assert_false(ledger.contains("- `terrain-label-map`"))
  for suffix in ["selection.json", "implementation.md"] {
    assert_false(
      @fs.exists(
        editor_implemented_feature_archive_path(
          workspace_root, "terrain-label-map", suffix,
        ),
      ),
    )
  }
  assert_eq(
    @support.read_text_or_empty(
      editor_feature_selection_result_path(workspace_root),
    ),
    selection_b,
  )
  assert_eq(
    @support.read_text_or_empty(
      editor_selected_feature_implementation_path(workspace_root),
    ),
    proof_b,
  )
}
