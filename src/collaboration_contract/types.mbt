///|
/// User-authored assignments. Source paths are relative to the selected Book.
pub(all) struct Participant {
  book_id : String
  source_paths : Array[String]
  focus_area : String
  perspective : String
  contribution : String
  next_artifact : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// A draft is a plan, never an execution or acceptance receipt.
pub(all) struct Draft {
  draft_id : String
  title : String
  question : String
  reviewer_id : String
  reviewer_name : String
  decision_prompt : String
  objection : String
  objection_reviewer_id : String
  objection_reviewer_name : String
  participants : Array[Participant]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Public snapshot identity; never contains a local workspace root.
pub(all) struct SourceSnapshot {
  book_id : String
  book_title : String
  source_path : String
  artifact_ref : String
  digest : String
  size_bytes : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
/// An immutable saved draft with host-captured source bytes.
pub(all) struct SavedDraft {
  contract_version : String
  draft : Draft
  revision : String
  previous_revision : String
  recorded_at : String
  sources : Array[SourceSnapshot]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct CatalogBook {
  book_id : String
  title : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Artifact {
  path : String
  digest : String
  size_bytes : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct Prepared {
  contract_version : String
  draft_id : String
  revision : String
  review_status : String
  artifacts : Array[Artifact]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Every response retains the request token for stale-callback rejection.
pub(all) struct Reply {
  contract_version : String
  request_id : String
  action : String
  ok : Bool
  error : String
  books : Array[CatalogBook]
  drafts : Array[SavedDraft]
  saved : SavedDraft?
  prepared : Prepared?
  work : OneoffWork?
  outcomes : Array[OutcomeEntry]
  outcome : RetainedOutcome?
  source_listing : SourceListing?
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn empty_draft(id : String) -> Draft {
  {
    draft_id: id,
    title: "",
    question: "",
    reviewer_id: "",
    reviewer_name: "",
    decision_prompt: "",
    objection: "",
    objection_reviewer_id: "",
    objection_reviewer_name: "",
    participants: [],
  }
}

///|
pub fn safe_id(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 96 &&
  value != "." &&
  value != ".." &&
  value
  .iter()
  .all(ch => {
    (ch >= 'a' && ch <= 'z') ||
    (ch >= 'A' && ch <= 'Z') ||
    (ch >= '0' && ch <= '9') ||
    ch == '-' ||
    ch == '_' ||
    ch == '.'
  })
}

///|
/// Portable relative paths only; the host also rejects symlink traversal.
pub fn safe_source_path(value : String) -> Bool {
  !value.is_empty() &&
  value.length() <= 240 &&
  !value.contains("\\") &&
  !value.contains(":") &&
  !value.contains("\u0000") &&
  !value.contains("\n") &&
  !value.contains("\r") &&
  !value.has_prefix("/") &&
  value
  .split("/")
  .all(part => {
    !part.is_empty() && part != "." && part != ".." && !part.has_prefix(".")
  })
}

///|
pub fn preparation_issues(saved : SavedDraft) -> Array[String] {
  let draft = saved.draft
  let issues : Array[String] = []
  if !safe_id(draft.draft_id) {
    issues.push("Choose a safe draft ID")
  }
  if draft.title.trim().is_empty() || draft.question.trim().is_empty() {
    issues.push("A title and collaboration question are required")
  }
  if !safe_id(draft.reviewer_id) ||
    draft.reviewer_name.trim().is_empty() ||
    draft.decision_prompt.trim().is_empty() {
    issues.push("Name a human reviewer, reviewer ID, and decision question")
  }
  if draft.reviewer_id == "town-composer" ||
    draft.objection_reviewer_id == "town-composer" {
    issues.push(
      "Human reviewers need their own IDs, distinct from town-composer",
    )
  }
  if draft.participants.length() < 2 {
    issues.push("Choose at least two participant Books")
  }
  let ids : Array[String] = []
  for p in draft.participants {
    if !safe_id(p.book_id) || ids.contains(p.book_id) {
      issues.push("Participant Book IDs must be safe and unique")
    }
    ids.push(p.book_id)
    if p.focus_area.trim().is_empty() ||
      p.perspective.trim().is_empty() ||
      p.contribution.trim().is_empty() ||
      p.next_artifact.trim().is_empty() {
      issues.push(
        "Each Book needs a focus, perspective, contribution, and next artifact",
      )
    }
    if p.source_paths.is_empty() ||
      !saved.sources.any(s => s.book_id == p.book_id) {
      issues.push("Each Book needs at least one captured source")
    }
  }
  if !draft.objection.trim().is_empty() &&
    (
      !safe_id(draft.objection_reviewer_id) ||
      draft.objection_reviewer_name.trim().is_empty()
    ) {
    issues.push("Name the human who must resolve the objection")
  }
  if !draft.objection.trim().is_empty() &&
    draft.objection_reviewer_id == draft.reviewer_id &&
    draft.objection_reviewer_name != draft.reviewer_name {
    issues.push("One reviewer ID cannot name two people")
  }
  issues
}
