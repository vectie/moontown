///|
pub async fn render_book_template_registry(
  registry_path? : String = default_book_template_registry_path(),
) -> String {
  let registry = inspect_book_template_registry(registry_path~)
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
      markdown_bullets(registry.missing_paths)
    },
  ].join("\n")
}

///|
pub async fn render_book_template_request_status(
  request_path? : String = default_book_template_request_path(),
) -> String {
  let status = inspect_book_template_request_status(request_path~)
  let ledger = load_book_template_request_ledger(request_path)
  let rows : Array[String] = []
  for request in ledger.requests {
    rows.push(
      "| `\{request.id}` | `\{request.template_id}` | `\{request.status}` | `\{request.config_path}` | \{request.summary} |",
    )
  }
  [
    "# Book Template Request Inbox",
    "",
    "- Path: `\{status.request_path}`",
    "- Ready: `\{status.ready}`",
    "- Requests: `\{status.request_count}`",
    "- Pending: `\{status.pending_count}`",
    "- Installed: `\{status.installed_count}`",
    "- Failed: `\{status.failed_count}`",
    "- Retry: `\{status.retry_count}`",
    "- Event log: `\{status.event_path}`",
    "- Latest event: \{status.latest_event_summary}",
    "",
    "| Request | Template | Status | Config | Summary |",
    "| --- | --- | --- | --- | --- |",
    if rows.is_empty() {
      "| none | none | none | none | none |"
    } else {
      rows.join("\n")
    },
  ].join("\n")
}
