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
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct MemoryCandidate {
  kind : String
  title : String
  detail : String
  durable : Bool
  target_page : String?
} derive(Debug, Eq, ToJson, FromJson)

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
  result_id : String
  summary : String
  artifacts : Array[String]
  memory_candidates : Array[MemoryCandidate]
  requires_review : Bool
  notify_town : Bool
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn BookResult::new(
  result_id~ : String,
  summary~ : String,
  artifacts? : Array[String] = [],
  memory_candidates? : Array[MemoryCandidate] = [],
  requires_review? : Bool = false,
  notify_town? : Bool = false,
) -> BookResult {
  {
    result_id,
    summary,
    artifacts,
    memory_candidates,
    requires_review,
    notify_town,
  }
}

///|
pub fn decode_book_result_payload(value : Json) -> BookResult? {
  let direct : BookResult = @json.from_json(value) catch {
    _ => return decode_book_result_envelope(value)
  }
  Some(direct)
}

///|
fn decode_book_result_envelope(value : Json) -> BookResult? {
  match value {
    Object(fields) =>
      match fields.get("book_result") {
        Some(nested) => {
          let result : BookResult = @json.from_json(nested) catch {
            _ => return None
          }
          Some(result)
        }
        None => None
      }
    _ => None
  }
}

///|
pub fn BookResult::to_executable_book_event(
  self : BookResult,
  book_id~ : String,
  evidence_id? : String? = None,
  run_id? : String? = None,
  review_path? : String? = None,
) -> @moonbook_contracts.ExecutableBookEvent {
  let evidence_part = evidence_id.unwrap_or(self.result_id)
  let event_type = if self.requires_review {
    "review_required"
  } else {
    "knowledge_accepted"
  }
  @moonbook_contracts.ExecutableBookEvent::new(
    id="book-event-\{book_id}-\{evidence_part}",
    book_id~,
    result_id=self.result_id,
    summary=self.summary,
    artifacts=self.artifacts,
    run_id~,
    event_type~,
    accepted=!self.requires_review,
    requires_review=self.requires_review,
    notify_town=self.notify_town,
    evidence_id~,
    review_path~,
  )
}

///|
pub struct PersistResultOutcome {
  log_path : String
  updated_pages : Array[String]
  review_queued : Bool
  notify_town : Bool
  evidence_id : String
  executable_event_path : String
  latest_executable_event_path : String
  executable_event : @moonbook_contracts.ExecutableBookEvent
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn PersistResultOutcome::new(
  log_path~ : String,
  updated_pages~ : Array[String],
  review_queued~ : Bool,
  notify_town~ : Bool,
  evidence_id~ : String,
  executable_event_path~ : String,
  latest_executable_event_path~ : String,
  executable_event~ : @moonbook_contracts.ExecutableBookEvent,
) -> PersistResultOutcome {
  {
    log_path,
    updated_pages,
    review_queued,
    notify_town,
    evidence_id,
    executable_event_path,
    latest_executable_event_path,
    executable_event,
  }
}
