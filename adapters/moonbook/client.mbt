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
pub struct BookPlanRequest {
  book_id : String
  goal_id : String
  title : String
  prompt : String
} derive(Show, Eq)

///|
pub struct BookTaskDraft {
  id : String
  title : String
  prompt : String
  required_role : @core.WorkerRole?
} derive(Show, Eq)

///|
pub struct BookPlanResponse {
  task_drafts : Array[BookTaskDraft]
  summary : String
  warnings : Array[String]
} derive(Show, Eq)

///|
pub struct BookHydrationRequest {
  book_id : String
  task_id : String
} derive(Show, Eq)

///|
pub struct BookHydrationResponse {
  workspace_root : String
  memory_scope : @core.MemoryScope
  context_summary : String
  skills : Array[String]
} derive(Show, Eq)

///|
pub struct BookPersistRequest {
  book_id : String
  task_id : String
  result_summary : String
  memory_candidates : Array[String]
} derive(Show, Eq)

///|
pub struct BookHealthResponse {
  book_id : String
  status : String
  detail : String
} derive(Show, Eq)

///|
pub fn stub_plan(req : BookPlanRequest) -> BookPlanResponse {
  {
    task_drafts: [
      {
        id: "\{req.goal_id}-draft",
        title: req.title,
        prompt: req.prompt,
        required_role: Some(@core.WorkerRole::Harness),
      },
    ],
    summary: "moonbook plan stub for \{req.book_id}",
    warnings: [],
  }
}

///|
pub fn stub_hydrate(req : BookHydrationRequest) -> BookHydrationResponse {
  let catalog = default_catalog()
  match find_catalog_entry(catalog, req.book_id) {
    Some(entry) =>
      {
        workspace_root: entry.workspace_root,
        memory_scope: entry.memory_scope,
        context_summary: "starter context for \{req.task_id}",
        skills: entry.skills,
      }
    None =>
      {
        workspace_root: "/books/\{req.book_id}",
        memory_scope: @core.MemoryScope::BookPrivate,
        context_summary: "starter context for \{req.task_id}",
        skills: ["analysis", "memory", "review"],
      }
  }
}

///|
pub fn stub_persist(req : BookPersistRequest) -> String {
  "persisted \{req.task_id} into \{req.book_id} with \{req.memory_candidates.length()} candidates"
}

///|
pub fn stub_health(book_id : String) -> BookHealthResponse {
  { book_id, status: "healthy", detail: "moonbook adapter stub" }
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
