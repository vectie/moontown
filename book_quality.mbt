///|
pub struct BookQualityScore {
  book_id : String
  title : String
  book_type : String
  workspace_root : String
  structural_score : Int
  structural_grade : String
  semantic_score : Int?
  semantic_grade : String
  quality_status : String
  score : Int
  grade : String
  ready : Bool
  strengths : Array[String]
  gaps : Array[String]
  next_action : String
} derive(Eq, ToJson, FromJson)

///|
pub struct BookQualityAudit {
  generated_at : String
  catalog_path : String
  total : Int
  world_class_count : Int
  ready_count : Int
  weakest_book_id : String
  weakest_score : Int
  scores : Array[BookQualityScore]
} derive(Eq, ToJson, FromJson)

///|
pub struct BookQualityReviewPacket {
  book_id : String
  book_type : String
  workspace_root : String
  structural_score : Int
  review_skill_path : String
  context_pages : Array[String]
  prompt : String
  output_contract : String
} derive(Eq, ToJson, FromJson)

///|
pub struct BookQualityReviewRun {
  book_id : String
  packet_path : String
  result_path : String
  proposal_id : String?
  run_id : String?
  status : String
  summary : String
  generated_at_ms : UInt64
} derive(Eq, ToJson, FromJson)

///|
pub struct BookQualityReviewRunLedger {
  runs : Array[BookQualityReviewRun]
} derive(Eq, ToJson, FromJson)

///|
struct BookQualityRepairBridgeItem {
  book_id : String
  book_type : String
  workspace_root : String
  semantic_score : Int
  semantic_grade : String
  repair_owner : String
  next_repair_task : String
  review_result_path : String
  book_review_path : String
  standing_goal_id : String
  status : String
  generated_at_ms : UInt64
} derive(Eq, ToJson, FromJson)

///|
struct BookQualityRepairBridgeLedger {
  items : Array[BookQualityRepairBridgeItem]
} derive(Eq, ToJson, FromJson)

///|
pub fn default_book_quality_audit_path() -> String {
  ".moontown/book-quality/audit.json"
}

///|
pub fn default_book_quality_review_dir() -> String {
  ".moontown/book-quality/ai-review-packets"
}

///|
pub fn default_book_quality_review_result_dir() -> String {
  ".moontown/book-quality/ai-review-results"
}

///|
pub fn default_book_quality_review_run_path() -> String {
  ".moontown/book-quality/ai-review-runs.json"
}

///|
fn default_book_quality_repair_bridge_path() -> String {
  ".moontown/book-quality/repair-bridge.json"
}

///|
pub async fn inspect_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> BookQualityAudit {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  let scores : Array[BookQualityScore] = []
  let review_result_dir = book_quality_review_result_dir_for_snapshot(
    snapshot_path,
  )
  for entry in catalog {
    scores.push(score_book(entry, review_result_dir))
  }
  let weakest = weakest_score(scores)
  {
    generated_at: "runtime",
    catalog_path: book_catalog_path,
    total: scores.length(),
    world_class_count: scores.filter(fn(item) { item.score >= 90 }).length(),
    ready_count: scores.filter(fn(item) { item.ready }).length(),
    weakest_book_id: match weakest {
      Some(score) => score.book_id
      None => ""
    },
    weakest_score: match weakest {
      Some(score) => score.score
      None => 0
    },
    scores,
  }
}

///|
async fn quality_catalog_with_runtime_books(
  catalog : Array[@moonbook.BookCatalogEntry],
  snapshot_path : String,
) -> Array[@moonbook.BookCatalogEntry] {
  let merged : Array[@moonbook.BookCatalogEntry] = []
  for entry in catalog {
    merged.push(entry)
  }
  match @storage.load_snapshot_file(snapshot_path) {
    Some(snapshot) =>
      for book in snapshot.town.books {
        if !merged.any(fn(entry) { entry.id == book.id }) {
          merged.push(
            @moonbook.BookCatalogEntry::new(
              id=book.id,
              name=book.name,
              purpose=book.purpose,
              workspace_root=book.workspace_root,
              memory_scope=book.memory_scope,
              tags=book.tags,
              skills=[],
            ),
          )
        }
      }
    None => ()
  }
  merged
}

///|
pub async fn render_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
) -> String {
  render_book_quality_audit(
    inspect_book_quality(book_catalog_path~, snapshot_path~),
  )
}

///|
pub async fn write_book_quality_audit(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  audit_path? : String = default_book_quality_audit_path(),
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  write_text_file(audit_path, audit.to_json().stringify(indent=2))
  let markdown_path = book_quality_markdown_path(audit_path)
  write_text_file(markdown_path, render_book_quality_audit(audit))
  "Wrote book management audit for \{audit.total} registered book(s) to \{audit_path} and \{markdown_path}; weakest_structural=\{audit.weakest_book_id}(\{audit.weakest_score}). Semantic quality scores require AI review results."
}

///|
pub async fn write_book_quality_review_packets(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  review_dir? : String = default_book_quality_review_dir(),
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  write_text_file(
    "\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md",
    book_quality_ai_review_skill_markdown(),
  )
  let packets : Array[BookQualityReviewPacket] = []
  for score in audit.scores {
    let packet = book_quality_review_packet(score, review_dir)
    packets.push(packet)
    write_text_file(
      "\{review_dir}/\{score.book_id}.json",
      packet.to_json().stringify(indent=2),
    )
  }
  write_text_file(
    "\{review_dir}/README.md",
    book_quality_review_readme(audit, packets),
  )
  "Wrote \{packets.length()} AI quality review packet(s) to \{review_dir}. Run these with MoonClaw/MoonBook and write results to \{default_book_quality_review_result_dir()}/<book-id>.md; structural checks only gate readiness."
}

///|
pub async fn dispatch_next_book_quality_ai_review(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  review_dir? : String = default_book_quality_review_dir(),
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
  run_inline? : Bool = moontown_moonclaw_inline_enabled(),
) -> String {
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let active = book_quality_ai_review_active_count(result_dir~, run_path~)
  if active > 0 {
    return "AI semantic book-quality review already active; daemon will not dispatch a duplicate. active=\{active}"
  }
  ignore(
    write_book_quality_review_packets(
      book_catalog_path~,
      snapshot_path~,
      review_dir~,
    ),
  )
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  let score = first_pending_ai_review_book(audit, result_dir)
  match score {
    None =>
      "No pending AI semantic book-quality review remains. Results are stored under \{result_dir}."
    Some(score) => {
      write_book_quality_review_moonclaw_profile(review_dir)
      let packet = book_quality_review_packet(score, review_dir)
      let external = book_quality_external_review_packet(packet, result_dir)
      let packet_path = book_quality_external_packet_path(
        review_dir,
        score.book_id,
      )
      let imported = @moonclaw.import_packet(
        external,
        packet_path,
        cwd=book_quality_review_root(review_dir),
        home=book_quality_moonclaw_home(review_dir),
        confirm=true,
        run_inline~,
      ) catch {
        error => {
          let run = BookQualityReviewRun::{
            book_id: score.book_id,
            packet_path,
            result_path: "\{result_dir}/\{score.book_id}.md",
            proposal_id: None,
            run_id: None,
            status: "blocked",
            summary: "MoonClaw AI review dispatch failed: \{error}",
            generated_at_ms: @env.now(),
          }
          append_book_quality_review_run(run_path, run)
          return run.summary
        }
      }
      let launch_command = match imported.run_id {
        Some(run_id) if !run_inline =>
          Some(
            @moonclaw.run_confirmed_run(
              run_id,
              cwd=book_quality_review_root(review_dir),
              home=book_quality_moonclaw_home(review_dir),
            ),
          )
        _ => None
      }
      let run = BookQualityReviewRun::{
        book_id: score.book_id,
        packet_path,
        result_path: "\{result_dir}/\{score.book_id}.md",
        proposal_id: Some(imported.proposal_id),
        run_id: imported.run_id,
        status: if imported.run_id is Some(_) {
          "dispatched"
        } else {
          "queued"
        },
        summary: match launch_command {
          Some(command) => "\{imported.summary} Detached runner: \{command}"
          None => imported.summary
        },
        generated_at_ms: @env.now(),
      }
      append_book_quality_review_run(run_path, run)
      "Dispatched AI semantic book-quality review for `\{score.book_id}`. \{run.summary}"
    }
  }
}

