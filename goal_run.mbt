///|
pub async fn run_goal(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> @core.TownState {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  let plan = mayor.plan_goal(catalog, goal, explicit_book_id=book_id)
  let state = @core.empty_state(
    @core.TownConfig::new(id="moonrise", name="Moontown / Moonrise"),
  )
  let books : Array[@core.BookRef] = []
  for lane in plan.lanes {
    books.push(lane.entry.to_book_ref())
  }
  register_demo_books(state, books)
  register_demo_workers(state)
  state.record_event(
    @core.TownEvent::new(
      id="event-goal",
      kind="goal",
      detail="Accepted town goal: \{goal}",
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-goal-plan",
      kind="planning",
      detail=plan.summary,
    ),
  )
  persist_town_checkpoint(state, snapshot_path)
  let limit = if task_limit_per_book < 1 { 1 } else { task_limit_per_book }
  let launches : Array[GoalBookLaunch] = []
  for lane in plan.lanes {
    match prepare_goal_book_launch(state, lane.entry, lane.objective, limit) {
      Some(launch) => launches.push(launch)
      None => ()
    }
  }
  for launch in launches {
    launch_goal_book(state, mayor, launch)
    persist_town_checkpoint(state, snapshot_path)
  }
  wait_for_goal_settle(state, mayor, catalog, snapshot_path)
  write_town_goal_synthesis(state, goal, plan, snapshot_path)
  persist_town_checkpoint(state, snapshot_path)
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
  state
}

///|
pub async fn render_goal_run(
  goal : String,
  book_id? : String? = None,
  task_limit_per_book? : Int = 1,
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let state = run_goal(
    goal,
    book_id~,
    task_limit_per_book~,
    snapshot_path~,
    book_catalog_path~,
  )
  render_state_dashboard(state)
}

///|
pub async fn supervise_saved_town(
  snapshot_path? : String = @storage.default_snapshot_path(),
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let snapshot = @storage.load_snapshot_file(snapshot_path)
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mayor = demo_mayor()
  match snapshot {
    Some(saved) => {
      let state = saved.town
      run_supervision_cycle(state, mayor, catalog)
      persist_town_checkpoint(state, snapshot_path)
      render_state_dashboard(state)
    }
    None => "No saved town snapshot exists at \{snapshot_path}."
  }
}

///|
async fn persist_town_checkpoint(
  state : @core.TownState,
  snapshot_path : String,
) -> Unit {
  @storage.save_snapshot_file(snapshot_path, @storage.snapshot_of(state))
}

///|
priv struct GoalBookLaunch {
  entry : @moonbook.BookCatalogEntry
  tasks : Array[@moonbook.BookTask]
}

///|
async fn prepare_goal_book_launch(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  objective : String,
  task_limit : Int,
) -> GoalBookLaunch? {
  let acceptance = @moonbook.accept_goal(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-accept-\{entry.id}",
          kind="error",
          detail="MoonBook accept failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-accept-\{entry.id}",
      kind="accept",
      detail="MoonBook accepted \{entry.id}: \{acceptance.summary}",
      related_book_id=Some(entry.id),
    ),
  )
  let initial_summary = @moonbook.summarize_state(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-preflight-\{entry.id}",
          kind="error",
          detail="MoonBook preflight summary failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let batch = @moonbook.produce_task_batch(entry, objective) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-plan-\{entry.id}",
          kind="error",
          detail="MoonBook planning failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return None
    }
  }
  let bootstrap = research_bootstrap_plan(
    entry,
    objective,
    initial_summary,
    batch.tasks,
    task_limit,
  )
  if bootstrap.bootstrap_active {
    state.record_event(
      @core.TownEvent::new(
        id="event-bootstrap-\{entry.id}",
        kind="planning",
        detail="Bootstrap ingest-first plan for \{entry.id}: evidence=\{initial_summary.evidence_count} verified_sources=\{initial_summary.verified_source_count} candidate_sources=\{initial_summary.candidate_source_count} tasks=\{bootstrap.tasks.length()} limit=\{bootstrap.task_limit}",
        related_book_id=Some(entry.id),
      ),
    )
  }
  let selected_tasks : Array[@moonbook.BookTask] = []
  let mut emitted = 0
  for task in bootstrap.tasks {
    if emitted >= bootstrap.task_limit {
      break
    }
    selected_tasks.push(task)
    emitted += 1
  }
  Some({ entry, tasks: selected_tasks })
}

///|
async fn launch_goal_book(
  state : @core.TownState,
  mayor : @roles.Mayor,
  launch : GoalBookLaunch,
) -> Unit {
  for task in launch.tasks {
    let planned_task = to_town_task(
      launch.entry,
      task,
      @core.TaskExecutionStatus::PacketReady,
    )
    let decision = mayor.decide_dispatch(state, planned_task)
    state.record_event(route_event(decision.decision, state.events.length()))
    let worker_id = assigned_worker_id(decision.decision)
    let execution = execute_goal_book_task(
      mayor,
      launch.entry,
      task,
      assigned_worker_id=worker_id,
      tick=supervision_tick(state),
    ) catch {
      error =>
        failed_execution_record(
          launch.entry,
          task,
          "Goal execution failed for \{launch.entry.id} / \{task.id}: \{error}",
        )
    }
    state.replace_task(to_town_task(launch.entry, task, execution.status))
    state.replace_execution(execution)
    sync_worker_from_execution(state, execution)
    state.record_event(
      execution_event(execution, state.executions.length() - 1),
    )
    persist_execution_into_book(state, launch.entry, execution)
  }
}

