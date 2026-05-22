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
      workspace_root=default_workspace_root("coding"),
      memory_scope=@core.MemoryScope::BookPrivate,
      tags=["moonbit", "git", "review"],
      skills=["analysis", "memory", "review"],
    ),
    BookCatalogEntry::new(
      id="finance",
      name="Moonbook / Finance",
      purpose="Private daily finance operations with isolated memory and task artifacts.",
      workspace_root=default_workspace_root("finance"),
      memory_scope=@core.MemoryScope::TaskEphemeral,
      tags=["ledger", "planning", "ops"],
      skills=["planning", "memory", "reporting"],
    ),
  ]
}

///|
pub fn default_workspace_root(book_id : String) -> String {
  ".moontown/books/\{book_id}"
}

///|
pub fn research_lane_topics(goal : String) -> Array[String] {
  let notes = goal.to_lower()
  let topics : Array[String] = []
  for topic in ["moontown", "moonbook", "moonclaw", "finance", "coding"] {
    if notes.contains(topic) {
      topics.push(topic)
    }
  }
  if notes.contains("opc") || notes.contains("one person company") {
    topics.push("opc")
  }
  topics
}

///|
pub fn should_parallelize_goal(goal : String) -> Bool {
  let topics = research_lane_topics(goal)
  is_research_goal(goal) && topics.length() > 1
}

///|
pub fn parallel_research_entry(topic : String) -> BookCatalogEntry {
  let normalized = normalize_topic_id(topic)
  let display = display_topic_name(normalized)
  BookCatalogEntry::new(
    id="research-\{normalized}",
    name="Moonbook / Research / \{display}",
    purpose="Isolated research wiki for \{display}, managed by the mayor as one lane in a parallel town goal.",
    workspace_root=default_workspace_root("research-\{normalized}"),
    memory_scope=@core.MemoryScope::BookPrivate,
    tags=["research", normalized, "parallel-lane"],
    skills=["analysis", "synthesis", "memory", "review"],
  )
}

///|
fn is_research_goal(goal : String) -> Bool {
  let notes = goal.to_lower()
  notes.contains("research") ||
  notes.contains("compare") ||
  notes.contains("survey") ||
  notes.contains("map")
}

///|
fn normalize_topic_id(topic : String) -> String {
  let normalized = topic.to_lower().trim().to_string()
  match normalized {
    "moontown" => "moontown"
    "moonbook" => "moonbook"
    "moonclaw" => "moonclaw"
    "finance" => "finance"
    "coding" => "coding"
    _ => normalized.replace(old=" ", new="-")
  }
}

///|
fn display_topic_name(topic : String) -> String {
  match topic {
    "moontown" => "Moontown"
    "moonbook" => "MoonBook"
    "moonclaw" => "MoonClaw"
    "finance" => "Finance"
    "coding" => "Coding"
    "opc" => "One Person Company (OPC)"
    _ => topic
  }
}

///|
pub fn default_catalog_path() -> String {
  ".moontown/moonbooks.json"
}

