///|
async fn write_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  snapshot_path : String,
) -> Unit {
  if plan.lanes.length() < 2 {
    return
  }
  let synthesis_dir = town_synthesis_dir(snapshot_path)
  let path = "\{synthesis_dir}/\{town_goal_slug(goal)}.md"
  let latest_path = "\{synthesis_dir}/latest.md"
  let content = render_town_goal_synthesis(state, goal, plan)
  write_text_file(path, content)
  write_text_file(latest_path, content)
  register_town_synthesis_execution(state, goal, plan, path)
  state.record_event(
    @core.TownEvent::new(
      id="event-town-synthesis-\{state.events.length()}",
      kind="synthesis",
      detail="Mayor wrote town-level synthesis for \{plan.lanes.length()} lanes: \{path}",
      related_task_id=Some(town_synthesis_task_id(goal)),
      related_book_id=Some("town"),
    ),
  )
}

///|
async fn render_town_goal_synthesis(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "# Moontown, MoonBook, and MoonClaw: Deep Research Analysis\n\n",
  )
  builder.write_string("Goal: \{goal}\n\n")
  builder.write_string("Mayor plan: \{plan.summary}\n\n")
  builder.write_string("Output contract: `mayor.town_synthesis.v1`\n\n")
  builder.write_string("## Executive Summary\n\n")
  builder.write_string(render_town_report_executive_summary(plan))
  builder.write_string("\n\n")
  builder.write_string("## Ecosystem Overview and Foundational Context\n\n")
  builder.write_string(render_town_ecosystem_overview(plan))
  builder.write_string("\n\n")
  builder.write_string(
    "## MoonBook: Documentation and Knowledge Infrastructure\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moonbook"))
  builder.write_string(
    "\n\n## MoonClaw: Agent Runtime and Job Orchestration\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moonclaw"))
  builder.write_string(
    "\n\n## Moontown: Orchestration Layer and Control Plane\n\n",
  )
  builder.write_string(render_lane_deep_report_for_topic(plan, "moontown"))
  builder.write_string(
    "\n\n## Inter-System Integration and Architectural Relationships\n\n",
  )
  builder.write_string(render_town_integration_section(plan))
  builder.write_string(
    "\n\n## Technical Documentation and Development Resources\n\n",
  )
  builder.write_string(render_town_technical_resources(plan))
  builder.write_string("\n\n## Comparative and Contextual Analysis\n\n")
  builder.write_string(render_town_comparative_analysis())
  builder.write_string("\n\n## Current Status and Development Trajectory\n\n")
  builder.write_string(render_town_status_and_trajectory(state, plan))
  builder.write_string("\n\n## Evidence and Limits\n\n")
  builder.write_string(render_town_evidence_and_limits(state, plan))
  builder.to_string()
}

///|
async fn render_town_report_executive_summary(
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "Moontown, MoonBook, and MoonClaw form a vertically layered MoonBit-native agent infrastructure stack: MoonBook maintains durable knowledge workspaces, MoonClaw executes bounded agent/job work, and Moontown coordinates multiple books and runtimes as a town-level control plane. ",
  )
  builder.write_string(
    "The strongest current evidence comes from the three MoonBook lane reports, each of which now contains a thesis-first deep analysis, implementation-backed sections, tables, and Mermaid relationship models. ",
  )
  builder.write_string(
    "The town-level conclusion is that the projects should be evaluated as a coupled ecosystem rather than as isolated repositories: knowledge, execution, and governance are deliberately separated so each layer can evolve without collapsing responsibilities.\n\n",
  )
  for topic in ["moonbook", "moonclaw", "moontown"] {
    builder.write_string("- \{display_topic_title(topic)}: ")
    builder.write_string(first_deep_report_summary(plan, topic))
    builder.write_string("\n")
  }
  builder.to_string()
}

///|
async fn first_deep_report_summary(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = read_lane_deep_report(entry)
      if report.is_blank() {
        return "No deep report was available for this lane."
      }
      let body = section_body(report, "## Executive Summary")
      let compact = first_non_heading_paragraph(body)
      if compact.is_blank() {
        "Deep report exists, but no usable executive-summary paragraph was found."
      } else {
        markdown_excerpt(compact, 520)
      }
    }
    None => "No matching lane was found."
  }
}

