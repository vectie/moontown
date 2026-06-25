///|
pub fn wiki_maintainer_skill_path() -> String {
  "skills/wiki-maintainer/SKILL.md"
}

///|
pub fn default_keeper_skill_paths() -> Array[String] {
  [wiki_maintainer_skill_path()]
}

///|
pub fn default_keeper_context_pages() -> Array[String] {
  ["wiki/index.md", "wiki/log.md"]
}

///|
pub fn fallback_keeper_policy_lines() -> Array[String] {
  [
    "Keep all memory and durable artifacts inside this book unless the task explicitly names a repository patch.",
    "Return explicit blockers instead of fake completion when required tools or sources are missing.",
    "Preserve Moontown, MoonBook, and MoonClaw responsibility boundaries.",
  ]
}

///|
pub fn fallback_keeper_routine_lines() -> Array[String] {
  [
    "Read task context pages first.", "Create or update target pages listed in the task when applicable.",
    "Report changed files, artifacts, blockers, and validation results.",
  ]
}

///|
pub fn fallback_keeper_memory_summary(
  book_id : String,
  task_id : String,
) -> String {
  "Fallback MoonBook context for externally planned task `\{task_id}` in book `\{book_id}`."
}

///|
pub fn fallback_keeper_output_contract_lines() -> Array[String] {
  [
    "result_id", "summary", "artifacts", "memory_candidates", "requires_review",
    "notify_town",
  ]
}

///|
pub fn executable_book_event_protocol() -> String {
  "moonbook.executable_event.v1"
}

///|
pub struct ExecutableBookLifecycleProof {
  contract_id : String
  owner : String
  session_id : String
  book_root : String
  ready : Bool
  status : String
  completed_step_count : Int
  step_count : Int
  blocked_step_count : Int
  first_blocker_id : String
  first_blocker_label : String
  first_blocker_evidence : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub struct ExecutableBookEvent {
  protocol : String
  id : String
  source : String
  book_id : String
  result_id : String
  run_id : String?
  event_type : String
  accepted : Bool
  requires_review : Bool
  notify_town : Bool
  summary : String
  artifacts : Array[String]
  evidence_id : String?
  review_path : String?
  lifecycle_proof : ExecutableBookLifecycleProof?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn ExecutableBookEvent::new(
  id~ : String,
  book_id~ : String,
  result_id~ : String,
  summary~ : String,
  artifacts? : Array[String] = [],
  run_id? : String? = None,
  event_type? : String = "knowledge_accepted",
  accepted? : Bool = true,
  requires_review? : Bool = false,
  notify_town? : Bool = false,
  evidence_id? : String? = None,
  review_path? : String? = None,
  lifecycle_proof? : ExecutableBookLifecycleProof? = None,
) -> ExecutableBookEvent {
  {
    protocol: executable_book_event_protocol(),
    id,
    source: "moonbook",
    book_id,
    result_id,
    run_id,
    event_type,
    accepted,
    requires_review,
    notify_town,
    summary,
    artifacts,
    evidence_id,
    review_path,
    lifecycle_proof,
  }
}

///|
pub struct ExecutableBookEventRoute {
  town_event : @core.TownEvent
  notify_operator : Bool
  lifecycle_status : String
  lifecycle_ready : Bool
  first_blocker_id : String
  route_reason : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn ExecutableBookEvent::lifecycle_status(
  self : ExecutableBookEvent,
) -> String {
  match self.lifecycle_proof {
    Some(proof) => proof.status
    None => "unknown"
  }
}

///|
pub fn ExecutableBookEvent::lifecycle_ready(self : ExecutableBookEvent) -> Bool {
  match self.lifecycle_proof {
    Some(proof) => proof.ready
    None => true
  }
}

///|
pub fn ExecutableBookEvent::first_lifecycle_blocker_id(
  self : ExecutableBookEvent,
) -> String {
  match self.lifecycle_proof {
    Some(proof) => proof.first_blocker_id
    None => ""
  }
}

///|
pub fn ExecutableBookEvent::has_lifecycle_blocker(
  self : ExecutableBookEvent,
) -> Bool {
  match self.lifecycle_proof {
    Some(proof) => !proof.ready
    None => false
  }
}

///|
pub fn ExecutableBookEvent::should_notify_town(
  self : ExecutableBookEvent,
) -> Bool {
  self.notify_town ||
  self.accepted ||
  self.requires_review ||
  self.has_lifecycle_blocker()
}

///|
pub fn ExecutableBookEvent::town_event_kind(
  self : ExecutableBookEvent,
) -> String {
  if self.requires_review {
    "book.review_required"
  } else if self.has_lifecycle_blocker() {
    "book.lifecycle_blocked"
  } else if self.accepted {
    "book.knowledge_accepted"
  } else {
    "book.result"
  }
}

///|
pub fn ExecutableBookEvent::route_reason(self : ExecutableBookEvent) -> String {
  if self.requires_review {
    "review_required"
  } else if self.has_lifecycle_blocker() {
    "lifecycle_blocked"
  } else if self.accepted {
    "knowledge_accepted"
  } else if self.notify_town {
    "notify_requested"
  } else {
    "record_only"
  }
}

///|
pub fn ExecutableBookEvent::to_town_event(
  self : ExecutableBookEvent,
  index : Int,
  proposal_id? : String? = None,
) -> @core.TownEvent {
  let kind = self.town_event_kind()
  let evidence = self.evidence_id.unwrap_or("none")
  let lifecycle = self.lifecycle_status()
  let blocker = self.first_lifecycle_blocker_id()
  let lifecycle_detail = if blocker == "" {
    "lifecycle=\{lifecycle}"
  } else {
    "lifecycle=\{lifecycle}; blocker=\{blocker}"
  }
  @core.TownEvent::new(
    id="event-book-\{index}-\{self.id}",
    kind~,
    detail="\{self.book_id} / \{self.result_id}: \{self.event_type}; artifacts=\{self.artifacts.length()}; evidence=\{evidence}; \{lifecycle_detail}; \{self.summary}",
    related_task_id=Some(self.result_id),
    related_book_id=Some(self.book_id),
    related_proposal_id=proposal_id,
    related_run_id=self.run_id,
  )
}

///|
pub fn ExecutableBookEvent::route_to_town(
  self : ExecutableBookEvent,
  index : Int,
  proposal_id? : String? = None,
) -> ExecutableBookEventRoute {
  {
    town_event: self.to_town_event(index, proposal_id~),
    notify_operator: self.should_notify_town(),
    lifecycle_status: self.lifecycle_status(),
    lifecycle_ready: self.lifecycle_ready(),
    first_blocker_id: self.first_lifecycle_blocker_id(),
    route_reason: self.route_reason(),
  }
}

///|
pub fn executable_book_event_core_fields() -> Array[String] {
  [
    "protocol", "id", "source", "book_id", "result_id", "event_type", "accepted",
    "requires_review", "notify_town", "summary", "artifacts",
  ]
}

///|
pub fn executable_book_event_optional_fields() -> Array[String] {
  ["run_id", "evidence_id", "review_path", "lifecycle_proof"]
}
