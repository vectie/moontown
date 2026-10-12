///|
async test "collaboration reuses exactly the reopened revision after a concurrent newer save" {
  let (store, _) = fixture()
  let draft = fixture_draft()
  let first = store.save(draft, "", "2026-10-06T16:00:00Z")
  let latest = store.save(
    { ..draft, question: "A different question saved elsewhere?", },
    first.revision,
    "2026-10-06T16:01:00Z",
  )
  let request : Request = {
    contract_version: "moontown.collaboration.request.v1",
    request_id: "reuse-a",
    action: "reuse",
    draft_id: draft.draft_id,
    revision: first.revision,
    new_draft_id: "reuse-a",
    artifact_path: "",
    payload: None,
    draft: None,
  }
  let reply = store.request(request, "2026-10-06T16:02:00Z")
  assert_true(reply.ok)
  let reused = reply.saved.unwrap()
  assert_eq(reused.draft.question, first.draft.question)
  assert_true(reused.draft.question != latest.draft.question)
  assert_eq(reused.draft.participants, first.draft.participants)
  assert_eq(reused.previous_revision, "")
  let prepared = store.prepare(reused.draft.draft_id, reused.revision)
  assert_eq(prepared.review_status, "pending_review")
  let packet = store.artifact(
    reused.draft.draft_id,
    reused.revision,
    revision_prefix(reused) + "source-packet.json",
  )
  let bundle = @review.reimport_review_bundle(
    @utf8.decode(
      store.artifact(
        reused.draft.draft_id,
        reused.revision,
        revision_prefix(reused) + "review-bundle.json",
      ),
    ),
    packet,
  )
  assert_true(bundle.decision_receipts.is_empty())
  assert_eq(bundle.previous_bundle_ref, "")
  assert_false(
    store.request(
      { ..request, revision: "", new_draft_id: "unbound-reuse", },
      "2026-10-06T16:03:00Z",
    ).ok,
  )
}
