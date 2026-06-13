///|
pub fn archive_pdf_evidence_watch_catalog_entry(
  catalog : Array[@moonbook.BookCatalogEntry],
  book_id : String,
  reason : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let updated : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    if entry.id == book_id {
      updated.push(
        @moonbook.BookCatalogEntry::new(
          id=entry.id,
          name=entry.name,
          purpose="\{entry.purpose}\n\nArchived: \{reason}",
          workspace_root=entry.workspace_root,
          memory_scope=entry.memory_scope,
          tags=ensure_pdf_evidence_watch_archive_tags(entry.tags),
          skills=entry.skills,
        ),
      )
    } else {
      updated.push(entry)
    }
  }
  updated
}

///|
fn ensure_pdf_evidence_watch_archive_tags(
  tags : Array[String],
) -> Array[String] {
  let updated : Array[String] = []
  for tag in tags {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  for tag in ["archived", "hidden", "internal"] {
    if !updated.contains(tag) {
      updated.push(tag)
    }
  }
  updated
}

///|
pub fn pdf_evidence_watch_goal_id(book_id : String) -> String {
  "watch-\{book_id}-pdfs"
}

///|
pub fn disable_pdf_evidence_watch_book_standing_goals(
  goals : Array[@core.StandingGoal],
  book_id : String,
) -> Array[@core.StandingGoal] {
  let updated : Array[@core.StandingGoal] = []
  for goal in goals {
    if pdf_evidence_watch_should_disable_goal_for_book(goal, book_id) {
      updated.push(pdf_evidence_watch_standing_goal_with_enabled(goal, false))
    } else {
      updated.push(goal)
    }
  }
  updated
}

///|
fn pdf_evidence_watch_should_disable_goal_for_book(
  goal : @core.StandingGoal,
  book_id : String,
) -> Bool {
  if goal.id == pdf_evidence_watch_goal_id(book_id) {
    return true
  }
  if goal.id == @book_quality.repair_goal_id(book_id) {
    return true
  }
  match goal.target_book_id {
    Some(target) => target == book_id
    None => false
  }
}

///|
pub fn count_disabled_pdf_evidence_watch_book_standing_goals(
  before : Array[@core.StandingGoal],
  after : Array[@core.StandingGoal],
  book_id : String,
) -> Int {
  let mut count = 0
  for goal in before {
    if goal.enabled &&
      pdf_evidence_watch_should_disable_goal_for_book(goal, book_id) {
      for candidate in after {
        if candidate.id == goal.id && !candidate.enabled {
          count += 1
        }
      }
    }
  }
  count
}

///|
fn pdf_evidence_watch_standing_goal_with_enabled(
  goal : @core.StandingGoal,
  enabled : Bool,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled~,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
pub fn render_pdf_evidence_watch_archive_summary(
  book_id : String,
  reason : String,
  book_catalog_path : String,
  goal_id : String,
  disabled_count : Int,
  request_event_path : String,
  status : @pdf_evidence_watch.PdfEvidenceWatchBookStatus,
) -> String {
  [
    "Archived PDF Evidence Watch book `\{book_id}`.",
    "- Reason: \{reason}",
    "- Catalog: `\{book_catalog_path}`",
    "- Standing goal: `\{goal_id}` enabled=`\{status.standing_goal_enabled}`",
    "- Disabled standing goals targeting this book: `\{disabled_count}`",
    "- Lifecycle event log: `\{request_event_path}`",
    "- Workspace preserved: `\{status.workspace_root}`",
    "- Ready for autonomous watching: `\{status.ready}`",
  ].join("\n")
}
