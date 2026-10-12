///|
fn result_bundle(
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
) -> @review.ConversationReviewBundle raise {
  let plan = draft_bundle(saved, source_packet(saved))
  let refs = work.participants
    .filter(p => !p.output_ref.is_empty())
    .map(p => p.output_ref)
  let result_entry = @review.draft_review_entry(
    "proposal",
    entry_id="result",
    author_participant_id="town-composer",
    turn={
      turn_id: saved.revision + "-result",
      client_turn_id: saved.revision + "-result-client",
      command_id: saved.revision + "-result-command",
    },
    body="Review the collected actual participant contributions and visible failures. No consensus is inferred. " +
      saved.draft.decision_prompt,
    evidence_refs=refs,
  )
  @review.draft_review_bundle(
    review_id="result-" + saved.draft.draft_id,
    source_artifact_ref=revision_prefix(saved) + "oneoff/result.json",
    source_bytes=@utf8.encode(work.result_text),
    source_revision_id=saved.revision,
    conversation=plan.conversation,
    participants=plan.participants,
    entries=[
      result_entry,
      ..plan.entries.filter(e => e.entry_kind == "objection"),
    ],
    required_decisions=plan.required_decisions.map(d => {
      if d.decision_id == "review-plan" {
        { ..d, decision_id: "review-result", subject_entry_id: "result", }
      } else {
        d
      }
    }),
    recorded_at=saved.recorded_at,
  )
}

///|
async fn Store::current_work_review(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
) -> (@review.ConversationReviewBundle, Int) {
  let root = self.work_root(saved) + "/review"
  let initial = result_bundle(saved, work)
  write_bytes(
    root + "/0.json",
    @utf8.encode(@review.serialize_review_bundle(initial, work.result_digest)),
  )
  let mut latest = initial
  let mut version = 0
  while kind(root + "/" + (version + 1).to_string() + ".json") is Some(Regular) {
    guard version < 100 else {
      raise CollaborationError(
        "Review history limit reached; revise the source for further review",
      )
    }
    version += 1
    let next = @review.reimport_review_bundle(
      text_bytes(
        read_bytes(root + "/" + version.to_string() + ".json", 2097152),
      ),
      @utf8.encode(work.result_text),
    )
    guard next.source_revision_id == saved.revision &&
      next.review_id == initial.review_id &&
      next.entries == initial.entries &&
      next.required_decisions == initial.required_decisions &&
      next.participants == initial.participants else {
      raise CollaborationError("Result review assignments changed")
    }
    latest = next
  }
  (latest, version)
}

///|
async fn Store::project_work_review(
  self : Store,
  saved : @contract.SavedDraft,
  work : @contract.OneoffWork,
) -> @contract.OneoffWork {
  let (bundle, version) = self.current_work_review(saved, work)
  let record = @review.project_review_record(bundle, work.result_digest, [])
  let history : Array[String] = []
  for i in 1..<=version {
    let prior = @review.reimport_review_bundle(
      text_bytes(
        read_bytes(
          self.work_root(saved) + "/review/" + i.to_string() + ".json",
          2097152,
        ),
      ),
      @utf8.encode(work.result_text),
    )
    for receipt in prior.decision_receipts {
      if receipt.receipt_id == "decision-" + i.to_string() {
        history.push(
          "Review " +
          i.to_string() +
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
    }
  }
  {
    ..work,
    review_status: record.review_status,
    review_version: version,
    review_history_text: history.join("\n\n"),
    decisions: bundle.required_decisions.map(required => {
      let reviewer = bundle.participants
        .iter()
        .find_first(p => p.participant_id == required.reviewer_participant_id)
        .unwrap()
      let receipt = bundle.decision_receipts
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
  }
}

///|
/// actor_id comes exclusively from the existing trusted host identity lookup.
/// Naming a reviewer in a draft or request never authorizes that identity.
pub async fn Store::decide_oneoff(
  self : Store,
  id : String,
  revision : String,
  actor_id : String?,
  payload : Json,
  timestamp : String,
) -> @contract.OneoffWork {
  self.locked(() => {
    guard actor_id is Some(actor) && !actor.is_empty() else {
      raise CollaborationError(
        "Named-human authority is unavailable. Sign in through the existing operator identity service as the assigned reviewer; the result remains pending",
      )
    }
    guard payload
      is {
        "result_digest": String(expected),
        "review_version": Number(expected_version),
        "decision_id": String(decision_id),
        "decision": String(decision),
        "rationale": String(rationale),
        ..
      } else {
      raise CollaborationError(
        "Choose the exact result, decision and a rationale",
      )
    }
    let saved = self.load_revision(id, revision)
    ignore(self.verify_prepared(saved))
    let work = self.collect_work(saved, self.work_intent(saved))
    guard !work.result_digest.is_empty() && work.result_digest == expected else {
      raise CollaborationError(
        "The reviewed output is stale; reopen the exact collected result",
      )
    }
    let (bundle, version) = self.current_work_review(saved, work)
    guard expected_version == version.to_double() else {
      raise CollaborationError(
        "The review changed. Refresh and inspect the recorded decision before retrying",
      )
    }
    guard bundle.required_decisions
      .iter()
      .find_first(d => d.decision_id == decision_id)
      is Some(required) &&
      required.reviewer_participant_id == actor else {
      raise CollaborationError(
        "Only the named owner of this decision may settle it; objection ownership is independent",
      )
    }
    guard ["approve", "reject", "defer"].contains(decision) &&
      !rationale.trim().is_empty() &&
      rationale.length() <= 4000 else {
      raise CollaborationError(
        "Choose approve, reject or defer and explain the decision",
      )
    }
    let reviewer = bundle.participants
      .iter()
      .find_first(p => p.participant_id == actor)
      .unwrap()
    let receipt : @review.HumanDecisionReceipt = {
      receipt_id: "decision-" + (version + 1).to_string(),
      decision_id,
      reviewer_participant_id: actor,
      reviewer_name: reviewer.display_name,
      decision,
      rationale,
      source_digest: work.result_digest,
      decided_at: timestamp,
      evidence_refs: [bundle.source_artifact_ref],
    }
    let receipts = bundle.decision_receipts.filter(r => {
      r.decision_id != decision_id
    })
    receipts.push(receipt)
    let settled = { ..bundle, decision_receipts: receipts, }
    let bytes = @utf8.encode(
      @review.serialize_review_bundle(settled, work.result_digest),
    )
    let path = self.work_root(saved) + "/review/" + (version + 1).to_string()
    write_bytes(path + ".json", bytes)
    write_bytes(
      path + "-events.json",
      @utf8.encode(
        @review.review_events(settled, work.result_digest)
        .to_json()
        .stringify(indent=2),
      ),
    )
    write_bytes(
      path + "-record.json",
      @utf8.encode(
        @review.project_review_record(settled, work.result_digest, [])
        .to_json()
        .stringify(indent=2),
      ),
    )
    self.project_work_review(saved, work)
  })
}
