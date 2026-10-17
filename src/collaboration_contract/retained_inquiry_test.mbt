///|
fn inquiry_fixture() -> (
  @collaboration_contract.RetainedInquiry,
  @collaboration_contract.RetainedOutcome,
) {
  let (saved, work, _) = collective_fixture()
  let key : @collaboration_contract.OutcomeKey = {
    draft_id: saved.draft.draft_id,
    revision: saved.revision,
    result_digest: work.result_digest,
    review_version: work.review_version,
    review_digest: "sha256:pinned-review",
  }
  let outcome : @collaboration_contract.RetainedOutcome = {
    contract_version: "moontown.retained-outcome.v1",
    key,
    saved,
    work,
    review_status: "rejected",
    reviews: [],
    artifacts: [],
    archive_digest: "sha256:archive",
    archive_size_bytes: 1024,
  }
  let input : @collaboration_contract.RetainedInquiry = {
    origin: key,
    draft_id: "fresh-inquiry",
    title: "Context-sensitive research",
    question: "Do the retained findings survive the current observations?",
    falsifier: "The updated observations contradict the retained conclusion.",
    dissent: "Cohort differences remain unresolved.",
    assumptions: "Dates are incomplete.",
    reviewer_id: "lee",
    reviewer_name: "Lee Reviewer",
    objection_reviewer_id: "ren",
    objection_reviewer_name: "Ren Reviewer",
    contributions: ["water", "mobility"].map(book_id => {
      book_id,
      quote: "Deterministic local fixture output: " + book_id,
      challenge: "Check the counterexamples from " + book_id,
    }),
  }
  (input, outcome)
}

///|
test "retained inquiry preserves pinned historical evidence and gaps without inheriting authority" {
  let (input, outcome) = inquiry_fixture()
  guard @collaboration_contract.retained_inquiry_draft(input, outcome)
    is Ok(draft) else {
    fail("Expected editable inquiry")
  }
  assert_eq(draft.draft_id, input.draft_id)
  assert_eq(draft.reviewer_id, "lee")
  assert_eq(draft.objection_reviewer_id, "ren")
  assert_eq(draft.participants.length(), 2)
  assert_eq(
    draft.participants[0].source_paths,
    outcome.saved.draft.participants[0].source_paths,
  )
  for
    text in [
      "sha256:pinned-review", "sha256:source-water", "sha256:output-water", "run-mobility",
      "rejected", "missing", "research-salon", "new inputs", "No participant endorsement",
    ] {
    assert_true(draft.question.contains(text), msg=text)
  }
  assert_true(draft.objection.contains(outcome.saved.draft.objection))
  assert_true(
    draft.participants[1].perspective.contains(input.contributions[1].challenge),
  )
  assert_true(draft.decision_prompt.contains("historical context only"))
}

///|
test "retained inquiry rejects fabricated failed duplicate single and mismatched selections" {
  let (input, outcome) = inquiry_fixture()
  for
    invalid in [
      { ..input, draft_id: input.origin.draft_id, },
      { ..input, draft_id: "../unsafe", },
      { ..input, origin: { ..input.origin, review_digest: "different", }, },
      { ..input, title: "x".repeat(201), },
      { ..input, question: " ", },
      { ..input, dissent: "", },
      { ..input, assumptions: "", },
      { ..input, falsifier: "x".repeat(4001), },
      { ..input, reviewer_id: "town-composer", },
      { ..input, objection_reviewer_id: input.reviewer_id, },
      { ..input, contributions: [input.contributions[0]], },
      {
        ..input,
        contributions: [input.contributions[0], input.contributions[0]],
      },
      {
        ..input,
        contributions: [
          { ..input.contributions[0], book_id: "missing", },
          input.contributions[1],
        ],
      },
      {
        ..input,
        contributions: [
          { ..input.contributions[0], quote: "fabricated", },
          input.contributions[1],
        ],
      },
      {
        ..input,
        contributions: [
          { ..input.contributions[0], quote: "", },
          input.contributions[1],
        ],
      },
      {
        ..input,
        contributions: [
          { ..input.contributions[0], challenge: "", },
          input.contributions[1],
        ],
      },
    ] {
    assert_true(
      @collaboration_contract.retained_inquiry_draft(invalid, outcome) is Err(_),
    )
  }
  assert_true(
    @collaboration_contract.retained_inquiry_draft(input, {
      ..outcome,
      work: { ..outcome.work, status: "running", },
    })
    is Err(_),
  )
}

