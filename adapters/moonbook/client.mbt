///|
pub struct BookCatalogEntry {
  id : String
  name : String
  purpose : String
  workspace_root : String
  memory_scope : @core.MemoryScope
  tags : Array[String]
  skills : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn BookCatalogEntry::new(
  id~ : String,
  name~ : String,
  purpose~ : String,
  workspace_root~ : String,
  memory_scope? : @core.MemoryScope = @core.MemoryScope::BookPrivate,
  tags? : Array[String] = [],
  skills? : Array[String] = [],
) -> BookCatalogEntry {
  BookCatalogEntry::{
    id,
    name,
    purpose,
    workspace_root,
    memory_scope,
    tags,
    skills,
  }
}

///|
pub fn BookCatalogEntry::to_book_ref(self : BookCatalogEntry) -> @core.BookRef {
  @core.BookRef::new(
    id=self.id,
    name=self.name,
    purpose=self.purpose,
    workspace_root=self.workspace_root,
    memory_scope=self.memory_scope,
    tags=self.tags,
  )
}

///|
pub struct MoonbookCatalogProvider {
  catalog : Array[BookCatalogEntry]
} derive(Show, Eq)

///|
pub fn MoonbookCatalogProvider::new(
  catalog : Array[BookCatalogEntry],
) -> MoonbookCatalogProvider {
  MoonbookCatalogProvider::{ catalog, }
}

///|
pub fn MoonbookCatalogProvider::book_refs(
  self : MoonbookCatalogProvider,
) -> Array[@core.BookRef] {
  catalog_to_book_refs(self.catalog)
}

///|
pub impl @core.BookProvider for MoonbookCatalogProvider with books(
  self : MoonbookCatalogProvider,
) -> Array[@core.BookRef] {
  self.book_refs()
}

///|
pub fn default_catalog() -> Array[BookCatalogEntry] {
  [
    BookCatalogEntry::new(
      id="coding",
      name="Moonbook / Coding",
      purpose="Harness engineering for source work, repo memory, and execution policy.",
      workspace_root="/workspace/coding",
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["moonbit", "git", "review"],
      skills=["analysis", "memory", "review"],
    ),
    BookCatalogEntry::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root="/workspace/finance",
      memory_scope=@core.MemoryScope::TaskEphemeral,
      tags=["ledger", "planning", "ops"],
      skills=["planning", "memory", "reporting"],
    ),
  ]
}

///|
pub fn default_catalog_path() -> String {
  ".moontown/moonbooks.json"
}

///|
pub fn catalog_to_book_refs(
  catalog : Array[BookCatalogEntry],
) -> Array[@core.BookRef] {
  let books = []
  for entry in catalog {
    books.push(entry.to_book_ref())
  }
  books
}

///|
pub fn find_catalog_entry(
  catalog : Array[BookCatalogEntry],
  book_id : String,
) -> BookCatalogEntry? {
  for entry in catalog {
    if entry.id == book_id {
      return Some(entry)
    }
  }
  None
}

