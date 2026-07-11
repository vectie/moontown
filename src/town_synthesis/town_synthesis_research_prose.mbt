///|
fn town_report_executive_topic_prefix(topic : String) -> String {
  "- \{display_topic_title(topic)}: "
}

///|
fn town_report_stack_thesis() -> String {
  [
    "MoonTown, MoonBook, and MoonClaw form a vertically layered MoonBit-native agent infrastructure stack:",
    "MoonBook maintains durable knowledge workspaces, MoonClaw executes bounded agent/job work, and MoonTown coordinates multiple books and runtimes as a town-level control plane.",
  ].join(" ") +
  " "
}

///|
fn town_report_lane_evidence_summary() -> String {
  [
    "The strongest current evidence comes from the three MoonBook lane reports,",
    "each of which now contains a thesis-first deep analysis, implementation-backed sections, tables, and Mermaid relationship models.",
  ].join(" ") +
  " "
}

///|
fn town_report_ecosystem_conclusion() -> String {
  [
    "The town-level conclusion is that the projects should be evaluated as a coupled ecosystem rather than as isolated repositories:",
    "knowledge, execution, and governance are deliberately separated so each layer can evolve without collapsing responsibilities.",
  ].join(" ") +
  "\n\n"
}

///|
fn town_report_lane_count_quality_note(plan : @roles.MayorGoalPlan) -> String {
  [
    "The current run includes \{plan.lanes.length()} isolated research lanes, which is the right execution shape for this goal.",
    "The remaining quality question is no longer whether the lanes ran, but whether the final town report preserves the knowledge contained in the lane reports.",
  ].join(" ")
}

///|
fn town_report_skill_quality_shift() -> String {
  [
    "The updated MoonBook research-report skill changes the quality target from status projection to article synthesis.",
    "MoonTown should therefore treat each lane's `raw/bootstrap/deep-report.md` as the primary source for town synthesis, while still using evidence matrices and readiness summaries as guardrails.",
  ].join(" ") +
  "\n\n"
}

///|
fn town_report_separation_overview() -> String {
  [
    "The ecosystem is organized around a clean separation of concerns:", "MoonBook stores and projects durable knowledge, MoonClaw runs jobs and provider-backed tool work, and MoonTown coordinates multi-book goals, quality gates, and cross-lane decisions.",
    "This relationship is visible across the three reports and is the central thesis of the town-level synthesis.",
  ].join(" ") +
  "\n\n"
}

///|
fn town_report_integration_thesis() -> String {
  [
    "The three reports converge on a stack interpretation:", "MoonBook is the knowledge substrate, MoonClaw is the execution substrate, and MoonTown is the governance substrate.",
    "The important design choice is not that the projects can call each other;",
    "it is that they divide responsibility along durable boundaries.",
  ].join(" ") +
  "\n\n"
}

///|
fn town_report_boundary_failure_note() -> String {
  "This model prevents a common multi-agent-system failure mode: the executor does not own long-term truth, the wiki does not become the global scheduler, and the town does not become a raw tool runner."
}

///|
fn town_report_ecosystem_diagram() -> String {
  [
    "```mermaid", "flowchart TB", "  User[User research goal] --> Town[MoonTown mayor]",
    "  Town --> MB[MoonBook lane]", "  Town --> MC[MoonClaw lane]", "  Town --> MT[MoonTown lane]",
    "  MB --> MBK[Durable wiki and generated report]", "  MC --> MCR[Execution evidence and provider results]",
    "  MT --> MTO[Routing supervision and town synthesis]", "  MBK --> S[Town-level ecosystem report]",
    "  MCR --> S", "  MTO --> S", "```", "",
  ].join("\n")
}