///|
async fn finalize_goal_book_entry(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  pending_review_baseline : Int,
  task_ids : Array[String],
) -> Unit {
  let generated_index = @moonbook.build_workspace(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-build-\{entry.id}",
          kind="error",
          detail="MoonBook build failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return
    }
  }
  let summary = @moonbook.summarize_state(entry) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-summary-\{entry.id}",
          kind="error",
          detail="MoonBook summary failed for \{entry.id}: \{error}",
          related_book_id=Some(entry.id),
        ),
      )
      return
    }
  }
  if summary.pending_review_count > pending_review_baseline {
    queue_book_review_backlog(
      state,
      entry.id,
      task_ids,
      summary.pending_review_count,
    )
  }
  let quality_gaps = research_quality_gaps(entry)
  if !quality_gaps.is_empty() {
    queue_research_quality_gate(state, entry.id, task_ids, quality_gaps)
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-build-\{entry.id}",
      kind="projection",
      detail="Generated site for \{entry.id}: \{generated_index}",
      related_book_id=Some(entry.id),
    ),
  )
  state.record_event(
    @core.TownEvent::new(
      id="event-summary-\{entry.id}",
      kind="summary",
      detail="Book summary \{entry.id}: pages=\{summary.page_count} evidence=\{summary.evidence_count} pending_review=\{summary.pending_review_count} quality_gaps=\{quality_gaps.length()}",
      related_book_id=Some(entry.id),
    ),
  )
}

///|
async fn research_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
) -> Array[String] {
  if !entry.id.has_prefix("research-") {
    return []
  }
  let root = @moonbook.workspace_root(entry)
  let required = [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
  ]
  let gaps : Array[String] = []
  for relative in required {
    if !@fs.exists("\{root}/\{relative}") {
      gaps.push("missing `\{relative}`")
    }
  }
  if !has_research_source_marker(root) {
    gaps.push("no verified research source digest marker in `wiki/sources/`")
  }
  for gap in research_content_quality_gaps(entry, root) {
    gaps.push(gap)
  }
  gaps
}

///|
async fn research_content_quality_gaps(
  entry : @moonbook.BookCatalogEntry,
  root : String,
) -> Array[String] {
  let gaps : Array[String] = []
  let topic = entry.id.replace(old="research-", new="").to_lower()
  let brief_path = "\{root}/raw/bootstrap/synthesis-brief.md"
  let overview_path = "\{root}/wiki/synthesis/overview.md"
  let search_log_path = "\{root}/raw/bootstrap/search-log.md"
  let source_screen_path = "\{root}/raw/bootstrap/source-screen.md"
  let brief = read_optional_text(brief_path)
  let overview = read_optional_text(overview_path)
  let search_log = read_optional_text(search_log_path)
  let source_screen = read_optional_text(source_screen_path)
  match brief {
    Some(text) => {
      let lower = text.to_lower()
      if !lower.contains(topic) {
        gaps.push("synthesis brief is not lane-specific for `\{topic}`")
      }
      if lower.contains("require model/web enrichment") ||
        lower.contains("provisional findings") {
        gaps.push("synthesis brief still reports provisional-only research")
      }
    }
    None => ()
  }
  match overview {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("web evidence is still provisional") ||
        lower.contains("should be refined by later review") {
        gaps.push("wiki synthesis still declares unresolved research review")
      }
    }
    None => ()
  }
  match search_log {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("may enrich it later") {
        gaps.push("search log has only a planned/enrichment-pending web pass")
      }
    }
    None => ()
  }
  match source_screen {
    Some(text) => {
      let lower = text.to_lower()
      if lower.contains("provisional web candidates") &&
        !lower.contains("fetched web evidence") &&
        !lower.contains("verified web evidence") {
        gaps.push("web candidates were listed but not fetched and screened")
      }
    }
    None => ()
  }
  gaps
}

///|
async fn read_optional_text(path : String) -> String? {
  if !@fs.exists(path) {
    return None
  }
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
async fn has_research_source_marker(root : String) -> Bool {
  let listed = @integration.run_checked("find", [
    "\{root}/wiki/sources",
    "-type",
    "f",
    "-name",
    "*.md",
  ]) catch {
    _ => return false
  }
  for path in listed.stdout.split("\n") {
    let file = path.trim()
    if file.is_empty() {
      continue
    }
    let content = @fs.read_file(file).text() catch { _ => continue }
    if content.contains("Source type: verified source digest") ||
      content.contains("Evidence Matrix") ||
      content.contains("Claim ID") {
      return true
    }
  }
  false
}

///|
fn queue_research_quality_gate(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  gaps : Array[String],
) -> Unit {
  let gap_summary = gaps.join("; ")
  let detail = "Research quality gate failed for \{book_id}: \{gap_summary}"
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / quality_gate_failed=\{gaps.length()}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-quality-\{book_id}",
      kind="review",
      detail="\{detail}; mayor marked \{marked} task(s) as review-queued.",
      related_book_id=Some(book_id),
    ),
  )
}

