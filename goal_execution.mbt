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
  let result_summary = research_persist_summary(entry, execution)
  let result_artifacts = research_persist_artifacts(entry, execution)
  let memory_candidates = research_persist_memory_candidates(entry, execution)
  let result = @moonbook.BookResult::new(
    task_id=execution.task_id,
    summary=result_summary,
    artifacts=result_artifacts,
    memory_candidates~,
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
async fn research_persist_summary(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> String {
  if !is_research_bootstrap_execution(entry, execution) {
    return execution.summary
  }
  let root = @moonbook.workspace_root(entry)
  let display = research_persist_display(entry)
  let brief = read_text_or_empty("\{root}/raw/bootstrap/synthesis-brief.md")
  let report = read_text_or_empty("\{root}/raw/bootstrap/deep-report.md")
  let source_screen = read_text_or_empty(
    "\{root}/raw/bootstrap/source-screen.md",
  )
  let evidence = read_text_or_empty("\{root}/raw/bootstrap/evidence-matrix.md")
  let evidence_summary = first_non_empty_compact_excerpt(
    [brief, report, source_screen, evidence],
    900,
  )
  let run_line = match execution.run_id {
    Some(run_id) => " Worker run: `\{run_id}`."
    None => ""
  }
  "Research bootstrap completed for \{display}. Raw artifacts are ready under `raw/bootstrap/`: research-question, search-log, source-screen, evidence-matrix, local-sources, synthesis-brief, deep-report, and marketing-brief.\{run_line} Evidence summary: \{evidence_summary}"
}

///|
fn research_persist_artifacts(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[String] {
  let artifacts : Array[String] = []
  match execution.run_id {
    Some(run_id) => artifacts.push(run_id)
    None => ()
  }
  if is_research_bootstrap_execution(entry, execution) {
    for artifact in research_bootstrap_result_artifacts() {
      artifacts.push(artifact)
    }
  }
  artifacts
}

///|
async fn research_persist_memory_candidates(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Array[@moonbook.MemoryCandidate] {
  if !is_research_bootstrap_execution(entry, execution) {
    return []
  }
  let topic = quality_topic_for_entry(entry)
  let display = research_persist_display(entry)
  let root = @moonbook.workspace_root(entry)
  let brief = read_text_or_empty("\{root}/raw/bootstrap/synthesis-brief.md")
  let source_screen = read_text_or_empty(
    "\{root}/raw/bootstrap/source-screen.md",
  )
  let evidence = read_text_or_empty("\{root}/raw/bootstrap/evidence-matrix.md")
  let report = read_text_or_empty("\{root}/raw/bootstrap/deep-report.md")
  let source_detail = first_non_empty_compact_excerpt(
    [source_screen, evidence, brief],
    700,
  )
  let entity_detail = first_non_empty_compact_excerpt([brief, report], 700)
  let concept_detail = first_non_empty_compact_excerpt(
    [evidence, brief, report],
    700,
  )
  let synthesis_detail = first_non_empty_compact_excerpt(
    [brief, evidence, report],
    700,
  )
  [
    @moonbook.MemoryCandidate::new(
      kind="source",
      title="\{display} screened source set",
      detail="Screened research evidence for this book: \{source_detail}",
      durable=true,
      target_page=Some("sources/\{topic}-screened-sources.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="entity",
      title=display,
      detail="Primary research entity for this book: \{entity_detail}",
      durable=true,
      target_page=Some("entities/\{topic}.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="concept",
      title="\{display} research thesis",
      detail="Maintained concept synthesized from the evidence matrix: \{concept_detail}",
      durable=true,
      target_page=Some("concepts/\{topic}-research-thesis.md"),
    ),
    @moonbook.MemoryCandidate::new(
      kind="synthesis",
      title="\{display} evidence-limited synthesis",
      detail="Current synthesis and open gaps: \{synthesis_detail}",
      durable=true,
      target_page=Some("synthesis/\{topic}-research-thesis.md"),
    ),
  ]
}

///|
fn is_research_bootstrap_execution(
  entry : @moonbook.BookCatalogEntry,
  execution : @core.TaskExecutionRecord,
) -> Bool {
  entry.id.has_prefix("research-") &&
  execution.task_id.contains("research-bootstrap-ingest")
}

///|
fn research_bootstrap_result_artifacts() -> Array[String] {
  [
    "raw/bootstrap/research-question.md", "raw/bootstrap/search-log.md", "raw/bootstrap/source-screen.md",
    "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/local-sources.md", "raw/bootstrap/synthesis-brief.md",
    "raw/bootstrap/deep-report.md", "raw/bootstrap/marketing-brief.md",
  ]
}

///|
fn research_persist_display(entry : @moonbook.BookCatalogEntry) -> String {
  let topic = quality_topic_for_entry(entry)
  if topic == "opc" {
    "One Person Company (OPC)"
  } else if !entry.name.trim().is_blank() {
    entry.name
  } else {
    topic.replace(old="-", new=" ").to_string()
  }
}

///|
fn first_non_empty_compact_excerpt(
  texts : Array[String],
  limit : Int,
) -> String {
  for text in texts {
    let compact = compact_markdown_for_candidate(text)
    if !compact.is_blank() {
      return markdown_excerpt(compact, limit)
    }
  }
  "No non-empty research artifact text was available at persistence time."
}

///|
fn compact_markdown_for_candidate(text : String) -> String {
  let builder = StringBuilder::new()
  let mut wrote = false
  for raw in text.split("\n") {
    let line = raw.trim().to_string()
    if line.is_empty() ||
      line.has_prefix("#") ||
      line.has_prefix("| ---") ||
      line.has_prefix("```") {
      continue
    }
    if wrote {
      builder.write_string(" ")
    }
    builder.write_string(line)
    wrote = true
  }
  builder.to_string()
}

///|
async fn execute_goal_book_task(
  mayor : @roles.Mayor,
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  if is_wenyu_book(entry) && is_local_wenyu_build_fallback_task(task.kind) {
    return local_wenyu_build_execution_record(
      entry,
      task,
      assigned_worker_id~,
      tick~,
    )
  }
  let prepared = mayor.prepare_keeper_packet(entry, task)
  let workspace_root = @moonbook.workspace_root(entry)
  let imported = @moonclaw.import_packet(
    prepared.packet,
    prepared.packet_path,
    cwd=workspace_root,
    confirm=true,
    run_inline=moontown_moonclaw_inline_enabled(),
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
fn is_local_wenyu_build_fallback_task(kind : String) -> Bool {
  kind == "implementation-backlog" || kind == "image-asset"
}

///|
fn local_wenyu_build_execution_record(
  entry : @moonbook.BookCatalogEntry,
  task : @moonbook.BookTask,
  assigned_worker_id? : String? = None,
  tick? : Int = 0,
) -> @core.TaskExecutionRecord {
  let packet_id = "local-\{entry.id}-\{task.id}"
  let status = if task.kind == "code-patch" {
    @core.TaskExecutionStatus::ReviewQueued
  } else {
    @core.TaskExecutionStatus::Completed
  }
  @core.TaskExecutionRecord::new(
    task_id=task.id,
    book_id=entry.id,
    packet_id~,
    packet_path="local://wenyu-build/\{entry.id}/\{task.id}",
    proposal_id=Some("local-wenyu-build-materializer"),
    run_id=None,
    status~,
    summary="Moontown used the local Wenyu build materializer for `\{task.kind}` because the current MoonClaw/Codex ACP path can start build controllers but does not provide reliable writable repository execution yet.",
    output_contract="wenyu.build.packet.v1",
    context_pages=task.target_pages,
    skill_paths=[
      "skills/wenyu-build/SKILL.md", "skills/wenyu-code-patch/SKILL.md", "skills/wenyu-asset-pack/SKILL.md",
    ],
    assigned_worker_id~,
    attempt=1,
    heartbeat_tick=tick,
    stale_after_tick=tick + 3,
    next_retry_tick=None,
    requires_review=task.requires_review || task.kind == "code-patch",
    notify_town=true,
  )
}

///|
fn moontown_moonclaw_inline_enabled() -> Bool {
  match optional_env_text("MOONTOWN_MOONCLAW_INLINE") {
    Some(value) => {
      let lower = value.to_lower()
      lower == "1" || lower == "true" || lower == "yes" || lower == "on"
    }
    None => false
  }
}

///|
async fn ensure_run_execution(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> (@moonclaw.ProposalPollResponse, String?)? {
  let initial = @moonclaw.poll_run(
    task_id,
    run_id,
    cwd=workspace_root,
    detect_orphan=false,
  )
  let launch_command = if initial.status
    is @core.TaskExecutionStatus::RunConfirmed {
    Some(@moonclaw.run_confirmed_run(run_id, cwd=workspace_root))
  } else {
    None
  }
  let current = wait_for_moonclaw_run(task_id, run_id, workspace_root)
  Some((current, launch_command))
}

///|
async fn wait_for_moonclaw_run(
  task_id : String,
  run_id : String,
  workspace_root : String,
) -> @moonclaw.ProposalPollResponse {
  let mut latest = @moonclaw.poll_run(
    task_id,
    run_id,
    cwd=workspace_root,
    detect_orphan=false,
  )
  for attempt = 0; attempt < 600; attempt = attempt + 1 {
    if !is_live_moonclaw_status(latest.status) {
      return latest
    }
    @async.sleep(1_000)
    latest = @moonclaw.poll_run(
      task_id,
      run_id,
      cwd=workspace_root,
      detect_orphan=false,
    )
  }
  @moonclaw.timed_out_poll_response(
    task_id,
    run_id,
    "MoonClaw run \{run_id} did not settle within the 10 minute Moontown supervision window; treating it as failed so the mayor can record blockers and continue recovery.",
  )
}

///|
fn is_live_moonclaw_status(status : @core.TaskExecutionStatus) -> Bool {
  status is @core.TaskExecutionStatus::ProposalImported ||
  status is @core.TaskExecutionStatus::RunConfirmed ||
  status is @core.TaskExecutionStatus::Running
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
