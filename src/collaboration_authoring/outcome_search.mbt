///|
/// Read-only search through exact retained selections. The index pins each review
/// before inspection; a later unavailable pin becomes a visible coverage gap.
/// No collector, live Book catalog or authoring write is invoked.
pub async fn Store::search_outcomes(
  self : Store,
  query : @contract.OutcomeSearchQuery,
) -> @contract.OutcomeSearch {
  let initial = @contract.empty_outcome_search(query)
  let keys : Array[@contract.OutcomeKey] = []
  let gaps : Array[@contract.OutcomeSearchGap] = []
  let mut excluded = 0
  let mut candidates = 0
  if query.selections.is_empty() {
    let entries = self.list_outcomes()
    candidates = entries.length()
    for entry in entries {
      if entry.outcome_status == "not_retained" ||
        entry.outcome_status == "unavailable" {
        gaps.push({
          draft_id: entry.draft_id,
          revision: entry.revision,
          review_version: entry.review_version,
          status: entry.outcome_status,
          detail: if entry.error.is_empty() {
            "No terminal retained dossier; execution state is unknown"
          } else {
            entry.error
          },
        })
      } else if !query.review_status.is_empty() &&
        entry.review_status != query.review_status {
        excluded += 1
      } else {
        keys.push(entry.key())
      }
    }
  } else {
    candidates = query.selections.length()
    keys.append(query.selections)
  }
  let hits : Array[@contract.OutcomeSearchHit] = []
  let mut searched = 0
  let mut bytes = 0
  let mut fields = 0
  for key in keys {
    let outcome = self.inspect_outcome(key) catch {
      error => {
        gaps.push({
          draft_id: key.draft_id,
          revision: key.revision,
          review_version: key.review_version,
          status: "unavailable",
          detail: error_message(error),
        })
        continue
      }
    }
    bytes += outcome.archive_size_bytes
    guard bytes <= 134217728 else {
      raise CollaborationError(
        "Search exceeds 128 MiB of verified dossier archives; select fewer exact keys",
      )
    }
    if (
        !query.review_status.is_empty() &&
        query.review_status != outcome.review_status
      ) ||
      (
        !query.book_id.is_empty() &&
        !outcome.saved.draft.participants.any(p => p.book_id == query.book_id)
      ) {
      excluded += 1
      continue
    }
    searched += 1
    if @contract.search_outcome(outcome, query) is Some(hit) {
      fields += hit.matches.length()
      guard hits.length() < 128 && fields <= 4096 else {
        raise CollaborationError(
          "Search exceeds 128 matching outcomes or 4096 fields; narrow the query",
        )
      }
      hits.push(hit)
    }
  }
  let result = {
    ..initial,
    candidate_count: candidates,
    searched_count: searched,
    excluded_count: excluded,
    gaps,
    hits,
  }
  ignore(result.json_text())
  result
}
