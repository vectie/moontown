///|
async test "editor pipeline module config loader handles missing invalid and valid files" {
  let root = "/tmp/moontown-editor-module-config-wbtest"
  @support.ignore_checked_command("rm", ["-rf", root])
  assert_true(
    load_editor_pipeline_module_config("\{root}/missing.json") is None,
  )
  @support.write_text_file("\{root}/invalid.json", "{bad json")
  assert_true(
    load_editor_pipeline_module_config("\{root}/invalid.json") is None,
  )
  @support.write_text_file(
    "\{root}/valid.json",
    editor_pipeline_module_config_fixture_json().stringify(),
  )
  let config = match load_editor_pipeline_module_config("\{root}/valid.json") {
    Some(config) => config
    None => abort("expected valid editor pipeline module config")
  }
  assert_eq(config.version, 1)
  assert_eq(config.description, "test registry")
  assert_eq(config.modules.length(), 1)
  let module_entry = config.modules[0]
  assert_eq(module_entry.id, "test-module")
  assert_eq(module_entry.book_id, "book-test")
  assert_eq(module_entry.footprint_w, 3)
  assert_eq(module_entry.entrance_y, 6)
}

///|
fn editor_pipeline_module_config_fixture_json() -> Json {
  {
    "version": 1,
    "description": "test registry",
    "modules": [editor_pipeline_module_config_entry_fixture_json()],
  }
}

///|
fn editor_pipeline_module_config_entry_fixture_json() -> Json {
  {
    "id": "test-module",
    "enabled": true,
    "title": "Test Module",
    "book_id": "book-test",
    "district": "civic-core",
    "building_kind": "pavilion",
    "grid_x": 1,
    "grid_y": 2,
    "footprint_w": 3,
    "footprint_h": 4,
    "display_w": 120,
    "display_h": 90,
    "entrance_x": 5,
    "entrance_y": 6,
    "interior_kind": "salon",
    "style_family": "white-tech-pavilion",
    "asset_base": "base.png",
    "asset_roof": "roof.png",
    "protocol_pattern": "research-salon",
    "use_case": "test use case",
    "agent_flow": "home to salon to home",
    "summary": "test summary",
  }
}

///|
test "editor pipeline default module config path is centralized" {
  assert_eq(
    default_editor_pipeline_module_config_path(),
    "ui/assets/tilemap/modules/wenyu-town-modules.json",
  )
  assert_eq(
    default_editor_pipeline_module_config_ref(),
    default_editor_pipeline_module_config_path(),
  )
}
