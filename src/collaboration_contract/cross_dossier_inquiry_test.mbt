///|
fn second_inquiry_outcome(
  first : @collaboration_contract.RetainedOutcome,
) -> @collaboration_contract.RetainedOutcome {
  let key = {
    ..first.key,
    draft_id: "second-question",
    revision: "r-second",
    result_digest: "sha256:second-result",
    review_digest: "sha256:second-review",
  }
  {
    ..first,
    key,
    saved: {
      ..first.saved,
      revision: key.revision,
      draft: {
        ..first.saved.draft,
        draft_id: key.draft_id,
        question: "Does another district disagree?",
        objection: "Different district, incompatible measurements",
      },
    },
    work: {
      ..first.work,
      draft_id: key.draft_id,
      revision: key.revision,
      result_digest: key.result_digest,
    },
    archive_digest: "sha256:second-archive",
  }
}

///|
test "cross dossier inquiry combines one selected contribution per question and preserves dissent" {
  let (input, first) = inquiry_fixture()
  let second = second_inquiry_outcome(first)
  let cross : @collaboration_contract.CrossDossierInquiry = {
    inquiry: { ..input, contributions: [input.contributions[0]], },
    additional: [
      { origin: second.key, contributions: [input.contributions[1]], },
    ],
  }
  let draft = @collaboration_contract.cross_dossier_inquiry_draft(cross, [
    first, second,
  ]).unwrap()
  assert_eq(draft.participants.map(p => p.book_id), ["water", "mobility"])
  for
    text in [
      first.key.review_digest,
      second.key.review_digest,
      first.archive_digest,
      second.archive_digest,
      input.contributions[0].quote,
      input.contributions[1].quote,
      "Different district",
      input.dissent,
    ] {
    assert_true((draft.question + draft.objection).contains(text), msg=text)
  }
  assert_true(
    @collaboration_contract.cross_dossier_inquiry_draft(cross, [first])
    is Err(_),
  )
  assert_true(
    @collaboration_contract.cross_dossier_inquiry_draft(
      {
        ..cross,
        additional: [
          { origin: first.key, contributions: [input.contributions[1]], },
        ],
      },
      [first],
    )
    is Err(_),
  )
  assert_true(
    @collaboration_contract.cross_dossier_inquiry_draft(
      {
        ..cross,
        additional: [
          {
            origin: second.key,
            contributions: [
              { ..input.contributions[1], quote: "Invented quote", },
            ],
          },
        ],
      },
      [first, second],
    )
    is Err(_),
  )
  // The same Book can contribute evidence from both origins, but receives one
  // ordinary assignment incorporating both challenges and current source paths.
  let other_path = "raw/other-period.md"
  let second = {
    ..second,
    saved: {
      ..second.saved,
      draft: {
        ..second.saved.draft,
        participants: second.saved.draft.participants.map(p => {
          if p.book_id == "water" {
            { ..p, source_paths: [other_path], }
          } else {
            p
          }
        }),
      },
      sources: second.saved.sources.map(s => {
        if s.book_id == "water" {
          {
            ..s,
            source_path: other_path,
            artifact_ref: "sources/water/" + other_path,
            digest: "sha256:other-period",
          }
        } else {
          s
        }
      }),
    },
  }
  let repeated = @collaboration_contract.cross_dossier_inquiry_draft(
    {
      ..cross,
      additional: [{ origin: second.key, contributions: input.contributions, }],
    },
    [first, second],
  ).unwrap()
  assert_eq(repeated.participants.length(), 2)
  assert_eq(
    repeated.participants[0].source_paths,
    first.saved.draft.participants[0].source_paths + [other_path],
  )
  assert_true(repeated.question.contains(first.key.review_digest))
  assert_true(repeated.question.contains(second.key.review_digest))
  assert_true(repeated.question.contains("sha256:other-period"))
}

///|
test "cross dossier basket survives inspection and opens an editable ordinary saved draft" {
  let (_, first) = inquiry_fixture()
  let second = second_inquiry_outcome(first)
  let selected = inquiry_client()
    .edit("inquiry_include_mobility", "no")
    .edit("inquiry_add_dossier", "add")
  assert_eq(selected.inquiry_dossiers.length(), 1)
  let inspecting = selected.select_outcome(second.key)
  assert_eq(
    inspecting.inquiry_fields.get("inquiry_question"),
    selected.inquiry_fields.get("inquiry_question"),
  )
  assert_eq(inspecting.inquiry_fields.get("inquiry_include_water"), None)
  let state = { ..inspecting, outcome: Some(second), }
    .edit("inquiry_include_mobility", "yes")
    .edit(
      "inquiry_quote_mobility", "Deterministic local fixture output: mobility",
    )
    .edit("inquiry_challenge_mobility", "Check the other district")
    .edit("inquiry_add_dossier", "add")
  assert_eq(state.inquiry_dossiers.length(), 2)
  let draft = state.cross_dossier_inquiry_preview().unwrap()
  let pending = state.begin("cross-dossier-inquiry", draft.draft_id)
  assert_true(pending.busy())
  let saved : @collaboration_contract.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft,
    revision: "r-cross",
    previous_revision: "",
    recorded_at: "2026-10-20",
    sources: [],
  }
  let reply = {
    ..outcome_reply(pending.generation, second.key),
    action: "cross-dossier-inquiry",
    outcome: None,
    saved: Some(saved),
  }
  let opened = pending.settle(
    pending.generation,
    "cross-dossier-inquiry",
    reply.to_json().stringify(),
  )
  assert_eq(opened.draft, draft)
  assert_true(opened.inquiry_dossiers.is_empty())
  assert_eq(opened.work, None)
  assert_eq(opened.prepared, None)
  assert_eq(
    opened.edit("title", "Edited cross-dossier inquiry").draft.title,
    "Edited cross-dossier inquiry",
  )
  assert_true(state.edit("inquiry_mode", "off").inquiry_outcomes.is_empty())
}
