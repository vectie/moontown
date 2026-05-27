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
pub impl @core.BookProvider for MoonbookCatalogProvider with fn books(
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
    tags=["research", normalized, "topic:\{normalized}", "parallel-lane"],
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
    _ => compact_topic_segment(normalized)
  }
}

///|
fn strip_research_attempt_suffix(topic : String) -> String {
  let cleaned = topic.to_lower().trim().to_string()
  let parts = cleaned.split("-").to_array()
  if parts.length() < 2 {
    return cleaned
  }
  let last = parts[parts.length() - 1].to_string()
  if !(last.length() > 1 &&
    last[0] == 'v' &&
    string_is_digits(last[1:].to_string())) {
    return cleaned
  }
  let builder = StringBuilder::new()
  for index in 0..<(parts.length() - 1) {
    if index > 0 {
      builder.write_char('-')
    }
    builder.write_string(parts[index].to_string())
  }
  builder.to_string()
}

///|
fn string_is_digits(text : String) -> Bool {
  if text.is_empty() {
    return false
  }
  for char in text {
    if char < '0' || char > '9' {
      return false
    }
  }
  true
}

///|
fn compact_topic_segment(text : String) -> String {
  let builder = StringBuilder::new()
  let mut last_dash = false
  for char in text.to_lower() {
    if (char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') {
      builder.write_char(char)
      last_dash = false
    } else if !last_dash {
      builder.write_char('-')
      last_dash = true
    }
  }
  builder.to_string().trim(chars="-").to_string()
}

///|
fn research_topic_from_goal(goal : String) -> String? {
  let trimmed = goal.trim().trim(chars=" .:;!?\"'`").to_string()
  if trimmed.is_empty() {
    return None
  }
  let lower = trimmed.to_lower()
  let prefixes = [
    "research about ", "research on ", "research the ", "research ", "study about ",
    "study on ", "study the ", "study ", "survey about ", "survey on ", "survey the ",
    "survey ", "compare about ", "compare on ", "compare the ", "compare ",
  ]
  for prefix in prefixes {
    if lower.has_prefix(prefix) {
      let topic = trimmed[prefix.length():]
        .trim()
        .trim(chars=" .:;!?\"'`")
        .to_string()
      if !topic.is_empty() {
        return Some(topic)
      }
    }
  }
  Some(trimmed)
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
    _ => topic_id_to_words(topic)
  }
}

