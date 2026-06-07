///|
fn render_planbook_autonomy_markdown(status : PlanbookAutonomyStatus) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# PlanBook Autonomy Status\n\n")
  builder.write_string("- status: `\{status.status}`\n")
  builder.write_string("- book: `\{status.book_id}`\n")
  builder.write_string("- workspace: `\{status.workspace_root}`\n")
  builder.write_string("- open gaps: `\{status.open_count}`\n")
  builder.write_string("- satisfied criteria: `\{status.satisfied_count}`\n\n")
  builder.write_string("## Self-Build Criteria\n\n")
  builder.write_string(
    "| Criterion | Owner | State | Evidence | Next Action |\n",
  )
  builder.write_string("| --- | --- | --- | --- | --- |\n")
  for item in status.criteria {
    builder.write_string(
      "|\{item.title}|\{item.owner}|\{if item.satisfied { "satisfied" } else { "open" }}|\{item.evidence}|\{item.next_action}|\n",
    )
  }
  builder.write_string("\n## Runtime Meaning\n\n")
  if status.open_count == 0 {
    builder.write_string(
      "The PlanBook sees no open self-build gaps. The town can continue normal watching and implementation cadence.\n",
    )
  } else {
    builder.write_string(
      "The PlanBook found open self-build gaps. The Mayor should treat the first open gap as implementation work, dispatch bounded MoonClaw repair, validate it, and update this evidence page.\n",
    )
  }
  builder.to_string()
}

///|
fn planbook_autonomy_table(status : PlanbookAutonomyStatus) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "| Criterion | Owner | State | Evidence | Next Action |\n",
  )
  builder.write_string("| --- | --- | --- | --- | --- |\n")
  for item in status.criteria {
    builder.write_string(
      "|\{item.title}|\{item.owner}|\{if item.satisfied { "satisfied" } else { "open" }}|\{item.evidence}|\{item.next_action}|\n",
    )
  }
  builder.to_string().trim_end().to_owned()
}

///|
fn planbook_autonomy_findings(status : PlanbookAutonomyStatus) -> String {
  let findings : Array[String] = []
  for item in status.criteria {
    if !item.satisfied {
      findings.push(
        "- `\{item.id}`: \{item.evidence}. Next: \{item.next_action}.",
      )
    }
  }
  if findings.is_empty() {
    "- no open findings"
  } else {
    findings.join("\n")
  }
}