///|
fn inquiry_client() -> @collaboration_contract.Client {
  let (input, outcome) = inquiry_fixture()
  let fields : Map[String, String] = {
    "inquiry_mode": "compose",
    "inquiry_id": input.draft_id,
    "inquiry_title": input.title,
    "inquiry_question": input.question,
    "inquiry_falsifier": input.falsifier,
    "inquiry_dissent": input.dissent,
    "inquiry_assumptions": input.assumptions,
    "inquiry_reviewer_id": input.reviewer_id,
    "inquiry_reviewer_name": input.reviewer_name,
    "inquiry_objection_reviewer_id": input.objection_reviewer_id,
    "inquiry_objection_reviewer_name": input.objection_reviewer_name,
  }
  for c in input.contributions {
    fields["inquiry_include_" + c.book_id] = "yes"
    fields["inquiry_quote_" + c.book_id] = c.quote
    fields["inquiry_challenge_" + c.book_id] = c.challenge
  }
  {
    ..@collaboration_contract.Client::new().edit(
      "question", "Keep unsaved text",
    ),
    outcome_key: Some(outcome.key),
    outcome: Some(outcome),
    inquiry_fields: fields,
  }
}

///|
test "retained inquiry client cancel repeated selection stale callbacks and saved response stay bound" {
  let client = inquiry_client()
  let (input, outcome) = inquiry_fixture()
  assert_eq(client.retained_inquiry_input(), Ok(input))
  assert_eq(
    client.edit("inquiry_mode", "compose").inquiry_fields,
    client.inquiry_fields,
  )
  assert_eq(
    client.select_outcome(outcome.key).inquiry_fields,
    client.inquiry_fields,
  )
  let pending = client.begin("retained-inquiry", input.draft_id)
  assert_true(pending.busy())
  assert_eq(
    pending.begin("retained-inquiry", input.draft_id).generation,
    pending.generation,
  )
  let draft = client.retained_inquiry_preview().unwrap()
  let saved : @collaboration_contract.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft,
    revision: "r-new",
    previous_revision: "",
    recorded_at: "2026-10-14",
    sources: [],
  }
  let reply = {
    ..outcome_reply(pending.generation, outcome.key),
    action: "retained-inquiry",
    outcome: None,
    saved: Some(saved),
  }
  for
    cancelled in [
      pending.edit("inquiry_mode", "off"),
      pending.dismiss(),
      pending.reset(),
      pending.edit("outcome_filter", "partial"),
      pending.select_outcome({ ..outcome.key, review_version: 1, }),
    ] {
    assert_true(cancelled.generation > pending.generation)
    assert_eq(
      cancelled.settle(
        pending.generation,
        "retained-inquiry",
        reply.to_json().stringify(),
      ).draft,
      cancelled.draft,
    )
  }
  assert_eq(
    pending.edit("inquiry_mode", "off").draft.question,
    "Keep unsaved text",
  )
  assert_true(pending.edit("inquiry_mode", "off").inquiry_fields.is_empty())
  let settled = pending.settle(
    pending.generation,
    "retained-inquiry",
    reply.to_json().stringify(),
  )
  assert_eq(settled.draft, draft)
  assert_false(settled.dirty)
  assert_eq(settled.work, None)
  assert_eq(settled.prepared, None)
  assert_true(settled.inquiry_fields.is_empty())
  let forged = {
    ..reply,
    saved: Some({ ..saved, draft: { ..draft, question: "forged", }, }),
  }
  assert_eq(
    pending.settle(
      pending.generation,
      "retained-inquiry",
      forged.to_json().stringify(),
    ).draft,
    client.draft,
  )
}