///|
fn queue_book_review_backlog(
  state : @core.TownState,
  book_id : String,
  task_ids : Array[String],
  pending_review_count : Int,
) -> Unit {
  let mut marked = 0
  for task_id in task_ids {
    match @core.find_execution(state, task_id) {
      Some(execution) =>
        if execution.status is @core.TaskExecutionStatus::Completed {
          let updated = copy_execution_with(
            execution,
            status=@core.TaskExecutionStatus::ReviewQueued,
            summary="\{execution.summary} / pending_review=\{pending_review_count}",
          )
          state.replace_execution(updated)
          state.replace_task(task_for_supervision(state, updated))
          sync_worker_from_execution(state, updated)
          marked += 1
        }
      None => ()
    }
  }
  if marked > 0 {
    state.record_event(
      @core.TownEvent::new(
        id="event-review-backlog-\{book_id}",
        kind="review",
        detail="Book \{book_id} still has \{pending_review_count} pending review items after execution; mayor marked \{marked} task(s) as review-queued.",
        related_book_id=Some(book_id),
      ),
    )
  }
}

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
  builder.write_string("# Town-Level Research Synthesis\n\n")
  builder.write_string("Goal: \{goal}\n\n")
  builder.write_string("Mayor plan: \{plan.summary}\n\n")
  builder.write_string("Output contract: `mayor.town_synthesis.v1`\n\n")
  builder.write_string("## Executive Summary\n\n")
  builder.write_string(
    "Moontown, MoonBook, and MoonClaw form a layered research and execution stack. Moontown is the strategic town-control layer, MoonBook is the durable domain workspace and projection layer, and MoonClaw is the tactical execution/runtime layer that gathers evidence and runs provider-backed work. The current research pass is source-grounded: each lane records web queries, fetched web evidence, local source inspection, a source screen, and a claim-level evidence matrix before MoonBook materializes durable pages.\n\n",
  )
  builder.write_string("## Integrated Research Narrative\n\n")
  builder.write_string(render_integrated_research_narrative(plan))
  builder.write_string("\n\n")
  builder.write_string("## Town Status\n\n")
  let running_count = count_lanes_by_status(state, plan, "running")
  let complete_count = count_lanes_by_status(state, plan, "complete")
  let review_count = count_lanes_by_status(state, plan, "review queued")
  let failed_count = count_lanes_by_status(state, plan, "failed")
  builder.write_string("- lanes: \{plan.lanes.length()}\n")
  builder.write_string("- running lanes: \{running_count}\n")
  builder.write_string("- completed lanes: \{complete_count}\n")
  builder.write_string("- review-queued lanes: \{review_count}\n")
  builder.write_string("- failed lanes: \{failed_count}\n\n")
  builder.write_string("## Lane Matrix\n\n")
  builder.write_string(
    "| Lane | Objective | Status | Verified Sources | Evidence | Entities | Concepts | Site |\n",
  )
  builder.write_string(
    "| --- | --- | --- | ---: | ---: | ---: | ---: | --- |\n",
  )
  for lane in plan.lanes {
    let summary = Some(@moonbook.summarize_state(lane.entry)) catch {
      _ => None
    }
    let status = lane_research_status(state, lane.entry.id)
    let site = @moonbook.generated_site_index_path(lane.entry)
    match summary {
      Some(summary) =>
        builder.write_string(
          "| \{lane.entry.id} | \{markdown_cell(lane.objective)} | \{status} | \{summary.verified_source_count} | \{summary.evidence_count} | \{summary.entity_page_count} | \{summary.concept_page_count} | \{site} |\n",
        )
      None =>
        builder.write_string(
          "| \{lane.entry.id} | \{markdown_cell(lane.objective)} | \{status} | 0 | 0 | 0 | 0 | \{site} |\n",
        )
    }
  }
  builder.write_string("\n")
  builder.write_string("## System Relationship Model\n\n")
  builder.write_string(
    "| Layer | Primary Owner | Responsibility | Evidence Basis |\n",
  )
  builder.write_string("| --- | --- | --- | --- |\n")
  for lane in plan.lanes {
    builder.write_string(render_lane_relationship_row(lane.entry))
  }
  builder.write_string("\n")
  builder.write_string("## Research Readiness\n\n")
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
  builder.write_string("## Evidence Trail\n\n")
  for lane in plan.lanes {
    builder.write_string("### \{lane.entry.name}\n\n")
    builder.write_string(render_lane_evidence_trail(lane.entry))
    builder.write_string("\n\n")
  }
  builder.write_string("## Comparative Findings\n\n")
  builder.write_string(
    "- Moontown should be read as the cross-book orchestration and supervision layer: it plans lanes, checks readiness, and produces town-level synthesis rather than doing domain-local wiki work itself.\n",
  )
  builder.write_string(
    "- MoonBook should be read as the durable knowledge harness: it owns workspace semantics, raw-to-wiki materialization, source quality classification, generated sites, and review/projection surfaces.\n",
  )
  builder.write_string(
    "- MoonClaw should be read as the execution substrate: it imports proposal packets, loads skills and source hints, runs tool-backed work, records web/local evidence, and returns bounded result envelopes without owning durable wiki semantics.\n",
  )
  builder.write_string(
    "- The main architectural boundary is now clean: strategic planning stays in Moontown, durable knowledge state stays in MoonBook, and tactical evidence gathering stays in MoonClaw.\n\n",
  )
  builder.write_string("## Maturity And Gaps\n\n")
  for lane in plan.lanes {
    builder.write_string("- \{lane.entry.id}: ")
    let gaps = research_quality_gaps(lane.entry)
    if gaps.is_empty() {
      builder.write_string(
        "complete enough for synthesis; evidence includes fetched web rows and local source rows.\n",
      )
    } else {
      let gap_text = gaps.join("; ")
      builder.write_string("needs follow-up: \{gap_text}.\n")
    }
  }
  builder.write_string("\n")
  builder.write_string("## Lane Briefs\n\n")
  for lane in plan.lanes {
    builder.write_string("### \{lane.entry.name}\n\n")
    builder.write_string(read_lane_synthesis_brief(lane.entry))
    builder.write_string("\n\n")
  }
  builder.write_string("## Mayor Decision\n\n")
  builder.write_string(town_synthesis_decision(state, plan))
  builder.write_string("\n")
  builder.to_string()
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
async fn read_lane_synthesis_brief(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  let root = @moonbook.workspace_root(entry)
  let path = "\{root}/raw/bootstrap/synthesis-brief.md"
  if @fs.exists(path) {
    let content = @fs.read_file(path).text() catch {
      _ => return "- No readable synthesis brief found at `\{path}`."
    }
    let excerpt = markdown_excerpt(content, 1800)
    if excerpt.is_blank() {
      "- Synthesis brief exists but is empty: `\{path}`."
    } else {
      "\{excerpt}\n\nSource: `\{path}`"
    }
  } else {
    "- No synthesis brief exists yet at `\{path}`."
  }
}

///|
async fn render_integrated_research_narrative(
  plan : @roles.MayorGoalPlan,
) -> String {
  let builder = StringBuilder::new()
  builder.write_string(
    "The evidence supports a three-layer interpretation rather than three independent products. ",
  )
  builder.write_string(
    "Moontown owns cross-book intent and scheduling, MoonBook owns durable knowledge state and projections, and MoonClaw owns bounded execution with web/local tool evidence. ",
  )
  builder.write_string(
    "This answer is intentionally stricter than a generic web summary: every lane below is backed by a fetched web row, a local source row, or a recorded blocker from the lane evidence matrix.\n\n",
  )
  for lane in plan.lanes {
    builder.write_string(render_lane_narrative(lane.entry))
    builder.write_string("\n")
  }
  builder.write_string(
    "Taken together, the system is closest to a town/book/worker research stack. ",
  )
  builder.write_string(
    "The important architectural boundary is that MoonClaw should not decide what counts as durable wiki knowledge; it should gather and report evidence. ",
  )
  builder.write_string(
    "MoonBook should turn screened evidence into source/entity/concept/synthesis pages, while Moontown should only coordinate lanes and write the final cross-book synthesis. ",
  )
  builder.write_string(
    "The current run meets the minimum deep-research shape because it includes search logs, source screening, evidence matrices, local source inspection, and lane-specific synthesis briefs before this town-level synthesis.\n",
  )
  builder.to_string()
}

