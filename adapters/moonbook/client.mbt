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
  entity_count : Int
  concept_count : Int
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
  entity_count~ : Int,
  concept_count~ : Int,
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
    entity_count,
    concept_count,
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
    task.goal.unwrap_or(task.prompt),
    "--task",
    task.id,
  ])
  enrich_worker_context_bundle(entry, @json.from_json(json))
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
  @path.Path(root)
  .join(@path.Path("book/site/generated/index.html"))
  .to_string()
}

///|
pub fn generated_site_index_path(entry : BookCatalogEntry) -> String {
  @path.Path(resolved_workspace_root(entry.workspace_root))
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
  if !entry.id.has_prefix("research-") {
    return bundle
  }
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      "skills/web-first-research/SKILL.md",
      "skills/repo-source-materialize/SKILL.md",
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
fn research_request_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "# Research Request",
    "",
    "- Topic: \{display}",
    "- Goal: produce durable wiki coverage that is specific to \{display}, not generic scaffold text.",
    "- Mode: web search first, then local repository inspection as fallback and corroboration.",
    "- Required durable outputs:",
    "  - `raw/bootstrap/web-sources.md`",
    "  - `raw/bootstrap/local-sources.md`",
    "  - at least one substantive page under `wiki/sources/`",
    "  - at least one substantive page under `wiki/entities/`, `wiki/concepts/`, or `wiki/synthesis/`",
    "  - `wiki/index.md` and `wiki/log.md` updated consistently",
    "",
    "## Execution Order",
    "",
    "1. Run targeted `web_search` queries first.",
    "2. Use `web_fetch` on the most authoritative pages you found.",
    "3. Write durable notes to `raw/bootstrap/web-sources.md` with titles, URLs, snippets, and why each source matters.",
    "4. Only after web discovery, inspect high-signal local files for corroboration and implementation detail.",
    "5. Write durable notes to `raw/bootstrap/local-sources.md` with exact paths and evidence bullets.",
    "6. Materialize durable wiki pages. Do not stop at notes or generic completion text.",
    "",
    "## Blocking Rule",
    "",
    "If a tool is unavailable, record the exact blocker, continue with the remaining permitted path, and still create the durable bootstrap notes that explain what happened.",
  ].join("\n")
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
    "## Web Search First",
    "",
  ]
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
  lines.push("")
  lines.push("## Local Repository Follow-Up")
  lines.push("")
  for path in local_paths {
    lines.push("- \{path}")
  }
  lines.push("")
  lines.push("## Materialization Target")
  lines.push("")
  lines.push(
    "- Turn evidence into topic-specific source, entity, concept, and synthesis pages.",
  )
  lines.push(
    "- Generic statements like `LLM Wiki is a maintained workspace` are not acceptable final coverage for this lane.",
  )
  lines.join("\n")
}

///|
fn web_first_research_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let sample_query = research_web_queries(topic).get(0).unwrap_or(display)
  let sample_url = research_reference_urls(topic)
    .get(0)
    .unwrap_or("https://github.com/vectie/\{topic}")
  [
    "---",
    "name: web-first-research",
    "description: Discover authoritative web sources before local repository search, then convert them into durable bootstrap notes and wiki-ready claims.",
    "---",
    "",
    "# Web-First Research",
    "",
    "Use this skill for research-lane ingest and follow-up work.",
    "",
    "## Rules",
    "",
    "- Start with `web_search` before local file discovery.",
    "- Prefer authoritative pages: official docs, repo pages, maintainer docs, and project READMEs.",
    "- After search, use `web_fetch` on the highest-signal pages before writing conclusions.",
    "- Write durable notes into `raw/bootstrap/web-sources.md` before inspecting the local repo.",
    "- Only then inspect the local repo to corroborate architecture, implementation, and file-level details.",
    "- If web tools are unavailable, write a blocker note and continue with local discovery instead of silently skipping the phase.",
    "",
    "## Required Output",
    "",
    "- `raw/bootstrap/web-sources.md` with query list, fetched URLs, evidence bullets, and open questions.",
    "- `raw/bootstrap/local-sources.md` with exact file paths and evidence bullets.",
    "- Durable wiki pages that are specific to \{display}.",
    "",
    "## Example",
    "",
    "Search sequence:",
    "- `web_search` query: `\{sample_query}`",
    "- `web_fetch` url: `\{sample_url}`",
    "",
    "Then write a note like:",
    "",
    "```md",
    "# Web Sources",
    "",
    "- Query: `\{sample_query}`",
    "- URL: `\{sample_url}`",
    "- Why it matters: canonical maintainer-facing source for \{display}",
    "- Evidence:",
    "  - concrete capability or architecture point with citation",
    "  - concrete repo or docs location with citation",
    "- Open questions:",
    "  - what is still unclear after the fetch",
    "```",
    "",
    "Do not stop after the note. Use it to drive durable wiki pages.",
  ].join("\n")
}

///|
fn repo_source_materialize_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  let source_page = "wiki/sources/\{topic}.md"
  let concept_page = "wiki/concepts/\{topic}-architecture.md"
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
    "- Update `wiki/index.md` and `wiki/log.md` whenever new substantive pages are created or revised.",
    "- If evidence is still weak, create an explicit blocker note that states what is missing.",
    "",
    "## Minimum Acceptable Materialization",
    "",
    "- one substantive source page, for example `\{source_page}`",
    "- one substantive concept, entity, or synthesis page, for example `\{concept_page}`",
    "- index and log updates that reference those pages",
    "",
    "## Example",
    "",
    "Good result:",
    "",
    "```md",
    "# \{display}",
    "",
    "## What It Is",
    "- precise description grounded in fetched docs and local repo evidence",
    "",
    "## Evidence",
    "- web: fetched maintainer or repo page",
    "- local: concrete file path and why it supports the claim",
    "",
    "## Open Questions",
    "- unresolved boundary or missing capability",
    "```",
    "",
    "Bad result:",
    "- `Completed provider task.`",
    "- generic workspace boilerplate with zero topic-specific claims",
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
