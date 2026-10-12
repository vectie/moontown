///|
/// A keyed before/after observation. Missing sides mean added or removed,
/// never failed execution. Both sides preserve their original attribution.
pub(all) struct OutcomeChange[T] {
  identity : String
  change : String
  before : T?
  after : T?
} derive(Debug, Eq, ToJson, FromJson)

///|
/// Local evidence comparison, not a new synthesis or acceptance receipt.
pub(all) struct OutcomeComparison {
  contract_version : String
  before : OutcomeKey
  after : OutcomeKey
  before_recorded_at : String
  after_recorded_at : String
  before_archive_digest : String
  after_archive_digest : String
  fields : Array[OutcomeChange[String]]
  assignments : Array[OutcomeChange[Participant]]
  sources : Array[OutcomeChange[SourceSnapshot]]
  contributions : Array[OutcomeChange[ParticipantWork]]
  decisions : Array[OutcomeChange[WorkDecision]]
} derive(Debug, Eq, ToJson, FromJson)

///|
fn[T] comparison_rows(
  before : Array[T],
  after : Array[T],
  identity : (T) -> String,
  equivalent : (T, T) -> Bool,
) -> Array[OutcomeChange[T]] raise {
  guard before.length() <= 1024 && after.length() <= 1024 else {
    fail("Comparison exceeds 1024 entries per section")
  }
  let old : Map[String, T] = Map([])
  let next : Map[String, T] = Map([])
  for entry in before {
    let id = identity(entry)
    guard !old.contains(id) else { fail("Duplicate before identity: " + id) }
    old[id] = entry
  }
  for entry in after {
    let id = identity(entry)
    guard !next.contains(id) else { fail("Duplicate after identity: " + id) }
    next[id] = entry
  }
  let rows : Array[OutcomeChange[T]] = []
  for entry in before {
    let id = identity(entry)
    let following = next.get(id)
    rows.push({
      identity: id,
      change: match following {
        None => "removed"
        Some(value) =>
          if equivalent(entry, value) {
            "unchanged"
          } else {
            "changed"
          }
      },
      before: Some(entry),
      after: following,
    })
  }
  for entry in after {
    let id = identity(entry)
    if !old.contains(id) {
      rows.push({
        identity: id,
        change: "added",
        before: None,
        after: Some(entry),
      })
    }
  }
  rows
}

///|
fn comparison_fields(outcome : RetainedOutcome) -> Array[(String, String)] {
  let draft = outcome.saved.draft
  [
    ("title", draft.title),
    ("question", draft.question),
    ("reviewer_id", draft.reviewer_id),
    ("reviewer_name", draft.reviewer_name),
    ("decision_prompt", draft.decision_prompt),
    ("objection", draft.objection),
    ("objection_reviewer_id", draft.objection_reviewer_id),
    ("objection_reviewer_name", draft.objection_reviewer_name),
    ("outcome_status", outcome.work.status),
    ("review_status", outcome.review_status),
  ]
}

///|
/// Compare explicitly selected, already inspected retained outcomes. Pairing is
/// by Book ID, Book ID + source path, or decision ID, never array position.
/// New run IDs and revision-specific artifact paths alone do not imply changed
/// evidence. Exact text/status/detail/digest differences do; no semantic or
/// contradiction inference is performed. All original provenance remains in JSON.
pub fn compare_outcomes(
  before : RetainedOutcome,
  after : RetainedOutcome,
) -> OutcomeComparison raise {
  for outcome in [before, after] {
    guard outcome.contract_version == "moontown.retained-outcome.v1" &&
      outcome.key.draft_id == outcome.saved.draft.draft_id &&
      outcome.key.revision == outcome.saved.revision &&
      outcome.key.draft_id == outcome.work.draft_id &&
      outcome.key.revision == outcome.work.revision &&
      outcome.key.result_digest == outcome.work.result_digest &&
      outcome.key.review_version == outcome.work.review_version else {
      fail("Comparison requires matching retained outcome identities")
    }
  }
  let fields = comparison_rows(
    comparison_fields(before),
    comparison_fields(after),
    entry => entry.0,
    (a, b) => a.1 == b.1,
  )
  {
    contract_version: "moontown.outcome-comparison.v1",
    before: before.key,
    after: after.key,
    before_recorded_at: before.saved.recorded_at,
    after_recorded_at: after.saved.recorded_at,
    before_archive_digest: before.archive_digest,
    after_archive_digest: after.archive_digest,
    fields: fields.map(row => {
      identity: row.identity,
      change: row.change,
      before: row.before.map(value => value.1),
      after: row.after.map(value => value.1),
    }),
    assignments: comparison_rows(
      before.saved.draft.participants,
      after.saved.draft.participants,
      p => p.book_id,
      (a, b) => a == b,
    ),
    sources: comparison_rows(
      before.saved.sources,
      after.saved.sources,
      s => s.book_id + ":" + s.source_path,
      (a, b) => {
        a.digest == b.digest &&
        a.size_bytes == b.size_bytes &&
        a.book_title == b.book_title
      },
    ),
    contributions: comparison_rows(
      before.work.participants,
      after.work.participants,
      p => p.book_id,
      (a, b) => {
        a.status == b.status &&
        a.detail == b.detail &&
        a.output_digest == b.output_digest &&
        a.output_text == b.output_text
      },
    ),
    decisions: comparison_rows(
      before.work.decisions,
      after.work.decisions,
      d => d.decision_id,
      (a, b) => a == b,
    ),
  }
}
