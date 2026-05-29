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
pub async fn inspect_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> BookQualityAudit {
  let catalog = @moonbook.load_or_create_catalog(path=book_catalog_path)
  let scores : Array[BookQualityScore] = []
  for entry in catalog {
    scores.push(score_book(entry))
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
pub async fn render_book_quality(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
) -> String {
  render_book_quality_audit(inspect_book_quality(book_catalog_path~))
}

///|
pub async fn write_book_quality_audit(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  audit_path? : String = default_book_quality_audit_path(),
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~)
  write_text_file(audit_path, audit.to_json().stringify(indent=2))
  let markdown_path = book_quality_markdown_path(audit_path)
  write_text_file(markdown_path, render_book_quality_audit(audit))
  "Wrote book management audit for \{audit.total} registered book(s) to \{audit_path} and \{markdown_path}; weakest_structural=\{audit.weakest_book_id}(\{audit.weakest_score}). Semantic quality scores require AI review results."
}

///|
pub async fn write_book_quality_review_packets(
  book_catalog_path? : String = @moonbook.default_catalog_path(),
  review_dir? : String = default_book_quality_review_dir(),
) -> String {
  ignore(bootstrap_default_operational_books(book_catalog_path))
  let audit = inspect_book_quality(book_catalog_path~)
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
async fn score_book(entry : @moonbook.BookCatalogEntry) -> BookQualityScore {
  let kind = book_quality_type(entry)
  match kind {
    "research-book" => score_research_book(entry)
    "course-book" => score_course_book(entry)
    "planbook" => score_planbook(entry)
    "cookbook" => score_cookbook(entry)
    "civic-protocol-support" => score_civic_book(entry)
    "operational-book" => score_operational_book(entry)
    _ => score_general_book(entry)
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
  finalize_score(entry, "research-book", root, score, strengths, gaps)
}

///|
async fn score_course_book(
  entry : @moonbook.BookCatalogEntry,
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
  finalize_score(entry, "course-book", root, score, strengths, gaps)
}

///|
async fn score_planbook(entry : @moonbook.BookCatalogEntry) -> BookQualityScore {
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
  finalize_score(entry, "planbook", root, score, strengths, gaps)
}

///|
async fn score_cookbook(entry : @moonbook.BookCatalogEntry) -> BookQualityScore {
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
  finalize_score(entry, "cookbook", root, score, strengths, gaps)
}

///|
async fn score_civic_book(
  entry : @moonbook.BookCatalogEntry,
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
      let result_path = ".moontown/book-results/goal-\{service.book_id}-civic-service.json"
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
  finalize_score(entry, "civic-protocol-support", root, score, strengths, gaps)
}

///|
async fn score_operational_book(
  entry : @moonbook.BookCatalogEntry,
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
  finalize_score(entry, "operational-book", root, score, strengths, gaps)
}

///|
async fn score_general_book(
  entry : @moonbook.BookCatalogEntry,
) -> BookQualityScore {
  let root = @moonbook.workspace_root(entry)
  let strengths : Array[String] = []
  let gaps : Array[String] = []
  let score = base_workspace_score(root, strengths, gaps) +
    path_score(root, "wiki/index.md", 20, strengths, gaps) +
    path_score(root, "book/moonbook-ui-state.json", 15, strengths, gaps)
  finalize_score(entry, "general-book", root, score, strengths, gaps)
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
) -> BookQualityScore {
  let score = if gaps.is_empty() {
    clamp_score(raw_score)
  } else {
    clamp_score(raw_score).min(89)
  }
  let semantic = read_ai_quality_score(entry.id)
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
    ready: score >= 80 && gaps.is_empty(),
    strengths,
    gaps,
    next_action: next_book_quality_action(book_type, gaps, score),
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
) -> String {
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
async fn read_ai_quality_score(book_id : String) -> Int? {
  let path = "\{default_book_quality_review_result_dir()}/\{book_id}.md"
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
