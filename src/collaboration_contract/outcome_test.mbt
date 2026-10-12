///|
fn outcome_key() -> @collaboration_contract.OutcomeKey {
  {
    draft_id: "historic",
    revision: "r-first",
    result_digest: "sha256:result",
    review_version: 2,
    review_digest: "sha256:review",
  }
}

///|
fn outcome_reply(
  generation : Int,
  key : @collaboration_contract.OutcomeKey,
) -> @collaboration_contract.Reply {
  let saved : @collaboration_contract.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft: @collaboration_contract.empty_draft(key.draft_id),
    revision: key.revision,
    previous_revision: "",
    recorded_at: "2026-10-07",
    sources: [],
  }
  {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: generation.to_string(),
    action: "outcome-inspect",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: None,
    prepared: None,
    work: None,
    outcomes: [],
    source_listing: None,
    outcome: Some({
      contract_version: "moontown.retained-outcome.v1",
      key,
      saved,
      work: {
        ..@collaboration_contract.empty_work(key.draft_id, key.revision),
        status: "partial",
        result_digest: key.result_digest,
        review_version: key.review_version,
      },
      review_status: "deferred",
      reviews: [],
      artifacts: [],
      archive_digest: "sha256:archive",
      archive_size_bytes: 1024,
    }),
  }
}

///|
test "retained outcome selection is separate from draft reuse and stale downloads cancel on filter clear dismiss and newer review" {
  let initial = @collaboration_contract.Client::new().edit(
    "question", "Unsaved question survives inspection",
  )
  let pending = initial
    .select_outcome(outcome_key())
    .begin("outcome-inspect", "historic")
  assert_true(pending.busy())
  assert_eq(
    pending.begin("outcome-inspect", "historic").generation,
    pending.generation,
  )
  let reply = outcome_reply(pending.generation, outcome_key())
    .to_json()
    .stringify()
  let selected = pending.settle(pending.generation, "outcome-inspect", reply)
  assert_true(selected.outcome is Some(_))
  assert_true(selected.dirty)
  assert_eq(selected.draft.question, initial.draft.question)
  assert_eq(selected.work, None)
  assert_eq(selected.prepared, None)
  let downloading = selected.begin("outcome-export", "historic")
  for
    cancelled in [
      downloading.dismiss(),
      downloading.reset(),
      downloading.edit("outcome_filter", "partial"),
      downloading.edit("review_filter", "deferred"),
      downloading.select_outcome({
        ..outcome_key(),
        review_version: 0,
        review_digest: "sha256:older",
      }),
    ] {
    assert_true(cancelled.generation > downloading.generation)
    assert_eq(
      cancelled.download_settled(
        downloading.generation,
        "Downloaded stale result",
      ).notice,
      cancelled.notice,
    )
  }
  let newer = pending
    .select_outcome({ ..outcome_key(), review_version: 3, })
    .begin("outcome-inspect", "historic")
  assert_eq(
    newer.settle(pending.generation, "outcome-inspect", reply).outcome,
    None,
  )
  let wrong = outcome_reply(pending.generation, {
      ..outcome_key(),
      revision: "r-other",
    })
    .to_json()
    .stringify()
  assert_eq(
    pending.settle(pending.generation, "outcome-inspect", wrong).outcome,
    None,
  )
  let interrupted = pending.settle(
    pending.generation,
    "outcome-inspect",
    "interrupted",
  )
  assert_false(interrupted.busy())
  assert_eq(interrupted.outcome, None)
  assert_eq(@collaboration_contract.Client::new().outcome, None)
}

///|
test "retained outcome filters keep failure and unavailable status distinct" {
  let entry : @collaboration_contract.OutcomeEntry = {
    draft_id: "historic",
    revision: "r-first",
    title: "Historical result",
    recorded_at: "2026-10-07",
    outcome_status: "partial",
    review_status: "deferred",
    review_version: 2,
    result_digest: "sha256:result",
    review_digest: "sha256:review",
    error: "",
  }
  let entries = [
    entry,
    {
      ..entry,
      revision: "r-broken",
      outcome_status: "unavailable",
      review_status: "unavailable",
      error: "Missing source",
    },
  ]
  assert_eq(
    @collaboration_contract.filter_outcomes(entries, "partial", "deferred"),
    [entry],
  )
  assert_eq(@collaboration_contract.filter_outcomes(entries, "completed", ""), [])
  assert_eq(
    @collaboration_contract.filter_outcomes(entries, "unavailable", "").length(),
    1,
  )
  assert_eq(
    @collaboration_contract.filter_outcomes(entries, "", "").length(),
    2,
  )
}