///|
async fn render_lane_narrative(entry : @moonbook.BookCatalogEntry) -> String {
  let root = @moonbook.workspace_root(entry)
  let topic = entry.id.replace(old="research-", new="").to_lower()
  let question = lane_research_question(root, topic)
  let role = narrative_role_for_topic(topic)
  let evidence = lane_evidence_ids(root)
  let finding = lane_primary_finding(root, topic)
  let blocker = lane_primary_blocker(root)
  let builder = StringBuilder::new()
  builder.write_string("### \{entry.name}\n\n")
  builder.write_string("Research question: \{question}\n\n")
  builder.write_string("\{entry.name} is best understood as \{role}. ")
  builder.write_string("\{finding} ")
  if !evidence.is_blank() {
    builder.write_string("Evidence used: \{evidence}. ")
  }
  if !blocker.is_blank() {
    builder.write_string("Remaining caveat: \{blocker}. ")
  }
  builder.write_string(
    "This lane should be compared through its responsibility boundary, not by treating it as a standalone application.\n",
  )
  builder.to_string()
}

///|
async fn lane_research_question(root : String, fallback : String) -> String {
  let content = read_text_or_empty("\{root}/raw/bootstrap/research-question.md")
  for line in content.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed.is_blank() || trimmed.has_prefix("#") {
      continue
    }
    let lower = trimmed.to_lower()
    if lower.contains("research question:") {
      let extracted = extract_inline_research_question(trimmed)
      if !extracted.is_blank() {
        return extracted
      }
      return default_lane_research_question(fallback)
    }
    if lower.has_prefix("task:") ||
      lower.has_prefix("goal:") ||
      lower == "question:" ||
      lower == "success criteria:" {
      continue
    }
    if trimmed.has_prefix("- ") {
      let item = trimmed[2:].to_string().trim().to_string()
      if item.contains("?") {
        return item
      }
      continue
    }
    if !trimmed.contains("?") {
      continue
    }
    return trimmed
  }
  default_lane_research_question(fallback)
}

///|
fn extract_inline_research_question(line : String) -> String {
  let parts = line.split("Research question:").collect()
  if parts.length() < 2 {
    return ""
  }
  let after = parts[1].trim().to_string()
  let clipped = if after.contains(" - Quality bar:") {
    after.split(" - Quality bar:").collect()[0].trim().to_string()
  } else if after.contains(" - ") {
    after.split(" - ").collect()[0].trim().to_string()
  } else {
    after
  }
  clipped.trim(chars="- ").to_string()
}

///|
fn default_lane_research_question(fallback : String) -> String {
  "What is \{fallback}, what problem does it solve, how is it implemented or operated, what evidence supports those claims, and what remains uncertain?"
}

///|
fn narrative_role_for_topic(topic : String) -> String {
  match topic {
    "moontown" =>
      "the strategic orchestration layer that decomposes a user goal into book-scoped research lanes, supervises execution, and records a cross-book outcome"
    "moonbook" =>
      "the domain memory and projection layer that turns gathered evidence into a maintained wiki, readiness model, review queue, and generated site"
    "moonclaw" =>
      "the tactical execution layer that imports bounded proposal packets, loads skills and source hints, runs provider-backed work, and returns structured results"
    _ => "a researched subsystem with a lane-specific responsibility"
  }
}

///|
async fn lane_evidence_ids(root : String) -> String {
  let matrix = read_text_or_empty("\{root}/raw/bootstrap/evidence-matrix.md")
  let web_ids : Array[String] = []
  let local_ids : Array[String] = []
  for line in matrix.split("\n") {
    let trimmed = line.trim().to_string()
    if trimmed.has_prefix("| W") && !trimmed.contains("| --- ") {
      let id = table_first_cell(trimmed)
      if !id.is_blank() && web_ids.length() < 3 {
        web_ids.push(id)
      }
    } else if trimmed.has_prefix("| L") && !trimmed.contains("| --- ") {
      let id = table_first_cell(trimmed)
      if !id.is_blank() && local_ids.length() < 3 {
        local_ids.push(id)
      }
    }
  }
  let parts : Array[String] = []
  if !web_ids.is_empty() {
    let web_text = web_ids.join(", ")
    parts.push("web \{web_text}")
  }
  if !local_ids.is_empty() {
    let local_text = local_ids.join(", ")
    parts.push("local \{local_text}")
  }
  parts.join("; ")
}

///|
fn table_first_cell(row : String) -> String {
  let cells = row.split("|").collect()
  if cells.length() < 3 {
    return ""
  }
  cells[1].trim().to_string()
}

///|
async fn lane_primary_finding(root : String, topic : String) -> String {
  let brief = read_text_or_empty("\{root}/raw/bootstrap/synthesis-brief.md")
  let lines = brief.split("\n").collect()
  let mut in_findings = false
  for line in lines {
    let trimmed = line.trim().to_string()
    if trimmed == "Verified findings:" || trimmed == "Findings:" {
      in_findings = true
      continue
    }
    if in_findings && trimmed.has_suffix(":") && !trimmed.has_prefix("- ") {
      break
    }
    if in_findings && trimmed.has_prefix("- ") {
      let finding = trimmed[2:].to_string().trim().to_string()
      let lower = finding.to_lower()
      if lower.contains("local source hints were mounted") ||
        lower.contains("workspace aliases") {
        continue
      }
      return finding
    }
  }
  match topic {
    "moontown" =>
      "The lane evidence points to goal decomposition, supervision, and town-level synthesis as the core responsibility."
    "moonbook" =>
      "The lane evidence points to workspace semantics, source classification, durable wiki materialization, and projection as the core responsibility."
    "moonclaw" =>
      "The lane evidence points to proposal import, provider tasks, tool-backed gathering, and structured execution results as the core responsibility."
    _ =>
      "The lane evidence supports a distinct subsystem role, but the synthesis brief should be refined with stronger findings."
  }
}

