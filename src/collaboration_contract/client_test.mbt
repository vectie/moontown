///|
test "collaboration client ignores stale replies after clear and repeated clicks" {
  let state = @collaboration_contract.Client::new()
  let pending = state.begin("save", state.draft.draft_id)
  assert_eq(
    pending.begin("save", pending.draft.draft_id).generation,
    pending.generation,
  )
  let cleared = pending.reset()
  assert_eq(
    cleared.settle(pending.generation, "save", "{}").generation,
    cleared.generation,
  )
  assert_false(cleared.busy())
  let failed = pending.settle(pending.generation, "save", "interrupted")
  assert_false(failed.busy())
  assert_true(failed.notice.contains("retry"))
  assert_true(
    failed.begin("save", failed.draft.draft_id).generation > pending.generation,
  )
}

///|
test "collaboration client dirty edits invalidate prepared downloads and named review boundaries" {
  let saved : @collaboration_contract.SavedDraft = {
    contract_version: "moontown.collaboration-draft.v1",
    draft: @collaboration_contract.empty_draft("example"),
    revision: "r-abc",
    previous_revision: "",
    recorded_at: "2026-10-06T16:00:00Z",
    sources: [],
  }
  let initial = @collaboration_contract.Client::new().begin("load", "example")
  let reply : @collaboration_contract.Reply = {
    contract_version: "moontown.collaboration.reply.v1",
    request_id: initial.generation.to_string(),
    action: "load",
    ok: true,
    error: "",
    books: [],
    drafts: [],
    saved: Some(saved),
    prepared: None,
    work: None,
    outcomes: [],
    outcome: None,
    source_listing: None,
  }
  let loaded = initial.settle(
    initial.generation,
    "load",
    reply.to_json().stringify(),
  )
  assert_false(loaded.dirty)
  assert_eq(loaded.draft.draft_id, "example")
  let edited = loaded.edit("question", "Revised question")
  assert_true(edited.dirty)
  assert_false(edited.begin("prepare", "example").busy())
  assert_false(edited.begin("export", "example").busy())
  assert_eq(edited.prepared, None)
  let wrong = {
    ..reply,
    saved: Some({
      ..saved,
      draft: @collaboration_contract.empty_draft("wrong"),
    }),
  }
  let blocked = initial.settle(
    initial.generation,
    "load",
    wrong.to_json().stringify(),
  )
  assert_true(blocked.notice.contains("identity"))
  assert_eq(blocked.revision, "")
}

///|
test "collaboration client source selections are explicit and reviewer edits never create decisions" {
  let initial = @collaboration_contract.Client::new()
  let state : @collaboration_contract.Client = {
    ..initial,
    books: [{ book_id: "water", title: "Water", }],
  }
  let selected = state
    .toggle_book("water")
    .edit_participant(
      "water", "source_paths", "raw/one.md\nraw/nested/two.pdf\n",
    )
  assert_eq(selected.draft.participants[0].source_paths, [
    "raw/one.md", "raw/nested/two.pdf",
  ])
  let named = selected.edit("reviewer_id", "alex").edit("reviewer_name", "Alex")
  assert_eq(named.draft.reviewer_name, "Alex")
  assert_true(named.prepared is None)
  assert_eq(named.toggle_book("unregistered").draft, named.draft)
  assert_true(named.toggle_book("water").draft.participants.is_empty())
}