///|
fn render_town_ecosystem_overview(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "The updated MoonBook research-report skill changes the quality target from status projection to article synthesis. Moontown should therefore treat each lane's `raw/bootstrap/deep-report.md` as the primary source for town synthesis, while still using evidence matrices and readiness summaries as guardrails.\n\n",
  )
  builder.write_string(
    "The ecosystem is organized around a clean separation of concerns: MoonBook stores and projects durable knowledge, MoonClaw runs jobs and provider-backed tool work, and Moontown coordinates multi-book goals, quality gates, and cross-lane decisions. This relationship is visible across the three reports and is the central thesis of the town-level synthesis.\n\n",
  )
  builder.write_string("```mermaid\n")
  builder.write_string("flowchart TB\n")
  builder.write_string("  User[User research goal] --> Town[Moontown mayor]\n")
  builder.write_string("  Town --> MB[MoonBook lane]\n")
  builder.write_string("  Town --> MC[MoonClaw lane]\n")
  builder.write_string("  Town --> MT[Moontown lane]\n")
  builder.write_string("  MB --> MBK[Durable wiki and generated report]\n")
  builder.write_string(
    "  MC --> MCR[Execution evidence and provider results]\n",
  )
  builder.write_string("  MT --> MTO[Routing supervision and town synthesis]\n")
  builder.write_string("  MBK --> S[Town-level ecosystem report]\n")
  builder.write_string("  MCR --> S\n")
  builder.write_string("  MTO --> S\n")
  builder.write_string("```\n\n")
  builder.write_string(
    "The current run includes \{plan.lanes.length()} isolated research lanes, which is the right execution shape for this goal. The remaining quality question is no longer whether the lanes ran, but whether the final town report preserves the knowledge contained in the lane reports.",
  )
  builder.to_string()
}

///|
async fn render_lane_deep_report_for_topic(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> String {
  match lane_entry_for_topic(plan, topic) {
    Some(entry) => {
      let report = read_lane_deep_report(entry)
      if report.is_blank() {
        return render_missing_deep_report_block(entry)
      }
      let body = remove_first_markdown_title(report)
      let excerpt = markdown_excerpt(demote_markdown_headings(body), 9000)
      "\{excerpt}\n\nSource lane report: `\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md`"
    }
    None => "- No lane report found for `\{topic}`."
  }
}

///|
fn render_missing_deep_report_block(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  "- Missing `raw/bootstrap/deep-report.md` for `\{entry.id}`. The town report cannot meet the MoonBook research-report skill standard until this lane emits a long-form report."
}

///|
fn render_town_integration_section(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "The three reports converge on a stack interpretation: MoonBook is the knowledge substrate, MoonClaw is the execution substrate, and Moontown is the governance substrate. The important design choice is not that the projects can call each other; it is that they divide responsibility along durable boundaries.\n\n",
  )
  builder.write_string(
    "| Layer | Project | Primary Responsibility | Town-Level Interpretation |\n",
  )
  builder.write_string("| --- | --- | --- | --- |\n")
  for topic in ["moonbook", "moonclaw", "moontown"] {
    match lane_entry_for_topic(plan, topic) {
      Some(entry) =>
        builder.write_string(
          "| \{display_topic_title(topic)} | \{entry.id} | \{project_responsibility(topic)} | \{project_town_interpretation(topic)} |\n",
        )
      None => ()
    }
  }
  builder.write_string("\n")
  builder.write_string(
    "This model prevents a common multi-agent-system failure mode: the executor does not own long-term truth, the wiki does not become the global scheduler, and the town does not become a raw tool runner.",
  )
  builder.to_string()
}

///|
fn render_town_technical_resources(plan : @roles.MayorGoalPlan) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "The strongest technical evidence in the current run comes from repository-controlled READMEs, local source files, Moon module metadata, architecture docs, and the generated deep reports. The town synthesis treats these as lane-owned evidence rather than copying raw logs directly into the main article.\n\n",
  )
  builder.write_string(
    "| Lane | Deep Report | Evidence Matrix | Generated Site |\n",
  )
  builder.write_string("| --- | --- | --- | --- |\n")
  for lane in plan.lanes {
    let root = @moonbook.workspace_root(lane.entry)
    let site = @moonbook.generated_site_index_path(lane.entry)
    builder.write_string(
      "| \{lane.entry.id} | `\{root}/raw/bootstrap/deep-report.md` | `\{root}/raw/bootstrap/evidence-matrix.md` | `\{site}` |\n",
    )
  }
  builder.write_string("\n")
  builder.write_string(
    "The town report should be judged against the `research-report` skill standard: at least ten sections for a multi-project report, thesis-first prose, tables, relationship diagrams, maturity assessment, and an evidence/limits section.",
  )
  builder.to_string()
}

