///|
test "registry policy constructs readiness from observed paths" {
  let templates = [descriptor("pdf-evidence-watch")]
  let ready = registry_from_observed(
    registry_path="templates/books/templates.json",
    templates~,
    missing_paths=[],
  )
  assert_true(ready.ready)
  assert_eq(ready.missing_count, 0)
  let missing = registry_from_observed(
    registry_path="templates/books/templates.json",
    templates~,
    missing_paths=["templates/books/pdf-evidence-watch"],
  )
  assert_false(missing.ready)
  assert_eq(missing.missing_count, 1)
  let empty = registry_from_observed(
    registry_path="templates/books/templates.json",
    templates=[],
    missing_paths=[],
  )
  assert_false(empty.ready)
}

///|
test "registry policy expands descriptor filesystem check paths" {
  let base = descriptor("pdf-evidence-watch")
  let base_paths = descriptor_check_paths(base)
  assert_eq(base_paths.length(), 2)
  assert_eq(base_paths[0], "templates/books/pdf-evidence-watch")
  assert_eq(base_paths[1], "templates/books/pdf-evidence-watch/SKILL.md")
  let with_example = { ..base, install_example: "examples/pdf-watch.json" }
  let example_paths = descriptor_check_paths(with_example)
  assert_eq(example_paths.length(), 3)
  assert_eq(example_paths[0], "templates/books/pdf-evidence-watch")
  assert_eq(example_paths[1], "examples/pdf-watch.json")
  assert_eq(example_paths[2], "templates/books/pdf-evidence-watch/SKILL.md")
}

///|
test "registry policy finds descriptors by template id" {
  let templates = [
    descriptor("pdf-evidence-watch"),
    descriptor("app-tool-book"),
  ]
  match find_registry_descriptor(templates, "app-tool-book") {
    Some(found) => assert_eq(found.template_id, "app-tool-book")
    None => fail("expected matching descriptor")
  }
  assert_true(find_registry_descriptor(templates, "missing") is None)
}

///|
test "registry policy renders registry markdown" {
  let registry = registry_from_observed(
    registry_path="templates/books/templates.json",
    templates=[descriptor("pdf-evidence-watch")],
    missing_paths=["templates/books/pdf-evidence-watch/SKILL.md"],
  )
  let text = render_registry_markdown(registry)
  assert_true(text.contains("# Book Template Registry"))
  assert_true(text.contains("- Ready: `false`"))
  assert_true(text.contains("- Templates: `1`"))
  assert_true(text.contains("| `pdf-evidence-watch` | `research-book` |"))
  assert_true(text.contains("- templates/books/pdf-evidence-watch/SKILL.md"))
}

///|
test "registry file schema decodes template descriptors" {
  let parsed = @json.parse(
    "{\"templates\":[{\"template_id\":\"pdf-evidence-watch\",\"book_type\":\"research-book\",\"specialization\":\"pdf-watch\",\"title\":\"PDF Evidence Watch\",\"purpose\":\"Watch PDFs.\",\"root\":\"templates/books/pdf-evidence-watch\",\"install_example\":\"examples/pdf.json\",\"install_command\":\"books template install\",\"status_command\":\"books template status\",\"required_paths\":[\"SKILL.md\"],\"editable_files\":[\"wiki/methods/analysis-method.md\"]}]}",
  ) catch {
    _ => fail("registry file json should parse")
  }
  let registry : BookTemplateRegistryFile = @json.from_json(parsed) catch {
    _ => fail("registry file schema should decode")
  }
  assert_eq(registry.templates.length(), 1)
  assert_eq(registry.templates[0].template_id, "pdf-evidence-watch")
  assert_eq(registry.templates[0].required_paths[0], "SKILL.md")
}

///|
fn descriptor(template_id : String) -> BookTemplateDescriptor {
  {
    template_id,
    book_type: "research-book",
    specialization: "pdf-watch",
    title: "PDF Evidence Watch",
    purpose: "Watch PDFs.",
    root: "templates/books/pdf-evidence-watch",
    install_example: "",
    install_command: "books template install",
    status_command: "books template status",
    required_paths: ["SKILL.md"],
    editable_files: ["wiki/methods/analysis-method.md"],
  }
}
