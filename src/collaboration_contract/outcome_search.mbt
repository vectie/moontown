///|
/// Literal phrase search. Empty selections scan the latest retained review of
/// every source revision; explicit keys search exactly those historical reviews.
pub(all) struct OutcomeSearchQuery {
  text : String
  case_sensitive : Bool
  book_id : String
  review_status : String
  selections : Array[OutcomeKey]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// One first-occurrence excerpt per matching field, with original UTF-16 offsets.
pub(all) struct OutcomeSearchMatch {
  field : String
  book_id : String
  identity : String
  digest : String
  excerpt : String
  match_offset : Int
  excerpt_offset : Int
  field_length : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct OutcomeSearchHit {
  key : OutcomeKey
  title : String
  recorded_at : String
  outcome_status : String
  review_status : String
  archive_digest : String
  matches : Array[OutcomeSearchMatch]
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Coverage gaps are explicit, including unavailable evidence that cannot be
/// classified by a Book or review filter. An empty hit list alone proves nothing.
pub(all) struct OutcomeSearchGap {
  draft_id : String
  revision : String
  review_version : Int
  status : String
  detail : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct OutcomeSearch {
  contract_version : String
  query : OutcomeSearchQuery
  review_selection : String
  candidate_count : Int
  searched_count : Int
  excluded_count : Int
  gaps : Array[OutcomeSearchGap]
  hits : Array[OutcomeSearchHit]
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn OutcomeSearchQuery::validate(self : OutcomeSearchQuery) -> Unit raise {
  guard !self.text.trim().is_empty() && self.text.length() <= 128 else {
    fail(
      "Search phrase must contain non-whitespace text and at most 128 UTF-16 code units",
    )
  }
  guard self.book_id.is_empty() || safe_id(self.book_id) else {
    fail("Search Book filter must be an exact safe Book ID")
  }
  guard ["", "pending_review", "accepted", "rejected", "deferred"].contains(
    self.review_status,
  ) else {
    fail(
      "Search review filter must be pending_review, accepted, rejected, deferred, or empty",
    )
  }
  guard self.selections.length() <= 128 else {
    fail("Search accepts at most 128 explicit historical keys")
  }
  let seen : Array[OutcomeKey] = []
  for key in self.selections {
    guard safe_id(key.draft_id) &&
      safe_id(key.revision) &&
      !key.result_digest.is_empty() &&
      !key.review_digest.is_empty() &&
      key.review_version >= 0 &&
      key.review_version <= 100 else {
      fail("Search requires complete exact historical keys")
    }
    guard !seen.contains(key) else {
      fail("Search contains a duplicate historical key")
    }
    seen.push(key)
  }
}

///|
pub fn empty_outcome_search(query : OutcomeSearchQuery) -> OutcomeSearch raise {
  query.validate()
  {
    contract_version: "moontown.outcome-search.v1",
    query,
    review_selection: if query.selections.is_empty() {
      "latest_retained_review_per_source_revision_at_index"
    } else {
      "explicit_pinned_reviews"
    },
    candidate_count: 0,
    searched_count: 0,
    excluded_count: 0,
    gaps: [],
    hits: [],
  }
}

///|
fn search_field(
  query : OutcomeSearchQuery,
  matches : Array[OutcomeSearchMatch],
  field : String,
  book_id : String,
  identity : String,
  digest : String,
  text : String,
) -> Unit raise {
  if !query.book_id.is_empty() && book_id != query.book_id {
    return
  }
  let haystack = if query.case_sensitive { text } else { text.to_lower() }
  let needle = if query.case_sensitive {
    query.text
  } else {
    query.text.to_lower()
  }
  if haystack.find(needle) is Some(offset) {
    guard matches.length() < 256 else {
      fail(
        "Search exceeds 256 matching fields in one outcome; narrow the phrase or Book filter",
      )
    }
    let mut start = if offset > 64 { offset - 64 } else { 0 }
    let candidate_end = offset + query.text.length() + 64
    let mut end = if candidate_end < text.length() {
      candidate_end
    } else {
      text.length()
    }
    // Keep supplementary Unicode characters intact at excerpt boundaries.
    if start > 0 && text[start] >= 0xdc00 && text[start] <= 0xdfff {
      start -= 1
    }
    if end < text.length() && text[end] >= 0xdc00 && text[end] <= 0xdfff {
      end += 1
    }
    matches.push({
      field,
      book_id,
      identity,
      digest,
      excerpt: text[start:end].to_string(),
      match_offset: offset,
      excerpt_offset: start,
      field_length: text.length(),
    })
  }
}

///|
/// Search an already verified retained outcome. Book filtering restricts matches
/// to that Book's fields; shared question/review fields have no Book attribution.
/// Case-insensitive mode folds ASCII only and leaves non-ASCII text exact.
pub fn search_outcome(
  outcome : RetainedOutcome,
  query : OutcomeSearchQuery,
) -> OutcomeSearchHit? raise {
  query.validate()
  guard outcome.contract_version == "moontown.retained-outcome.v1" &&
    outcome.key.draft_id == outcome.saved.draft.draft_id &&
    outcome.key.revision == outcome.saved.revision &&
    outcome.key.draft_id == outcome.work.draft_id &&
    outcome.key.revision == outcome.work.revision &&
    outcome.key.result_digest == outcome.work.result_digest &&
    outcome.key.review_version == outcome.work.review_version else {
    fail("Search requires matching retained outcome identities")
  }
  if !query.selections.is_empty() && !query.selections.contains(outcome.key) {
    return None
  }
  if !query.review_status.is_empty() &&
    query.review_status != outcome.review_status {
    return None
  }
  let matches : Array[OutcomeSearchMatch] = []
  let draft = outcome.saved.draft
  for
    (field, value) in [
      ("title", draft.title),
      ("question", draft.question),
      ("objection", draft.objection),
      ("reviewer_name", draft.reviewer_name),
      ("decision_prompt", draft.decision_prompt),
    ] {
    search_field(query, matches, field, "", draft.draft_id, "", value)
  }
  for p in draft.participants {
    for
      (field, value) in [
        ("assignment.focus_area", p.focus_area),
        ("assignment.perspective", p.perspective),
        ("assignment.contribution", p.contribution),
        ("assignment.next_artifact", p.next_artifact),
      ] {
      search_field(query, matches, field, p.book_id, p.book_id, "", value)
    }
  }
  for source in outcome.saved.sources {
    for
      (field, value) in [
        ("source.book_title", source.book_title),
        ("source.path", source.source_path),
        ("source.digest", source.digest),
      ] {
      search_field(
        query,
        matches,
        field,
        source.book_id,
        source.source_path,
        source.digest,
        value,
      )
    }
  }
  for p in outcome.work.participants {
    search_field(
      query,
      matches,
      "contribution",
      p.book_id,
      p.output_ref,
      p.output_digest,
      p.output_text,
    )
    search_field(
      query,
      matches,
      "participant.detail",
      p.book_id,
      p.run_id,
      p.output_digest,
      p.detail,
    )
  }
  for decision in outcome.work.decisions {
    for
      (field, value) in [
        ("decision.prompt", decision.prompt),
        ("decision.rationale", decision.rationale),
        ("decision.reviewer_name", decision.reviewer_name),
      ] {
      search_field(query, matches, field, "", decision.decision_id, "", value)
    }
  }
  if matches.is_empty() {
    return None
  }
  Some({
    key: outcome.key,
    title: draft.title,
    recorded_at: outcome.saved.recorded_at,
    outcome_status: outcome.work.status,
    review_status: outcome.review_status,
    archive_digest: outcome.archive_digest,
    matches,
  })
}
