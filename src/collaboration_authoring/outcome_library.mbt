///|
struct OutcomeHistory {
  bundle : @review.ConversationReviewBundle
  work : @contract.OneoffWork
  files : Array[(String, Bytes)]
  reviews : Array[@contract.OutcomeReview]
}

///|
async fn Store::outcome_history(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
  selected : Int,
) -> OutcomeHistory {
  let files : Array[(String, Bytes)] = []
  let reviews : Array[@contract.OutcomeReview] = []
  let history : Array[String] = []
  let mut latest = result_bundle(saved, work)
  let mut size = 0
  for version in 0..<=selected {
    let (bundle, bytes) = self.retained_review(saved, work, version)
    size += bytes.length()
    guard size <= 16777216 else {
      raise CollaborationError(
        "Selected review history exceeds the 16 MiB read limit",
      )
    }
    if version > 0 {
      let additions = bundle.decision_receipts.filter(r => {
        r.receipt_id == "decision-" + version.to_string()
      })
      guard additions.length() == 1 else {
        raise CollaborationError(
          "Retained review version has no unique decision receipt",
        )
      }
      let receipt = additions[0]
      let expected = latest.decision_receipts.filter(r => {
        r.decision_id != receipt.decision_id
      })
      expected.push(receipt)
      guard bundle.decision_receipts == expected else {
        raise CollaborationError(
          "Retained review history replaced unrelated decisions",
        )
      }
      history.push(
        "Review " +
        version.to_string() +
        " · " +
        receipt.decided_at +
        " · " +
        receipt.reviewer_name +
        " (" +
        receipt.reviewer_participant_id +
        ")\n" +
        receipt.decision_id +
        ": " +
        receipt.decision +
        "\n" +
        receipt.rationale,
      )
    }
    latest = bundle
    files.push(("review/" + version.to_string() + ".json", bytes))
    reviews.push({ version, digest: digest(bytes), })
  }
  let record = @review.project_review_record(latest, work.result_digest, [])
  {
    bundle: latest,
    files,
    reviews,
    work: {
      ..work,
      review_status: record.review_status,
      review_version: selected,
      review_history_text: history.join("\n\n"),
      decisions: latest.required_decisions.map(required => {
        let reviewer = latest.participants
          .iter()
          .find_first(p => p.participant_id == required.reviewer_participant_id)
          .unwrap()
        let receipt = latest.decision_receipts
          .iter()
          .find_first(r => r.decision_id == required.decision_id)
        {
          decision_id: required.decision_id,
          reviewer_id: reviewer.participant_id,
          reviewer_name: reviewer.display_name,
          prompt: required.prompt,
          decision: receipt.map(r => r.decision).unwrap_or("pending"),
          rationale: receipt.map(r => r.rationale).unwrap_or(""),
        }
      }),
    },
  }
}

///|
fn unavailable_outcome(
  id : String,
  revision : String,
  error : String,
) -> @contract.OutcomeEntry {
  {
    draft_id: id,
    revision,
    title: id,
    recorded_at: "",
    outcome_status: "unavailable",
    review_status: "unavailable",
    review_version: -1,
    result_digest: "",
    review_digest: "",
    error,
  }
}

///|
async fn Store::outcome_entry(
  self : Store,
  id : String,
  revision : String,
) -> @contract.OutcomeEntry {
  let saved = self.load_revision(id, revision)
  let root = self.work_root(saved)
  if kind(root) is Some(_) {
    directory(root, false)
  }
  let base = {
    ..unavailable_outcome(id, revision, ""),
    title: saved.draft.title,
    recorded_at: saved.recorded_at,
    outcome_status: "not_retained",
    review_status: "not_ready",
  }
  if kind(root + "/result.json") is None {
    guard kind(root + "/review") is None else {
      raise CollaborationError(
        "Retained result is missing while its review history exists",
      )
    }
    return base
  }
  let work = self.retained_work(saved)
  let versions = self.retained_review_versions(saved)
  let version = versions[versions.length() - 1]
  let history = self.outcome_history(saved, work, version)
  {
    ..base,
    outcome_status: work.status,
    review_status: outcome_review_status(history.bundle),
    review_version: version,
    result_digest: work.result_digest,
    review_digest: history.reviews[version].digest,
  }
}

///|
/// Every retained revision, not just current draft pointers. Individual corrupt
/// entries stay visible. A store over the bound fails explicitly, never truncates.
pub async fn Store::list_outcomes(
  self : Store,
) -> Array[@contract.OutcomeEntry] {
  if kind(self.root) is None {
    return []
  }
  self.read_locked(() => {
    if kind(self.root + "/drafts") is None {
      return []
    }
    let entries : Array[@contract.OutcomeEntry] = []
    let ids = outcome_children(self.root + "/drafts", 128)
    for id in ids {
      let revisions = outcome_children(self.draft_root(id) + "/revisions", 64) catch {
        error => {
          entries.push(unavailable_outcome(id, "", error_message(error)))
          continue
        }
      }
      guard entries.length() + revisions.length() <= 512 else {
        raise CollaborationError(
          "Retained outcome index exceeds 512 revisions; no partial index was returned",
        )
      }
      for revision in revisions {
        let entry = self.outcome_entry(id, revision) catch {
          error => unavailable_outcome(id, revision, error_message(error))
        }
        entries.push(entry)
      }
    }
    entries
  })
}
