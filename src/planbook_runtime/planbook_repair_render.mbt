///|
fn render_planbook_repair_markdown(
  task : PlanbookRepairTask,
  result_text? : String = "",
) -> String {
  let proposal = task.proposal_id.unwrap_or("none")
  let run = task.run_id.unwrap_or("none")
  let lines = [
    "# PlanBook Repair Task",
    "",
    "- id: `\{task.id}`",
    "- criterion: `\{task.criterion_id}`",
    "- title: \{task.title}",
    "- status: `\{task.status}`",
    "- owner: `\{task.owner}`",
    "- workspace: `\{task.workspace_root}`",
    "- packet: `\{task.packet_path}`",
    "- proposal: `\{proposal}`",
    "- run: `\{run}`",
    "- validation: `\{task.validation_command}`",
    "",
    "## Summary",
    "",
    task.summary,
  ]
  if result_text != "" {
    lines.push("")
    lines.push("## Repair Result")
    lines.push("")
    lines.push("```text")
    lines.push(result_text)
    lines.push("```")
  }
  lines.join("\n")
}