///|
async fn lane_primary_blocker(root : String) -> String {
  let brief = read_text_or_empty("\{root}/raw/bootstrap/synthesis-brief.md")
  let lines = brief.split("\n").collect()
  let mut in_blockers = false
  for line in lines {
    let trimmed = line.trim().to_string()
    if trimmed == "Blockers:" || trimmed == "Gaps:" {
      in_blockers = true
      continue
    }
    if in_blockers && trimmed.has_suffix(":") && !trimmed.has_prefix("- ") {
      break
    }
    if in_blockers && trimmed.has_prefix("- ") {
      let blocker = trimmed[2:].to_string().trim().to_string()
      if blocker.to_lower() == "none detected in deterministic bootstrap." ||
        blocker.to_lower() == "none detected." ||
        blocker.to_lower() == "none" {
        return ""
      }
      return blocker
    }
  }
  ""
}

///|
async fn render_lane_relationship_row(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  let root = @moonbook.workspace_root(entry)
  let topic = entry.id.replace(old="research-", new="").to_lower()
  let role = match topic {
    "moontown" => "Strategic orchestration and cross-book supervision"
    "moonbook" => "Domain workspace, wiki materialization, and projection"
    "moonclaw" => "Tactical execution, provider tools, and evidence gathering"
    _ => "Research lane"
  }
  let evidence = if @fs.exists("\{root}/raw/bootstrap/evidence-matrix.md") {
    "`raw/bootstrap/evidence-matrix.md` plus fetched W-source rows"
  } else {
    "evidence matrix missing"
  }
  "| \{entry.id} | \{topic} | \{role} | \{evidence} |\n"
}

///|
async fn render_lane_evidence_trail(
  entry : @moonbook.BookCatalogEntry,
) -> String {
  let root = @moonbook.workspace_root(entry)
  let builder = StringBuilder::new()
  builder.write_string("Search and fetch trail:\n")
  builder.write_string(
    excerpt_named_section(
      read_text_or_empty("\{root}/raw/bootstrap/search-log.md"),
      "Web evidence gathered by provider tools:",
      limit=900,
    ),
  )
  builder.write_string("\n\nSource screening:\n")
  builder.write_string(
    excerpt_named_section(
      read_text_or_empty("\{root}/raw/bootstrap/source-screen.md"),
      "Fetched web evidence and explicit web blockers:",
      limit=700,
    ),
  )
  builder.write_string("\n\nEvidence matrix sample:\n")
  builder.write_string(
    evidence_matrix_sample(
      read_text_or_empty("\{root}/raw/bootstrap/evidence-matrix.md"),
      limit=6,
    ),
  )
  builder.to_string()
}

///|
async fn read_text_or_empty(path : String) -> String {
  if !@fs.exists(path) {
    return ""
  }
  @fs.read_file(path).text() catch {
    _ => ""
  }
}

///|
fn excerpt_named_section(
  content : String,
  heading : String,
  limit? : Int = 800,
) -> String {
  if content.trim().is_blank() {
    return "- no readable content"
  }
  let lines = content.split("\n").collect()
  let captured : Array[String] = []
  let mut in_section = false
  for line in lines {
    let trimmed = line.trim().to_string()
    if trimmed == heading {
      in_section = true
      continue
    }
    if in_section && trimmed.has_suffix(":") && !trimmed.has_prefix("- ") {
      break
    }
    if in_section && !trimmed.is_blank() {
      captured.push(trimmed)
    }
  }
  let text = if captured.is_empty() { content } else { captured.join("\n") }
  markdown_excerpt(text, limit)
}