///|
pub async fn reconcile_book_quality_repair_bridge(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  snapshot_path? : String = @storage.default_snapshot_path(),
  result_dir? : String = default_book_quality_review_result_dir(),
  bridge_path? : String = default_book_quality_repair_bridge_path(),
) -> String {
  let catalog = quality_catalog_with_runtime_books(
    @moonbook.load_or_create_catalog(path=book_catalog_path),
    snapshot_path,
  )
  let repairable_book_ids = book_quality_repairable_book_ids(catalog)
  let audit = inspect_book_quality(book_catalog_path~, snapshot_path~)
  let current_tick = book_quality_current_daemon_tick(snapshot_path)
  let goals_path = book_quality_standing_goal_path(snapshot_path)
  let goals = @storage.load_or_create_standing_goals(path=goals_path)
  let retired_goal_ids = retire_satisfied_book_quality_repair_goals(
    goals,
    audit.scores,
    repairable_book_ids,
    result_dir,
  )
  let repaired : Array[BookQualityRepairBridgeItem] = []
  for score in audit.scores {
    if !repairable_book_ids.contains(score.book_id) {
      continue
    }
    let result_path = "\{result_dir}/\{score.book_id}.md"
    let result_text = read_text_or_empty(result_path)
    if result_text.is_empty() {
      continue
    }
    match parse_ai_quality_score(result_text) {
      Some(value) if value < 80 => {
        let item = book_quality_repair_bridge_item(
          score, result_path, result_text, value,
        )
        write_book_quality_repair_review_page(item, result_text)
        upsert_book_quality_repair_standing_goal(goals, item, current_tick)
        repaired.push(item)
      }
      _ => ()
    }
  }
  @storage.save_standing_goals_file(goals_path, goals)
  write_text_file(
    bridge_path,
    BookQualityRepairBridgeLedger::{ items: repaired }
    .to_json()
    .stringify(indent=2),
  )
  if repaired.is_empty() {
    if retired_goal_ids.is_empty() {
      "No weak AI semantic book-quality review needed repair bridging."
    } else {
      "No weak AI semantic book-quality review needed repair bridging. Retired \{retired_goal_ids.length()} stale repair goal(s): \{retired_goal_ids.join(", ")}."
    }
  } else {
    let ids = repaired.map(fn(item) { item.book_id }).join(", ")
    if retired_goal_ids.is_empty() {
      "Bridged \{repaired.length()} weak AI semantic book-quality review(s) into MoonBook review queues and standing repair goals: \{ids}."
    } else {
      "Bridged \{repaired.length()} weak AI semantic book-quality review(s) into MoonBook review queues and standing repair goals: \{ids}. Retired \{retired_goal_ids.length()} stale repair goal(s): \{retired_goal_ids.join(", ")}."
    }
  }
}

///|
async fn retire_satisfied_book_quality_repair_goals(
  goals : Array[@core.StandingGoal],
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Array[String] {
  let retired : Array[String] = []
  for index in 0..<goals.length() {
    let goal = goals[index]
    if book_quality_should_retire_repair_goal(
        goal, scores, repairable_book_ids, result_dir,
      ) {
      goals[index] = disabled_book_quality_repair_goal(goal)
      retired.push(goal.id)
    }
  }
  retired
}

///|
async fn book_quality_should_retire_repair_goal(
  goal : @core.StandingGoal,
  scores : Array[BookQualityScore],
  repairable_book_ids : Array[String],
  result_dir : String,
) -> Bool {
  if !goal.enabled || !goal.id.has_prefix("book-quality-repair-") {
    return false
  }
  match goal.target_book_id {
    None => false
    Some(book_id) => {
      if !book_quality_score_exists(scores, book_id) {
        return true
      }
      if !repairable_book_ids.contains(book_id) {
        return true
      }
      let result_text = read_text_or_empty("\{result_dir}/\{book_id}.md")
      match parse_ai_quality_score(result_text) {
        Some(value) => value >= 80
        None => false
      }
    }
  }
}

///|
fn book_quality_score_exists(
  scores : Array[BookQualityScore],
  book_id : String,
) -> Bool {
  for score in scores {
    if score.book_id == book_id {
      return true
    }
  }
  false
}

///|
fn disabled_book_quality_repair_goal(
  goal : @core.StandingGoal,
) -> @core.StandingGoal {
  @core.StandingGoal::new(
    id=goal.id,
    title=goal.title,
    prompt=goal.prompt,
    target_book_id=goal.target_book_id,
    cadence_ticks=goal.cadence_ticks,
    next_due_tick=goal.next_due_tick,
    last_run_tick=goal.last_run_tick,
    enabled=false,
    source_policy=goal.source_policy,
    quality_threshold=goal.quality_threshold,
  )
}

///|
fn book_quality_repairable_book_ids(
  catalog : Array[@moonbook.BookCatalogEntry],
) -> Array[String] {
  let ids : Array[String] = []
  for entry in catalog {
    if book_quality_repairable_catalog_entry(entry) {
      ids.push(entry.id)
    }
  }
  ids
}

///|
fn book_quality_repairable_catalog_entry(
  entry : @moonbook.BookCatalogEntry,
) -> Bool {
  !entry.tags.contains("archived") &&
  !entry.tags.contains("hidden") &&
  !entry.tags.contains("internal")
}

///|
fn book_quality_repair_bridge_item(
  score : BookQualityScore,
  result_path : String,
  result_text : String,
  semantic_score : Int,
) -> BookQualityRepairBridgeItem {
  let repair_owner = book_quality_contract_field(result_text, "repair_owner").unwrap_or(
    "mixed",
  )
  let task = book_quality_contract_field(result_text, "next_repair_task").unwrap_or(
    score.next_action,
  )
  let semantic_grade = book_quality_contract_field(
    result_text, "ai_quality_grade",
  ).unwrap_or(score.semantic_grade)
  {
    book_id: score.book_id,
    book_type: score.book_type,
    workspace_root: score.workspace_root,
    semantic_grade,
    repair_owner,
    next_repair_task: task,
    review_result_path: result_path,
    book_review_path: "\{score.workspace_root}/wiki/reviews/book-quality-repair.md",
    standing_goal_id: book_quality_repair_goal_id(score.book_id),
    status: "queued",
    generated_at_ms: @env.now(),
    semantic_score,
  }
}

///|
async fn write_book_quality_repair_review_page(
  item : BookQualityRepairBridgeItem,
  result_text : String,
) -> Unit {
  write_text_file(
    item.book_review_path,
    [
      "# Book Quality Repair Queue",
      "",
      "This page is generated from Moontown's semantic book-quality review. It is a repair queue, not accepted domain evidence.",
      "",
      "## Current Repair",
      "",
      "- Book: `\{item.book_id}`",
      "- Type: `\{item.book_type}`",
      "- AI quality: `\{item.semantic_score}` / `\{item.semantic_grade}`",
      "- Repair owner: `\{item.repair_owner}`",
      "- Standing repair goal: `\{item.standing_goal_id}`",
      "- Status: `\{item.status}`",
      "",
      "## Next Repair Task",
      "",
      item.next_repair_task,
      "",
      "## Review Contract",
      "",
      "```md",
      result_text.trim().to_owned(),
      "```",
      "",
      "## Accounting Rule",
      "",
      "Do not mark this repair as accepted progress until the owning MoonBook or civic protocol has updated durable domain/service artifacts and a later semantic review no longer reports this gap.",
    ].join("\n"),
  )
}

///|
fn upsert_book_quality_repair_standing_goal(
  goals : Array[@core.StandingGoal],
  item : BookQualityRepairBridgeItem,
  current_tick : Int,
) -> Unit {
  let replacement = @core.StandingGoal::new(
    id=item.standing_goal_id,
    title="Repair book quality: \{item.book_id}",
    prompt=book_quality_repair_goal_prompt(item),
    target_book_id=Some(item.book_id),
    cadence_ticks=60,
    next_due_tick=current_tick + 1,
    source_policy=book_quality_repair_source_policy(item.book_type),
    quality_threshold=80,
  )
  let mut replaced = false
  for index in 0..<goals.length() {
    if goals[index].id == replacement.id {
      let existing = goals[index]
      goals[index] = @core.StandingGoal::new(
        id=item.standing_goal_id,
        title="Repair book quality: \{item.book_id}",
        prompt=book_quality_repair_goal_prompt(item),
        target_book_id=Some(item.book_id),
        cadence_ticks=60,
        next_due_tick=existing.next_due_tick,
        last_run_tick=existing.last_run_tick,
        enabled=true,
        source_policy=book_quality_repair_source_policy(item.book_type),
        quality_threshold=80,
      )
      replaced = true
    }
  }
  if !replaced {
    goals.push(replacement)
  }
}

///|
fn book_quality_repair_goal_prompt(
  item : BookQualityRepairBridgeItem,
) -> String {
  [
    "A semantic MoonBook quality review found that this book is not ready.",
    "",
    "Book id: `\{item.book_id}`",
    "Book type: `\{item.book_type}`",
    "AI quality: `\{item.semantic_score}` / `\{item.semantic_grade}`",
    "Repair owner: `\{item.repair_owner}`",
    "Review queue: `wiki/reviews/book-quality-repair.md`",
    "",
    "Repair task from the AI review:",
    item.next_repair_task,
    "",
    "Rules:",
    "- Repair the existing book in place; do not create v1/v2/v3/v4 alternates.",
    "- Follow the book's own contract and SKILL.md; do not force a research genre onto civic, course, planbook, cookbook, or operational books.",
    "- Separate operational logs from domain/service evidence.",
    "- If the repair needs web evidence and source policy allows it, search/fetch web sources before local fallback.",
    "- Return a strict standing-goal decision marker so Moontown can account for real growth.",
  ].join("\n")
}

///|
fn book_quality_repair_source_policy(book_type : String) -> String {
  match book_type {
    "research-book" => "web-first"
    _ => "book-first"
  }
}

///|
fn book_quality_repair_goal_id(book_id : String) -> String {
  "book-quality-repair-\{book_id}"
}

///|
fn book_quality_contract_field(text : String, key : String) -> String? {
  let needle = "\{key.to_lower()}:"
  for raw in text.split("\n") {
    let line = raw.trim()
    let lower = line.to_lower()
    if lower.has_prefix(needle) {
      return Some(line[needle.length():].trim().to_owned())
    }
  }
  None
}

///|
async fn book_quality_current_daemon_tick(snapshot_path : String) -> Int {
  let path = book_quality_daemon_state_path(snapshot_path)
  if !@fs.exists(path) {
    return 0
  }
  let parsed = @json.parse(@fs.read_file(path).text()) catch { _ => return 0 }
  match parsed {
    Object(object) =>
      match object.get("tick_sequence") {
        Some(Number(value, ..)) => value.to_int()
        _ => 0
      }
    _ => 0
  }
}

///|
fn book_quality_daemon_state_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    ".moontown/daemon.json"
  } else {
    "\{base}/daemon.json"
  }
}

