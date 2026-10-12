///|
/// A historical source revision. "unavailable" is an integrity failure, never
/// an execution failure. Only completed/partial entries have retained dossiers.
pub(all) struct OutcomeEntry {
  draft_id : String
  revision : String
  title : String
  recorded_at : String
  outcome_status : String
  review_status : String
  review_version : Int
  result_digest : String
  review_digest : String
  error : String
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Exact immutable selection. A new review must not silently replace this pin.
pub(all) struct OutcomeKey {
  draft_id : String
  revision : String
  result_digest : String
  review_version : Int
  review_digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct OutcomeReview {
  version : Int
  digest : String
} derive(Debug, Eq, ToJson, FromJson)

///|
pub(all) struct RetainedOutcome {
  contract_version : String
  key : OutcomeKey
  saved : SavedDraft
  work : OneoffWork
  review_status : String
  reviews : Array[OutcomeReview]
  artifacts : Array[Artifact]
  archive_digest : String
  archive_size_bytes : Int
} derive(Debug, Eq, ToJson, FromJson)

///|
pub fn OutcomeEntry::key(self : OutcomeEntry) -> OutcomeKey {
  {
    draft_id: self.draft_id,
    revision: self.revision,
    result_digest: self.result_digest,
    review_version: self.review_version,
    review_digest: self.review_digest,
  }
}

///|
pub fn filter_outcomes(
  entries : Array[OutcomeEntry],
  outcome_status : String,
  review_status : String,
) -> Array[OutcomeEntry] {
  entries.filter(entry => {
    (outcome_status.is_empty() || entry.outcome_status == outcome_status) &&
    (review_status.is_empty() || entry.review_status == review_status)
  })
}