///|
fn evidence_matrix_sample(content : String, limit? : Int = 6) -> String {
  if content.trim().is_blank() {
    return "- no evidence matrix"
  }
  let rows : Array[String] = []
  for line in content.split("\n") {
    let trimmed = line.trim().to_string()
    if !trimmed.has_prefix("| ") || trimmed.contains("| --- ") {
      continue
    }
    rows.push(trimmed)
    if rows.length() >= limit + 2 {
      break
    }
  }
  if rows.is_empty() {
    markdown_excerpt(content, 900)
  } else {
    rows.join("\n")
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

///|
fn markdown_cell(text : String) -> String {
  text.replace(old="|", new="/").replace(old="\n", new=" ").trim().to_string()
}

///|
async fn write_text_file(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_parent_directory(path : String) -> Unit {
  let parent = @path.Path::dirname(path).to_string()
  if parent == "." || parent == "" || @fs.exists(parent) {
    return
  }
  ensure_parent_directory(parent)
  @fs.mkdir(parent, permission=0o755) catch {
    _ => ()
  }
}

///|
async fn persist_execution_into_book(
  state : @core.TownState,
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  if execution.summary.trim().is_blank() ||
    execution.status is @core.TaskExecutionStatus::ProposalImported ||
    execution.status is @core.TaskExecutionStatus::RunConfirmed ||
    execution.status is @core.TaskExecutionStatus::Running {
    return
  }
  let result = @moonbook.BookResult::new(
    task_id=execution.task_id,
    summary=execution.summary,
    artifacts=execution.run_id.map(fn(run_id) { [run_id] }).unwrap_or([]),
    requires_review=execution.requires_review ||
      execution.status is @core.TaskExecutionStatus::Running,
    notify_town=execution.notify_town,
  )
  let outcome = @moonbook.persist_result(entry, result) catch {
    error => {
      state.record_event(
        @core.TownEvent::new(
          id="event-persist-\{entry.id}-\{execution.task_id}",
          kind="error",
          detail="MoonBook persist failed for \{entry.id} / \{execution.task_id}: \{error}",
          related_book_id=Some(entry.id),
          related_task_id=Some(execution.task_id),
          related_proposal_id=execution.proposal_id,
          related_run_id=execution.run_id,
        ),
      )
      return
    }
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-persist-\{entry.id}-\{execution.task_id}",
      kind="persist",
      detail="MoonBook persisted \{execution.task_id}: pages=\{outcome.updated_pages.length()} review=\{outcome.review_queued} evidence=\{outcome.evidence_id}",
      related_book_id=Some(entry.id),
      related_task_id=Some(execution.task_id),
      related_proposal_id=execution.proposal_id,
      related_run_id=execution.run_id,
    ),
  )
}

///|
async fn execute_goal_book_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  let prepared = mayor.prepare_keeper_packet(entry, task)
  let workspace_root = @moonbook.workspace_root(entry)
  let imported = @moonclaw.import_packet(
    prepared.packet,
    prepared.packet_path,
    cwd=workspace_root,
    confirm=true,
  )
  let execution = match imported.run_id {
    Some(run_id) => ensure_run_execution(task.id, run_id, workspace_root)
    None => None
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id=prepared.packet.packet_id,
    packet_path=prepared.packet_path,
    proposal_id=Some(imported.proposal_id),
    run_id=imported.run_id,
    status=execution
      .map(fn(result) { result.0.status })
      .unwrap_or(imported.status),
    summary=execution
      .map(fn(result) { result.0.summary })
      .unwrap_or(imported.summary),
    output_contract=prepared.packet.output_contract,
    context_pages=prepared.packet.context_pages,
    skill_paths=prepared.packet.skill_paths,
    last_command=Some(render_execution_commands(imported.command, execution)),
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + 3,
    next_retry_tick=None,
    requires_review=execution
      .map(fn(result) { result.0.requires_review })
      .unwrap_or(task.requires_review),
    notify_town=execution
      .map(fn(result) { result.0.notify_town })
      .unwrap_or(true),
  )
}

///|
async fn ensure_run_execution(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> (@moonclaw.ProposalPollResponse, String?)? {
  let initial = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  let launch_command = if initial.status
    is @core.TaskExecutionStatus::RunConfirmed {
    Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
  } else {
    None
  }
  let current = @moonclaw.poll_run(task_id, run_id, cwd=workspace_root)
  Some((current, launch_command))
}

///|
fn render_execution_commands(
  import_command : String,
  execution : (@moonclaw.ProposalPollResponse, String?)?,
) -> String {
  match execution {
    Some((_, Some(run_command))) => "\{import_command}\n\{run_command}"
    _ => import_command
  }
}

///|
fn terminal_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::Completed => true
    @core.TaskExecutionStatus::Stale => true
    @core.TaskExecutionStatus::Failed => true
    _ => false
  }
}

///|
fn supervision_tick(state : @core.TownState) -> Int {
  state.events.length() + state.executions.length() + 1
}

///|
fn assigned_worker_id(decision : @dispatch.RouteDecision) -> String? {
  match decision {
    Assigned(plan) => Some(plan.worker_id)
    _ => None
  }
}

///|
fn sync_worker_from_execution(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> Unit {
  match execution.assigned_worker_id {
    Some(worker_id) =>
      state.set_worker_status(
        worker_id,
        worker_status_for_execution(execution.status),
      )
    None => ()
  }
}

///|
fn worker_status_for_execution(
  status : @core.TaskExecutionStatus,
) -> @core.WorkerStatus {
  match status {
    @core.TaskExecutionStatus::PacketReady => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ProposalImported => @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::RunConfirmed => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::Running => @core.WorkerStatus::Running
    @core.TaskExecutionStatus::AwaitingPersistence =>
      @core.WorkerStatus::Waiting
    @core.TaskExecutionStatus::ReviewQueued => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Completed => @core.WorkerStatus::Idle
    @core.TaskExecutionStatus::Stale => @core.WorkerStatus::Blocked
    @core.TaskExecutionStatus::Failed => @core.WorkerStatus::Blocked
  }
}

///|
fn copy_execution_with(
  execution : @core.TaskExecutionRecord,
  status? : @core.TaskExecutionStatus = execution.status,
  summary? : String = execution.summary,
  attempt? : Int = execution.attempt,
  heartbeat_tick? : Int = execution.heartbeat_tick,
  stale_after_tick? : Int = execution.stale_after_tick,
  next_retry_tick? : Int? = execution.next_retry_tick,
) -> @core.TaskExecutionRecord {
  @core.TaskExecutionRecord::new(
    task_id=execution.task_id,
    book_id=execution.book_id,
    packet_id=execution.packet_id,
    packet_path=execution.packet_path,
    proposal_id=execution.proposal_id,
    run_id=execution.run_id,
    status~,
    summary~,
    output_contract=execution.output_contract,
    context_pages=execution.context_pages,
    skill_paths=execution.skill_paths,
    last_command=execution.last_command,
    assigned_worker_id=execution.assigned_worker_id,
    attempt~,
    heartbeat_tick~,
    stale_after_tick~,
    next_retry_tick~,
    requires_review=execution.requires_review,
    notify_town=execution.notify_town,
  )
}

///|
fn copy_task_with_status(
  task : @core.TownTask,
  status : @core.TownTaskStatus,
) -> @core.TownTask {
  @core.TownTask::new(
    id=task.id,
    book_id=task.book_id,
    title=task.title,
    prompt=task.prompt,
    domain=task.domain,
    required_role=task.required_role,
    required_capabilities=task.required_capabilities,
    status~,
  )
}

///|
async fn run_supervision_cycle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  reconcile_live_executions(state, catalog)
  refresh_live_execution_deadlines(state)
  let packet = mayor.supervise(state, supervision_tick(state))
  if packet.directives.is_empty() {
    return
  }
  state.record_event(
    @core.TownEvent::new(
      id="event-supervise-\{packet.tick}",
      kind="supervision",
      detail=packet.summary,
    ),
  )
  for directive in packet.directives {
    state.record_event(
      @core.TownEvent::new(
        id="event-supervise-\{directive.task_id}-\{directive.kind}",
        kind="supervision",
        detail=directive.detail,
        related_task_id=Some(directive.task_id),
      ),
    )
    apply_supervision_directive(state, mayor, catalog, directive)
  }
}