///|
pub fn default_moonbook_root() -> String {
  "../moonbook"
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
pub fn entry_for_book_id(
  catalog : Array[BookCatalogEntry],
  book_id : String,
) -> BookCatalogEntry? {
  match find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None =>
      if book_id.has_prefix("research-") {
        let parts = book_id.split("research-").to_array()
        if parts.length() > 1 {
          Some(parallel_research_entry(parts[1].to_string()))
        } else {
          None
        }
      } else {
        None
      }
  }
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
    Some(catalog) => {
      let normalized = normalize_catalog(catalog)
      if normalized != catalog {
        save_catalog_file(path, normalized)
      }
      normalized
    }
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
  goal : String?
  title : String
  kind : String
  prompt : String
  priority : Int
  requires_review : Bool
  target_pages : Array[String]
  required_role : @core.WorkerRole?
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn BookTask::new(
  id~ : String,
  goal? : String? = None,
  title~ : String,
  kind~ : String,
  prompt~ : String,
  priority~ : Int,
  requires_review~ : Bool,
  target_pages? : Array[String] = [],
  required_role? : @core.WorkerRole? = None,
) -> BookTask {
  {
    id,
    goal,
    title,
    kind,
    prompt,
    priority,
    requires_review,
    target_pages,
    required_role,
  }
}

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
struct ExternalBookTask {
  id : String
  title : String
  kind : String
  prompt : String
  priority : Int
  requires_review : Bool
  target_pages : Array[String]
} derive(Show, Eq, ToJson, FromJson)

///|
struct ExternalBookTaskBatch {
  goal_id : String
  goal : String
  summary : String
  tasks : Array[ExternalBookTask]
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
pub fn MemoryCandidate::new(
  kind~ : String,
  title~ : String,
  detail~ : String,
  durable? : Bool = false,
  target_page? : String? = None,
) -> MemoryCandidate {
  { kind, title, detail, durable, target_page }
}

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
pub fn BookResult::new(
  task_id~ : String,
  summary~ : String,
  artifacts? : Array[String] = [],
  memory_candidates? : Array[MemoryCandidate] = [],
  requires_review? : Bool = false,
  notify_town? : Bool = false,
) -> BookResult {
  {
    task_id,
    summary,
    artifacts,
    memory_candidates,
    requires_review,
    notify_town,
  }
}

///|
pub struct PersistResultOutcome {
  log_path : String
  updated_pages : Array[String]
  review_queued : Bool
  notify_town : Bool
  evidence_id : String
} derive(Show, Eq, ToJson, FromJson)

///|
struct BookTaskProviderMetadata {
  command : String
  args : Array[String]
  cwd : String
  workspace_root : String
} derive(Show, Eq, ToJson, FromJson)

///|
struct BookTaskProviderManifestEntry {
  name : String
  title : String
  description : String
  kind : String
  capabilities : Array[String]
  metadata : BookTaskProviderMetadata
} derive(Show, Eq, ToJson, FromJson)

///|
pub struct BookStateSummary {
  book_id : String
  root : String
  page_count : Int
  source_count : Int
  source_page_count : Int
  candidate_source_count : Int
  provisional_source_count : Int
  verified_source_count : Int
  entity_count : Int
  entity_page_count : Int
  concept_count : Int
  concept_page_count : Int
  query_note_count : Int
  pending_review_count : Int
  keeper_memory_count : Int
  keeper_working_count : Int
  evidence_count : Int
  summary : String
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn BookStateSummary::new(
  book_id~ : String,
  root~ : String,
  page_count~ : Int,
  source_count~ : Int,
  source_page_count? : Int = source_count,
  candidate_source_count? : Int = 0,
  provisional_source_count? : Int = 0,
  verified_source_count? : Int = source_page_count,
  entity_count~ : Int,
  entity_page_count? : Int = entity_count,
  concept_count~ : Int,
  concept_page_count? : Int = concept_count,
  query_note_count? : Int = 0,
  pending_review_count~ : Int,
  keeper_memory_count~ : Int,
  keeper_working_count~ : Int,
  evidence_count~ : Int,
  summary~ : String,
) -> BookStateSummary {
  {
    book_id,
    root,
    page_count,
    source_count,
    source_page_count,
    candidate_source_count,
    provisional_source_count,
    verified_source_count,
    entity_count,
    entity_page_count,
    concept_count,
    concept_page_count,
    query_note_count,
    pending_review_count,
    keeper_memory_count,
    keeper_working_count,
    evidence_count,
    summary,
  }
}

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
pub async fn accept_goal(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookGoalAcceptance {
  ignore(goal_id)
  let json = run_book_json_command(entry, ["accept", entry.workspace_root, goal])
  @json.from_json(json)
}

///|
pub async fn produce_task_batch(
  entry : BookCatalogEntry,
  goal : String,
  goal_id? : String? = None,
) -> BookTaskBatch {
  ignore(goal_id)
  let json = run_book_json_command(entry, ["tasks", entry.workspace_root, goal])
  let external : ExternalBookTaskBatch = @json.from_json(json)
  {
    goal_id: external.goal_id,
    goal: external.goal,
    summary: external.summary,
    tasks: external.tasks.map(task => {
      external_task_to_book_task(entry, task, external.goal)
    }),
  }
}

///|
pub async fn hydrate_worker_context(
  entry : BookCatalogEntry,
  task : BookTask,
) -> WorkerContextBundle {
  let json = run_book_json_command(entry, [
    "context",
    entry.workspace_root,
    context_goal_for_task(task),
    "--task",
    task.id,
  ]) catch {
    _ =>
      return enrich_worker_context_bundle(
        entry,
        fallback_worker_context_bundle(entry, task),
      )
  }
  let parsed : WorkerContextBundle = @json.from_json(json) catch {
    _ => fallback_worker_context_bundle(entry, task)
  }
  enrich_worker_context_bundle(entry, parsed)
}

///|
fn context_goal_for_task(task : BookTask) -> String {
  if task.kind == "standing-watch" {
    task.prompt
  } else {
    task.goal.unwrap_or(task.prompt)
  }
}

///|
fn fallback_worker_context_bundle(
  entry : BookCatalogEntry,
  task : BookTask,
) -> WorkerContextBundle {
  {
    book_id: entry.id,
    workspace_root: resolved_workspace_root(entry.workspace_root),
    task_id: task.id,
    prompt: task.prompt,
    policy: [
      "Keep all memory and durable artifacts inside this book unless the task explicitly names a repository patch.",
      "Return explicit blockers instead of fake completion when required tools or sources are missing.",
      "Preserve Moontown, MoonBook, and MoonClaw responsibility boundaries.",
    ],
    routines: [
      "Read task context pages first.", "Create or update target pages listed in the task when applicable.",
      "Report changed files, artifacts, blockers, and validation results.",
    ],
    skill_paths: ["skills/wiki-maintainer/SKILL.md"],
    context_pages: task.target_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "Fallback MoonBook context for externally planned task `\{task.id}` in book `\{entry.id}`.",
    output_contract: [
      "task_id", "summary", "artifacts", "memory_candidates", "requires_review",
      "notify_town",
    ],
  }
}

///|
pub async fn persist_result(
  entry : BookCatalogEntry,
  result : BookResult,
) -> PersistResultOutcome {
  let path = result_temp_path(result.task_id)
  save_result_file(path, result)
  let json = run_book_json_command(entry, [
    "persist",
    entry.workspace_root,
    path,
  ])
  @json.from_json(json)
}

///|
pub async fn summarize_state(entry : BookCatalogEntry) -> BookStateSummary {
  let json = run_book_json_command(entry, ["summary", entry.workspace_root])
  @json.from_json(json)
}

///|
pub async fn report_health(entry : BookCatalogEntry) -> BookHealthReport {
  let json = run_book_json_command(entry, ["health", entry.workspace_root])
  @json.from_json(json)
}

///|
pub async fn build_workspace(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> String {
  ensure_workspace(entry, moonbook_root~)
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  ignore(
    @integration.run_checked(
      "moon",
      ["run", "cmd/main", "--", "build", root],
      cwd=Some(resolved_moonbook_root),
    ),
  )
  resolved_generated_site_index_after_build(root)
}

///|
pub fn generated_site_index_path(entry : BookCatalogEntry) -> String {
  @path.Path(resolved_workspace_root(entry.workspace_root))
  .join(@path.Path("book/site/generated/index.html"))
  .to_string()
}

///|
async fn resolved_generated_site_index_after_build(root : String) -> String {
  let candidates = [
    "book/site/generated/index.html", "site/generated/index.html", "site/index.html",
  ]
  for relative in candidates {
    let path = @path.Path(root).join(@path.Path(relative)).to_string()
    let exists = @fs.exists(path) catch { _ => false }
    if exists {
      return path
    }
  }
  @path.Path(root)
  .join(@path.Path("book/site/generated/index.html"))
  .to_string()
}

///|
pub fn workspace_root(entry : BookCatalogEntry) -> String {
  resolved_workspace_root(entry.workspace_root)
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
fn normalize_catalog(
  catalog : Array[BookCatalogEntry],
) -> Array[BookCatalogEntry] {
  catalog.map(normalize_catalog_entry)
}

///|
fn normalize_catalog_entry(entry : BookCatalogEntry) -> BookCatalogEntry {
  if entry.workspace_root.contains("/workspace/") {
    { ..entry, workspace_root: default_workspace_root(entry.id) }
  } else if !entry.workspace_root.has_prefix("/") {
    { ..entry, workspace_root: resolved_workspace_root(entry.workspace_root) }
  } else {
    entry
  }
}

///|
fn external_task_to_book_task(
  entry : BookCatalogEntry,
  task : ExternalBookTask,
  goal : String,
) -> BookTask {
  {
    id: task.id,
    goal: Some(goal),
    title: task.title,
    kind: task.kind,
    prompt: task.prompt,
    priority: task.priority,
    requires_review: task.requires_review,
    target_pages: task.target_pages.map(path => normalize_target_page(path)),
    required_role: Some(infer_role_for_kind(entry, task.kind)),
  }
}

///|
fn infer_role_for_kind(
  entry : BookCatalogEntry,
  kind : String,
) -> @core.WorkerRole {
  match kind {
    "review" => @core.WorkerRole::Reviewer
    "planning" => @core.WorkerRole::Planner
    "ingest" => @core.WorkerRole::Harness
    "ingest-followup" => @core.WorkerRole::Harness
    "implementation-backlog" => @core.WorkerRole::Planner
    "code-patch" => @core.WorkerRole::Harness
    "test-fix" => @core.WorkerRole::Harness
    "projection-schema" => @core.WorkerRole::Harness
    "image-asset" => @core.WorkerRole::Specialist
    _ => default_role_for_book(entry)
  }
}

///|
fn result_temp_path(task_id : String) -> String {
  resolved_root_path(".moontown/book-results/\{task_id}.json")
}

///|
async fn save_result_file(path : String, result : BookResult) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(result.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_workspace(
  entry : BookCatalogEntry,
  moonbook_root? : String = default_moonbook_root(),
) -> Unit {
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  let marker = "\{root}/wiki/index.md"
  if @fs.exists(marker) {
    ensure_workspace_build_dirs(root)
    ensure_book_provider_manifest(root, resolved_moonbook_root)
    ensure_moontown_research_pack(root, entry)
    let jobs_path = "\{root}/moonclaw.jobs.json"
    if @fs.exists(jobs_path) {
      return
    }
  } else {
    ignore(
      @integration.run_checked(
        "moon",
        ["run", "cmd/main", "--", "wiki", "init", root],
        cwd=Some(resolved_moonbook_root),
      ),
    )
    ensure_workspace_build_dirs(root)
  }
  ignore(
    @integration.run_checked(
      "moon",
      ["run", "cmd/main", "--", "wiki", "enable", "moonclaw", root],
      cwd=Some(resolved_moonbook_root),
    ),
  )
  ensure_book_provider_manifest(root, resolved_moonbook_root)
  ensure_moontown_research_pack(root, entry)
}

///|
async fn run_book_json_command(
  entry : BookCatalogEntry,
  args : Array[String],
  moonbook_root? : String = default_moonbook_root(),
) -> Json {
  ensure_workspace(entry, moonbook_root~)
  let root = resolved_workspace_root(entry.workspace_root)
  let resolved_moonbook_root = resolved_root_path(moonbook_root)
  @integration.run_json(
    "moon",
    [
      "run",
      "cmd/main",
      "--",
      "wiki",
      "book",
      ..rewrite_workspace_args(args, root),
    ],
    cwd=Some(resolved_moonbook_root),
  )
}

///|
async fn ensure_workspace_build_dirs(root : String) -> Unit {
  let marker = "\{root}/book/site/generated/.gitkeep"
  ensure_parent_directory(marker)
  if !@fs.exists("\{root}/book") {
    @fs.mkdir("\{root}/book", permission=0o755) catch {
      _ => ()
    }
  }
  if !@fs.exists("\{root}/book/site") {
    @fs.mkdir("\{root}/book/site", permission=0o755) catch {
      _ => ()
    }
  }
  if !@fs.exists("\{root}/book/site/generated") {
    @fs.mkdir("\{root}/book/site/generated", permission=0o755) catch {
      _ => ()
    }
  }
}

///|
fn enrich_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  if entry.id.has_prefix("wenyu-") {
    return enrich_wenyu_worker_context_bundle(entry, bundle)
  }
  if !entry.id.has_prefix("research-") {
    return bundle
  }
  if is_standing_watch_context_bundle(bundle) {
    return standing_watch_worker_context_bundle(bundle)
  }
  if is_research_bootstrap_context_bundle(bundle) {
    return research_bootstrap_worker_context_bundle(entry, bundle)
  }
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/web-first-research/SKILL.md",
      "skills/research-evidence-synthesis/SKILL.md",
      "skills/repo-source-materialize/SKILL.md",
      "skills/wiki-marketing/SKILL.md",
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      "raw/bootstrap/RESEARCH_REQUEST.md",
      "raw/bootstrap/SOURCE_HINTS.md",
      "wiki/history/journey.md",
    ],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths,
    context_pages,
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract: bundle.output_contract,
  }
}

///|
fn is_standing_watch_context_bundle(bundle : WorkerContextBundle) -> Bool {
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("standing-watch") ||
  combined.contains("standing watch") ||
  combined.contains("standing_goal_decision")
}

///|
fn is_research_bootstrap_context_bundle(bundle : WorkerContextBundle) -> Bool {
  guard !is_standing_watch_context_bundle(bundle) else { return false }
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("bootstrap") && combined.contains("research")
}

///|
fn standing_watch_worker_context_bundle(
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/standing-watch/SKILL.md",
      "skills/web-first-research/SKILL.md",
      "skills/source-diarize/SKILL.md",
      "skills/research-evidence-synthesis/SKILL.md",
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      "wiki/history/standing-watch.md",
      "wiki/history/journey.md",
      "wiki/sources/",
      "wiki/synthesis/overview.md",
      "wiki/synthesis/claims.md",
    ],
  )
  let output_contract = unique_paths(
    [
      ..bundle.output_contract,
      "standing_goal_decision: update | no_change | needs_review | failed",
      "delta_score: 0-100",
      "new_source_count: <integer>",
      "next_check_hint: normal | slower | faster | review",
    ],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths,
    context_pages,
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract,
  }
}

///|
fn research_bootstrap_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  let skill_paths = [
    "skills/web-first-research/SKILL.md", "skills/source-diarize/SKILL.md", "skills/research-evidence-synthesis/SKILL.md",
    "skills/research-report/SKILL.md", "skills/wiki-marketing/SKILL.md",
  ]
  let context_pages = [
    "raw/bootstrap/RESEARCH_REQUEST.md", "raw/bootstrap/SOURCE_HINTS.md",
  ]
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: research_bootstrap_worker_prompt(entry),
    policy: [
      "MoonClaw owns raw evidence/report execution for this bootstrap worker.", "MoonBook owns durable wiki materialization after raw artifacts are ready.",
      "Use web discovery before local file inspection; do not infer a local repository for external-domain topics.",
      "If a tool or source is blocked, record the exact blocker and continue with clearly labeled evidence limits.",
    ],
    routines: [
      "Read `raw/bootstrap/RESEARCH_REQUEST.md` and `raw/bootstrap/SOURCE_HINTS.md` first.",
      "Produce raw bootstrap artifacts with provenance, source IDs, claim IDs, and blockers.",
      "Return a concise Markdown handoff summary from each worker step.",
    ],
    skill_paths,
    context_pages,
    active_memory: [],
    user_memory: [],
    working_memory: [],
    memory_summary: "Sanitized Moontown research bootstrap context for `\{entry.id}`.",
    output_contract: research_bootstrap_output_contract_lines(),
  }
}

