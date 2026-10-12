///|
/// Framework-independent composer state, shared by the Rabbita UI and tests.
pub(all) struct Client {
  draft : Draft
  revision : String
  sources : Array[SourceSnapshot]
  prepared : Prepared?
  work : OneoffWork?
  previous_revision : String
  work_fields : Map[String, String]
  books : Array[CatalogBook]
  drafts : Array[SavedDraft]
  new_draft_id : String
  dirty : Bool
  generation : Int
  pending_action : String
  pending_id : String
  notice : String
  outcomes : Array[OutcomeEntry]
  outcome_key : OutcomeKey?
  outcome : RetainedOutcome?
  outcome_filter : String
  review_filter : String
  source_book : String
  source_listing : SourceListing?
  source_filter : String
} derive(Debug)

///|
pub fn Client::new() -> Client {
  {
    draft: empty_draft("collaboration"),
    revision: "",
    sources: [],
    prepared: None,
    work: None,
    previous_revision: "",
    work_fields: Map([]),
    books: [],
    drafts: [],
    new_draft_id: "",
    dirty: true,
    generation: 0,
    pending_action: "",
    pending_id: "",
    outcomes: [],
    outcome_key: None,
    outcome: None,
    outcome_filter: "",
    review_filter: "",
    source_book: "",
    source_listing: None,
    source_filter: "",
    notice: "Choose existing Books and exact source paths. Save incomplete drafts; prepare when assignments and reviewers are ready.",
  }
}

///|
pub fn Client::busy(self : Client) -> Bool {
  !self.pending_action.is_empty()
}

///|
/// Leaving the composer cancels pending UI callbacks, not committed host work.
pub fn Client::dismiss(self : Client) -> Client {
  {
    ..self,
    generation: self.generation + 1,
    pending_action: "",
    pending_id: "",
    notice: if self.busy() {
      "A local request was interrupted. Reopen or retry to see its durable result."
    } else {
      self.notice
    },
  }
}

///| Clearing the form invalidates in-flight callbacks without cancelling a

///|
/// durable save that the server may already have committed.
pub fn Client::reset(self : Client) -> Client {
  {
    ..Client::new(),
    generation: self.generation + 1,
    books: self.books,
    drafts: self.drafts,
  }
}

///|
pub fn Client::edit(self : Client, field : String, value : String) -> Client {
  if field == "source_filter" {
    return { ..self, source_filter: value, }
  }
  if field == "outcome_filter" || field == "review_filter" {
    return {
      ..self.dismiss(),
      outcome_filter: if field == "outcome_filter" {
        value
      } else {
        self.outcome_filter
      },
      review_filter: if field == "review_filter" {
        value
      } else {
        self.review_filter
      },
    }
  }
  if self.busy() {
    return self
  }
  let d = self.draft
  if field.has_prefix("work_") {
    let fields = self.work_fields.copy()
    fields[field] = value
    return { ..self, work_fields: fields, }
  }
  if field == "new_draft_id" {
    return { ..self, new_draft_id: value, }
  }
  let draft = match field {
    "draft_id" => { ..d, draft_id: value, }
    "title" => { ..d, title: value, }
    "question" => { ..d, question: value, }
    "reviewer_id" => { ..d, reviewer_id: value, }
    "reviewer_name" => { ..d, reviewer_name: value, }
    "decision_prompt" => { ..d, decision_prompt: value, }
    "objection" => { ..d, objection: value, }
    "objection_reviewer_id" => { ..d, objection_reviewer_id: value, }
    "objection_reviewer_name" => { ..d, objection_reviewer_name: value, }
    _ => return self
  }
  {
    ..self,
    draft,
    revision: if field == "draft_id" {
      ""
    } else {
      self.revision
    },
    sources: [],
    prepared: None,
    work: None,
    dirty: true,
    generation: self.generation + 1,
    notice: "Unsaved changes",
  }
}

///|
pub fn Client::toggle_book(self : Client, id : String) -> Client {
  if self.busy() || !self.books.any(b => b.book_id == id) {
    return self
  }
  let participants = if self.draft.participants.any(p => p.book_id == id) {
    self.draft.participants.filter(p => p.book_id != id)
  } else {
    self.draft.participants +
    [
      {
        book_id: id,
        source_paths: [],
        focus_area: "",
        perspective: "",
        contribution: "",
        next_artifact: "",
      },
    ]
  }
  {
    ..self,
    draft: { ..self.draft, participants, },
    sources: [],
    prepared: None,
    work: None,
    dirty: true,
    generation: self.generation + 1,
    notice: "Unsaved participant selection",
    source_book: "",
    source_listing: None,
  }
}

///|
pub fn Client::edit_participant(
  self : Client,
  id : String,
  field : String,
  value : String,
) -> Client {
  if self.busy() {
    return self
  }
  let participants = self.draft.participants.map(p => {
    if p.book_id != id {
      p
    } else {
      match field {
        "source_paths" =>
          {
            ..p,
            source_paths: value
            .split("\n")
            .map(v => v.trim().to_owned())
            .filter(v => !v.is_empty())
            .collect(),
          }
        "focus_area" => { ..p, focus_area: value, }
        "perspective" => { ..p, perspective: value, }
        "contribution" => { ..p, contribution: value, }
        "next_artifact" => { ..p, next_artifact: value, }
        _ => p
      }
    }
  })
  {
    ..self,
    draft: { ..self.draft, participants, },
    sources: [],
    prepared: None,
    work: None,
    dirty: true,
    generation: self.generation + 1,
    notice: "Unsaved assignment changes",
  }
}

