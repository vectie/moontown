///|
async test "cross dossier API verifies two histories captures current sources saves edits and prepares" {
  let (store, root) = fixture()
  let original = store.save(fixture_draft(), "", "2026-10-20T03:00:00Z")
  ignore(retain_outcome_fixture(store, original, false))
  let second = store.save(
    {
      ..fixture_draft(),
      draft_id: "second-question",
      question: "Do the districts disagree?",
      objection: "Conflicting measurement periods",
    },
    "",
    "2026-10-20T03:01:00Z",
  )
  ignore(retain_outcome_fixture(store, second, false))
  let entries = store.list_outcomes()
  let first_outcome = store.inspect_outcome(
    entries.filter(e => e.draft_id == original.draft.draft_id)[0].key(),
  )
  let second_outcome = store.inspect_outcome(
    entries.filter(e => e.draft_id == second.draft.draft_id)[0].key(),
  )
  let input : @contract.CrossDossierInquiry = {
    inquiry: retained_inquiry_input(first_outcome, ["water"]),
    additional: [
      {
        origin: second_outcome.key,
        contributions: retained_inquiry_input(second_outcome, ["mobility"]).contributions,
      },
    ],
  }
  @fs.write_file(
    root + "/books/water/raw/nested/source.bin",
    "Updated current evidence for the cross-question inquiry",
  )
  let request = {
    ..retained_inquiry_request(input.inquiry),
    action: "cross-dossier-inquiry",
    payload: Some(input.to_json()),
  }
  let reply = store.request(request, "2026-10-20T03:02:00Z")
  assert_true(reply.ok, msg=reply.error)
  let saved = reply.saved.unwrap()
  assert_true(saved.draft.question.contains(first_outcome.key.review_digest))
  assert_true(saved.draft.question.contains(second_outcome.key.review_digest))
  assert_true(saved.draft.objection.contains("Conflicting measurement periods"))
  assert_true(saved.sources[0].digest != original.sources[0].digest)
  assert_eq(store.load(input.inquiry.draft_id), saved)
  assert_false(@fs.exists(store.work_root(saved)))
  let edited = store.save(
    { ..saved.draft, title: "Edited cross-dossier inquiry", },
    saved.revision,
    "2026-10-20T03:03:00Z",
  )
  assert_eq(store.load(input.inquiry.draft_id), edited)
  let prepared = store.prepare(input.inquiry.draft_id, edited.revision)
  assert_eq(prepared.review_status, "pending_review")
  assert_eq(
    store.read_oneoff(input.inquiry.draft_id, edited.revision).status,
    "not_started",
  )
  assert_eq(store.inspect_outcome(first_outcome.key), first_outcome)
  assert_eq(store.inspect_outcome(second_outcome.key), second_outcome)
}
