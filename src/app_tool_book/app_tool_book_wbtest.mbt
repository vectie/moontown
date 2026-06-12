///|
async test "app tool book bootstraps durable app and civic manifest" {
  let base = "/tmp/moontown-app-tool-book-wbtest"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let workspace_root = "\{base}/toolbook"
  let summary = bootstrap_app_tool_book(
    book_id="toolbook-opc-dashboard",
    title="OPC Dashboard",
    purpose="Watch OPC sources and expose a usable dashboard.",
    websites=["https://example.org/opc"],
    analysis_method="# OPC Method\n\nPrefer source-backed deltas.",
    tool_spec="# OPC Dashboard Spec\n\nShow changes and questions.",
    civic_building_id="opc-lab",
    cadence_ticks=31,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
    workspace_root~,
  )
  assert_true(summary.contains("book_template_install_status: installed"))
  assert_true(summary.contains("Bootstrapped App ToolBook"))
  let status = inspect_app_tool_book(
    book_id="toolbook-opc-dashboard",
    workspace_root~,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(status.ready)
  assert_eq(status.missing_count, 0)
  assert_true(@fs.exists("\{workspace_root}/tool-manifest.json"))
  assert_true(@fs.exists("\{workspace_root}/app/index.html"))
  assert_true(@fs.exists(generated_tool_workspace_path(workspace_root)))
  assert_true(@fs.exists(generated_site_workspace_path(workspace_root)))
  let manifest = read_text_or_empty("\{workspace_root}/tool-manifest.json")
  assert_true(manifest.contains("moontown.app_tool_book.manifest.v1"))
  assert_true(manifest.contains("opc-lab"))
}

///|
async test "app tool book config installer resolves method and spec files" {
  let base = "/tmp/moontown-app-tool-book-install-wbtest"
  let config_path = "\{base}/app-tool.json"
  let method_path = "\{base}/method.md"
  let spec_path = "\{base}/tool.md"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let workspace_root = "\{base}/workspace"
  write_text_file(method_path, "# File Method\n\nUse file method.")
  write_text_file(spec_path, "# File Tool Spec\n\nUse file tool spec.")
  let spec = AppToolBookInstallSpec::{
    book_id: "toolbook-file-config",
    title: "File Config ToolBook",
    purpose: "Installed from a Moondesk-style config.",
    websites: ["https://example.org/data"],
    analysis_method: "",
    analysis_method_path: "method.md",
    tool_spec: "",
    tool_spec_path: "tool.md",
    civic_building_id: "file-config-building",
    cadence_ticks: 37,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  let summary = install_app_tool_book_config(
    config_path,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(summary.contains("book_template_install_status: installed"))
  assert_true(summary.contains("Installed App ToolBook config"))
  assert_true(
    read_text_or_empty("\{workspace_root}/wiki/methods/analysis-method.md").contains(
      "File Method",
    ),
  )
  assert_true(
    read_text_or_empty("\{workspace_root}/wiki/tools/tool-spec.md").contains(
      "File Tool Spec",
    ),
  )
}

///|
async test "app tool book status helper reports required path gaps" {
  let root = "/tmp/moontown-app-tool-book-status-helper-wbtest"
  ignore_checked_command("rm", ["-rf", root])
  let missing_before = missing_required_paths(root)
  assert_eq(missing_before.length(), required_paths().length())
  write_text_file("\{root}/book.json", "{}")
  write_text_file("\{root}/tool-manifest.json", "{}")
  let missing_after = missing_required_paths(root)
  assert_true(missing_after.length() < missing_before.length())
  assert_true(!missing_after.contains("book.json"))
  assert_true(!missing_after.contains("tool-manifest.json"))
  assert_true(missing_after.contains("wiki/index.md"))
}