///|
fn research_bootstrap_worker_prompt(entry : BookCatalogEntry) -> String {
  let display = display_topic_name(research_topic_id(entry))
  [
    "Own the MoonClaw raw research bootstrap handoff for \{display}.",
    "",
    "Use the generated job profile steps as the execution authority:",
    "- stage 1 writes research question and starter search log",
    "- stage 2 performs bounded web/source screening",
    "- stage 3 writes evidence matrix, synthesis brief, deep report, and marketing brief",
    "",
    "Do not materialize durable `wiki/*` pages in the worker stage. MoonBook will materialize wiki pages from the raw evidence envelope.",
    "Do not treat \{display} as a local repository unless screened sources prove that interpretation.",
    "Do not hard-code final research claims. Let the LLM choose sources and claims from screened evidence.",
  ].join("\n")
}

///|
fn research_bootstrap_output_contract_lines() -> Array[String] {
  [
    "For direct Moontown research bootstrap worker steps, return plain Markdown summaries unless a step prompt explicitly asks for JSON.",
    "Do not return adaptive-planning JSON such as `needs_subplan` or `suggested_substeps`.",
    "Raw artifacts must be workspace-relative paths under `raw/bootstrap/`.", "Required raw artifacts before the handoff is complete: `raw/bootstrap/research-question.md`, `raw/bootstrap/search-log.md`, `raw/bootstrap/source-screen.md`, `raw/bootstrap/evidence-matrix.md`, `raw/bootstrap/local-sources.md`, `raw/bootstrap/synthesis-brief.md`, `raw/bootstrap/deep-report.md`, and `raw/bootstrap/marketing-brief.md`.",
    "If any artifact cannot be produced, write a blocker artifact and explain the missing tool or source.",
  ]
}

///|
fn enrich_wenyu_worker_context_bundle(
  entry : BookCatalogEntry,
  bundle : WorkerContextBundle,
) -> WorkerContextBundle {
  ignore(entry)
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/wenyu-build/SKILL.md",
      "skills/wenyu-code-patch/SKILL.md",
      "skills/wenyu-asset-pack/SKILL.md",
      "skills/web-first-research/SKILL.md",
      "skills/research-evidence-synthesis/SKILL.md",
      "skills/repo-source-materialize/SKILL.md",
      "skills/wiki-marketing/SKILL.md",
    ],
  )
  let context_pages = unique_paths(
    [
      ..bundle.context_pages,
      "raw/bootstrap/RESEARCH_REQUEST.md",
      "raw/bootstrap/SOURCE_HINTS.md",
      "raw/bootstrap/WENYU_VALLEY_PRD.md",
      "raw/bootstrap/WENYU_VISION.md",
      "raw/bootstrap/deep-report.md",
      "raw/bootstrap/evidence-matrix.md",
      "raw/bootstrap/marketing-brief.md",
      "raw/bootstrap/local-sources.md",
      "mounted-sources/MANIFEST.md",
      "build/IMPLEMENTATION_BACKLOG.md",
      "build/ACCEPTANCE_TESTS.md",
    ],
  )
  {
    book_id: bundle.book_id,
    workspace_root: bundle.workspace_root,
    task_id: bundle.task_id,
    prompt: bundle.prompt,
    policy: bundle.policy,
    routines: bundle.routines,
    skill_paths,
    context_pages,
    active_memory: bundle.active_memory,
    user_memory: bundle.user_memory,
    working_memory: bundle.working_memory,
    memory_summary: bundle.memory_summary,
    output_contract: bundle.output_contract,
  }
}

///|
fn unique_paths(values : Array[String]) -> Array[String] {
  let next : Array[String] = []
  for value in values {
    if !next.contains(value) {
      next.push(value)
    }
  }
  next
}

///|
async fn ensure_book_provider_manifest(
  root : String,
  moonbook_root : String,
) -> Unit {
  let path = moonclaw_provider_manifest_path(root)
  ensure_parent_directory(path)
  let manifest = [moonbook_task_provider_manifest_entry(root, moonbook_root)]
  @fs.write_file(
    path,
    @encoding/utf8.encode(manifest.to_json().stringify()),
    create=0o644,
    truncate=true,
  )
}

///|
async fn ensure_moontown_research_pack(
  root : String,
  entry : BookCatalogEntry,
) -> Unit {
  guard entry.id.has_prefix("research-") else { return }
  write_workspace_text(
    "\{root}/skills/web-first-research/SKILL.md",
    web_first_research_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/wiki-ingest/SKILL.md",
    research_wiki_ingest_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/source-diarize/SKILL.md",
    research_source_diarize_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/research-evidence-synthesis/SKILL.md",
    research_evidence_synthesis_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/skills/repo-source-materialize/SKILL.md",
    repo_source_materialize_skill_text(entry),
  )
  write_workspace_text(
    "\{root}/raw/bootstrap/RESEARCH_REQUEST.md",
    research_request_text(entry),
  )
  write_workspace_text(
    "\{root}/raw/bootstrap/SOURCE_HINTS.md",
    research_source_hints_text(entry),
  )
  write_workspace_text_if_missing(
    "\{root}/raw/bootstrap/research-question.md",
    research_question_seed_text(entry),
  )
  write_workspace_text_if_missing(
    "\{root}/raw/bootstrap/search-log.md",
    research_search_log_seed_text(entry),
  )
  ensure_moontown_research_moonclaw_profile(root)
}