///|
pub fn Client::begin(self : Client, action : String, id : String) -> Client {
  if self.busy() {
    return self
  }
  if (
      action == "prepare" ||
      action == "export" ||
      action == "download" ||
      action.has_prefix("oneoff-")
    ) &&
    (self.dirty || self.revision.is_empty()) {
    return {
      ..self,
      notice: "Save this draft before preparing or downloading",
    }
  }
  {
    ..self,
    generation: self.generation + 1,
    pending_action: action,
    pending_id: id,
    notice: "Working locally…",
  }
}

///|
pub fn Client::settle(
  self : Client,
  generation : Int,
  action : String,
  raw : String,
) -> Client {
  if generation != self.generation || action != self.pending_action {
    return self
  }
  let clean = { ..self, pending_action: "", pending_id: "", }
  let reply : Reply = @json.from_json(@json.parse(raw)) catch {
    _ =>
      return {
        ..clean,
        notice: "The local response was interrupted. Reopen or retry the same action.",
      }
  }
  if reply.contract_version != "moontown.collaboration.reply.v1" ||
    reply.request_id != generation.to_string() ||
    reply.action != action {
    return {
      ..clean,
      notice: "Response identity changed. Reopen the draft before retrying.",
    }
  }
  if !reply.ok {
    return { ..clean, notice: reply.error, }
  }
  if action == "source-list" {
    guard reply.source_listing is Some(listing) &&
      listing.book_id == self.source_book &&
      listing.book_id == self.pending_id &&
      self.draft.participants.any(p => p.book_id == listing.book_id) &&
      listing.paths.length() <= 256 &&
      listing.paths.all(safe_source_path) else {
      return {
        ..clean,
        source_listing: None,
        notice: "Source listing did not match the selected Book",
      }
    }
    return { ..clean, source_listing: Some(listing), notice: listing.detail, }
  }
  if action == "outcome-list" {
    return {
      ..clean,
      outcomes: reply.outcomes,
      notice: "Retained revisions loaded without collecting or running work. Missing or corrupt entries remain visible.",
    }
  }
  if action == "outcome-inspect" {
    guard reply.outcome is Some(outcome) &&
      self.outcome_key is Some(key) &&
      outcome.key == key &&
      outcome.contract_version == "moontown.retained-outcome.v1" &&
      outcome.saved.draft.draft_id == key.draft_id &&
      outcome.saved.revision == key.revision &&
      outcome.work.draft_id == key.draft_id &&
      outcome.work.revision == key.revision &&
      outcome.work.result_digest == key.result_digest &&
      outcome.work.review_version == key.review_version &&
      ["completed", "partial"].contains(outcome.work.status) else {
      return {
        ..clean,
        outcome: None,
        notice: "Retained outcome response did not match the selected result and review",
      }
    }
    return {
      ..clean,
      outcome: Some(outcome),
      notice: "Exact retained result and selected review verified. Downloading is independent of Book submission and acceptance.",
    }
  }
  if reply.work is Some(work) {
    if work.contract_version != "moontown.collaboration-oneoff.v1" ||
      work.draft_id != self.draft.draft_id ||
      work.revision != self.revision {
      return {
        ..clean,
        notice: "Work response belongs to another captured revision",
      }
    }
    return { ..clean, work: Some(work), notice: work.detail, }
  }
  if action == "list" {
    return {
      ..clean,
      books: reply.books,
      drafts: reply.drafts,
      notice: if reply.error.is_empty() {
        "Saved drafts and existing Books loaded"
      } else {
        reply.error
      },
    }
  }
  if reply.saved is Some(saved) {
    let expected_id = if action == "reuse" {
      self.new_draft_id
    } else {
      self.pending_id
    }
    if saved.draft.draft_id != expected_id ||
      !safe_id(saved.revision) ||
      (action == "save" && saved.draft != self.draft) {
      return {
        ..clean,
        notice: "Saved draft identity did not match this request",
      }
    }
    let drafts = self.drafts.filter(d => {
      d.draft.draft_id != saved.draft.draft_id
    })
    drafts.push(saved)
    return {
      ..clean,
      draft: saved.draft,
      revision: saved.revision,
      sources: saved.sources,
      prepared: None,
      work: None,
      previous_revision: saved.previous_revision,
      drafts,
      dirty: false,
      source_book: "",
      source_listing: None,
      notice: "Saved source snapshots reopened. Prepare verifies every captured file.",
    }
  }
  if reply.prepared is Some(prepared) {
    if prepared.draft_id != self.draft.draft_id ||
      prepared.revision != self.revision ||
      prepared.review_status != "pending_review" {
      return {
        ..clean,
        notice: "Prepared artifact did not match this saved revision",
      }
    }
    return {
      ..clean,
      prepared: Some(prepared),
      notice: "Prepared locally. The collaboration remains pending human review; no work was scheduled or run.",
    }
  }
  {
    ..clean,
    notice: "The response did not contain the requested draft or artifacts",
  }
}

///|
pub fn Client::download_settled(
  self : Client,
  generation : Int,
  message : String,
) -> Client {
  if generation != self.generation ||
    !(self.pending_action == "download" ||
    self.pending_action == "export" ||
    self.pending_action == "outcome-export") {
    self
  } else {
    { ..self, pending_action: "", pending_id: "", notice: message, }
  }
}

///|
pub fn Client::select_outcome(self : Client, key : OutcomeKey) -> Client {
  {
    ..self.dismiss(),
    outcome_key: Some(key),
    outcome: None,
    notice: "Inspecting the selected retained result and review version",
  }
}

///|
pub fn Client::visible_outcomes(self : Client) -> Array[OutcomeEntry] {
  filter_outcomes(self.outcomes, self.outcome_filter, self.review_filter)
}