///|
fn book_quality_standing_goal_path(snapshot_path : String) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    @storage.default_standing_goal_path()
  } else {
    "\{base}/standing-goals.json"
  }
}

///|
async fn book_quality_ai_review_active_count(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> Int {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let now = @env.now()
  let mut active = 0
  for run in ledger.runs {
    if book_quality_review_run_active(run, result_dir, now~) {
      active += 1
    }
  }
  active
}

///|
async fn book_quality_review_run_active(
  run : BookQualityReviewRun,
  result_dir : String,
  now? : UInt64 = @env.now(),
) -> Bool {
  if @fs.exists("\{result_dir}/\{run.book_id}.md") ||
    @fs.exists(run.result_path) {
    return false
  }
  if run.status != "dispatched" &&
    run.status != "queued" &&
    run.status != "running" {
    return false
  }
  match run.run_id {
    Some(run_id) if @moonclaw.run_process_alive(run_id) => true
    Some(_) => now < run.generated_at_ms + book_quality_review_stale_after_ms()
    None => now < run.generated_at_ms + book_quality_review_stale_after_ms()
  }
}

///|
pub async fn render_book_quality_ai_review_status(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> String {
  ignore(reconcile_book_quality_ai_review_results(result_dir~, run_path~))
  let ledger = load_book_quality_review_run_ledger(run_path)
  let active = book_quality_ai_review_active_count(result_dir~, run_path~)
  let current_runs = current_book_quality_review_runs(ledger)
  let historical_attempts = ledger.runs.length() - current_runs.length()
  let historical_problem_attempts = historical_book_quality_problem_attempt_count(
    ledger, current_runs,
  )
  let lines : Array[String] = [
    "# Book Quality AI Review Runs",
    "",
    "- run ledger: `\{run_path}`",
    "- result dir: `\{result_dir}`",
    "- active reviews: `\{active}`",
    "- runs: `\{ledger.runs.length()}`",
    "- current books: `\{current_runs.length()}`",
    "- historical attempts: `\{historical_attempts}`",
    "- historical problem attempts: `\{historical_problem_attempts}`",
    "",
    "## Current By Book",
    "",
    "| Book | Status | Result | Run | Summary |",
    "| --- | --- | --- | --- | --- |",
  ]
  for run in current_runs {
    let result_state = if @fs.exists(run.result_path) {
      "written"
    } else {
      "pending"
    }
    lines.push(
      "|\{run.book_id}|\{run.status}|\{result_state}|`\{run.run_id.unwrap_or("none")}`|\{markdown_inline(run.summary)}|",
    )
  }
  if historical_attempts > 0 {
    lines.push("")
    lines.push("## Historical Attempts")
    lines.push("")
    lines.push(
      "Historical attempts are audit trail. If a later current row is `written`, earlier `orphaned` or `blocked` rows are recovered failures, not current unresolved work.",
    )
    lines.push("")
    lines.push("| Book | Status | Result | Run | Summary |")
    lines.push("| --- | --- | --- | --- | --- |")
    for run in ledger.runs {
      if book_quality_review_run_is_current(run, current_runs) {
        continue
      }
      let result_state = if @fs.exists(run.result_path) {
        "written"
      } else {
        "pending"
      }
      lines.push(
        "|\{run.book_id}|\{run.status}|\{result_state}|`\{run.run_id.unwrap_or("none")}`|\{markdown_inline(run.summary)}|",
      )
    }
  }
  lines.join("\n")
}

///|
fn current_book_quality_review_runs(
  ledger : BookQualityReviewRunLedger,
) -> Array[BookQualityReviewRun] {
  let current : Array[BookQualityReviewRun] = []
  for run in ledger.runs {
    let mut found = false
    for index in 0..<current.length() {
      if current[index].book_id == run.book_id {
        current[index] = run
        found = true
        break
      }
    }
    if !found {
      current.push(run)
    }
  }
  current
}

///|
fn book_quality_review_run_is_current(
  run : BookQualityReviewRun,
  current_runs : Array[BookQualityReviewRun],
) -> Bool {
  current_runs.any(fn(current) {
    current.book_id == run.book_id &&
    current.generated_at_ms == run.generated_at_ms &&
    current.run_id == run.run_id &&
    current.status == run.status &&
    current.summary == run.summary
  })
}

///|
fn historical_book_quality_problem_attempt_count(
  ledger : BookQualityReviewRunLedger,
  current_runs : Array[BookQualityReviewRun],
) -> Int {
  let mut count = 0
  for run in ledger.runs {
    if book_quality_review_run_is_current(run, current_runs) {
      continue
    }
    if run.status == "orphaned" || run.status == "blocked" {
      count += 1
    }
  }
  count
}

///|
pub async fn reconcile_book_quality_ai_review_results(
  result_dir? : String = default_book_quality_review_result_dir(),
  run_path? : String = default_book_quality_review_run_path(),
) -> Int {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let reconciled : Array[BookQualityReviewRun] = []
  let mut written = 0
  let mut changed = false
  let root = book_quality_review_root_from_run_path(run_path)
  let home = book_quality_moonclaw_home_from_run_path(run_path)
  for run in ledger.runs {
    if @fs.exists(run.result_path) {
      let terminal = corrected_terminal_book_quality_review_run(run)
      if terminal.status == run.status && terminal.summary == run.summary {
        reconciled.push(run)
      } else {
        reconciled.push(terminal)
        changed = true
      }
      continue
    }
    let mut current = run
    match run.run_id {
      Some(run_id) => {
        let content = book_quality_review_result_content_from_run(
          run_id, root, home,
        )
        if content.contains("ai_quality_score:") &&
          content.contains("book_role_fit:") {
          write_text_file("\{result_dir}/\{run.book_id}.md", content)
          written += 1
          current = {
            ..run,
            status: "written",
            summary: "Harvested MoonClaw AI semantic review result from \{run_id}.",
            generated_at_ms: @env.now(),
          }
          changed = true
        } else {
          let reconciled_run = stale_book_quality_review_run(
            run,
            root,
            home,
            now_ms=@env.now(),
          )
          if reconciled_run.status != run.status ||
            reconciled_run.summary != run.summary {
            changed = true
          }
          current = reconciled_run
        }
      }
      None => ()
    }
    reconciled.push(current)
  }
  if changed {
    write_text_file(
      run_path,
      BookQualityReviewRunLedger::{ runs: reconciled }
      .to_json()
      .stringify(indent=2),
    )
  }
  written
}

///|
fn corrected_terminal_book_quality_review_run(
  run : BookQualityReviewRun,
) -> BookQualityReviewRun {
  if run.summary.contains("Marked orphaned") {
    { ..run, status: "orphaned" }
  } else if run.summary.contains("MoonClaw AI review dispatch failed") {
    { ..run, status: "blocked" }
  } else if run.status == "dispatched" ||
    run.status == "queued" ||
    run.status == "running" {
    { ..run, status: "written" }
  } else {
    run
  }
}

///|
fn book_quality_review_stale_after_ms() -> UInt64 {
  600_000UL
}

///|
async fn stale_book_quality_review_run(
  run : BookQualityReviewRun,
  root : String,
  home : String,
  now_ms? : UInt64 = @env.now(),
) -> BookQualityReviewRun {
  match run.run_id {
    Some(run_id) => {
      if @moonclaw.run_process_alive(run_id) {
        return run
      }
      if run.status != "dispatched" &&
        run.status != "queued" &&
        run.status != "running" {
        return run
      }
      if now_ms < run.generated_at_ms + book_quality_review_stale_after_ms() {
        return run
      }
      let poll = @moonclaw.poll_run(
        "book-quality-ai-review-\{run.book_id}",
        run_id,
        cwd=root,
        home~,
      )
      {
        ..run,
        status: "orphaned",
        summary: if poll.summary.is_empty() {
          "MoonClaw AI semantic review run \{run_id} is stale, has no result artifact, and no live process was found; marked orphaned so governance can retry."
        } else {
          "\{poll.summary} Marked orphaned by Book Quality reconciliation because no result artifact was produced."
        },
        generated_at_ms: now_ms,
      }
    }
    None => run
  }
}

///|
pub async fn bootstrap_registered_book_workspaces(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  let operational = bootstrap_default_operational_books(book_catalog_path)
  ignore(bootstrap_moontown_cookbook(book_catalog_path~))
  ignore(bootstrap_moontown_planbook(book_catalog_path~))
  ignore(bootstrap_wenyu_game_design_course_book(book_catalog_path~))
  ignore(bootstrap_wenyu_civic_workspaces(book_catalog_path~))
  "Bootstrapped canonical registered MoonBook workspaces: operational=\{operational}, cookbook=1, planbook=1, course=1, civic=\{@civic.wenyu_civic_services().length()}."
}

///|
async fn bootstrap_default_operational_books(book_catalog_path : String) -> Int {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let mut count = 0
  for entry in catalog {
    match entry.id {
      "coding" => {
        write_default_operational_book_workspace(
          entry,
          "Coding Harness Book",
          "This MoonBook stores coding harness memory, review policy, repo-quality notes, and execution boundaries. It is an operational planning/memory book, not a generic research book.",
          ["repo-quality", "review", "implementation memory"],
        )
        count += 1
      }
      "finance" => {
        write_default_operational_book_workspace(
          entry,
          "Finance Operations Book",
          "This MoonBook stores private finance workflow memory, ledger procedures, review gates, and daily operating notes. It contains no seeded personal financial data.",
          ["ledger hygiene", "planning", "private review"],
        )
        count += 1
      }
      _ => ()
    }
  }
  count
}

///|
fn book_quality_review_result_dir_for_snapshot(
  snapshot_path : String,
) -> String {
  let base = @path.Path::dirname(snapshot_path).to_string()
  if base == "." || base == "" {
    default_book_quality_review_result_dir()
  } else {
    "\{base}/book-quality/ai-review-results"
  }
}

///|
async fn score_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let kind = book_quality_type(entry)
  match kind {
    "research-book" => score_research_book(entry, review_result_dir)
    "course-book" => score_course_book(entry, review_result_dir)
    "planbook" => score_planbook(entry, review_result_dir)
    "cookbook" => score_cookbook(entry, review_result_dir)
    "civic-protocol-support" => score_civic_book(entry, review_result_dir)
    "operational-book" => score_operational_book(entry, review_result_dir)
    _ => score_general_book(entry, review_result_dir)
  }
}

///|
fn book_quality_type(entry : @moonbook.BookCatalogEntry) -> String {
  if entry.tags.contains("cookbook") || entry.id.contains("cookbook") {
    return "cookbook"
  }
  if entry.tags.contains("planbook") || entry.id.has_prefix("plan-") {
    return "planbook"
  }
  if entry.tags.contains("course") ||
    entry.id.has_prefix("course-") ||
    entry.name.to_lower().contains("course") {
    return "course-book"
  }
  if entry.tags.contains("research") ||
    entry.id.has_prefix("research-") ||
    entry.name.to_lower().contains("research") {
    return "research-book"
  }
  if entry.tags.contains("civic-service") || entry.id.has_prefix("wenyu-") {
    return "civic-protocol-support"
  }
  if entry.id == "coding" ||
    entry.id == "finance" ||
    entry.tags.contains("operational") {
    return "operational-book"
  }
  "general-book"
}

///|
async fn score_research_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/research-question.md", 6, strengths, gaps,
  )
  score += path_score(root, "raw/bootstrap/search-log.md", 8, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/source-screen.md", 8, strengths, gaps,
  )
  score += path_score(
    root, "raw/bootstrap/evidence-matrix.md", 10, strengths, gaps,
  )
  score += path_score(root, "raw/bootstrap/deep-report.md", 12, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/marketing-brief.md", 5, strengths, gaps,
  )
  score += path_score(root, "wiki/index.md", 7, strengths, gaps)
  score += path_score(
    root, "book/site/generated/index.html", 6, strengths, gaps,
  )
  let words = word_count(
    read_text_or_empty("\{root}/raw/bootstrap/deep-report.md"),
  )
  if words >= 12000 {
    score += 18
    strengths.push("deep report reaches 12k+ words")
  } else if words >= 8000 {
    score += 12
    gaps.push("deep report below world-class 12k word target")
  } else if words >= 2000 {
    score += 6
    gaps.push("deep report is useful but too short for deep research")
  } else {
    gaps.push("deep report is missing or shallow")
  }
  finalize_score(
    entry, "research-book", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/COURSE_CONTRACT.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "raw/bootstrap/course-outline.md", 10, strengths, gaps,
  )
  score += path_score(
    root, "raw/bootstrap/source-material.md", 4, strengths, gaps,
  )
  score += path_score(
    root, "wiki/course/beginner-course.md", 16, strengths, gaps,
  )
  score += path_score(root, "wiki/course/exercises.md", 10, strengths, gaps)
  score += path_score(
    root, "wiki/course/progress-rubric.md", 8, strengths, gaps,
  )
  score += path_score(
    root, "skills/course-builder/SKILL.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "book/site/generated/index.html", 6, strengths, gaps,
  )
  let index = read_text_or_empty("\{root}/wiki/index.md").to_lower()
  if index.contains("## research report") || entry.id.has_prefix("research-") {
    gaps.push("course still looks research-shaped in id or index")
  } else if index.contains("course book") ||
    index.contains("type: `course-book`") {
    score += 8
    strengths.push("course identity is explicit")
  }
  finalize_score(
    entry, "course-book", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_planbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/PLANBOOK_CONTRACT.md", 14, strengths, gaps,
  )
  score += path_score(
    root, "plans/2026-05-29-book-quality-upgrade/plan.md", 16, strengths, gaps,
  )
  score += path_score(root, "plans/index.md", 8, strengths, gaps)
  score += path_score(
    root, "wiki/planning/quality-gates.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "wiki/planning/execution-evidence.md", 10, strengths, gaps,
  )
  score += path_score(
    root, "wiki/reviews/active-plan-review.md", 10, strengths, gaps,
  )
  score += path_score(root, "wiki/history/decision-log.md", 8, strengths, gaps)
  score += path_score(root, "schemas/plan-record.schema.md", 6, strengths, gaps)
  score += path_score(root, "skills/code-plan/SKILL.md", 12, strengths, gaps)
  score += path_score(root, "skills/code-review/SKILL.md", 10, strengths, gaps)
  score += path_score(root, "skills/doc-sync/SKILL.md", 8, strengths, gaps)
  score += path_score(
    root, "book/site/generated/index.html", 6, strengths, gaps,
  )
  finalize_score(
    entry, "planbook", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_cookbook(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/COOKBOOK_CONTRACT.md", 14, strengths, gaps,
  )
  score += path_score(
    root, "wiki/definitions/stable-state.md", 16, strengths, gaps,
  )
  score += path_score(
    root, "wiki/definitions/ownership.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "wiki/definitions/book-types.md", 6, strengths, gaps,
  )
  score += path_score(
    root, "wiki/definitions/runtime-boundaries.md", 6, strengths, gaps,
  )
  score += path_score(
    root, "wiki/operating-procedures/doctor.md", 10, strengths, gaps,
  )
  score += path_score(
    root, "wiki/operating-procedures/book-governance.md", 6, strengths, gaps,
  )
  score += path_score(
    root, "wiki/history/stable-state-ledger.md", 6, strengths, gaps,
  )
  score += path_score(
    root, "schemas/stable-state-manifest.schema.md", 8, strengths, gaps,
  )
  score += path_score(
    root, "book/site/generated/index.html", 6, strengths, gaps,
  )
  if @fs.exists(".moontown/book-quality/audit.json") {
    score += 6
    strengths.push("book quality audit is linked into stable-state governance")
  } else {
    gaps.push("book quality audit has not been written yet")
  }
  finalize_score(
    entry, "cookbook", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md", 12, strengths, gaps,
  )
  score += path_score(
    root, "skills/wenyu-civic-service/SKILL.md", 10, strengths, gaps,
  )
  score += path_score(root, "moonclaw.jobs.json", 10, strengths, gaps)
  score += path_score(
    root, "book/site/generated/index.html", 6, strengths, gaps,
  )
  match @civic.wenyu_civic_service_for_book_id(entry.id) {
    Some(service) => {
      score += paths_score(root, service.schema_pages, 10, strengths, gaps)
      score += paths_score(root, service.wiki_pages, 10, strengths, gaps)
      score += paths_score(root, service.review_queues, 8, strengths, gaps)
      score += path_score(
        root, "wiki/ledgers/service-ledger.md", 5, strengths, gaps,
      )
      score += path_score(
        root, "wiki/ledgers/exchange-ledger.md", 5, strengths, gaps,
      )
      score += path_score(
        root, "wiki/history/service-history.md", 5, strengths, gaps,
      )
      score += path_score(root, service.skill_path, 10, strengths, gaps)
      let result_path = civic_service_result_path(service, root~)
      if @fs.exists(result_path) {
        score += 10
        strengths.push("latest civic service result exists")
      } else {
        gaps.push(
          "no latest civic service result; workspace is still mostly scaffold",
        )
      }
    }
    None => gaps.push("no civic service definition matched this book")
  }
  finalize_score(
    entry, "civic-protocol-support", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let mut score = base_workspace_score(root, strengths, gaps)
  score += path_score(
    root, "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", 18, strengths, gaps,
  )
  score += path_score(
    root, "wiki/operations/review-policy.md", 16, strengths, gaps,
  )
  score += path_score(root, "wiki/history/journey.md", 12, strengths, gaps)
  score += path_score(
    root, "skills/operational-keeper/SKILL.md", 16, strengths, gaps,
  )
  score += path_score(
    root, "book/site/generated/index.html", 10, strengths, gaps,
  )
  finalize_score(
    entry, "operational-book", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
  review_result_dir : String,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let score = base_workspace_score(root, strengths, gaps) +
    path_score(root, "wiki/index.md", 20, strengths, gaps) +
    path_score(root, "book/moonbook-ui-state.json", 15, strengths, gaps)
  finalize_score(
    entry, "general-book", root, score, strengths, gaps, review_result_dir,
  )
}

///|
async fn base_workspace_score(
  root : String,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  let mut score = 0
  if @fs.exists(root) {
    score += 12
    strengths.push("workspace exists")
  } else {
    gaps.push("workspace directory is missing")
  }
  if @fs.exists("\{root}/wiki/index.md") {
    score += 8
    strengths.push("wiki index exists")
  } else {
    gaps.push("missing wiki/index.md")
  }
  if @fs.exists("\{root}/book/moonbook-ui-state.json") {
    score += 8
    strengths.push("MoonBook projection state exists")
  } else {
    gaps.push("missing book/moonbook-ui-state.json")
  }
  score
}

///|
async fn path_score(
  root : String,
  relative : String,
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if @fs.exists("\{root}/\{relative}") {
    strengths.push("has `\{relative}`")
    points
  } else {
    gaps.push("missing `\{relative}`")
    0
  }
}

///|
async fn paths_score(
  root : String,
  relatives : Array[String],
  points : Int,
  strengths : Array[String],
  gaps : Array[String],
) -> Int {
  if relatives.is_empty() {
    return points
  }
  let missing : Array[String] = []
  for relative in relatives {
    if !@fs.exists("\{root}/\{relative}") {
      missing.push(relative)
    }
  }
  if missing.is_empty() {
    strengths.push("all \{relatives.length()} expected typed pages exist")
    points
  } else {
    let joined = missing.join(", ")
    gaps.push("missing typed pages: \{joined}")
    points * (relatives.length() - missing.length()) / relatives.length()
  }
}

///|
async fn finalize_score(
  entry : @moonbook.BookCatalogEntry,
  book_type : String,
  root : String,
  raw_score : Int,
  strengths : Array[String],
  gaps : Array[String],
  review_result_dir : String,
) -> BookQualityScore {
  let score = if gaps.is_empty() {
    clamp_score(raw_score)
  } else {
    clamp_score(raw_score).min(89)
  }
  let semantic = read_ai_quality_score(entry.id, review_result_dir)
  let semantic_grade = match semantic {
    Some(value) => quality_grade(value)
    None => "pending-ai-review"
  }
  let quality_status = match semantic {
    Some(_) => "ai-reviewed"
    None => "pending-ai-review"
  }
  {
    book_id: entry.id,
    title: entry.name,
    book_type,
    workspace_root: root,
    structural_score: score,
    structural_grade: quality_grade(score),
    semantic_score: semantic,
    semantic_grade,
    quality_status,
    score,
    grade: quality_grade(score),
    ready: score >= 80 &&
    gaps.is_empty() &&
    semantic_quality_allows_ready(semantic),
    strengths,
    gaps,
    next_action: next_book_quality_action(book_type, gaps, score, semantic),
  }
}

///|
fn semantic_quality_allows_ready(score : Int?) -> Bool {
  match score {
    Some(value) => value >= 80
    None => true
  }
}

///|
async fn write_default_operational_book_workspace(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
  focus : Array[String],
) -> Unit {
  let root = @moonbook.workspace_root(entry)
  write_text_file(
    "\{root}/wiki/index.md",
    default_operational_index(entry, title, summary, focus),
  )
  write_text_file(
    "\{root}/raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md",
    default_operational_contract(title),
  )
  write_text_file(
    "\{root}/wiki/operations/review-policy.md",
    default_operational_review_policy(title),
  )
  write_text_file(
    "\{root}/wiki/history/journey.md",
    default_operational_journey(title),
  )
  write_text_file(
    "\{root}/skills/operational-keeper/SKILL.md",
    default_operational_skill(title),
  )
  write_text_file(
    "\{root}/book/moonbook-ui-state.json",
    default_operational_ui_state(entry, title, summary),
  )
  let html = default_operational_site(entry, title, summary)
  write_text_file("\{root}/book/Home.html", html)
  write_text_file("\{root}/book/site/generated/index.html", html)
}

///|
fn default_operational_index(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
  focus : Array[String],
) -> String {
  [
    "# \{title}",
    "",
    summary,
    "",
    "## Book",
    "",
    "- Book id: `\{entry.id}`",
    "- Workspace: `\{entry.workspace_root}`",
    "- Type: `operational-book`",
    "",
    "## Focus",
    "",
    markdown_bullets(focus),
    "",
    "## Start Here",
    "",
    "- `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md`",
    "- `wiki/operations/review-policy.md`",
    "- `wiki/history/journey.md`",
    "- `skills/operational-keeper/SKILL.md`",
  ].join("\n")
}

///|
fn default_operational_contract(title : String) -> String {
  [
    "# \{title} Contract",
    "",
    "This operational book preserves workspace memory, review rules, and safe execution boundaries.",
    "",
    "## Rules",
    "",
    "- Do not invent external facts.",
    "- Do not store sensitive user data unless explicitly provided and scoped.",
    "- Keep operational records separate from domain evidence.",
    "- Prefer small reviewed changes and durable journey notes.",
  ].join("\n")
}

///|
fn default_operational_review_policy(title : String) -> String {
  [
    "# \{title} Review Policy",
    "",
    "- Queue review when a change affects external systems, private data, money, or repo quality gates.",
    "- Record validation evidence before marking a task complete.",
    "- Preserve a short journey note for material decisions.",
  ].join("\n")
}

///|
fn default_operational_journey(title : String) -> String {
  [
    "# \{title} Journey",
    "",
    "| Date | Event | Evidence |",
    "| --- | --- | --- |",
    "| bootstrap | Created operational MoonBook workspace | `raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md` |",
  ].join("\n")
}

///|
fn default_operational_skill(title : String) -> String {
  [
    "---",
    "name: operational-keeper",
    "description: Maintain an operational MoonBook workspace with review policy, journey notes, and safe execution boundaries.",
    "---",
    "",
    "# Operational Keeper Skill",
    "",
    "Operate `\{title}` as durable workspace memory.",
    "",
    "## Rules",
    "",
    "- Read the book contract before updating memory.",
    "- Separate operational records from domain facts.",
    "- Write concise journey notes for material decisions.",
    "- Queue review for sensitive, financial, external, or code-quality-impacting changes.",
    "",
    "## Concrete Example",
    "",
    "```md",
    "operational_decision: update",
    "book_changed: yes",
    "review_required: no",
    "summary: Added a validated review policy note and linked the validation evidence.",
    "```",
  ].join("\n")
}

///|
fn default_operational_ui_state(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
) -> String {
  [
    "{",
    "  \"book_id\": \{json_string(entry.id)},",
    "  \"title\": \{json_string(title)},",
    "  \"summary\": \{json_string(summary)},",
    "  \"status_chips\": [",
    "    {\"label\":\"operational-book\",\"tone\":\"healthy\"},",
    "    {\"label\":\"review-gated\",\"tone\":\"review\"}",
    "  ],",
    "  \"metrics\": [",
    "    {\"label\":\"Contracts\",\"value\":\"1\",\"note\":\"operational contract\",\"tone\":\"healthy\"},",
    "    {\"label\":\"Skills\",\"value\":\"1\",\"note\":\"operational keeper\",\"tone\":\"healthy\"}",
    "  ],",
    "  \"readiness\": [",
    "    {\"title\":\"Operational contract\",\"detail\":\"raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md\",\"meta\":\"Ready\"}",
    "  ],",
    "  \"review_queue\": [],",
    "  \"page_families\": [",
    "    {\"title\":\"Review policy\",\"detail\":\"wiki/operations/review-policy.md\",\"meta\":\"Operations\"}",
    "  ],",
    "  \"journey\": [",
    "    {\"title\":\"Operational bootstrap\",\"stage\":\"generated\",\"status\":\"ready\",\"summary\":\"MoonBook workspace created for registered operational book.\",\"highlights\":[]}",
    "  ]",
    "}",
  ].join("\n")
}

///|
fn default_operational_site(
  entry : @moonbook.BookCatalogEntry,
  title : String,
  summary : String,
) -> String {
  [
    "<!doctype html><html><head><meta charset=\"utf-8\"><meta name=\"viewport\" content=\"width=device-width,initial-scale=1\"><title>\{html_escape(title)}</title>",
    "<style>body{margin:0;background:#f3efe3;color:#1f2e2a;font-family:Georgia,serif}main{max-width:900px;margin:auto;padding:48px 24px}.hero{padding:30px;border-radius:24px;background:#fffaf0;border:1px solid #c8b98d}code{background:#e8dec3;padding:2px 6px;border-radius:6px}</style></head><body><main>",
    "<section class=\"hero\"><p>MoonBook operational workspace</p><h1>\{html_escape(title)}</h1><p>\{html_escape(summary)}</p><p><code>\{html_escape(entry.workspace_root)}</code></p></section>",
    "</main></body></html>",
  ].join("\n")
}

///|
fn clamp_score(score : Int) -> Int {
  if score < 0 {
    0
  } else if score > 100 {
    100
  } else {
    score
  }
}

///|
fn quality_grade(score : Int) -> String {
  if score >= 95 {
    "world-class"
  } else if score >= 90 {
    "excellent"
  } else if score >= 80 {
    "strong"
  } else if score >= 65 {
    "usable"
  } else if score >= 45 {
    "weak"
  } else {
    "not-managed"
  }
}

///|
fn next_book_quality_action(
  book_type : String,
  gaps : Array[String],
  score : Int,
  semantic_score : Int?,
) -> String {
  match semantic_score {
    Some(value) if value < 80 =>
      return "Use the AI semantic review to repair real book quality, not just structure."
    _ => ()
  }
  if gaps.is_empty() && score >= 90 {
    "Keep running standing review; no immediate repair."
  } else {
    match book_type {
      "research-book" =>
        "Run a research quality review and repair source depth, evidence matrix, report length, and generated projection."
      "course-book" =>
        "Run course projection repair: enforce course identity, lesson progression, exercises, checkpoints, and beginner usability."
      "planbook" =>
        "Bootstrap or repair plan contract, code-plan skill, acceptance gates, and execution evidence."
      "cookbook" =>
        "Refresh cookbook bootstrap and include latest docs, definitions, runtime state, and book-quality audit."
      "civic-protocol-support" =>
        "Run one protocol-native loop: inbox/contribution -> reduction -> review -> accepted distribution, then persist only the support records required by the building persistence mode."
      "operational-book" =>
        "Run an operational keeper review: validate safe memory, review policy, journey notes, and sensitive-boundary handling."
      _ =>
        "Bootstrap a typed MoonBook workspace or remove placeholder catalog entry."
    }
  }
}

///|
fn book_quality_review_packet(
  score : BookQualityScore,
  review_dir : String,
) -> BookQualityReviewPacket {
  {
    book_id: score.book_id,
    book_type: score.book_type,
    workspace_root: score.workspace_root,
    structural_score: score.structural_score,
    review_skill_path: "\{review_dir}/BOOK_QUALITY_REVIEW_SKILL.md",
    context_pages: book_quality_context_pages(score),
    prompt: book_quality_review_prompt(score),
    output_contract: "moontown.book_quality.ai_review.v1",
  }
}

///|
fn book_quality_context_pages(score : BookQualityScore) -> Array[String] {
  match score.book_type {
    "research-book" =>
      [
        "wiki/index.md", "raw/bootstrap/research-question.md", "raw/bootstrap/source-screen.md",
        "raw/bootstrap/evidence-matrix.md", "raw/bootstrap/deep-report.md", "book/site/generated/index.html",
      ]
    "course-book" =>
      [
        "wiki/index.md", "raw/bootstrap/COURSE_CONTRACT.md", "wiki/course/beginner-course.md",
        "wiki/course/exercises.md", "skills/course-builder/SKILL.md", "book/site/generated/index.html",
      ]
    "planbook" =>
      [
        "wiki/index.md", "raw/bootstrap/PLANBOOK_CONTRACT.md", "plans/2026-05-29-book-quality-upgrade/plan.md",
        "skills/code-plan/SKILL.md", "book/site/generated/index.html",
      ]
    "cookbook" =>
      [
        "wiki/index.md", "raw/bootstrap/COOKBOOK_CONTRACT.md", "wiki/definitions/stable-state.md",
        "wiki/definitions/ownership.md", "book/site/generated/index.html",
      ]
    "civic-protocol-support" =>
      [
        "wiki/index.md", "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", "raw/bootstrap/BUILDING_PROTOCOL_CONTRACT.md",
        "skills/wenyu-civic-service/SKILL.md", "wiki/ledgers/service-ledger.md",
        "wiki/ledgers/exchange-ledger.md", "wiki/history/service-history.md", "book/site/generated/index.html",
      ]
    "operational-book" =>
      [
        "wiki/index.md", "raw/bootstrap/OPERATIONAL_BOOK_CONTRACT.md", "wiki/operations/review-policy.md",
        "wiki/history/journey.md", "skills/operational-keeper/SKILL.md", "book/site/generated/index.html",
      ]
    _ => ["wiki/index.md", "book/moonbook-ui-state.json"]
  }
}

///|
fn book_quality_review_prompt(score : BookQualityScore) -> String {
  [
    "Review MoonBook workspace `\{score.book_id}` as a `\{score.book_type}`.",
    "",
    "Structural readiness score is `\{score.structural_score}`. Do not blindly accept it as quality. Structural readiness only proves that expected files exist. Use the book's own contracts and skills to judge real quality.",
    "",
    "Judge:",
    "- usefulness to its intended user",
    "- correctness and evidence discipline",
    "- originality, imagination, curiosity, and judgment where appropriate",
    "- whether the book is using the right genre instead of leaking research/course/civic/plan behavior",
    "- whether operational evidence is separated from domain/service evidence",
    "- whether generated site/projection is meaningful enough to use",
    "",
    "Return the exact output contract from `BOOK_QUALITY_REVIEW_SKILL.md`.",
  ].join("\n")
}

///|
fn book_quality_ai_review_skill_markdown() -> String {
  [
    "# Book Quality AI Review Skill", "", "This review is the semantic judge above Moontown's structural doctor.",
    "", "## Rule", "", "Do not score a book as world-class just because files exist. Read the book's own contract and skill files, then decide whether the book genuinely performs its role.",
    "", "## Genre-Specific Quality", "", "- Research: evidence quality, source diversity, synthesis depth, uncertainty handling, insight, and report/projection usefulness.",
    "- Course: beginner progression, exercises, checkpoints, examples, and ability to teach judgment.",
    "- Planbook: repository-specific plan quality, acceptance criteria, validation, rollback, and resumability.",
    "- Cookbook: stable-state coverage, ownership clarity, drift accounting, and operator usefulness.",
    "- Civic service: building protocol behavior, service-native workflow, review gates, ledger/projection usefulness, and no forced research genre.",
    "- Operational: safe memory, review policy, journey trace, and sensitive-boundary discipline.",
    "", "## Output Contract", "", "```md", "ai_quality_score: <0-100>", "ai_quality_grade: world-class | excellent | strong | usable | weak | not-managed",
    "book_role_fit: excellent | acceptable | wrong-genre", "semantic_gaps:", "- <gap>",
    "best_strengths:", "- <strength>", "repair_owner: moontown | moonbook | moonclaw | moondesk | mixed",
    "next_repair_task: <one concrete task>", "projection_quality: excellent | acceptable | weak",
    "evidence_accounting_ok: yes | no", "```", "", "## Concrete Example", "", "```md",
    "ai_quality_score: 72", "ai_quality_grade: usable", "book_role_fit: acceptable",
    "semantic_gaps:", "- Civic workspace has contracts but no accepted service result, so it is not yet proven operationally.",
    "best_strengths:", "- Building protocol and module-specific skill are clear.",
    "repair_owner: mixed", "next_repair_task: Run one service-native exchange/reduction/review loop and update the projection with accepted output.",
    "projection_quality: acceptable", "evidence_accounting_ok: yes", "```",
  ].join("\n")
}

///|
fn book_quality_review_readme(
  audit : BookQualityAudit,
  packets : Array[BookQualityReviewPacket],
) -> String {
  let rows : Array[String] = [
    "| Book | Type | Structural Score | Packet |", "| --- | --- | ---: | --- |",
  ]
  for packet in packets {
    rows.push(
      "|\{packet.book_id}|\{packet.book_type}|\{packet.structural_score}|`\{packet.book_id}.json`|",
    )
  }
  [
    "# AI Book Quality Review Packets",
    "",
    "These packets are the semantic quality layer above `.moontown/book-quality/audit.json`.",
    "",
    "The structural doctor is deliberately deterministic. It checks existence, contracts, and routing shape. These packets should be sent to MoonClaw/MoonBook so an AI reviewer can judge whether each book is actually useful, insightful, correct, and genre-appropriate.",
    "",
    "- Total packets: `\{packets.length()}`",
    "- Weakest structural book: `\{audit.weakest_book_id}` (`\{audit.weakest_score}`)",
    "",
    rows.join("\n"),
  ].join("\n")
}

///|
async fn first_pending_ai_review_book(
  audit : BookQualityAudit,
  result_dir : String,
) -> BookQualityScore? {
  let mut candidate : BookQualityScore? = None
  for score in audit.scores {
    if @fs.exists("\{result_dir}/\{score.book_id}.md") {
      continue
    }
    match candidate {
      Some(current) if current.structural_score <= score.structural_score => ()
      _ => candidate = Some(score)
    }
  }
  candidate
}

///|
fn book_quality_external_review_packet(
  packet : BookQualityReviewPacket,
  result_dir : String,
) -> @moonclaw.ExternalProposalPacket {
  let root = absolute_path(packet.workspace_root)
  let context_pages : Array[String] = []
  for page in packet.context_pages {
    context_pages.push(@path.Path(root).join(@path.Path(page)).to_string())
  }
  let skill_path = absolute_path(packet.review_skill_path)
  @moonclaw.ExternalProposalPacket::new(
    packet_id="book-quality-ai-review-\{packet.book_id}",
    title="AI semantic quality review: \{packet.book_id}",
    summary="Semantic quality review for MoonBook `\{packet.book_id}`.",
    request_text=book_quality_external_review_request(packet, result_dir),
    profile="book_quality_ai_reviewer",
    output_contract=packet.output_contract,
    context_pages~,
    skill_paths=[skill_path],
    notes=[
      "This is a semantic review, not a structural existence check.", "Do not modify the book workspace; return the required review contract.",
      "Do not inflate score for operational logs or scaffolding.",
    ],
    tags=["book-quality", "ai-review", packet.book_type, packet.book_id],
    metadata={
      "producer": "moontown".to_json(),
      "book_id": packet.book_id.to_json(),
      "book_type": packet.book_type.to_json(),
      "result_path": "\{result_dir}/\{packet.book_id}.md".to_json(),
      "disable_waiting_for_input": true.to_json(),
      "best_effort_on_missing_input": true.to_json(),
      "profile_metadata": {
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
      "step_metadata": {
        "kind": "book_quality_ai_review".to_json(),
        "execution_mode": "acp".to_json(),
        "execution_target": "codex-main".to_json(),
        "output_contract": packet.output_contract.to_json(),
        "preferred_skills": ["book-quality-ai-review"].to_json(),
        "disable_waiting_for_input": true.to_json(),
        "best_effort_on_missing_input": true.to_json(),
      },
    },
  )
}

///|
fn book_quality_external_review_request(
  packet : BookQualityReviewPacket,
  result_dir : String,
) -> String {
  [
    "You are the MoonBook semantic quality reviewer for Moontown.",
    "",
    "Book id: `\{packet.book_id}`",
    "Book type: `\{packet.book_type}`",
    "Workspace root: `\{absolute_path(packet.workspace_root)}`",
    "Structural score: `\{packet.structural_score}`",
    "Result target after reconciliation: `\{result_dir}/\{packet.book_id}.md`",
    "",
    "Task:",
    "1. Read the review skill and the listed context pages.",
    "2. Judge the book's real quality for its role, not file completeness.",
    "3. Separate domain/service evidence from operational logs and scaffolding.",
    "4. Return exactly the `moontown.book_quality.ai_review.v1` Markdown contract.",
    "5. Do not write repository files directly; Moontown will reconcile your returned contract into the durable result path.",
    "",
    packet.prompt,
  ].join("\n")
}

///|
async fn write_book_quality_review_moonclaw_profile(
  review_dir : String,
) -> Unit {
  let root = book_quality_review_root(review_dir)
  write_text_file(
    "\{root}/moonclaw.jobs.json",
    book_quality_review_moonclaw_profile_json().stringify(indent=2),
  )
  let home = "\{root}/.moonclaw"
  let config_path = "\{home}/moonclaw.json"
  write_text_file(
    config_path,
    book_quality_review_acp_config_json().stringify(indent=2),
  )
}

///|
fn book_quality_review_moonclaw_profile_json() -> Json {
  {
    "jobs": {
      "profiles": {
        "book_quality_ai_reviewer": {
          "family": "book_quality_ai_reviewer",
          "role": "reviewer",
          "priority": 170,
          "tags": ["book-quality", "ai-review", "semantic-review"],
          "match": {
            "all": ["book-quality", "ai-review"],
            "any": [
              "research-book", "course-book", "planbook", "cookbook", "civic-protocol-support",
              "operational-book",
            ],
          },
          "steps": [
            {
              "id": "review_book_semantic_quality",
              "title": "Review one MoonBook workspace for real semantic quality",
              "kind": "job.analysis",
              "prompt_template": "Read ${proposal.request_text}. Read all absolute context_pages and skill_paths. Return exactly the requested book quality AI review contract. Do not write files.",
              "metadata": {
                "preferred_skills": ["book-quality-ai-review"],
                "enable_tools": true,
                "execution_mode": "acp",
                "execution_target": "codex-main",
                "output_contract": "moontown.book_quality.ai_review.v1",
                "disable_waiting_for_input": true,
                "best_effort_on_missing_input": true,
                "role_runtime": {
                  "planning_layer": "town-quality-governance",
                  "runtime_mode": "semantic-review",
                  "tool_access": "workspace-read",
                  "memory_scope": "book-quality",
                  "allow_delegate": false,
                  "allow_workspace_write": false,
                  "allow_execution_tools": true,
                  "output_contract": "moontown.book_quality.ai_review.v1",
                },
              },
            },
          ],
        },
      },
    },
  }
}

///|
fn book_quality_review_acp_config_json() -> Json {
  let root = absolute_path(".")
  {
    "acp": {
      "targets": {
        "codex-main": {
          "backend": "codex",
          "label": "Codex Book Quality Reviewer",
          "cwd": root,
          "workspace": root,
          "command": resolved_codex_command(),
          "args": resolved_codex_args(),
          "model": "gpt-5",
        },
      },
    },
  }
}

///|
fn book_quality_external_packet_path(
  review_dir : String,
  book_id : String,
) -> String {
  "\{book_quality_review_root(review_dir)}/moonclaw-packets/book-quality-ai-review-\{book_id}.json"
}

///|
fn book_quality_review_root(review_dir : String) -> String {
  if review_dir.has_suffix("/ai-review-packets") {
    review_dir[:review_dir.length() - "/ai-review-packets".length()].to_owned()
  } else {
    ".moontown/book-quality"
  }
}

///|
fn book_quality_review_root_from_run_path(run_path : String) -> String {
  if run_path.has_suffix("/ai-review-runs.json") {
    run_path[:run_path.length() - "/ai-review-runs.json".length()].to_owned()
  } else {
    ".moontown/book-quality"
  }
}

///|
fn book_quality_moonclaw_home(review_dir : String) -> String {
  ignore(review_dir)
  ".moonclaw"
}

///|
fn book_quality_moonclaw_home_from_run_path(run_path : String) -> String {
  ignore(run_path)
  ".moonclaw"
}

///|
async fn append_book_quality_review_run(
  run_path : String,
  run : BookQualityReviewRun,
) -> Unit {
  let ledger = load_book_quality_review_run_ledger(run_path)
  let runs : Array[BookQualityReviewRun] = []
  for existing in ledger.runs {
    if existing.book_id != run.book_id || existing.run_id != run.run_id {
      runs.push(existing)
    }
  }
  runs.push(run)
  write_text_file(
    run_path,
    BookQualityReviewRunLedger::{ runs, }.to_json().stringify(indent=2),
  )
}

///|
async fn load_book_quality_review_run_ledger(
  run_path : String,
) -> BookQualityReviewRunLedger {
  if !@fs.exists(run_path) {
    return { runs: [] }
  }
  let parsed = @json.parse(@fs.read_file(run_path).text()) catch {
    _ => return { runs: [] }
  }
  @json.from_json(parsed) catch {
    _ => { runs: [] }
  }
}

///|
async fn book_quality_review_result_content_from_run(
  run_id : String,
  cwd : String,
  home : String,
) -> String {
  let workspace_dir = match @moonclaw.run_workspace_dir(run_id, cwd~, home~) {
    Some(workspace_dir) => workspace_dir
    None => return ""
  }
  let result_path = "\{workspace_dir}/result.json"
  if !@fs.exists(result_path) {
    return ""
  }
  let parsed = @json.parse(@fs.read_file(result_path).text()) catch {
    _ => return ""
  }
  book_quality_json_string_field(parsed, "content").unwrap_or(
    book_quality_json_string_field(parsed, "summary").unwrap_or(""),
  )
}

///|
fn book_quality_json_string_field(value : Json, key : String) -> String? {
  match value {
    Object(object) =>
      match object.get(key) {
        Some(String(text)) => Some(text)
        _ => None
      }
    _ => None
  }
}

///|
fn absolute_path(path : String) -> String {
  if path.has_prefix("/") {
    path
  } else {
    match @env.current_dir() {
      Some(dir) => @path.Path(dir).join(@path.Path(path)).to_string()
      None => path
    }
  }
}

///|
fn markdown_inline(text : String) -> String {
  text.replace(old="\n", new=" ").replace(old="|", new="\\|")
}

///|
fn weakest_score(scores : Array[BookQualityScore]) -> BookQualityScore? {
  let mut weakest : BookQualityScore? = None
  for score in scores {
    match weakest {
      Some(current) if current.score <= score.score => ()
      _ => weakest = Some(score)
    }
  }
  weakest
}

///|
fn word_count(text : String) -> Int {
  let mut count = 0
  let mut in_word = false
  for char in text {
    let is_word = (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9')
    if is_word && !in_word {
      count += 1
    }
    in_word = is_word
  }
  count
}

///|
fn render_book_quality_audit(audit : BookQualityAudit) -> String {
  let builder = StringBuilder::new()
  builder.write_string("# MoonBook Management And Quality Audit\n\n")
  builder.write_string(
    "Total: \{audit.total}; structurally ready: \{audit.ready_count}; structurally excellent: \{audit.world_class_count}; weakest structural book: `\{audit.weakest_book_id}` (\{audit.weakest_score}).\n\n",
  )
  builder.write_string(
    "Important: structural readiness is not book quality. Real quality must come from AI semantic review results written under `\{default_book_quality_review_result_dir()}/<book-id>.md`.\n\n",
  )
  builder.write_string(
    "| Book | Type | Structural readiness | AI quality | Quality status | Ready | Next action |\n",
  )
  builder.write_string("| --- | --- | ---: | --- | --- | ---: | --- |\n")
  for score in audit.scores {
    let ai_quality = match score.semantic_score {
      Some(value) => "\{value} / \{score.semantic_grade}"
      None => "pending"
    }
    builder.write_string(
      "|\{score.book_id}|\{score.book_type}|\{score.structural_score} / \{score.structural_grade}|\{ai_quality}|\{score.quality_status}|\{score.ready}|\{score.next_action}|\n",
    )
  }
  builder.write_string("\n## Gaps By Book\n\n")
  for score in audit.scores {
    builder.write_string("### \{score.book_id}\n\n")
    if score.gaps.is_empty() {
      builder.write_string("- none\n\n")
    } else {
      builder.write_string(markdown_bullets(score.gaps))
      builder.write_string("\n\n")
    }
  }
  builder.to_string()
}

///|
async fn read_ai_quality_score(book_id : String, result_dir : String) -> Int? {
  let path = "\{result_dir}/\{book_id}.md"
  let text = read_text_or_empty(path)
  if text.is_empty() {
    return None
  }
  parse_ai_quality_score(text)
}

///|
fn parse_ai_quality_score(text : String) -> Int? {
  for raw in text.split("\n") {
    let line = raw.trim()
    let owned = line.to_owned()
    let lower = owned.to_lower()
    if lower.has_prefix("ai_quality_score:") {
      return first_int(owned)
    }
    if lower.has_prefix("\"ai_quality_score\"") {
      return first_int(owned)
    }
  }
  None
}

///|
fn first_int(text : String) -> Int? {
  let mut value = 0
  let mut seen = false
  for char in text {
    if char >= '0' && char <= '9' {
      seen = true
      value = value * 10 + (char.to_int() - '0'.to_int())
    } else if seen {
      return Some(value)
    }
  }
  if seen {
    Some(value)
  } else {
    None
  }
}

///|
fn book_quality_markdown_path(audit_path : String) -> String {
  if audit_path.has_suffix(".json") {
    "\{audit_path[:audit_path.length() - 5]}.md"
  } else {
    "\{audit_path}.md"
  }
}