///|
async fn write_workspace_text(path : String, content : String) -> Unit {
  ensure_parent_directory(path)
  @fs.write_file(
    path,
    @encoding/utf8.encode(content),
    create=0o644,
    truncate=true,
  )
}

///|
async fn write_workspace_text_if_missing(
  path : String,
  content : String,
) -> Unit {
  let existing = if @fs.exists(path) {
    @fs.read_file(path).text() catch {
      _ => ""
    }
  } else {
    ""
  }
  if existing.trim().is_empty() {
    write_workspace_text(path, content)
  }
}

///|
async fn ensure_moontown_research_moonclaw_profile(root : String) -> Unit {
  let path = "\{root}/moonclaw.jobs.json"
  let existing = if @fs.exists(path) {
    @json.parse(@fs.read_file(path).text()) catch {
      _ => Json::object({})
    }
  } else {
    Json::object({})
  }
  let profile = @json.parse(moontown_research_bootstrap_profile_json()) catch {
    _ => Json::object({})
  }
  write_workspace_text(
    path,
    upsert_moonclaw_job_profile_json(
      existing, "moontown_research_bootstrap_worker", profile,
    ).stringify(indent=2),
  )
}

///|
fn moonbook_json_object_copy(value : Json?) -> Map[String, Json] {
  let copied : Map[String, Json] = {}
  match value {
    Some(Object(obj)) =>
      for key, entry in obj {
        copied[key] = entry
      }
    _ => ()
  }
  copied
}

///|
fn upsert_moonclaw_job_profile_json(
  config : Json,
  profile_id : String,
  profile : Json,
) -> Json {
  let root = moonbook_json_object_copy(Some(config))
  let jobs = moonbook_json_object_copy(root.get("jobs"))
  let profiles = moonbook_json_object_copy(jobs.get("profiles"))
  profiles[profile_id] = profile
  jobs["profiles"] = Json::object(profiles)
  root["jobs"] = Json::object(jobs)
  Json::object(root)
}

///|
fn moontown_research_bootstrap_profile_json() -> String {
  [
    "{", "  \"family\": \"moontown_research_bootstrap_worker\",", "  \"role\": \"worker\",",
    "  \"priority\": 150,", "  \"tags\": [\"moontown\", \"research\", \"bootstrap\", \"web\", \"wiki\"],",
    "  \"match\": {", "    \"all\": [\"research\"],", "    \"any\": [\"bootstrap\", \"source\", \"web\", \"evidence\", \"report\"]",
    "  },", "  \"steps\": [", "    {", "      \"id\": \"research_bootstrap_sources\",",
    "      \"title\": \"Run bounded web discovery and source screening\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the source-screening stage of the imported Moontown research bootstrap packet for ${proposal.title}. Read raw/bootstrap/RESEARCH_REQUEST.md, raw/bootstrap/SOURCE_HINTS.md, raw/bootstrap/research-question.md, raw/bootstrap/search-log.md, and only the relevant source-screening SKILL.md files. Use native web_search first when it is available, then use web_fetch on high-signal candidate pages. If a native web tool returns {bad request}, retry once with a simpler query or URL. If native web tools are unavailable, blocked, or return only weak search pages, fall back to bounded execute_command discovery such as curl -L --max-time 12 against LLM-chosen search-result pages and selected source URLs. First update raw/bootstrap/search-log.md with a source-screening plan, then immediately run the web-discovery tool path; do not spend a long model turn planning. Keep this pass bounded: stop searching after enough inspected evidence for a cautious synthesis, after three explicit blockers, or after six web/discovery attempts. Use high-signal URLs from SOURCE_HINTS.md as leads, but let the LLM choose which sources to include, exclude, or mark blocked. Use search pages only for discovery, never as claim evidence. Do not inspect local implementation files unless SOURCE_HINTS.md explicitly permits it. Write or revise raw/bootstrap/search-log.md, raw/bootstrap/source-screen.md, and raw/bootstrap/tool-blockers.md. Do not ask for more input; weak coverage is a blocker to record, not a reason to stall. Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan. After these files are written, immediately return a concise completion summary with source counts, rejected sources, blockers, and whether synthesis has enough evidence.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"web-first-research\",",
    "          \"source-diarize\"", "        ],", "        \"enable_tools\": true,",
    "        \"web_search\": true,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"best_effort_on_timeout\": true,",
    "        \"retry_max_attempts\": 1,", "        \"timeout_ms\": 300000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 0,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.sources.v1\"", "        }",
    "      }", "    },", "    {", "      \"id\": \"research_bootstrap_report\",",
    "      \"title\": \"Synthesize evidence and write research reports\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the synthesis stage of the imported Moontown research bootstrap packet for ${proposal.title}. Start by reading raw/bootstrap/source-screen.md, raw/bootstrap/search-log.md, raw/bootstrap/tool-blockers.md, raw/bootstrap/research-question.md, raw/bootstrap/RESEARCH_REQUEST.md, and raw/bootstrap/SOURCE_HINTS.md. Read only the directly relevant synthesis/report/marketing SKILL.md files. Do not run new web discovery in this stage and do not ask for more input. Use the screened sources and blockers as the evidence boundary, even if the source set is thin. Write or revise raw/bootstrap/local-sources.md, raw/bootstrap/evidence-matrix.md, raw/bootstrap/synthesis-brief.md, raw/bootstrap/deep-report.md, and raw/bootstrap/marketing-brief.md. If evidence is weak, write a cautious report with explicit Evidence and Limits, missing-source blockers, and next research; do not stall waiting for stronger evidence. The report must be topic-correct, source-backed, thesis-first, evidence-limited, and governed by the loaded research skills. Do not reinterpret external domain topics as local repositories unless screened sources prove that meaning. Do not update wiki pages in this worker stage; raw artifacts are the handoff for MoonBook materialization. Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan. After the files are written, immediately return the artifact paths, source counts, blockers, report quality gaps if any, and whether the evidence is strong enough for MoonBook wiki materialization.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"research-evidence-synthesis\",",
    "          \"research-report\",", "          \"wiki-marketing\"", "        ],",
    "        \"enable_tools\": true,", "        \"web_search\": false,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"best_effort_on_timeout\": true,",
    "        \"retry_max_attempts\": 1,", "        \"timeout_ms\": 240000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 1,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.report.v1\"", "        }",
    "      }", "    }", "  ],", "  \"metadata\": {", "    \"profile_metadata\": {",
    "      \"disable_waiting_for_input\": true,", "      \"best_effort_on_missing_input\": true",
    "    },", "    \"worker_role\": \"research_bootstrap\"", "  }", "}",
  ].join("\n")
}

