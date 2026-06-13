///|
pub fn registry_from_observed(
  registry_path~ : String,
  templates~ : Array[BookTemplateDescriptor],
  missing_paths~ : Array[String],
) -> BookTemplateRegistry {
  {
    registry_path,
    templates,
    missing_count: missing_paths.length(),
    missing_paths,
    ready: registry_ready(templates, missing_paths),
  }
}

///|
pub fn registry_ready(
  templates : Array[BookTemplateDescriptor],
  missing_paths : Array[String],
) -> Bool {
  !templates.is_empty() && missing_paths.is_empty()
}

///|
pub fn descriptor_check_paths(
  template : BookTemplateDescriptor,
) -> Array[String] {
  let paths = [template.root]
  if !template.install_example.trim().is_empty() {
    paths.push(template.install_example)
  }
  for required in template.required_paths {
    paths.push("\{template.root}/\{required}")
  }
  paths
}

///|
pub fn find_registry_descriptor(
  templates : Array[BookTemplateDescriptor],
  template_id : String,
) -> BookTemplateDescriptor? {
  for template in templates {
    if template.template_id == template_id {
      return Some(template)
    }
  }
  None
}

///|
pub fn render_registry_markdown(registry : BookTemplateRegistry) -> String {
  let rows : Array[String] = []
  for template in registry.templates {
    rows.push(
      "| `\{template.template_id}` | `\{template.book_type}` | `\{template.specialization}` | \{template.title} | `\{template.install_command}` |",
    )
  }
  [
    "# Book Template Registry",
    "",
    "- Registry: `\{registry.registry_path}`",
    "- Ready: `\{registry.ready}`",
    "- Templates: `\{registry.templates.length()}`",
    "- Missing required paths: `\{registry.missing_count}`",
    "",
    "## Templates",
    "",
    "| Template | Book type | Specialization | Title | Install command |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | none | none | none | none |"
    } else {
      rows.join("\n")
    },
    "",
    "## Missing",
    "",
    if registry.missing_paths.is_empty() {
      "- none"
    } else {
      render_registry_missing_paths(registry.missing_paths)
    },
  ].join("\n")
}

///|
fn render_registry_missing_paths(paths : Array[String]) -> String {
  let lines : Array[String] = []
  for path in paths {
    lines.push("- \{path}")
  }
  lines.join("\n")
}