///|
fn topic_id_to_words(topic : String) -> String {
  let builder = StringBuilder::new()
  for char in topic {
    if char == '-' {
      builder.write_char(' ')
    } else {
      builder.write_char(char)
    }
  }
  builder.to_string()
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
pub fn entry_for_explicit_research_book(
  catalog : Array[BookCatalogEntry],
  book_id : String,
  goal : String,
) -> BookCatalogEntry? {
  match find_catalog_entry(catalog, book_id) {
    Some(entry) => Some(entry)
    None =>
      if book_id.has_prefix("research-") {
        let storage_topic = book_id[9:].to_string()
        let stable_storage_topic = strip_research_attempt_suffix(storage_topic)
        let goal_topic = research_topic_from_goal(goal)
        let goal_topic_id = match goal_topic {
          Some(topic) => normalize_topic_id(topic)
          None => ""
        }
        let storage_topic_id = normalize_topic_id(stable_storage_topic)
        let has_attempt_suffix = stable_storage_topic !=
          storage_topic.to_lower().trim().to_string()
        let book_topic_id = if has_attempt_suffix && !goal_topic_id.is_empty() {
          goal_topic_id
        } else {
          storage_topic_id
        }
        if book_topic_id.is_empty() {
          return None
        }
        let topic_id = if !goal_topic_id.is_empty() {
          goal_topic_id
        } else {
          book_topic_id
        }
        let canonical_book_id = "research-\{book_topic_id}"
        let display = display_topic_name(topic_id)
        let purpose = if canonical_book_id == book_id {
          "Isolated research wiki for \{display}, stored in \{canonical_book_id} for this topic."
        } else {
          "Isolated research wiki for \{display}; requested as \{book_id}, but stored in stable topic book \{canonical_book_id} so quality retries do not create v1/v2/v3 forks."
        }
        let tags = if canonical_book_id == book_id {
          ["research", topic_id, "topic:\{topic_id}", "explicit-book"]
        } else {
          [
            "research",
            topic_id,
            "topic:\{topic_id}",
            "explicit-book",
            "requested-book:\{book_id}",
          ]
        }
        Some(
          BookCatalogEntry::new(
            id=canonical_book_id,
            name="Moonbook / Research / \{display}",
            purpose~,
            workspace_root=default_workspace_root(canonical_book_id),
            memory_scope=@core.MemoryScope::BookPrivate,
            tags~,
            skills=["analysis", "synthesis", "memory", "review"],
          ),
        )
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
  total_evidence_count : Int
  operational_evidence_count : Int
  substantive_coverage_ready : Bool
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
  total_evidence_count? : Int = evidence_count,
  operational_evidence_count? : Int = total_evidence_count - evidence_count,
  substantive_coverage_ready? : Bool = false,
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
    total_evidence_count,
    operational_evidence_count,
    substantive_coverage_ready,
    summary,
  }
}

///|
struct ExternalBookStateSummary {
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
  substantive_coverage_ready : Bool
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
  let external : ExternalBookStateSummary = @json.from_json(json)
  normalize_book_state_summary(entry, external)
}

///|
pub async fn report_health(entry : BookCatalogEntry) -> BookHealthReport {
  let json = run_book_json_command(entry, ["health", entry.workspace_root])
  @json.from_json(json)
}

///|
async fn normalize_book_state_summary(
  entry : BookCatalogEntry,
  external : ExternalBookStateSummary,
) -> BookStateSummary {
  let root = resolved_workspace_root(entry.workspace_root)
  let accounting = evidence_accounting_for_workspace(
    root,
    fallback_total=external.evidence_count,
  )
  let substantive_coverage_ready = external.substantive_coverage_ready &&
    accounting.domain_count > 0
  BookStateSummary::new(
    book_id=external.book_id,
    root=external.root,
    page_count=external.page_count,
    source_count=external.source_count,
    source_page_count=external.source_page_count,
    candidate_source_count=external.candidate_source_count,
    provisional_source_count=external.provisional_source_count,
    verified_source_count=external.verified_source_count,
    entity_count=external.entity_count,
    entity_page_count=external.entity_page_count,
    concept_count=external.concept_count,
    concept_page_count=external.concept_page_count,
    query_note_count=external.query_note_count,
    pending_review_count=external.pending_review_count,
    keeper_memory_count=external.keeper_memory_count,
    keeper_working_count=external.keeper_working_count,
    evidence_count=accounting.domain_count,
    total_evidence_count=accounting.total_count,
    operational_evidence_count=accounting.operational_count,
    substantive_coverage_ready~,
    summary=append_evidence_accounting_summary(external.summary, accounting),
  )
}

///|
struct EvidenceAccounting {
  total_count : Int
  domain_count : Int
  operational_count : Int
} derive(Show, Eq)

///|
async fn evidence_accounting_for_workspace(
  root : String,
  fallback_total~ : Int,
) -> EvidenceAccounting {
  let evidence_path = @path.Path(root)
    .join(@path.Path("wiki/synthesis/evidence.md"))
    .to_string()
  if !(@fs.exists(evidence_path) catch { _ => false }) {
    return {
      total_count: fallback_total,
      domain_count: fallback_total,
      operational_count: 0,
    }
  }
  evidence_accounting_from_text(
    @fs.read_file(evidence_path).text() catch {
      _ => ""
    },
  )
}

///|
fn evidence_accounting_from_text(content : String) -> EvidenceAccounting {
  let blocks = evidence_record_blocks(content)
  let mut operational_count = 0
  for block in blocks {
    if evidence_block_is_operational(block) {
      operational_count += 1
    }
  }
  {
    total_count: blocks.length(),
    domain_count: blocks.length() - operational_count,
    operational_count,
  }
}

///|
fn evidence_record_blocks(content : String) -> Array[String] {
  let blocks : Array[String] = []
  let mut current = ""
  let mut active = false
  for raw in content.split("\n") {
    let line = raw.to_string()
    if line.has_prefix("### ") {
      if active {
        blocks.push(current)
      }
      current = line + "\n"
      active = true
    } else if active {
      current = current + line + "\n"
    }
  }
  if active {
    blocks.push(current)
  }
  blocks
}

///|
fn evidence_block_is_operational(block : String) -> Bool {
  let lower = block.to_lower()
  if evidence_block_is_standing_watch(lower) {
    return !standing_watch_block_has_domain_delta(block)
  }
  lower.contains("workflow completed workspace=") &&
  lower.contains("/moonclaw-jobs/run-") &&
  !lower.contains("accepted_facts_count:") &&
  !lower.contains("wiki_pages_changed_count:")
}

///|
fn evidence_block_is_standing_watch(lower_block : String) -> Bool {
  lower_block.contains("standing-watch") ||
  lower_block.contains("standing watch") ||
  lower_block.contains("standing_goal_decision") ||
  lower_block.contains("next_check_hint")
}

///|
fn standing_watch_block_has_domain_delta(block : String) -> Bool {
  let decision = summary_field(block, "standing_goal_decision").to_lower()
  let accepted_facts = summary_field_int(block, "accepted_facts_count")
  let changed_pages = summary_field_int(block, "wiki_pages_changed_count")
  let book_changed = summary_field(block, "book_changed").to_lower()
  (decision == "update" || decision == "needs_review") &&
  (accepted_facts > 0 || changed_pages > 0 || book_changed == "yes")
}

///|
fn summary_field(content : String, key : String) -> String {
  let prefix = key.to_lower() + ":"
  for raw in content.split("\n") {
    let mut line = raw.trim().to_string()
    if line.has_prefix("- ") {
      line = line[2:].trim().to_string()
    }
    if line.to_lower().has_prefix("summary:") {
      line = line[8:].trim().to_string()
    }
    if line.to_lower().has_prefix(prefix) {
      return line[prefix.length():].trim().trim(chars="`").to_string()
    }
  }
  ""
}

///|
fn summary_field_int(content : String, key : String) -> Int {
  match first_non_negative_int(summary_field(content, key)) {
    Some(value) => value
    None => 0
  }
}

///|
fn first_non_negative_int(text : String) -> Int? {
  let mut seen = false
  let mut value = 0
  for char in text {
    if char >= '0' && char <= '9' {
      value = value * 10 + (char.to_int() - '0'.to_int())
      seen = true
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
fn append_evidence_accounting_summary(
  summary : String,
  accounting : EvidenceAccounting,
) -> String {
  let extra = "domain_evidence=\{accounting.domain_count} operational_evidence=\{accounting.operational_count} total_evidence=\{accounting.total_count}"
  if summary.contains("domain_evidence=") {
    summary
  } else if summary.is_empty() {
    extra
  } else {
    summary + " " + extra
  }
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
      "checked_sources_count: <integer>",
      "new_sources_found: <integer>",
      "accepted_facts_count: <integer>",
      "rejected_facts_count: <integer>",
      "wiki_pages_changed_count: <integer>",
      "book_changed: yes | no",
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
    "raw/bootstrap/RESEARCH_REQUEST.md", "raw/bootstrap/SOURCE_HINTS.md", "raw/bootstrap/REFERENCE_STYLE.md",
    "raw/bootstrap/REFERENCE_OUTPUT.md", "raw/bootstrap/REFERENCE_SOURCE_HINTS.md",
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
    "If `raw/bootstrap/REFERENCE_STYLE.md` or `raw/bootstrap/REFERENCE_OUTPUT.md` exists, use it only as a style, length, language, and quality target. Do not import its claims as evidence for this topic.",
    "If `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` exists, treat it as a candidate lead sheet only. Fetch, screen, accept, reject, or mark blocked; never cite it as evidence by itself.",
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
  let civic_context = is_wenyu_civic_context_bundle(bundle)
  let skill_paths = unique_paths(
    [
      ..bundle.skill_paths,
      ..if civic_context {
        [
          "skills/wenyu-civic-service/SKILL.md",
          ..skill_paths_from_context_pages(bundle.context_pages),
        ]
      } else {
        []
      },
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
      ..if civic_context {
        [
          "raw/bootstrap/CIVIC_SERVICE_CONTRACT.md", "book/moonbook-ui-state.json",
        ]
      } else {
        []
      },
    ],
  )
  let output_contract = if civic_context {
    unique_paths(
      [
        ..bundle.output_contract,
        "civic_service_decision: update | no_change | needs_review | blocked",
        "book_changed: yes | no",
        "wiki_pages_changed_count: <integer>",
        "accepted_facts_count: <integer>",
        "review_items_created_count: <integer>",
        "projection_updated: yes | no",
        "next_check_hint: normal | faster | slower | review",
      ],
    )
  } else {
    bundle.output_contract
  }
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
fn is_wenyu_civic_context_bundle(bundle : WorkerContextBundle) -> Bool {
  let combined = "\{bundle.task_id} \{bundle.prompt}".to_lower()
  combined.contains("civic-service") ||
  combined.contains("civic service") ||
  bundle.context_pages.any(fn(path) {
    path.contains("CIVIC_SERVICE_CONTRACT.md") ||
    path.contains("wenyu-civic-service/SKILL.md")
  })
}

///|
fn skill_paths_from_context_pages(pages : Array[String]) -> Array[String] {
  let skill_paths : Array[String] = []
  for page in pages {
    if page.has_prefix("skills/") && page.has_suffix("/SKILL.md") {
      skill_paths.push(page)
    }
  }
  skill_paths
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
    "\{root}/skills/research-report/SKILL.md",
    research_report_skill_text(entry),
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
    "      \"prompt_template\": \"Execute the source-screening stage of the imported Moontown research bootstrap packet for ${proposal.title}. Read raw/bootstrap/RESEARCH_REQUEST.md, raw/bootstrap/SOURCE_HINTS.md, raw/bootstrap/research-question.md, raw/bootstrap/search-log.md, optional raw/bootstrap/REFERENCE_STYLE.md, optional raw/bootstrap/REFERENCE_SOURCE_HINTS.md, and only the relevant source-screening SKILL.md files. Do not load the full reference report in this source-screening stage; REFERENCE_STYLE.md already contains the style target and line count. Reference output is not evidence, but its route names, comparison axes, diagrams, and section taxonomy may be used as hypothesis/search leads only when they are summarized by REFERENCE_STYLE.md or SOURCE_HINTS.md and relevant to the user objective. Reference source hints are not evidence; they are candidate leads that must be fetched, screened, accepted, rejected, or marked blocked. Verify every adopted route independently. Use native web_search first when it is available, then use web_fetch on high-signal candidate pages. If a native web tool returns {bad request}, retry once with a simpler query or URL. If native web tools are unavailable, blocked, or return only weak search pages, fall back to bounded execute_command discovery. Weak native search means search-engine result URLs, redirect shells, snippets without source URLs, generic index pages, or fewer than six included inspected sources after native discovery. In fallback mode, you must call execute_command with bounded curl/front-door commands before closing source screening below six included sources. Fetch the search-result page itself, extract candidate result URLs and titles, then fetch selected result URLs; do not skip directly to guessed URLs unless search-result extraction is blocked. If search-result extraction is blocked, pivot to source-class front-door discovery: choose authoritative organizations for the topic, fetch their home pages, robots.txt, sitemap files, visible search/index pages, and navigation pages, harvest candidate links with topic keywords, then fetch selected candidates. When any front-door or sitemap step harvests candidate content URLs, convert the harvest into inspection: fetch at least eight high-signal candidate pages, or all harvested candidate pages if fewer than eight, unless each unfetched class is explicitly blocked. Do not stop at a sitemap/index harvest; harvested URLs are only leads until fetched and screened. In fallback/front-door mode, write a Command Fallback Attempts table with each command target, source class, harvested candidate count, fetched candidate count, and result. Do not treat the first guessed 404 URL as exhausting a source class. Use commands such as curl -L --max-time 12 against LLM-chosen search-result pages, source-domain front doors, robots.txt, sitemaps, index pages, and selected source URLs. First update raw/bootstrap/search-log.md with a source-screening plan, then immediately run the web-discovery tool path; do not spend a long model turn planning. Keep this pass bounded but serious: for comparative, route-map, or technology research, try to screen ten to fourteen accessible high-signal sources across primary, independent, research-institution, market/adoption, critique/risk, and primary-paper/source-data classes before synthesis. Six included sources is the minimum for a cautious report; ten or more is the preferred source base for a 12k-15k word dossier. Search pages, site search pages, hub pages, and index pages are discovery artifacts, not included evidence sources, unless the page itself contains substantive inspected claims; normally mark them discovery_only/candidate rather than include. Do not stop below six included inspected evidence sources merely because generic search pages are blocked; exhaust source-class front-door discovery and direct source-domain link harvesting first. Only proceed below six after twenty-four web/discovery attempts, recorded command fallback attempts, candidate-harvest conversion attempts, and an explicit source-depth blocker with ready_for_12k_dossier=false. Use high-signal URLs from SOURCE_HINTS.md and REFERENCE_SOURCE_HINTS.md as leads, but let the LLM choose which sources to include, exclude, or mark blocked. Use search pages only for discovery, never as claim evidence. Do not inspect local implementation files unless SOURCE_HINTS.md explicitly permits it. Write or revise raw/bootstrap/search-log.md, raw/bootstrap/source-screen.md, and raw/bootstrap/tool-blockers.md. Do not ask for more input; weak coverage is a blocker to record, not a reason to stall. If something feels missing, write the missing source class into tool-blockers.md and complete the best research pass from available screened leads; never return a missing-input/adaptive-planning response. Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan. After these files are written, immediately return a concise completion summary with source counts, rejected sources, blockers, ready_for_12k_dossier, and whether synthesis has enough evidence.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"web-first-research\",",
    "          \"source-diarize\"", "        ],", "        \"enable_tools\": true,",
    "        \"web_search\": true,", "        \"disable_adaptive\": true,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"best_effort_on_timeout\": true,",
    "        \"retry_max_attempts\": 3,", "        \"retry_backoff_ms\": 4000,",
    "        \"timeout_ms\": 900000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 0,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.sources.v1\"", "        }",
    "      }", "    },", "    {", "      \"id\": \"research_bootstrap_source_expansion\",",
    "      \"title\": \"Expand weak source screens with command fallback\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the focused source-expansion stage of the imported Moontown research bootstrap packet for ${proposal.title}. Start by reading raw/bootstrap/RESEARCH_REQUEST.md, raw/bootstrap/search-log.md, raw/bootstrap/source-screen.md, raw/bootstrap/tool-blockers.md, raw/bootstrap/SOURCE_HINTS.md, and skills/web-first-research/SKILL.md. This step exists only to fix thin or weak source screens; do not write the final report. If source-screen.md already has six or more included inspected evidence sources, verify the count, add a short no-op note to search-log.md, and finish. Otherwise, perform command-line fallback and source-domain front-door discovery now. You must call execute_command with bounded curl commands before returning when native search was weak. Fetch search-result pages when useful; if search pages block extraction, fetch source-domain front doors, robots.txt, sitemaps, and selected candidate content URLs. When sitemaps or front doors harvest candidate content URLs, fetch at least eight high-signal candidate pages, or all harvested candidates when fewer than eight, unless the domain blocks access. Convert fetched content pages into source-screen rows with include, exclude, discovery_only, or blocked decisions. Search/index/hub pages and sitemaps are not evidence unless they contain substantive inspected claims. Revise raw/bootstrap/search-log.md with Command Fallback Attempts and harvested/fetched counts. Revise raw/bootstrap/source-screen.md with accurate included_source_count and ready_for_12k_dossier. Revise raw/bootstrap/tool-blockers.md with exact blocked source classes. If you still cannot reach six included sources after command fallback and candidate conversion, record why; do not invent claims and do not ask for input. Return plain Markdown with included source count, command fallback count, fetched candidate count, blockers, and whether the next report step may target 12k-15k words.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"web-first-research\",",
    "          \"source-diarize\"", "        ],", "        \"enable_tools\": true,",
    "        \"web_search\": true,", "        \"disable_adaptive\": true,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"best_effort_on_timeout\": true,",
    "        \"retry_max_attempts\": 2,", "        \"retry_backoff_ms\": 4000,",
    "        \"timeout_ms\": 900000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 1,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.source_expansion.v1\"", "        }",
    "      }", "    },", "    {", "      \"id\": \"research_bootstrap_report\",",
    "      \"title\": \"Synthesize evidence and write research reports\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the synthesis stage of the imported Moontown research bootstrap packet for ${proposal.title}. Start by reading raw/bootstrap/source-screen.md, raw/bootstrap/search-log.md, raw/bootstrap/tool-blockers.md, raw/bootstrap/research-question.md, raw/bootstrap/RESEARCH_REQUEST.md, raw/bootstrap/SOURCE_HINTS.md, optional raw/bootstrap/REFERENCE_SOURCE_HINTS.md, optional raw/bootstrap/REFERENCE_STYLE.md, and optional raw/bootstrap/QUALITY_REPAIR.md. If raw/bootstrap/QUALITY_REPAIR.md exists and says `No active quality repair`, treat it as historical audit context only. If raw/bootstrap/QUALITY_REPAIR.md exists with active gaps and raw/bootstrap/deep-report.md already exists, treat this as repair mode: do not rewrite deep-report.md from scratch in this report stage, preserve the existing report structure and claims, refresh only obviously stale companion artifacts, and leave length expansion or detailed review to research_bootstrap_quality_repair unless deep-report.md is missing. Do not load the full raw/bootstrap/REFERENCE_OUTPUT.md in this draft stage; use REFERENCE_STYLE.md for language, length class, and visual/table expectations when it exists. Read only the directly relevant synthesis/report/marketing SKILL.md files. Do not run new web discovery in this stage and do not ask for more input. Use the screened sources and blockers as the evidence boundary, even if the source set is thin. Treat reference output as a style, language, structure, length, candidate-route taxonomy, and visualization target only; do not copy its domain claims unless independently supported by screened sources for this topic. Treat reference source hints only as already-screened lead metadata; if a hinted source was not screened, it belongs in Evidence and Limits, not in claims. If no reference report exists, use `skills/research-report/SKILL.md` as the quality authority: for complex external, comparative, route-map, or technology research with six or more included sources, the draft should aim for a 13k-15k English-word deep dossier, not a short executive article; 12k English words is only the acceptance floor, so aim above it to avoid near-miss drafts. If the source base is too thin for that length, write the best honest draft and explicitly name which source classes prevent full depth. Write analysis, route mechanics, evidence interpretation, adoption logic, and limits. Write or revise raw/bootstrap/local-sources.md, raw/bootstrap/evidence-matrix.md, raw/bootstrap/synthesis-brief.md, raw/bootstrap/deep-report.md, and raw/bootstrap/marketing-brief.md. If evidence is weak, write a cautious report with explicit Evidence and Limits, missing-source blockers, and next research; do not stall waiting for stronger evidence. The report must be topic-correct, source-backed, thesis-first, evidence-limited, and governed by the loaded research skills. Before returning, perform a tool-backed self-review of deep-report.md: count English words, section headings, included screened sources, tables, Mermaid blocks, topic correctness, and process-log leakage; if any fixable quality gap remains, revise the report in-place immediately instead of leaving the issue for the review stage. Do not reinterpret external domain topics as local repositories unless screened sources prove that meaning. Do not update wiki pages in this worker stage; raw artifacts are the handoff for MoonBook materialization. Return plain Markdown, not JSON; do not use fields named verdict, substeps, suggested_substeps, or needs_subplan. After the files are written and self-reviewed, immediately return the artifact paths, source counts, blockers, report word count, report quality gaps if any, and whether the evidence is strong enough for MoonBook wiki materialization.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"research-evidence-synthesis\",",
    "          \"research-report\",", "          \"wiki-marketing\"", "        ],",
    "        \"enable_tools\": true,", "        \"web_search\": false,", "        \"disable_adaptive\": true,",
    "        \"disable_waiting_for_input\": true,", "        \"best_effort_on_missing_input\": true,",
    "        \"best_effort_on_timeout\": true,", "        \"retry_max_attempts\": 2,",
    "        \"retry_backoff_ms\": 4000,", "        \"timeout_ms\": 900000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 2,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.report.v1\"", "        }",
    "      }", "    },", "    {", "      \"id\": \"research_bootstrap_quality_repair\",",
    "      \"title\": \"Review gate and repair research report if needed\",", "      \"kind\": \"job.analysis\",",
    "      \"prompt_template\": \"Execute the final deep-research review gate for ${proposal.title}. Read raw/bootstrap/source-screen.md, raw/bootstrap/evidence-matrix.md, raw/bootstrap/synthesis-brief.md, raw/bootstrap/deep-report.md, raw/bootstrap/marketing-brief.md, optional raw/bootstrap/QUALITY_REPAIR.md, skills/research-report/SKILL.md, and optional raw/bootstrap/REFERENCE_STYLE.md. Use tools to count English word tokens, lines, sections, tables, Mermaid blocks, and included source rows. If raw/bootstrap/REFERENCE_OUTPUT.md exists, count its lines but do not load the full reference report unless REFERENCE_STYLE.md is insufficient. If no reference exists, do not ask for one; the skill is the quality contract. First judge whether the report already passes; if it passes, record a no-op review with measured counts and do not rewrite for churn. If fixable gaps remain, repair in-place in raw/bootstrap/deep-report.md rather than creating v2/v3/v4 files or a new book. For complex external, comparative, route-map, or technology research with six or more included sources, revise raw/bootstrap/deep-report.md toward a 13k-15k English-word dossier with a hard acceptance floor of 12k words unless the source-screen explicitly records a source-depth blocker. Use the tool-counted word count, not visual length; if the count is below 13k and evidence exists, keep expanding from screened evidence until it is safely above 12k. If a long reference exists, also satisfy the reference line-count target. Expand only from screened evidence by adding mechanism analysis, route-by-route sections, source-reliability analysis, maturity/adoption filters, bottlenecks, scenarios, second-order implications, what would change the thesis, and explicit evidence limits. Do not add unsupported claims, do not copy reference facts, and do not hard-code topic facts outside screened evidence. Also revise raw/bootstrap/marketing-brief.md only if the report title or thesis changed. Return plain Markdown with before/after word counts, line counts, section count, source count, whether repair was needed, and remaining quality gaps.\",",
    "      \"metadata\": {", "        \"preferred_skills\": [", "          \"research-report\",",
    "          \"research-evidence-synthesis\"", "        ],", "        \"enable_tools\": true,",
    "        \"web_search\": false,", "        \"disable_adaptive\": true,", "        \"disable_waiting_for_input\": true,",
    "        \"best_effort_on_missing_input\": true,", "        \"best_effort_on_timeout\": true,",
    "        \"retry_max_attempts\": 2,", "        \"retry_backoff_ms\": 4000,",
    "        \"timeout_ms\": 900000,", "        \"board_lane\": \"Bootstrap\",",
    "        \"board_order\": 3,", "        \"role_runtime\": {", "          \"planning_layer\": \"execution\",",
    "          \"runtime_mode\": \"executor\",", "          \"tool_access\": \"full\",",
    "          \"memory_scope\": \"workspace\",", "          \"allow_delegate\": false,",
    "          \"allow_workspace_write\": true,", "          \"allow_execution_tools\": true,",
    "          \"output_contract\": \"moontown.research.quality_repair.v1\"", "        }",
    "      }", "    }", "  ],", "  \"metadata\": {", "    \"profile_metadata\": {",
    "      \"disable_adaptive\": true,", "      \"disable_waiting_for_input\": true,",
    "      \"best_effort_on_missing_input\": true", "    },", "    \"worker_role\": \"research_bootstrap\"",
    "  }", "}",
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
    "- Depth target: for complex external, comparative, route-map, or technology research, `raw/bootstrap/deep-report.md` should target 12k-15k English words when the screened source base has enough evidence. If the source base cannot support that depth, write the exact source-class blocker rather than padding.",
    "- Reference style: if `raw/bootstrap/REFERENCE_STYLE.md` or `raw/bootstrap/REFERENCE_OUTPUT.md` exists, match its depth, length, section discipline, language, tables, and visualization standard. Treat it as a style target and candidate search-taxonomy source only, not evidence for \{display}.",
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
    "2. Run at least three targeted web-discovery attempts before local file discovery. Use native `web_search` when available; if it returns only weak search pages, redirect shells, or fewer than six included inspected sources, use bounded command-line discovery such as `curl -L --max-time 12` against LLM-chosen search pages and candidate URLs before closing the source-screening stage.",
    "   - If native search only returns search-engine pages, fetch those result pages with `execute_command`/`curl` when native fetch cannot extract results, extract result URLs and titles, and then inspect selected result URLs before guessing direct source URLs.",
    "   - If search-result extraction is blocked, switch to source-domain front-door discovery: choose authoritative organizations for each source class, fetch home pages, robots/sitemaps, on-site search/index pages, and navigation pages, harvest candidate links, then fetch selected pages.",
    "   - Record a `Command Fallback Attempts` table in `raw/bootstrap/search-log.md` whenever native search is weak and the source screen remains below six included inspected sources.",
    "   - If sitemaps or front-door pages harvest candidate content URLs, fetch at least eight high-signal candidate pages, or all harvested candidate pages when fewer than eight, before declaring source depth blocked.",
    "   - Do not treat one guessed 404 as a failed source class. A source class is only exhausted after front-door discovery and bounded link harvesting fail.",
    web_priority,
    "4. Write `raw/bootstrap/search-log.md` with query strings, result counts if available, selected URLs, rejected URLs, and the reason for each decision.",
    "5. Write `raw/bootstrap/source-screen.md` with one row per inspected source: include/exclude, authority, recency, relevance, and risk. For complex external research, aim for at least six included inspected evidence sources before synthesis; search/index/hub pages are discovery artifacts and should not count unless they contain substantive inspected claims. If impossible after bounded source-domain discovery, write `ready_for_12k_dossier: false` and the exact source-depth blocker.",
    "6. Extract claims into `raw/bootstrap/evidence-matrix.md` before synthesis. Use claim IDs like `C1`, `C2`, and cite source IDs like `W1` or `L1`.",
    local_step,
    "8. Write `raw/bootstrap/local-sources.md` with exact paths, symbols or sections inspected, and evidence bullets.",
    "9. Write `raw/bootstrap/synthesis-brief.md` that separates findings, contradictions, gaps, and next research.",
    "10. Write `raw/bootstrap/deep-report.md` using `skills/research-report/SKILL.md`. Prefer a 12k-15k English-word deep dossier for complex external/technology-route research with enough screened sources. If a reference report exists, also match its reader-facing ambition and approximate length class without copying unsupported claims.",
    "11. Write `raw/bootstrap/marketing-brief.md` using `skills/wiki-marketing/SKILL.md`: buyer pain, promise, differentiation, proof, objections, and next action.",
    "12. If running inside MoonBook, materialize durable wiki pages. If running inside a direct MoonClaw worker, stop at wiki-ready raw artifacts and clearly mark whether MoonBook has enough evidence to materialize pages.",
    "",
    "## Blocking Rule",
    "",
    "If a tool is unavailable, record the exact blocker in `raw/bootstrap/tool-blockers.md`, continue with the remaining permitted path, and still create the durable bootstrap notes that explain what happened.",
    "If native `web_search` returns only a search-engine result page or query URL, fetch that page, extract candidate URLs if possible, and retry with broader or narrower query variants before declaring the web pass blocked.",
    "If native `web_search` is disabled, stalls, or only returns weak search pages, use bounded command-line web discovery such as `curl -L --max-time 12` against LLM-chosen search-result pages and candidate URLs. Retry `{bad request}` once with a simpler query or URL before recording a blocker.",
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
  lines.push("")
  lines.push("## Optional Reference Style Inputs")
  lines.push("")
  lines.push(
    "- `raw/bootstrap/REFERENCE_STYLE.md`: if present, explains how to use user-supplied reference material as a style and quality target.",
  )
  lines.push(
    "- `raw/bootstrap/REFERENCE_OUTPUT.md`: if present, match its length class, section discipline, evidence density, tables, visualization style, and language when appropriate.",
  )
  lines.push(
    "- `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`: if present, use it as a candidate lead sheet only. Every lead still needs source screening before it can support claims.",
  )
  lines.push(
    "- Reference files are not evidence for \{display}; use them to improve report craft, not to import facts.",
  )
  lines.push(
    "- If the reference report names candidate routes, comparison axes, or visual dimensions that fit the user's objective, use them as search hypotheses and independently screen sources for each adopted route.",
  )
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
    "## Research Temperament",
    "",
    "Good research needs more than correctness.",
    "",
    "- Use imagination to form hypotheses, adjacent-domain search angles, and second-order implications. Do not invent facts.",
    "- Use curiosity to ask why the topic matters now, what would surprise the current book, who benefits, who is harmed, and what evidence would change the synthesis.",
    "- Use judgement to prefer high-signal sources and reject noise, stale mirrors, shallow commentary, and operational busywork.",
    "- End with a point of view: what changed, what did not change, why it matters, and what should be watched next.",
    "",
    "## Reference Style Discipline",
    "",
    "- If `raw/bootstrap/REFERENCE_STYLE.md` or `raw/bootstrap/REFERENCE_OUTPUT.md` exists, read it before synthesis and use it to match the expected quality bar.",
    "- Treat reference files as craft guidance only: length class, language, section architecture, table density, visualization type, and level of analytical courage.",
    "- Treat reference route names, comparison axes, and diagram dimensions as hypotheses/search leads when they fit the user's objective; verify them with current screened sources before including them.",
    "- Never use reference-file claims as evidence for \{display} unless independent screened sources support them.",
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
    "- If native `web_search` or `web_fetch` is disabled, unavailable, stalls, returns only search-engine/redirect pages, or leaves the source base below six included inspected sources, use bounded `execute_command` discovery such as `curl -L --max-time 12` against LLM-chosen search-result pages and candidate URLs before local file discovery.",
    "- In command-line discovery mode, first write the planned query/source-screening strategy to `raw/bootstrap/search-log.md`, then run a small bounded command batch. Do not spend a long model turn planning before the first durable write or command.",
    "- Run at least three web queries for this topic.",
    "- For comparative or technology-route research, try to cover at least six high-signal sources across primary, independent, research-institution, market/adoption, and critique/risk classes before synthesis. Ten or more included sources is preferred for a 12k-15k dossier.",
    "- Do not count search pages, site search pages, hub pages, or index pages as included evidence just because they were fetched. Use `discovery_only`, `candidate`, or `exclude` unless the page itself contains substantive inspected claims.",
    "- Keep discovery bounded but serious. Do not stop below six included inspected sources merely because generic search-result pages are blocked. First try source-class front-door discovery, domain sitemaps, on-site search/index pages, and link harvesting.",
    "- When sitemap/front-door harvesting yields candidate content URLs, convert the harvest into inspected sources: fetch at least eight high-signal candidates, or every harvested candidate when fewer than eight, before declaring the source base thin.",
    "- Stop below six included sources only after twenty-four web/discovery attempts and an explicit source-depth blocker. In that case write `ready_for_12k_dossier: false` into `raw/bootstrap/source-screen.md`.",
    authority_rule,
    "- After search, inspect at least two highest-signal pages before writing conclusions. Use native `web_fetch` if available; otherwise use bounded command-line fetches.",
    "- If native `web_search` returns only a search-engine URL or weak result page, fetch the result page with native fetch; if that cannot extract candidates, use `execute_command`/`curl`, extract candidates when possible, and retry query variants before writing a blocker.",
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
    "## Deep Dossier Target",
    "",
    "For complex external, comparative, route-map, or technology research, source collection should be strong enough to support a long-form dossier, not just a short article.",
    "",
    "- preferred source base: ten to fourteen included, inspected sources across primary, independent, research-institution, market/adoption, critique/risk, and primary-paper/source-data classes",
    "- minimum source base for a cautious dossier: six included, inspected sources plus explicit blockers for missing classes",
    "- target report size with enough evidence: 12k-15k English words",
    "- if this target cannot be reached honestly, write the source-depth blocker, set `ready_for_12k_dossier: false`, and write the next search plan; do not pad with generic definitions",
    "",
    "## Search-Result Fallback",
    "",
    "When native `web_search` returns only a search-engine page, weak landing page, or `{bad request}`, do not guess a final source list from memory.",
    "",
    "1. Fetch the search-result page itself with a bounded command such as `curl -L --max-time 12`; this command fallback is mandatory before closing below six included inspected sources when native search was weak.",
    "2. Extract candidate result URLs, titles, snippets, and domains into `raw/bootstrap/search-log.md`.",
    "3. Choose candidates across source classes: primary, independent, research institution, market/adoption, critique/risk, and source-data or paper.",
    "4. Fetch selected result URLs and only then include, reject, or block them in `raw/bootstrap/source-screen.md`.",
    "5. If search-result extraction is blocked, record the exact blocked page, command target, and source class in `raw/bootstrap/tool-blockers.md`.",
    "",
    "## Source-Class Front-Door Fallback",
    "",
    "If generic search pages block extraction, shift from search-engine discovery to source-domain discovery instead of guessing article URLs from memory.",
    "",
    "1. Derive source classes for the topic: primary/official, customer or adopter, research institution, standards or conference, market/adoption, independent critique, and source-data or paper.",
    "2. For each source class, choose candidate organizations or publications that a serious researcher would inspect for this topic.",
    "3. For each chosen domain, fetch the home page, `robots.txt`, one or more sitemap URLs if exposed, visible search or index pages, and high-signal navigation pages.",
    "4. Harvest candidate links whose titles, paths, or snippets match the topic keywords; write them into `raw/bootstrap/search-log.md` before fetching.",
    "5. Fetch at least eight high-signal harvested candidate pages, or all harvested candidates when fewer than eight, and screen them. A 404 on one guessed URL is a rejected candidate, not a rejected source class.",
    "6. Continue until the source screen has at least six included inspected sources, ten preferred, or until twenty-four bounded attempts plus a source-depth blocker make more discovery dishonest.",
    "",
    "Concrete front-door command pattern:",
    "",
    "- fetch `https://<domain>/robots.txt` and look for `Sitemap:` entries",
    "- fetch likely sitemap URLs such as `https://<domain>/sitemap.xml` only when chosen by the worker for that domain",
    "- fetch the domain home page and one visible topic/search/index page",
    "- extract candidate links containing topic terms, route names, or source-class terms",
    "- fetch candidate article/report/product/paper pages; only these fetched content pages normally count as included evidence",
    "- write a `Front-Door Attempts` table in `raw/bootstrap/search-log.md` with domain, command target, harvested candidates, fetched candidates, and result",
    "- write a `Command Fallback Attempts` table whenever native search was weak and command-line fetching was used",
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
    "## Research Temperament",
    "",
    "The goal is not to dump facts. The goal is to build understanding.",
    "",
    "- Imagination: propose plausible mechanisms and futures, then test them against evidence.",
    "- Curiosity: look for surprises, absences, contradictions, incentives, and second-order effects.",
    "- Judgement: decide what matters enough to become durable knowledge and what should be rejected or deferred.",
    "- Taste: make the synthesis useful to a human decision-maker, not just correct in isolation.",
    "",
    "## Reference-Aware Synthesis",
    "",
    "When a reference report is supplied, use it as a benchmark for research craft:",
    "",
    "- match its seriousness, section depth, table/diagram expectations, and approximate length class when the evidence supports that depth",
    "- preserve its language choice when the user has not asked otherwise",
    "- use its route taxonomy, comparison axes, and visual structure as candidate hypotheses only when the current topic calls for those comparisons",
    "- use optional `raw/bootstrap/REFERENCE_SOURCE_HINTS.md` only as a list of sources or searches to screen, not as evidence",
    "- do not copy its claims, source choices, or conclusions unless current screened evidence for \{display} independently supports them",
    "- if evidence is thinner than the reference, explain the gap and write the strongest honest version rather than padding with generic prose",
    "",
    "When no reference report is supplied, use the skill's own depth standard:",
    "",
    "- for complex external, comparative, route-map, or technology research, target a 12k-15k English-word dossier when the screened source base has enough evidence",
    "- six included inspected sources is the minimum for a cautious dossier; ten or more included sources is the preferred source base for a reference-grade report",
    "- build length from explanation depth: mechanisms, route tradeoffs, adoption constraints, evidence reliability, scenarios, second-order implications, and what would change the thesis",
    "- do not pad with repeated definitions, unverified background, or generic process notes",
    "- if the source base is too thin, say exactly which missing source classes block full depth",
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
fn research_report_skill_text(entry : BookCatalogEntry) -> String {
  let topic = research_topic_id(entry)
  let display = display_topic_name(topic)
  [
    "---",
    "name: research-report",
    "description: Turn screened research artifacts into a long-form, reader-facing deep research report with evidence-backed claims, comparison tables, diagrams, and explicit limits.",
    "---",
    "",
    "# Research Report Skill For \{display}",
    "",
    "Use this skill after source collection and evidence extraction. It is not a source-fetching skill; if evidence is missing, write blockers and limits instead of inventing claims.",
    "",
    "## Non-Negotiable Output",
    "",
    "Always produce or revise `raw/bootstrap/deep-report.md` when `raw/bootstrap/evidence-matrix.md` exists.",
    "",
    "Hard requirements:",
    "",
    "- title: the first heading must contain `Deep Research Analysis`; use `# \{display}: Deep Research Analysis` unless there is a strong reason to add a subtitle",
    "- at least 8 `##` sections for a single-topic report",
    "- first `##` section: `## Executive Summary`",
    "- at least one comparison, evidence, roadmap, or maturity table",
    "- at least one Mermaid relationship, route, or decision diagram when relationships or routes matter",
    "- source IDs on strong claims",
    "- a final `## Evidence and Limits` section",
    "- process/tool caveats only in the limits section unless they invalidate the thesis",
    "- for complex external, comparative, route-map, or technology research with enough screened sources: target 12k-15k English words; 12k English words is the quality floor unless explicit source-depth blockers make that dishonest",
    "",
    "This word target is not a license to pad. Reach it through evidence-backed mechanism analysis, route-by-route judgement, adoption constraints, second-order implications, and source reliability work.",
    "",
    "## Reference Output Rule",
    "",
    "If these files exist, read them before writing:",
    "",
    "- `raw/bootstrap/REFERENCE_STYLE.md`",
    "- `raw/bootstrap/REFERENCE_OUTPUT.md`",
    "- `raw/bootstrap/REFERENCE_SOURCE_HINTS.md`",
    "- `raw/bootstrap/REFERENCE_VISUAL_PATH.txt`",
    "",
    "Use reference material only as a style and quality benchmark:",
    "",
    "- match its approximate length class when evidence supports that length",
    "- match its section discipline, evidence density, table density, strategic conclusions, and visual-analysis ambition",
    "- if the reference report is hundreds of lines long, write a hundreds-of-lines report rather than a short executive brief; when `REFERENCE_STYLE.md` reports the line count and `source-screen.md` has at least six included sources, target at least 60% of the reference line count plus a 30-line safety buffer",
    "- if evidence is narrower than the reference, expand by explaining mechanisms, route tradeoffs, adoption logic, bottlenecks, source reliability, and what evidence would change the thesis; do not pad with repeated definitions or unsupported facts",
    "- use route names, comparison axes, and visual dimensions found in the reference as candidate search and synthesis hypotheses when relevant, but verify each adopted route independently",
    "- use reference source hints only when `source-screen.md` or `evidence-matrix.md` shows they were inspected; unscreened hints belong in gaps, not claims",
    "- preserve its language choice when the user has not asked otherwise",
    "- never import its factual claims into \{display} unless independently supported by screened evidence",
    "- if the reference is stronger than the available evidence, state the evidence gap and write the strongest honest report instead of padding",
    "",
    "## No-Reference Deep Research Rule",
    "",
    "When no reference report is supplied, do not fall back to a short default report.",
    "",
    "- Use this skill as the quality authority.",
    "- With six or more included inspected sources, write toward the 12k-15k English-word dossier target.",
    "- With fewer than six included inspected sources, write the strongest honest report and make the source-depth blocker explicit.",
    "- Prefer ten or more included inspected sources before claiming reference-grade depth.",
    "- Expand by asking researcher questions: what mechanism actually creates the advantage, what adoption filter blocks it, which route is only a supplement, what would change the thesis, and what second-order consequence matters.",
    "",
    "## Research Temperament",
    "",
    "Correctness is necessary but not sufficient.",
    "",
    "- Imagination: propose mechanisms, futures, substitutions, hidden constraints, and second-order consequences; then test them against evidence.",
    "- Curiosity: ask why the topic matters now, what changed recently, what would surprise a serious reader, and which missing fact would change the conclusion.",
    "- Judgement: rank evidence quality, reject weak sources, distinguish signal from hype, and decide what deserves durable memory.",
    "- Taste: write with a point of view. The report should help a human make sense of the topic, not merely prove that a pipeline ran.",
    "",
    "## Required Inputs",
    "",
    "- `raw/bootstrap/research-question.md`",
    "- `raw/bootstrap/search-log.md`",
    "- `raw/bootstrap/source-screen.md`",
    "- `raw/bootstrap/evidence-matrix.md`",
    "- `raw/bootstrap/local-sources.md`",
    "- `raw/bootstrap/synthesis-brief.md`",
    "- `wiki/sources/*.md`",
    "- `wiki/entities/*.md`",
    "- `wiki/concepts/*.md`",
    "- `wiki/synthesis/*.md`",
    "",
    "## Article Shape",
    "",
    "Use this shape unless the evidence clearly calls for a better structure:",
    "",
    "1. Executive Summary",
    "2. Research Question and Scope",
    "3. Ecosystem Context",
    "4. Core Thesis",
    "5. Technical Routes or Architecture",
    "6. Evidence and Key Claims",
    "7. Comparison and Tradeoffs",
    "8. Maturity, Bottlenecks, and Adoption Signals",
    "9. Roadmap and Watch Points",
    "10. Evidence and Limits",
    "",
    "For technology-route research, compare alternatives by performance, manufacturability, cost, maturity, supply chain, scalability, and unresolved physics or engineering bottlenecks when the evidence supports those dimensions.",
    "For long-form reference-matched technology research, create section depth from reasoning over screened claims: explain mechanisms, dependencies, adoption constraints, what would change the conclusion, and why each route is or is not a supplement. Do not fill length with repeated definitions.",
    "",
    "## Quality Rubric",
    "",
    "| Dimension | Strong output | Weak output |",
    "| --- | --- | --- |",
    "| Thesis | Opens with a clear interpretation and why it matters now | Opens with workspace/process notes |",
    "| Evidence | Converts source rows into claim-backed paragraphs | Lists sources without synthesis |",
    "| Comparison | Explains tradeoffs across alternatives | Ranks things without criteria |",
    "| Specificity | Names concrete actors, technologies, dates, metrics, and bottlenecks when sourced | Uses generic claims that could fit any topic |",
    "| Judgement | Separates near-term reality, plausible supplement, and speculative route | Treats every idea as equally viable |",
    "",
    "## Concrete Example",
    "",
    "```md",
    "# \{display}: Deep Research Analysis",
    "",
    "## Executive Summary",
    "",
    "<Answer the research question directly in one or two dense paragraphs. Cite strongest source IDs.>",
    "",
    "## Technical Route Comparison",
    "",
    "| Route | Advantage | Bottleneck | Maturity | Evidence |",
    "| --- | --- | --- | --- | --- |",
    "| Route A | Supported advantage | Specific unresolved issue | pilot / mature / speculative | W1, W3 |",
    "",
    "## Relationship Model",
    "",
    "```mermaid",
    "flowchart LR",
    "  Need[Manufacturing need] --> RouteA[Route A]",
    "  Need --> RouteB[Route B]",
    "  RouteA --> Constraint[Shared bottleneck]",
    "  RouteB --> Supplement[Supplementary use case]",
    "```",
    "",
    "## Evidence and Limits",
    "",
    "- Strongest sources: W1, W2, W3.",
    "- Weakest point: <missing source, uncertainty, or contradiction>.",
    "```",
    "",
    "Before returning success, revise if the draft is short, generic, missing tables, missing diagram, not lane-specific to \{topic}, or reads like a run log.",
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
  for tag in entry.tags {
    if tag.has_prefix("topic:") {
      let topic = tag[6:].to_string()
      if !topic.is_empty() {
        return topic
      }
    }
  }
  if entry.id.has_prefix("research-") {
    entry.id[9:].to_string()
  } else {
    normalize_topic_id(entry.id)
  }
}

///|
fn is_external_domain_research_topic(topic : String) -> Bool {
  !is_local_project_research_topic(topic)
}

///|
fn is_local_project_research_topic(topic : String) -> Bool {
  match topic {
    "moontown" | "moonbook" | "moonclaw" => true
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
    _ if is_external_domain_research_topic(topic) =>
      "What is \{display}, what new advantages or supplements are emerging, what evidence shows their technical and market significance, what routes or alternatives should be compared, what bottlenecks remain, and what should be watched next?"
    _ =>
      "What is \{display}, what problem does it solve, how is it implemented or operated, what evidence supports those claims, and what remains uncertain?"
  }
}

///|
fn research_followup_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "AI solo founder one person company trend"
    _ if is_external_domain_research_topic(topic) =>
      "\{display} latest research advantages limitations roadmap"
    _ => "\{display} architecture implementation"
  }
}

///|
fn research_risk_query(topic : String, display : String) -> String {
  match topic {
    "opc" => "one person company risks operations legal finance"
    _ if is_external_domain_research_topic(topic) =>
      "\{display} bottlenecks risks supply chain adoption"
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
    _ if is_external_domain_research_topic(topic) => {
      let display = display_topic_name(topic)
      [
        "\{display} latest research advantages limitations",
        "\{display} technology roadmap 2026",
        "\{display} market analysis suppliers adoption",
        "\{display} new advances bottlenecks comparison",
        "\{display} research report risks supplements",
        "\{display} alternatives complementary technologies comparison",
        "\{display} route comparison maturity cost scalability",
      ]
    }
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
    _ if is_external_domain_research_topic(topic) => []
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
    _ if is_external_domain_research_topic(topic) => []
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