///|
fn research_request_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let mode = research_mode_text(topic)
  let question = research_question_text(topic, display)
  let web_priority = if is_external_domain_research_topic(topic) {
    "3. Fetch or otherwise inspect the highest-signal pages you found with the available web access path, prioritizing current reputable coverage, primary sources, official pages, regulatory or standards material, and well-sourced expert analysis."
  } else {
    "3. Fetch or otherwise inspect the highest-signal pages you found with the available web access path, prioritizing official repositories, maintainer docs, release docs, and project pages."
  }
  let local_step = if is_external_domain_research_topic(topic) {
    "7. Do not infer a local repository from the topic name. Inspect local files only when `SOURCE_HINTS.md` lists explicit paths or fetched sources prove local implementation material is relevant."
  } else {
    "7. Only after web discovery, inspect high-signal local files for corroboration and implementation detail."
  }
  [
    "# Research Request",
    "",
    "- Topic: \{display}",
    "- Goal: produce a researcher-grade dossier and durable wiki coverage that is specific to \{display}, not generic scaffold text.",
    "- Mode: \{mode}",
    "- Research question: \{question}",
    "- Quality bar: every major claim must trace to either a fetched web source, a local file path, or an explicit blocker explaining why the source could not be inspected.",
    "- Required MoonClaw worker outputs:",
    "  - `raw/bootstrap/research-question.md`",
    "  - `raw/bootstrap/search-log.md`",
    "  - `raw/bootstrap/source-screen.md`",
    "  - `raw/bootstrap/evidence-matrix.md`",
    "  - `raw/bootstrap/local-sources.md`",
    "  - `raw/bootstrap/synthesis-brief.md`",
    "  - `raw/bootstrap/deep-report.md`",
    "  - `raw/bootstrap/marketing-brief.md`",
    "- Required MoonBook materialization outputs after raw evidence is ready:",
    "  - at least one substantive page under `wiki/sources/`",
    "  - at least one substantive page under `wiki/entities/`",
    "  - at least one substantive page under `wiki/concepts/`",
    "  - at least one substantive page under `wiki/synthesis/`",
    "  - `wiki/index.md` and `wiki/log.md` updated consistently",
    "",
    "## Execution Order",
    "",
    "1. Write `raw/bootstrap/research-question.md` with scope, inclusion criteria, exclusion criteria, keywords, and known source classes.",
    "2. Run at least three targeted web-discovery attempts before local file discovery. Use native `web_search` when available; otherwise use bounded command-line discovery such as `curl -L --max-time 12` against LLM-chosen search pages and candidate URLs.",
    web_priority,
    "4. Write `raw/bootstrap/search-log.md` with query strings, result counts if available, selected URLs, rejected URLs, and the reason for each decision.",
    "5. Write `raw/bootstrap/source-screen.md` with one row per inspected source: include/exclude, authority, recency, relevance, and risk.",
    "6. Extract claims into `raw/bootstrap/evidence-matrix.md` before synthesis. Use claim IDs like `C1`, `C2`, and cite source IDs like `W1` or `L1`.",
    local_step,
    "8. Write `raw/bootstrap/local-sources.md` with exact paths, symbols or sections inspected, and evidence bullets.",
    "9. Write `raw/bootstrap/synthesis-brief.md` that separates findings, contradictions, gaps, and next research.",
    "10. Write `raw/bootstrap/marketing-brief.md` using `skills/wiki-marketing/SKILL.md`: buyer pain, promise, differentiation, proof, objections, and next action.",
    "11. If running inside MoonBook, materialize durable wiki pages. If running inside a direct MoonClaw worker, stop at wiki-ready raw artifacts and clearly mark whether MoonBook has enough evidence to materialize pages.",
    "",
    "## Blocking Rule",
    "",
    "If a tool is unavailable, record the exact blocker in `raw/bootstrap/tool-blockers.md`, continue with the remaining permitted path, and still create the durable bootstrap notes that explain what happened.",
    "If native `web_search` returns only a search-engine result page or query URL, fetch that page, extract candidate URLs if possible, and retry with broader or narrower query variants before declaring the web pass blocked.",
    "If native `web_search` is disabled or stalls, use bounded command-line web discovery such as `curl -L --max-time 12` against LLM-chosen search-result pages and candidate URLs. Retry `{bad request}` once with a simpler query or URL before recording a blocker.",
    "If web search or fetch fails, do not pretend web evidence exists. Mark the source status as `blocked`, use local sources only as provisional evidence, and make the wiki page say what is missing.",
  ].join("\n")
}

///|
fn research_question_seed_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "# Research Question",
    "",
    "## Core Question",
    "",
    research_question_text(topic, display),
    "",
    "## Scope",
    "",
    "This seed file frames a web-first research pass for \{display}. It is intentionally provisional; the worker should revise it when source screening finds better boundaries.",
    "",
    "## Inclusion Criteria",
    "",
    "- directly relevant to \{display}",
    "- attributable to a reputable publisher, official body, company, operator, or named expert",
    "- specific enough to support falsifiable claims",
    "- current enough for the research question, or clearly foundational if older",
    "",
    "## Exclusion Criteria",
    "",
    "- search snippets treated as verified evidence",
    "- generic or motivational content without inspectable claims",
    "- local repository interpretation unless screened sources prove that meaning",
    "- final claims written before source inspection",
    "",
    "## Query Seeds",
    "",
    ..research_web_queries(topic).map(fn(query) { "- `\{query}`" }),
    "",
    "## Local Source Position",
    "",
    if is_external_domain_research_topic(topic) {
      "`SOURCE_HINTS.md` says no local repository is implied for this lane. Keep local evidence empty unless screened web evidence points to a concrete local artifact."
    } else {
      "Inspect local files only after web discovery has been recorded."
    },
  ].join("\n")
}

///|
fn research_search_log_seed_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "# Search Log",
    "",
    "## Seed Status",
    "",
    "Moontown created this starter log before MoonClaw source screening so the research trail is durable. It contains planned queries only; source screening must revise it with actual attempts, selected URLs, rejected URLs, blockers, and decisions.",
    "",
    "## Planned Queries",
    "",
    "| Query ID | Query | Purpose | Status |",
    "| --- | --- | --- | --- |",
    ..research_query_seed_rows(topic, display),
    "",
    "## Source Screening Rules",
    "",
    "- Use native web tools when available; otherwise use bounded command-line discovery such as `curl -L --max-time 12`.",
    "- Retry `{bad request}` once with a simpler query or URL before recording a blocker.",
    "- Use search pages only for discovery; do not cite them as evidence.",
    "- Prefer inspected source content, clear provenance, and claim-level extraction.",
    "- Keep blocked or weak sources visible in `raw/bootstrap/source-screen.md` or `raw/bootstrap/tool-blockers.md`.",
  ].join("\n")
}

///|
fn research_query_seed_rows(topic : String, display : String) -> Array[String] {
  let rows : Array[String] = []
  let queries = research_web_queries(topic)
  for index, query in queries {
    rows.push(
      "| Q\{index + 1} | `\{query}` | source discovery for \{display} | planned |",
    )
  }
  rows
}

///|
fn research_source_hints_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let web_queries = research_web_queries(topic)
  let local_paths = research_local_paths(topic)
  let reference_urls = research_reference_urls(topic)
  let lines : Array[String] = [
    "# Source Hints",
    "",
    "These are Moontown-generated hints for the \{display} research lane.",
    "",
  ]
  if is_external_domain_research_topic(topic) {
    lines.push("## Interpretation Guard")
    lines.push("")
    lines.push(
      "- Treat \{display} as an external domain research topic, not as a Vectie repository, MoonBit package, or local codebase unless source evidence proves otherwise.",
    )
    lines.push(
      "- Let the LLM choose the best current sources, but require screened web evidence before synthesis.",
    )
    lines.push(
      "- Prefer recent, reputable, source-backed material over search snippets, generic explainers, or run-log prose.",
    )
    lines.push("")
  }
  lines.push("## Web Search First")
  lines.push("")
  for query in web_queries {
    lines.push("- \{query}")
  }
  if !reference_urls.is_empty() {
    lines.push("")
    lines.push("## High-Signal URLs")
    lines.push("")
    for url in reference_urls {
      lines.push("- \{url}")
    }
  }
  if !local_paths.is_empty() {
    lines.push("")
    lines.push("## Local Repository Follow-Up")
    lines.push("")
    for path in local_paths {
      lines.push("- \{path}")
    }
  } else if is_external_domain_research_topic(topic) {
    lines.push("")
    lines.push("## Local Follow-Up")
    lines.push("")
    lines.push(
      "- No local repository is implied for this lane. Record `raw/bootstrap/local-sources.md` as intentionally empty unless web evidence points to a concrete local artifact.",
    )
  }
  lines.push("")
  lines.push("## Materialization Target")
  lines.push("")
  lines.push(
    "- Turn screened evidence into topic-specific source, entity, concept, and synthesis pages.",
  )
  lines.push(
    "- Generic statements like `LLM Wiki is a maintained workspace` are not acceptable final coverage for this lane.",
  )
  lines.push(
    "- Candidate source lists are not enough. MoonBook now treats durable coverage as verified only after source pages digest inspected material with provenance.",
  )
  lines.join("\n")
}

