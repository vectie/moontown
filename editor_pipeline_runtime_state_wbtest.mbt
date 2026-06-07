///|
async test "editor pipeline refresh writes runtime contract" {
  let workspace = planbook_autonomy_test_workspace(
    "/tmp/moontown-editor-pipeline-wbtest",
  )
  let snapshot_path = workspace.snapshot_path
  let workspace_root = workspace.workspace_root
  ignore(
    bootstrap_moontown_planbook(
      book_catalog_path=workspace.catalog_path,
      workspace_root~,
    ),
  )
  let path = write_editor_pipeline_state(snapshot_path~, workspace_root~)
  let text = read_text_or_empty(path)
  let digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_editor_pipeline_initial_contract(text, digest)
  let ready_text = select_implemented_editor_feature_and_refresh(
    snapshot_path, workspace_root, "output-readiness-lifecycle", "Output Readiness Lifecycle",
    1, "add lifecycle", "ready-to-export visible",
  )
  assert_editor_pipeline_ready_feature(ready_text, "output-readiness-lifecycle")
  assert_true(ready_text.contains("\"lifecycle_status\": \"ready-to-export\""))
  let movement_text = select_implemented_editor_feature_and_refresh(
    snapshot_path, workspace_root, "movement-loop-evidence", "Movement Loop Evidence",
    1, "add route proof", "home to entrance to output to home visible",
  )
  assert_editor_pipeline_ready_feature(movement_text, "movement-loop-evidence")
  assert_editor_pipeline_movement_contract(movement_text)
  write_editor_feature_selection_fixture(
    workspace_root, "placement-diff-preview", "Placement Diff Preview", 1, "add reviewable placement diff",
    "placement diff visible before export",
  )
  write_editor_placement_proposal_fixture(workspace_root)
  write_editor_feature_implementation_fixture(
    workspace_root, "placement-diff-preview",
  )
  let placement_text = read_text_or_empty(
    write_editor_pipeline_state(snapshot_path~, workspace_root~),
  )
  assert_editor_pipeline_ready_feature(placement_text, "placement-diff-preview")
  assert_editor_pipeline_placement_contract(placement_text)
  let terrain_text = select_implemented_editor_feature_and_refresh(
    snapshot_path, workspace_root, "terrain-label-map", "Terrain Label Map Layers",
    1, "add terrain label evidence", "terrain labels visible before export",
  )
  let terrain_digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_editor_pipeline_ready_feature(terrain_text, "terrain-label-map")
  assert_editor_pipeline_terrain_contract(terrain_text, terrain_digest)
  let style_text = select_implemented_editor_feature_and_refresh(
    snapshot_path, workspace_root, "style-comparison-workbench", "Building Style Comparison Workbench",
    2, "compare visual styles", "three style candidates visible",
  )
  let style_digest = read_text_or_empty(
    default_editor_pipeline_markdown_path(snapshot_path~),
  )
  assert_editor_pipeline_ready_feature(style_text, "style-comparison-workbench")
  assert_editor_pipeline_style_contract(style_text, style_digest)
}