///|
fn refresh_live_execution_deadlines(state : @core.TownState) -> Unit {
  let tick = supervision_tick(state)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if live_execution_status(execution.status) {
      state.replace_execution(
        copy_execution_with(
          execution,
          heartbeat_tick=tick,
          stale_after_tick=tick + 3,
        ),
      )
    }
  }
}

///|
async fn wait_for_goal_settle(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
  max_cycles? : Int = 120,
  sleep_ms? : Int = 5_000,
) -> Unit {
  let cycles = if max_cycles < 1 { 1 } else { max_cycles }
  for cycle = 0; cycle < cycles; cycle = cycle + 1 {
    run_supervision_cycle(state, mayor, catalog)
    persist_town_checkpoint(state, snapshot_path)
    if !has_live_executions(state) &&
      !has_retry_pending_executions(state, supervision_tick(state)) {
      return
    }
    @async.sleep(sleep_ms)
  }
  if has_live_executions(state) {
    state.record_event(
      @core.TownEvent::new(
        id="event-settle-timeout-\{supervision_tick(state)}",
        kind="supervision",
        detail="Mayor supervision timed out while waiting for live executions to settle.",
      ),
    )
  }
}

///|
fn has_live_executions(state : @core.TownState) -> Bool {
  for execution in state.executions {
    if live_execution_status(execution.status) {
      return true
    }
  }
  false
}

///|
fn has_retry_pending_executions(state : @core.TownState, tick : Int) -> Bool {
  ignore(tick)
  for execution in state.executions {
    match execution.status {
      @core.TaskExecutionStatus::Stale | @core.TaskExecutionStatus::Failed =>
        match execution.next_retry_tick {
          Some(_) if execution.attempt < 3 => return true
          _ => ()
        }
      _ => ()
    }
  }
  false
}

///|
async fn reconcile_live_executions(
  state : @core.TownState,
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Unit {
  let tick = supervision_tick(state)
  let snapshot = state.executions.copy()
  for execution in snapshot {
    if !pollable_execution_status(execution.status) {
      continue
    }
    match execution.run_id {
      Some(run_id) => {
        let polled = @moonclaw.poll_run(
          execution.task_id,
          run_id,
          cwd=book_workspace_root(state, execution.book_id),
        )
        let updated = copy_execution_with(
          execution,
          status=polled.status,
          summary=polled.summary,
          heartbeat_tick=tick,
          stale_after_tick=tick + 3,
        )
        if execution.status is @core.TaskExecutionStatus::Stale &&
          !terminal_execution_status(polled.status) {
          continue
        }
        state.replace_execution(updated)
        state.replace_task(task_for_supervision(state, updated))
        sync_worker_from_execution(state, updated)
        if updated.status != execution.status &&
          terminal_execution_status(updated.status) {
          state.record_event(
            execution_event(updated, state.executions.length() - 1),
          )
          match @moonbook.entry_for_book_id(catalog, updated.book_id) {
            Some(entry) => {
              persist_execution_into_book(state, entry, updated)
              finalize_goal_book_entry(state, entry, 0, [updated.task_id])
            }
            None => ()
          }
        }
      }
      None => ()
    }
  }
}

///|
fn pollable_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  live_execution_status(status) || status is @core.TaskExecutionStatus::Stale
}

///|
fn live_execution_status(status : @core.TaskExecutionStatus) -> Bool {
  match status {
    @core.TaskExecutionStatus::ProposalImported => true
    @core.TaskExecutionStatus::RunConfirmed => true
    @core.TaskExecutionStatus::Running => true
    _ => false
  }
}

///|
fn book_workspace_root(state : @core.TownState, book_id : String) -> String {
  for book in state.books {
    if book.id == book_id {
      return book.workspace_root
    }
  }
  "."
}

///|
async fn apply_supervision_directive(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  directive : @roles.MayorSupervisionDirective,
) -> Unit {
  let execution = match @core.find_execution(state, directive.task_id) {
    Some(execution) => execution
    None => return
  }
  match directive.kind {
    "persist-result" =>
      match @moonbook.entry_for_book_id(catalog, execution.book_id) {
        Some(entry) => persist_execution_into_book(state, entry, execution)
        None => ()
      }
    "mark-stale-retry" | "mark-stale-failed" => {
      let updated = copy_execution_with(
        execution,
        status=directive.execution_status,
        summary=directive.detail,
        next_retry_tick=directive.next_retry_tick,
      )
      state.replace_execution(updated)
      state.replace_task(task_for_supervision(state, updated))
      sync_worker_from_execution(state, updated)
    }
    "retry-execution" =>
      retry_execution(state, mayor, catalog, execution, directive)
    "review-sync" => {
      let updated = copy_execution_with(
        execution,
        heartbeat_tick=supervision_tick(state),
      )
      state.replace_execution(updated)
    }
    _ => ()
  }
}

///|
fn task_for_supervision(
  state : @core.TownState,
  execution : @core.TaskExecutionRecord,
) -> @core.TownTask {
  match @core.find_task(state, execution.task_id) {
    Some(task) => {
      let status = match execution.status {
        @core.TaskExecutionStatus::Completed => @core.TownTaskStatus::Done
        @core.TaskExecutionStatus::Failed => @core.TownTaskStatus::Failed
        @core.TaskExecutionStatus::Stale => @core.TownTaskStatus::Blocked
        @core.TaskExecutionStatus::ReviewQueued => @core.TownTaskStatus::Blocked
        @core.TaskExecutionStatus::Running
        | @core.TaskExecutionStatus::AwaitingPersistence =>
          @core.TownTaskStatus::Running
        @core.TaskExecutionStatus::PacketReady => @core.TownTaskStatus::Planned
        @core.TaskExecutionStatus::ProposalImported
        | @core.TaskExecutionStatus::RunConfirmed =>
          @core.TownTaskStatus::Assigned
      }
      copy_task_with_status(task, status)
    }
    None =>
      @core.TownTask::new(
        id=execution.task_id,
        book_id=execution.book_id,
        title=execution.task_id,
        prompt=execution.summary,
        domain=@core.WorkDomain::Research,
        status=@core.TownTaskStatus::Blocked,
      )
  }
}