///|
fn research_wiki_ingest_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let lines : Array[String] = [
    "---",
    "name: wiki-ingest",
    "description: Research-grade wiki ingest for a Moontown research book: search, screen, extract, materialize, and report blockers with provenance.",
    "---",
    "",
    "# Wiki Ingest For \{display} Research",
    "",
    "This research book overrides the default generic wiki ingest behavior. Do not produce generic MoonBook product copy. Build a lane-specific research record for \{display}.",
    "",
  ]
  if is_external_domain_research_topic(topic) {
    lines.push("## Domain Guard")
    lines.push("")
    lines.push(
      "- This lane is external domain research. Do not reinterpret \{display} as a local repo, Vectie project, or MoonBit package unless screened sources prove that meaning.",
    )
    lines.push(
      "- Build source-backed coverage from web discovery, inspected pages, evidence extraction, raw worker artifacts, and durable MoonBook wiki pages.",
    )
    lines.push(
      "- If a search tool returns only a search results page, fetch and screen that page or retry query variants before declaring a blocker.",
    )
    lines.push("")
  }
  for
    line in [
      "## Mandatory Method",
      "",
      "1. Read `raw/bootstrap/RESEARCH_REQUEST.md` and `raw/bootstrap/SOURCE_HINTS.md` first.",
      "2. Attempt web-first discovery before local-only conclusions. Use native `web_search` and `web_fetch` when available. If they are unavailable, use bounded command-line discovery such as `curl -L --max-time 12`; if all web access is blocked, write `raw/bootstrap/tool-blockers.md` and mark web evidence as blocked.",
      "3. Create `raw/bootstrap/research-question.md` with question, scope, inclusion criteria, exclusion criteria, keywords, and source classes.",
      "4. Create `raw/bootstrap/search-log.md` even when web tools are blocked. Include attempted queries, selected or blocked URLs, rejected sources, and decisions.",
      "5. Create `raw/bootstrap/source-screen.md` with source ID, include/exclude decision, authority, relevance, recency, and risk.",
      "6. Create `raw/bootstrap/evidence-matrix.md` before writing wiki prose. Claims must be falsifiable and cite source IDs.",
      "7. Inspect local files only after recording the web-search state, and only when `SOURCE_HINTS.md` or screened web evidence makes local files relevant. Use exact paths and record them as `L1`, `L2`, etc.",
      "8. Write `raw/bootstrap/marketing-brief.md` from screened evidence using `skills/wiki-marketing/SKILL.md`; make it buyer-facing, specific, and proof-backed.",
      "9. Materialize durable wiki pages only from screened evidence: `wiki/sources/`, `wiki/entities/`, `wiki/concepts/`, and `wiki/synthesis/`.",
      "10. Update `wiki/index.md` and `wiki/log.md` with the durable pages created.",
      "",
      "## Required Raw Files",
      "",
      "- `raw/bootstrap/research-question.md`",
      "- `raw/bootstrap/search-log.md`",
      "- `raw/bootstrap/source-screen.md`",
      "- `raw/bootstrap/evidence-matrix.md`",
      "- `raw/bootstrap/local-sources.md`",
      "- `raw/bootstrap/synthesis-brief.md`",
      "- `raw/bootstrap/marketing-brief.md`",
      "",
      "## Required Wiki Files",
      "",
      "- `wiki/sources/\{topic}-web-and-local.md` or another topic-specific verified source digest.",
      "- `wiki/entities/\{topic}.md` or another concrete entity page for \{display}.",
      "- `wiki/concepts/\{topic}-architecture.md` or another concept page grounded in claims.",
      "- `wiki/synthesis/\{topic}-research-brief.md` or another synthesis page connecting claims across sources.",
      "",
      "## Verified Source Page Criteria",
      "",
      "A page under `wiki/sources/` is verified only when it includes:",
      "",
      "- `Source type: verified source digest`",
      "- source IDs such as `W1`, `W2`, `L1`",
      "- inspected content summary",
      "- extracted claim IDs",
      "- confidence and risk notes",
      "- explicit blockers for missing web or local evidence",
      "",
      "## Example Result Shape",
      "",
      "```md",
      "# \{display} Research Brief",
      "",
      "## Findings",
      "- C1: \{display} has a specific verified property. Evidence: W1 and W2 if web was available, optional L1 only when local files are relevant.",
      "",
      "## Contradictions",
      "- C2 has local support but no public source; confidence remains medium.",
      "",
      "## Gaps",
      "- Web tools were unavailable, so public-source verification is blocked.",
      "```",
      "",
      "If you cannot create the required files, return a blocker result. Do not mark the task complete with only generic source pages.",
    ] {
    lines.push(line)
  }
  lines.join("\n")
}

///|
fn research_source_diarize_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "---",
    "name: source-diarize",
    "description: Convert inspected web and local sources into claim-level research packets with screen decisions, provenance, and blockers.",
    "---",
    "",
    "# Source Diarize For \{display}",
    "",
    "Use this skill during bootstrap gather and materialization. The goal is not to list files. The goal is to turn inspected evidence into a reproducible research trail.",
    "",
    "## Source IDs",
    "",
    "- `W1`, `W2`, `W3`: web sources from search/fetch.",
    "- `L1`, `L2`, `L3`: local files only when local evidence is explicitly relevant.",
    "- `B1`: blocker records such as missing web search, unreadable file, or unavailable source.",
    "",
    "## Packet Requirements",
    "",
    "For each source packet or durable source page, include:",
    "",
    "- source ID",
    "- source type: web, local, or blocker",
    "- exact URL or local path",
    "- why it was included or excluded",
    "- extracted claims with IDs",
    "- confidence",
    "- risks or contradictions",
    "",
    "## Evidence Matrix Example",
    "",
    "```md",
    "| Claim ID | Claim | Source IDs | Evidence detail | Confidence | Gap or contradiction |",
    "| --- | --- | --- | --- | --- | --- |",
    "| C1 | \{display} has a specific verified property stated as a falsifiable sentence. | W1, W2 | Inspected sources support the claim; blocker rows explain missing evidence. | medium | Needs another independent source or narrower jurisdiction note. |",
    "```",
    "",
    "## Do Not",
    "",
    "- Do not create a verified source page from a candidate URL list alone.",
    "- Do not write only `moon.mod.json` metadata unless that is the actual research question.",
    "- Do not use the same generic product text across Moontown, MoonBook, and MoonClaw lanes.",
    "- Do not omit `raw/bootstrap/search-log.md` just because web tools are missing.",
  ].join("\n")
}