///|
fn render_town_comparative_analysis() -> String {
  "Compared with a single generated marketing page, a town-level deep report must answer a different question: how do the projects work together, where do their boundaries sit, and what tradeoffs does the stack make? MoonBook contributes durable memory and report projection, MoonClaw contributes bounded execution and tool-backed evidence collection, and Moontown contributes planning, parallel decomposition, supervision, and acceptance. This makes the ecosystem closer to a coordinated agent-infrastructure stack than to a loose collection of utilities."
}

///|
fn render_town_status_and_trajectory(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  let running_count = count_lanes_by_status(state, plan, "running")
  let complete_count = count_lanes_by_status(state, plan, "complete")
  let review_count = count_lanes_by_status(state, plan, "review queued")
  let failed_count = count_lanes_by_status(state, plan, "failed")
  builder.write_string(
    "The latest town run has \{complete_count} completed lanes, \{running_count} running lanes, \{review_count} review-queued lanes, and \{failed_count} failed lanes. ",
  )
  if review_count == 0 && failed_count == 0 && running_count == 0 {
    builder.write_string(
      "That status is strong enough for a town-level report, provided the lane `deep-report.md` files remain present and substantive.\n\n",
    )
  } else {
    builder.write_string(
      "That status means the town report should be treated as interim rather than final.\n\n",
    )
  }
  builder.write_string(
    "The next improvement is to stop treating generated marketing pages as the final reading surface. The source of truth for research quality is now the deep report in each MoonBook lane plus this town-level synthesis.",
  )
  builder.to_string()
}

///|
async fn render_town_evidence_and_limits(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string("### Lane Matrix\n\n")
  builder.write_string(render_town_lane_matrix(state, plan))
  builder.write_string("\n### Readiness\n\n")
  for lane in plan.lanes {
    let gaps = research_quality_gaps(lane.entry)
    if gaps.is_empty() {
      builder.write_string(
        "- \{lane.entry.id}: ready for cross-lane synthesis.\n",
      )
    } else {
      let gap_summary = gaps.join("; ")
      builder.write_string("- \{lane.entry.id}: blocked by \{gap_summary}.\n")
    }
  }
  builder.write_string("\n")
  builder.write_string(
    "Limit: this town report relies on the three lane reports produced by MoonBook. If a lane report is shallow, missing, or process-heavy, Moontown should mark the town synthesis as review-queued instead of masking the weakness with generic ecosystem prose.\n\n",
  )
  builder.write_string("Mayor decision: ")
  builder.write_string(town_synthesis_decision(state, plan))
  builder.to_string()
}

///|
async fn render_town_lane_matrix(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "| Lane | Status | Verified Sources | Evidence | Entities | Concepts | Deep Report |\n",
  )
  builder.write_string("| --- | --- | ---: | ---: | ---: | ---: | --- |\n")
  for lane in plan.lanes {
    let summary = Some(@moonbook.summarize_state(lane.entry)) catch {
      _ => None
    }
    let status = lane_research_status(state, lane.entry.id)
    let root = @moonbook.workspace_root(lane.entry)
    match summary {
      Some(summary) =>
        builder.write_string(
          "| \{lane.entry.id} | \{status} | \{summary.verified_source_count} | \{summary.evidence_count} | \{summary.entity_page_count} | \{summary.concept_page_count} | `\{root}/raw/bootstrap/deep-report.md` |\n",
        )
      None =>
        builder.write_string(
          "| \{lane.entry.id} | \{status} | 0 | 0 | 0 | 0 | `\{root}/raw/bootstrap/deep-report.md` |\n",
        )
    }
  }
  builder.to_string()
}

///|
fn lane_entry_for_topic(
  plan : @roles.MayorGoalPlan,
  topic : String,
) -> @moonbook.BookCatalogEntry? {
  let needle = "research-\{topic}"
  for lane in plan.lanes {
    if lane.entry.id == needle || lane.entry.id.contains(topic) {
      return Some(lane.entry)
    }
  }
  None
}

///|
fn display_topic_title(topic : String) -> String {
  match topic {
    "moonbook" => "MoonBook"
    "moonclaw" => "MoonClaw"
    "moontown" => "Moontown"
    _ => topic
  }
}

