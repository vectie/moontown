///|
priv struct EditorModuleRowView {
  title : String
  identity : String
  placement : String
  style : String
  runtime_label : String
  runtime_class : String
  projection_status : String
  issue_text : String
}

///|
fn editor_module_row_view(
  model : Model,
  civic : WenyuTownModule,
  executions : Array[@core.TaskExecutionRecord],
) -> EditorModuleRowView {
  let runtime = wenyu_module_runtime_state(model, civic, executions)
  {
    title: civic.title,
    identity: "\{civic.id} / \{civic.book_id}",
    placement:
      "\{civic.grid_x},\{civic.grid_y} / \{civic.footprint_w}x\{civic.footprint_h} -> \{civic.entrance_x},\{civic.entrance_y}",
    style: "\{civic.style_family} / \{civic.protocol_pattern}",
    runtime_label: runtime.status_label,
    runtime_class: runtime.status_class,
    projection_status: editor_module_projection_status(
      find_module_book_projection(model, civic),
    ),
    issue_text: editor_module_issue_text(module_validation_issues(civic)),
  }
}

///|
fn editor_module_projection_status(
  projection : BookProjectionFragment?,
) -> String {
  match projection {
    Some(_) => "MoonBook output connected"
    None => "Missing MoonBook output"
  }
}

///|
fn editor_module_issue_text(issues : Array[String]) -> String {
  if issues.is_empty() {
    "placement clean"
  } else {
    issues.join(", ")
  }
}
