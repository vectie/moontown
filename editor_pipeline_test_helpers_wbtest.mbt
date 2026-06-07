///|
fn test_editor_feature_selection_json(
  feature_id : String,
  title : String,
  score : Int,
  implementation_hint : String,
  acceptance : String,
) -> String {
  "{\"contract\":\"\{editor_feature_selection_result_contract()}\",\"selected_feature\":\"\{feature_id}\",\"title\":\"\{title}\",\"score\":\{score},\"implementation_hint\":\"\{implementation_hint}\",\"acceptance\":[\"\{acceptance}\"]}"
}

///|
fn test_editor_feature_selection_json_with_gap(
  feature_id : String,
  title : String,
  current_gap : String,
  implementation_hint : String,
  acceptance : String,
) -> String {
  "{\"contract\":\"\{editor_feature_selection_result_contract()}\",\"selected_feature\":\"\{feature_id}\",\"title\":\"\{title}\",\"score\":1,\"current_gap\":\"\{current_gap}\",\"implementation_hint\":\"\{implementation_hint}\",\"acceptance\":[\"\{acceptance}\"]}"
}

///|
fn test_editor_feature_implementation_proof(feature_id : String) -> String {
  "contract: \{editor_selected_feature_implementation_contract()}\nselected_feature: \{feature_id}\nimplementation_status: accepted\nvalidation: test"
}

///|
async fn write_editor_feature_selection_fixture(
  workspace_root : String,
  feature_id : String,
  title : String,
  score : Int,
  implementation_hint : String,
  acceptance : String,
) -> Unit {
  write_text_file(
    editor_feature_selection_result_path(workspace_root),
    test_editor_feature_selection_json(
      feature_id, title, score, implementation_hint, acceptance,
    ),
  )
}

///|
async fn write_editor_feature_implementation_fixture(
  workspace_root : String,
  feature_id : String,
) -> Unit {
  write_text_file(
    editor_selected_feature_implementation_path(workspace_root),
    test_editor_feature_implementation_proof(feature_id),
  )
}

///|
async fn select_implemented_editor_feature_and_refresh(
  snapshot_path : String,
  workspace_root : String,
  feature_id : String,
  title : String,
  score : Int,
  implementation_hint : String,
  acceptance : String,
) -> String {
  write_editor_feature_selection_fixture(
    workspace_root, feature_id, title, score, implementation_hint, acceptance,
  )
  write_editor_feature_implementation_fixture(workspace_root, feature_id)
  read_text_or_empty(
    write_editor_pipeline_state(snapshot_path~, workspace_root~),
  )
}

///|
fn assert_editor_pipeline_initial_contract(
  text : String,
  digest : String,
) -> Unit raise {
  for
    token in [
      "moontown.editor_pipeline.v1", "command-contract", "feature-selection", "viewport-binding",
      "movement-loop-evidence", "placement-diff-preview", "terrain-label-map", "style-comparison-workbench",
      "\"movement_loops\"", "\"placement_diffs\"", "\"terrain_layers\"", "\"terrain_reasons\"",
      "\"style_candidates\"", "\"style_selection\"", "\"lifecycle_status\": \"planned\"",
      "\"selected_feature\": \"none\"",
    ] {
    assert_true(text.contains(token))
  }
  for
    token in [
      "Editor Pipeline Status", "Movement Loop Evidence", "Placement Diff Preview",
      "Terrain Label Map", "Style Comparison Workbench",
    ] {
    assert_true(digest.contains(token))
  }
}

///|
fn assert_editor_pipeline_ready_feature(
  text : String,
  feature_id : String,
) -> Unit raise {
  assert_true(text.contains("\"status\": \"ready\""))
  assert_true(text.contains("\"selected_feature\": \"\{feature_id}\""))
}

///|
fn assert_editor_pipeline_movement_contract(text : String) -> Unit raise {
  assert_true(text.contains("\"home_ref\": \"book:"))
  assert_true(text.contains("\"entrance_ref\": \"tile:"))
  assert_true(text.contains("\"output_ref\": \"viewport:output#"))
}

///|
async fn write_editor_placement_proposal_fixture(
  workspace_root : String,
) -> Unit {
  write_text_file(
    default_editor_placement_proposal_path(workspace_root~),
    editor_placement_proposal_fixture_json().stringify(),
  )
}

///|
fn editor_placement_proposal_fixture_json() -> Json {
  {
    "version": 2,
    "description": "test placement proposal",
    "modules": [
      {
        "id": "town-shell",
        "enabled": true,
        "title": "Town Shell",
        "book_id": "wenyu-town-shell",
        "district": "civic-core",
        "building_kind": "town-shell",
        "grid_x": 130,
        "grid_y": 74,
        "footprint_w": 8,
        "footprint_h": 6,
        "display_w": 230,
        "display_h": 170,
        "entrance_x": 130,
        "entrance_y": 81,
        "interior_kind": "mayor",
        "style_family": "white-tech-pavilion",
        "asset_base": "tilemap/buildings/white-tech-pavilion/alpha/town-shell.png",
        "asset_roof": "",
        "protocol_pattern": "mayor-supervision",
        "use_case": "Mayor supervision",
        "agent_flow": "Agents route through mayor",
        "summary": "Mayor supervision",
      },
    ],
  }
}

///|
fn assert_editor_pipeline_placement_contract(text : String) -> Unit raise {
  assert_true(text.contains("\"change_kind\": \"moved\""))
  assert_true(text.contains("\"terrain_status\":"))
  assert_true(text.contains("\"before_ref\": \"tile:"))
  assert_true(text.contains("\"after_ref\": \"tile:130,74/8x6\""))
}

///|
fn assert_editor_pipeline_terrain_contract(
  text : String,
  digest : String,
) -> Unit raise {
  for layer in ["water", "roads", "farms", "forests"] {
    assert_true(text.contains("\"layer_id\": \"\{layer}\""))
  }
  assert_true(text.contains("\"terrain_layer\":"))
  assert_true(text.contains("\"placement_ref\": \"tile:"))
  assert_true(digest.contains("Module Terrain Reasons"))
}

///|
fn assert_editor_pipeline_style_contract(
  text : String,
  digest : String,
) -> Unit raise {
  for
    style in [
      "white-tech-pavilion", "wenyu-pixel-backup", "shape-label-workbench",
    ] {
    assert_true(text.contains("\"style_id\": \"\{style}\""))
  }
  assert_true(text.contains("\"selected\": true"))
  assert_true(text.contains("\"selected_style_id\": \"white-tech-pavilion\""))
  assert_true(digest.contains("Style Comparison Workbench"))
}