///|
pub async fn save_catalog_file(
  path : String,
  catalog : Array[BookCatalogEntry],
) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(catalog.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
pub async fn load_catalog_file(path : String) -> Array[BookCatalogEntry]? {
  if !@fs.exists(path) {
    return None
  }
  let text = @fs.read_file(path).text()
  let parsed = @json.parse(text) catch { _ => return None }
  Some(@json.from_json(parsed) catch { _ => return None })
}

///|
pub async fn load_or_create_catalog(
  path? : String = default_catalog_path(),
) -> Array[BookCatalogEntry] {
  match load_catalog_file(path) {
    Some(catalog) => catalog
    None => {
      let catalog = default_catalog()
      save_catalog_file(path, catalog)
      catalog
    }
  }
}

///|
pub async fn load_or_create_provider(
  path? : String = default_catalog_path(),
) -> MoonbookCatalogProvider {
  MoonbookCatalogProvider::new(load_or_create_catalog(path~))
}

///|
pub struct BookTask {
  id : String
  title : String
  kind : String
  prompt : String
  priority : Int
  requires_review : Bool
  target_pages : Array[String]
  required_role : @core.WorkerRole?
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookTaskBatch {
  goal_id : String
  goal : String
  summary : String
  tasks : Array[BookTask]
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookGoalAcceptance {
  goal_id : String
  accepted : Bool
  reason : String
  task_count : Int
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct WorkerContextBundle {
  book_id : String
  workspace_root : String
  task_id : String
  prompt : String
  policy : Array[String]
  routines : Array[String]
  skill_paths : Array[String]
  context_pages : Array[String]
  active_memory : Array[String]
  user_memory : Array[String]
  working_memory : Array[String]
  memory_summary : String
  output_contract : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct MemoryCandidate {
  kind : String
  title : String
  detail : String
  durable : Bool
  target_page : String?
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookResult {
  task_id : String
  summary : String
  artifacts : Array[String]
  memory_candidates : Array[MemoryCandidate]
  requires_review : Bool
  notify_town : Bool
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct PersistResultOutcome {
  log_path : String
  updated_pages : Array[String]
  review_queued : Bool
  notify_town : Bool
  evidence_id : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookStateSummary {
  book_id : String
  root : String
  page_count : Int
  source_count : Int
  entity_count : Int
  concept_count : Int
  pending_review_count : Int
  keeper_memory_count : Int
  keeper_working_count : Int
  evidence_count : Int
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookHealthReport {
  level : String
  summary : String
  pending_review_count : Int
  low_confidence_claim_count : Int
  maintenance_entry_count : Int
  keeper_working_count : Int
  evidence_count : Int
  issues : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn accept_goal(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookGoalAcceptance {
  let batch = produce_task_batch(entry, goal, goal_id~)
  if batch.tasks.is_empty() {
    {
      goal_id: batch.goal_id,
      accepted: false,
      reason: "no book-local tasks produced",
      task_count: 0,
      summary: batch.summary,
    }
  } else {
    {
      goal_id: batch.goal_id,
      accepted: true,
      reason: "goal accepted into keeper packet planning",
      task_count: batch.tasks.length(),
      summary: batch.summary,
    }
  }
}

///|
pub fn produce_task_batch(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookTaskBatch {
  let normalized_goal_id = goal_id.unwrap_or("goal-\{slugify_text(goal)}")
  let goal_lower = goal.to_lower()
  let tasks : Array[BookTask] = []
  if goal_lower.contains("review") || goal_lower.contains("approve") {
    tasks.push({
      id: "\{normalized_goal_id}-review",
      title: "Review pending book updates",
      kind: "review",
      prompt: "Review pending changes for the goal inside \{entry.name}: \{goal}",
      priority: 100,
      requires_review: false,
      target_pages: ["wiki/reviews/pending.md", "wiki/reviews/approved.md"],
      required_role: Some(@core.WorkerRole::Reviewer),
    })
  }
  if goal_lower.contains("plan") ||
    goal_lower.contains("next") ||
    goal_lower.contains("roadmap") {
    tasks.push({
      id: "\{normalized_goal_id}-planning",
      title: "Refresh local planning surfaces",
      kind: "planning",
      prompt: "Plan the next book-local revisions for the goal inside \{entry.name}: \{goal}",
      priority: 95,
      requires_review: true,
      target_pages: [
        "wiki/synthesis/maintenance-plan.md", "wiki/synthesis/map.md",
      ],
      required_role: Some(@core.WorkerRole::Planner),
    })
  }
  tasks.push({
    id: "\{normalized_goal_id}-analysis",
    title: "Produce domain-local task result",
    kind: "analysis",
    prompt: "Use the durable wiki and keeper memory in \{entry.name} without leaking to other books: \{goal}",
    priority: 85,
    requires_review: true,
    target_pages: ["wiki/index.md", "wiki/log.md", "keeper/INSIGHTS.md"],
    required_role: Some(default_role_for_book(entry)),
  })
  if goal_lower.contains("source") ||
    goal_lower.contains("ingest") ||
    goal_lower.contains("memory") {
    tasks.push({
      id: "\{normalized_goal_id}-ingest",
      title: "Prepare keeper ingest follow-up",
      kind: "ingest",
      prompt: "Inspect source and synthesis pages to prepare keeper ingest follow-up for: \{goal}",
      priority: 72,
      requires_review: true,
      target_pages: ["raw/", "wiki/sources/", "wiki/synthesis/overview.md"],
      required_role: Some(@core.WorkerRole::Harness),
    })
  }
  {
    goal_id: normalized_goal_id,
    goal,
    summary: "book=\{entry.id} workspace=\{entry.workspace_root} tasks=\{tasks.length()} memory=\{entry.memory_scope.to_string()}",
    tasks,
  }
}

///|
pub fn hydrate_worker_context(
  entry : BookCatalogEntry,
  task : BookTask,
) -> WorkerContextBundle {
  let context_pages = task.target_pages.map(path => normalize_target_page(path))
  let skill_paths = entry.skills.map(skill => "skills/\{skill}/SKILL.md")
  {
    book_id: entry.id,
    workspace_root: entry.workspace_root,
    task_id: task.id,
    prompt: task.prompt,
    policy: [
      "Respect \{entry.name} memory boundaries.",
      "Do not leak context across books.",
      "Persist durable knowledge only through keeper review.",
    ],
    routines: [
      "hydrate wiki state", "produce keeper packet output", "stage review-safe results",
    ],
    skill_paths,
    context_pages,
    active_memory: ["\{entry.name} active memory", "recent keeper conclusions"],
    user_memory: [
      "user preference: keep domains isolated", "town preference: packet-first handoff",
    ],
    working_memory: [
      "task kind: \{task.kind}",
      "priority: \{task.priority.to_string()}",
    ],
    memory_summary: "\{entry.name} keeper memory for \{task.title}",
    output_contract: ["keeper.plan.packet.v1", "book.result.v1"],
  }
}

///|
pub fn persist_result(
  entry : BookCatalogEntry,
  result : BookResult,
) -> PersistResultOutcome {
  {
    log_path: "\{entry.workspace_root}/keeper/logs/\{result.task_id}.md",
    updated_pages: collect_updated_pages(result.memory_candidates),
    review_queued: result.requires_review,
    notify_town: result.notify_town,
    evidence_id: "evidence-\{entry.id}-\{result.task_id}",
  }
}

///|
pub fn summarize_state(entry : BookCatalogEntry) -> BookStateSummary {
  let base = if entry.id == "finance" { 12 } else { 18 }
  {
    book_id: entry.id,
    root: entry.workspace_root,
    page_count: base + entry.tags.length() * 3,
    source_count: base / 2,
    entity_count: base,
    concept_count: base - 4,
    pending_review_count: if entry.id == "finance" {
      1
    } else {
      2
    },
    keeper_memory_count: entry.skills.length() + 2,
    keeper_working_count: entry.tags.length() + 1,
    evidence_count: base - 6,
    summary: "\{entry.name} maintains wiki, keeper memory, and review queues under \{entry.workspace_root}",
  }
}

///|
pub fn report_health(entry : BookCatalogEntry) -> BookHealthReport {
  let pending = if entry.id == "finance" { 1 } else { 2 }
  let low_confidence = if entry.memory_scope == @core.MemoryScope::TaskEphemeral {
    0
  } else {
    2
  }
  let issues : Array[String] = []
  if pending > 1 {
    issues.push("review queue needs keeper attention")
  }
  if low_confidence > 0 {
    issues.push("low-confidence claims are waiting for review")
  }
  {
    level: if issues.is_empty() {
      "healthy"
    } else {
      "degraded"
    },
    summary: "\{entry.name} keeper health snapshot",
    pending_review_count: pending,
    low_confidence_claim_count: low_confidence,
    maintenance_entry_count: entry.tags.length() + 2,
    keeper_working_count: entry.skills.length() + 1,
    evidence_count: entry.skills.length() + 3,
    issues,
  }
}

///|
fn default_role_for_book(entry : BookCatalogEntry) -> @core.WorkerRole {
  if entry.id == "finance" {
    @core.WorkerRole::MemoryKeeper
  } else {
    @core.WorkerRole::Harness
  }
}

///|
fn normalize_target_page(path : String) -> String {
  if path.contains("/") {
    path
  } else {
    "wiki/\{path}"
  }
}

///|
fn collect_updated_pages(candidates : Array[MemoryCandidate]) -> Array[String] {
  let pages : Array[String] = []
  for candidate in candidates {
    match candidate.target_page {
      Some(page) => if !pages.contains(page) { pages.push(page) }
      None => ()
    }
  }
  if pages.is_empty() {
    ["wiki/log.md", "keeper/INSIGHTS.md"]
  } else {
    pages
  }
}

///|
fn slugify_text(text : String) -> String {
  let builder = StringBuilder::new()
  let mut pending_dash = false
  for char in text.to_lower() {
    let code = char.to_int()
    let is_ascii_lower = code >= 'a'.to_int() && code <= 'z'.to_int()
    let is_ascii_digit = code >= '0'.to_int() && code <= '9'.to_int()
    if is_ascii_lower || is_ascii_digit {
      if pending_dash && builder.to_string() != "" {
        builder.write_char('-')
      }
      pending_dash = false
      builder.write_char(char)
    } else if builder.to_string() != "" {
      pending_dash = true
    }
  }
  let slug = builder.to_string()
  if slug == "" {
    "goal"
  } else {
    slug
  }
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