///|
fn web_first_research_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let sample_query = research_web_queries(topic).get(0).unwrap_or(display)
  let sample_url = research_reference_urls(topic)
    .get(0)
    .unwrap_or("source chosen from screened web discovery")
  let authority_rule = if is_external_domain_research_topic(topic) {
    "- Prefer reputable current coverage, primary-source pages, official/regulatory material, research reports, expert essays, and clearly dated news. Do not prefer code repositories unless the topic is actually a software project."
  } else {
    "- Prefer authoritative pages: official docs, repo pages, maintainer docs, and project READMEs."
  }
  let local_rule = if is_external_domain_research_topic(topic) {
    "- Do not inspect a local repository by guessing from the topic name. Use local files only when explicitly listed in `SOURCE_HINTS.md` or when web evidence points to a concrete local artifact."
  } else {
    "- Only then inspect the local repo to corroborate architecture, implementation, and file-level details."
  }
  [
    "---",
    "name: web-first-research",
    "description: Discover authoritative web sources before local repository search, then convert them into durable bootstrap notes and wiki-ready claims.",
    "---",
    "",
    "# Web-First Research",
    "",
    "Use this skill for research-lane ingest and follow-up work. The output must look like a researcher worked through a transparent protocol, not like a product blurb.",
    "",
    "## Research Method",
    "",
    "Follow this sequence:",
    "",
    "1. Formulate the research question, scope, keywords, inclusion criteria, and exclusion criteria.",
    "2. Search the web before local files. Use multiple query phrasings, not just the project name.",
    "3. Fetch and inspect selected sources before writing claims.",
    "4. Screen sources for authority, relevance, recency, and risk.",
    "5. Extract evidence into a claim matrix before synthesis.",
    "6. Compare web evidence with local repository evidence.",
    "7. Synthesize what is supported, what conflicts, and what remains unknown.",
    "8. Materialize verified wiki pages with source IDs and claim IDs.",
    "",
    "## Rules",
    "",
    "- Start with web discovery before local file discovery. Use native `web_search` when it is available.",
    "- If native `web_search` or `web_fetch` is disabled, unavailable, or stalls, use bounded command-line web discovery such as `curl -L --max-time 12` against LLM-chosen search-result pages and candidate URLs before local file discovery.",
    "- In command-line discovery mode, first write the planned query/source-screening strategy to `raw/bootstrap/search-log.md`, then run a small bounded command batch. Do not spend a long model turn planning before the first durable write or command.",
    "- Run at least three web queries for this topic.",
    "- Keep discovery bounded. Stop searching once the pass has enough inspected evidence for a cautious synthesis, three explicit blockers, or six web/discovery attempts. Weak evidence should become an explicit blocker and synthesis gap, not an endless search.",
    authority_rule,
    "- After search, inspect at least two highest-signal pages before writing conclusions. Use native `web_fetch` if available; otherwise use bounded command-line fetches.",
    "- If native `web_search` returns only a search-engine URL or weak result page, fetch the result page, extract candidates when possible, and retry query variants before writing a blocker.",
    "- Write durable notes into `raw/bootstrap/search-log.md` and `raw/bootstrap/source-screen.md` before inspecting the local repo.",
    local_rule,
    "- If all web access paths are unavailable, write `raw/bootstrap/tool-blockers.md` and continue only with clearly provisional evidence instead of silently skipping the phase.",
    "- Do not cite search snippets as verified evidence unless fetch is blocked and the source is clearly labeled provisional.",
    "- Do not mark a source page verified unless it contains inspected source content, extracted claims, and provenance.",
    "",
    "## Required Output",
    "",
    "- `raw/bootstrap/research-question.md` with scope and criteria.",
    "- `raw/bootstrap/search-log.md` with queries, selected URLs, rejected URLs, and reasons.",
    "- `raw/bootstrap/source-screen.md` with authority, relevance, recency, and risk notes.",
    "- `raw/bootstrap/evidence-matrix.md` with claim IDs, source IDs, evidence, confidence, and gaps.",
    "- `raw/bootstrap/local-sources.md` with exact file paths, symbols or sections, and evidence bullets.",
    "- `raw/bootstrap/synthesis-brief.md` with findings, contradictions, gaps, and next research.",
    "- `raw/bootstrap/deep-report.md` with thesis-first research analysis, tables, Mermaid relationship diagram, maturity assessment, and evidence limits.",
    "- `raw/bootstrap/marketing-brief.md` with buyer-facing positioning, product strengths, proof points, objections, and next action.",
    "- Wiki-ready materialization notes that are specific to \{display}; create durable wiki pages only when the current runtime owns MoonBook wiki materialization.",
    "",
    "## Example Workflow",
    "",
    "Search sequence:",
    "- native mode: `web_search` query: `\{sample_query}`",
    "- native mode: `web_search` query: `\{research_followup_query(topic, display)}`",
    "- native mode: `web_search` query: `\{research_risk_query(topic, display)}`",
    "- command-line mode: `curl -L --max-time 12 'search page chosen by the worker for \{sample_query}'`",
    "- command-line mode: `curl -L --max-time 12 '\{sample_url}'`",
    "",
    "Then write protocol notes like:",
    "",
    "```md",
    "# Search Log",
    "",
    "| ID | Query | Selected source | Decision | Rationale |",
    "| --- | --- | --- | --- | --- |",
    "| W1 | `\{sample_query}` | `\{sample_url}` | include | inspected source with direct relevance to \{display} |",
    "",
    "# Evidence Matrix",
    "",
    "| Claim ID | Claim | Sources | Confidence | Notes |",
    "| --- | --- | --- | --- | --- |",
    "| C1 | \{display} has a specific verified property discovered from screened evidence. | W1 | medium | Confirm with another current source before final synthesis. |",
    "```",
    "",
    "Do not stop after the notes. Use them to drive either durable wiki pages or a clear handoff that MoonBook can materialize.",
    "",
    "## Output Contract Example",
    "",
    "Return JSON only when the runtime asks for JSON:",
    "",
    "```json",
    "{",
    "  \"task_id\": \"goal-research-moonclaw-research-bootstrap-ingest\",",
    "  \"summary\": \"Created a web-first research dossier and verified wiki pages for MoonClaw.\",",
    "  \"artifacts\": [",
    "    \"raw/bootstrap/search-log.md\",",
    "    \"raw/bootstrap/evidence-matrix.md\",",
    "    \"wiki/sources/moonclaw-web-and-local.md\",",
    "    \"wiki/entities/moonclaw.md\",",
    "    \"wiki/concepts/moonclaw-agent-runtime.md\",",
    "    \"wiki/synthesis/moonclaw-research-brief.md\"",
    "  ],",
    "  \"memory_candidates\": [",
    "    { \"kind\": \"finding\", \"text\": \"MoonClaw owns execution and result packaging; MoonBook owns durable memory promotion.\" }",
    "  ],",
    "  \"requires_review\": true,",
    "  \"notify_town\": true",
    "}",
    "```",
  ].join("\n")
}

///|
fn research_evidence_synthesis_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "---",
    "name: research-evidence-synthesis",
    "description: Apply a transparent evidence-synthesis workflow: question, search, screen, extract, triangulate, synthesize, and report gaps.",
    "---",
    "",
    "# Research Evidence Synthesis",
    "",
    "Use this skill when a research lane needs real knowledge work instead of a scaffold or candidate inventory.",
    "",
    "## Protocol",
    "",
    "1. Question: define the research question for \{display}, the subquestions, and what counts as in scope.",
    "2. Search: record every query attempted and why it was chosen.",
    "3. Screen: include or exclude sources using authority, relevance, recency, and source risk.",
    "4. Extract: convert source observations into claim rows before writing prose.",
    "5. Triangulate: compare multiple independent web sources, and compare with local repository evidence only when local evidence is explicitly relevant.",
    "6. Synthesize: combine claims into a short argument about what \{display} is, how it works, and why it matters.",
    "7. Position: use the marketing skill to convert supported claims into `raw/bootstrap/marketing-brief.md` without inventing unsupported product claims.",
    "8. Gap map: list missing evidence, contradictions, and next searches.",
    "",
    "## Evidence Matrix Schema",
    "",
    "Write `raw/bootstrap/evidence-matrix.md` with this table:",
    "",
    "```md",
    "| Claim ID | Claim | Source IDs | Evidence detail | Confidence | Gap or contradiction |",
    "| --- | --- | --- | --- | --- | --- |",
    "| C1 | \{display} claim stated as a falsifiable sentence. | W1, L1 | What each source actually shows. | medium | What still needs verification. |",
    "```",
    "",
    "## Wiki Materialization Rules",
    "",
    "- A source page under `wiki/sources/` must identify source IDs, source type, inspected content, extracted claims, and risk.",
    "- An entity page under `wiki/entities/` must describe the concrete project, actor, institution, domain model, or market participant that the evidence actually supports.",
    "- A concept page under `wiki/concepts/` must explain one architecture, workflow, business, legal, or market concept grounded in claims.",
    "- A synthesis page under `wiki/synthesis/` must connect claims across sources and name unresolved gaps.",
    "- `raw/bootstrap/marketing-brief.md` must translate the evidence into product and seller perspective: buyer, pain, promise, strengths, proof, objections, and next action.",
    "- Every durable page must include provenance. Use claim IDs and source IDs from the evidence matrix.",
    "",
    "## Example Source Page",
    "",
    "```md",
    "# \{display} Web and Local Evidence",
    "",
    "- Source type: verified source digest",
    "- Topic: \{display}",
    "- Source IDs: W1, W2, optional L1 only when local evidence is relevant",
    "",
    "## Screened Sources",
    "",
    "- W1: fetched reputable web source. Included because it directly describes \{display}.",
    "- L1: optional local file path inspected only when source hints or screened evidence make it relevant.",
    "",
    "## Extracted Claims",
    "",
    "- C1: \{display} has a specific verified property. Sources: W1, W2. Confidence: medium.",
    "",
    "## Risks",
    "",
    "- Missing current evidence, blocked sources, jurisdiction limits, or single-source claims.",
    "```",
    "",
    "## Failure Discipline",
    "",
    "If the research cannot reach verified coverage, make that explicit. Create provisional pages only when they are labeled provisional and explain the exact missing source or tool.",
  ].join("\n")
}

