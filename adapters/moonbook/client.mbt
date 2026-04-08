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
  {
    workspace_root: "/books/\{req.book_id}",
    memory_scope: @core.MemoryScope::BookPrivate,
    context_summary: "starter context for \{req.task_id}",
    skills: ["analysis", "memory", "review"],
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
