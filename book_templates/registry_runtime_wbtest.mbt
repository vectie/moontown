///|
async test "book template registry exposes pdf evidence watch template" {
  let registry = inspect_registry()
  assert_true(registry.ready)
  assert_eq(registry.missing_count, 0)
  let mut found = false
  let mut found_app_tool = false
  for template in registry.templates {
    if template.template_id == "pdf-evidence-watch" {
      found = true
      assert_eq(template.book_type, "research-book")
      assert_true(template.install_command.contains("books template install"))
      assert_true(
        template.editable_files.contains("wiki/methods/analysis-method.md"),
      )
    }
    if template.template_id == "app-tool-book" {
      found_app_tool = true
      assert_eq(template.book_type, "toolbook")
      assert_true(template.install_command.contains("books template install"))
      assert_true(template.status_command.contains("books app-tool status"))
      assert_true(template.editable_files.contains("wiki/tools/tool-spec.md"))
    }
  }
  assert_true(found)
  assert_true(found_app_tool)
}

///|
async test "book template registry reports missing manifest as not ready" {
  let registry = inspect_registry(
    registry_path="/tmp/moontown-missing-book-template-registry.json",
  )
  assert_false(registry.ready)
  assert_eq(registry.templates.length(), 0)
  assert_eq(registry.missing_count, 1)
}

///|
async test "generic book template installer dispatches pdf evidence watch" {
  let base = "/tmp/moontown-book-template-install-wbtest"
  let config_path = "\{base}/pdf-watch.json"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let method_path = "\{base}/method.md"
  let workspace_root = "\{base}/workspace"
  write_text_file(
    method_path, "# Registry Method\n\nPromote only durable deltas.",
  )
  let spec = @pdf_evidence_watch.PdfEvidenceWatchInstallSpec::{
    book_id: "research-registry-pdfs",
    title: "Registry PDF Watch",
    purpose: "Installed through generic template registry.",
    websites: ["https://example.org/registry-pdfs"],
    analysis_method: "",
    analysis_method_path: "method.md",
    cadence_ticks: 19,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  let summary = install_book_template_config(
    "pdf-evidence-watch",
    config_path,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(summary.contains(install_success_marker()))
  assert_true(summary.contains("Installed PDF Evidence Watch config"))
  assert_true(@fs.exists("\{workspace_root}/book.json"))
  let method_text = read_text_or_empty(
    "\{workspace_root}/wiki/methods/analysis-method.md",
  )
  assert_true(method_text.contains("Registry Method"))
}

///|
async test "generic book template installer dispatches app tool book" {
  let base = "/tmp/moontown-app-tool-template-install-wbtest"
  let config_path = "\{base}/app-tool.json"
  let catalog_path = "\{base}/catalog.json"
  let goals_path = "\{base}/standing-goals.json"
  let method_path = "\{base}/method.md"
  let tool_path = "\{base}/tool.md"
  let workspace_root = "\{base}/workspace"
  write_text_file(method_path, "# Tool Method\n\nUse current sources.")
  write_text_file(tool_path, "# Tool Spec\n\nRender an explorer.")
  let spec = @app_tool_book.AppToolBookInstallSpec::{
    book_id: "toolbook-registry-app",
    title: "Registry App Tool",
    purpose: "Installed through generic template registry.",
    websites: ["https://example.org/tool-data"],
    analysis_method: "",
    analysis_method_path: "method.md",
    tool_spec: "",
    tool_spec_path: "tool.md",
    civic_building_id: "registry-tool-lab",
    cadence_ticks: 29,
    workspace_root,
  }
  write_text_file(config_path, spec.to_json().stringify(indent=2))
  let summary = install_book_template_config(
    "app-tool-book",
    config_path,
    book_catalog_path=catalog_path,
    standing_goal_path=goals_path,
  )
  assert_true(summary.contains(install_success_marker()))
  assert_true(summary.contains("Installed App ToolBook config"))
  assert_true(@fs.exists("\{workspace_root}/tool-manifest.json"))
  assert_true(@fs.exists("\{workspace_root}/book/site/generated/tool.html"))
}

///|
test "book template installer registry names supported installers" {
  assert_true(find_book_template_installer("pdf-evidence-watch") is Some(_))
  assert_true(find_book_template_installer("app-tool-book") is Some(_))
  assert_true(find_book_template_installer("experimental-only") is None)
}

///|
async test "generic book template installer reports registered templates without installers" {
  let base = "/tmp/moontown-book-template-no-installer-wbtest"
  let registry_path = "\{base}/templates.json"
  let config_path = "\{base}/config.json"
  write_text_file(
    registry_path,
    "{\"templates\":[{\"template_id\":\"experimental-only\",\"book_type\":\"experimental\",\"specialization\":\"test\",\"title\":\"Experimental Only\",\"purpose\":\"Registered without an installer.\",\"root\":\"\{base}\",\"install_example\":\"\",\"install_command\":\"\",\"status_command\":\"\",\"required_paths\":[],\"editable_files\":[]}]}",
  )
  write_text_file(config_path, "{}")
  let summary = install_book_template_config(
    "experimental-only",
    config_path,
    registry_path~,
    book_catalog_path="\{base}/catalog.json",
    standing_goal_path="\{base}/standing-goals.json",
  )
  assert_eq(summary, registered_without_installer_summary("experimental-only"))
}