///|
fn repo_source_materialize_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let source_page = "wiki/sources/\{topic}-web-and-local.md"
  let entity_page = "wiki/entities/\{topic}.md"
  let concept_page = "wiki/concepts/\{topic}-architecture.md"
  let synthesis_page = "wiki/synthesis/\{topic}-research-brief.md"
  [
    "---",
    "name: repo-source-materialize",
    "description: Turn gathered web and local evidence into durable source, entity, concept, and synthesis pages instead of generic completion text.",
    "---",
    "",
    "# Repo Source Materialize",
    "",
    "Use this skill after source discovery for \{display}.",
    "",
    "## Rules",
    "",
    "- Convert evidence into durable markdown pages, not chat-style summaries.",
    "- Preserve provenance from both web and local sources.",
    "- Use the evidence matrix as the only source of claims. If a claim is not in `raw/bootstrap/evidence-matrix.md`, extract it there first.",
    "- Mark source pages as `Source type: verified source digest` only when fetched or inspected content exists.",
    "- Candidate inventories and provisional blockers belong in `raw/bootstrap/` or clearly labeled provisional pages, not as the final source coverage.",
    "- Update `wiki/index.md` and `wiki/log.md` whenever new substantive pages are created or revised.",
    "- If evidence is still weak, create an explicit blocker note that states what is missing.",
    "",
    "## Minimum Acceptable Materialization",
    "",
    "- one verified source page, for example `\{source_page}`",
    "- one entity page, for example `\{entity_page}`",
    "- one concept page, for example `\{concept_page}`",
    "- one synthesis page, for example `\{synthesis_page}`",
    "- index and log updates that reference those pages",
    "",
    "## Example",
    "",
    "Good result:",
    "",
    "```md",
    "# \{display} Architecture",
    "",
    "## What It Is",
    "- precise description grounded in fetched docs and local repo evidence, with claim IDs",
    "",
    "## Evidence",
    "- C1: web source W1 shows the public/project-facing claim.",
    "- C2: local source L1 shows how the claim is implemented.",
    "",
    "## Synthesis",
    "- explain how the evidence fits together and where it is still weak",
    "",
    "## Open Questions",
    "- unresolved boundary or missing capability",
    "```",
    "",
    "Bad result:",
    "- `Completed provider task.`",
    "- generic workspace boilerplate with zero topic-specific claims",
    "- a `wiki/sources/` page that only lists candidate URLs without inspected evidence",
  ].join("\n")
}

///|
fn research_topic_id(entry : BookCatalogEntry) -> String {
  if entry.id.has_prefix("research-") {
    entry.id[9:].to_string()
  } else {
    normalize_topic_id(entry.id)
  }
}

///|
fn is_external_domain_research_topic(topic : String) -> Bool {
  match topic {
    "opc" => true
    _ => false
  }
}

///|
fn research_mode_text(topic : String) -> String {
  if is_external_domain_research_topic(topic) {
    "web discovery first, source screening second, evidence extraction third, source triangulation fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last. Local repository inspection is not part of the default path."
  } else {
    "web discovery first, source screening second, evidence extraction third, local repository inspection fourth, MoonClaw raw handoff fifth, and MoonBook wiki materialization last."
  }
}

///|
fn research_question_text(topic : String, display : String) -> String {
  match topic {
    "opc" =>
      "What is the One Person Company model, what current news and evidence show about its business reality, how AI tools and agentic workflows change its feasibility, what examples and risks matter, and what remains uncertain?"
    _ =>
      "What is \{display}, what problem does it solve, how is it implemented or operated, what evidence supports those claims, and what remains uncertain?"
  }
}

///|
fn research_followup_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "AI solo founder one person company trend"
    _ => "\{display} architecture implementation"
  }
}

///|
fn research_risk_query(topic : String, _display : String) -> String {
  match topic {
    "opc" => "one person company risks operations legal finance"
    _ => "site:github.com vectie \{topic}"
  }
}

///|
fn research_web_queries(topic : String) -> Array[String] {
  match topic {
    "moontown" =>
      [
        "vectie moontown", "moontown moonbook moonclaw", "site:github.com vectie moontown",
      ]
    "moonbook" =>
      [
        "vectie moonbook", "moonbook wiki moonbit", "site:github.com vectie moonbook",
      ]
    "moonclaw" =>
      [
        "vectie moonclaw", "moonclaw moonbit agent", "site:github.com vectie moonclaw",
      ]
    "opc" =>
      [
        "one person company latest news AI", "one-person company solo founder AI startup",
        "one person company business model trend", "one-person unicorn AI startup trend",
        "Anthropic CEO one-person billion-dollar company AI", "OPC entrepreneur one person company current evidence",
        "one person company risks legal finance operations",
      ]
    _ =>
      ["vectie \{topic}", "\{topic} moonbit", "site:github.com vectie \{topic}"]
  }
}

///|
fn research_reference_urls(topic : String) -> Array[String] {
  match topic {
    "moontown" => ["https://github.com/vectie/moontown"]
    "moonbook" => ["https://github.com/vectie/moonbook"]
    "moonclaw" => ["https://github.com/vectie/moonclaw"]
    "opc" =>
      [
        "https://www.opc.community/", "https://www.forbes.com/sites/elainepofeldt/2026/01/28/as-more-founders-aim-to-build-billion-dollar-one-person-businesses-new-research-points-to-high-potential-niches/",
        "https://www.europeanbusinessreview.com/one-person-startups-are-on-the-rise-thanks-to-ai/",
        "https://www.worldbank.org/en/programs/entrepreneurship", "https://www.gov.uk/running-a-limited-company",
      ]
    _ => ["https://github.com/vectie/\{topic}"]
  }
}

///|
fn research_local_paths(topic : String) -> Array[String] {
  match topic {
    "moontown" =>
      [
        "/Users/kq/Workspace/moontown/README.md", "/Users/kq/Workspace/moontown/README.mbt.md",
        "/Users/kq/Workspace/moontown/AGENTS.md", "/Users/kq/Workspace/moontown/moon.mod.json",
        "/Users/kq/Workspace/moontown/cmd/main/main.mbt", "/Users/kq/Workspace/moontown/goal_run.mbt",
        "/Users/kq/Workspace/moontown/adapters/moonbook/client.mbt", "/Users/kq/Workspace/moontown/adapters/moonclaw/client.mbt",
        "/Users/kq/Workspace/moontown/roles/mayor.mbt",
      ]
    "moonbook" =>
      [
        "/Users/kq/Workspace/moonbook/README.md", "/Users/kq/Workspace/moonbook/README.mbt.md",
        "/Users/kq/Workspace/moonbook/AGENTS.md", "/Users/kq/Workspace/moonbook/moon.mod.json",
        "/Users/kq/Workspace/moonbook/docs/SYSTEM_ARCHITECTURE.md", "/Users/kq/Workspace/moonbook/wiki/bookapi.mbt",
        "/Users/kq/Workspace/moonbook/wiki/init.mbt", "/Users/kq/Workspace/moonbook/wiki/ui_state.mbt",
      ]
    "moonclaw" =>
      [
        "/Users/kq/Workspace/moonclaw/README.mbt.md", "/Users/kq/Workspace/moonclaw/Agents.md",
        "/Users/kq/Workspace/moonclaw/moon.mod.json", "/Users/kq/Workspace/moonclaw/docs/research_controller_architecture.md",
        "/Users/kq/Workspace/moonclaw/job/provider_task.mbt", "/Users/kq/Workspace/moonclaw/job/analysis_contracts.mbt",
        "/Users/kq/Workspace/moonclaw/tools/web_search/tool.mbt", "/Users/kq/Workspace/moonclaw/tools/web_fetch/tool.mbt",
        "/Users/kq/Workspace/moonclaw/tools/search_files/tool.mbt",
      ]
    "opc" => []
    _ =>
      [
        "/Users/kq/Workspace/\{topic}/README.md",
        "/Users/kq/Workspace/\{topic}/moon.mod.json",
      ]
  }
}

///|
fn moonclaw_provider_manifest_path(root : String) -> String {
  "\{root}/.moonclaw/providers.json"
}

///|
fn moonbook_task_provider_manifest_entry(
  root : String,
  moonbook_root : String,
) -> BookTaskProviderManifestEntry {
  {
    name: "moonbook",
    title: "MoonBook Book Harness",
    description: "MoonBook provider-task bridge for domain-local workspace logic.",
    kind: "task-provider",
    capabilities: [
      "provider", "extension", "provider.task", "extension.task", "bookapi", "moonbook.bookapi",
    ],
    metadata: {
      command: "moon",
      args: ["run", "cmd/main", "--"],
      cwd: moonbook_root,
      workspace_root: root,
    },
  }
}

///|
fn rewrite_workspace_args(args : Array[String], root : String) -> Array[String] {
  if args.is_empty() {
    return args
  }
  let next = args.copy()
  match next[0] {
    "accept"
    | "tasks"
    | "context"
    | "persist"
    | "catalog"
    | "summary"
    | "health" => if next.length() >= 2 { next[1] = root }
    _ => ()
  }
  next
}

///|
fn resolved_workspace_root(workspace_root : String) -> String {
  resolved_root_path(workspace_root)
}

///|
fn resolved_root_path(path : String) -> String {
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