///|
fn project_responsibility(topic : String) -> String {
  match topic {
    "moonbook" =>
      "documentation, wiki state, report projection, and durable memory"
    "moonclaw" =>
      "agent runtime, jobs, provider tasks, tools, memory, and artifacts"
    "moontown" =>
      "goal decomposition, routing, supervision, quality gates, and town synthesis"
    _ => "lane-specific responsibility"
  }
}

///|
fn project_town_interpretation(topic : String) -> String {
  match topic {
    "moonbook" =>
      "the book layer that decides what evidence becomes durable knowledge"
    "moonclaw" =>
      "the claw layer that performs bounded work and returns structured evidence"
    "moontown" =>
      "the town layer that coordinates many books and workers into one operator-visible goal"
    _ => "a supporting layer in the town goal"
  }
}

///|
async fn read_lane_deep_report(entry : @moonbook.BookCatalogEntry) -> String {
  read_text_or_empty(
    "\{@moonbook.workspace_root(entry)}/raw/bootstrap/deep-report.md",
  )
}

///|
fn remove_first_markdown_title(report : String) -> String {
  let builder = StringBuilder::new()
  let mut skipped = false
  for line in report.split("\n") {
    let trimmed = line.trim().to_string()
    if !skipped && trimmed.has_prefix("# ") {
      skipped = true
      continue
    }
    builder.write_string(line.to_string())
    builder.write_string("\n")
  }
  builder.to_string().trim().to_string()
}

///|
fn demote_markdown_headings(markdown : String) -> String {
  let builder = StringBuilder::new()
  for line in markdown.split("\n") {
    if line.has_prefix("####") {
      builder.write_string("#\{line}\n")
    } else if line.has_prefix("###") {
      builder.write_string("#\{line}\n")
    } else if line.has_prefix("##") {
      builder.write_string("#\{line}\n")
    } else {
      builder.write_string(line.to_string())
      builder.write_string("\n")
    }
  }
  builder.to_string()
}

///|
fn section_body(report : String, heading : String) -> String {
  let builder = StringBuilder::new()
  let mut in_section = false
  for line in report.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed == heading {
      in_section = true
      continue
    }
    if in_section && trimmed.has_prefix("## ") {
      break
    }
    if in_section {
      builder.write_string(line.to_string())
      builder.write_string("\n")
    }
  }
  builder.to_string().trim().to_string()
}

///|
fn first_non_heading_paragraph(markdown : String) -> String {
  let builder = StringBuilder::new()
  for line in markdown.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed.is_blank() {
      if !builder.to_string().trim().is_blank() {
        break
      }
      continue
    }
    if trimmed.has_prefix("#") ||
      trimmed.has_prefix("|") ||
      trimmed.has_prefix("```") {
      continue
    }
    builder.write_string(trimmed)
    builder.write_string(" ")
  }
  builder.to_string().trim().to_string()
}

///|
fn register_town_synthesis_execution(
  state : @core.TownState,
  goal : String,
  plan : @roles.MayorGoalPlan,
  path : String,
) -> Unit {
  register_town_book_if_missing(state)
  let task_id = town_synthesis_task_id(goal)
  state.replace_task(
    @core.TownTask::new(
      id=task_id,
      book_id="town",
      title="Mayor town-level synthesis",
      prompt="Combine \{plan.lanes.length()} isolated research lanes into one town-level synthesis and expose readiness gaps.",
      domain=@core.WorkDomain::Research,
      required_role=Some(@core.WorkerRole::Planner),
      required_capabilities=["synthesis", "supervision", "quality-gate"],
      status=town_synthesis_task_status(state, plan),
    ),
  )
  let status = town_synthesis_execution_status(state, plan)
  state.replace_execution(
    @core.TaskExecutionRecord::new(
      task_id~,
      book_id="town",
      packet_id="mayor-town-synthesis-\{town_goal_slug(goal)}",
      packet_path=path,
      status~,
      summary=town_synthesis_execution_summary(state, plan, path),
      output_contract="mayor.town_synthesis.v1",
      context_pages=plan.lanes.map(fn(lane) { lane.entry.id }),
      skill_paths=[],
      last_command=Some(path),
      assigned_worker_id=None,
      requires_review=false,
      notify_town=true,
    ),
  )
}

///|
fn town_synthesis_execution_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> @core.TaskExecutionStatus {
  if town_synthesis_ready(state, plan) {
    @core.TaskExecutionStatus::Completed
  } else {
    @core.TaskExecutionStatus::ReviewQueued
  }
}