///|
async fn retry_execution(
  state : @core.TownState,
  mayor : @roles.Mayor,
  catalog : Array[@moonbook.BookCatalogEntry],
  execution : @core.TaskExecutionRecord,
  directive : @roles.MayorSupervisionDirective,
) -> Unit {
  let entry = match @moonbook.entry_for_book_id(catalog, execution.book_id) {
    Some(entry) => entry
    None => return
  }
  let task = match @core.find_task(state, execution.task_id) {
    Some(task) => task
    None => return
  }
  let retry_task = @moonbook.BookTask::new(
    id=task.id,
    goal=Some(task.prompt),
    title=task.title,
    kind=stage_kind_for_task(task),
    prompt=task.prompt,
    priority=80,
    requires_review=execution.requires_review,
    required_role=task.required_role,
  )
  let rerun = execute_goal_book_task(
    mayor,
    entry,
    retry_task,
    assigned_worker_id=execution.assigned_worker_id,
    tick=supervision_tick(state),
  ) catch {
    error =>
      failed_execution_record(
        entry,
        retry_task,
        "Mayor retry failed for \{entry.id} / \{task.id}: \{error}",
      )
  }
  let updated = copy_execution_with(
    rerun,
    attempt=execution.attempt + 1,
    next_retry_tick=directive.next_retry_tick,
  )
  state.replace_execution(updated)
  state.replace_task(task_for_supervision(state, updated))
  sync_worker_from_execution(state, updated)
  persist_execution_into_book(state, entry, updated)
}

///|
fn stage_kind_for_task(task : @core.TownTask) -> String {
  let text = "\{task.id} \{task.title} \{task.prompt}".to_lower()
  if text.contains("ingest") || text.contains("source") {
    "ingest"
  } else if text.contains("review") {
    "review"
  } else if text.contains("plan") {
    "planning"
  } else {
    "analysis"
  }
}

///|
fn prioritized_tasks(
  tasks : Array[@moonbook.BookTask],
  goal : String,
) -> Array[@moonbook.BookTask] {
  let ordered = tasks.copy()
  let research_goal = is_research_goal(goal)
  ordered.sort_by(fn(left, right) {
    task_priority_score(right, research_goal).compare(
      task_priority_score(left, research_goal),
    )
  })
  ordered
}

///|
priv struct ResearchBootstrapPlan {
  tasks : Array[@moonbook.BookTask]
  task_limit : Int
  bootstrap_active : Bool
}

///|
async fn research_bootstrap_plan(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
  tasks : Array[@moonbook.BookTask],
  task_limit : Int,
) -> ResearchBootstrapPlan {
  let ordered = prioritized_tasks(tasks, goal)
  let bootstrap_active = research_goal_needs_bootstrap(entry, goal, summary)
  if !bootstrap_active {
    return { tasks: ordered, task_limit, bootstrap_active: false }
  }
  let bootstrap_task = bootstrap_ingest_task(entry, goal)
  let planned = [
    bootstrap_task,
    ..ordered.filter(fn(task) { task.id != bootstrap_task.id }),
  ]
  let effective_limit = research_bootstrap_task_limit()
  { tasks: planned, task_limit: effective_limit, bootstrap_active: true }
}

///|
fn research_bootstrap_task_limit() -> Int {
  1
}

///|
async fn research_goal_needs_bootstrap(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
  summary : @moonbook.BookStateSummary,
) -> Bool {
  if !is_research_goal(goal) {
    return false
  }
  let no_substantive_tree = !has_substantive_research_tree(entry)
  let missing_domain_coverage = summary.entity_count == 0 &&
    summary.concept_count == 0
  let no_durable_sources = summary.verified_source_count == 0
  let no_durable_evidence = summary.evidence_count == 0
  no_substantive_tree ||
  missing_domain_coverage ||
  no_durable_sources ||
  no_durable_evidence
}

///|
fn bootstrap_ingest_task(
  entry : @moonbook.BookCatalogEntry,
  goal : String,
) -> @moonbook.BookTask {
  let normalized_goal = goal.trim().to_string()
  @moonbook.BookTask::new(
    id="goal-\{entry.id}-research-bootstrap-ingest",
    goal=Some(normalized_goal),
    title="Bootstrap verified research coverage",
    kind="ingest",
    prompt="Bootstrap this book before answering the research question. Work as a researcher: formulate the lane-specific question, run web search before local file search, fetch and screen authoritative sources, extract a claim-level evidence matrix, inspect local files only after web discovery, then materialize verified source, entity, concept, and synthesis pages. The result must be specific to this book lane, not generic MoonBook copy, and every major claim must cite a source ID or local path.",
    priority=100,
    requires_review=true,
    target_pages=[
      "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
      "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
      "wiki/sources", "wiki/entities", "wiki/concepts", "wiki/synthesis", "wiki/index.md",
      "wiki/log.md",
    ],
    required_role=Some(@core.WorkerRole::Harness),
  )
}

///|
fn is_research_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("moontown") ||
  notes.contains("moonbook") ||
  notes.contains("moonclaw")
}

///|
async fn has_substantive_research_tree(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  let root = @moonbook.workspace_root(entry)
  let paths = [
    "\{root}/wiki/entities",
    "\{root}/wiki/concepts",
    "\{root}/wiki/sources",
    "\{root}/wiki/queries",
  ]
  for path in paths {
    let listed = @integration.run_checked("find", [path, "-type", "f"]) catch {
      _ => continue
    }
    if !listed.stdout.trim().is_blank() {
      return true
    }
  }
  false
}

///|
fn task_priority_score(task : @moonbook.BookTask, research_goal : Bool) -> Int {
  let kind_score = match task.kind {
    "analysis" => 60
    "synthesis" => 50
    "planning" => if research_goal { 15 } else { 40 }
    "review" => if research_goal { 10 } else { 45 }
    "ingest" | "ingest-followup" => if research_goal { 35 } else { 25 }
    _ => 20
  }
  kind_score + task.priority
}