///|
fn town_synthesis_task_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> @core.TownTaskStatus {
  if town_synthesis_ready(state, plan) {
    @core.TownTaskStatus::Done
  } else {
    @core.TownTaskStatus::Blocked
  }
}

///|
fn town_synthesis_ready(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> Bool {
  for lane in plan.lanes {
    if lane_research_status(state, lane.entry.id) != "complete" {
      return false
    }
  }
  true
}

///|
fn town_synthesis_execution_summary(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
  path : String,
) -> String {
  if town_synthesis_ready(state, plan) {
    "Mayor synthesized \{plan.lanes.length()} research lanes into \{path}."
  } else {
    "Mayor wrote an interim town synthesis at \{path}, but lane work is not ready for final acceptance."
  }
}

///|
fn register_town_book_if_missing(state : @core.TownState) -> Unit {
  for book in state.books {
    if book.id == "town" {
      return
    }
  }
  state.register_book(
    @core.BookRef::new(
      id="town",
      name="Moontown / Mayor",
      purpose="Shared town-level synthesis, supervision, and cross-book readiness.",
      workspace_root=".moontown",
      memory_scope=@core.MemoryScope::SharedTown,
      tags=["town", "mayor", "synthesis"],
    ),
  )
}

///|
fn town_synthesis_decision(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
) -> String {
  if count_lanes_by_status(state, plan, "running") > 0 {
    return "The mayor should keep supervising because at least one lane is still running.\n"
  }
  if count_lanes_by_status(state, plan, "failed") > 0 {
    return "The mayor should retry or escalate failed lanes before accepting the research goal as complete.\n"
  }
  if count_lanes_by_status(state, plan, "review queued") > 0 {
    return "The mayor should keep the goal in review because one or more lanes have quality-gate or pending-review blockers.\n"
  }
  "The mayor can treat the town goal as complete and use this artifact as the cross-lane synthesis entry point.\n"
}

///|
fn count_lanes_by_status(
  state : @core.TownState,
  plan : @roles.MayorGoalPlan,
  status : String,
) -> Int {
  let mut count = 0
  for lane in plan.lanes {
    if lane_research_status(state, lane.entry.id) == status {
      count += 1
    }
  }
  count
}

///|
fn lane_research_status(state : @core.TownState, book_id : String) -> String {
  let mut saw_running = false
  let mut saw_review = false
  let mut saw_failed = false
  let mut saw_completed = false
  for execution in state.executions {
    if execution.book_id != book_id {
      continue
    }
    match execution.status {
      @core.TaskExecutionStatus::Completed => saw_completed = true
      @core.TaskExecutionStatus::ReviewQueued => saw_review = true
      @core.TaskExecutionStatus::Failed | @core.TaskExecutionStatus::Stale =>
        saw_failed = true
      @core.TaskExecutionStatus::ProposalImported
      | @core.TaskExecutionStatus::RunConfirmed
      | @core.TaskExecutionStatus::Running
      | @core.TaskExecutionStatus::AwaitingPersistence => saw_running = true
      _ => ()
    }
  }
  if saw_running {
    "running"
  } else if saw_failed {
    "failed"
  } else if saw_review {
    "review queued"
  } else if saw_completed {
    "complete"
  } else {
    "planned"
  }
}

///|
fn markdown_excerpt(text : String, limit : Int) -> String {
  let trimmed = text.trim()
  if trimmed.length() <= limit {
    return trimmed.to_string()
  }
  let builder = StringBuilder::new()
  let mut emitted = 0
  for char in trimmed {
    if emitted >= limit {
      break
    }
    builder.write_char(char)
    emitted += 1
  }
  "\{builder.to_string()}\n\n..."
}

///|
fn town_synthesis_dir(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/town-synthesis"
  } else {
    "\{base}/town-synthesis"
  }
}

///|
fn town_synthesis_task_id(goal : String) -> String {
  "town-synthesis-\{town_goal_slug(goal)}"
}

///|
fn town_goal_slug(goal : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  let mut emitted = 0
  for char in goal.to_lower() {
    if emitted >= 72 {
      break
    }
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
      emitted += 1
    } else if !last_dash && emitted > 0 {
      builder.write_char('-')
      last_dash = true
      emitted += 1
    }
  }
  let slug = builder.to_string().trim(chars="-").to_string()
  if slug.is_empty() {
    "goal"
  } else {
    slug
  }
}
